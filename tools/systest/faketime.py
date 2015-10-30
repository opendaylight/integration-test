from state import state
import robot.libraries.BuiltIn as BuiltIn
import robot.libraries.DateTime as DateTime
from robot.utils import is_falsy


class FakeTimeState:

    def initialize(s):
        s.now = "2015-10-30 01:47:26.846"
        s.sleeping_drift = "0.007s"
        s.time_reading_drift = "0.007s"
        s.time_zone_offset = "-7h"


# Instead of actually sleeping, just increate a "current time"
def FakeSleep(*args):
    if state.are_special_actions_enabled():
        self = args[0]
        time = args[1]
        reason = None
        if len(args) > 2:
            reason = args[2]
        if time == "SET_SLEEP_DRIFT":
            seconds = BuiltIn.timestr_to_secs(reason)
            if seconds < 0:
                raise ValueError("Sleep drift cannot be negative")
            faketime.sleeping_drift = reason
        elif time == "SET_TIME_READ_DRIFT":
            seconds = BuiltIn.timestr_to_secs(reason)
            if seconds < 0:
                raise ValueError("Time reading drift cannot be negative")
            faketime.time_reading_drift = reason
        elif time == "SET_TIME_ZONE_OFFSET":
            seconds = BuiltIn.timestr_to_secs(reason)
            if seconds < -12*3600 or seconds > 12*3600:
                raise ValueError("Time zone offset is out of range")
            faketime.time_zone_offset = reason
        else:
            seconds = BuiltIn.timestr_to_secs(time)
            if seconds < 0:
                seconds = 0
            newtime = DateTime.add_time_to_date(faketime.now, time)
            faketime.now = DateTime.add_time_to_date(newtime, faketime.sleeping_drift)
            self.log('Slept %s' % BuiltIn.secs_to_timestr(seconds))
            if reason:
                self.log(reason)
        return
    OriginalSleep(*args)


def fake_get_current_date(time_zone='local',
                          increment=0,
                          result_format='timestamp',
                          exclude_millis=False):
    if state.are_special_actions_enabled():
        dt = faketime.now
        if time_zone.upper() == 'LOCAL':
            dt = DateTime.add_time_to_date(dt, faketime.time_zone_offset)
        elif time_zone.upper() != 'UTC':
            raise ValueError("Unsupported timezone '%s'." % time_zone)
        date = DateTime.Date(dt) + DateTime.Time(increment)
        return date.convert(result_format, millis=is_falsy(exclude_millis))
    args = (time_zone, increment, result_format, exclude_millis)
    return original_get_current_date(*args)


def initialize():
    faketime.initialize()


faketime = FakeTimeState()
Misc = BuiltIn._Misc
OriginalSleep = Misc.sleep
Misc.sleep = FakeSleep
del Misc
original_get_current_date = DateTime.get_current_date
DateTime.get_current_date = fake_get_current_date
