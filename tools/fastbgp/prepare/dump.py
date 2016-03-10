import mrt


def PrefixToString(Prefix, Length):
    if Length is None:
        LengthStr = ""
        Length = 32
    else:
        LengthStr = "/" + str(Length)
    Bytes = []
    if isinstance(Prefix, int):
        InvalidBits = 0
        if Length < 32:
            Mask = 1 << (32 - Length)
            Mask -= 1
            InvalidBits = Prefix & Mask
        if InvalidBits == 0:
            InvalidBits = None
        else:
            InvalidBits = "%X" % InvalidBits
        for i in range(4):
            Bytes.append(str(Prefix & 255))
            Prefix /= 256
        Bytes.reverse()
        Delimiter = "."
        if Length < 25:
            Bytes.pop()
        if Length < 17:
            Bytes.pop()
        if Length < 9:
            Bytes.pop()
    else:
        for Index in range(0, 16, 2):
            Word = ord(Prefix[Index]) * 256 + ord(Prefix[Index + 1])
            Bytes.append("%X" % Word)
        IndexStart = 0
        IndexEnd = 0
        for Start in range(8):
            if Bytes[Start] == "0":
                End = Start
                while End < 8 and Bytes[End] == "0":
                    End += 1
                if End - Start >= IndexEnd - IndexStart:
                    IndexStart = Start
                    IndexEnd = End
        if IndexStart < IndexEnd:
            Bytes[IndexStart:IndexEnd] = [""]
        Delimiter = ":"
        InvalidBits = None
    Result = Delimiter.join(Bytes) + LengthStr
    if InvalidBits is not None:
        Result += "!INVALIDBITS{" + InvalidBits + "}"
    return Result


def PeerToString(IP, AS):
    return "IP=" + PrefixToString(IP, None) + ",AS=" + str(AS)


def get_peer_name(peer):
    return PrefixToString(peer[0], None) + "-" + str(peer[1])


AFIs = {
    1: "IPv4",
    2: "IPv6",
    3: "NSAP",
    4: "HDLC",
    5: "BBN1822",
    6: "802",
    7: "E.163",
    8: "E.164(SMDS/Relay/ATM)",
    9: "F.69",
    10: "X.121",
    11: "IPX",
    12: "AppleTalk",
    13: "DecnetIV",
    14: "BanyanVines",
    15: "E.164(NSAP)",
    16: "DNS",
    17: "DN",
    18: "AS",
    19: "XTP/IPv4",
    20: "XTP/IPv6",
    21: "XTP",
    22: "FibrePortName",
    23: "FibreNodeName",
    24: "GWID",
    25: "L2VPN",
    26: "MPLS-TP/Section",
    27: "MPLS-TP/LSP",
    28: "MPLS-TP/Pseudowire",
    29: "MT:IPv4",
    30: "MT:IPv6",
}
SAFIs = {
    1: "Unicast",
    2: "Multicast",
    3: "Unicast+Multicast",
}


def Translate(Name, Value, ValidValues):
    if Value in ValidValues:
        return ValidValues[Value]
    else:
        return "!" + Name + "{" + str(Value) + "}"


def TranslateState(State):
    return Translate("STATE", State, mrt.States)


def TranslateAFI(AFI):
    return Translate("AFI", AFI, AFIs)


def TranslateSAFI(SAFI):
    return Translate("SAFI", SAFI, SAFIs)
