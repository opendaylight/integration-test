"""MRT Replay Data Preparator Program

This program prepares MRT data and Restconf configuration from raw data
downloaded from an Internet Archive Site.

The program takes as an input a MRT file or a directory full of MRT files
and generates 2 outputs: The consolidated MRT file that can be passed to
play.py and a set of files with a set of BGP peer configurations to be upload
into the ODL being tested (most likely via a Restconf request).
"""


import argparse
import sys
import fileio
import bgp
import mrt


def IPToInt(IP):
    Splitted=IP.split(".")
    if len(Splitted)!=4:
        raise ValueError("Too many IP address components")
    for i in range(4):
        Item=int(Splitted[i])
        if Item<0 or Item>255:
            raise ValueError("IP address component not in 0-255 range")
        Splitted[i]=Item
    IP=Splitted[0]*256+Splitted[1]
    IP=IP*65536+Splitted[2]*256+Splitted[3]
    return IP


def peer_specification(peer):
    splitted = peer.split("-")
    if len(splitted) != 2:
        raise ValueError("Wrong count of '-' separated components")
    peer_ip = IPToInt(splitted[0])
    try:
        peer_as = int(splitted[1])
    except ValueError:
        raise ValueError("The AS number is not a valid number")
    if peer_as < 0 or peer_as > 0xFFFFFFFF:
        raise ValueError("The AS number is outside of allowed range")
    return peer_ip, peer_as


def parse_arguments():
    """Use argparse to get arguments,

    Returns:
        :return: args object.
    """
    description = (
        "Cleanup and package raw data feeds for use with the feed replayer "
        '(the program "replay.py").'
    )
    parser = argparse.ArgumentParser(description=description)
    str_help = (
        "Raw data source to be processed. This can either be a file or a "
        "directory. If it is a directory, all the files contained therein "
        "are sorted according to their names, concatenated together in "
        "that sorted order and the result used as the raw data source. "
        "The files can be uncompressed or compressed with gzip or bzip2 "
        "(the compression format is detected automatically)."
    )
    parser.add_argument(
        "--source", default="rawfeed.gz",
        type=str, dest="source", help=str_help
    )
    str_help = (
        "Name of the file where the processed result will be written."
    )
    parser.add_argument(
        "--output", default="feed.gz",
        type=str, dest="output", help=str_help
    )
    str_help = (
        "Timestamp to be used in the resulting gzip header expressed as "
        "the number of seconds since the Epoch. Default is no timestamp."
    )
    parser.add_argument(
        "--timestamp", default="0",
        type=int, dest="time", help=str_help
    )
    group = parser.add_mutually_exclusive_group()
    str_help = (
        "Specify peers to be included in the resulting output. The peers "
        "are specified in the format <ip>-<as>. All other peers present "
        "in the input are left out of the output."
    )
    group.add_argument(
        "--include", metavar="PEER", nargs="+",
        type=peer_specification, dest="include", help=str_help
    )
    str_help = (
        "Specify peers to be excluded in the resulting output. The peers "
        "are specified in the format <ip>-<as>. All peers that are not "
        "listed here will be included in the resulting file."
    )
    group.add_argument(
        "--exclude", metavar="PEER", nargs="+",
        type=peer_specification, dest="exclude", help=str_help
    )
    arguments = parser.parse_args()
    return arguments


def FilterOpenMessage(M):
    Params = M.Parameters
    M.Parameters = []
    # Throw away "route refresh" capabilities if any are present.
    # The player does not support "route refresh" at all.
    UnwantedCapabilities = (
        bgp.CAP_ROUTE_REFRESH,
        bgp.CAP_ROUTE_REFRESH_ENHANCED,
    )
    for Param in Params:
        KeepParameter = True
        if Param.Type == bgp.OPEN_CAPABILITIES:
            List = Param.List
            Param.List = []
            for Capability in List:
                if Capability.Type not in UnwantedCapabilities:
                    Param.List.append(Capability)
            KeepParameter = len(Param.List) > 0
        if KeepParameter:
            M.Parameters.append(Param)


class TQueue:

    def __init__(s):
        s.Input = []
        s.Output = []

    def Put(s, Item):
        s.Input.append(Item)

    def Get(s):
        if len(s.Output) == 0:
            Temp = s.Input
            s.Input = s.Output
            Temp.reverse()
            s.Output = Temp
        return s.Output.pop()

    def Return(s, Item):
        s.Output.append(Item)

    def __iter__(s):
        for Item in s.Input:
            yield Item
        for Item in s.Output:
            yield Item

    def GetLength(s):
        return len(s.Input) + len(s.Output)


class TPacketQueue:

    def __init__(s, Writer):
        s.Writer = Writer
        s.Queue = TQueue()
        s.Peers = {}
        s.UndecidedPeers = {}
        s.LocalIP = 0
        s.LocalAS = 0

    def UpdateLocalAddresses(s):
        if s.LocalIP == 0 or s.LocalIP == 0:
            return
        for Packet in s.Queue:
            Packet.Data.LocalIP = s.LocalIP
            Packet.Data.LocalAS = s.LocalAS

    def EmitDecidedPackets(s):
        Packet = None
        while s.Queue.GetLength() > 0:
            Packet = s.Queue.Get()
            D = Packet.Data
            if D.LocalIP == 0 or D.LocalAS == 0:
                break
            if D.PeerIP == 0 or D.PeerAS == 0:
                break
            s.Writer.PutNextPacket(Packet)
            Packet = None
        if Packet is not None:
            s.Queue.Return(Packet)

    def PutNextPacket(s, P):
        s.Queue.Put(P)
        D = P.Data
        if s.LocalIP == 0:
            s.LocalIP = D.LocalIP
            s.UpdateLocalAddresses()
        if s.LocalAS == 0:
            s.LocalAS = D.LocalAS
            s.UpdateLocalAddresses()
        D.LocalIP = s.LocalIP
        D.LocalAS = s.LocalAS
        if D.PeerIP not in s.Peers:
            if D.PeerAS == 0:
                if D.PeerIP not in s.UndecidedPeers:
                    List = []
                    s.UndecidedPeers[D.PeerIP] = List
                else:
                    List = s.UndecidedPeers[D.PeerIP]
                List.append(P)
            else:
                s.Peers[D.PeerIP] = D.PeerAS
                if D.PeerIP in s.UndecidedPeers:
                    List = s.UndecidedPeers[D.PeerIP]
                    del s.UndecidedPeers[D.PeerIP]
                    for Packet in List:
                        Packet.PeerAS = D.PeerAS
        else:
            D.PeerAS = s.Peers[D.PeerIP]
        s.EmitDecidedPackets()


class TPacketReporter:

    def __init__(s, Writer):
        s.Writer = Writer

    def PutNextPacket(s, P):
        print "%08X  " % P.Position, P.DataReport()
        s.Writer.PutNextPacket(P)


class TPacketFilter:

    def __init__(self, writer, peerlist, exclude):
        self.writer = writer
        self.peerlist = peerlist
        self.exclude = exclude

    def PutNextPacket(self, P):
        D = P.Data
        emit = False
        for peer_ip, peer_as in self.peerlist:
            if D.PeerIP == peer_ip and D.PeerAS == peer_as:
                emit = True
                break
        if self.exclude:
            emit = not emit
        if emit:
            self.writer.PutNextPacket(P)


if __name__ == "__main__":
    arguments = parse_arguments()
    InF = fileio.TFileReader(arguments.source)
    OutF = open(arguments.output, "w")
    Time = arguments.time
    OutF = fileio.TGzipFileWriter(OutF, Time)
    Reader = mrt.TMRTReader(InF)
    Writer = fileio.TFileWriter(OutF)
    Writer = mrt.TMRTWriter(Writer)
    Writer = TPacketReporter(Writer)
    if len(arguments.include)>0:
        Writer = TPacketFilter(Writer, arguments.include, False)
    elif len(arguments.exclude)>0:
        Writer = TPacketFilter(Writer, arguments.exclude, True)
    Writer = TPacketQueue(Writer)
    while True:
        Start = InF.BytesRead
        P = Reader.GetNextPacket()
        if P is None:
            break
        P.Position = Start
        H = P.H
        if H.Type != mrt.BGP4MP:
            continue
        WantedSubTypes = (
            mrt.BGP4MP_STATE_CHANGE, mrt.BGP4MP_MESSAGE,
            mrt.BGP4MP_STATE_CHANGE_AS4, mrt.BGP4MP_MESSAGE_AS4,
        )
        if H.SubType not in WantedSubTypes:
            continue
        if P.Data.AddressFamily != mrt.AFI_IPv4:
            continue
        if H.SubType in (mrt.BGP4MP_MESSAGE, mrt.BGP4MP_MESSAGE_AS4):
            Message = P.Data.Data
            if Message.Type == bgp.MT_OPEN:
                FilterOpenMessage(Message)
        Writer.PutNextPacket(P)
    InF.close()
    OutF.close()
