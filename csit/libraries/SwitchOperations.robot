*** Settings ***
Documentation     Library to perform switch operations like dump flow and group tables, add,list and delete ports.
Resource          Utils.robot
Resource          GBP/OpenFlowUtils.robot
Variables         ../variables/Variables.py

*** Variables ***
${SH_OF_CMD}      sudo ovs-ofctl
${SH_OVS_CMD}     sudo ovs-vsctl
${OF_PROTOCOL}    -O OpenFlow13
${IFCONFIG}       sudo ifconfig
${check}          LINK_DOWN
${count}          0
${grep}           | grep
${grep_cmd_name}    | grep addr | awk -F '[()]' '{print $2}'
${grep_cmd_state}    | grep state | awk '{print $2}'

*** Keyword ***
SW_GET_FLOW_TABLE
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    Returns the flow tables of the bridge specified. Mandatory arguments are the switch ip and bridge name.
    ${cmd}=    Catenate    ${SH_OF_CMD}    dump-flows    ${brname}    ${OF_PROTOCOL}
    Log    ${cmd}
    ${flow_table_output}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    Log    ${flow_table_output}
    [Return]    ${flow_table_output}

SW_GET_FLOW_TABLE_ID
    [Arguments]    ${ip}    ${brname}    ${tableid}    ${sw_type}=ovs
    [Documentation]    Returns the flow tables of the bridge specified. Mandatory arguments are the switch ip and bridge name.
    ${cmd}=    Catenate    ${SH_OF_CMD}    dump-flows    ${brname}     table=${tableid}    ${OF_PROTOCOL}
    Log    ${cmd}
    ${flow_table_output}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    Log    ${flow_table_output}
    [Return]    ${flow_table_output}

# TODO Contribute to ODL Community
Switch Should Contain Flow
    [Arguments]    ${ip}    ${brname}    ${flow_table_criterion}=${none}    ${flow_match_criteria}=${none}    ${flow_action_criteria}=${none}
    [Documentation]    Executes 'ovs-ofctl dump-flows' on remote ip ystem and goes through each output line.
    ...    A line is returned if all the criterias in actions part and matches part are matched. This is
    ...    done by calling 'Check Match' keyword. If no match is found for any of the flows, caller test case
    ...    will be failed.
    ...    flow_table_criterion can be ${None} to specify that any table matches
    ...    flow_match_criteria argument can be either a single value or a list of values to match. ${None} to specify no condition
    ...    flow_action_criteria argument can be either a single value or a list of values to match. ${None} to specify no condition
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    ${conn_id}=    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${DEFAULT_TIMEOUT}
    Flexible SSH Login    ${DEFAULT_USER}    ${EMPTY}
    ${flow}    Find Flow in OFCTL Output    br-int    ${flow_table_criterion}    ${flow_match_criteria}    ${flow_action_criteria}
    Run keyword if    not "${flow}"
    ...    Fail    Flow 'table=${flow_table_criterion}, ${flow_match_criteria} actions=${flow_action_criteria}' not found!
    SSHLibrary.Close Connection

# TODO Contribute to ODL Community
Switch Should Not Contain Flow
    [Arguments]    ${ip}    ${brname}    ${flow_table_criterion}=${none}    ${flow_match_criteria}=${none}    ${flow_action_criteria}=${none}
    [Documentation]    Oposite to 'Switch Should contain flow'
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    ${conn_id}=    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${DEFAULT_TIMEOUT}
    Flexible SSH Login    ${DEFAULT_USER}    ${EMPTY}
    ${flow}    Find Flow in OFCTL Output    br-int    ${flow_table_criterion}    ${flow_match_criteria}    ${flow_action_criteria}
    Run keyword if    "${flow}"
    ...    Fail    Flow 'table=${flow_table_criterion}, ${flow_match_criteria} actions=${flow_action_criteria}' not expected!
    SSHLibrary.Close Connection



SW_GET_FLOW_GROUP
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    Returns the group tables of the bridge specified. Mandatory arguments are the switch ip and bridge name.
    ${cmd}=    Catenate    ${SH_OF_CMD}    dump-groups    ${brname}    ${OF_PROTOCOL}
    Log    ${cmd}
    ${group_table_output}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    Log    ${group_table_output}
    [Return]    ${group_table_output}

SW_GET_GROUP_STAT
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    Returns the group tables of the bridge specified. Mandatory arguments are the switch ip and bridge name.
    ${cmd}=    Catenate    ${SH_OF_CMD}    dump-group-stats    ${brname}    ${OF_PROTOCOL}
    Log    ${cmd}
    ${group_stat_output}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    Log    ${group_stat_output}
    [Return]    ${group_stat_output}


SW_ADD_PORT
    [Arguments]    ${ip}    ${brname}    ${intf}    ${type}    ${sw_type}=ovs
    [Documentation]    Adds the given interface to the bridge. Mandatory arguments are the switch ip, bridge, interface name and type of the interface. If the port addition is successful then the return value is Added Successfully else Addition Failed.
    ${cmd}=    Catenate    ${SH_OVS_CMD}    add-port    ${brname}    ${intf}    -- set Interface
    ...    ${intf}    type=${type}
    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    Wait Until Keyword Succeeds    20s    3s    SW_GET_PORT_STATUS    ${ip}    ${brname}    ${intf}
    ${port_status}=    SW_GET_PORT_STATUS    ${ip}    ${brname}    ${intf}
    ${port_status}=    Set Variable If    "'${port_status}'"=="'Down'"    Addition Failed    Added Successfully
    Log    ${port_status}
    [Return]    ${port_status}

SW_DELETE_INTERFACE
    [Arguments]    ${ip}    ${brname}    ${intf}    ${sw_type}=ovs
    [Documentation]    Deletes the specified port from the bridge. Mandatory arguments are the switch ip, bridge and interface name. It checks if the deletion is successful or not and returns Deletion successful in case of successful deletion of port.
    ${cmd}=    Catenate    ${SH_OVS_CMD}    del-port    ${brname}    ${intf}
    Log    ${cmd}
    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    ${output}=    Run Command On Remote System    ${ip}    ${SH_OVS_CMD} show | grep ${intf}
    Log    ${output}
    ${del_port_status}=    Set Variable If    "'${output}'"=="''"    Deletion successful    Deletion failed
    [Return]    ${del_port_status}

SW_DELETE_ALL_PORTS
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    Deletes all ports from the bridge. Mandatory arguments are the switch ip and bridge name. It checks if the deletion is successful or not and returns Deletion successful in case of successful deletion of ports.
    ${all_port_output}=    SW_GET_ALL_PORT    ${ip}    ${brname}
    Log    ${all_port_output}
    ${port_list} =    Get Dictionary Keys    ${all_port_output}    ${port}
    : FOR    ${port}    IN    ${port_list}
    \    ${cmd}=    Catenate    {SH_OVS_CMD}    del-port    ${brname}    ${port}
    \    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    ${all_port_output}=    SW_GET_ALL_PORT    ${ip}    ${brname}
    ${del_all_port}=    Set Variable If    Should Be Empty    ${all_port_output}    Deletion successful    Deletion failed
    Log    ${del_all_port}

SW_GET_ALL_PORT_STATUS
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    It returns all the ports present in the bridge and its status. Mandatory arguments are the switch ip and bridge name.
    ${all_ports_status}=    Create Dictionary
    ${cmd_port_name}=    Catenate    ${SH_OF_CMD}    show    ${brname}    ${OF_PROTOCOL}    ${grep_cmd_name}
    ${cmd_port_state}=    Catenate    ${SH_OF_CMD}    show    ${brname}    ${OF_PROTOCOL}    ${grep_cmd_state}
    ${result}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd_port_name}
    @{keys}=    Split To Lines    ${result}
    ${result}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd_port_state}
    @{values}=    Split To Lines    ${result}
    ${length} =    Get Length    ${keys}
    ${length} =    Evaluate    ${length} - 1
    : FOR    ${item}    IN    0    ${length}
    \    Set To Dictionary    ${all_ports_status}    ${keys[${item}]}=${values[${item}]}
    [Return]    ${all_ports_status}

SW_GET_PORT_STATUS
    [Arguments]    ${ip}    ${brname}    ${port}    ${sw_type}=ovs
    [Documentation]    It checks the status of the port specified. Returns Up if the port is in LIVE state else returns Down. Mandatory arguments are the switch ip, bridge and the port name.
    &{all_port_output}=    SW_GET_ALL_PORT_STATUS    ${ip}    ${brname}    ${sw_type}
    ${port_status}=    Get From Dictionary    ${all_port_output}    ${port}
    ${port_status}=    Set Variable If    "'${port_status}'"=="'${check}'"    Down    Up
    [Return]    ${port_status}

SW_GET_ALL_PORT
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    It lists all the ports present in the bridge. Mandatory arguments are the switch ip and bridge name.
    @{list_of_ports}=    SW_GET_ALL_PORT_STATUS    ${ip}    ${brname}    ${sw_type}
    [Return]    ${list_of_ports}

SW_DUMP_ALL_TABLES
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    Returns the dump of flow tables and flow groups of the bridge specified. Mandatory arguments are the switch ip and bridge name.
    ${output1}=    SW_GET_FLOW_TABLE    ${ip}    ${brname}
    ${output2}=    SW_GET_FLOW_GROUP    ${ip}    ${brname}
    ${output}=    Catenate    ${output1}    \n    ${output2}
    Log    ${output}
    [Return]    ${output}

SW_GET_SWITCH_ID
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    Returns the flow tables of the bridge specified. Mandatory arguments are the switch ip and bridge name.
    ${cmd}=    Catenate    ${SH_OF_CMD}    show    ${brname}    ${OF_PROTOCOL}    | head -1 | awk -F "dpid:" '{ print $2 }'
    Log    ${cmd}
    ${CmdOut}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    ${SwitchId}    Convert To Integer    ${CmdOut}    16
    Log    ${SwitchId}
    [Return]    ${SwitchId}


