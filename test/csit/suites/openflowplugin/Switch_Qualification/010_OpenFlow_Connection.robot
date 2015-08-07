*** Settings ***
Documentation     TODO
Suite Setup       Switch Qualification Suite Setup
Suite Teardown    Switch Qualification Suite Teardown
Test Timeout      5m
Library           Collections
Library           OperatingSystem
Resource          ../../../libraries/SwitchUtils.txt
Resource          ../../../libraries/Utils.robot
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/SwitchClasses/${SWITCH_CLASS}.py
Variables         ../../../variables/Variables.py

*** Variables ***
${SWITCH_CLASS}    Ovs
${SWITCH_IP}      ${MININET}
${SWITCH_PROMPT}    ${LINUX_PROMPT}
${CONTROLLER}     null
${REST_CONTEXT}    /restconf/operational/opendaylight-inventory:nodes

*** Test Cases ***
OF1.3 Connection Between Switch and Controller
    [Tags]    switch_qualification
    Configure OpenFlow    ${test_switch}
    Enable OpenFlow    ${test_switch}
    ${datapath_id_from_switch}=    Get Switch Datapath ID    ${test_switch}
    Verify Switch In Operational Data Store    ${test_switch}
    Disable OpenFlow    ${test_switch}
    Wait Until Keyword Succeeds    3s    1s    Verify Switch Not In Operational Data Store    ${test_switch}
    ##MORE CHECKS TO ADD ON SWITCH AND OPERATIONAL DATA STORE
    ##- proper OF version
    ##- proper default flow rules
    ##- ???

*** Keywords ***
Switch Qualification Suite Setup
    ${test_switch}=    Get Switch    ${SWITCH_CLASS}
    Set Suite Variable    ${test_switch}
    Call Method    ${test_switch}    set_mgmt_ip    ${SWITCH_IP}
    Call Method    ${test_switch}    set_controller_ip    ${CONTROLLER}
    Call Method    ${test_switch}    set_mgmt_prompt    ${SWITCH_PROMPT}
    Log    MAKE: ${test_switch.make}\n MODEL: ${test_switch.model}\n IP: ${test_switch.mgmt_ip}\n PROMPT: ${test_switch.mgmt_prompt}\n CONTROLLER_IP: ${test_switch.of_controller_ip}\n MGMT_PROTOCOL: ${test_switch.mgmt_protocol}
    Ping    ${test_switch.mgmt_ip}
    Initialize Switch    ${test_switch}
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

Switch Qualification Suite Teardown
    Cleanup Switch    ${test_switch}
    SSHLibrary.Close All Connections
    Telnet.Close All Connections
