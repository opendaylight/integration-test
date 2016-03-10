"""MRT Replay Data Preparator Program

This program prepares MRT data and Restconf configuration from raw data
downloaded from an Internet Archive Site.

The program takes as an input a MRT file or a directory full of MRT files
and generates 2 outputs: The consolidated MRT file that can be passed to
play.py and a set of files with a set of BGP peer configurations to be upload
into the ODL being tested (most likely via a Restconf request).
"""


import sys
import fileio
import bgp
import mrt


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
            Packet.LocalIP = s.LocalIP
            Packet.LocalAS = s.LocalAS

    def EmitDecidedPackets(s):
        Packet = None
        while s.Queue.GetLength() > 0:
            Packet = s.Queue.Get()
            D = Packet.Data
            if D.LocalIP != 0 and D.LocalAS != 0:
                if D.PeerIP != 0 and D.PeerAS != 0:
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


if __name__ == "__main__":
    InF = fileio.TFileReader(sys.argv[1])
    OutF = open(sys.argv[2], "w")
    Time = 0
    if len(sys.argv) > 3:
        Time = int(sys.argv[3])
    OutF = fileio.TGzipFileWriter(OutF, Time)
    Reader = mrt.TMRTReader(InF)
    Writer = fileio.TFileWriter(OutF)
    Writer = mrt.TMRTWriter(Writer)
    Writer = TPacketReporter(Writer)
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
