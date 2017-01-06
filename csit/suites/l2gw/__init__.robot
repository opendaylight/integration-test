*** Settings ***
Documentation     Test suite for HWVTEP Setup
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           Collections
Resource          ../../variables/Variables.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../variables/l2gw/Variables.robot

*** Variables ***

*** Keywords ***
Start Suite
    [Documentation]    Suite setup for L2Gw testcases which includes the cleanup and initiation of HWVTEP Emulator
    Log    " Create And Set Hwvtep Connection Id"
    Create And Set Hwvtep Connection Id
    Log    "Hwvtep Cleanup"
    Hwvtep Cleanup
    Log    "Namespace Cleanup"
    Namespace Cleanup
    Log    "Hwvtep Initiate"
    Hwvtep Initiate
    Log    " Namespace Intiate"
    Namespace Intiate
    Log    " Hwvtep Validation"
    Hwvtep Validation

Stop Suite
    Log    Stop the tests
    Hwvtep Cleanup
    Log    " Namespace Cleanup"
    Namespace Cleanup
    Switch Connection    ${hwvtep_conn_id}
    close connection

Hwvtep Cleanup
    Switch Connection    ${hwvtep_conn_id}
    Log    "KILL_VTEP_PROC"
    Execute Command    ${KILL_VTEP_PROC}
    Log    "KILL_VSWITCHD_PROC"
    Execute Command    ${KILL_VSWITCHD_PROC}
    Log    "KILL_OVSDB_PROC"
    Execute Command    ${KILL_OVSDB_PROC}
    ${stdout}=    Execute Command    ${GREP_OVS}
    Log    ${stdout}
    Log    "REM_OVSDB"
    Execute Command    ${REM_OVSDB}
    Log    "REM_VTEPDB"
    Execute Command    ${REM_VTEPDB}
    Log    "DEL_OVS_BRIDGE"
    Execute Command    ${DEL_OVS_BRIDGE} ${HWVTEP_BRIDGE}

Namespace Cleanup
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Execute Command    ${IP_LINK}
    Log    ${stdout}
    Execute Command    ${IP_LINK_DEL} ${NS_PORT1}
    Execute Command    ${IP_LINK_DEL} ${NS_PORT2}
    ${stdout}=    Execute Command    ${NETNS}
    Log    ${stdout}
    Execute Command    ${NETNS_DEL} ${HWVTEP_NS1}
    ${stdout}=    Execute Command    ${IP_LINK}
    Log    ${stdout}

Hwvtep Initiate
    Switch Connection    ${hwvtep_conn_id}
    Execute Command    ${CREATE_OVSDB}
    Execute Command    ${CREATE VTEP}
    Execute Command    ${START_OVSDB_SERVER}
    ${stdout}=    Execute Command    ${GREP_OVS}
    Log    ${stdout}
    Execute Command    ${INIT_VSCTL}
    Execute Command    ${DETACH_VSWITCHD}
    Execute Command    ${CREATE_OVS_BRIDGE} ${HWVTEP_BRIDGE}
    ${stdout}=    Execute Command    ${OVS_SHOW}
    Log    ${stdout}
    Execute Command    ${ADD_VTEP_PS} ${HWVTEP_BRIDGE}
    Execute Command    ${SET_VTEP_PS}${HWVTEP_IP}
    Execute Command    ${START_OVSVTEP}
    ${stdout}=    Execute Command    ${GREP_OVS}
    Log    ${stdout}

Namespace Intiate
    Switch Connection    ${hwvtep_conn_id}
    Execute Command    ${NETNS_ADD} ${HWVTEP_NS1}
    Execute Command    ${IP_LINK_ADD} ${NS_TAP1} type veth peer name ${NS_PORT1}
    Execute Command    ${IP_LINK_ADD} ${NS_TAP2} type veth peer name ${NS_PORT2}
    Execute Command    ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT1}
    Execute Command    ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT2}
    Execute Command    ${IP_LINK_SET} ${NS_TAP1} netns ${HWVTEP_NS1}
    Execute Command    ${IP_LINK_SET} ${NS_TAP2} netns ${HWVTEP_NS1}
    Execute Command    ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP1} up
    Execute Command    ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP2} up
    Execute Command    sudo ${IPLINK_SET} ${NS_PORT1} up
    Execute Command    sudo ${IPLINK_SET} ${NS_PORT2} up
    ${stdout}=    Execute Command    ${NETNS_EXEC} ${HWVTEP_NS1} ${IFCONF}
    Log    ${stdout}

Hwvtep Validation
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Execute Command    ${VTEP LIST} ${PHYSICAL_SWITCH_TABLE}
    Should Contain    ${stdout}    ${HWVTEP_BRIDGE}
    Should Contain    ${stdout}    ${HWVTEP_IP}

Create And Set Hwvtep Connection Id
    Log    ${HWVTEP_IP}
    Log    ${DEFAULT_LINUX_PROMPT}
    ${hwvtep_conn_id}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${hwvtep_conn_id}
    Log    ${hwvtep_conn_id}
    Log    ${DEFAULT_USER}
    Log    ${DEFAULT_PASSWORD}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
