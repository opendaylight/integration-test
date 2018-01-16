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
    ${hwvtep_conn_id}=    Create And Set Hwvtep Connection Id    ${HWVTEP_IP}
    Set Suite Variable    ${hwvtep_conn_id}
    ${hwvtep2_conn_id}=    Create And Set Hwvtep Connection Id    ${HWVTEP2_IP}
    Set Suite Variable    ${hwvtep2_conn_id}
    Hwvtep Cleanup    ${hwvtep_conn_id}    ${HWVTEP_BRIDGE}
    Hwvtep Cleanup    ${hwvtep2_conn_id}    ${HWVTEP2_BRIDGE}
    Namespace Cleanup
    Hwvtep Initiate    ${hwvtep_conn_id}    ${HWVTEP_IP}    ${HWVTEP_BRIDGE}
    Hwvtep Initiate    ${hwvtep2_conn_id}    ${HWVTEP2_IP}    ${HWVTEP2_BRIDGE}
    Namespace Initiate Hwvtep
    Wait Until Keyword Succeeds    30s    1s    Hwvtep Validation

Stop Suite
    [Documentation]    Stop Suite to cleanup Hwvtep configuration
    Hwvtep Cleanup    ${hwvtep_conn_id}    ${HWVTEP_BRIDGE}
    Hwvtep Cleanup    ${hwvtep2_conn_id}    ${HWVTEP2_BRIDGE}
    Namespace Cleanup
    Switch Connection    ${hwvtep_conn_id}
    Close Connection
    Switch Connection    ${hwvtep2_conn_id}
    Close Connection

Hwvtep Cleanup
    [Arguments]    ${conn_id}    ${hwvtep_bridge}
    [Documentation]    Cleanup any existing VTEP, VSWITCHD or OVSDB processes.
    Switch Connection    ${conn_id}
    Write Commands Until Prompt    ${DEL_OVS_BRIDGE} ${hwvtep_bridge}    30s
    Write Commands Until Prompt    ${KILL_VTEP_PROC}    30s
    Write Commands Until Prompt    ${KILL_VSWITCHD_PROC}    30s
    Write Commands Until Prompt    ${KILL_OVSDB_PROC}    30s
    Write Commands Until Prompt    ${KILL_DHCLIENT_PROC}
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
    Write Commands Until Prompt    ${NETNS_DEL} ${HWVTEP_NS2}    30s
    ${stdout}=    Write Commands Until Prompt    ${IP_LINK}    30s
    Log    ${stdout}
    Switch Connection    ${hwvtep2_conn_id}
    ${stdout}=    Write Commands Until Prompt    ${IP_LINK}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${IP_LINK_DEL} ${NS2_PORT1}    30s
    Write Commands Until Prompt    ${IP_LINK_DEL} ${NS2_PORT2}    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${NETNS_DEL} ${HWVTEP2_NS1}    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${NETNS_DEL} ${HWVTEP2_NS2}    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS}    30s
    Log    ${stdout}

Hwvtep Initiate
    [Arguments]    ${conn_id}    ${hwvtep_ip}    ${hwvtep_bridge}
    [Documentation]    Configure the Hwvtep Emulation
    Switch Connection    ${conn_id}
    Write Commands Until Prompt    ${CREATE_OVSDB}    30s
    Write Commands Until Prompt    ${CREATE VTEP}    30s
    Write Commands Until Prompt    ${START_OVSDB_SERVER}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${INIT_VSCTL}    30s
    Write Commands Until Prompt    ${DETACH_VSWITCHD}    30s
    Write Commands Until Prompt    ${CREATE_OVS_BRIDGE} ${hwvtep_bridge}    30s
    ${stdout}=    Write Commands Until Prompt    ${OVS_SHOW}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${ADD_VTEP_PS} ${hwvtep_bridge}    30s
    Write Commands Until Prompt    ${SET_VTEP_PS} ${hwvtep_bridge} tunnel_ips=${hwvtep_ip}    30s
    Write Commands Until Prompt    ${START_OVSVTEP} ${hwvtep_bridge}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}

Namespace Initiate Hwvtep
    [Documentation]    Create and configure the namespace, bridges and ports.
    Create Configure Namespace    ${hwvtep_conn_id}    ${HWVTEP_NS1}    ${NS_PORT1}    ${NS_TAP1}    ${HWVTEP_BRIDGE}
    Create Configure Namespace    ${hwvtep_conn_id}    ${HWVTEP_NS2}    ${NS_PORT2}    ${NS2_TAP1}    ${HWVTEP_BRIDGE}
    Create Configure Namespace    ${hwvtep2_conn_id}    ${HWVTEP2_NS1}    ${NS2_PORT1}    ${NS3_TAP1}    ${HWVTEP2_BRIDGE}
    Create Configure Namespace    ${hwvtep2_conn_id}    ${HWVTEP2_NS2}    ${NS2_PORT2}    ${NS4_TAP1}    ${HWVTEP2_BRIDGE}

Create Configure Namespace
    [Arguments]    ${conn_id}    ${ns_name}    ${ns_port_name}    ${tap_port_name}    ${hwvtep_bridge}    ${vlan_id}=${EMPTY}
    [Documentation]    Namespace configuration to create veth pair and add to hwvtep bridge
    Switch Connection    ${conn_id}
    Write Commands Until Prompt    ${NETNS_ADD} ${ns_name}    30s
    Write Commands Until Prompt    ${IP_LINK_ADD} ${tap_port_name} type veth peer name ${ns_port_name}    30s
    Write Commands Until Prompt    ${CREATE_OVS_PORT} ${hwvtep_bridge} ${ns_port_name}    30s
    Write Commands Until Prompt    ${IP_LINK_SET} ${tap_port_name} netns ${ns_name}    30s
    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} ${IPLINK_SET} ${tap_port_name} up    30s
    Write Commands Until Prompt    sudo ${IPLINK_SET} ${ns_port_name} up    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} ${IFCONF}    30s
    Log    ${stdout}

Hwvtep Validation
    [Documentation]    Initial validation of the Hwvtep Configuration to confirm Phyisical_Switch table entries
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_SWITCH_TABLE}    30s
    Should Contain    ${stdout}    ${HWVTEP_BRIDGE}
    Should Contain    ${stdout}    ${HWVTEP_IP}
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_PORT_TABLE}    30s
    Should Contain    ${stdout}    ${NS_PORT1}
    Should Contain    ${stdout}    ${NS_PORT2}
    Switch Connection    ${hwvtep2_conn_id}
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_SWITCH_TABLE}    30s
    Should Contain    ${stdout}    ${HWVTEP2_BRIDGE}
    Should Contain    ${stdout}    ${HWVTEP2_IP}
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_PORT_TABLE}    30s
    Should Contain    ${stdout}    ${NS2_PORT1}
    Should Contain    ${stdout}    ${NS2_PORT2}

Create And Set Hwvtep Connection Id
    [Arguments]    ${hwvtep_ip}
    [Documentation]    To create connection and return connection id for hwvtep_ip received
    ${conn_id}=    SSHLibrary.Open Connection    ${hwvtep_ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Log    ${conn_id}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    [Return]    ${conn_id}
