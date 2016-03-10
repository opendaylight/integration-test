import binascii
import fileio
import dump


OPEN_CAPABILITIES = 2

CAP_MULTIPROTO = 1
CAP_AS4 = 65
CAP_ROUTE_REFRESH = 2
CAP_GRACEFUL_RESTART = 64
CAP_ROUTE_REFRESH_ENHANCED = 70


class TMessageBase:

    def __init__(s, Marker, Type, Length, Garbage):
        s.Marker = Marker
        s.Type = Type
        s.Length = Length
        s.Garbage = Garbage

    def ReadData(s, InF):
        s.Data = InF.ReadToEnd()

    def WriteContent(s, OutF):
        OutF.Write(s.Data)

    def WriteData(s, OutF):
        S = fileio.CreateString()
        s.WriteContent(S)
        S = S.ToString()
        OutF.Write(s.Marker)
        OutF.Write16(len(S) + 19)
        OutF.Write8(s.Type)
        OutF.Write(S)

    def AddNameReport(s, Report):
        Report.append("!UNKNOWN{" + str(s.Type) + "}")

    def AddValueReport(s, Report):
        if s.Data != "":
            Report.append("DATA:" + binascii.hexlify(s.Data))


class TOpenParameter:

    def __init__(s, Type, Length, InF):
        s.Type = Type
        s.Length = Length
        s.ReadValue(InF)

    def ReadValue(s, F):
        s.Value = F.Read(s.Length)

    def WriteValue(s, F):
        F.Write(s.Value)

    def GetTypeReport(s):
        return "!UNKNOWN{" + str(s.Type) + "}"

    def GetValueReport(s):
        return binascii.hexlify(s.Value)

    def GetDataReport(s):
        Type = s.GetTypeReport()
        Value = s.GetValueReport()
        return Type + "[" + Value + "]"


class TCapability:

    def __init__(s, Type, Length, F):
        s.Type = Type
        s.Length = Length
        s.Garbage = None
        s.ReadValue(F)

    def ReadValue(s, F):
        s.Value = F.Read(s.Length)

    def WriteValue(s, F):
        F.Write(s.Value)

    def GetTypeReport(s):
        return "!UNKNOWN{" + str(s.Type) + "}"

    def GetValueReport(s):
        return binascii.hexlify(s.Value)


class TPrivate(TCapability):

    def GetTypeReport(s):
        return "PRIVATE(" + str(s.Type) + ")"


class TRouteRefresh(TCapability):

    def GetTypeReport(s):
        return "ROUTEREFRESH"


class TRouteRefreshEnhanced(TCapability):

    def GetTypeReport(s):
        return "ROUTEREFRESHENHANCED"


class TGracefulRestart(TCapability):

    def GetTypeReport(s):
        return "GRACEFULRESTART"


class TAS4(TCapability):

    def ReadValue(s, F):
        if s.Length != 4:
            s.Value = None
            s.Garbage = F.Read(s.Length)
            return
        s.Value = F.Read32()

    def WriteValue(s, F):
        F.Write32(s.Value)

    def GetTypeReport(s):
        return "AS4"

    def GetValueReport(s):
        return str(s.Value)


class TMultiProto(TCapability):

    def ReadValue(s, F):
        if s.Length != 4:
            s.Garbage = F.Read(s.Length)
            return
        s.AFI = F.Read16()
        s.Reserved = F.Read8()
        s.SAFI = F.Read8()

    def WriteValue(s, F):
        if s.Garbage is None:
            F.Write16(s.AFI)
            F.Write8(s.Reserved)
            F.Write8(s.SAFI)

    def GetTypeReport(s):
        return "MULTIPROTO"

    def GetValueReport(s):
        Report = []
        Report.append("AFI:" + dump.TranslateAFI(s.AFI))
        if s.Reserved != 0:
            Report.append("!RESERVED{" + str(s.Reserved) + "}")
        Report.append("SAFI:" + dump.TranslateSAFI(s.SAFI))
        return "[" + ", ".join(Report) + "]"


class TCapabilities(TOpenParameter):

    def ReadValue(s, F):
        s.List = []
        while F.GetLengthToRead() > 0:
            Type = F.Read8()
            Length = F.Read8()
            if Type >= 128:
                C = TPrivate(Type, Length, F)
            elif Type == CAP_AS4:
                C = TAS4(Type, Length, F)
            elif Type == CAP_MULTIPROTO:
                C = TMultiProto(Type, Length, F)
            elif Type == CAP_ROUTE_REFRESH:
                C = TRouteRefresh(Type, Length, F)
            elif Type == CAP_ROUTE_REFRESH_ENHANCED:
                C = TRouteRefreshEnhanced(Type, Length, F)
            elif Type == CAP_GRACEFUL_RESTART:
                C = TGracefulRestart(Type, Length, F)
            else:
                C = TCapability(Type, Length, F)
            s.List.append(C)

    def WriteValue(s, F):
        for C in s.List:
            F.Write8(C.Type)
            S = fileio.CreateString()
            C.WriteValue(S)
            if C.Garbage is not None:
                S.Write(C.Garbage)
            S = S.ToString()
            F.Write8(len(S))
            F.Write(S)

    def GetTypeReport(s):
        return "CAPABILITIES"

    def GetValueReport(s):
        Report = []
        for Capability in s.List:
            Data = Capability.GetTypeReport()
            Value = Capability.GetValueReport()
            if Value != "":
                Data += ":" + Value
            Report.append(Data)
        return ", ".join(Report)


class TOpenMessage(TMessageBase):

    def ReadData(s, F):
        s.Version = F.Read8()
        s.AS = F.Read16()
        s.HoldTime = F.Read16()
        s.BGPID = F.Read32()
        s.Parameters = []
        Length = F.Read8()
        Data = F.Read(Length)
        F = fileio.OpenString(Data)
        while F.GetLengthToRead() > 0:
            Type = F.Read8()
            Length = F.Read8()
            Data = F.Read(Length)
            InF = fileio.OpenString(Data)
            if Type == OPEN_CAPABILITIES:
                Factory = TCapabilities
            else:
                Factory = TOpenParameter
            P = Factory(Type, Length, InF)
            s.Parameters.append(P)

    def WriteContent(s, F):
        F.Write8(s.Version)
        F.Write16(s.AS)
        F.Write16(s.HoldTime)
        F.Write32(s.BGPID)
        PS = fileio.CreateString()
        for P in s.Parameters:
            PS.Write8(P.Type)
            S = fileio.CreateString()
            P.WriteValue(S)
            S = S.ToString()
            PS.Write8(len(S))
            PS.Write(S)
        PS = PS.ToString()
        F.Write8(len(PS))
        F.Write(PS)

    def AddNameReport(s, Report):
        Report.append("OPEN")

    def AddValueReport(s, Report):
        Report.append("VERSION:" + str(s.Version))
        Report.append("AS:" + str(s.AS))
        HoldTimer = "Disabled"
        if s.HoldTime != 0:
            HoldTimer = str(s.HoldTime)
        Report.append("HOLDTIME:" + HoldTimer)
        BGPID = dump.PrefixToString(s.BGPID, None)
        Report.append("BGPID:" + BGPID)
        for Parameter in s.Parameters:
            Data = Parameter.GetDataReport()
            Report.append(Data)


class TUpdateMessage(TMessageBase):

    def AddNameReport(s, Report):
        Report.append("UPDATE")


class TNotificationMessage(TMessageBase):

    def AddNameReport(s, Report):
        Report.append("NOTIFY")


class TKeepAliveMessage(TMessageBase):

    def AddNameReport(s, Report):
        Report.append("KEEPALIVE")


MT_OPEN = 1
MT_UPDATE = 2
MT_NOTIFY = 3
MT_KEEPALIVE = 4
KnownMessageTypes = {
    MT_OPEN: TOpenMessage,
    MT_UPDATE: TUpdateMessage,
    MT_NOTIFY: TNotificationMessage,
    MT_KEEPALIVE: TKeepAliveMessage,
}


def ParseMessage(Data):
    InF = fileio.OpenString(Data)
    Marker = InF.Read(16)
    Size = InF.Read16()
    Type = InF.Read8()
    Data = InF.Read(Size - 19)
    Garbage = InF.ReadToEnd()
    InF = fileio.OpenString(Data)
    if Type in KnownMessageTypes:
        Reader = KnownMessageTypes[Type]
    else:
        Reader = TMessageBase
    Object = Reader(Marker, Type, Size, Garbage)
    Object.ReadData(InF)
    return Object
