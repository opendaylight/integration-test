*** Settings ***
Documentation      Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster TESTAREA1
Test Setup         Pretest Setup
Test Teardown      Pretest Cleanup
Library            RequestsLibrary
Library            SSHLibrary
Library            Collections
Library            String
Resource           ../../../csit/libraries/Utils.robot
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
@{EXTRA_NW_IP}    10.50.0.2
@{SUBNET_IP_NET50}    10.50.0.0

*** Test Cases ***

TC1 7.1.1 Verification of intra_network_intra_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.1
    [Tags]    Nightly
    [Setup]    Log    NO PRETEST Setup
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.1 Verification Of Intra_Network_Intra_Openvswitch network connectivity ${\n}"
    Validation_OpenFlow_Node_Inventory_BGP
    Log    "Log PING VNF11 <-> VNF12 AND VNF21 <-> VNF22"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{REQ_SUBNET_CIDR_TESTAREA1}
    \    Should Contain    ${output}    ${IP}

TC2 7.1.2 Verification of intra_network_inter_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.2
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.2 Verification of intra_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF13 AND VNF21 <-> VNF23"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[2]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
    \    Should Contain    ${output}    ${IP}

TC3 7.1.3 Verification of inter_network_intra_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.3
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.3 Verification of inter_network_intra_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF21 AND VNF12 <-> VNF22"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[1]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
    \    Should Contain    ${output}    ${IP}

TC4 7.1.4 Verification of inter_network_inter_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.4
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.4 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF23 and VNF12 <-> VNF24"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
    \    Should Contain    ${output}    ${IP}

TC5_TC6 7.1.5 7.1.6 Verification of subnet route and VNF as gateway for enterprise network n after VNF reboot
    [Documentation]    Testcase Id 7.1.5
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.5 Verification of subnet route and VNF as gateway for enterprise network ${\n} 7.1.6 Verification of subnet route and VNF as gateway after VNF reboot ${\n}"
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
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{SUBNET_IP_NET50}  
    \    Should Contain    ${output}    ${IP} 
    Log    "STEP 2 : PING VNF14 <-> VNF11 AND VNF14 <-> External route on VNF11"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    @{EXTRA_NW_IP}[0]
 
    Reboot Nova VM    @{REQ_VM_INSTANCES_NET1}[0]

    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{SUBNET_IP_NET50}  
    \    Should Contain    ${output}    ${IP} 
    Log    "STEP 2 : PING VNF14 <-> VNF11 AND VNF14 <-> External route on VNF11"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    @{EXTRA_NW_IP}[0]


#TC7 7.1.7 Verification of VNF reboot across L3VPNoVxLAN
#    [Documentation]    Testcase Id 7.1.7
#    [Tags]    Nightly
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.7 Verification of VNF reboot across L3VPNoVxLAN ${\n}"
#    Log    "STEP 2 : PING VNF11 <-> VNF23 and VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    Log    "STEP 3 : REBOOT 8 VNFs AND VERIFY PING ACROSS THEM"
#    ${VM_INST} =    Create List    @{REQ_VM_INSTANCES_NET1}    @{REQ_VM_INSTANCES_NET2}
#    : FOR    ${VM_INSTANCE}    IN    @{VM_INST}
#    \    Reboot Nova VM    ${VM_INSTANCE}
#    Log    "STEP 2 : PING VNF11 <-> VNF23 and VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
#    \    Should Contain    ${output}    ${IP}

#TC8_TC9 7.1.8 7.1.9 Verification of VNF deletion (nova delete) and recreation (nova boot) across L3VPNoVxLAN
#    [Documentation]    Testcase Id 7.1.8 7.1.9
#    [Tags]    Nightly
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.8 Verification of VNF deletion and recreation across L3VPNoVxLAN ${\n}"
#    Log    "STEP 2 : PING VNF11 <-> VNF23 and VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    Log    "STEP 3 : NOVA DELETE THE VNFs ONE BY ONE"
#    ${VM_INST} =    Create List    @{REQ_VM_INSTANCES_NET1}    @{REQ_VM_INSTANCES_NET2}
#    : FOR    ${VmInstance}    IN    @{VM_INST}
#    \    Delete Vm Instance    ${VmInstance}
#    ${VM_IP_LIST} =    Create List    @{VM_IP_NET1}    @{VM_IP_NET2}
#    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
#    \    Remove RSA Key From KnowHosts     ${VM_IP}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
#    \    Should Not contain    ${output}    ${IP}
#    Log    "STEP 4 : NOVA CREATE THE VNFs ONE BY ONE"
#    ${Req_no_of_vms_per_dpn} =    Evaluate    4
#    Create Nova VMs     ${Req_no_of_vms_per_dpn}
#    ${VM_IP_NET1}    ${VM_IP_NET2}    Wait Until Keyword Succeeds    300s    10s    Verify VMs received IP
#    Set Global Variable    ${VM_IP_NET2}
#    Set Global Variable    ${VM_IP_NET1}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
#    \    Should Contain    ${output}    ${IP}

#TC11 7.1.11 Verification of new VNF bring up across already existed L3VPNoVxLAN
#    [Documentation]    Testcase Id 7.1.11
#    [Tags]    Nightly
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.11 Verification of new VNF bring up across already existed L3VPNoVxLAN ${\n}"
#    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    Log    "STEP 3 : CREATE VNF15 ON OPENVSWITCH1 AND CHECK PING FROM ALL OTHER VNFs AND ASR"
#    Create Port    @{REQ_NETWORKS}[0]    @{PORT_LIST_NEW}[0]    sg=${SECURITY_GROUP}
#    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_PORT_URL}    ${PORT_LIST_NEW}
#    Create Vm Instance With Port On Compute Node    @{PORT_LIST_NEW}[0]    ${VM_NAME_NEW}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
#    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_NAME_NEW}
#    ${VM_IP_NET1_New}    ${VM_IP_NET2_New}    Wait Until Keyword Succeeds    300s    10s    Verify VMs received IP
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1_New}    @{VM_IP_NET2_New}
#    \    Should Contain    ${output}    ${IP}
#    Log    "STEP 4 : DELETE VNF15 CREATED"
#    Delete Vm Instance    ${VM_NAME_NEW}
#    Delete Port    @{PORT_LIST_NEW}[0]

#TC16_TC17 7.1.16 7.1.17 Verify disassociation and re association of networks from L3VPNoVxLAN
#    [Documentation]    Testcase Id 7.1.6
#    [Tags]    Nightly
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.6 Verify disassociation of networks from L3VPNoVxLAN ${\n} 7.1.17 Verify re association of networks from L3VPNoVxLAN ${\n}"
#    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    ${output}=    Get Fib Entries    session
#    Log    "STEP 3 : Dissociate L3VPN From Networks"
#    ${Req_no_of_net} =    Evaluate    2
#    Dissociate L3VPN    ${Req_no_of_net}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
#    \    Should Not Contain    ${output}    ${IP}
#    Log    "STEP 4 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
#    \    Should Contain    ${output}    ${IP}

#TC18 7.1.18 7.1.19 Verify deletion recreation and re associate L3VPNoVxLAN which has networks associated
#    [Documentation]    Testcase Id 7.1.18
#    [Tags]    Nightly
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.18 Verify deletion L3VPNoVxLAN which has networks associated ${\n} 7.1.19 Verify recreation of L3VPNoVxLAN and re associate the networks ${\n}"
#    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
#    \    Should Contain    ${output}    ${IP}
#    Log    "STEP 3 : DELETE L3VPN"
#    ${Req_no_of_L3VPN} =    Evaluate    1
#    Delete L3VPN    ${Req_no_of_L3VPN}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
#    \    Should Not Contain    ${output}    ${IP}
#    Log    "STEP 4 : CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID"
#    ${Req_no_of_L3VPN} =    Evaluate    1
#    Create L3VPN    ${Req_no_of_L3VPN}
#    Log    "STEP 5 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}
#    Log    "STEP 6 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
#    \    Should Contain    ${output}    ${IP}

#TC10 7.1.10 Verification of VNF port deletion (neutron port delete) across L3VPNoVxLAN
#    [Documentation]    Testcase Id 7.1.10
#    [Tags]    Nightly
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.10 Verification of VNF neutron port delete across L3VPNoVxLAN ${\n}"
#    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    Log    "STEP 3 : DELETE NEUTRON PORT PORT11"
#    Delete Port    @{REQ_PORT_LIST}[0]
#    ${output}=    Get Fib Entries    session
#    Should Not Contain    ${output}    ${VM_IP_NET1[0]}
#    Log    "STEP 4 : DELETE AND RECREATE VM AND PORT"
#    Delete And Recreate VM And Port    @{VM_INSTANCES}[0]    @{REQ_PORT_LIST}[0]
#    ${VM_IP_NET1}    ${VM_IP_NET2}    Wait Until Keyword Succeeds    300s    10s    Verify VMs received IP
#    Set Global Variable    ${VM_IP_NET2}
#    Set Global Variable    ${VM_IP_NET1}
#    Create Setup

#TC23 7.1.23 Verify ASR DCGW BGP session down from CSC
#    [Documentation]    Verify ASR DCGW BGP session down from CSC
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.23 Verify ASR DCGW BGP session down from CSC"
#    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Success    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
#    ${output} =    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    
#    \    Should Contain    ${output}    ${IP}
#    Log    "STEP 3 : CHECK BGP NEIGHBORSHIP ESTED"
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    Log    ${output}
#    Log    "STEP 4 : DELETE THE BGP config on DCGW"
#    Delete BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
#    Log    "STEP 5 : CHECK BGP NEIGHBORSHIP ESTED"
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga NEG    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    Log    ${output}
#    Log    "STEP 6 : Verifying The Added Route On ASR From VNF Which Should Not be Pingable"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Failure    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${LOOPBACK_IP}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Failure    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping Failure    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${LOOPBACK_IP1}
#    ${output} =    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}   
#    \    Should Contain    ${output}    ${IP}

#*** Keywords ***

#Pretest Setup
#    [Documentation]    Test Case Pretest Setup
#    Log    START PRETEST SETUP
#    Create Setup

#Pretest Cleanup
#    [Documentation]    Test Case Cleanup
#    Log To Console    "Running Test case level Pretest Cleanup"
#    Log    START PRETEST CLEANUP
#    Get Test Teardown Debugs
#    Delete Setup

#Create Setup
#    [Documentation]    Associate EVPN To Networks
#    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}

#Delete Setup
#    [Documentation]    Dissociate EVPN From Networks 
#    Log    "STEP 1 : Dissociate L3VPN From Networks"
#    ${Req_no_of_net} =    Evaluate    2
#    Dissociate L3VPN    ${Req_no_of_net}

#Verify BGP Neighbor Status On Quagga NEG
#    [Arguments]    ${dcgw_ip}    ${neighbor_ip}
#    [Documentation]    Verify bgp neighbor status on quagga
#    ${output} =    Execute Show Command On quagga    ${dcgw_ip}    show bgp neighbors ${neighbor_ip}
#    Log    ${output}
#    Should Not Contain    ${output}    BGP state = Established

#Associate L3VPN To Networks
#    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Associates L3VPN to networks and verify
#    ${devstack_conn_id} =    Get ControlNode Connection
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NET}
#    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
#    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Contain    ${resp}    ${network_id}

#Dissociate L3VPN
#    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Dissociate L3VPN from networks
#    ${devstack_conn_id} =    Get ControlNode Connection
#    Log Many    "Number of network"    ${NUM_OF_NET}
#    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETS}
#    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
#    \    Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Not Contain    ${resp}    ${network_id}

#Verify Ping Success
#    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
#    [Documentation]    Verify Ping Success among VMs
#    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}    ping -c 3 ${VM_IP2}
#    Should Contain    ${output}    ${REQ_PING_REGEXP}

#Verify Ping Failure
#    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
#    [Documentation]    Verify Ping Success among VMs
#    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}    ping -c 3 ${VM_IP2}
#    Should Contain    ${output}    , 100% packet loss

#Create Nova VMs
#    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Create Vm instances on compute nodes
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_VMS_PER_DPN}
#    \    Create Vm Instance With Port On Compute Node    ${VM_INSTANCES_DPN1_PORTS[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
#    \    Create Vm Instance With Port On Compute Node    ${VM_INSTANCES_DPN2_PORTS[${index}]}    ${VM_INSTANCES_DPN2[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
#    :FOR    ${VM}    IN    @{REQ_VM_INSTANCES_NET1}    @{REQ_VM_INSTANCES_NET2}
#    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}

#Remove RSA Key From KnowHosts
#    [Arguments]    ${vm_ip}
#    [Documentation]    Remove RSA
#    ${devstack_conn_id}=    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${output}=    Write Commands Until Prompt    sudo cat /root/.ssh/known_hosts    30s
#    Log    ${output}
#    ${output}=    Write Commands Until Prompt    sudo ssh-keygen -f "/root/.ssh/known_hosts" -R ${vm_ip}    30s
#    Log    ${output}
#    ${output}=    Write Commands Until Prompt    sudo cat "/root/.ssh/known_hosts"    30s
#    Log    ${output}
#    Close Connection

#Get Fib Entries
#    [Arguments]    ${session}
#    [Documentation]    Get Fib table entries from ODL session
#    ${resp}    RequestsLibrary.Get Request    ${session}    ${FIB_ENTRIES_URL}
#    Log    ${resp.content}
#    [Return]    ${resp.content}

#Get Inventory Nodes
#    [Arguments]    ${session}
#    [Documentation]    Get Inventory Nodes using rest
#    ${resp}    RequestsLibrary.Get Request    ${session}    /restconf/operational/opendaylight-inventory:nodes
#    Log    ${resp.content}
#    [Return]    ${resp.content}

#Verify VMs received IP
#    [Documentation]    Verify VM received IP
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{REQ_VM_INSTANCES_NET1}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{REQ_VM_INSTANCES_NET2}
#    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET1}
#    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET2}
#    Log    ${VM_IP_NET1}
#    Log    ${VM_IP_NET2}
#    Should Not Contain    ${VM_IP_NET2}    None
#    Should Not Contain    ${VM_IP_NET1}    None
#    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}

#Delete L3VPN
#    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Delete L3VPN
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
#    \    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}

#Create L3VPN
#    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Creates L3VPN and verify the same
#    ${devstack_conn_id} =    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]    ${devstack_conn_id}
#    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
#    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    l3vni=${CREATE_L3VNI[${index}]}    tenantid=${tenant_id}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
#    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
#    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*

#Delete And Recreate VM And Port
#    [Arguments]    ${VM_NAME}    ${PORT_NAME}
#    [Documentation]    Delete VM and recreate the port and VM
#    Delete Vm Instance    ${VM_NAME}
#    Create Port    @{REQ_NETWORKS}[0]    @{REQ_PORT_LIST}[0]    sg=${SECURITY_GROUP}
#    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_PORT_URL}    ${REQ_PORT_LIST}
#    Create Vm Instance With Port On Compute Node    ${PORT_NAME}    ${VM_NAME}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
#    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_NAME}

#Delete BGP Config On ODL
#    [Documentation]    Delete BGP Configuration on ODL
#    Delete BGP Configuration On ODL    session
#    ${output} =    Get BGP Configuration On ODL    session
#    Log    ${output}
#    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
#    Log    ${output}
#    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
#    Log    ${output}

#Create BGP Config On ODL
#    [Documentation]    Create BGP Config on ODL
#    Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
#    AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
#    ${output} =    Get BGP Configuration On ODL    session
#    Log    ${output}
#    Should Contain    ${output}    ${DCGW_SYSTEM_IP}

#Create BGP Config On DCGW
#    [Documentation]    Configure BGP Config on DCGW
#    Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME[0]}    ${DCGW_RD}
#    ...    ${LOOPBACK_IP}
#    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
#    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
#    Log    ${output}
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    Log    ${output}
#    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
#    Log    ${output1}
#    Should Contain    ${output1}    ${LOOPBACK_IP}

#Verify ITM Status
#    [Arguments]    ${state}
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
#    Should Contain    ${output}    ${state}

#Get Output From Dcgw
#    [Arguments]    ${dcgw_ip}    ${cmd}
#    ${dcgw_conn_id} =    Open_Connection_To_Tools_System    ip_address=${dcgw_ip}
#    Switch Connection    ${dcgw_conn_id}
#    ${output}    Write Commands Until Prompt    ${cmd}    30
#    Close Connection
#    [Return]    ${output}

#Verify L3VPN
#    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Verify the same
#    ${devstack_conn_id} =    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]    ${devstack_conn_id}
#    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
#    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
#    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*

#Verify Tunnel Status as UP
#    [Documentation]    Verify that the tunnels are UP
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
#    Log    ${output}
#    Should Contain    ${output}    ${STATE_UP}
#    Should Not Contain    ${output}    ${STATE_DOWN}

