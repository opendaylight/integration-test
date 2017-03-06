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
    [Documentation]    Suite Setup to configure HWVTEP Emulator for L2 Gateway Testcase Verification.
    Create And Set Hwvtep Connection Id
    Hwvtep Cleanup
    Namespace Cleanup
    Hwvtep Initiate
    Namespace Intiate
    Hwvtep Validation

Stop Suite
    [Documentation]    Stop Suite to cleanup Hwvtep configuration
    Hwvtep Cleanup
    Namespace Cleanup
    Switch Connection    ${hwvtep_conn_id}
    close connection

Hwvtep Cleanup
    [Documentation]    Cleanup any existing VTEP, VSWITCHD or OVSDB processes.
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${DEL_OVS_BRIDGE} ${HWVTEP_BRIDGE}    30s
    Write Commands Until Prompt    ${KILL_VTEP_PROC}    30s
    Write Commands Until Prompt    ${KILL_VSWITCHD_PROC}    30s
    Write Commands Until Prompt    ${KILL_OVSDB_PROC}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${REM_OVSDB}    30s
    Write Commands Until Prompt    ${REM_VTEPDB}    30s

Namespace Cleanup
    [Documentation]    Cleanup the existing namespaces and ports.
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Write Commands Until Prompt    ${IP_LINK}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${IP_LINK_DEL} ${NS_PORT1}    30s
    Write Commands Until Prompt    ${IP_LINK_DEL} ${NS_PORT2}    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${NETNS_DEL} ${HWVTEP_NS1}    30s
    ${stdout}=    Write Commands Until Prompt    ${IP_LINK}    30s
    Log    ${stdout}

Hwvtep Initiate
    [Documentation]    Configure the Hwvtep Emulation
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${CREATE_OVSDB}    30s
    Write Commands Until Prompt    ${CREATE VTEP}    30s
    Write Commands Until Prompt    ${START_OVSDB_SERVER}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${INIT_VSCTL}    30s
    Write Commands Until Prompt    ${DETACH_VSWITCHD}    30s
    Write Commands Until Prompt    ${CREATE_OVS_BRIDGE} ${HWVTEP_BRIDGE}    30s
    ${stdout}=    Write Commands Until Prompt    ${OVS_SHOW}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${ADD_VTEP_PS} ${HWVTEP_BRIDGE}    30s
    Write Commands Until Prompt    ${SET_VTEP_PS}${HWVTEP_IP}    30s
    Write Commands Until Prompt    ${START_OVSVTEP}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}

Namespace Intiate
    [Documentation]    Create and configure the namespace, bridges and ports.
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${NETNS_ADD} ${HWVTEP_NS1}    30s
    Write Commands Until Prompt    ${IP_LINK_ADD} ${NS_TAP1} type veth peer name ${NS_PORT1}    30s
    Write Commands Until Prompt    ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT1}    30s
    Write Commands Until Prompt    ${IP_LINK_SET} ${NS_TAP1} netns ${HWVTEP_NS1}    30s
    Write Commands Until Prompt    ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP1} up    30s
    Write Commands Until Prompt    sudo ${IPLINK_SET} ${NS_PORT1} up    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS_EXEC} ${HWVTEP_NS1} ${IFCONF}    30s
    Log    ${stdout}

Hwvtep Validation
    [Documentation]    Initial validation of the Hwvtep Configuration to confirm Phyisical_Switch table entries
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_SWITCH_TABLE}    30s
    Should Contain    ${stdout}    ${HWVTEP_BRIDGE}
    Should Contain    ${stdout}    ${HWVTEP_IP}
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_PORT_TABLE}    30s
    Should Contain    ${stdout}    ${NS_PORT1}

Create And Set Hwvtep Connection Id
    [Documentation]    To create Hwvtep connection id for the suite
    ${hwvtep_conn_id}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${hwvtep_conn_id}
    Log    ${hwvtep_conn_id}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
