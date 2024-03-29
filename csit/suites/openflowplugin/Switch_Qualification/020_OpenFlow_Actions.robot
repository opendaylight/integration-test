*** Settings ***
Documentation       OF1.3 Suite for flow actions
...                 - output ALL
...                 - output CONTROLLER
...                 - output TABLE
...                 - output INPORT
...                 - output LOCAL
...                 - output NORMAL
...                 - output FLOOD
...                 - output ANY
...
...                 NOTE: for OVS, INPORT does not appear to be supported

Library             Collections
Library             OperatingSystem
Library             String
Library             XML
Resource            ../../../libraries/Utils.robot
Resource            ../../../libraries/FlowLib.robot
Resource            ../../../libraries/SwitchUtils.robot
Resource            ../../../libraries/OVSDB.robot
Library             RequestsLibrary
Library             ../../../libraries/Common.py
Variables           ../../../variables/Variables.py
Library             ../../../libraries/SwitchClasses/${SWITCH_CLASS}.py

Suite Setup         OpenFlow Actions Suite Setup
Suite Teardown      OpenFlow Actions Suite Teardown
Test Template       Create And Remove Flow


*** Variables ***
${SWITCH_CLASS}         Ovs
${SWITCH_IP}            ${TOOLS_SYSTEM_IP}
${SWITCH_PROMPT}        ${TOOLS_SYSTEM_PROMPT}
${ODL_SYSTEM_IP}        null
${ipv4_src}             11.3.0.0/16
${ipv4_dst}             99.0.0.0/8
${eth_type}             0x800
${eth_src}              00:ab:cd:ef:01:23
${eth_dst}              ff:ff:ff:ff:ff:ff
##documentation strings
${INPORT_doc}
...                     OF1.3: OFPP_INPORT = 0xfffffff8, /* Send the packet out the input port. This\nreserved port must be explicitly used\nin order to send back out of the input\nport. */\n
${TABLE_doc}
...                     OF1.3: OFPP_TABLE = 0xfffffff9, /* Submit the packet to the first flow table NB: This destination port can only be used in packet-out messages. */
${NORMAL_doc}           OF1.3 OFPP_NORMAL = 0xfffffffa, /* Process with normal L2/L3 switching. */
${FLOOD_doc}
...                     OF1.3 OFPP_FLOOD = 0xfffffffb, /* All physical ports in VLAN, except input port and those blocked or link down. */
${ALL_doc}              OF1.3: OFPP_ALL = 0xfffffffc, /* All physical ports except input port. */
${CONTROLLER_doc}       OF1.3 OFPP_CONTROLLER = 0xfffffffd, /* Send to controller. */
${LOCAL_doc}            OF1.3 OFPP_LOCAL = 0xfffffffe, /* Local openflow "port". */


*** Test Cases ***    output port    tableID    flowID    priority
INPORT    [Documentation]    ${INPORT_doc}
    [Tags]    inport
    ${TEST_NAME}    200    161    1
TABLE    [Documentation]    ${TABLE_doc}
    [Tags]    table
    ${TEST_NAME}    200    261    65535
NORMAL    [Documentation]    ${NORMAL_doc}
    [Tags]    normal
    ${TEST_NAME}    200    361    9
FLOOD    [Documentation]    ${FLOOD_doc}
    [Tags]    flood
    ${TEST_NAME}    200    81    255
ALL    [Documentation]    ${ALL_doc}
    [Tags]    all
    ${TEST_NAME}    200    88    42
CONTROLLER    [Documentation]    ${CONTROLLER_doc}
    [Tags]    controller
    ${TEST_NAME}    200    21    21
LOCAL    [Documentation]    ${LOCAL_doc}
    [Tags]    local
    ${TEST_NAME}    200    32    12345


*** Keywords ***
Create And Remove Flow
    [Arguments]    ${output_port}    ${table_id}    ${flow_id}    ${priority}
    ##The dictionaries here will be used to populate the match and action elements of the flow mod
    ${ethernet_match_dict}=    Create Dictionary    type=${eth_type}    destination=${eth_dst}    source=${eth_src}
    ${ipv4_match_dict}=    Create Dictionary    source=${ipv4_src}    destination=${ipv4_dst}
    ##flow is a python Object to build flow details, including the xml format to send to controller
    ${flow}=    Create Inventory Flow
    Set "${flow}" "table_id" With "${table_id}"
    Set "${flow}" "id" With "${flow_id}"
    Set "${flow}" "priority" With "${priority}"
    Clear Flow Actions    ${flow}
    Set Flow Output Action    ${flow}    0    0    ${output_port}
    Set Flow Ethernet Match    ${flow}    ${ethernet_match_dict}
    Set Flow IPv4 Match    ${flow}    ${ipv4_match_dict}
    Log    Flow XML is ${flow.xml}
    Call Method    ${test_switch}    create_flow_match_elements    ${flow.xml}
    Log    ${test_switch.flow_validations}
    ${dpid_id}=    Get Switch Datapath ID    ${test_switch}
    Wait Until Keyword Succeeds
    ...    3s
    ...    1s
    ...    Add Flow To Controller And Verify
    ...    ${flow.xml}
    ...    openflow%3A${dpid_id}
    ...    ${flow.table_id}
    ...    ${flow.id}
    Wait Until Keyword Succeeds
    ...    3s
    ...    1s
    ...    Validate Switch Output
    ...    ${test_switch}
    ...    ${test_switch.dump_all_flows}
    ...    ${test_switch.flow_validations}
    Wait Until Keyword Succeeds
    ...    3s
    ...    1s
    ...    Remove Flow From Controller And Verify
    ...    openflow%3A${dpid_id}
    ...    ${flow.table_id}
    ...    ${flow.id}
    Wait Until Keyword Succeeds
    ...    3s
    ...    1s
    ...    Validate Switch Output
    ...    ${test_switch}
    ...    ${test_switch.dump_all_flows}
    ...    ${test_switch.flow_validations}
    ...    false

OpenFlow Actions Suite Setup
    ${test_switch}=    Get Switch    ${SWITCH_CLASS}
    Set Suite Variable    ${test_switch}
    Call Method    ${test_switch}    set_mgmt_ip    ${SWITCH_IP}
    Call Method    ${test_switch}    set_controller_ip    ${ODL_SYSTEM_IP}
    Call Method    ${test_switch}    set_mgmt_prompt    ${SWITCH_PROMPT}
    Run Command On Controller    ${ODL_SYSTEM_IP}    ps -elf | grep java
    Log
    ...    MAKE: ${test_switch.make}\nMODEL: ${test_switch.model}\nIP: ${test_switch.mgmt_ip}\nPROMPT: ${test_switch.mgmt_prompt}\nCONTROLLER_IP: ${test_switch.of_controller_ip}\nMGMT_PROTOCOL: ${test_switch.mgmt_protocol}
    Ping    ${test_switch.mgmt_ip}
    Initialize Switch    ${test_switch}
    Configure OpenFlow    ${test_switch}
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

OpenFlow Actions Suite Teardown
    Clean OVSDB Test Environment
    Cleanup Switch    ${test_switch}
    SSHLibrary.Close All Connections
    Telnet.Close All Connections
