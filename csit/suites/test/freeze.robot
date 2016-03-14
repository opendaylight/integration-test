*** Settings ***
Documentation     Not a test, it just logs versions of installed Python modules.
...               Useful when library documentation mentions version-specific behavior.
Library           OperatingSystem
Library           SSHLibrary
Resource          ${CURDIR}/../../libraries/Utils.robot

*** Variables ***
@{PATH_LIST}      /usr    /usr/lib    /usr/lib/jvm    /usr/lib/jvm/java-1.7.0    /usr/lib/jvm/java-1.8.0

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
    SSHLibrary.Close_Conection

Ulimit_On_Tools_System
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    ${limits} =    SSHLibrary.Execute_Command    bash -c "ulimit -a"
    BuiltIn.Log    ${limits}
    SSHLibrary.Close_Conection

DiskFree_On_Robot
    ${sizes} =    OperatingSystem.Run    bash -c "df -h"
    BuiltIn.Log    ${sizes}

DiskFree_On_Odl_System
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    Utils.Flexible_Controller_Login
    ${sizes} =    SSHLibrary.Execute_Command    bash -c "df -h"
    BuiltIn.Log    ${sizes}
    SSHLibrary.Close_Conection

DiskFree_On_Tools_System
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    ${sizes} =    SSHLibrary.Execute_Command    bash -c "df -h"
    BuiltIn.Log    ${sizes}
    SSHLibrary.Close_Conection

Ls_On_Odl_System
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    Utils.Flexible_Controller_Login
    Ls_List    ${PATH_LIST}
    SSHLibrary.Close_Conection

Ls_On_Tools_System
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    Ls_List    ${PATH_LIST}
    SSHLibrary.Close_Conection

*** Keywords ***
Ls_List
    [Arguments]    ${path_list}
    [Documentation]    Run "ls -lA" for each path in the list.
    : FOR    ${path}    IN    @{path_list}
    \    SSHLibrary.Execute_Command    bash -c "ls -lA ${path}"
