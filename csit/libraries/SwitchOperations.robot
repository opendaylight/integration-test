*** Settings ***
Documentation     Library to perform switch operations like dump flow and group tables, add,list and delete ports.
Resource          Utils.robot
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

SW_GET_FLOW_GROUP
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    [Documentation]    Returns the group tables of the bridge specified. Mandatory arguments are the switch ip and bridge name.
    ${cmd}=    Catenate    ${SH_OF_CMD}    dump-groups    ${brname}    ${OF_PROTOCOL}
    Log    ${cmd}
    ${group_table_output}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    Log    ${group_table_output}
    [Return]    ${group_table_output}

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
    ${cmd}=    Catenate    ${SH_OF_CMD}    show    ${OF_PROTOCOL}    ${brname}
    ${cmd_port_name}=    Catenate    ${SH_OF_CMD}    show    ${OF_PROTOCOL}    ${brname}    ${grep_cmd_name}
    ${cmd_port_state}=    Catenate    ${SH_OF_CMD}    show    ${OF_PROTOCOL}    ${brname}    ${grep_cmd_state}
    ${result}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    Log    ${result}
    ${result}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd_port_name}
    @{keys}=    Split To Lines    ${result}
    ${result}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd_port_state}
    @{values}=    Split To Lines    ${result}
    ${length} =    Get Length    ${keys}
    #${length} =    Evaluate    ${length} - 1
    : FOR    ${item}    IN RANGE    0    ${length}
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
