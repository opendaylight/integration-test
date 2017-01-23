*** Settings ***
Documentation      Test Suite for SF218 EVPN In Inter DC Deployments with CBA \ NON CBA based ODL Cluster
Suite Setup        BuiltIn.Run Keywords    DevstackUtils.Devstack Suite Setup
#...                AND    DevstackUtils.Devstack Suite Setup
#...                AND    Enable ODL Karaf Log
Test Setup         Pretest Setup
Test Teardown      Pretest Cleanup
Library            RequestsLibrary
Resource           ../../../csit/libraries/OpenStackOperations.robot
Resource           ../../../csit/libraries/DevstackUtils.robot
Resource           ../../libraries/SetupUtils.robot
Resource           ../../libraries/VpnOperations.robot
Variables          ../../../csit/variables/SF218_EVPN_In_Inter_DC_Deployments/SF218_EVPN_In_Inter_DC_Deployments_vars.py
Library            DebugLibrary

*** Variables ***
@{NETWORKS}       NET1    NET2    NET3    NET4    NET5    NET6    NET7    NET8
@{SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6    SUBNET7    SUBNET8
@{SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16    10.5.0.0/16    10.6.0.0/16    10.7.0.0/16    10.8.0.0/16
@{PORT_LIST}      PORT11    PORT12    PORT21    PORT22    PORT13    PORT14    PORT23    PORT24
@{VM_INSTANCES}    VM11    VM12    VM21    VM22    VM13    VM14    VM23    VM24
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111
@{VPN_NAME}       vpn1
${CREATE_RD}      ["2200:2"]
${L3VPN_RD}        2200:2
${CREATE_EXPORT_RT}    ["2200:2","8800:2"]
${CREATE_IMPORT_RT}    ["2200:2","8800:2"]
${CREATE_l3VNI}    200
${DEF_LINUX_PROMPT}    #

*** Test Cases ***

SF218_UC1.1_TC_7.1.1 Verification Of Intra_Network_Intra_Openvswitch network connectivity
    [Documentation]    Testcase Id 7.1.1
    [Tags]    Nightly
    ${exp_result}    ConvertToInteger    1

    Log    "Testcases covered as per Testplan ${\n} 7.1.1 Verification Of Intra_Network_Intra_Openvswitch network connectivity ${\n}"

    Log    "STEP 1 : CREATE THE SETUP AS PER TOPOLOGY_1"
    #Topology created and Tunnel between CSS is UP, Open Flow channel is established between VSwitches and CSC

    Log    "STEP 2 : CREATE NETWORK net1 AND net2, BRING UP 4 VNF FOR EACH NETWORK"
    #8 VNFs are up with IP and CSC inventory shows them in the node inventory.


    ${Req_no_of_net} =    Evaluate    2
    ${Req_no_of_subNet} =     Evaluate    2
    ${port_index} =    Evaluate    0
    ${num_of_vms_per_cpn} =    Evaluate    4

    Create Neutron Networks    ${Req_no_of_net}
    ${NET_LIST}    List Networks
    Log To Console    "NETWORK LIST"
    Log To Console    ${NET_LIST}
    Log    ${NET_LIST}
    #Should Contain    ${NET_LIST}    ${REQUIRED_NETWORKS}


    Create Neutron Subnets    ${Req_no_of_subNet}
    ${SUB_LIST}    List Subnets
    Log To Console    "SUBNET LIST"
    Log To Console    ${SUB_LIST}

    Add Ssh Allow Rule

    Create Neutron Ports    ${Req_no_of_net}    ${port_index}
    ${port_index} =    Evaluate    4
    Create Neutron Ports    ${Req_no_of_net}    ${port_index}
    ${PORT_LIST}    List Ports
    Log To Console    "PORT LIST"
    Log To Console    ${PORT_LIST}

    Create Nova VMs    ${num_of_vms_per_cpn}
    ${NOVA_VM_LIST}    List Nova VMs
    Log To Console    "NOVA VM LIST"
    Log To Console    ${NOVA_VM_LIST}

    Log    "STEP 3 : CREATE EVPN FROM THE REST API WITH PROPER EVI ID"
    #EVPN creation is successful, get on the EVPN should display the EVI along with RD, RTs
 
    Create L3VPN

    Log    "STEP 4 : ADD BGP NEIGHBOUR ( ASR AS DCGW ) AND CHECK BGP CONNECTION"
    #BGP neighbour ship is established between CSC and ASR. ASR routes are seen in CSC FIB.

    Log    "STEP 5 : ASSOCIATE net1 AND net2 TO EVPN FROM CSC"
    #Association is successful. CSC fib is populated with 8 VNF and subnet routes along with ASR routes.ASR fib should be in sync with CSC fib. Verify the EVPN pipeline is populated as per EVPN pipeline structure given in reference.

    Associate L3VPN To Networks    ${Req_no_of_net}

    Log    "STEP 6 : PING VNF11 <-> VNF12 AND VNF21 <-> VNF22"
    #Non-stop ping should work between the VNFs. ASR routes are reachable from VNFs
 
    Check ELAN Datapath Traffic Within The Networks    ${Req_no_of_net}
    
*** Keywords ***

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of networks

    ${REQUIRED_NETWORKS}=    Get Slice From List    ${NETWORKS}    0    ${NUM_OF_NETWORK}
    Log To Console    "REQUIRED NETWORKS IS"
    Log To Console    ${REQUIRED_NETWORKS}
    
    : FOR    ${NET}    IN    @{REQUIRED_NETWORKS}
    \    Create Network    ${NET}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks

    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETWORK}
    \    Create SubNet    ${NETWORKS[${index}]}    ${SUBNETS[${index}]}    ${SUBNET_CIDR[${index}]}

    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    ${REQUIRED_SUBNET}=    Get Slice From List    ${SUBNETS}    0    ${NUM_OF_NETWORK}
    #Should Contain    ${REQUIRED_SUBNET}    ${SUB_LIST}
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/subnets/    ${SUBNETS}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    sg-vpnservice
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0


Create Neutron Ports
    [Arguments]    ${NUM_OF_NETWORK}    ${PORT_INDEX}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create four ports under previously created subnets

    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETWORK}
    \    Create Port    ${NETWORKS[${index}]}    ${PORT_LIST[${PORT_INDEX}]}    sg-vpnservice
    \    ${PORT_INDEX} =    Evaluate    ${PORT_INDEX} + 1
    \    Create Port    ${NETWORKS[${index}]}    ${PORT_LIST[${PORT_INDEX}]}    sg-vpnservice
    \    ${PORT_INDEX} =    Evaluate    ${PORT_INDEX} + 1

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_CPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute node with port
   
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_VMS_PER_CPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES[${index}]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    \    ${resp}    Sleep    ${DELAY_AFTER_VM_CREATION}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index} + ${NUM_OF_VMS_PER_CPN} ]}    ${VM_INSTANCES[${index} + ${NUM_OF_VMS_PER_CPN}]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    \    ${resp}    Sleep    ${DELAY_AFTER_VM_CREATION}

    Log    Check for routes
    #Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate
    #${VM_IP}    ${DHCP_IP}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES}
    #Log    ${VM_IP}
    #Set Suite Variable    ${VM_IP}


Create L3VPN
    [Documentation]    Creates L3VPN and verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD[0]}    exportrt=${CREATE_EXPORT_RT[0]}    importrt=${CREATE_IMPORT_RT[0]}    l3vni=${CREATE_L3VNI}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection

    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${network_id}

Check ELAN Datapath Traffic Within The Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Checks datapath within the same network with different vlans.

    ${VM_IP_INDEX}    0
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NET}
    \    ${VM_IP_INDEX} =    Evaluate    ${index} + ${index}
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[${index}]    ${VM_IP[${VM_IP_INDEX}]}    ping -c 3 ${VM_IP[${VM_IP_INDEX}+1]}
    \    Should Contain    ${output}    64 bytes

Wait For Routes To Propogate
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    #${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ${DEF_LINUX_PROMPT}
    #Should Contain    ${output}    @{SUBNET_CIDR}[0]
    #${net_id} =    Get Net Id    @{NETWORKS}[1]    ${devstack_conn_id}
    #${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ${DEF_LINUX_PROMPT}
    #Should Contain    ${output}    @{SUBNET_CIDR}[1]

Verify VMs Received DHCP Lease
    [Arguments]    @{vm_list}
    [Documentation]    Using nova console-log on the provided ${vm_list} to search for the string "obtained" which
    ...    correlates to the instance receiving it's IP address via DHCP. Also retrieved is the ip of the nameserver
    ...    if available in the console-log output. The keyword will also return a list of the learned ips as it
    ...    finds them in the console log output, and will have "None" for Vms that no ip was found.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ip_list}    Create List    @{EMPTY}
    ${dhcp_ip}    Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${vm_ip_line}=    Write Commands Until Prompt    nova console-log ${vm} | grep -i "obtained"    30s
    \    Log    ${vm_ip_line}
    \    @{vm_ip}    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
    \    ${vm_ip_length}    Get Length    ${vm_ip}
    \    Run Keyword If    ${vm_ip_length}>0    Append To List    ${ip_list}    @{vm_ip}[0]
    \    ...    ELSE    Append To List    ${ip_list}    None
    \    ${dhcp_ip_line}=    Write Commands Until Prompt    nova console-log ${vm} | grep "^nameserver"    30s
    \    Log    ${dhcp_ip_line}
    \    @{dhcp_ip}    Get Regexp Matches    ${dhcp_ip_line}    [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
    \    Log    ${dhcp_ip}
    ${dhcp_length}    Get Length    ${dhcp_ip}
    Return From Keyword If    ${dhcp_length}==0    ${ip_list}    ${EMPTY}
    [Return]    ${ip_list}    @{dhcp_ip}[0]

Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output

Pretest Setup
    [Documentation]    Test Case Pretest Setup

    Log    "STEP 1 : $$$$$$$$$$$FILL IN AS PER TESTPLAN$$$$$$$$$$$$$$$$$$$$$"


Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log To Console    "Running Test case level Pretest Cleanup"
    ${RESP}    Log    ***********************************Pretest Cleanup ********************************

