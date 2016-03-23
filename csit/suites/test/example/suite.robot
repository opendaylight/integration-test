*** Settings ***
Documentation     Example of why Variables.py is bad and variables.robot is good.
...               Usage:
...               pybot -v PYTHON_PRIMARY:BAR -v ROBOT_PRIMARY:BAR suite.robot
Variables         ${CURDIR}/variables.py
Resource          ${CURDIR}/variables.robot

*** Test Cases ***
Check_Robot_Primary
    BuiltIn.Should_Be_Equal    BAR    ${ROBOT_PRIMARY}

Check_Robot_Secondary
    BuiltIn.Should_Be_Equal    BAR    ${ROBOT_SECONDARY}

Check_Python_Primary
    BuiltIn.Should_Be_Equal    BAR    ${PYTHON_PRIMARY}

Check_Python_Secondary
    BuiltIn.Should_Be_Equal    BAR    ${PYTHON_SECONDARY}
