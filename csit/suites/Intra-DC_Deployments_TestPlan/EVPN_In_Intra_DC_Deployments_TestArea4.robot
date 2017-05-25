*** Settings ***
Documentation      Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster TESTAREA2
Test Setup         Pretest Setup
Test Teardown      Pretest Cleanup
Library            RequestsLibrary
Library            SSHLibrary
Library            Collections
Library            String
Resource           ../../../csit/libraries/OpenStackOperations.robot
Resource           ../../../csit/libraries/DevstackUtils.robot
Resource           ../../libraries/SetupUtils.robot
Resource           ../../libraries/KarafKeywords.robot
Resource           ../../libraries/VpnOperations.robot
Resource           ../../../csit/libraries/Utils.robot
Resource           ../../libraries/BgpOperations.robot
Resource           ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
Variables          ../../variables/Variables.py

*** Variables ***

${DCGW_SYSTEM_IP}     ${TOOLS_SYSTEM_1_IP}
@{PORT_LIST_NEW}      PORT15
${VM_NAME_NEW}        VM15
${MAC_REGEX}      (([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))
${IP_REGEX}       (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])
${Req_no_of_ports}         16 
${Req_no_of_vms_per_dpn}    8

*** Test Cases ***

CREATE TEST TOPOLOGY FOR TEST AREA 4
    [Documentation]    CREATE TEST TOPOLOGY FOR TEST AREA 4
    [Tags]    Nightly
    [Setup]    Log    NO PRETEST SETUP
    Log    Delete Interface From Router
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA3}
    \    Remove Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
    Log    ADD INTERFACE NET3 NET4 TO RTR1
    Log    ADD INTERFACE NET7 NET8 TO RTR2
    Add Interfaces To Routers
    Log    Delete the VM instances
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    Log    Delete neutron ports
    : FOR    ${Port}    IN    @{REQ_PORT_LIST}
    \    Delete Port    ${Port}
    Log    CREATE PORTS
    Create Neutron Ports    ${Req_no_of_ports}
    Log    CREATE VM INSTANCES
    Create Nova VMs     ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    ${VM_IP_NET5}    ${VM_IP_NET6}    ${VM_IP_NET7}    ${VM_IP_NET8}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET1}
    Set Global Variable    ${VM_IP_NET3}
    Set Global Variable    ${VM_IP_NET4}
    Set Global Variable    ${VM_IP_NET5}
    Set Global Variable    ${VM_IP_NET6}
    Set Global Variable    ${VM_IP_NET7}
    Set Global Variable    ${VM_IP_NET8}
    Log    Dissociate NET1 NET2 AND RTR1 FROM EVPN
    ${Req_no_of_routers} =    Evaluate    1
    Dissociate L3VPN From Routers    ${Req_no_of_routers}
    ${Req_no_of_net} =    Evaluate    2
    Dissociate L3VPN    ${Req_no_of_net}
    Log    Delete Interface From Router RTR1
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA3}
    \    Remove Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
    Log    DELETE BGP CONFIG ON ODL
    Delete BGP Config On ODL
    Log    DELETE L3VPN
    ${Req_no_of_L3VPN} =    Evaluate    1
    Delete L3VPN    ${Req_no_of_L3VPN}
    Log    CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID
    ${Req_no_of_L3VPN} =    Evaluate    2
    Create L3VPN    ${Req_no_of_L3VPN}
    Log    ADD BGP NEIGHBOUR ( ASR AS DCGW ) AND CHECK BGP CONNECTION
    Create BGP Config On ODL
    Create BGP Config On DCGW
    Log    VERIFY TUNNELS BETWEEN DPNS IS UP
    Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
    Log    VERIFY FLOWS ARE PRESENT ON THE DPNS
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    VERIFY ALL VM's ARE IN ACTIVE STATE
    :FOR    ${VM}    IN    @{VM_INSTANCES_TEST_TOPOLOGY_4}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    ASSOCIATE NET1 NET2 AND RTR1 TO EVPN1 AND NET5 NET6 AND RTR2 TO EVPN2 FROM CSC
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    ${Req_no_of_routers} =    Evaluate    1
    Associate L3VPN To Routers    ${Req_no_of_routers}
    [Teardown]    Log    NO PRETEST Teardown

TC63 7.4.1 Verify network connectivity between VNF_Network to VNF_Router on intra_openvswitch for L3VPNoVxLAN1
    Log    "Testcases covered as per Testplan ${\n} 7.4.1 Verify network connectivity between VNF_Network to VNF_Router on intra_openvswitch for L3VPNoVxLAN1"
    Log    "STEP 2 : PING VNF11 <-> VNF31 VNF12<-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    Should Contain    ${output}    ${IP}

TC64 7.4.2 Verify network connectivity between VNF_Network to VNF_Router on inter_openvswitch for L3VPNoVxLAN1
    Log    "Testcases covered as per Testplan ${\n} 7.4.2 Verify network connectivity between VNF_Network to VNF_Router on inter_openvswitch for L3VPNoVxLAN1"
    Log    "STEP 2 : PING VNF11 <-> VNF32, VNF21<-> VNF42"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[2]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    Should Contain    ${output}    ${IP}

TC65 7.4.3 Verify network connectivity between VNF_Network to VNF_Router on intra_openvswitch for L3VPNoVxLAN2
    Log    "Testcases covered as per Testplan ${\n} 7.4.3 Verify network connectivity between VNF_Network to VNF_Router on intra_openvswitch for L3VPNoVxLAN2"
    Log    "STEP 2 : PING VNF51 <-> VNF71, VNF61<-> VNF81"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[4]    ${VM_IP_NET5[0]}    ${VM_IP_NET7[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[0]}    ${VM_IP_NET8[0]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
    Should Contain    ${output}    ${IP}

TC66 7.4.4 Verify network connectivity between VNF_Network to VNF_Router on inter_openvswitch for L3VPNoVxLAN2
    Log    "Testcases covered as per Testplan ${\n} 7.4.4 Verify network connectivity between VNF_Network to VNF_Router on inter_openvswitch for L3VPNoVxLAN2"
    Log    "STEP 2 : PING VNF51 <-> VNF72, VNF61<-> VNF82"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    000    ${VM_IP_NET5[0]}    ${VM_IP_NET7[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[0]}    ${VM_IP_NET8[1]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
    Should Contain    ${output}    ${IP}

TC67_TC68 7.4.5_7.4.6Verify disassociation of Network from L3VPNoVxLAN1
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.4.5 Verify the disassociation of networks from L3VPNoVxLAN1 ${\n} 7.4.6 Verify the disassociation of router from L3VPNoVxLAN2 ${\n} "
    Log    "STEP 2 : PING VNF11 <-> VNF32 VNF21<-> VNF42 "
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[1]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}
    Log    "STEP 3 : Dissociate L3VPN1 From Networks"
    ${Req_no_of_net} =    Evaluate    2
    Dissociate L3VPN    ${Req_no_of_net}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Not Contain    ${output}    ${IP}
    Log    "STEP 4 : PING VNF51 <-> VNF72 VNF61<-> VNF82 "
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[4]    ${VM_IP_NET5[0]}    ${VM_IP_NET7[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[0]}    ${VM_IP_NET8[1]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
    \    Should Contain    ${output}    ${IP}
    Log    "STEP 4 : Dissociate EVPN2 From ROUTERS"
    ${Req_no_of_routers} =    Evaluate    1
    Dissociate L3VPN From Routers    ${Req_no_of_routers}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
    \    Should Not Contain    ${output}    ${IP}
    Log    "STEP 5 : ASSOCIATE NET1 NET2 TO EVPN1 AND RTR2 TO EVPN2 FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    ${Req_no_of_routers} =    Evaluate    1
    Associate L3VPN To Routers    ${Req_no_of_routers}


*** Keywords ***

Pretest Setup
    [Documentation]    Test Case Pretest Setup
    Log    START PRETEST SETUP
    Create Setup

Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log To Console    "Running Test case level Pretest Cleanup"
    Log    START PRETEST CLEANUP
    Get Test Teardown Debugs
    Delete Setup

Create Setup
    [Documentation]    Associate EVPN To Routers
    Log    "STEP 1 : ASSOCIATE NET1 NET2 AND RTR1 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    ${Req_no_of_routers} =    Evaluate    1
    Associate L3VPN To Routers    ${Req_no_of_routers}

Delete Setup
    [Documentation]    Dissociate EVPN From Routers 
    Log    "STEP 1 : Dissociate EVPN From NET1 NET2 AND RTR1"
    ${Req_no_of_net} =    Evaluate    2
    Dissociate L3VPN    ${Req_no_of_net}
    ${Req_no_of_routers} =    Evaluate    1
    Dissociate L3VPN From Routers    ${Req_no_of_routers}

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection
    :FOR   ${NET}   IN   @{REQ_NETWORKS_ASSOCIATION_TESTAREA4_EVPN1}
    \    ${network_id} =    Get Net Id    ${NET}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${network_id}
    :FOR   ${NET}   IN   @{REQ_NETWORKS_ASSOCIATION_TESTAREA4_EVPN2}
    \    ${network_id} =    Get Net Id    ${NET}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[1]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    \    Should Contain    ${resp}    ${network_id}


Associate L3VPN To Routers
    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associating router to L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_ROUTER}
    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index}]}    ${devstack_conn_id}
    \    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${router_id}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_ROUTER}
    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index+1}]}    ${devstack_conn_id}
    \    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[1]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    \    Should Contain    ${resp}    ${router_id}

Dissociate L3VPN
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociate L3VPN from networks
    ${devstack_conn_id} =    Get ControlNode Connection
    Log Many    "Number of network"    ${NUM_OF_NET}
    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETS}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Not Contain    ${resp}    ${network_id}

Dissociate L3VPN From Routers
    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociating router from L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_ROUTER}
    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index}]}    ${devstack_conn_id}
    \    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Not Contain    ${resp}    ${router_id}

Verify Ping
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
    [Documentation]    Verify Ping among VMs
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}    ping -c 3 ${VM_IP2}
    Should Contain    ${output}    ${REQ_PING_REGEXP}

Verify VM Is ACTIVE
    [Arguments]    ${vm_name}
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova show ${vm_name} | grep OS-EXT-STS:vm_state    30s
    Log    ${output}
    Should Contain    ${output}    active

Reboot VM
    [Arguments]    @{vm_list}
    [Documentation]    Reboot vm and verify the VM is active or not.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    : FOR    ${Vm}    IN    @{vm_list}
    \    ${command}    Set Variable    nova reboot  ${Vm}
    \    ${output}=    Write Commands Until Prompt    ${command}    30s
    \    sleep    60
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    ${output}
    [Return]    ${output}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST_TEST_TOPOLOGY_4[${index}]}    ${VM_INSTANCES_DPN1_TEST_TOPOLOGY_4[${index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    ${start} =     Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    :FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST_TEST_TOPOLOGY_4[${index}]}    ${VM_INSTANCES_TEST_TOPOLOGY_4[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    :FOR    ${VM}    IN    @{VM_INSTANCES_TEST_TOPOLOGY_4}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}

Remove RSA Key From KnowHosts
    [Arguments]    ${vm_ip}
    [Documentation]    Remove RSA
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo cat /root/.ssh/known_hosts    30s
    Log    ${output}
    ${output}=    Write Commands Until Prompt    sudo ssh-keygen -f "/root/.ssh/known_hosts" -R ${vm_ip}    30s
    Log    ${output}
    ${output}=    Write Commands Until Prompt    sudo cat "/root/.ssh/known_hosts"    30s
    Log    ${output}
    Close Connection

Get Fib Entries
    [Arguments]    ${session}
    [Documentation]    Get Fib table entries from ODL session
    ${resp}    RequestsLibrary.Get Request    ${session}    ${FIB_ENTRIES_URL}
    Log    ${resp.content}
    [Return]    ${resp.content}

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET1_TEST_TOPOLOGY_4}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET2_TEST_TOPOLOGY_4}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET3_TEST_TOPOLOGY_4}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET4_TEST_TOPOLOGY_4}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET5_TEST_TOPOLOGY_4}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET6_TEST_TOPOLOGY_4}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET7_TEST_TOPOLOGY_4}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET8_TEST_TOPOLOGY_4}
    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET1_TEST_TOPOLOGY_4}
    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET2_TEST_TOPOLOGY_4}
    ${VM_IP_NET3}    ${DHCP_IP3}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET3_TEST_TOPOLOGY_4}
    ${VM_IP_NET4}    ${DHCP_IP4}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET4_TEST_TOPOLOGY_4}
    ${VM_IP_NET5}    ${DHCP_IP5}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET5_TEST_TOPOLOGY_4}
    ${VM_IP_NET6}    ${DHCP_IP6}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET6_TEST_TOPOLOGY_4}
    ${VM_IP_NET7}    ${DHCP_IP7}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET7_TEST_TOPOLOGY_4}
    ${VM_IP_NET8}    ${DHCP_IP8}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET8_TEST_TOPOLOGY_4}
    Log    ${VM_IP_NET1}
    Log    ${VM_IP_NET2}
    Log    ${VM_IP_NET3}
    Log    ${VM_IP_NET4}
    Log    ${VM_IP_NET5}
    Log    ${VM_IP_NET6}
    Log    ${VM_IP_NET7}
    Log    ${VM_IP_NET8}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    Should Not Contain    ${VM_IP_NET3}    None
    Should Not Contain    ${VM_IP_NET4}    None
    Should Not Contain    ${VM_IP_NET5}    None
    Should Not Contain    ${VM_IP_NET6}    None
    Should Not Contain    ${VM_IP_NET7}    None
    Should Not Contain    ${VM_IP_NET8}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    ${VM_IP_NET5}    ${VM_IP_NET6}    ${VM_IP_NET7}    ${VM_IP_NET8}

Delete L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Delete L3VPN
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
    \    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}

Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Creates L3VPN and verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    l3vni=${CREATE_L3VNI[${index}]}    tenantid=${tenant_id}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*

Get Gateway MAC And IP Address
    [Arguments]    ${router_Name}
    [Documentation]    Get Gateway mac and IP Address
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    neutron router-port-list ${router_Name}    30s
    @{MacAddr-list} =    Get Regexp Matches    ${output}    ${MAC_REGEX}
    @{IpAddr-list} =    Get Regexp Matches    ${output}    ${IP_REGEX}
    [Return]    ${MacAddr-list}    ${IpAddr-list}

Add Interfaces To Routers
    [Documentation]    Add Interfaces
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA4}
    \    Add Router Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
    : FOR    ${INTERFACE}    IN    @{ROUTER2_INTERFACE_TESTAREA4}
    \    Add Router Interface    ${REQ_ROUTERS[1]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${REQ_ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA4}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    ${interface_output} =    Show Router Interface    ${REQ_ROUTERS[1]}
    : FOR    ${INTERFACE}    IN    @{ROUTER2_INTERFACE_TESTAREA4}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    ${GWMAC_ADDRS_ROUTER1_TESTAREA4}    ${GWIP_ADDRS_ROUTER1_TESTAREA4} =    Get Gateway MAC And IP Address    ${REQ_ROUTERS[0]}
    Log    ${GWMAC_ADDRS_ROUTER1_TESTAREA4}
    Set Suite Variable    ${GWMAC_ADDRS_ROUTER1_TESTAREA4}
    Log    ${GWIP_ADDRS_ROUTER1_TESTAREA4}
    Set Suite Variable    ${GWIP_ADDRS_ROUTER1_TESTAREA4}

Delete And Recreate VM And Port
    [Arguments]    ${VM_NAME}    ${PORT_NAME}
    [Documentation]    Delete VM and recreate the port and VM
    Delete Port    ${PORT_NAME}
    Delete Vm Instance    ${VM_NAME}
    Create Port    @{REQ_NETWORKS}[0]    ${PORT_NAME}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_PORT_URL}    ${REQ_PORT_LIST}
    Create Vm Instance With Port On Compute Node    ${PORT_NAME}    ${VM_NAME}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_NAME}

Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    Delete BGP Configuration On ODL    session
    ${output} =    Get BGP Configuration On ODL    session
    Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
    Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
    Log    ${output}

Create BGP Config On ODL
    [Documentation]    Create BGP Config on ODL
    Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    Get BGP Configuration On ODL    session
    Log    ${output}
    Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP Config on DCGW
    Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME[0]}    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    Log    ${output}
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    Log    ${output1}
    Should Contain    ${output1}    ${LOOPBACK_IP}

Verify Tunnel Status as UP
    [Documentation]    Verify that the tunnels are UP
    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_DOWN}

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    ${resp}=    Should Contain    ${flow_output}    table=51
    Log    ${resp}

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of ports under previously created subnets
    Log     ${PORT_LIST_TEST_TOPOLOGY_4}
    ${REQUIRED_PORT_LIST}=    Get Slice From List    ${PORT_LIST_TEST_TOPOLOGY_4}    0    ${NUM_OF_PORTS}
    Log     ${REQUIRED_PORT_LIST}
    Log To Console    "REQUIRED PORT LIST IS"
    Log To Console    ${REQUIRED_PORT_LIST}
    :FOR    ${item}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port_name}    Get From List    ${PORT_LIST_TEST_TOPOLOGY_4}     ${item}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer     ${net}
    \    ${network}    Get From List       ${REQ_NETWORKS}    ${net-1}
    \    Create Port     ${network}    ${port_name}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_PORT_URL}    ${PORT_LIST_TEST_TOPOLOGY_4}
