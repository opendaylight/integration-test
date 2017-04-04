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

*** Variables ***

${DCGW_SYSTEM_IP}     ${TOOLS_SYSTEM_1_IP}
@{PORT_LIST_NEW}      PORT15
${VM_NAME_NEW}        VM15

*** Test Cases ***

TC1 7.1.1 Verification of intra_network_intra_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.1
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.1 Verification Of Intra_Network_Intra_Openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF12 AND VNF21 <-> VNF22"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}
    ${output}=    Get Fib Entries    session

TC2 7.1.2 Verification of intra_network_inter_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.2
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.2 Verification of intra_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF13 AND VNF21 <-> VNF23"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[2]}
    ${output}=    Get Fib Entries    session

TC3 7.1.3 Verification of inter_network_intra_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.3
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.3 Verification of inter_network_intra_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF21 AND VNF12 <-> VNF22"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[0]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[1]}
    ${output}=    Get Fib Entries    session

TC4 7.1.4 Verification of inter_network_inter_openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.4
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.4 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF23 and VNF12 <-> VNF24"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    ${output}=    Get Fib Entries    session

TC7 7.1.7 Verification of VNF reboot across L3VPNoVxLAN
    [Documentation]    Testcase Id 7.1.7
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.7 Verification of VNF reboot across L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF23 and VNF12 <-> VNF24"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    Log    "STEP 3 : REBOOT 8 VNFs AND VERIFY PING ACROSS THEM"
    Reboot VM    @{VM_INSTANCES}
    Log    "STEP 2 : PING VNF11 <-> VNF23 and VNF12 <-> VNF24"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    ${output}=    Get Fib Entries    session

TC8_TC9 7.1.8 7.1.9 Verification of VNF deletion (nova delete) and recreation (nova boot) across L3VPNoVxLAN
    [Documentation]    Testcase Id 7.1.8 7.1.9
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.8 Verification of VNF deletion and recreation across L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF23 and VNF12 <-> VNF24"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    Log    "STEP 3 : NOVA DELETE THE VNFs ONE BY ONE"
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    ${VM_IP_LIST} =    Create List    @{VM_IP_NET1}    @{VM_IP_NET2}
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Remove RSA Key From KnowHosts     ${VM_IP}
    Log    "STEP 4 : NOVA CREATE THE VNFs ONE BY ONE"
    ${Req_no_of_vms_per_dpn} =    Evaluate    4
    Create Nova VMs     ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET1}
    ${output}=    Get Fib Entries    session

TC11 7.1.11 Verification of new VNF bring up across already existed L3VPNoVxLAN
    [Documentation]    Testcase Id 7.1.11
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.11 Verification of new VNF bring up across already existed L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    Log    "STEP 3 : 7 CREATE VNF15 ON OPENVSWITCH1 AND CHECK PING FROM ALL OTHER VNFs AND ASR"
    Create Port    @{NETWORKS}[0]    @{PORT_LIST_NEW}[0]    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST_NEW}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST_NEW}[0]    ${VM_NAME_NEW}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_NAME_NEW}
    ${output}=    Get Fib Entries    session

TC12 7.1.12 Verify manual TEP deletion scenario for L3VPNoVxLAN VNFs
    [Documentation]    Testcase Id 7.1.12
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.12 Verify manual TEP deletion scenario for L3VPNoVxLAN VNFs ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    Log    "STEP 3 : DELETE THE TEP OF openVSwitch1 USING REST API"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Get Fib Entries    session

TC10 7.1.10 Verification of VNF port deletion (neutron port delete) across L3VPNoVxLAN
    [Documentation]    Testcase Id 7.1.10
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.10 Verification of VNF neutron port delete across L3VPNoVxLAN ${\n}"
    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Wait Until Keyword Succeeds    180s    10s    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    Log    "STEP 3 : DELETE NEUTRON PORT PORT11"
    Delete Port    @{PORT_LIST}[0]
    ${output}=    Get Fib Entries    session
    [Teardown]    Run Keywords    Create Port    @{NETWORKS}[0]    @{PORT_LIST}[0]    sg=${SECURITY_GROUP}
    ...    AND    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}

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
    [Documentation]    Associate EVPN To Networks
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}

Delete Setup
    [Documentation]    Dissociate EVPN From Networks 
    Log    "STEP 1 : Dissociate L3VPN From Networks, DELETE L3VPN AND UNCONFIG BGP"
    ${Req_no_of_net} =    Evaluate    2
    Dissociate L3VPN    ${Req_no_of_net}

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
    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET1}
    Log    ${VM_IP_NET2}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}
