*** Settings ***
Documentation     Not a test, it just logs versions of installed Python modules.
...               Useful when library documentation mentions version-specific behavior.
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           OperatingSystem
Library           SSHLibrary
Library           RequestsLibrary
Resource          ${CURDIR}/../../libraries/Utils.robot
Variables         ${CURDIR}/../../variables/Variables.py

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
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    ${limits} =    SSHLibrary.Execute_Command    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}

DiskFree_On_Robot
    ${sizes} =    OperatingSystem.Run    bash -c "df -h"
    BuiltIn.Log    ${sizes}

DiskFree_On_Controller
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    Utils.Flexible_Controller_Login
    ${sizes} =    SSHLibrary.Execute_Command    bash -c "df -h"
    BuiltIn.Log    ${sizes}

DiskFree_On_Mininet
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    ${sizes} =    SSHLibrary.Execute_Command    bash -c "df -h"
    BuiltIn.Log    ${sizes}

Log_Modules
    ${resp} =    RequestsLibrary.Get_Request    session    ${CONTROLLER_CONFIG_MOUNT}/config:modules
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Contain    ${resp.content}    distribution-version
