DaysInTwoMonths = 31 + 29
DaysIn4Years = (365 * 4 + 1)


def GetDayOfWeek(Date):
    return Date % 7


def FormatDateCore(Date):
    Year = Date / DaysIn4Years
    Date %= DaysIn4Years
    Year *= 4
    Year += 1900
    if Date > 365:
        Date -= 366
        Year += 1 + Date / 365
        Date %= 365
    Days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if Year % 4 == 0:
        Days[1] = 29
    Month = 0
    while 1:
        DayCount = Days[Month]
        Month += 1
        if Date < DayCount:
            break
        Date -= DayCount
    Day = Date + 1
    return (Day, Month, Year)


def FormatDate(Date):
    Date = FormatDateCore(Date)
    return "%02d.%02d.%d" % Date


def ParseTimeCore(Hour, Minute, Second):
    if Hour < 0 or Hour > 23:
        return "Invalid hour"
    if Minute < 0 or Minute > 59:
        return "Invalid minute"
    if Second < 0 or Second > 59:
        return "Invalid second"
    return Hour * 3600 + Minute * 60 + Second


def FormatTime(Time):
    Hour = Time / 3600
    Time %= 3600
    Minute = Time / 60
    Second = Time % 60
    return "%02d:%02d:%02d" % (Hour, Minute, Second)


def FormatDateTime(TimeStamp):
    TimeStamp += 25568 * 86400
    Date = TimeStamp / 86400
    Time = TimeStamp % 86400
    return FormatDate(Date) + " " + FormatTime(Time)
