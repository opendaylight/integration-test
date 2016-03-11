import ipaddr
import logging
import binascii

# TODO: Define this bgp marker as a class (constant) variable of some
# suitable class.
VALID_BGP_MARKER = "0xFF" * 16


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


class BGPConnection(object):
    """Wrapper around a socket to a BGP speaker that provides BGP stream disassembly"""

    def __init__(self, name, bgp_socket=None):
        self.socket = bgp_socket
        self.logger = logging.getLogger(name)

    def establish_talking_connection(arguments):
        """Establish connection to BGP peer.

        Arguments:
            :arguments: Object with the following attributes:
                - arguments.myip: local IP address
                - arguments.myport: local port
                - arguments.peerip: remote IP address
                - arguments.peerport: remote port
        Returns:
            :return: socket.
        """
        self.logger.info("Connecting in the talking mode.")
        self.logger.debug("Local IP address: " + str(arguments.myip))
        self.logger.debug("Local port: " + str(arguments.myport))
        self.logger.debug("Remote IP address: " + str(arguments.peerip))
        self.logger.debug("Remote port: " + str(arguments.peerport))
        talking_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        talking_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        # bind to force specified address and port
        talking_socket.bind((str(arguments.myip), arguments.myport))
        # socket does not spead ipaddr, hence str()
        talking_socket.connect((str(arguments.peerip), arguments.peerport))
        self.socket = talking_socket
        self.logger.info("Connected to ODL.")

    def get_data(self, expected_length):
        self.logger.debug(
            "Getting " + str(expected_length) + " byte(s) of data"
        )
        message = []
        length = 0
        while length < expected_length:
            piece = self.socket.recv(expected_length - length)
            self.logger.debug(
                "Got data piece: " + binascii.hexlify(piece)
            )
            length += len(piece)
            message.append(piece)
        return "".join(message)

    def get_message(self):
        # Read the first 18 bytes of the message. These are needed to get
        # the exact length of the message.
        msg_header = self.get_data(19)
        self.logger.debug(
            "Got message header: " + binascii.hexlify(msg_header)
        )
        # TODO: NOTIFY the sender (Connection Not Synchronized) and close the
        #       connection if marker is not all 1's.
        if msg_header[0:16] != VALID_BGP_MARKER:
            error_msg = (
                "The marker in the message header is not valid"
            )
            self.logger.error(error_msg + ": " + binascii.hexlify(msg_header))
            raise MessageError(error_msg, msg_header)
        # Extract and check the actual length of the message. The length is
        # stored in the bytes 16 and 17 (counting from 0) of the message.
        msg_length = get_short_int_from_message(msg_header)
        self.logger.debug(
            "Message length: " + str(msg_length)
        )
        self.logger.debug(
            "Message type: " + str(ord(msg_header[18]))
        )
        if msg_length < 19:
            error_msg = (
                "The length of the message (" + str(msg_length) +
                ") is too small to be valid"
            )
            self.logger.error(error_msg + ": " + binascii.hexlify(msg_header))
            raise MessageError(error_msg, msg_header)
        # Calculate the length of the data in the message. The first 19
        # bytes were already read as the header.
        data_length = msg_length - 19
        msg_data = self.get_data(data_length)
        self.logger.debug(
            "Got message data: " + binascii.hexlify(msg_data)
        )
        # assemble and return the message.
        return msg_header + msg_data

    def send(self, data):
        self.logger.debug(
            "Senging message: " + binascii.hexlify(data)
        )
        self.socket.send(data)


def add_bgp_connection_arguments(parser):
    str_help = "Numeric IP Address of the target BGP speaker."
    parser.add_argument(
        "--peerip", default="127.0.0.1",
        type=ipaddr.IPv4Address, help=str_help
    )
    str_help = "TCP port of the target BGP speaker."
    parser.add_argument("--peerport", default="179", type=int, help=str_help)
