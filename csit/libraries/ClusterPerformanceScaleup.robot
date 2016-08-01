*** Settings ***
Documentation     ClusterPerformanceScaleup Keyword library contains keywords for performing operation in cluster for setting up and maintaining
...               performance and scaleup environment
Library           BuiltIn
Library           Collections
Resource          ${CURDIR}/ClusterManagement.robot
Library           ${CURDIR}/ScaleClient.py

*** Variables ***

*** Keywords ***
Verify_Switch_Connections_Running_On_Member
    [Arguments]    ${switch_count}    ${switch_state}    ${member_index}
    [Documentation]    Fail if number of Switch connections on member of given index is not equal to switch connected.
    ${command} =    BuiltIn.Set_Variable    netstat -na | grep 6633 | grep ${switch_state} | wc -l
    ${count} =    Run_Command_On_Member    command=${command}    member_index=${member_index}
    BuiltIn.Should_Be_Equal    ${switch_count}    ${count}    Number of Switches in ${switch_state} state: ${count}

Run_Karaf_Command_On_List_Or_All
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}
    [Documentation]    Cycle through indices (or all), run karaf command on each.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${index}
    \    KarafKeywords.Issue Command On Karaf Console    ${command}    ${member_ip}

Check_Flows_Inventory_Oper_DS
    [Arguments]    ${switch_count}    ${flow_count_after_add}    ${member_index}
    [Documentation]    Checks in inventory has required state
    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${member_index}
    ${sw}    ${repf}    ${found_flow}=    Flow Stats Collected    controller=${member_ip}
    Should Be Equal As Numbers    ${flow_count_after_add}    ${found_flow}

Run_Command_On_Mininet_Tool
    [Arguments]    ${switch_state_pre_connection}    ${command}    ${mininet_tool_ip}
    [Documentation]    Pass Mininet Tool IP, call Utils and return output. This does not preserve active ssh session.
    ${output} =    Utils.Run_Command_On_Controller    ${mininet_tool_ip}    ${command}
    BuiltIn.Should_Be_Equal    0    ${output}

Stabilize_Mininet_System
    [Arguments]    ${switch_state_pre_connection}    ${mininet_tool_ip}
    [Documentation]    Check till TIME_WAIT state is over
    ${command} =    BuiltIn.Set_Variable    netstat -na | grep 6633 | grep ${switch_state_pre_connection} | wc -l
    Wait Until Keyword Succeeds    ${mininet_timeout}    1s    Run Command On Mininet Tool    ${switch_state_pre_connection}    ${command}    ${mininet_tool_ip}

Clean_And_Stabilize_Mininet_System
    [Arguments]    ${switch_state_pre_connection}    ${mininet_tool_ip}
    [Documentation]    Clean Mininet system and check till TIME_WAIT state is over
    Utils.Clean Mininet System
    ClusterPerformanceScaleup.Stabilize_Mininet_System    ${switch_state_pre_connection}    ${mininet_tool_ip}
