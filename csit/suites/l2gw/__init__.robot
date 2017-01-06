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
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log     ${stdout}
    Log    ${KILL_VTEP_PROC}
    Write Commands Until Prompt    ${KILL_VTEP_PROC}    30s
    Log    ${KILL_VSWITCHD_PROC}
    Write Commands Until Prompt    ${KILL_VSWITCHD_PROC}    30s
    Log    ${KILL_OVSDB_PROC}
    Write Commands Until Prompt    ${KILL_OVSDB_PROC}    30s
    Log    ${GREP_OVS}
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log     ${stdout}
    Log    ${REM_OVSDB}
    Write Commands Until Prompt    ${REM_OVSDB}    30s
    Log     ${REM_VTEPDB}
    Write Commands Until Prompt    ${REM_VTEPDB}    30s
    Log     ${DEL_OVS_BRIDGE} ${HWVTEP_BRIDGE}
    Write Commands Until Prompt    ${DEL_OVS_BRIDGE} ${HWVTEP_BRIDGE}    30s

Namespace Cleanup
    Switch Connection    ${hwvtep_conn_id}
    Log     ${IP_LINK}
    ${stdout}=    Write Commands Until Prompt    ${IP_LINK}    30s
    Log     ${stdout}
    Log     ${IP_LINK_DEL} ${NS_PORT1}
    Write Commands Until Prompt    ${IP_LINK_DEL} ${NS_PORT1}    30s
    Log     ${IP_LINK_DEL} ${NS_PORT2}
    Write Commands Until Prompt    ${IP_LINK_DEL} ${NS_PORT2}    30s
    Log    ${NETNS} 
    ${stdout}=    Write Commands Until Prompt    ${NETNS}    30s
    Log     ${stdout}
    Log    ${NETNS_DEL} ${HWVTEP_NS1} 
    Write Commands Until Prompt    ${NETNS_DEL} ${HWVTEP_NS1}    30s
    Log      ${IP_LINK}
    ${stdout}=    Write Commands Until Prompt    ${IP_LINK}    30s
    Log     ${stdout}

Hwvtep Initiate
    Switch Connection    ${hwvtep_conn_id}
    Log     ${CREATE_OVSDB}  
    Write Commands Until Prompt    ${CREATE_OVSDB}    30s
    Log    ${CREATE VTEP} 
    Write Commands Until Prompt    ${CREATE VTEP}    30s
    Log     ${START_OVSDB_SERVER}
    Write Commands Until Prompt    ${START_OVSDB_SERVER}    30s
    Log     ${GREP_OVS}  
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log     ${stdout}
    Log     ${INIT_VSCTL}  
    Write Commands Until Prompt    ${INIT_VSCTL}    30s
    Log      ${DETACH_VSWITCHD}  
    Write Commands Until Prompt    ${DETACH_VSWITCHD}    30s
    Log    ${CREATE_OVS_BRIDGE} ${HWVTEP_BRIDGE}  
    Write Commands Until Prompt    ${CREATE_OVS_BRIDGE} ${HWVTEP_BRIDGE}    30s
    Log      ${OVS_SHOW} 
    ${stdout}=    Write Commands Until Prompt    ${OVS_SHOW}    30s
    Log     ${stdout}
    Log     ${ADD_VTEP_PS} ${HWVTEP_BRIDGE} 
    Write Commands Until Prompt    ${ADD_VTEP_PS} ${HWVTEP_BRIDGE}    30s
    Log      ${SET_VTEP_PS}${HWVTEP_IP} 
    Write Commands Until Prompt    ${SET_VTEP_PS}${HWVTEP_IP}    30s
    Log      ${START_OVSVTEP} 
    Write Commands Until Prompt    ${START_OVSVTEP}    30s
    Log     ${GREP_OVS} 
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log     ${stdout}

Namespace Intiate
    Switch Connection    ${hwvtep_conn_id}
    Log     ${NETNS_ADD} ${HWVTEP_NS1}  
    Write Commands Until Prompt    ${NETNS_ADD} ${HWVTEP_NS1}    30s
    Log      ${IP_LINK_ADD} ${NS_TAP1} type veth peer name ${NS_PORT1} 
    Write Commands Until Prompt    ${IP_LINK_ADD} ${NS_TAP1} type veth peer name ${NS_PORT1}    30s
    Log     ${IP_LINK_ADD} ${NS_TAP2} type veth peer name ${NS_PORT2}
    Write Commands Until Prompt    ${IP_LINK_ADD} ${NS_TAP2} type veth peer name ${NS_PORT2}    30s
    Log     ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT1}
    Write Commands Until Prompt    ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT1}    30s
    Log     ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT2}   
    Write Commands Until Prompt    ${CREATE_OVS_PORT} ${HWVTEP_BRIDGE} ${NS_PORT2}    30s
    Log     ${IP_LINK_SET} ${NS_TAP1} netns ${HWVTEP_NS1}
    Write Commands Until Prompt    ${IP_LINK_SET} ${NS_TAP1} netns ${HWVTEP_NS1}    30s
    Log    ${IP_LINK_SET} ${NS_TAP2} netns ${HWVTEP_NS1} 
    Write Commands Until Prompt    ${IP_LINK_SET} ${NS_TAP2} netns ${HWVTEP_NS1}    30s
    Log     ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP1} up
    Write Commands Until Prompt    ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP1} up    30s
    Log    ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP2} up  
    Write Commands Until Prompt    ${NETNS_EXEC} ${HWVTEP_NS1} ${IPLINK_SET} ${NS_TAP2} up    30s
    Log    sudo ${IPLINK_SET} ${NS_PORT1} up  
    Write Commands Until Prompt    sudo ${IPLINK_SET} ${NS_PORT1} up    30s
    Log    sudo ${IPLINK_SET} ${NS_PORT2} up   
    Write Commands Until Prompt    sudo ${IPLINK_SET} ${NS_PORT2} up    30s
    Log     ${NETNS_EXEC} ${HWVTEP_NS1} ${IFCONF} 
    ${stdout}=    Write Commands Until Prompt    ${NETNS_EXEC} ${HWVTEP_NS1} ${IFCONF}    30s
    Log     ${stdout}

Hwvtep Validation
    Switch Connection    ${hwvtep_conn_id}
    Log    ${VTEP LIST} ${PHYSICAL_SWITCH_TABLE} 
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_SWITCH_TABLE}    30s
    Should Contain    ${stdout}    ${HWVTEP_BRIDGE}
    Should Contain    ${stdout}    ${HWVTEP_IP}

Create And Set Hwvtep Connection Id
    Log     ${HWVTEP_IP}
    Log     ${DEFAULT_LINUX_PROMPT}
    ${hwvtep_conn_id}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${hwvtep_conn_id}
    Log     ${hwvtep_conn_id}
    Log     ${DEFAULT_USER}
    Log     ${DEFAULT_PASSWORD}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}

