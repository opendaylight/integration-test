"""
Script to trace network traffic on controller - using packets to calculate
round-trip performance
"""
__author__ = 'Marcus Williams'
__copyright__ = "Copyright (c) 2016, Intel Corp Inc. "
__license__ = "New-style BSD"
__email__ = "marcus.williams@intel.com"
__version__ = "0.0.1"


import argparse
from BaseHTTPServer import BaseHTTPRequestHandler
from StringIO import StringIO
from impacket import ImpactDecoder as Pkt_Decoder
import logging
import pcapy
import signal
import socket
from struct import unpack
import sys


class CaptureTrace(object):
    """Exceptions are documented in the same way as classes.

    The __init__ method may be documented in either the class level
    docstring, or as a docstring on the __init__ method itself.

    Either form is acceptable, but the two should not be mixed. Choose one
    convention to document the __init__ method and be consistent with it.

    Note:
        Do not include the `self` parameter in the ``Args`` section.

    Args:
        msg (str): Human readable string describing the exception.
        code (Optional[int]): Error code.

    Attributes:
        msg (str): Human readable string describing the exception.
        code (int): Exception error code.

    """
    DEFAULT_PKT_FILTER_DICT = {'http_port': 80,
                               'openflow_port': 6633,
                               'ovsdb_port': 6640}
    ETH_HEADER_LEN = 14
    ETH_PROTOCOL_NUM = 8
    TCP_PROTOCOL_NUM = 6
    UDP_PROTOCOL_NUM = 17

    def __init__(self,
                 capt_interface,
                 capt_snaplen=65536,
                 capt_promisc=1,
                 capt_timeout_ms=0,
                 packet_filter_dict=DEFAULT_PKT_FILTER_DICT):
        """
        Args:
            :param controller_ip: The ODL host ip used to send RPCs
            :param controller_port: The RESTCONF port on the ODL host
            :param vswitch_ip: The ip of Open vSwitch to use
            :param vswitch_ovsdb_port: The ovsdb port of Open vSwitch to use
            :param vswitch_remote_ip: The ip of remote Open vSwitch to use
            :param vswitch_remote_ovsdb_port: The ovsdb port of remote Open
                vSwitch to use
            :param vswitch_port_type: Port type to create
            :param num_instances: The number of instances (bridges, ports etc)
                to be added
        """
        logging.basicConfig(level=logging.DEBUG)
        self.capt_interface = capt_interface
        self.capt_snaplen = capt_snaplen
        self.capt_promisc = capt_promisc
        self.capt_timeout_ms = capt_timeout_ms
        self.capt_dict = dict()
        self.http_dict = dict()
        self.openflow_dict = dict()
        self.ovsdb_dict = dict()
        self.packet_filter_dict = packet_filter_dict

    def capture_pkts(self):
        """Generators have a ``Yields`` section instead of a ``Returns``

        Args:
            n (int): The upper limit of the range to generate, from 0 to

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and should
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        net_trace = pcapy.open_live(self.capt_interface,
                                    self.capt_snaplen,
                                    self.capt_promisc,
                                    self.capt_timeout_ms)

        net_trace.setfilter('tcp and port %d or port %d or '
                            'port %d or dst port 6653' %
                            (self.packet_filter_dict['http_port'],
                             self.packet_filter_dict['openflow_port'],
                             self.packet_filter_dict['ovsdb_port']))
        while True:
            (pcap_header, packet) = net_trace.next()
            self.process_pkt(pcap_header, packet)

    @staticmethod
    def convert_mac_addr(address):
        """Generators have a ``Yields`` section instead of a ``Returns``

        Args:
            n (int): The upper limit of the range to generate, from 0 to

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and should
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        hex_str = "%.2x:%.2x:%.2x:%.2x:%.2x:%.2x" % \
                  (ord(address[0]),
                   ord(address[1]),
                   ord(address[2]),
                   ord(address[3]),
                   ord(address[4]),
                   ord(address[5]))
        return hex_str

    @staticmethod
    def parse_eth_header(packet):
        """Generators have a ``Yields`` section instead of a

        Args:
            n (int): The upper limit of the range to generate, from 0 to

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and should
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        eth_header_packed = packet[:CaptureTrace.ETH_HEADER_LEN]
        eth_header = unpack('!6s6sH', eth_header_packed)
        eth_protocol = socket.ntohs(eth_header[2])
        dst_mac = CaptureTrace.convert_mac_addr(packet[0:6])
        src_mac = CaptureTrace.convert_mac_addr(packet[6:12])
        print 'Destination MAC: ' + dst_mac
        print 'Source MAC: ' + src_mac
        print 'Protocol: ' + eth_protocol

        return eth_protocol, dst_mac, src_mac

    @staticmethod
    def parse_ip_pkt(packet):
        """Generators have a ``Yields`` section instead of a

        Args:
            n (int): The upper limit of the range to generate, f

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        ip_header_packed = \
            packet[CaptureTrace.ETH_HEADER_LEN:20+CaptureTrace.ETH_HEADER_LEN]
        ip_header = unpack('!BBHHHBBH4s4s', ip_header_packed)

        version_ihl = ip_header[0]
        version = version_ihl >> 4
        ihl = version_ihl & 0xF

        ip_head_length = ihl * 4

        ttl = ip_header[5]
        protocol = ip_header[6]
        src_addr = socket.inet_ntoa(ip_header[8])
        dst_addr = socket.inet_ntoa(ip_header[9])

        print 'Version: ' + str(version)
        print 'IP Header Length: ' + str(ihl)
        print 'TTL: ' + str(ttl)
        print 'Protocol: ' + str(protocol)
        print 'Source Address: ' + str(src_addr)
        print 'Destination Address: ' + str(dst_addr)

        return ip_head_length, ttl, protocol, src_addr, dst_addr

    @staticmethod
    def parse_transport_pkt_data(packet,
                                 ip_header_length,
                                 transport_protocol,
                                 transport_header_len):
        """Generators have a ``Yields`` section instead

        Args:
            n (int): The upper limit of the range to generate,

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and should
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        header_size = None
        if transport_protocol == "tcp":
            header_size = CaptureTrace.ETH_HEADER_LEN + \
                          ip_header_length + \
                          transport_header_len * 4
        elif transport_protocol == "udp":
            header_size = CaptureTrace.ETH_HEADER_LEN + \
                          ip_header_length + \
                          transport_header_len

        data_payload_size = len(packet) - header_size

        data = packet[header_size:]

        print 'Data Payload Size : ' + str(data_payload_size)
        print 'Data : ' + data

        return header_size, data_payload_size, data

    @staticmethod
    def parse_tcp_pkt(packet, ip_header_length):
        """Generators have a ``Yields`` section instead of a

        Args:
            n (int): The upper limit of the range to generate,

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        previous_headers_len = ip_header_length + CaptureTrace.ETH_HEADER_LEN
        tcp_header_packed = packet[previous_headers_len:previous_headers_len+20]

        tcp_header = unpack('!HHLLBBHHH', tcp_header_packed)

        src_port = tcp_header[0]
        dst_port = tcp_header[1]
        sequence = tcp_header[2]
        acknowledgement = tcp_header[3]
        doff_reserved = tcp_header[4]
        tcp_header_len = doff_reserved >> 4

        print 'Source Port: ' + str(src_port)
        print 'Destination Port: ' + str(dst_port)
        print 'Sequence Number: ' + str(sequence)
        print 'Acknowledgement: ' + str(acknowledgement)
        print 'TCP header length: ' + str(tcp_header_len)

        udp_data_tuple = CaptureTrace.parse_transport_pkt_data(packet,
                                                               ip_header_length,
                                                               "tcp",
                                                               tcp_header_len)
        header_size, data_payload_size, data = udp_data_tuple

        return src_port, dst_port, sequence, acknowledgement, \
            doff_reserved, tcp_header_len, header_size, \
            data_payload_size, data

    @staticmethod
    def parse_udp_pkt(packet, ip_header_length):
        """Generators have a ``Yields`` section instead of a

        Args:
            n (int): The upper limit of the range to generate,

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        previous_headers_len = ip_header_length + CaptureTrace.ETH_HEADER_LEN
        udp_header_length = 8
        udp_header_packed = packet[previous_headers_len:previous_headers_len+8]

        udp_header = unpack('!HHHH', udp_header_packed)

        src_port = udp_header[0]
        dst_port = udp_header[1]
        udp_len = udp_header[2]
        checksum = udp_header[3]

        print 'Source Port: ' + str(src_port)
        print 'Destination Port: ' + str(dst_port)
        print 'Length: ' + str(udp_len)
        print 'Checksum : ' + str(checksum)

        udp_data_tuple = CaptureTrace.\
            parse_transport_pkt_data(packet,
                                     ip_header_length,
                                     "udp",
                                     udp_header_length)
        header_size, data_payload_size, data = udp_data_tuple

        return src_port, dst_port, udp_len, checksum, \
            header_size, data_payload_size, data

    @staticmethod
    def process_data(data):
        """Generators have a ``Yields`` section instead of a

        Args:
            n (int): The upper limit of the range to generate, from

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and should
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        ## Process Data
        data_decoder = Pkt_Decoder.DataDecoder()
        decoded_data = data_decoder.decode(data)
        print decoded_data

        return decoded_data

    def process_pkt(self, pcap_header, packet):
        """Generators have a ``Yields`` section instead of a

        Args:
            n (int): The upper limit of the range to generate, from

        Yields:
            int: The next number in the range of 0 to `n` - 1.

        Examples:
            Examples should be written in doctest format, and should
            to use the function.

            >>> print([i for i in example_generator(4)])
            [0, 1, 2, 3]

        """
        packet_obj = None
        data = None
        ## pcap_header.getts()
        ## get timestamp tuple (seconds, microseconds) since the Epoch
        timestamp_tuple = pcap_header.getts()

        eth_protocol, dst_mac, src_mac = CaptureTrace.parse_eth_header(packet)

        if eth_protocol == CaptureTrace.ETH_PROTOCOL_NUM:
            ip_output_tuple = CaptureTrace.parse_ip_pkt(packet)
            ip_head_len, ip_ttl, ip_protocol, ip_src_addr, \
            ip_dst_addr = ip_output_tuple

            if ip_protocol == CaptureTrace.TCP_PROTOCOL_NUM:
                tcp_output_tuple = CaptureTrace.parse_tcp_pkt(packet,
                                                              ip_head_len)
                src_port, dst_port, tcp_sequence, \
                    tcp_acknowledgement, tcp_doff_reserved, \
                    transport_header_len, header_size, \
                    data_payload_size, data = tcp_output_tuple

                packet_obj = PacketTCP(
                    tcp_sequence=tcp_sequence,
                    tcp_acknowledgement=tcp_acknowledgement,
                    tcp_doff_reserved=tcp_doff_reserved,
                    eth_type=eth_protocol,
                    eth_type_name="ip",
                    src_mac=src_mac,
                    dst_mac=dst_mac,
                    ip_head_len=ip_head_len,
                    transport_proto=ip_protocol,
                    transport_proto_name="tcp",
                    transport_header_len=transport_header_len,
                    ttl=ip_ttl,
                    src_ip=ip_src_addr,
                    dst_ip=ip_dst_addr,
                    src_port=src_port,
                    dst_port=dst_port,
                    total_header_size=header_size,
                    data_payload_size=data_payload_size,
                    data=data,
                    decoded_data=CaptureTrace.process_data(data),
                    pkt_sent_time=timestamp_tuple)

            elif ip_protocol == CaptureTrace.UDP_PROTOCOL_NUM:
                udp_output_tuple = CaptureTrace.parse_udp_pkt(
                    packet,
                    ip_head_len)
                src_port, dst_port, transport_header_len, udp_checksum, \
                    header_size, data_payload_size, data = udp_output_tuple

                packet_obj = PacketUDP(
                    udp_checksum=udp_checksum,
                    eth_type=eth_protocol,
                    eth_type_name="ip",
                    src_mac=src_mac,
                    dst_mac=dst_mac,
                    ip_head_len=ip_head_len,
                    transport_proto=ip_protocol,
                    transport_proto_name="tcp",
                    transport_header_len=transport_header_len,
                    ttl=ip_ttl,
                    src_ip=ip_src_addr,
                    dst_ip=ip_dst_addr,
                    src_port=src_port,
                    dst_port=dst_port,
                    total_header_size=header_size,
                    data_payload_size=data_payload_size,
                    data=data,
                    decoded_data=CaptureTrace.process_data(data),
                    pkt_sent_time=timestamp_tuple)

            if self.packet_filter_dict['http_port'] in packet_obj.dst_port:
                request = HTTPRequest(
                    packet_obj.decoded_data.get_buffer_as_string())
                if "br" in request.path:
                    self.http_dict[request.path] = (packet_obj, request)
            if self.packet_filter_dict['openflow_port'] in packet_obj.dst_port:
                packet_obj.decoded_data.get_buffer_as_string()
                self.openflow_dict[timestamp_tuple[1]] = packet_obj
            if self.packet_filter_dict['ovsdb_port'] in packet_obj.dst_port:
                self.ovsdb_dict[timestamp_tuple[1]] = packet_obj


class Packet(object):
    """Exceptions are documented in the same way as classes.

    The __init__ method may be documented in either the class level
    docstring, or as a docstring on the __init__ method itself.

    Either form is acceptable, but the two should not be mixed. Choose one
    convention to document the __init__ method and be consistent with it.

    Note:
        Do not include the `self` parameter in the ``Args`` section.

    Args:
        msg (str): Human readable string describing the exception.
        code (Optional[int]): Error code.

    Attributes:
        msg (str): Human readable string describing the exception.
        code (int): Exception error code.

    """
    def __init__(self,
                 eth_type,
                 eth_type_name,
                 src_mac,
                 dst_mac,
                 ip_head_len,
                 transport_proto,
                 transport_proto_name,
                 transport_header_len,
                 ttl,
                 src_ip,
                 dst_ip,
                 src_port,
                 dst_port,
                 total_header_size,
                 data_payload_size,
                 data,
                 pkt_sent_time):
        """
        Args:
            :param type: String - Packet type
            :param protocol: String - Protocol type
            :param rx_port: Int - Receive port number
            :param tx_port: Int - Transmit port number
        """
        logging.basicConfig(level=logging.DEBUG)
        self.eth_type = eth_type
        self.eth_type = eth_type_name
        self.src_mac = src_mac
        self.dst_mac = dst_mac
        self.ip_head_len = ip_head_len
        self.transport_proto = transport_proto
        self.transport_proto_name = transport_proto_name
        self.transport_header_len = transport_header_len
        self.ttl = ttl
        self.src_ip = src_ip
        self.dst_ip = dst_ip
        self.src_port = src_port
        self.dst_port = dst_port
        self.total_header_size = total_header_size
        self.data_payload_size = data_payload_size
        self.data = data
        self.pkt_sent_time = pkt_sent_time


class PacketTCP(Packet):
    """Exceptions are documented in the same way as classes.

    The __init__ method may be documented in either the class level
    docstring, or as a docstring on the __init__ method itself.

    Either form is acceptable, but the two should not be mixed. Choose one
    convention to document the __init__ method and be consistent with it.

    Note:
        Do not include the `self` parameter in the ``Args`` section.

    Args:
        msg (str): Human readable string describing the exception.
        code (Optional[int]): Error code.

    Attributes:
        msg (str): Human readable string describing the exception.
        code (int): Exception error code.

    """
    def __init__(self,
                 tcp_sequence,
                 tcp_acknowledgement,
                 tcp_doff_reserved,
                 eth_type,
                 eth_type_name,
                 src_mac,
                 dst_mac,
                 ip_head_len,
                 transport_proto,
                 transport_proto_name,
                 transport_header_len,
                 ttl,
                 src_ip,
                 dst_ip,
                 src_port,
                 dst_port,
                 total_header_size,
                 data_payload_size,
                 data,
                 decoded_data,
                 pkt_sent_time):

        Packet.__init__(self,
                        eth_type=eth_type,
                        eth_type_name=eth_type_name,
                        src_mac=src_mac,
                        dst_mac=dst_mac,
                        ip_head_len=ip_head_len,
                        transport_proto=transport_proto,
                        transport_proto_name=transport_proto_name,
                        transport_header_len=transport_header_len,
                        ttl=ttl,
                        src_ip=src_ip,
                        dst_ip=dst_ip,
                        src_port=src_port,
                        dst_port=dst_port,
                        total_header_size=total_header_size,
                        data_payload_size=data_payload_size,
                        data=data,
                        pkt_sent_time=pkt_sent_time)
        self.tcp_sequence = tcp_sequence
        self.tcp_acknowledgement = tcp_acknowledgement
        self.tcp_doff_reserved = tcp_doff_reserved
        self.decoded_data = decoded_data


class PacketUDP(Packet):
    """Exceptions are documented in the same way as classes.

    The __init__ method may be documented in either the class level
    docstring, or as a docstring on the __init__ method itself.

    Either form is acceptable, but the two should not be mixed. Choose one
    convention to document the __init__ method and be consistent with it.

    Note:
        Do not include the `self` parameter in the ``Args`` section.

    Args:
        msg (str): Human readable string describing the exception.
        code (Optional[int]): Error code.

    Attributes:
        msg (str): Human readable string describing the exception.
        code (int): Exception error code.

    """
    def __init__(self,
                 udp_checksum,
                 eth_type,
                 eth_type_name,
                 src_mac,
                 dst_mac,
                 ip_head_len,
                 transport_proto,
                 transport_proto_name,
                 transport_header_len,
                 ttl,
                 src_ip,
                 dst_ip,
                 src_port,
                 dst_port,
                 total_header_size,
                 data_payload_size,
                 data,
                 decoded_data,
                 pkt_sent_time):

        Packet.__init__(self,
                        eth_type=eth_type,
                        eth_type_name=eth_type_name,
                        src_mac=src_mac,
                        dst_mac=dst_mac,
                        ip_head_len=ip_head_len,
                        transport_proto=transport_proto,
                        transport_proto_name=transport_proto_name,
                        transport_header_len=transport_header_len,
                        ttl=ttl,
                        src_ip=src_ip,
                        dst_ip=dst_ip,
                        src_port=src_port,
                        dst_port=dst_port,
                        total_header_size=total_header_size,
                        data_payload_size=data_payload_size,
                        data=data,
                        pkt_sent_time=pkt_sent_time)
        self.udp_checksum = udp_checksum
        self.decoded_data = decoded_data


class CalculateTrip(object):
    """Exceptions are documented in the same way as classes.

    The __init__ method may be documented in either the class level
    docstring, or as a docstring on the __init__ method itself.

    Either form is acceptable, but the two should not be mixed. Choose one
    convention to document the __init__ method and be consistent with it.

    Note:
        Do not include the `self` parameter in the ``Args`` section.

    Args:
        msg (str): Human readable string describing the exception.
        code (Optional[int]): Error code.

    Attributes:
        msg (str): Human readable string describing the exception.
        code (int): Exception error code.

    """
    print 'cal trip'


class HTTPRequest(BaseHTTPRequestHandler):
    """Exceptions are documented in the same way as classes.

    The __init__ method may be documented in either the class level
    docstring, or as a docstring on the __init__ method itself.

    Either form is acceptable, but the two should not be mixed. Choose one
    convention to document the __init__ method and be consistent with it.

    Note:
        Do not include the `self` parameter in the ``Args`` section.

    Args:
        msg (str): Human readable string describing the exception.
        code (Optional[int]): Error code.

    Attributes:
        msg (str): Human readable string describing the exception.
        code (int): Exception error code.

    """
    def __init__(self, req_txt):
        self.read_file = StringIO(req_txt)
        self.raw_requestline = self.read_file.readline()
        self.error_code = self.error_message = None
        self.parse_request()
        # BaseHTTPRequestHandler.__init__()

    def send_error(self, code, message=None):
        self.error_code = code
        self.error_message = message


def sigterm_handler(_signo, _stack_frame):
    """sigterm_handler handle signal termination gracefully

    Args:
        _signo (int): signal number
        _stack_frame (int): stack frame
    """

    print _signo
    print _stack_frame
    print "Exiting Gracefully ..."
    sys.exit(0)

if __name__ == "__main__":
    PARSER = argparse.ArgumentParser(
        description='Script to trace network traffic on controller'
        '- using packets to calculate performance of round-trip'
        ' rest to SB to OpenDaylight')

    PARSER.add_argument('--capt_interface', default=None,
                        help='Interface used to capture traffic \
                            (default is None)')
    PARSER.add_argument('--capt_snaplen', default=65536,
                        help='Snaplen of capture (default \
                            is 65536)')
    PARSER.add_argument('--capt_promisc', default=1,
                        help='Capture in promiscuous mode \
                            (default is 1 or on)')
    PARSER.add_argument('--capt_timeout_ms', default=0,
                        help='Capture timeout in milliseconds \
                            (default is 0)')
    PARSER.add_argument('--capt_filter_lst', default='6640',
                        help='Comma separated list of name:port_num \
                            (default is "http_port:80, '
                             'openflow_port:6633, ovsdb_port:6640")')
    PARSER.add_argument('--out_file', default='net_trace_calc.csv',
                        help='Name of output file \
                            (default is "net_trace_calc.csv")')

    ARGS = PARSER.parse_args()

    signal.signal(signal.SIGTERM, sigterm_handler)

    CAPTURE_TRACE = CaptureTrace(ARGS.capt_interface,
                                 ARGS.capt_snaplen,
                                 ARGS.capt_promisc,
                                 ARGS.capt_timeout_ms)

    if ARGS.capt_interface:
        CAPTURE_TRACE.capture_pkts()
    else:
        print "Please supply interface name such as '--capt_interface eth0'", \
            ARGS.capt_interface
