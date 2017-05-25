#*** Settings ***
#Documentation      Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster TESTAREA3
#Test Setup         Pretest Setup
#Test Teardown      Pretest Cleanup
#Library            RequestsLibrary
#Library            SSHLibrary
#Library            Collections
#Library            String
#Resource           ../../../csit/libraries/Utils.robot
#Resource           ../../../csit/libraries/OpenStackOperations.robot
#Resource           ../../../csit/libraries/DevstackUtils.robot
#Resource           ../../libraries/SetupUtils.robot
#Resource           ../../libraries/KarafKeywords.robot
#Resource           ../../libraries/VpnOperations.robot
#Resource           ../../../csit/libraries/Utils.robot
#Resource           ../../libraries/BgpOperations.robot
#Resource           ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
#Variables          ../../variables/Variables.py
#
#*** Variables ***
#
#${DCGW_SYSTEM_IP}     ${TOOLS_SYSTEM_1_IP}
#@{PORT_LIST_NEW}      PORT15
#${VM_NAME_NEW}        VM15
#${MAC_REGEX}      (([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))
#${IP_REGEX}       (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])
#
#*** Test Cases ***
#
#CREATE TEST TOPOLOGY FOR TEST AREA 3
#    [Documentation]    CREATE TEST TOPOLOGY FOR TEST AREA 3
#    [Tags]    Nightly
#    [Setup]    Log    NO PRETEST SETUP
#    Log    Dissociate EVPN From Routers
#    Log    PLEASE DISSOCIATE FROM BOTH THE ROUTERS 
#    Log    CURRENTLY ONLY ONE ROUTER IS GETTING ASSOCIATED WITH ONE EVPN
#    ${Req_no_of_routers} =    Evaluate    1
#    Dissociate L3VPN From Routers    ${Req_no_of_routers}
#    Log    Delete Interface From Router RTR1 and RTR2
#    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE}
#    \    Remove Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
#    : FOR    ${INTERFACE}    IN    @{ROUTER2_INTERFACE}
#    \    Remove Interface    ${REQ_ROUTERS[1]}    ${INTERFACE}
#    Log    ADD INTERFACE NET3 NET4 TO RTR1
#    Add Interfaces To Routers
#    Log    DELETE BGP CONFIG ON ODL
#    Delete BGP Config On ODL
#    Log    DELETE L3VPN
#    ${Req_no_of_L3VPN} =    Evaluate    1
#    Delete L3VPN    ${Req_no_of_L3VPN}
#    Log    DELETE AND RECREATE PORT11 AND VNF11
#    Delete And Recreate VM And Port    @{VM_INSTANCES}[0]    @{REQ_PORT_LIST}[0]
#    Log    CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID
#    ${Req_no_of_L3VPN} =    Evaluate    1
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
#    :FOR    ${VM}    IN    @{VM_INSTANCES}
#    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
#    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    Wait Until Keyword Succeeds    300s    10s    Verify VMs received IP
#    Set Global Variable    ${VM_IP_NET2}
#    Set Global Variable    ${VM_IP_NET1}
#    Set Global Variable    ${VM_IP_NET3}
#    Set Global Variable    ${VM_IP_NET4}
#    Log    ASSOCIATE NET1 NET2 AND RTR1 TO EVPN FROM CSC
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}
#    ${Req_no_of_routers} =    Evaluate    1
#    Associate L3VPN To Routers    ${Req_no_of_routers}
#    [Teardown]    Log    NO PRETEST Teardown
#
##TC51 7.3.1 Verify network connectivity between VNF_Network to VNF_Router for intra_openvswitch
##    [Documentation]    Testcase Id 7.3.1
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.1 Verify network connectivity between VNF_Network to VNF_Router for intra_openvswitch ${\n}"
##    Log    "STEP 2 : PING VNF11 <-> VNF31 VNF12<-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
##    #Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET2[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}    @{REQ_SUBNET_CIDR_TESTAREA3}
##    \    Should Contain    ${output}    ${IP}
##    ${iproute}    Get Output From Dcgw    ${DCGW_SYSTEM_IP}    show ip route
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}    @{REQ_SUBNET_CIDR_TESTAREA3}
##    \    Should Contain    ${iproute}    ${IP}
##
##TC52 7.3.2 Verify network connectivity between VNF_Network to VNF_Router for inter_openvswitch
##    [Documentation]    Testcase Id 7.3.2
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.2 Verify network connectivity between VNF_Network to VNF_Router for inter_openvswitch ${\n}"
##    Log    "STEP 2 : PING VNF13 <-> VNF31 VNF14<-> VNF32 VNF23<-> VNF41 AND VNF23<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[1]}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##
##TC53_54_55 7.3.3 7.3.4 7.3.5 Verify the disassociation and re association of networks router from L3VPNoVxLAN 
##    [Documentation]    Testcase Id 7.3.3
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.3 Verify the disassociation of networks from L3VPNoVxLAN ${\n} 7.3.4 Verify the disassociation of router from L3VPNoVxLAN ${\n} 7.3.5 Verify the re association of networks, router to L3VPNoVxLAN ${\n}"
##    Log    "STEP 2 : PING VNF13 <-> VNF31 VNF14<-> VNF32 VNF23<-> VNF41 AND VNF23<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[1]}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 3 : Dissociate L3VPN From Networks"
##    ${Req_no_of_net} =    Evaluate    2
##    Dissociate L3VPN    ${Req_no_of_net}
##    ${output}=    Get Fib Entries    session
##    Log    "STEP 4 : Dissociate EVPN From ROUTERS"
##    ${Req_no_of_routers} =    Evaluate    1
##    Dissociate L3VPN From Routers    ${Req_no_of_routers}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Not Contain    ${output}    ${IP}
##    Log    "STEP 5 : ASSOCIATE NET1 NET2 AND RTR1 TO EVPN FROM CSC"
##    ${Req_no_of_net} =    Evaluate    2
##    Associate L3VPN To Networks    ${Req_no_of_net}
##    ${Req_no_of_routers} =    Evaluate    1
##    Associate L3VPN To Routers    ${Req_no_of_routers}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 6 : PING VNF13 <-> VNF31 VNF14<-> VNF32 VNF23<-> VNF41 AND VNF23<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[1]}
##
##TC56 7.3.6 Verify deletion L3VPNoVxLAN which has routers associated
##    [Documentation]    Testcase Id 7.3.6
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.6 Verify deletion L3VPNoVxLAN which has routers associated ${\n}"
##    Log    "STEP 2 : PING VNF13 <-> VNF31 VNF14<-> VNF32 VNF23<-> VNF41 AND VNF23<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[1]}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 3 : DELETE L3VPN"
##    ${Req_no_of_L3VPN} =    Evaluate    1
##    Delete L3VPN    ${Req_no_of_L3VPN}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Not Contain    ${output}    ${IP}
##    Log    "STEP 4 : RECREATE EVPN FROM THE REST API WITH PROPER L3VNI ID"
##    ${Req_no_of_L3VPN} =    Evaluate    1
##    Create L3VPN    ${Req_no_of_L3VPN}
##    Log    "STEP 5 : ASSOCIATE NET1 NET2 AND RTR1 TO EVPN FROM CSC"
##    ${Req_no_of_net} =    Evaluate    2
##    Associate L3VPN To Networks    ${Req_no_of_net}
##    ${Req_no_of_routers} =    Evaluate    1
##    Associate L3VPN To Routers    ${Req_no_of_routers}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 6 : PING VNF13 <-> VNF31 VNF14<-> VNF32 VNF23<-> VNF41 AND VNF23<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[1]}
##
##TC57 7.3.7 Verify deletion of L3VPNoVxLAN without any associations
##    [Documentation]    Testcase Id 7.3.7
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.7 Verify deletion of L3VPNoVxLAN without any associations ${\n}"
##    Log    "STEP 2 : PING VNF13 <-> VNF31 VNF14<-> VNF32 VNF23<-> VNF41 AND VNF23<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[1]}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 3 : Dissociate EVPN From NET1 NET2 AND RTR1"
##    ${Req_no_of_net} =    Evaluate    2
##    Dissociate L3VPN    ${Req_no_of_net}
##    ${Req_no_of_routers} =    Evaluate    1
##    Dissociate L3VPN From Routers    ${Req_no_of_routers}
##    Log    "STEP 4 : DELETE L3VPN"
##    ${Req_no_of_L3VPN} =    Evaluate    1
##    Delete L3VPN    ${Req_no_of_L3VPN}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Not Contain    ${output}    ${IP}
##    Log    "STEP 5 : RECREATE EVPN FROM THE REST API WITH PROPER L3VNI ID"
##    ${Req_no_of_L3VPN} =    Evaluate    1
##    Create L3VPN    ${Req_no_of_L3VPN}
##    Log    "STEP 6 : ASSOCIATE NET1 NET2 AND RTR1 TO EVPN FROM CSC"
##    ${Req_no_of_net} =    Evaluate    2
##    Associate L3VPN To Networks    ${Req_no_of_net}
##    ${Req_no_of_routers} =    Evaluate    1
##    Associate L3VPN To Routers    ${Req_no_of_routers}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 7 : PING VNF13 <-> VNF31 VNF14<-> VNF32 VNF23<-> VNF41 AND VNF23<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    ${VM_IP_NET4[1]}
##
##TC58_TC59 7.3.8 7.3.9 Verify manual TEP deletion and recreation scenario for L3VPNoVxLAN VNFs
##    [Documentation]    Testcase Id 7.3.8
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.8 Verify manual TEP deletion scenario for L3VPNoVxLAN VNFs ${\n} 7.3.9 Verify manual TEP recreation scenario for L3VPNoVxLAN VNFs ${\n}"
##    Log    "STEP 2 : PING VNF11 <-> VNF31 VNF12<-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
##    Log    "STEP 3 : DELETE THE TEP OF openVSwitch1 USING ODL KARAF CMD"
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Log    ${output}
##    ${split_output}=    Split String    ${output}
##    ${index} =      Get Index From List    ${split_output}    ${OS_COMPUTE_1_IP}
##    ${cmd} =    Catenate    tep:delete ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
##    ${output}=    Issue Command On Karaf Console    ${cmd}
##    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Log    ${output}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Not Contain    ${output}    ${IP}
##    Log    "STEP 4 : READD THE TEP OF openVSwitch1 USING ODL KARAF CMD"
##    ${cmd} =    Catenate    tep:add ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
##    ${output}=    Issue Command On Karaf Console    ${cmd}
##    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Log    ${output}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##
##TC60 7.3.10     Verify manual TEP recreation with modified TEP IPs for L3VPNoVxLAN VNFs
##    [Documentation]    Testcase Id 7.3.10
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.10 Verify manual TEP recreation with modified TEP IPs for L3VPNoVxLAN VNFs ${\n}"
##    Log    "STEP 2 : PING VNF11 <-> VNF31 VNF12<-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
##    Log    "STEP 3 : DELETE THE TEP OF openVSwitch1 USING ODL KARAF CMD"
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Log    ${output}
##    ${split_output}=    Split String    ${output}
##    ${index} =      Get Index From List    ${split_output}    ${OS_COMPUTE_1_IP}
##    ${cmd} =    Catenate    tep:delete ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
##    ${output}=    Issue Command On Karaf Console    ${cmd}
##    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Log    ${output}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Not Contain    ${output}    ${IP}
##    Log    "STEP 4 : READD THE TEP OF openVSwitch1 USING ODL KARAF CMD"
##    ${cmd} =    Catenate    tep:add ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
##    ${output}=    Issue Command On Karaf Console    ${cmd}
##    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Log    ${output}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 5 :Read the modified  TEP back with different tep ip"
##    ${dpn_id1}    Get Dpn Id    ${OS_COMPUTE_1_IP}
##    ${dpn_id2}    Get Dpn Id    ${OS_COMPUTE_2_IP}
##    Change Br-ext Ip    ${OS_COMPUTE_1_IP}    ${TEMP_BR_EXT_IP_DPN1}
##    Change Br-ext Ip    ${OS_COMPUTE_2_IP}    ${TEMP_BR_EXT_IP_DPN2}
##    ${cmd} =    Catenate    tep:add ${dpn_id1} dpdk0 0 ${TEMP_BR_EXT_IP_DPN1} ${TEMP_BR_EXT_SUBNET_DPN1}  null TZA
##    ${output}=    Issue Command On Karaf Console    ${cmd}
##    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Should Contain    ${output}    ${TEMP_BR_EXT_IP_DPN1}
##    ${cmd} =    Catenate    tep:add ${dpn_id2} dpdk0 0 ${TEMP_BR_EXT_IP_DPN2} ${TEMP_BR_EXT_SUBNET_DPN2}  null TZA
##    ${output}=    Issue Command On Karaf Console    ${cmd}
##    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Should Contain    ${output}    ${TEMP_BR_EXT_IP_DPN2}
##    Log    ${output}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 6 : PING VNF11 <-> VNF31 VNF12<-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
##    Log    "STEP 7 : Restart OVSDB"
##    Restart OVSDB    ${OS_COMPUTE_1_IP}
##    Restart OVSDB    ${OS_COMPUTE_2_IP}
##
##TC15 7.3.11     Verify TEP UP/DOWN events for L3VPNoVxLAN VNFs
##    [Documentation]    Testcase Id 7.3.11
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.11      Verify TEP UP/DOWN events for L3VPNoVxLAN VNFs ${\n}"
##    Log    "STEP 2 : PING VNF11 <-> VNF31 VNF12<-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
##    Log    "STEP 3 : READD THE TEP OF openVSwitch1 USING ODL KARAF CMD"
##    ${cmd} =    Catenate    tep:add ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
##    ${output}=    Issue Command On Karaf Console    ${cmd}
##    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW}
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Log    ${output}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 4 :Read the modified  TEP back with different tep ip"
##    ${dpn_id1}    Get Dpn Id    ${OS_COMPUTE_1_IP}
##    Bring Down Br-ext    ${OS_COMPUTE_1_IP}
##    Wait Until Keyword Succeeds    180s    10s    Verify ITM Status    DOWN
##    Bring Up Br-ext    ${OS_COMPUTE_1_IP}
##    Wait Until Keyword Succeeds    180s    10s    Verify ITM Status    UP
##    ${output}=    Issue Command On Karaf Console    ${REQ_TEP_SHOW_STATE}
##    Log    ${output}
##    ${output}=    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 5 : PING VNF11 <-> VNF31 VNF12<-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
##
##TC62 7.3.12 Verify nova migration for L3VPNoVxLAN VNFs
##    [Documentation]    Testcase Id 7.3.12
##    [Tags]    Nightly
##    ${exp_result}    ConvertToInteger    1
##    Log    "Testcases covered as per Testplan ${\n} 7.3.12 Verify nova migration for L3VPNoVxLAN VNFs ${\n}"
##    Log    "STEP 2 : PING VNF11 <-> VNF31 VNF12<-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
##    ${output} =    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 3 : MIGRATE VNF11 FROM CSS1 TO CSS2"
##    Nova Migrate    ${VM_INSTANCES[0]}
##    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_INSTANCES[0]}
##    ${output} =    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 4 : VERIFY PING AFTER MIGRATING VNF11 FROM CSS1 TO CSS2"
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
##    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
##    ${output} =    Get Fib Entries    session
##    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
##    \    Should Contain    ${output}    ${IP}
##    Log    "STEP 5 : MIGRATE VNF11 FROM CSS2 TO CSS1"
##    Nova Migrate    ${VM_INSTANCES[0]}
##    Verify VM Is ACTIVE    ${VM_INSTANCES[0]}
##    [Teardown]    Run Keywords    Get Test Teardown Debugs
##    ...    AND    Delete Setup
#
#*** Keywords ***
#
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
#Associate L3VPN To Networks
#    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Associates L3VPN to networks and verify
#    ${devstack_conn_id} =    Get ControlNode Connection
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NET}
#    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
#    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Contain    ${resp}    ${network_id}
#
#Associate L3VPN To Routers
#    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Associating router to L3VPN
#    ${devstack_conn_id}=    Get ControlNode Connection
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_ROUTER}
#    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index}]}    ${devstack_conn_id}
#    \    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Contain    ${resp}    ${router_id}
#
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
#
#Dissociate L3VPN From Routers
#    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Dissociating router from L3VPN
#    ${devstack_conn_id}=    Get ControlNode Connection
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_ROUTER}
#    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index}]}    ${devstack_conn_id}
#    \    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
#    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
#    \    Should Not Contain    ${resp}    ${router_id}
#
#Verify Ping
#    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
#    [Documentation]    Verify Ping among VMs
#    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}    ping -c 3 ${VM_IP2}
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
#    \    ${command}    Set Variable    nova reboot  ${Vm}
#    \    ${output}=    Write Commands Until Prompt    ${command}    30s
#    \    sleep    60
#    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
#    Log    ${output}
#    [Return]    ${output}
#
#Nova Evacuate
#    [Documentation]    Evacuate all VMs from one CSS to another
#    ${devstack_conn_id}=    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${output}=    Write Commands Until Prompt    nova list    30s
#    ${output}=    Write Commands Until Prompt    nova host-evacuate ${devstack_conn_id}    30s
#    Log    ${output}
#    ${output}=    Write Commands Until Prompt    nova list    30s
#
#Create Nova VMs
#    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Create Vm instances on compute nodes
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_VMS_PER_DPN}
#    \    Create Vm Instance With Port On Compute Node    ${REQ_PORT_LIST[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
#    ${start} =     Evaluate    ${index}+1
#    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
#    :FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
#    \    Create Vm Instance With Port On Compute Node    ${REQ_PORT_LIST[${index}]}    ${VM_INSTANCES[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
#    :FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
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
#    ...    true    @{REQ_VM_INSTANCES_NET1}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{REQ_VM_INSTANCES_NET2}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{REQ_VM_INSTANCES_NET3}
#    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    5s    Collect VM IP Addresses
#    ...    true    @{REQ_VM_INSTANCES_NET4}
#    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET1}
#    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET2}
#    ${VM_IP_NET3}    ${DHCP_IP3}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET3}
#    ${VM_IP_NET4}    ${DHCP_IP4}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET4}
#    Log    ${VM_IP_NET1}
#    Log    ${VM_IP_NET2}
#    Log    ${VM_IP_NET3}
#    Log    ${VM_IP_NET4}
#    Should Not Contain    ${VM_IP_NET2}    None
#    Should Not Contain    ${VM_IP_NET1}    None
#    Should Not Contain    ${VM_IP_NET3}    None
#    Should Not Contain    ${VM_IP_NET4}    None
#    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}
#
#Delete L3VPN
#    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
#    [Documentation]    Delete L3VPN
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
#    \    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
#
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
#    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA3}
#    \    Add Router Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
#    ${interface_output} =    Show Router Interface    ${REQ_ROUTERS[0]}
#    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE_TESTAREA3}
#    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
#    \    Should Contain    ${interface_output}    ${subnet_id}
#    ${GWMAC_ADDRS_ROUTER1_TESTAREA3}    ${GWIP_ADDRS_ROUTER1_TESTAREA3} =    Get Gateway MAC And IP Address    ${REQ_ROUTERS[0]}
#    Log    ${GWMAC_ADDRS_ROUTER1_TESTAREA3}
#    Set Suite Variable    ${GWMAC_ADDRS_ROUTER1_TESTAREA3}
#    Log    ${GWIP_ADDRS_ROUTER1_TESTAREA3}
#    Set Suite Variable    ${GWIP_ADDRS_ROUTER1_TESTAREA3}
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
