*** Settings ***
Documentation     Not a test, it just logs versions of installed Python modules.
...               Useful when library documentation mentions version-specific behavior.
Library           OperatingSystem
Library           SSHLibrary
Resource          ${CURDIR}/../../libraries/Utils.robot

*** Variables ***
@{CMD_LIST}      bash -c 'ls -lA /usr/lib/jvm'    bash -c '/usr/lib/jvm/java-1.7.0-*/bin/java -version'    bash -c '/usr/lib/jvm/java-1.8.0-*/bin/java -version'

*** Test Cases ***
Freeze
    ${versions} =    OperatingSystem.Run    pip freeze
    BuiltIn.Log    ${versions}

Ulimit_On_Robot
    ${limits} =    OperatingSystem.Run    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}

Ulimit_On_Odl_System
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    Utils.Flexible_Controller_Login
    ${limits} =    SSHLibrary.Execute_Command    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}
    SSHLibrary.Close_Connection

Ulimit_On_Tools_System
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    ${limits} =    SSHLibrary.Execute_Command    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}
    SSHLibrary.Close_Connection

DiskFree_On_Robot
    ${sizes} =    OperatingSystem.Run    bash -c "df -h"
    BuiltIn.Log    ${sizes}

DiskFree_On_Odl_System
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    Utils.Flexible_Controller_Login
    ${sizes} =    SSHLibrary.Execute_Command    bash -c "df -h"
    BuiltIn.Log    ${sizes}
    SSHLibrary.Close_Connection

DiskFree_On_Tools_System
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    ${sizes} =    SSHLibrary.Execute_Command    bash -c "df -h"
    BuiltIn.Log    ${sizes}
    SSHLibrary.Close_Connection

Ls_On_Odl_System
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    Utils.Flexible_Controller_Login
    Cmd_List    ${CMD_LIST}
    SSHLibrary.Close_Connection

Ls_On_Tools_System
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    Cmd_List    ${CMD_LIST}
    SSHLibrary.Close_Connection

*** Keywords ***
Cmd_List
    [Arguments]    ${cmd_list}
    [Documentation]    Run each command in the list.
    : FOR    ${cmd}    IN    @{cmd_list}
    \    ${output} =    SSHLibrary.Execute_Command    ${cmd} 2>&1
    \    BuiltIn.Log    ${output}
