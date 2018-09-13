*** Settings ***
Resource          ../../../libraries/ClusterManagement.robot

*** Keywords ***
Stop Member and Log
    [Arguments]    ${member}    ${up}=none    ${down}=none
    KarafKeywords.Log Message To Controller Karaf    Stopping: ODL${member}, up: ${up}, down: ${down}
    ${new_cluster_list} =    ClusterManagement.Stop Single Member    ${member}
    [Return]    ${new_cluster_list}

Start Member and Log
    [Arguments]    ${member}    ${up}=none    ${down}=none
    KarafKeywords.Log Message To Controller Karaf    Starting: ODL${member}, up: ${up}, down: ${down}
    ClusterManagement.Start Single Member    member=${member}    check_system_status=True    service_list=@{NETVIRT_DIAG_SERVICES}
