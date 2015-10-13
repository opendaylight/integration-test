*** Settings ***
Documentation     Not a test, it just logs versions of installed Python modules.
...               Useful when library documentation mentions version-specific behavior.
Library           OperatingSystem
Library           SSHLibrary
Resource          ${CURDIR}/../../libraries/Utils.robot

*** Test Cases ***
Freeze
    ${versions} =    OperatingSystem.Run    pip freeze
    BuiltIn.Log    ${versions}

Ulimit_On_Robot
    ${limits} =    OperatingSystem.Run    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}

Ulimit_On_Controller
    SSHLibrary.Open_Connection    ${ODL_SYSTEM}
    Utils.Flexible_Controller_Login
    ${limits} =    SSHLibrary.Execute_Command    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}
