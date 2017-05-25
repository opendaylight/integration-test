#*** Settings ***
#Documentation     Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster TESTAREA5
#Test Setup        Pretest Setup
#Test Teardown     Pretest Cleanup
#Library           RequestsLibrary
#Library           SSHLibrary
#Library           Collections
#Library           String
#Resource           ../../../csit/libraries/Utils.robot
#Resource          ../../../csit/libraries/OpenStackOperations.robot
#Resource          ../../../csit/libraries/DevstackUtils.robot
#Resource          ../../libraries/SetupUtils.robot
#Resource          ../../libraries/KarafKeywords.robot
#Resource          ../../libraries/VpnOperations.robot
#Resource          ../../../csit/libraries/Utils.robot
#Resource          ../../libraries/BgpOperations.robot
#Resource          ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
#Variables         ../../variables/Variables.py
#
#*** Variables ***
#${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
#@{PORT_LIST_NEW}    PORT15
#${VM_NAME_NEW}    VM15
#${MAC_REGEX}      (([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))
#${IP_REGEX}       (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])
#${Req_no_of_ports}    16
#${Req_no_of_vms_per_dpn}    8
#
#*** Test Cases ***
#CREATE TEST TOPOLOGY FOR TEST AREA 5
#    [Documentation]    CREATE TEST TOPOLOGY FOR TEST AREA 4
#    [Tags]    Nightly
#    [Setup]    Log    NO PRETEST SETUP
#    Log    Delete Interface From Router
#    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA4}
#    \    Remove Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
#    :FOR    ${INTERFACE}    IN    @{ROUTER2_INTERFACE_TESTAREA4}
#    \    Remove Interface    ${REQ_ROUTERS[1]}    ${INTERFACE}
#    Log    ADD INTERFACE NET3 NET4 TO RTR1
#    Log    ADD INTERFACE NET7 NET8 TO RTR2
#    Add Interfaces To Routers
#    Log    Delete the VM instances
#    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
#    \    Delete Vm Instance    ${VmInstance}
#    Log    Delete neutron ports
#    : FOR    ${Port}    IN    @{PORT_LIST_TEST_TOPOLOGY_4}
#    \    Delete Port    ${Port}
#    Log    CREATE PORTS
#    Create Neutron Ports    ${Req_no_of_ports}
#    Log    CREATE VM INSTANCES
#    Create Nova VMs    ${Req_no_of_vms_per_dpn}
#    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    ${VM_IP_NET5}    ${VM_IP_NET6}    ${VM_IP_NET7}
#    ...    ${VM_IP_NET8}    Wait Until Keyword Succeeds    300s    10s    Verify VMs received IP
#    Set Global Variable    ${VM_IP_NET2}
#    Set Global Variable    ${VM_IP_NET1}
#    Set Global Variable    ${VM_IP_NET3}
#    Set Global Variable    ${VM_IP_NET4}
#    Set Global Variable    ${VM_IP_NET5}
#    Set Global Variable    ${VM_IP_NET6}
#    Set Global Variable    ${VM_IP_NET7}
#    Set Global Variable    ${VM_IP_NET8}
#    Comment    Log    Delete Interface From Router RTR1
#    Comment    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA3}
#    Comment    \    Remove Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
#    Log    DELETE BGP CONFIG ON ODL
#    Delete BGP Config On ODL
#    Log    DELETE L3VPN
#    ${Req_no_of_L3VPN} =    Evaluate    1
#    Delete L3VPN    ${Req_no_of_L3VPN}
#    Log    CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID
#    ${Req_no_of_L3VPN} =    Evaluate    2
#    Create L3VPN    ${Req_no_of_L3VPN}
#    Log    ADD BGP NEIGHBOUR ( ASR AS DCGW ) AND CHECK BGP CONNECTION
#    Create BGP Config On ODL
#    Create BGP Config On DCGW
#    Log    VERIFY TUNNELS BETWEEN DPNS IS UP
#    Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
#    Log    VERIFY FLOWS ARE PRESENT ON THE DPNS
#    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
#    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
#    Log    VERIFY ALL VM's ARE IN ACTIVE STATE
#    : FOR    ${VM}    IN    @{VM_INSTANCES_TEST_TOPOLOGY_4}
#    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
#    Log    ASSOCIATE NET1 NET2 AND RTR1 TO EVPN1 AND NET5 NET6 AND RTR2 TO EVPN2 FROM CSC
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}
#    ${Req_no_of_routers} =    Evaluate    1
#    Associate L3VPN To Routers    ${Req_no_of_routers}
#    [Teardown]    Log    NO PRETEST Teardown
#
#TC78 7.5.1 Verify network connectivity between VNF_Network_L3VPN1 to VNF_Router_L3VPN2 on intra_openvswitch
#    Log    "Testcases covered as per Testplan ${\n} 7.5.1 Verify network connectivity between VNF_Network to VNF_Router on intra_openvswitch for L3VPNoVxLAN1"
#    Log    "STEP 2 : 7 PING "VNF11 <-> VNF71, VNF21<-> VNF81"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET7[0]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET8[0]}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET7}    @{VM_IP_NET8}    @{REQ_SUBNET_CIDR_TESTAREA5}
#    \    Should Contain    ${iproute}    ${IP}
#
#TC79 7.5.2 Verify network connectivity between VNF_Network_VPN1 to VNF_Router_VPN2 on inter_openvswitch for L3VPNoVxLAN1
#    Log    "Testcases covered as per Testplan ${\n} 7.5.2 Verify network connectivity between VNF_Network to VNF_Router on inter_openvswitch for L3VPNoVxLAN1"
#    Log    "STEP 2 : PING VNF11 <-> VNF52, VNF21<-> VNF82"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET5[1]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET8[1]}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET5}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#
#TC80_TC81 7.5.3_7.5.4 Verify disassociation of Network from L3VPNoVxLAN1 and router \ from L3VPNoVxLAN2
#    Log    "Testcases covered as per Testplan ${\n} 7.5.3 Verify disassociation of Network from L3VPNoVxLAN1 7.5.4 Verify disassociation of routers from L3VPNoVxLAN2
#    Log    "STEP 1 : PING VNF11 <-> VNF72, VNF21<-> VNF82 "
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET7[1]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET8[1]}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#    Log    "STEP 2 : Dissociate L3VPN1 From Networks"
#    ${Req_no_of_net} =    Evaluate    2
#    Dissociate L3VPN    ${Req_no_of_net}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Not Contain    ${output}    ${IP}
#    Log    "STEP 3 : PING VNF51 <-> VNF72 VNF61<-> VNF82 "
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[4]    ${VM_IP_NET5[0]}    ${VM_IP_NET7[1]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[0]}    ${VM_IP_NET8[1]}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#    Log    "STEP 4 : Dissociate EVPN2 From ROUTERS"
#    ${Req_no_of_routers} =    Evaluate    1
#    Dissociate L3VPN From Routers    ${Req_no_of_routers}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Not Contain    ${output}    ${IP}
#    Log    "STEP 5 : ASSOCIATE NET1 NET2 TO EVPN1 AND RTR2 TO EVPN2 FROM CSC"
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}
#    ${Req_no_of_routers} =    Evaluate    1
#    Associate L3VPN To Routers    ${Req_no_of_routers}
#
#TC83_TC84 7.5.5_7.5.6 Verify deletion and recreation of L3VPNoVxLAN1 and its impact on L3VPNoVxLAN2
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.5.5 Verify deletion of L3VPNoVxLAN1 does not impact on L3VPNoVxLAN2 7.5.6 Verify recreation of L3VPNoVxLAN1 does not impact other L3VPNoVxLAN2"
#    Log    "STEP 1 : PING VNF51 <-> VNF82, VNF61<-> VNF72"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[4]    ${VM_IP_NET5[0]}    ${VM_IP_NET8[1]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[0]}    ${VM_IP_NET7[1]}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#    Log    "STEP 2 : DELETE L3VPN"
#    ${Req_no_of_L3VPN} =    Evaluate    1
#    Delete L3VPN    ${Req_no_of_L3VPN}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Not Contain    ${output}    ${IP}
#    Log    "STEP 3 : CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID"
#    ${Req_no_of_L3VPN} =    Evaluate    1
#    Create L3VPN    ${Req_no_of_L3VPN}
#    Log    "STEP 4 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}
#    Log    "STEP 5 : PING VNF51 <-> VNF82, VNF61<-> VNF72"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[4]    ${VM_IP_NET5[0]}    ${VM_IP_NET8[1]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[0]}    ${VM_IP_NET7[1]}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#
#TC85_TC86 7.5.7_7.5.8 Verify manual TEP deletion and recreation scenario for L3VPNoVxLAN VNFs
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.5.7 Verify deletion L3VPNoVxLAN which has networks associated ${\n} 7.5.8 Verify recreation of L3VPNoVxLAN and re associate the networks ${\n}"
#    Log    "STEP 1 : PING VNF11 <-> VNF32, VNF21<-> VNF42"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[1]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[1]}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
#    \    Should Contain    ${output}    ${IP}
#    Log    "STEP 2 : DELETE THE TEP OF openVSwitch1 USING ODL KARAF CMD"
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
#    Log    ${output}
#    ${split_output}=    Split String    ${output}
#    ${index} =    Get Index From List    ${split_output}    ${OS_COMPUTE_1_IP}
#    ${cmd} =    Catenate    tep:delete ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
#    ${output}=    Issue Command On Karaf Console    ${cmd}
#    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
#    Log    ${output}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
#    \    Should Not Contain    ${output}    ${IP}
#    Log    "STEP 3 : READD THE TEP OF openVSwitch1 USING ODL KARAF CMD"
#    ${cmd} =    Catenate    tep:add ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
#    ${output}=    Issue Command On Karaf Console    ${cmd}
#    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
#    Log    ${output}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
#    \    Should Contain    ${output}    ${IP}
#
#TC87 7.5.11 Verify ASR route updates for L3VPNoVxLAN
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.5.11 Verify ASR route updates for L3VPNoVxLAN ${\n}"
#    Log    "STEP 1 : PING VNF51 <-> VNF72, VNF61<-> VNF82"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[4]    ${VM_IP_NET5[0]}    ${VM_IP_NET7[1]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[0]}    ${VM_IP_NET8[1]}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#    Add Address Family On DCGW    ${DCGW_SYSTEM_IP}    ${LOOPBACK_IP1}    ${AS_ID}    ${DCGW_RD}
#    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo1    ${LOOPBACK_IP1}
#    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
#    Log    ${output}
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    Log    ${output}
#    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
#    Log    ${output1}
#    Should Contain    ${output1}    ${LOOPBACK_IP1}
#    ${output}=    Get Fib Entries    session
#    :FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#    Should Contain    ${output}    ${LOOPBACK_IP1}
#    Log    "STEP 2 : ACCESS THE ADDED ROUTE ON ASR FROM VNF"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[4]    ${VM_IP_NET5[0]}    ${LOOPBACK_IP}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[4]    ${VM_IP_NET5[1]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[1]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[5]    ${VM_IP_NET6[0]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[6]    ${VM_IP_NET7[0]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[7]    ${VM_IP_NET8[0]}    ${LOOPBACK_IP1}
#    Log    "STEP 3 : DELETE ROUTE TO ASR"
#    Delete Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo1    ${LOOPBACK_IP1}
#    sleep    60
#    ${output}=    Get Fib Entries    session
#    Should Not Contain    ${output}    ${LOOPBACK_IP1}
#    :FOR    ${IP}    IN    @{VM_IP_NET5}    @{VM_IP_NET6}    @{VM_IP_NET7}    @{VM_IP_NET8}
#    \    Should Contain    ${output}    ${IP}
#
#TC88_TC89 7.5.12_7.5.13 Verify ASR DCGW deletion and readdition from CSC
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.5.12 Verify ASR DCGW deletion from CSC ${\n} 7.5.13 Verify ASR DCGW re addition from CSC ${\n}"
#    Log    "STEP 1 : CHECK BGP NEIGHBORSHIP ESTED"
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    Log    ${output}
#    Log    "STEP 2 : PING VNF11 <-> VNF32, VNF21<-> VNF42"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[1]}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[2]}
#    ${output}=    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
#    \    Should Contain    ${output}    ${IP}
#    Log    "STEP 3 : DELETE THE DCGW NEIGH USING KARAF CMD ON ODL"
#    ${BGP_DELETE_NEIGH_CMD}    Catenate    ${BGP_DELETE_NEIGH_CMD}${DCGW_SYSTEM_IP}
#    ${output} =    Issue Command On Karaf Console    ${BGP_DELETE_NEIGH_CMD}
#    ${output} =    Issue Command On Karaf Console    ${BGP_STOP_SERVER_CMD}
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Not Est Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    Log    ${output}
#    ${output} =    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
#    \    Should Not Contain    ${output}    ${IP}
#    Log    "STEP 4 : RE ADD DCGW NEIGH USING KARAF CMD ON ODL"
#    ${BGP_CONFIG_CMD}    Catenate    ${BGP_CONFIG_CMD}${ODL_SYSTEM_IP}
#    ${BGP_CONFIG_ADD_NEIGHBOR_CMD}    Catenate    ${BGP_CONFIG_ADD_NEIGHBOR_CMD}${DCGW_SYSTEM_IP} --as-num 100 --use-source-ip ${ODL_SYSTEM_IP}
#    ${output} =    Issue Command On Karaf Console    ${BGP_CONFIG_CMD}
#    ${output} =    Issue Command On Karaf Console    ${BGP_CONFIG_ADD_NEIGHBOR_CMD}
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    ${output} =    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
#    \    Should Contain    ${output}    ${IP}
#
#TC90 7.5.14 Verify ASR DCGW BGP session down from CSC
#    [Documentation]    Verify ASR DCGW BGP session down from CSC
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.5.14 Verify ASR DCGW BGP session down from CSC"
#    Log    "STEP 1 : CHECK BGP NEIGHBORSHIP ESTED"
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    Log    ${output}
#    Log    "STEP 2 : DELETE THE BGP config on DCGW"
#    Delete BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
#    Log    "STEP 3 : CHECK BGP NEIGHBORSHIP ESTED"
#    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga NEG    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
#    Log    ${output}
#    Should Not Contain    ${output}    Established
#    Log    "STEP 4 : Verifying The Added Route On ASR From VNF Which Should Not be Pingable"
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${LOOPBACK_IP}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[2]    ${VM_IP_NET3[0]}    ${LOOPBACK_IP1}
#    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[3]    ${VM_IP_NET4[0]}    ${LOOPBACK_IP1}
#    ${output} =    Get Fib Entries    session
#    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
#    \    Should Not Contain    ${output}    ${IP}
#
#*** Keywords ***
#Pretest Setup
#    [Documentation]    Test Case Pretest Setup
#    Log    START PRETEST SETUP
#    #Create Setup
#
#Pretest Cleanup
#    [Documentation]    Test Case Cleanup
#    Log To Console    "Running Test case level Pretest Cleanup"
#    Log    START PRETEST CLEANUP
#    Get Test Teardown Debugs
#    #Delete Setup
#
#Create Setup
#    [Documentation]    Associate EVPN To Routers
#    Log    "STEP 1 : ASSOCIATE NET1 NET2 AND RTR1 TO EVPN FROM CSC"
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}
#    ${Req_no_of_routers} =    Evaluate    1
#    Associate L3VPN To Routers    ${Req_no_of_routers}
#
#Delete Setup
#    [Documentation]    Dissociate EVPN From Routers
#    Log    "STEP 1 : Dissociate EVPN From NET1 NET2 AND RTR1"
#    ${Req_no_of_net} =    Evaluate    2
#    Dissociate L3VPN    ${Req_no_of_net}
#    ${Req_no_of_routers} =    Evaluate    1
#    Dissociate L3VPN From Routers    ${Req_no_of_routers}
#
#Verify BGP Neighbor Status On Quagga NEG
#    [Arguments]    ${dcgw_ip}    ${neighbor_ip}
#    [Documentation]    Verify bgp neighbor status on quagga
#    ${output} =    Execute Show Command On quagga    ${dcgw_ip}    show bgp neighbors ${neighbor_ip}
#    Log    ${output}
#    Should Not Contain    ${output}    BGP state = Established
#
#Associate L3VPN To Networks
#    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Associates L3VPN to networks and verify
#    ${devstack_conn_id} =    Get ControlNode Connection
#    : FOR    ${NET}    IN    @{NETWORKS_ASSOCIATION_TESTAREA4_EVPN1}
#    \    ${network_id} =    Get Net Id    ${NET}    ${devstack_conn_id}
#    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Contain    ${resp}    ${network_id}
#    : FOR    ${NET}    IN    @{NETWORKS_ASSOCIATION_TESTAREA4_EVPN2}
#    \    ${network_id} =    Get Net Id    ${NET}    ${devstack_conn_id}
#    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[1]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
#    \    Should Contain    ${resp}    ${network_id}
#
#Associate L3VPN To Routers
#    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Associating router to L3VPN
#    ${devstack_conn_id}=    Get ControlNode Connection
#    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTER}
#    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index}]}    ${devstack_conn_id}
#    \    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Contain    ${resp}    ${router_id}
#    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTER}
#    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index+1}]}    ${devstack_conn_id}
#    \    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[1]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
#    \    Should Contain    ${resp}    ${router_id}
#
#Dissociate L3VPN
#    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Dissociate L3VPN from networks
#    ${devstack_conn_id} =    Get ControlNode Connection
#    Log Many    "Number of network"    ${NUM_OF_NET}
#    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
#    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETS}
#    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
#    \    Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Not Contain    ${resp}    ${network_id}
#
#Dissociate L3VPN From Routers
#    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Dissociating router from L3VPN
#    ${devstack_conn_id}=    Get ControlNode Connection
#    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTER}
#    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index}]}    ${devstack_conn_id}
#    \    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Not Contain    ${resp}    ${router_id}
#
#Verify Ping
#    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
#    [Documentation]    Verify Ping among VMs
#    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}
#    ...    ping -c 3 ${VM_IP2}
#    Should Contain    ${output}    ${REQ_PING_REGEXP}
#
#Verify VM Is ACTIVE
#    [Arguments]    ${vm_name}
#    [Documentation]    Run these commands to check whether the created vm instance is active or not.
#    ${devstack_conn_id}=    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${output}=    Write Commands Until Prompt    nova show ${vm_name} | grep OS-EXT-STS:vm_state    30s
#    Log    ${output}
#    Should Contain    ${output}    active
#
#Reboot VM
#    [Arguments]    @{vm_list}
#    [Documentation]    Reboot vm and verify the VM is active or not.
#    ${devstack_conn_id}=    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    : FOR    ${Vm}    IN    @{vm_list}
#    \    ${command}    Set Variable    nova reboot    ${Vm}
#    \    ${output}=    Write Commands Until Prompt    ${command}    30s
#    \    sleep    60
#    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
#    Log    ${output}
#    [Return]    ${output}
#
#Create Nova VMs
#    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Create Vm instances on compute nodes
#    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
#    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST_TEST_TOPOLOGY_4[${index}]}    ${VM_INSTANCES_DPN1_TEST_TOPOLOGY_4[${index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
#    ${start} =    Evaluate    ${index}+1
#    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
#    : FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
#    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST_TEST_TOPOLOGY_4[${index}]}    ${VM_INSTANCES_TEST_TOPOLOGY_4[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
#    : FOR    ${VM}    IN    @{VM_INSTANCES_TEST_TOPOLOGY_4}
#    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
#
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
#
#Get Fib Entries
#    [Arguments]    ${session}
#    [Documentation]    Get Fib table entries from ODL session
#    ${resp}    RequestsLibrary.Get Request    ${session}    ${FIB_ENTRIES_URL}
#    Log    ${resp.content}
#    [Return]    ${resp.content}
#
#Verify VMs received IP
#    [Documentation]    Verify VM received IP
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{VM_INSTANCES_NET1_TEST_TOPOLOGY_4}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{VM_INSTANCES_NET2_TEST_TOPOLOGY_4}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{VM_INSTANCES_NET3_TEST_TOPOLOGY_4}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{VM_INSTANCES_NET4_TEST_TOPOLOGY_4}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{VM_INSTANCES_NET5_TEST_TOPOLOGY_4}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{VM_INSTANCES_NET6_TEST_TOPOLOGY_4}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{VM_INSTANCES_NET7_TEST_TOPOLOGY_4}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{VM_INSTANCES_NET8_TEST_TOPOLOGY_4}
#    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET1_TEST_TOPOLOGY_4}
#    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET2_TEST_TOPOLOGY_4}
#    ${VM_IP_NET3}    ${DHCP_IP3}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET3_TEST_TOPOLOGY_4}
#    ${VM_IP_NET4}    ${DHCP_IP4}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET4_TEST_TOPOLOGY_4}
#    ${VM_IP_NET5}    ${DHCP_IP5}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET5_TEST_TOPOLOGY_4}
#    ${VM_IP_NET6}    ${DHCP_IP6}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET6_TEST_TOPOLOGY_4}
#    ${VM_IP_NET7}    ${DHCP_IP7}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET7_TEST_TOPOLOGY_4}
#    ${VM_IP_NET8}    ${DHCP_IP8}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET8_TEST_TOPOLOGY_4}
#    Log    ${VM_IP_NET1}
#    Log    ${VM_IP_NET2}
#    Log    ${VM_IP_NET3}
#    Log    ${VM_IP_NET4}
#    Log    ${VM_IP_NET5}
#    Log    ${VM_IP_NET6}
#    Log    ${VM_IP_NET7}
#    Log    ${VM_IP_NET8}
#    Should Not Contain    ${VM_IP_NET2}    None
#    Should Not Contain    ${VM_IP_NET1}    None
#    Should Not Contain    ${VM_IP_NET3}    None
#    Should Not Contain    ${VM_IP_NET4}    None
#    Should Not Contain    ${VM_IP_NET5}    None
#    Should Not Contain    ${VM_IP_NET6}    None
#    Should Not Contain    ${VM_IP_NET7}    None
#    Should Not Contain    ${VM_IP_NET8}    None
#    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    ${VM_IP_NET5}    ${VM_IP_NET6}
#    ...    ${VM_IP_NET7}    ${VM_IP_NET8}
#
#Delete L3VPN
#    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Delete L3VPN
#    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
#    \    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
#
#Create L3VPN
#    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Creates L3VPN and verify the same
#    ${devstack_conn_id} =    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]    ${devstack_conn_id}
#    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
#    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
#    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}
#    \    ...    l3vni=${CREATE_L3VNI[${index}]}    tenantid=${tenant_id}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
#    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
#    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
#    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*
#
#Get Gateway MAC And IP Address
#    [Arguments]    ${router_Name}
#    [Documentation]    Get Gateway mac and IP Address
#    ${devstack_conn_id}=    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${output} =    Write Commands Until Prompt    neutron router-port-list ${router_Name}    30s
#    @{MacAddr-list} =    Get Regexp Matches    ${output}    ${MAC_REGEX}
#    @{IpAddr-list} =    Get Regexp Matches    ${output}    ${IP_REGEX}
#    [Return]    ${MacAddr-list}    ${IpAddr-list}
#
#Add Interfaces To Routers
#    [Documentation]    Add Interfaces
#    ${devstack_conn_id} =    Get ControlNode Connection
#    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA4}
#    \    Add Router Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
#    : FOR    ${INTERFACE}    IN    @{ROUTER2_INTERFACE_TESTAREA4}
#    \    Add Router Interface    ${REQ_ROUTERS[1]}    ${INTERFACE}
#    ${interface_output} =    Show Router Interface    ${REQ_ROUTERS[0]}
#    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA4}
#    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
#    \    Should Contain    ${interface_output}    ${subnet_id}
#    ${interface_output} =    Show Router Interface    ${REQ_ROUTERS[1]}
#    : FOR    ${INTERFACE}    IN    @{ROUTER2_INTERFACE_TESTAREA4}
#    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
#    \    Should Contain    ${interface_output}    ${subnet_id}
#    ${GWMAC_ADDRS_ROUTER1_TESTAREA4}    ${GWIP_ADDRS_ROUTER1_TESTAREA4} =    Get Gateway MAC And IP Address    ${REQ_ROUTERS[0]}
#    Log    ${GWMAC_ADDRS_ROUTER1_TESTAREA4}
#    Set Suite Variable    ${GWMAC_ADDRS_ROUTER1_TESTAREA4}
#    Log    ${GWIP_ADDRS_ROUTER1_TESTAREA4}
#    Set Suite Variable    ${GWIP_ADDRS_ROUTER1_TESTAREA4}
#
#Delete And Recreate VM And Port
#    [Arguments]    ${VM_NAME}    ${PORT_NAME}
#    [Documentation]    Delete VM and recreate the port and VM
#    Delete Port    ${PORT_NAME}
#    Delete Vm Instance    ${VM_NAME}
#    Create Port    @{REQ_NETWORKS}[0]    ${PORT_NAME}    sg=${SECURITY_GROUP}
#    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_PORT_URL}    ${REQ_PORT_LIST}
#    Create Vm Instance With Port On Compute Node    ${PORT_NAME}    ${VM_NAME}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
#    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_NAME}
#
#Delete BGP Config On ODL
#    [Documentation]    Delete BGP Configuration on ODL
#    Delete BGP Configuration On ODL    session
#    ${output} =    Get BGP Configuration On ODL    session
#    Log    ${output}
#    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
#    Log    ${output}
#    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
#    Log    ${output}
#
#Create BGP Config On ODL
#    [Documentation]    Create BGP Config on ODL
#    Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
#    AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
#    ${output} =    Get BGP Configuration On ODL    session
#    Log    ${output}
#    Should Contain    ${output}    ${DCGW_SYSTEM_IP}
#
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
#
#Verify Tunnel Status as UP
#    [Documentation]    Verify that the tunnels are UP
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
#    Log    ${output}
#    Should Contain    ${output}    ${STATE_UP}
#    Should Not Contain    ${output}    ${STATE_DOWN}
#
#Verify Flows Are Present
#    [Arguments]    ${ip}
#    [Documentation]    Verify Flows Are Present
#    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
#    Log    ${flow_output}
#    ${resp}=    Should Contain    ${flow_output}    table=50
#    Log    ${resp}
#    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
#    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
#    ${resp}=    Should Contain    ${flow_output}    table=51
#    Log    ${resp}
#
#Create Neutron Ports
#    [Arguments]    ${NUM_OF_PORTS}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Create required number of ports under previously created subnets
#    Log    ${PORT_LIST_TEST_TOPOLOGY_4}
#    ${REQUIRED_PORT_LIST}=    Get Slice From List    ${PORT_LIST_TEST_TOPOLOGY_4}    0    ${NUM_OF_PORTS}
#    Log    ${REQUIRED_PORT_LIST}
#    Log To Console    "REQUIRED PORT LIST IS"
#    Log To Console    ${REQUIRED_PORT_LIST}
#    : FOR    ${item}    IN RANGE    0    ${NUM_OF_PORTS}
#    \    ${port_name}    Get From List    ${PORT_LIST_TEST_TOPOLOGY_4}    ${item}
#    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
#    \    ${net}    Get From List    ${match}    0
#    \    ${net}    Convert To Integer    ${net}
#    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
#    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}
#    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_PORT_URL}    ${PORT_LIST_TEST_TOPOLOGY_4}
#
#Get Dpn Id
#    [Arguments]    ${ServerIp}
#    [Documentation]    Get DpnId from server and return
#    ${conn_handle}    SSHLibrary.Open Connection    ${ServerIp}
#    Set Client Configuration    prompt=#
#    SSHLibrary.Login    ${OS_USER}    ${LOGIN_PSWD}
#    ${CmdOut}    Write Commands Until Prompt    sudo ovs-ofctl show -O Openflow13 br-int | head -1 | awk -F "dpid:" '{ print $2 }'    30s
#    ${HexValue}    Should Match Regexp    ${CmdOut}    [0-9a-f]+
#    ${DpnId}    Convert To Integer    ${HexValue}    16
#    SSHLibrary.Close Connection
#    [Return]    ${DpnId}
#
#Change Br-ext Ip
#    [Arguments]    ${serverip}    ${ip}
#    [Documentation]    Get DpnId from server and return
#    ${conn_handle}    SSHLibrary.Open Connection    ${serverip}
#    Set Client Configuration    prompt=#
#    SSHLibrary.Login    ${OS_USER}    ${LOGIN_PSWD}
#    ${CmdOut}    Write Commands Until Prompt    sudo ifconfig br-ext ${ip} netmask 255.255.255.0    30s
#    SSHLibrary.Close Connection
#
#Bring Down Br-ext
#    [Arguments]    ${serverip}
#    [Documentation]    Bring down the br-ext interface
#    ${conn_handle}    SSHLibrary.Open Connection    ${serverip}
#    Set Client Configuration    prompt=#
#    SSHLibrary.Login    ${OS_USER}    ${LOGIN_PSWD}
#    ${CmdOut}    Write Commands Until Prompt    ifconfig br-ext down    30s
#    SSHLibrary.Close Connection
#
#Bring Up Br-ext
#    [Arguments]    ${serverip}
#    [Documentation]    Bring down the br-ext interface
#    ${conn_handle}    SSHLibrary.Open Connection    ${serverip}
#    Set Client Configuration    prompt=#
#    SSHLibrary.Login    ${OS_USER}    ${LOGIN_PSWD}
#    ${CmdOut}    Write Commands Until Prompt    ifconfig br-ext up    30s
#    SSHLibrary.Close Connection
#
#Verify ITM Status
#    [Arguments]    ${state}
#    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
#    Should Contain    ${output}    ${state}
#
#Get Output From Dcgw
#    [Arguments]    ${dcgw_ip}    ${cmd}
#    ${dcgw_conn_id} =    Open_Connection_To_Tools_System    ip_address=${dcgw_ip}
#    Switch Connection    ${dcgw_conn_id}
#    ${output}    Write Commands Until Expected Prompt    ${cmd}    $    30
#    Close Connection
#    [Return]    ${output}
#
