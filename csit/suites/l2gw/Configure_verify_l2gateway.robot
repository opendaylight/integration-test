*** Settings ***
Documentation     Test Suite for verification of HWVTEP usecases
Suite Setup       Basic Suite Setup
Suite Teardown    Basic Suite Teardown
Resource          ../../libraries/L2GatewayOperations.robot

*** Test Cases ***
TC1 Connect Hwvtep And Ovs To Controller Verify
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}
    DUMP
    L2GatewayOperations.Add Ovs Bridge Manager Controller And Verify    ${OVS_IP}
    DUMP

*** Keywords ***
Basic Suite Setup
    [Documentation]    Basic Suite Setup required for the HWVTEP Test Suite
    ${port_mac_list}=    Create List
    Set Suite Variable    ${port_mac_list}
    Log    ${OS_IP}
    Log    ${DEFAULT_LINUX_PROMPT}
    RequestsLibrary.Create Session    alias=session    url=http://${ODL_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${devstack_conn_id}=    SSHLibrary.Open Connection    ${OS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${devstack_conn_id}
    Set Suite Variable    ${devstack_conn_id}
    Log    ${OS_USER}
    Log    ${OS_PASSWORD}
    Login    ${OS_USER}    ${OS_PASSWORD}
    Write Commands Until Prompt    cd ${DEVSTACK_DEPLOY_PATH}; source openrc admin admin

Basic Suite Teardown
    [Documentation]    Basic Suite Teardown required after the HWVTEP Test Suite
    Switch Connection    ${devstack_conn_id}
    close connection
