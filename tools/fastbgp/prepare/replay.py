"""Utility for replaying data prepared by the 'prepare' tool.

It needs to be run with sudo-able user when you want to use ports below 1024
as --myip. This utility is used to avoid excessive waiting times which EXABGP
exhibits when used with huge router tables and also avoid the memory cost of
EXABGP in this type of scenario."""


import argparse
import ipaddr
import logging
import bgpstream
import binascii
import fileio
import mrt
import dump


__author__ = "Jozef Behran"
__copyright__ = "Copyright(c) 2016, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "jbehran@cisco.com"


ValidLogLevels = ("critical", "error", "warn", "info", "debug")


def loglevel(level):
    numeric_level = None
    if level in ValidLogLevels:
        numeric_level = getattr(logging, level.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError('Invalid log level: %s' % level)
    return numeric_level


def get_valid_log_levels():
    names = []
    for name in ValidLogLevels:
        try:
            value = loglevel(name)
        except ValueError:
            continue
        names.append(name)
    return names


def add_logging_arguments(parser):
    names = get_valid_log_levels()
    str_help = "Log level (" + ", ".join(names) + ")"
    parser.add_argument(
        "--loglevel", default="info",
        type=loglevel, dest="loglevel", help=str_help
    )
    str_help = "Log file name"
    parser.add_argument("--logfile", default="replay.log", help=str_help)


def configure_logging(arguments):
    logging.basicConfig(
        filename=arguments.logfile, level=arguments.loglevel, filemode="w",
        format="%(asctime)s|%(levelname)8s|%(name)30s|%(funcName)30s|%(message)s"
    )


def split_range(value):
    value = value.split("-")
    if len(value) != 2:
        raise ValueError("Too many components in the range")
    return value


def ip_range(value):
    first_ip, last_ip = split_range(value)
    first_ip = ipaddr.IPv4Address(first_ip)
    last_ip = ipaddr.IPv4Address(last_ip)
    return first_ip, last_ip


def port_range(value):
    first_port, last_port = split_range(value)
    first_port = int(first_port)
    last_port = int(last_port)
    return first_port, last_port


def parse_arguments():
    """Use argparse to get arguments,

    Returns:
        :return: args object.
    """
    parser = argparse.ArgumentParser()
    str_help = (
        "Data file to be replayed. It can be uncompressed or "
        "compressed with gzip or bzip2 (the compression "
        "format is detected automatically)"
    )
    parser.add_argument(
        "--feedfile", default="feed.gz",
        type=str, dest="feedfile", help=str_help
    )
    str_help = (
        "Template to be used to construct configuration data "
        "to be sent to ODL Restconf to configure the simulated "
        "peers from the feed."
    )
    parser.add_argument(
        "--template", default="template.xml",
        type=str, dest="template", help=str_help
    )
    str_help = (
        "IP address range (inclusive) to be used for the "
        "simulated peers."
    )
    parser.add_argument(
        "--iprange", default = "127.0.0.2-127.0.255.254",
        type=ip_range, dest="iprange", help=str_help
    )
    str_help = (
        "Port to be used for the simulated peers."
    )
    parser.add_argument(
        "--port", default = "17900",
        type=int, dest="port", help=str_help
    )
    str_help = (
        "Restconf port of the tested ODL instance."
    )
    parser.add_argument(
        "--restconfport", default="8181", metavar="PORT",
        type=int, dest="restconfport", help=str_help
    )
    str_help = (
        "URL path template to use to configure the peers (the"
        "http://server:port/ prefix is left out)."
    )
    path=(
        "restconf/config/"
        "network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/"
        "config:modules/module/odl-bgp-rib-impl-cfg:bgp-peer/$NAME"
    )
    parser.add_argument(
        "--urlpath", default=path,
        type=str, dest="urlpath", help=str_help
    )
    str_help = (
        "Username to be used for restconf."
    )
    parser.add_argument(
        "--username", default="admin",
        type=str, dest="username", help=str_help
    )
    str_help = (
        "Password to be used for restconf."
    )
    parser.add_argument(
        "--password", default="admin",
        type=str, dest="password", help=str_help
    )
    bgpstream.add_bgp_connection_arguments(parser)
    add_logging_arguments(parser)
    arguments = parser.parse_args()
    configure_logging(arguments)
    return arguments


def error(error_msg):
    logger.exception(error_msg)
    print error_msg
    raise SystemExit(1)


def get_address_iterator(ip_range, port):
    first_ip, last_ip = ip_range
    ip = int(first_ip)
    last_ip = int(last_ip)
    while ip < last_ip:
        address = ipaddr.IPv4Address(ip)
        yield str(address), port
        ip += 1


class TPeerList:

    def __init__(self, addresses, template, peer, url, auth):
        """Construct an empty peer table.

        Arguments:
            :addresses: Iterable with addresses to be assigned to the
                simulated peers.
            :template: Configuration template to be used to configure new
                peers into ODL. It uses the following 
                - $NAME: Name of the peer used for lookups
                - $IP: IP address from which the peer is connecting
                - $PEER_PORT: port from which the peer is connecting
                - $HOLDTIME: hold time value to be presented to the peer
                - $INITIATE: always "false" (whether ODL initiates connection)
        """
        self.template = template
        self.addresses = addresses
        self.peer = peer
        self.peers = {}
        self.url = url
        self.auth = auth
        self.manager = bgpstream.ConnectionManager()

    def get_connection(self, peer):
        """Construct and get connection object for the specified peer.

        Arguments:
            :peer: Peer for which to get the connection
        """
        if peer in self.peers:
            return self.peers[peer]
        name = dump.get_peer_name(peer)
        address = self.addresses.next()
        peeras = peer[1]
        odl = self.peer
        manager = self.manager
        connection = bgpstream.BgpConnection(name, address, peeras, odl, manager)
        connection.configure_peer(self.template, self.url, self.auth)
        self.peers[peer] = connection
        return connection


def main():
    global logger
    logger = logging.getLogger("main")
    arguments = parse_arguments()
    configure_logging(arguments)
    logger.info("Starting the feed data replay")
    try:
        template = open(arguments.template).read()
    except EnvironmentError:
        error("Could not open the configuration template file")
    logger.info(
        "Loaded configuration template from file: " + arguments.template
    )
    sequence = get_address_iterator(arguments.iprange, arguments.port)
    peer = (arguments.peerip, arguments.peerport)
    url = (
        "http://" + str(arguments.peerip) + ":" +
        str(arguments.restconfport) + "/" + arguments.urlpath
    )
    auth = (arguments.username, arguments.password)
    peers = TPeerList(sequence, template, peer, url, auth)
    try:
        F = fileio.TFileReader(arguments.feedfile)
    except EnvironmentError:
        error("Could not open the feed file")
    logger.info("Opened feed file: " + arguments.feedfile)
    reader = mrt.TMRTReader(F)
    StateChange = (mrt.BGP4MP_STATE_CHANGE, mrt.BGP4MP_STATE_CHANGE_AS4)
    Message = (mrt.BGP4MP_MESSAGE, mrt.BGP4MP_MESSAGE_AS4)
    while True:
        P = reader.GetNextPacket()
        if P is None:
            break
        H = P.H
        D = P.Data
        if H.Type == mrt.BGP4MP:
            if H.SubType in StateChange:
                logger.debug(
                    'Fetched state change from "' +
                    dump.TranslateState(D.OldState) + '" to "' +
                    dump.TranslateState(D.NewState) + '" for peer "' +
                    dump.PeerToString(D.PeerIP, D.PeerAS) + '"'
                )
                connection = peers.get_connection((D.PeerIP, D.PeerAS))
                if D.NewState == mrt.ST_IDLE:
                    if connection.connected:
                        connection.disconnect()
                else:
                    if not connection.connected:
                        connection.establish_talking_connection()
                P = None
            elif H.SubType in Message:
                logger.debug(
                    'Fetched message from peer "' +
                    dump.PeerToString(D.PeerIP, D.PeerAS) + '": ' +
                    binascii.hexlify(D.RawMessageData)
                )
                connection = peers.get_connection((D.PeerIP, D.PeerAS))
                connection.send(D.RawMessageData)
                P = None
            if P is None:
                connection = peers.get_connection((D.PeerIP, D.PeerAS))
        if P is not None:
            logger.debug(
                "Fetched unsupported packet with type " + str(H.Type) +
                ", subtype " + str(H.SubType) + " and data: " +
                binascii.hexlify(P.RawData)
            )


if __name__ == "__main__":
    main()
