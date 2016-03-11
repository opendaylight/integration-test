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
        format="%(asctime)s|%(name)10s|%(funcName)10s|%(message)s"
    )


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
    bgpstream.add_bgp_connection_arguments(parser)
    add_logging_arguments(parser)
    arguments = parser.parse_args()
    configure_logging(arguments)
    return arguments


def main():
    logger = logging.getLogger("main")
    arguments = parse_arguments()
    configure_logging(arguments)
    logger.info("Starting the feed data replay")
    try:
        F = fileio.TFileReader(arguments.feedfile)
    except EnvironmentError:
        logger.exception("Could not open the feed file")
        print "Could not open the feed file"
        raise SystemExit(1)
    logger.info("Opened feed file: " + arguments.feedfile)
    reader = mrt.TMRTReader(F)
    StateChange = (mrt.BGP4MP_STATE_CHANGE, mrt.BGP4MP_STATE_CHANGE_AS4)
    Message = (mrt.BGP4MP_MESSAGE, mrt.BGP4MP_MESSAGE_AS4)
    while True:
        P = reader.GetNextPacket()
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
                P = None
            elif H.SubType in Message:
                logger.debug(
                    'Fetched message from peer "' +
                    dump.PeerToString(D.PeerIP, D.PeerAS) + '": ' +
                    binascii.hexlify(D.RawMessageData)
                )
                P = None
        if P is not None:
            logger.debug(
                "Fetched unsupported packet with type " + str(H.Type) +
                ", subtype " + str(H.SubType) + " and data: " +
                binascii.hexlify(P.RawData)
            )


if __name__ == "__main__":
    main()
