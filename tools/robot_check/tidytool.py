import difflib
import os
import sys
import stat
import robot.tidy


def Error(FileSpec, Message):
    global ErrorsReported
    print "File", FileSpec + ":", Message
    ErrorsReported = True


def traverse_and_process(DirList, Processor):
    """Traverse the directory and process all .robot files found"""
    Stack = []
    for Dir in DirList:
        if Dir[-1] == "/":
            Dir = Dir[:-1]
        Stack.append(Dir)
    while len(Stack) > 0:
        Dir = Stack.pop() + "/"
        try:
            List = os.listdir(Dir)
        except (IOError, OSError), e:
            Error(Dir, "Directory not accessible: " + str(e))
            continue
        for Item in List:
            Spec = Dir + Item
            Stat = os.stat(Spec)
            if stat.S_ISDIR(Stat.st_mode):
                Stack.append(Spec)
            elif Item.endswith(".robot"):
                Processor(Spec)


def check_quietly(FileSpec):
    try:
        Data = open(FileSpec).read()
    except (IOError, OSError), e:
        Error(FileSpec, "Not accessible: " + str(e))
        return
    try:
        Data = Data.decode("utf8")
    except:
        Error(FileSpec, "Has invalid UTF8 data")
        return
    TidyTool = robot.tidy.Tidy()
    CleanedData = TidyTool.file(FileSpec)
    if Data != CleanedData:
        Error(FileSpec, "Found to be untidy")


def check(FileSpec):
    Index = FileSpec.rfind("/")
    FileName = FileSpec
    if Index >= 0:
        FileName = FileSpec[Index + 1:]
    sys.stdout.write("  " + FileName + "\r")
    sys.stdout.flush()
    check_quietly(FileSpec)
    sys.stdout.write(" " * (2 + len(FileName)) + "\r")


def tidy(FileSpec):
    print "Processing file:", FileSpec
    TidyTool = robot.tidy.Tidy()
    try:
        CleanedData = TidyTool.file(FileSpec)
        CleanedData = CleanedData.encode("utf8")
        open(FileSpec, "w").write(CleanedData)
    except (IOError, OSError), e:
        Error(FileSpec, "Not accessible: " + str(e))


def diff(FileSpec):
    TidyTool = robot.tidy.Tidy()
    try:
        ActualLines = open(FileSpec, 'U').readlines()
        CleanedData = TidyTool.file(FileSpec)
        # Unified diff wants list of lines, and split on newline creates empty line at the end.
        CleanedLines = [line + '\n' for line in CleanedData.encode("utf8").split('\n')[:-1]]
        DiffText = "".join(tuple(difflib.unified_diff(ActualLines, CleanedLines, n=10)))
        # TODO: If the last line does not contain \n, the output is ugly. Can we fix that without causing confsion?
        if DiffText:
            Error(FileSpec, "Tidy requires the following diff:\n" + DiffText)
    except (IOError, OSError), e:
        Error(FileSpec, "Not accessible: " + str(e))


# TODO: Refactor the command line argument parsing to use argparse. Since I
#       wanted to just quickly make this tool to get rid of manual robot.tidy
#       runs I did not have time to create polished argparse based command
#       line argument parsing code. Remember also to update the convenience
#       scripts.


def usage():
    print "Usage:\ttidytool.py <command>k <dir1> [<dir2> <dir3> ...]"
    print
    print "where <command> is one of these:"
    print
    print "check\tCheck that the Robot test data is tidy."
    print "quiet\tCheck quietly that the Robot test data is tidy."
    print "tidy\tTidy the Robot test data."
    print
    print "The program traverses the specified directories, searching for"
    print "Robot test data (.robot files) and performing the specified"
    print "command on them."


if __name__ == "__main__":
    if len(sys.argv) < 2:
        usage()
        raise SystemExit
    Command = sys.argv[1]
    DirList = sys.argv[2:]
    if Command == "check":
        Processor = check
    elif Command == "quiet":
        Processor = check_quietly
    elif Command == "tidy":
        Processor = tidy
    elif Command == "diff":
        Processor = diff
    else:
        print "Unrecognized command:", Command
        sys.exit(1)
    ErrorsReported = False
    traverse_and_process(DirList, Processor)
    if ErrorsReported:
        print "tidytool run FAILED !!!"
        sys.exit(1)
