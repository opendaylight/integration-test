*** Settings ***
Documentation      Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster
Test Setup         Pretest Setup
Test Teardown      Pretest Cleanup
Library            RequestsLibrary
Resource           ../../../csit/libraries/OpenStackOperations.robot
Resource           ../../../csit/libraries/DevstackUtils.robot
Resource           ../../libraries/SetupUtils.robot
Resource           ../../libraries/VpnOperations.robot
Variables          ../../variables/Inter-DC_Deployments_TestPlan_Var/SF218_EVPN_In_Inter_DC_Deployments_vars.py
Resource           ../../variables/Inter-DC_Deployments_TestPlan_Var/SF218_EVPN_In_Inter_DC_Deployments_vars.robot
#Resource           ../../../csit/suites/Inter-DC_Deployments_TestPlan/__init__.robot
Variables          ../../variables/Variables.py
#Variables          /home/mininet/final_sf218/test/csit/variables/SF218_EVPN_In_Inter_DC_Deployments/SF218_EVPN_In_Inter_DC_Deployments_vars.py
#Resource           /home/mininet/final_sf218/test/csit/variables/SF218_EVPN_In_Inter_DC_Deployments/SF218_EVPN_In_Inter_DC_Deployments_vars.robot
#Variables          /home/mininet/final_sf218/test/csit/variables/Variables.py


*** Test Cases ***

TC1
    [Documentation]    Testcase Id 7.1.1
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.1 Verification Of Intra_Network_Intra_Openvswitch network connectivity ${\n}"
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STEP 2 : PING VNF11 <-> VNF12 AND VNF21 <-> VNF22"
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}
    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}

TC4_TC16_TC18
    [Documentation]    Testcase Id 7.1.4 7.1.16 7.1.18
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.4 7.1.16 7.1.18 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[2]}
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET2[1]}    ${VM_IP_NET2[3]}

TC2
    [Documentation]    Testcase Id 7.1.2
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.2 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STEP 2 : PING VNF11 <-> VNF13 AND VNF21 <-> VNF23"
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[2]}
    Verify Ping    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[2]}

TC3
    [Documentation]    Testcase Id 7.1.3
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.3 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STEP 2 : PING VNF11 <-> VNF21 AND VNF12 <-> VNF22"
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[0]}
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[1]}

#TC5
#    [Documentation]    Testcase Id 7.1.5
#    [Tags]    Nightly
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.5 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
#    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
#    ${Req_no_of_net} =    Evaluate    2
#    Associate L3VPN To Networks    ${Req_no_of_net}
#    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
#    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
#    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}

#TC6
#    [Documentation]    Testcase Id 7.1.6
#    [Tags]    Nightly
#    ${exp_result}    ConvertToInteger    1
#    Log    "Testcases covered as per Testplan ${\n} 7.1.6 Verification of subnet route and VNF as gateway after VNF reboot ${\n}"
    

TC7
    [Documentation]    Testcase Id 7.1.7
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.7 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    Log    "STEP 3 : Reboot all the 8 VNFs and verify ping across them"
    Reboot VM    @{VM_INSTANCES}
    #Reboot VM    ${VM_IP_NET2}
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}

TC8
    [Documentation]    Testcase Id 7.1.8
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1
    Log    "Testcases covered as per Testplan ${\n} 7.1.8 Verification of inter_network_inter_openvswitch network connectivity ${\n}"
    Log    "STEP 1 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STEP 2 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}
    Log    "STEP 3 : Nova delete the VNFs one by one"
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    Log    "STEP 4 : Nova Create the VNFs one by one"
    ${Req_no_of_vms_per_dpn} =    Evaluate    4
    Create Nova VMs     ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET1}
    Log    "STEP 5 : PING VNF11 <-> VNF23 AND VNF12 <-> VNF24"
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[2]}
    Verify Ping    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[3]}


*** Keywords ***

Pretest Setup
    [Documentation]    Test Case Pretest Setup
    Log    Start Pretest Setup
    Create Setup


Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log To Console    "Running Test case level Pretest Cleanup"
    Log    Start Pretest Cleanup
    Get Test Teardown Debugs
    Delete Setup

Create Setup
    [Documentation]    Create Required number of EVPN, add BGP configuration, verify ITM tunnels are up and verify if the VM's are UP
    Log    "STEP 1 : CREATE EVPN FROM THE REST API WITH PROPER EVI ID"
    Log    Create EVPN FROM THE REST API WITH PROPER EVI ID
    #EVPN creation is successful, get on the EVPN should display the EVI along with RD, RTs
    ${Req_no_of_L3VPN} =    Evaluate    1
    Create L3VPN    ${Req_no_of_L3VPN}

    #Log    "STEP 2 : ADD BGP NEIGHBOUR ( ASR AS DCGW ) AND CHECK BGP CONNECTION"
    #Log    ADD BGP NEIGHBOUR ( ASR AS DCGW ) AND CHECK BGP CONNECTION
    #BGP neighbour ship is established between CSC and ASR. ASR routes are seen in CSC FIB.
    #Create BGP Configuration    localas=100    routerid=${ODL_SYSTEM_IP}
    #AddNeighbor To BGP Configuration       remoteas=100      neighborAddr=${DCGW_SYSTEM_IP}
    #AddVRF To BGP Configuration       rd=${CREATE_RD[1]}    impRT=${CREATE_EXPORT_RT[1]}     expRT=${CREATE_IMPORT_RT[1]}
    #${output} =     Get BGP Configuration
    #Log     ${output}
    #Should Contain      ${output}     ${DCGW_SYSTEM_IP}

    Log    Verify tunnel btw the DPN is up
    Verify Tunnel Status as UP
    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Log    Verify VM is active
    :FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}

Delete Setup
    [Documentation]    Dissociate EVPN From Networks, Delete EVPN created and unconfigure BGP 
    Log    "STEP 1 : Dissociate L3VPN From Networks, DELETE L3VPN AND UNCONFIG BGP"
    Log    Dissociate L3VPN From Networks
    ${Req_no_of_net} =    Evaluate    2
    Dissociate L3VPN    ${Req_no_of_net}
    Log    DELETE L3VPN
    ${Req_no_of_L3VPN} =    Evaluate    1
    Delete L3VPN    ${Req_no_of_L3VPN}
    #Log    Delete BGP config
    #Delete BGP Configuration 
    #${output} =     Get BGP Configuration 
    #Log     ${output} 

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

#Create BGP Configuration
#    [Arguments]    &{Kwargs}
#    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
#    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/create_bgp    mapping=${Kwargs}    session=session

#AddNeighbor To BGP Configuration
#    [Arguments]    &{Kwargs}
#    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
#    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/addNeighbor_bgp    mapping=${Kwargs}    session=session

#AddVRF To BGP Configuration
#    [Arguments]    &{Kwargs}
#    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
#    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/addVRF_bgp    mapping=${Kwargs}    session=session

#Get BGP Configuration
#    [Documentation]    Get bgp configuration
#    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/ebgp:bgp/
#    Log    ${resp.content}
#    [Return]    ${resp.content}

#Delete BGP Configuration
#    [Documentation]    Delete BGP
#    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_API}/ebgp:bgp/
#    Log    ${resp.content}
#    Should Be Equal As Strings    ${resp.status_code}    200
#    [Return]    ${resp.content}

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
#    ${resp}=    Should Contain    ${flow_output}    table=50
#    Log    ${resp}
#    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
#    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
#    ${table51_output} =    Get Lines Containing String    ${flow_output}    table=51
#    Log    ${table51_output}
#    @{table51_output}=    Split To Lines    ${table51_output}    0    -1
#    : FOR    ${line}    IN    @{table51_output}
#    \    Log    ${line}
#    \    ${resp}=    Should Match Regexp    ${line}    ${MAC_REGEX}

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
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    ${start} =     Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    :FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES[${index}]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    :FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${VM_IP_NET1}    ${DHCP_IP1}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET2}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}

