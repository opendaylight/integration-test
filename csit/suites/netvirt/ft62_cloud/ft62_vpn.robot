*** Settings ***
Documentation     Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster TESTAREA1
Test Teardown     Pretest Cleanup
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           String
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/FT62_bgp.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/ft62_variables/ft62_vars.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_IP}

*** Test Cases ***
Verification of l3vpn_association_with_network_ping_test
    [Documentation]    Verification of l3vpn_association_with_network_ping_test
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}
    ...    ${REQ_PING_REGEXP}
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[1]}
    ...    ${REQ_PING_REGEXP}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{REQ_SUBNET_CIDR}
    \    Should Contain    ${output}    ${IP}
    Verify Routes Exchange Between ODL And DCGW

Verification of l3vpn_association_with_router_ping_test
    [Documentation]    Verification of l3vpn_association_with_router_ping_test
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network_id} =    Get Net Id    ${REQ_NETWORKS[1]}    ${devstack_conn_id}
    Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    Add Router Interface    ${REQ_ROUTER}    ${ROUTER_INTERFACE1}
    Add Router Interface    ${REQ_ROUTER}    ${ROUTER_INTERFACE2}
    ${router_id}=    Get Router Id    ${REQ_ROUTER}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[2]    ${VM_IP_NET3[0]}    ${VM_IP_NET3[1]}
    ...    ${REQ_PING_REGEXP}
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[2]    ${VM_IP_NET3[0]}    ${VM_IP_NET2[1]}
    ...    ${REQ_PING_REGEXP}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET3}    @{REQ_SUBNET_CIDR_LIST2}
    \    Should Contain    ${output}    ${IP}

*** Keywords ***
Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log To Console    "Running Test case level Pretest Cleanup"
    Log    START PRETEST CLEANUP
    Get Test Teardown Debugs

