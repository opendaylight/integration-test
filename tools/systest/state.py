class StrictBotState:

    def __init__(s):
        s.special_actions_enabled = False

    def enable_special_actions(s):
        s.special_actions_enabled = True

    def are_special_actions_enabled(s):
        return s.special_actions_enabled

state = StrictBotState()
