import os
import stat
import bz2
import gzip
import cStringIO as StringIO

BZ2_MAGIC = '\x42\x5a\x68'
GZIP_MAGIC = '\x1f\x8b'


class TFileInfo:

    def __init__(s):
        s.Opener = None
        s.InF = None
        s.Name = None
        s.TimeStamp = None


def AnalyzeDiskFile(FileName):
    Name = None
    TimeStamp = None
    InF = file(FileName, 'rb')
    Hdr = InF.read(max(len(BZ2_MAGIC), len(GZIP_MAGIC)))
    Opener = None
    if FileName.endswith('.bz2') and Hdr.startswith(BZ2_MAGIC):
        Opener = bz2.BZ2File
    elif FileName.endswith('.gz') and Hdr.startswith(GZIP_MAGIC):
        Opener = gzip.GzipFile
        Hdr += InF.read(7)
        TimeStamp = ord(Hdr[4]) + 256 * ord(Hdr[5])
        TimeStamp += 65536 * (ord(Hdr[6]) + 256 * ord(Hdr[7]))
        Flags = ord(Hdr[3])
        if Flags & 0x04 != 0:
            Size = InF.read(2)
            Size = ord(Size[0]) + 256 * ord(Size[1])
            InF.read(Size)
        if Flags & 0x08 != 0:
            Name = ""
            while True:
                Ch = InF.read(1)
                if Ch in ("", "\x00"):
                    break
                Name += Ch
    if Opener is not None:
        InF.close()
        InF = None
    else:
        InF.seek(0)
    return Opener, InF, Name, TimeStamp


def OpenDiskFile(FileName):
    I = TFileInfo()
    Opener, I.InF, I.Name, I.TimeStamp = AnalyzeDiskFile(FileName)
    if Opener is not None:
        I.InF = Opener(FileName, 'rb')
    return I


class TFileReader:

    def __init__(s, I):
        s.CurrentFile = 0
        if not isinstance(I, TFileInfo):
            Spec = I
            Stat = os.stat(I)
            if stat.S_ISDIR(Stat.st_mode):
                List = os.listdir(Spec)
                List.sort()
                s.FileList = []
                if Spec[-1] != "/":
                    Spec += "/"
                for File in List:
                    s.FileList.append(Spec + File)
            elif stat.S_ISREG(Stat.st_mode):
                s.FileList = [Spec]
            else:
                raise IOError("Unsupported file type")
            s.InF = None
        else:
            s.InF = I.InF
            s.FileList = []
        s.BytesRead = 0
        s.EofHit = False

    def close(s):
        if s.InF is not None:
            s.InF.close()
        del s.InF

    def GetLengthToRead(s):
        return s.Size - s.BytesRead

    def RawRead(s, Size):
        if s.EofHit:
            return ""
        Result = []
        while Size > 0:
            if s.InF is None:
                if s.CurrentFile == len(s.FileList):
                    s.EofHit = True
                    break
                FileSpec = s.FileList[s.CurrentFile]
                s.CurrentFile += 1
                I = OpenDiskFile(FileSpec)
                s.InF = I.InF
            Data = s.InF.read(Size)
            if Data == "":
                s.InF.close()
                s.InF = None
            else:
                Size -= len(Data)
                Result.append(Data)
        Data = "".join(Result)
        s.BytesRead += len(Data)
        return Data

    def ReadToEnd(s):
        Result = []
        while True:
            Data = s.RawRead(8192)
            if Data == "":
                break
            Result.append(Data)
        return "".join(Result)

    def Read(s, Length):
        Data = s.RawRead(Length)
        if len(Data) != Length:
            raise IndexError("Attempt to read past end of file")
        return Data

    def Read8(s):
        Data = s.Read(1)
        return ord(Data[0])

    def Read16(s):
        Data = s.Read(2)
        return ord(Data[0]) * 256 + ord(Data[1])

    def Read32(s):
        High = s.Read16()
        Low = s.Read16()
        return Low + High * 65536


def OpenString(Data):
    Len = len(Data)
    I = TFileInfo()
    I.InF = StringIO.StringIO(Data)
    F = TFileReader(I)
    F.Size = Len
    return F


class TGzipFileWriter:

    def __init__(s, OutF, MTime, Level=9):
        s.OF = OutF
        OutF = gzip.GzipFile(
            filename="",
            fileobj=OutF,
            mode="w",
            compresslevel=Level,
            mtime=MTime
        )
        s.write = OutF.write
        s.Finish = OutF.close

    def close(s):
        del s.write
        s.Finish()
        del s.Finish
        s.OF.close()
        del s.OF


class TFileWriter:

    def __init__(s, OutF):
        s.RawWrite = OutF.write
        s.Close = OutF.close
        s.Size = 0

    def Write(s, Data):
        s.RawWrite(Data)
        s.Size += len(Data)

    def Write8(s, Value):
        s.Write(chr(Value))

    def Write16(s, Value):
        s.Write8(Value / 256)
        s.Write8(Value % 256)

    def Write32(s, Value):
        s.Write16(Value / 65536)
        s.Write16(Value % 65536)


def CreateString():
    OutF = StringIO.StringIO()
    Result = TFileWriter(OutF)
    Result.ToString = OutF.getvalue
    return Result
