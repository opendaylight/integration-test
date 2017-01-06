*** Settings ***
Documentation     Test suite for HWVTEP Setup
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           Collections
Resource          ../../variables/Variables.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../variables/l2gw/Variables.robot

*** Variables ***

*** Keywords ***
Start Suite
    [Documentation]    Suite setup for L2Gw testcases which includes the cleanup and initiation of HWVTEP Emulator
    Create And Set Hwvtep Connection Id
    Hwvtep Cleanup
    Namespace Cleanup
    Hwvtep Initiate
    Namespace Intiate
    Hwvtep Validation

Stop Suite
    Log    Stop the tests
    Hwvtep Cleanup
    Namespace Cleanup
    Switch Connection    ${hwvtep_conn_id}
    close connection

Hwvtep Cleanup
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Execute With Timeout    ${GREP_OVS}
    Log To Console    ${stdout}
    Execute With Timeout    ${KILL_VTEP_PROC}
    Execute With Timeout    ${KILL_VSWITCHD_PROC}
    Execute With Timeout    ${KILL_OVSDB_PROC}
    ${stdout}=    Execute With Timeout    ${GREP_OVS}
    Log To Console    ${stdout}
    Execute With Timeout    ${REM_OVSDB}
    Execute With Timeout    ${REM_VTEPDB}
    Execute With Timeout    ${DEL_OVS_BRIDGE} ${HWVTEP_BRIDGE}

Namespace Cleanup
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Execute With Timeout    ${IP_LINK}
    Log To Console    ${stdout}
    Execute With Timeout    ${IP_LINK_DEL} ${NS_PORT1}
    Execute With Timeout    ${IP_LINK_DEL} ${NS_PORT2}
    ${stdout}=    Execute With Timeout    ${NETNS}
    Log To Console    ${stdout}
    Execute With Timeout    ${NETNS_DEL} ${HWVTEP_NS1}
    ${stdout}=    Execute With Timeout    ${IP_LINK}
    Log To Console    ${stdout}

Hwvtep Initiate
    Switch Connection    ${hwvtep_conn_id}
    Execute With Timeout    ${CREATE_OVSDB}
    Execute With Timeout    ${CREATE VTEP}
    Execute With Timeout    ${START_OVSDB_SERVER}
    ${stdout}=    Execute With Timeout    ${GREP_OVS}
    Log To Console    ${stdout}
    Execute With Timeout    ${INIT_VSCTL}
    Execute With Timeout    ${DETACH_VSWITCHD}
    Execute With Timeout    ${CREATE_OVS_BRIDGE} ${HWVTEP_BRIDGE}
    ${stdout}=    Execute With Timeout    ${OVS_SHOW}
    Log To Console    ${stdout}
    Execute With Timeout    ${ADD_VTEP_PS} ${HWVTEP_BRIDGE}
    Execute With Timeout    ${SET_VTEP_PS}${HWVTEP_IP}
    Execute With Timeout    ${START_OVSVTEP}
    ${stdout}=    Execute With Timeout    ${GREP_OVS}
    Log To Console    ${stdout}

Namespace Intiate
    Switch Connection    ${hwvtep_conn_id}
    Execute With Timeout    ${NETNS_ADD} ${HWVTEP_NS1}
    Execute With Timeout    ${IP_LINK_ADD} ${NS_TAP1} type veth peer name ${NS_PORT1}
    Execute With Timeout    ${IP_LINK_ADD} ${NS_TAP2} type veth peer name ${NS_PORT2}
    Execute With Timeout    ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT1}
    Execute With Timeout    ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT2}
    Execute With Timeout    ${IP_LINK_SET} ${NS_TAP1} netns ${HWVTEP_NS1}
    Execute With Timeout    ${IP_LINK_SET} ${NS_TAP2} netns ${HWVTEP_NS1}
    Execute With Timeout    ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP1} up
    Execute With Timeout    ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP2} up
    Execute With Timeout    sudo ${IPLINK_SET} ${NS_PORT1} up
    Execute With Timeout    sudo ${IPLINK_SET} ${NS_PORT2} up
    ${stdout}=    Execute With Timeout    ${NETNS_EXEC} ${HWVTEP_NS1} ${IFCONF}
    Log To Console    ${stdout}

Hwvtep Validation
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Execute With Timeout    ${VTEP LIST} ${PHYSICAL_SWITCH_TABLE}
    Should Contain    ${stdout}    ${HWVTEP_BRIDGE}
    Should Contain    ${stdout}    ${HWVTEP_IP}

Create And Set Hwvtep Connection Id
    Log To Console    ${HWVTEP_IP}
    Log To Console    ${DEFAULT_LINUX_PROMPT}
    ${hwvtep_conn_id}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${hwvtep_conn_id}
    Log To Console    ${hwvtep_conn_id}
    Log To Console    ${DEFAULT_USER}
    Log To Console    ${DEFAULT_PASSWORD}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}

Execute With Timeout
    [Arguments]    ${command}=help
    ${output}=    Write Commands Until Prompt    ${command}    30s
    Log To Console    ${output}
    [Return]    ${output}
