*** Settings ***
Documentation     Not a test, it just logs versions of installed Python modules.
...               Useful when library documentation mentions version-specific behavior.
Library           OperatingSystem
Library           SSHLibrary
Resource          ${CURDIR}/../../libraries/Utils.robot
Resource          ${CURDIR}/../../libraries/KarafKeywords.robot

*** Test Cases ***
Freeze
    ${versions} =    OperatingSystem.Run    pip freeze
    BuiltIn.Log    ${versions}

Ulimit_On_Robot
    ${limits} =    OperatingSystem.Run    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}

Ulimit_On_Controller
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    Utils.Flexible_Controller_Login
    ${limits} =    SSHLibrary.Execute_Command    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}

Ulimit_On_Mininet
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_Mininet_Login
    ${limits} =    SSHLibrary.Execute_Command    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}

List_Installed_Features
    Open_Controller_Karaf_Console_On_Background
    ${output} =    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    feature:list -i
    BuiltIn.Log    ${output}
