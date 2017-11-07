*** Settings ***
Documentation     Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster TESTAREA1
Test Setup        Pretest Setup
Test Teardown     Pretest Cleanup
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           String
Resource          ../../../../csit/libraries/Utils.robot
Resource          ../../../../csit/libraries/OpenStackOperations.robot
Resource          ../../../../csit/libraries/DevstackUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../../csit/libraries/Utils.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/EVPN_In_Intra_DC_Deployments.robot
Resource          ../../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
Variables         ../../../variables/netvirt/Variables.robot
Variables         ../../../variables/Variables.robot

*** Variables ***
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
@{EXTRA_NW_IP}    10.50.0.2
@{SUBNET_IP_NET50}    10.50.0.0

*** Test Cases ***
Verification of intra_network_intra_openvswitch network connectivity
    [Documentation]    Verification of intra_network_intra_openvswitch network connectivity
    Validation_OpenFlow_Node_Inventory_BGP
    Log    " PING VNF11 to VNF12 and VNF21 to VNF22"
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}
    ...    , 0% packet loss
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}
    ...    , 0% packet loss
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{REQ_SUBNET_CIDR_TESTAREA1}
    \    Should Contain    ${output}    ${IP}

Verification of intra_network_inter_openvswitch network connectivity
    [Documentation]    Verification of intra_network_inter_openvswitch network connectivity
    Log    "PING VNF11 to VNF13 and VNF21 to VNF23"
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[2]}
    ...    , 0% packet loss
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[2]}
    ...    , 0% packet loss
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
    \    Should Contain    ${output}    ${IP}

Verification of inter_network_intra_openvswitch network connectivity
    [Documentation]    Verification of inter_network_intra_openvswitch network connectivity
    Log    "PING VNF11 to VNF21 and VNF12 to VNF22"
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[0]}
    ...    , 0% packet loss
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[1]}
    ...    , 0% packet loss
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
    \    Should Contain    ${output}    ${IP}

Verification of subnet route and VNF as gateway for enterprise network and after VNF reboot
    [Documentation]    Verification of subnet route and VNF as gateway for enterprise network and after VNF reboot
    Create Network    NET50
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    NET50
    Create SubNet    NET50    SUBNET50    10.50.0.0/16
    ${SUBNET_LIST}    List Subnets
    Log    ${SUBNET_LIST}
    Should Contain    ${SUBNET_LIST}    SUBNET50
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network_id} =    Get Net Id    NET50    ${devstack_conn_id}
    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network_id}
    ${CONFIG_EXTRA_ROUTE_IP} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.0.0 up
    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{SUBNET_IP_NET50}
    \    Should Contain    ${output}    ${IP}
    Log    " PING VNF14 to VNF11 and VNF14 to External route on VNF11"
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ...    , 0% packet loss
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    @{EXTRA_NW_IP}[0]
    ...    , 0% packet loss
    Reboot Nova VM    @{REQ_VM_INSTANCES_NET1}[0]
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{SUBNET_IP_NET50}
    \    Should Contain    ${output}    ${IP}
    Log    " PING VNF14 to VNF11 and VNF14 to External route on VNF11"
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ...    , 0% packet loss
    Wait Until Keyword Succeeds    40s    10s    Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    @{EXTRA_NW_IP}[0]
    ...    , 0% packet loss

*** Keywords ***
Pretest Setup
    [Documentation]    Test Case Pretest Setup
    Create Setup

Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log To Console    "Running Test case level Pretest Cleanup"
    Log    START PRETEST CLEANUP
    Get Test Teardown Debugs
    Delete Setup

Create Setup
    [Documentation]    Associate EVPN To Networks
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}

Delete Setup
    [Documentation]    Dissociate EVPN From Networks
    Log    "STEP 1 : Dissociate L3VPN From Networks"
    ${Req_no_of_net} =    Evaluate    2
    Dissociate L3VPN    ${Req_no_of_net}

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${network_id}

Dissociate L3VPN
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociate L3VPN from networks
    ${devstack_conn_id} =    Get ControlNode Connection
    Log Many    "Number of network"    ${NUM_OF_NET}
    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETS}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Not Contain    ${resp}    ${network_id}
