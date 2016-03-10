import binascii
import dthandle
import fileio
import dump
import bgp


# MRT Header
MRT_HEADER_LEN = 12


# AFIs
AFI_IPv4 = 1
AFI_IPv6 = 2


# BGP4MP record types
BGP4MP = 16
BGP4MP_STATE_CHANGE = 0
BGP4MP_MESSAGE = 1
BGP4MP_MESSAGE_AS4 = 4
BGP4MP_STATE_CHANGE_AS4 = 5
BGP4MPSubTypes = {
    BGP4MP_STATE_CHANGE: "STATE_CHANGE",
    BGP4MP_MESSAGE: "MESSAGE",
    BGP4MP_MESSAGE_AS4: "MESSAGE_AS4",
    BGP4MP_STATE_CHANGE_AS4: "STATE_CHANGE_AS4",
}


# BGP4MP_STATE_CHANGE states
ST_IDLE = 1
ST_CONNECT = 2
ST_ACTIVE = 3
ST_OPENSENT = 4
ST_OPENCONFIRM = 5
ST_ESTABLISHED = 6
States = {
    ST_IDLE: "Idle",
    ST_CONNECT: "Connect",
    ST_ACTIVE: "Active",
    ST_OPENSENT: "OpenSent",
    ST_OPENCONFIRM: "OpenConfirm",
    ST_ESTABLISHED: "Established",
    7: "Error",
    8: "OpenRejected",
}


# MRT Types (see RFC6396, sections 4 and 5.3)
# Only BGP4MP is supported by this tool right now but it is nice to see what
# type of unsupported packet we are dealing with so all types are listed
# here.
Types = {
    0: "NULL",
    1: "START",
    2: "DIE",
    3: "I_AM_DEAD",
    4: "PEER_DOWN",
    5: "BGP",                   # Deprecated by BGP4MP
    6: "RIP",
    7: "IDRP",
    8: "RIPNG",
    9: "BGP4PLUS",                # Deprecated by BGP4MP
    10: "BGP4PLUS_01",            # Deprecated by BGP4MP
    11: "OSPFv2",
    12: "TABLE_DUMP",
    13: "TABLE_DUMP_V2",
    BGP4MP: "BGP4MP",
    17: "BGP4MP_ET",
    32: "ISIS",
    33: "ISIS_ET",
    64: "OSPF_ET",
}


class TMRTHeader:

    def __init__(s, F):
        if isinstance(F, TMRTHeader):
            TimeStamp = F.TimeStamp
            Type = F.Type
            SubType = F.SubType
            Length = F.Length
        else:
            TimeStamp = F.Read32()
            Type = F.Read16()
            SubType = F.Read16()
            Length = F.Read32()
        s.TimeStamp = TimeStamp
        s.Type = Type
        s.SubType = SubType
        s.Length = Length

    def WriteData(s, F):
        F.Write32(s.TimeStamp)
        F.Write16(s.Type)
        F.Write16(s.SubType)
        F.Write32(s.Length)

    def HeaderReport(s):
        if s.Type in Types:
            Type = Types[s.Type]
        else:
            Type = "!TYPE{" + str(s.Type) + ", " + str(s.SubType) + "}"
        SubType = None
        SubTypes = None
        if s.Type == BGP4MP:
            SubTypes = BGP4MPSubTypes
        if SubTypes is None:
            if s.SubType == 0:
                SubType = ""
        else:
            if s.SubType in SubTypes:
                SubType = " " + SubTypes[s.SubType]
        if SubType is None:
            SubType = " !SUBTYPE{" + str(s.SubType) + "}"
        return Type + SubType


class TBGP4MPBase:

    def ReadASNumbers(s, F):
        if s.AS32Bit:
            ASReader = F.Read32
        else:
            ASReader = F.Read16
        s.PeerAS = ASReader()
        s.LocalAS = ASReader()

    def ReadAddressData(s, F):
        s.InterfaceIndex = F.Read16()
        s.AddressFamily = F.Read16()
        if s.AddressFamily == AFI_IPv4:
            s.PeerIP = F.Read32()
            s.LocalIP = F.Read32()
        elif s.AddressFamily == AFI_IPv6:
            s.PeerIP = F.Read(16)
            s.LocalIP = F.Read(16)

    def ReadCommonFields(s, F, AS32Bit):
        s.AS32Bit = AS32Bit
        s.ReadASNumbers(F)
        s.ReadAddressData(F)

    def WriteASNumbers(s, F):
        if s.AS32Bit:
            ASWriter = F.Write32
        else:
            ASWriter = F.Write16
        ASWriter(s.PeerAS)
        ASWriter(s.LocalAS)

    def WriteAddressData(s, F):
        F.Write16(s.InterfaceIndex)
        F.Write16(s.AddressFamily)
        if s.AddressFamily == AFI_IPv4:
            F.Write32(s.PeerIP)
            F.Write32(s.LocalIP)
        elif s.AddressFamily == AFI_IPv6:
            F.Write(s.PeerIP)
            F.Write(s.LocalIP)

    def WriteCommonFields(s, F):
        s.WriteASNumbers(F)
        s.WriteAddressData(F)

    def AddCommonFieldsReport(s, Report):
        if s.AddressFamily == AFI_IPv4:
            Report.append("IPv4")
        elif s.AddressFamily == AFI_IPv6:
            Report.append("IPv6")
        else:
            Report.append("!AFI{" + str(s.AddressFamily) + "}")
        Local = dump.PeerToString(s.LocalIP, s.LocalAS)
        Report.append("LOCAL:" + Local)
        Peer = dump.PeerToString(s.PeerIP, s.PeerAS)
        Report.append("PEER:" + Peer)
        if s.InterfaceIndex != 0:
            Report.append("!IFACE{" + str(s.InterfaceIndex) + "}")


class TBGP4MPStateChangeBase(TBGP4MPBase):

    def Initialize(s, F, LongAS):
        s.ReadCommonFields(F, LongAS)
        s.OldState = F.Read16()
        s.NewState = F.Read16()

    def WriteData(s, F):
        s.WriteCommonFields(F)
        F.Write16(s.OldState)
        F.Write16(s.NewState)

    def DataReport(s):
        Report = []
        s.AddCommonFieldsReport(Report)
        Report.append("OLD:" + dump.TranslateState(s.OldState))
        Report.append("NEW:" + dump.TranslateState(s.NewState))
        return ", ".join(Report)


class TBGP4MPStateChange(TBGP4MPStateChangeBase):

    def __init__(s, F):
        s.Initialize(F, False)


class TBGP4MPStateChangeAS4(TBGP4MPStateChangeBase):

    def __init__(s, F):
        s.Initialize(F, True)


class TBGP4MPMessageBase(TBGP4MPBase):

    def Initialize(s, F, LongAS):
        s.LocalIP = 0x6F6F6F6F
        s.LocalAS = 11111
        s.PeerIP = 0x6F6F6F6F
        s.PeerAS = 11111
        s.ReadCommonFields(F, LongAS)
        Data = F.ReadToEnd()
        s.Data = bgp.ParseMessage(Data)

    def WriteData(s, F):
        s.WriteCommonFields(F)
        if isinstance(s.Data, str):
            F.Write(s.Data)
        else:
            s.Data.WriteData(F)

    def DataReport(s):
        Report = []
        s.AddCommonFieldsReport(Report)
        s.Data.AddNameReport(Report)
        s.Data.AddValueReport(Report)
        if s.Data.Marker != 16 * "\xFF":
            Marker = binascii.hexlify(s.Marker)
            Report.append("!MARKER{" + Marker + "}")
        if s.Data.Garbage is not None and s.Data.Garbage != "":
            Garbage = binascii.hexlify(s.Data.Garbage)
            Report.append("!GARBAGE{" + Garbage + "}")
        return ", ".join(Report)


class TBGP4MPMessage(TBGP4MPMessageBase):

    def __init__(s, F):
        s.Initialize(F, False)


class TBGP4MPMessageAS4(TBGP4MPMessageBase):

    def __init__(s, F):
        s.Initialize(F, True)


class TMRTPacket:

    def __init__(s, H):
        s.H = H
        s.Data = None

    def FetchDataPortion(s, F):
        s.Data = F.Read(s.H.Length)

    def ReadData(s):
        H = s.H
        I = fileio.OpenString(s.Data)
        s.Garbage = None
        try:
            D = None
            Type = s.H.Type
            if Type is None:
                Type = H.Type
            if Type == BGP4MP:
                if H.SubType == BGP4MP_STATE_CHANGE:
                    D = TBGP4MPStateChange(I)
                elif H.SubType == BGP4MP_MESSAGE:
                    D = TBGP4MPMessage(I)
                elif H.SubType == BGP4MP_STATE_CHANGE_AS4:
                    D = TBGP4MPStateChangeAS4(I)
                elif H.SubType == BGP4MP_MESSAGE_AS4:
                    D = TBGP4MPMessageAS4(I)
            if D is None:
                raise IndexError
            Len = I.GetLengthToRead()
            if Len != 0:
                s.Garbage = I.Read(Len)
        except IndexError:
            D = s.Data
        s.Data = D

    def WriteData(s, OutF):
        S = s.Data
        if not isinstance(S, str):
            S = fileio.CreateString()
            s.Data.WriteData(S)
            S = S.ToString()
        s.H.Length = len(S)
        s.H.WriteData(OutF)
        OutF.Write(S)

    def DataReport(s):
        H = s.H
        if H is not Ellipsis:
            Line = dthandle.FormatDateTime(H.TimeStamp) + "  "
            Type = H.HeaderReport()
            Line += Type
        else:
            Line = " "
        D = s.Data
        if D is not None:
            if isinstance(D, str):
                Data = "DATA:" + binascii.hexlify(D)
            else:
                Data = D.DataReport()
            Line += " " + Data
        return Line


class TMRTReader:

    def __init__(s, InF):
        s.InF = InF

    def GetNextPacket(s):
        try:
            H = TMRTHeader(s.InF)
            P = TMRTPacket(H)
            P.FetchDataPortion(s.InF)
            P.ReadData()
        except IndexError:
            P = None
        return P


class TMRTWriter:

    def __init__(s, OutF):
        s.OutF = OutF

    def PutNextPacket(s, P):
        P.WriteData(s.OutF)
