from state import state
import robot.libraries.BuiltIn as BuiltIn


class FakeFailureState:

    def initialize(s):
        s.active = False


# Adds new behavior specific to SYSTEST: When the message is equal to a magic
# string, the SYSTEST becomes active and starts to look for two other magic
# strings used to control an internal failure simulation flag. When this
# failure simulation flag is set, the RunKeywordIfTestFailed will run the
# keyword passed to it even when the test is still in the "passed" state but
# the ${SUITE_STATUS} suite variable which is available in suite teardown is
# still showing "PASS" state of the test case so the simulation is not
# perfect.
def fail(*args):
    global fake_test_failure
    if len(args) == 2:
        message = args[1]
        if message == "MAGIC_KEYWORD_ASKING_SYSTEST_TO_ENABLE_ITSELF":
            state.enable_special_actions()
            return
        if state.are_special_actions_enabled():
            if message == "SIMULATE_FAILURE_BUT_DO_NOT_ACTUALLY_FAIL":
                fake_failure.active = True
                return
            elif message == "RESET_FAKE_FAILURE_FLAG_IF_SET_OR_DO_NOTHING":
                fake_failure.active = False
                return
    original_fail(*args)


# If the STRICTBOT internal "fake failure" flag is set, execute the keyword
# given to it as if the test failed despite the fact that test is still
# flagged as being passed.
def run_keyword_if_test_failed(*args):
    if state.are_special_actions_enabled():
        if fake_failure.active:
            self = args[0]
            name = args[1]
            args = args[2:]
            self.run_keyword(name, *args)
            return
    original_run_keyword_if_test_failed(*args)


def initialize():
    fake_failure.initialize()

fake_failure = FakeFailureState()
Verify = BuiltIn._Verify
original_fail = Verify.fail
Verify.fail = fail
del Verify
RunKeyword = BuiltIn._RunKeyword
original_run_keyword_if_test_failed = RunKeyword.run_keyword_if_test_failed
RunKeyword.run_keyword_if_test_failed = run_keyword_if_test_failed
del RunKeyword
