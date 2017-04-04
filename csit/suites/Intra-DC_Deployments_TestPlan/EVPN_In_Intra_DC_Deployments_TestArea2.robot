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
Variables          ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.py
Resource           ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
Resource           ../../../csit/libraries/Utils.robot
Resource           ../../libraries/BgpOperations.robot
Variables          ../../variables/Variables.py

*** Variables ***

${DCGW_SYSTEM_IP}     ${TOOLS_SYSTEM_1_IP}
@{PORT_LIST_NEW}      PORT15
${VM_NAME_NEW}        VM15
${MAC_REGEX}      (([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))
${IP_REGEX}       (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])

*** Test Cases ***

CREATE TEST TOPOLOGY FOR TEST AREA 2
    [Documentation]    CREATE TEST TOPOLOGY FOR TEST AREA 2
    [Tags]    Nightly
    [Setup]    Log    NO PRETEST SETUP
    Log    Dissociate L3VPN From Networks
    ${Req_no_of_net} =    Evaluate    2
    Dissociate L3VPN    ${Req_no_of_net}
    Log    ADD INTERFACE NET1 NET2 TO RTR1 AND INTERFACE NET3 NET4 RTR2
    Add Interfaces To Routers
    Log    DELETE BGP CONFIG ON ODL
    Delete BGP Config On ODL
    Log    DELETE L3VPN
    ${Req_no_of_L3VPN} =    Evaluate    1
    Delete L3VPN    ${Req_no_of_L3VPN}
    Log    DELETE AND RECREATE PORT11 AND VNF11
    Delete Port    @{PORT_LIST}[0]
    Delete And Recreate VM And Port    @{VM_INSTANCES}[0]    @{PORT_LIST}[0]
    Log    CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID
    ${Req_no_of_L3VPN} =    Evaluate    1
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
    :FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET1}
    Set Global Variable    ${VM_IP_NET3}
    Set Global Variable    ${VM_IP_NET4}
    Log    ASSOCIATE RTR1 AND RTR2 TO EVPN FROM CSC
    ${Req_no_of_routers} =    Evaluate    2
    Associate L3VPN To Routers    ${Req_no_of_routers}
    [Teardown]    Log    NO PRETEST Teardown

TC26 7.2.1 Verification of intra_router_intra_openvswitch network connectivity
    [Documentation]    Testcase Id 7.2.1
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.1 Verification of intra_router_intra_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF12 VNF21 <-> VNF22 VNF31 <-> VNF32 AND VNF41 <-> VNF42"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[3]    ${VM_IP_NET4[0]}    ${VM_IP_NET4[1]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}


TC27 7.2.2 Verification of intra_router_inter_openvswitch network connectivity
    [Documentation]    Testcase Id 7.2.2
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.2 Verification of intra_router_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF13 VNF21 <-> VNF23 VNF31 <-> VNF33 AND VNF41 <-> VNF43"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[3]    ${VM_IP_NET4[0]}    ${VM_IP_NET4[2]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC28 7.2.3 Verification of inter_router_intra_openvswitch network connectivity
    [Documentation]    Testcase Id 7.2.3
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.3 Verification of inter_router_intra_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF31 VNF12 <-> VNF32 VNF21<-> VNF41 AND VNF22<-> VNF42"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET4[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[1]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC29 7.2.4 Verification of inter_router_inter_openvswitch network connectivity
    [Documentation]    Testcase Id 7.2.4
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.4 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC32 7.2.7 Verification of VNF reboot across L3VPNoVxLAN
    [Documentation]    Testcase Id 7.2.7
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.7 Verification of VNF reboot across L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Log    "STEP 3 : REBOOT 16 VNFs AND VERIFY PING ACROSS THEM"
    Reboot VM    @{VM_INSTANCES}
    Log    "STEP 4 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC33_TC34 7.2.8 7.2.9 Verification of VNF deletion (nova delete) and recreation (nova boot) across L3VPNoVxLAN
    [Documentation]    Testcase Id 7.2.8 7.2.9
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.8 7.2.9 Verification of VNF deletion (nova delete) and recreation (nova boot) across L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Log    "STEP 3 : NOVA DELETE THE VNFs ONE BY ONE"
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_NET2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    ${VM_IP_LIST} =    Create List    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Remove RSA Key From KnowHosts     ${VM_IP}
    Log    "STEP 4 : NOVA CREATE THE VNFs ONE BY ONE"
    ${Req_no_of_vms_per_dpn} =    Evaluate    8
    Create Nova VMs     ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET1}
    Set Global Variable    ${VM_IP_NET3}
    Set Global Variable    ${VM_IP_NET4}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC36 7.2.11 Verification of new VNF bring up across already existed L3VPNoVxLAN
    [Documentation]    Testcase Id 7.2.11
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.11 Verification of new VNF bring up across already existed L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Log    "STEP 3 : 7 CREATE VNF15 ON OPENVSWITCH1 AND CHECK PING FROM ALL OTHER VNFs AND ASR"
    Create Port    @{NETWORKS}[0]    @{PORT_LIST_NEW}[0]    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST_NEW}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST_NEW}[0]    ${VM_NAME_NEW}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_NAME_NEW}
    ${VM_IP_NET1_New}    ${VM_IP_NET2_New}    ${VM_IP_NET3_New}    ${VM_IP_NET4_New}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1_New}    @{VM_IP_NET2_New}    @{VM_IP_NET3_New}    @{VM_IP_NET4_New}
    \    Should Contain    ${output}    ${IP}
    Log    "STEP 4 : DELETE VNF15 CREATED"
    Delete Vm Instance    ${VM_NAME_NEW}
    Delete Port    @{PORT_LIST_NEW}[0]

TC37_TC38 7.2.12 7.2.13 Verify manual TEP deletion\recreation scenario for L3VPNoVxLAN VNFs
    [Documentation]    Testcase Id 7.2.12 7.2.13
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.12 Verify manual TEP deletion scenario for L3VPNoVxLAN VNFs ${\n} 7.2.13 Verify manual TEP recreation scenario for L3VPNoVxLAN VNFs ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Log    "STEP 3 : DELETE THE TEP OF openVSwitch1 USING ODL KARAF CMD"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    ${split_output}=    Split String    ${output}
    ${index} =      Get Index From List    ${split_output}    ${OS_COMPUTE_1_IP}
    ${cmd} =    Catenate    tep:delete ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
    ${output}=    Issue Command On Karaf Console    ${cmd}
    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Not Contain    ${output}    ${IP}
    Log    "STEP 4 : READD THE TEP OF openVSwitch1 USING ODL KARAF CMD"
    ${cmd} =    Catenate    tep:add ${split_output[${index-1}]} ${split_output[${index+1}]} ${split_output[${index-2}]} ${split_output[${index}]} ${split_output[${index-4}]} ${split_output[${index-3}]} ${split_output[${index-6}]}
    ${output}=    Issue Command On Karaf Console    ${cmd}
    ${output}=    Issue Command On Karaf Console    ${TEP_COMMIT}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC41_TC42 7.2.16 7.2.17 Verify disassociation and re association of networks from L3VPNoVxLAN
    [Documentation]    Testcase Id 7.2.6
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.6 Verify disassociation of networks from L3VPNoVxLAN ${\n} 7.2.17 Verify re association of networks from L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}
    Log    "STEP 3 : Dissociate EVPN From ROUTERS"
    ${Req_no_of_routers} =    Evaluate    2
    Dissociate L3VPN From Routers    ${Req_no_of_routers}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Not Contain    ${output}    ${IP}
    Log    "STEP 4 : ASSOCIATE RTR1 AND RTR2 TO EVPN FROM CSC"
    ${Req_no_of_routers} =    Evaluate    2
    Associate L3VPN To Routers    ${Req_no_of_routers}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC43_TC44 7.2.18 7.2.19 Verify deletion recreation and re associate L3VPNoVxLAN which has networks associated
    [Documentation]    Testcase Id 7.2.18 7.2.19
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.18 Verify deletion L3VPNoVxLAN which has networks associated ${\n} 7.2.19 Verify recreation of L3VPNoVxLAN and re associate the networks ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}
    Log    "STEP 3 : DELETE L3VPN"
    ${Req_no_of_L3VPN} =    Evaluate    1
    Delete L3VPN    ${Req_no_of_L3VPN}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Not Contain    ${output}    ${IP}
    Log    "STEP 4 : CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID"
    ${Req_no_of_L3VPN} =    Evaluate    1
    Create L3VPN    ${Req_no_of_L3VPN}
    Log    "STEP 5 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STEP 6 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC45 7.2.20 Verify ASR route updates for L3VPNoVxLAN
    [Documentation]    Testcase Id 7.2.20
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.20 Verify ASR route updates for L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Log    "STEP 2 : ADD ROUTE TO ASR"
    Add Address Family On DCGW    ${DCGW_SYSTEM_IP}    ${LOOPBACK_IP1}    ${AS_ID}    ${DCGW_RD}
    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo1    ${LOOPBACK_IP1}
    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    Log    ${output}
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    Log    ${output1}
    Should Contain    ${output1}    ${LOOPBACK_IP1}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}
    Should Contain    ${output}    ${LOOPBACK_IP1}
    Log    "STEP 3 : ACCESS THE ADDED ROUTE ON ASR FROM VNF"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${LOOPBACK_IP}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${LOOPBACK_IP1}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${LOOPBACK_IP1}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${LOOPBACK_IP1}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ${LOOPBACK_IP1}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[3]    ${VM_IP_NET4[0]}    ${LOOPBACK_IP1}
    Log    "STEP 4 : DELETE ROUTE TO ASR"
    Delete Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo1    ${LOOPBACK_IP1}
    sleep    60
    ${output}=    Get Fib Entries    session
    Should Not Contain    ${output}    ${LOOPBACK_IP1}
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC46_TC47 7.2.21 7.2.22 Verify ASR DCGW deletion and re addition from CSC
    [Documentation]    Testcase Id 7.2.21 7.2.22
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.21 Verify ASR DCGW deletion from CSC ${\n} 7.2.22 Verify ASR DCGW re addition from CSC ${\n}"
    Log    "STEP 2 : CHECK BGP NEIGHBORSHIP ESTED"
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ${output} =    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}
    Log    "STEP 4 : DELETE THE DCGW NEIGH USING KARAF CMD ON ODL"
    ${BGP_DELETE_NEIGH_CMD}    Catenate    ${BGP_DELETE_NEIGH_CMD}${DCGW_SYSTEM_IP}   
    ${output} =    Issue Command On Karaf Console    ${BGP_DELETE_NEIGH_CMD}
    ${output} =    Issue Command On Karaf Console    ${BGP_STOP_SERVER_CMD}
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Not Est Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    ${output} =    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Not Contain    ${output}    ${IP}
    Log    "STEP 5 : RE ADD DCGW NEIGH USING KARAF CMD ON ODL" 
    ${BGP_CONFIG_CMD}    Catenate    ${BGP_CONFIG_CMD}${ODL_SYSTEM_IP}
    ${BGP_CONFIG_ADD_NEIGHBOR_CMD}    Catenate    ${BGP_CONFIG_ADD_NEIGHBOR_CMD}${DCGW_SYSTEM_IP} --as-num 100 --use-source-ip ${ODL_SYSTEM_IP}
    ${output} =    Issue Command On Karaf Console    ${BGP_CONFIG_CMD}
    ${output} =    Issue Command On Karaf Console    ${BGP_CONFIG_ADD_NEIGHBOR_CMD}
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    ${output} =    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC35 7.2.10 Verification of VNF port deletion (neutron port delete) across L3VPNoVxLAN
    [Documentation]    Testcase Id 7.2.10
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.10 Verification of VNF neutron port delete across L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Log    "STEP 3 : DELETE NEUTRON PORT PORT11"
    Delete Port    @{PORT_LIST}[0]
    ${output}=    Get Fib Entries    session
    Should Not Contain    ${output}    ${VM_IP_NET1[0]}
    Log    "STEP 4 : DELETE AND RECREATE VM AND PORT"
    Delete And Recreate VM And Port    @{VM_INSTANCES}[0]    @{PORT_LIST}[0]
    Log    "STEP 5 : VERIFY REACHABILITY AFTER RECREATION OF PORT11 AND VM11"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}

TC49 7.2.24 Verify nova migration for L3VPNoVxLAN VNFs
    [Documentation]    Testcase Id 7.2.24
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.2.24 Verify nova migration for L3VPNoVxLAN VNFs ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF33 VNF22<-> VNF44 VNF13<-> VNF31 VNF14<-> VNF41"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    ${output} =    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}
    Log    "STEP 3 : MIGRATE VNF11 FROM CSS1 TO CSS2"
    Nova Migrate    ${VM_INSTANCES[0]}
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_INSTANCES[0]}
    ${output} =    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}    @{VM_IP_NET4}
    \    Should Contain    ${output}    ${IP}
    Log    "STEP 4 : VERIFY PING AFTER MIGRATING VNF11 FROM CSS1 TO CSS2"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET3[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ${VM_IP_NET4[3]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[2]}    ${VM_IP_NET3[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[0]}
    Log    "STEP 5 : MIGRATE VNF11 FROM CSS2 TO CSS1"
    Nova Migrate    ${VM_INSTANCES[0]}
    Verify VM Is ACTIVE    ${VM_INSTANCES[0]}

*** Keywords ***

Pretest Setup
    [Documentation]    Test Case Pretest Setup
    Log    START PRETEST SETUP
    #Create Setup

Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log To Console    "Running Test case level Pretest Cleanup"
    Log    START PRETEST CLEANUP
    Get Test Teardown Debugs
    #Delete Setup

Create Setup
    [Documentation]    Associate EVPN To Routers
    Log    "STEP 1 : ASSOCIATE RTR1 AND RTR2 TO EVPN FROM CSC"
    ${Req_no_of_routers} =    Evaluate    2
    Associate L3VPN To Routers    ${Req_no_of_routers}

Delete Setup
    [Documentation]    Dissociate EVPN From Routers 
    Log    "STEP 1 : Dissociate EVPN From Routers"
    ${Req_no_of_routers} =    Evaluate    2
    Dissociate L3VPN From Routers    ${Req_no_of_routers}

Associate L3VPN To Routers
    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associating router to L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_ROUTER}
    \    ${router_id}=    Get Router Id    ${ROUTERS[${index}]}    ${devstack_conn_id}
    \    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${router_id}

Dissociate L3VPN From Routers
    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociating router from L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_ROUTER}
    \    ${router_id}=    Get Router Id    ${ROUTERS[${index}]}    ${devstack_conn_id}
    \    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Not Contain    ${resp}    ${router_id}

Verify Ping
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
    [Documentation]    Verify Ping among VMs
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}    ping -c 3 ${VM_IP2}
    Should Contain    ${output}    ${PING_REGEXP}

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
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    ${start} =     Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    :FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    :FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
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
    ...    true    @{VM_INSTANCES_NET1}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET2}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET3}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET4}
    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET2}
    ${VM_IP_NET3}    ${DHCP_IP3}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET3}
    ${VM_IP_NET4}    ${DHCP_IP4}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET4}
    Log    ${VM_IP_NET1}
    Log    ${VM_IP_NET2}
    Log    ${VM_IP_NET3}
    Log    ${VM_IP_NET4}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    Should Not Contain    ${VM_IP_NET3}    None
    Should Not Contain    ${VM_IP_NET4}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}

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
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    l3vni=${CREATE_L3VNI[${index}]}    tenantid=${tenant_id}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*

Delete And Recreate VM And Port
    [Arguments]    ${VM_NAME}    ${PORT_NAME}
    [Documentation]    Delete VM and recreate the port and VM
    Delete Vm Instance    ${VM_NAME}
    Create Port    @{NETWORKS}[0]    @{PORT_LIST}[0]    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}
    Create Vm Instance With Port On Compute Node    ${PORT_NAME}    ${VM_NAME}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_NAME}

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
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    : FOR    ${INTERFACE}    IN    @{ROUTER2_INTERFACE}
    \    Add Router Interface    ${ROUTERS[1]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[1]}
    : FOR    ${INTERFACE}    IN    @{ROUTER2_INTERFACE}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    ${GWMAC_ADDRS_ROUTER1}    ${GWIP_ADDRS_ROUTER1} =    Get Gateway MAC And IP Address    ${ROUTERS[0]}
    Log    ${GWMAC_ADDRS_ROUTER1}
    Set Suite Variable    ${GWMAC_ADDRS_ROUTER1}
    Log    ${GWIP_ADDRS_ROUTER1}
    Set Suite Variable    ${GWIP_ADDRS_ROUTER1}
    ${GWMAC_ADDRS_ROUTER2}    ${GWIP_ADDRS_ROUTER2} =    Get Gateway MAC And IP Address    ${ROUTERS[1]}
    Log    ${GWMAC_ADDRS_ROUTER2}
    Set Suite Variable    ${GWMAC_ADDRS_ROUTER2}
    Log    ${GWIP_ADDRS_ROUTER2}
    Set Suite Variable    ${GWIP_ADDRS_ROUTER2}

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
