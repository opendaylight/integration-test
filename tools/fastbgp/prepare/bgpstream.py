import dump
import ipaddr
import logging
import binascii
import requests
import socket
import select

# TODO: Define this bgp marker as a class (constant) variable of some
# suitable class.
VALID_BGP_MARKER = "\xFF" * 16


def get_short_int_from_message(message, offset=16):
    """Extract 2-bytes number from provided message.

    Arguments:
        :message: given message
        :offset: offset of the short_int inside the message
    Returns:
        :return: required short_inf value.
    Notes:
        default offset value is the BGP message size offset.
    """
    high_byte_int = ord(message[offset])
    low_byte_int = ord(message[offset + 1])
    short_int = high_byte_int * 256 + low_byte_int
    return short_int


class ConnectionManager(object):
    def __init__(self):
        self.registry = select.epoll()
        self.connections = {}

    def register(self, connection):
        socket = connection.socket
        fd = socket.fileno()
        mask = select.EPOLLIN | select.EPOLLOUT
        self.registry.register(fd, mask)
        self.connections[fd] = connection

    def wait_until_message_sent(self, connection):
        while connection.connected and connection.buffer != "":
            result = self.registry.poll()
            for fd, events in result:
                if fd in self.connections:
                    other = self.connections[fd]
                    if events & select.EPOLLIN:
                        other.handle_reading_end()
                    if not other.connected:
                        continue
                    if events & select.EPOLLOUT:
                        other.handle_writing_end()

    def unregister(self, connection):
        socket = connection.socket
        fd = socket.fileno()
        del self.connections[fd]
        self.registry.unregister(fd)


class BgpConnectionError(EnvironmentError):

    def __init__(self, text, message, *args):
        """Initialisation.

        Store and call super init for textual comment,
        store raw message which caused it.
        """
        self.text = text
        self.msg = message
        super(BgpConnectionError, self).__init__(text, message, *args)

    def __str__(self):
        """Generate human readable error message.

        Returns:
            :return: human readable message as string
        Notes:
            Use a placeholder string if the message is to be empty.
        """
        message = binascii.hexlify(self.msg)
        if message == "":
            message = "(empty message)"
        return self.text + ": " + message


class BgpConnection(object):
    """Wrapper around a socket to a BGP speaker that provides BGP stream disassembly"""

    def __init__(self, name, address, myas, peer, manager=None):
        self.name = name
        self.myip, self.myport = address
        self.myas = myas
        self.peerip, self.peerport = peer
        self.logger = logging.getLogger(self.name)
        self.manager = manager
        self.connected = False

    def reset_message_getter(self):
        self.current = []
        self.remaining_size = 19
        self.process = self.analyze_header
        self.msg_header = None

    def use_template(self, template):
        data = template.replace("$NAME", self.name)
        data = data.replace("$IP", str(self.myip))
        data = data.replace("$PORT", str(self.myport))
        data = data.replace("$AS", str(self.myas))
        return data

    def configure_peer(self, template, url, auth):
        """Configure the BGP peer.

        Arguments:
            :template: Configuration template to use. The following
                placeholders are replaced in the template:
                - $NAME: Name of the peer
                - $IP: IP address of the peer
                - $PORT: Port of the peer
            :url: Restconf URL to post the resulting configuration to.
                Can also be a template with the placeholders as for
                the :template: parameter.
        """
        self.logger.info(
            "Configuring peer at IP=" + str(self.myip) + ", PORT=" +
            str(self.myport)
        )
        # Construct the configuration data using the template.
        data = self.use_template(template)
        # Send the data into ODL
        url = self.use_template(url)
        headers = {
            'Content-Type': 'application/xml',
            'Accept': 'application/xml',
        }
        self.logger.debug("Executing PUT on: " + url)
        self.logger.debug("PUTting headers: " + repr(headers))
        self.logger.debug("PUTting data: " + repr(data))
        r = requests.put(url, data=data, headers=headers, auth=auth)
        self.logger.info(
            "Got response code " + str(r.status_code) + " to configuration request."
        )
        try:
            r.raise_for_status()
        except requests.exceptions.HTTPError:
            self.logger.exception(
                "Failed to configure peer " + self.name +
                "; got response data " + repr(r.content)
            )

    def establish_talking_connection(self):
        """Establish connection to BGP peer.

        After successful completion the "get_message" and "send" methods
        become usable.
        """
        self.logger.info("Connecting in the talking mode: " + self.name)
        self.logger.debug("Local IP address: " + str(self.myip))
        self.logger.debug("Local port: " + str(self.myport))
        self.logger.debug("Remote IP address: " + str(self.peerip))
        self.logger.debug("Remote port: " + str(self.peerport))
        talking_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        talking_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        # bind to force specified address and port
        talking_socket.bind((str(self.myip), self.myport))
        # socket does not speak ipaddr, hence str()
        talking_socket.connect((str(self.peerip), self.peerport))
        talking_socket.setblocking(0)
        # Register the connection with the connection manager
        self.socket = talking_socket
        if self.manager is not None:
            self.manager.register(self)
        self.buffer = ""
        # Initialize message getting state
        self.reset_message_getter()
        # Report that it is connected
        self.logger.info("Connected: " + self.name)
        self.connected = True

    def disconnect(self):
        self.logger.info("Disconnecting: " + self.name)
        if self.manager is not None:
            self.manager.unregister(self)
        self.socket.close()
        del self.socket, self.buffer, self.msg_header, self.current
        del self.remaining_size, self.process
        self.connected = False
        self.logger.info("Disconnected: " + self.name)

    def analyze_header(self):
        # Assemble the header of the message.
        msg_header = ''.join(self.current)
        self.logger.debug(
            "Got message header: " + binascii.hexlify(msg_header)
        )
        # Check the marker and raise an exception if found invalid.
        marker = msg_header[:16]
        if marker != VALID_BGP_MARKER:
            print repr(marker)
            print repr(VALID_BGP_MARKER)
            # TODO: Emit NOTIFY: 1, 1 (Connection Not Synchronized)
            error_msg = (
                "The marker in the message header is not valid"
            )
            self.logger.error(error_msg + ": " + binascii.hexlify(msg_header))
            self.disconnect()
            raise BgpConnectionError(error_msg, msg_header)
        # Extract and check the actual length of the message. The length is
        # stored in the bytes 16 and 17 (counting from 0) of the message
        # header. Also check the length for validity
        msg_length = get_short_int_from_message(msg_header)
        self.logger.debug(
            "Message length: " + str(msg_length)
        )
        self.logger.debug(
            "Message type: " + str(ord(msg_header[18]))
        )
        error_msg = None
        if msg_length < 19:
            error_msg = (
                "The length of the message (" + str(msg_length) +
                ") is too small to be valid"
            )
        if msg_length > 4096:
            error_msg = (
                "The length of the message (" + str(msg_length) +
                ") is too large to be valid"
            )
        if error_msg is not None:
            # TODO: NOTIFY the sender 1, 2 (Bad Message Length).
            self.logger.error(error_msg + ": " + binascii.hexlify(msg_header))
            self.disconnect()
            raise BgpConnectionError(error_msg, msg_header)
        # Configure the state machine to load the data part of the message
        self.msg_header = msg_header
        self.current = []
        if msg_length == 19:
            self.assemble_message()
        else:
            self.remaining_size = msg_length - 19
            self.process = self.assemble_message

    def assemble_message(self):
        # Assemble the message
        msg_data = "".join(self.current)
        self.logger.debug(
            "Got message data: " + binascii.hexlify(msg_data)
        )
        message = self.msg_header + msg_data
        self.process_message(message)
        # Reset the state machine to make it ready for another message.
        self.reset_message_getter()

    def process_message(self, message):
        pass

    def handle_reading_end(self):
        "Read data on the connection and add it to the message being assembled."
        try:
            data = self.socket.recv(self.remaining_size)
        except EnvironmentError:
            return
        self.logger.debug(
            "Received " + str(len(data)) + "byte(s): " +
            binascii.hexlify(data)
        )
        if data=="":
            self.disconnect()
            return
        self.remaining_size -= len(data)
        self.current.append(data)
        if self.remaining_size == 0:
            self.process()

    def handle_writing_end(self):
        try:
            bytes_sent = self.socket.send(self.buffer)
        except EnvironmentError:
            return
        if bytes_sent == 0:
            return
        self.logger.debug(
            "Transmitted " + str(bytes_sent) + "byte(s): " +
            binascii.hexlify(self.buffer[:bytes_sent])
        )
        self.buffer = self.buffer[bytes_sent:]

    def send(self, data):
        if not self.connected:
            self.logger.debug(
                "Ignoring data: " + binascii.hexlify(data)
            )
            return
        self.logger.debug(
            "Queueing message: " + binascii.hexlify(data)
        )
        self.buffer += data
        if self.manager is not None:
            self.manager.wait_until_message_sent(self)


def add_bgp_connection_arguments(parser):
    str_help = "Numeric IP Address of the target BGP speaker."
    parser.add_argument(
        "--peerip", default="127.0.0.1",
        type=ipaddr.IPv4Address, help=str_help
    )
    str_help = "TCP port of the target BGP speaker."
    parser.add_argument("--peerport", default="179", type=int, help=str_help)
