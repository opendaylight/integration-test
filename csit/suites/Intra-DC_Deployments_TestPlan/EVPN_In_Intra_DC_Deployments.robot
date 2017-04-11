*** Settings ***
Documentation      Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster
Test Setup         Pretest Setup
Test Teardown      Pretest Cleanup
Library            RequestsLibrary
Library            SSHLibrary
Resource           ../../../csit/libraries/OpenStackOperations.robot
Resource           ../../../csit/libraries/DevstackUtils.robot
Resource           ../../libraries/SetupUtils.robot
Resource           ../../libraries/KarafKeywords.robot
Resource           ../../libraries/VpnOperations.robot
Variables          ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.py
Resource           ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
Resource           ../../../csit/libraries/Utils.robot
Resource           ../../../csit/libraries/BgpOperations.robot
Variables          ../../variables/Variables.py


*** Test Cases ***

TC1 7.1.1 Verification of intra_network_intra_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.1 Verification of intra_network_intra_openvswitch network connectivity
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.1 Verification Of Intra_Network_Intra_Openvswitch network connectivity ${\n}"
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STEP 2 : PING VNF11 <-> VNF12 AND VNF21 <-> VNF22"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}


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
    [Documentation]    Create Required number of EVPN, add BGP configuration, verify ITM tunnels are up and verify if the VM's are UP
    Log    "STEP 1 : CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID"
    ${Req_no_of_L3VPN} =    Evaluate    1
    Create L3VPN    ${Req_no_of_L3VPN}
    Log    "STEP 2 : ADD BGP NEIGHBOUR ( ASR AS DCGW ) AND CHECK BGP CONNECTION"
    Create BGP Config On ODL
    Create BGP Config On DCGW
    Log    VERIFY TUNNELS BETWEEN DPNS IS UP
    Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
    Log    VERIFY FLOWS ARE PRESENT ON THE DPNS
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    VERIFY THE VM IS ACTIVE
    :FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}


Delete Setup
    [Documentation]    Dissociate EVPN From Networks, Delete EVPN created and unconfigure BGP 
    Log    "STEP 1 : Dissociate L3VPN From Networks, DELETE L3VPN AND UNCONFIG BGP"
    ${Req_no_of_net} =    Evaluate    2
    Dissociate L3VPN    ${Req_no_of_net}
    Log    DELETE L3VPN
    ${Req_no_of_L3VPN} =    Evaluate    1
    Delete L3VPN    ${Req_no_of_L3VPN}
    Log    DELETE BGP CONFIG ON ODL
    Delete BGP Config On ODL

Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Creates L3VPN and verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    l3vni=${CREATE_L3VNI}    tenantid=${tenant_id}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI}.*

Delete L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Delete L3VPN
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
    \    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${NETWORKS[${index}]}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${network_id}

Dissociate L3VPN
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociate L3VPN from networks
    ${devstack_conn_id} =    Get ControlNode Connection
    Log Many    "Number of network"    ${NUM_OF_NET}
    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETS}
    \    ${network_id} =    Get Net Id    ${NETWORKS[${index}]}    ${devstack_conn_id}
    \    Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Not Contain    ${resp}    ${network_id}

Verify Ping
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
    [Documentation]    Verify Ping among VMs
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}    ping -c 3 ${VM_IP2}
    Should Contain    ${output}    ${PING_REGEXP}

Verify Tunnel Status as UP
    [Documentation]    Verify that the tunnels are UP
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
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

Verify VM Is ACTIVE
    [Arguments]    ${vm_name}
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova show ${vm_name} | grep OS-EXT-STS:vm_state    30s
    Log    ${output}
    Should Contain    ${output}    active

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

Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    Delete BGP Configuration On ODL    session
    ${output} =    Get BGP Configuration On ODL    session
    Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
    Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
    Log    ${output}
