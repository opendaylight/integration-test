*** Settings ***
Documentation     Subnet Routing And Multicast
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           String
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/L2GatewayOperations.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${AS_ID}          100
${SECURITY_GROUP}    sg-multicastservice
${REQ_NO_NET}     3
${REQ_NO_SUBNET}    3
${REQ_NO_VMS_PER_DPN}    6
${REQ_NO_PORTS_PER_DPN}    4
@{VM_DELETE}      multicast_net1_vm1_1    multicast_net1_vm3_2    multicast_net1_vm2_1    multicast_net1_vm4_2
@{PORT_DELETE}    multicast_net1_port1_1    multicast_net1_port3_2    multicast_net1_port2_1    multicast_net1_port4_2
${REQ_NO_CIDR}    10.1.0.0/16
@{REQ_NETWORKS}    multicast_net1    multicast_net2    multicast_net3
@{VM_INSTANCES_DPN1}    multicast_net1_vm1_1    multicast_net1_vm2_1    multicast_net2_vm1_1    multicast_net2_vm2_1    multicast_net3_vm1_1    multicast_net3_vm2_1
@{VM_INSTANCES_DPN2}    multicast_net1_vm3_2    multicast_net1_vm4_2    multicast_net2_vm3_2    multicast_net2_vm4_2    multicast_net3_vm3_2    multicast_net3_vm4_2
@{VM_INSTANCES_DPN1_PORTS}    multicast_net1_port1_1    multicast_net1_port2_1    multicast_net2_port1_1    multicast_net2_port2_1    multicast_net3_port1_1    multicast_net3_port2_1
@{VM_INSTANCES_DPN2_PORTS}    multicast_net1_port3_2    multicast_net1_port4_2    multicast_net2_port3_2    multicast_net2_port4_2    multicast_net3_port3_2    multicast_net3_port4_2
@{REQ_PORT_LIST}    multicast_net1_port1_1    multicast_net1_port2_1    multicast_net1_port3_2    multicast_net1_port4_2    multicast_net2_port1_1    multicast_net2_port2_1    multicast_net2_port3_2
...               multicast_net2_port4_2    multicast_net3_port1_1    multicast_net3_port2_1    multicast_net3_port3_2    multicast_net3_port4_2
@{REQ_SUBNETS}    multicast_subnet1    multicast_subnet2    multicast_subnet3
@{REQ_SUBNET_CIDR}    10.1.0.0/24    10.2.0.0/24    10.3.0.0/24
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111
@{VPN_NAME}       vpn1
@{L3VPN_RD}       2200:2
@{CREATE_RD}      ["2200:2"]
@{CREATE_EXPORT_RT}    ["2200:2"]
@{CREATE_IMPORT_RT}    ["2200:2"]
${REQ_PING_REGEXP}    , 0% packet loss
${REQ_PING_REGEXP_FAIL}    , 100% packet loss
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${OVSDB_STATE}    state=ACTIVE
${VM_IP_NET5}     10.1.0.200
${VM_IP_NET6}     224.1.0.200
@{ALLOWED_IP}     10.1.0.100    10.2.0.100    10.3.0.100    10.1.0.110
@{ALLOWED_IP_PORT}    10.1.0.100    10.2.0.100
@{ALLOWED_IP_PORT1}    10.2.0.100    10.3.0.100
@{ALLOWED_IP_PORT2}    10.3.0.100    10.1.0.100
@{MASK}           32    255.255.255.0
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 10.1.0.100 10.1.0.100
${RPING_MIP_IP1}    sudo arping -I eth0:1 -c 5 -b -s 10.2.0.100 10.2.0.100
${RPING_MIP_IP2}    sudo arping -I eth0:1 -c 5 -b -s 10.3.0.100 10.3.0.100
${RPING_MIP_IP3}    sudo arping -I eth0:1 -c 5 -b -s 10.1.0.110 10.1.0.110
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
@{REQ_VM_INSTANCES_NET1}    multicast_net1_vm1_1    multicast_net1_vm2_1    multicast_net1_vm3_2    multicast_net1_vm4_2
@{REQ_VM_INSTANCES_NET2}    multicast_net2_vm1_1    multicast_net2_vm2_1    multicast_net2_vm3_2    multicast_net2_vm4_2
@{REQ_VM_INSTANCES_NET3}    multicast_net3_vm1_1    multicast_net3_vm2_1    multicast_net3_vm3_2    multicast_net3_vm4_2
${LOOPBACK_IP}    5.5.5.2
${DCGW_RD}        2200:2

*** Test Cases ***
Verify the subnet route when neutron port hosting subnet route is down/up on single VSwitch topology
    [Documentation]    Verify the subnet route when neutron port hosting subnet route is down/up
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface_down    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    ${allowed_ip_list} =    BuiltIn.Create List    @{ALLOWED_IP}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    Verify Ping between Inter Intra And Enterprise host

Verify Enterprise Hosts Reachability After VM Reboot
    [Documentation]    Verify Enterprise Hosts Reachability After VM Reboot
    OpenStackOperations.Get ControlNode Connection
    ${nslist} =    Utils.Write Commands Until Expected Prompt    ip netns list    ${DEFAULT_LINUX_PROMPT_STRICT}
    Log    ${nslist}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1[0]}
    : FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}[0]
    \    OpenStackOperations.Reboot Nova VM    ${VM}
    ${nslist} =    Utils.Write Commands Until Expected Prompt    ip netns list    ${DEFAULT_LINUX_PROMPT_STRICT}
    Log    ${nslist}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1[0]}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route for multiple subnets on multi VSwitch topology when DC-GW is restarted
    [Documentation]    Verify The Subnet Route For One Subnet When DC-GW Is Restarted
    BgpOperations.Restart BGP Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create BGP Config On DCGW
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route for multiple subnets on multi VSwitch topology when QBGP is restarted
    [Documentation]    Verify Enterprise Hosts Reachability After Qbgp Restart
    BgpOperations.Restart bgp Processes On ODL    ${ODL_SYSTEM_IP}
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route when VSwitch hosting subnet route is restarted on single VSwitch topology
    [Documentation]    Verify the subnet route when VSwitch hosting subnet route is restarted on single VSwitch topology
    OVSDB.Restart OVSDB    ${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Get Ovsdb State    ${OS_COMPUTE_2_IP}
    ${allowed_ip_list} =    BuiltIn.Create List    @{ALLOWED_IP}[0]    @{ALLOWED_IP}[1]    @{ALLOWED_IP}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    Verify Ping between Inter Intra And Enterprise host

Verify The Subnet Route When The Network Is Removed From The Vpn
    [Documentation]    Verify The Subnet Route When The Network Is Removed From The Vpn
    Dissociate L3VPN    ${REQ_NO_NET}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
    \    BuiltIn.Should Not Contain    ${output}    ${IP}
    Associate L3VPN To Networks    ${REQ_NO_NET}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}
    \    BuiltIn.Should Contain    ${output}    ${IP}
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    OpenStackOperations.Get ControlNode Connection
    Create Sub Interfaces And Verify
    ${allowed_ip_list} =    BuiltIn.Create List    @{ALLOWED_IP}[0]    @{ALLOWED_IP}[1]    @{ALLOWED_IP}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route when VSwitch hosting subnet Enterprise Host is restarted on single VSwitch topology
    [Documentation]    Validate The Enterprise Host Reachability After Rebooting Node
    OVSDB.Restart OVSDB    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Get Ovsdb State    ${OS_COMPUTE_1_IP}
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route when VSwitch hosting subnet Enterprise Host is restarted on single multiple VSwitch topology
    [Documentation]    Verify Enterprise Hosts Reachability OVS Control Plane Restart On CSS
    OVSDB.Restart OVSDB    ${OS_COMPUTE_1_IP}
    OVSDB.Restart OVSDB    ${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Get Ovsdb State    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Get Ovsdb State    ${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    VpnOperations.Verify Tunnel Status as UP
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route for one subnet on a single VSwitch
    [Documentation]    Verify the subnet route for one subnet on a single VSwitch
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET2}[1]    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    Should Contain    ${output2}    @{ALLOWED_IP}
    OpenStackOperations.Get ControlNode Connection
    Create Sub Interfaces And Verify
    ${allowed_ip_list} =    BuiltIn.Create List    @{ALLOWED_IP}[0]    @{ALLOWED_IP}[1]    @{ALLOWED_IP}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route for multiple subnets on multi VSwitch topology
    [Documentation]    Verify the subnet route for multiple subnets on multi VSwitch topology
    BuiltIn.Log    Bring up enterprise host in another vswitch
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[2]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[3]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[3]}
    \    ...    ${vm_ip}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[2]    ${RPING_MIP_IP3}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET1}[2]    ping -c 3 @{ALLOWED_IP}[3]
    BuiltIn.Should Contain    ${output}    64 bytes
    Verify Ping between Inter Intra And Enterprise host

Verify that the broadcast traffic is always transmitted over ELAN path for network which is associated to l3vpn
    [Documentation]    Verify that the broadcast traffic is always transmitted over ELAN path for network which is associated to l3vpn
    ${cn1} =    Tcpdump.Start Tcpdumping
    ${cn1_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_COMPUTE_1_IP}    file_Name=tcpDumpCN1
    ${cn2_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_COMPUTE_2_IP}    file_Name=tcpDumpCN2
    ${os_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_CONTROL_NODE_IP}    file_Name=tcpDumpOS
    BuiltIn.Log    Check ELAN Datapath Traffic Within The Networks
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 @{VM_IP_NET1}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ping -c 3 @{VM_IP_NET2}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    check ELAN Datapath Traffic For Broadcast Traffic From VM
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 ${VM_IP_NET5}
    BuiltIn.Should Not Contain    ${output}    64 bytes
    ${dumpflow_compute_node1}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo tcpdump -ttttnnr /tmp/tcpDumpCN1.pcap | grep ICMP
    BuiltIn.Log    ${dumpflow_compute_node1}
    ${dumpflow_compute_node2}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo tcpdump -ttttnnr /tmp/tcpDumpCN1.pcap | grep ARP
    BuiltIn.Log    ${dumpflow_compute_node2}
    Verify Ping between Inter Intra And Enterprise host

Verify Multicast traffic always transmitted over ELAN path for network which is associated to l3vpn
    [Documentation]    Verify that the multicast traffic is always transmitted over ELAN path for network which is associated to l3vpn
    ${cn1} =    Tcpdump.Start Tcpdumping
    ${cn1_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_COMPUTE_1_IP}    file_Name=tcpDumpCN1
    ${cn2_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_COMPUTE_2_IP}    file_Name=tcpDumpCN2
    ${os_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_CONTROL_NODE_IP}    file_Name=tcpDumpOS
    BuiltIn.Log    Check ELAN Datapath Traffic Within The Networks
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 @{VM_IP_NET1}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ping -c 3 @{VM_IP_NET2}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    check ELAN Datapath Traffic For Multicast Traffic From VM
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 ${VM_IP_NET6}
    BuiltIn.Should Not Contain    ${output}    64 bytes
    ${dumpflow_compute_node1}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo tcpdump -ttttnnr /tmp/tcpDumpCN1.pcap | grep ICMP
    BuiltIn.Log    ${dumpflow_compute_node1}
    ${dumpflow_compute_node2}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo tcpdump -ttttnnr /tmp/tcpDumpCN1.pcap | grep ARP
    BuiltIn.Log    ${dumpflow_compute_node2}
    Verify Ping between Inter Intra And Enterprise host

Delete And Reconfigure neutron port, subnet, network Hosting Enterprise Host
    [Documentation]    Delete And Reconfigure “neutron port, subnet, network” Hosting Enterprise Host
    : FOR    ${vm}    IN    @{VM_DELETE}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    : FOR    ${port_del}    IN    @{PORT_DELETE}
    \    OpenStackOperations.Delete Port    ${port_del}
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${PORT_URL}    ${PORT_DELETE}
    OpenStackOperations.Delete Network    @{REQ_NETWORKS}[0]
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${NETWORK_URL}    ${REQ_NETWORKS}[0]
    OpenStackOperations.Create Network    @{REQ_NETWORKS}[0]
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${REQ_NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{REQ_NETWORKS}[0]    @{REQ_SUBNETS}[0]    ${REQ_NO_CIDR}
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${REQ_SUBNETS}[0]
    : FOR    ${port_del}    IN    @{PORT_DELETE}
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[0]    ${port_del}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_DELETE[0]}    ${VM_DELETE[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_DELETE[1]}    ${VM_DELETE[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_DELETE[2]}    ${VM_DELETE[2]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_DELETE[3]}    ${VM_DELETE[3]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    BuiltIn.Set Global Variable    @{VM_IP_NET1}
    ${REQ_NO_NET} =    Evaluate    1
    Associate L3VPN To Networks    ${REQ_NO_NET}
    : FOR    ${vm_ip}    IN    @{VM_IP_NET1}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    Verify Ping between Inter Intra And Enterprise host

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Subnet_Routing_and_Multicast_Deployments with CSS.
    VpnOperations.Basic Suite Setup
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    OpenStackOperations.Create Nano Flavor
    Create Setup

Get Ovsdb State
    [Arguments]    ${dpn_ip}
    [Documentation]    Get Ovsdb State for the DPNs
    ${output_dpn1}    Utils.Run Command On Remote System    ${dpn_ip}    sudo ovsdb-client dump -f list Open_vSwitch Controller | grep state
    BuiltIn.Log    ${output_dpn1}
    BuiltIn.Should Contain    ${output_dpn1}    ${OVSDB_STATE}

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{REQ_NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    ${NET_LIST}    OpenStackOperations.List Networks
    BuiltIn.Log    ${NET_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${NET_LIST}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    OpenStackOperations.Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${SUB_LIST}    OpenStackOperations.List Subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[${index}]}

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    : FOR    ${index}    IN RANGE    0    ${REQ_NO_PORTS_PER_DPN}
    \    Create Port    @{REQ_NETWORKS}[0]    @{REQ_PORT_LIST}[${index}]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT}
    ${start} =    Evaluate    ${index}+1
    ${REQ_NO_PORTS_PER_DPN_NET2} =    Evaluate    ${start}+${REQ_NO_PORTS_PER_DPN}
    : FOR    ${index}    IN RANGE    ${start}    ${REQ_NO_PORTS_PER_DPN_NET2}
    \    Create Port    @{REQ_NETWORKS}[1]    @{REQ_PORT_LIST}[${index}]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT1}
    ${start} =    Evaluate    ${index}+1
    ${REQ_NO_PORTS_PER_DPN_NET3} =    Evaluate    ${start}+${REQ_NO_PORTS_PER_DPN}
    : FOR    ${index}    IN RANGE    ${start}    ${REQ_NO_PORTS_PER_DPN_NET3}
    \    Create Port    @{REQ_NETWORKS}[2]    @{REQ_PORT_LIST}[${index}]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT2}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${VM_INSTANCES_DPN1_PORTS[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${VM_INSTANCES_DPN2_PORTS[${index}]}    ${VM_INSTANCES_DPN2[${index}]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    @{VM_IP_NET2}    ${NET2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET2}
    @{VM_IP_NET3}    ${NET3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET3}
    Set Suite Variable    @{VM_IP_NET1}
    Set Suite Variable    @{VM_IP_NET2}
    Set Suite Variable    @{VM_IP_NET3}
    BuiltIn.Should Not Contain    ${VM_IP_NET1}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET2}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET3}    None

Create Setup
    [Documentation]    Create basic topology
    VM Creation Quota Update    30
    OpenStackOperations.Get ControlNode Connection
    Create Neutron Networks    ${REQ_NO_NET}
    Create Neutron Subnets    ${REQ_NO_SUBNET}
    Create And Configure Security Group    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs    ${REQ_NO_VMS_PER_DPN}
    Create Sub Interfaces And Verify
    OpenStackOperations.Get ControlNode Connection
    ${Req_no_of_L3VPN} =    Evaluate    1
    Create L3VPN    ${Req_no_of_L3VPN}
    Associate L3VPN To Networks    ${REQ_NO_NET}
    Create BGP Config On ODL
    Create BGP Config On DCGW
    OpenStackOperations.Get ControlNode Connection
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
    Create External Tunnel Endpoint
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ${RPING_MIP_IP}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ${RPING_MIP_IP1}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]    ${RPING_MIP_IP2}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply

Create Sub Interfaces And Verify
    BuiltIn.Log    Create Sub Interface and verify for all VMs
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET2[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${ALLOWED_IP[1]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${ALLOWED_IP[1]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET3[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${ALLOWED_IP[2]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${ALLOWED_IP[2]}
    \    ...    ${vm_ip}

Delete L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Delete L3VPN
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}

Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Creates L3VPN and verify the same
    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}
    \    ...    tenantid=${tenant_id}
    \    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    BuiltIn.Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    BuiltIn.Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    BuiltIn.Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*

Create BGP Config On ODL
    [Documentation]    Configure BGP Config on ODL
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONFIG_SERVER_CMD}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME[0]}    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    BuiltIn.Log    ${output}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    BuiltIn.Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    BuiltIn.Log    ${output1}

Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    BgpOperations.Delete BGP Configuration On ODL    session
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    ${output} =    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
    BuiltIn.Log    ${output}
    ${output} =    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
    BuiltIn.Log    ${output}

Create External Vxlan Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Vxlan Tunnel Endpoint Configuration    destIp=${OS_COMPUTE_1_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${OS_COMPUTE_1_IP}
    BuiltIn.Should Contain    ${output}    ${OS_COMPUTE_1_IP}

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}
    \    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp} =    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    BuiltIn.Should Contain    ${resp}    ${network_id}

Dissociate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociates L3VPN to networks and verify
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}
    \    VpnOperations.Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp} =    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    BuiltIn.Should Not Contain    ${resp}    ${network_id}

Configure_IP_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${mask}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for configuring specified IP on specified interface and the corresponding specified sub interface
    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number} ${ip} netmask ${mask} up

Configure_IP_On_Sub_Interface_down
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${mask}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for configuring specified IP on specified interface and the corresponding specified sub interface
    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number} ${ip} netmask ${mask} down

Verify_IP_Configured_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for verifying specified IP on specified interface and the corresponding specified sub interface
    ${resp}    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number}
    BuiltIn.Should Contain    ${resp}    ${ip}

Verify Ping between Inter Intra And Enterprise host
    [Documentation]    Ping Enterprise Host for Intra, Inter from different and same network
    ${exp_result}    ConvertToInteger    0
    BuiltIn.Log    "Verification of intra_network_intra_openvswitch network connectivity"
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]
    ...    ping -c 3 @{VM_IP_NET1}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]
    ...    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[3]
    ...    ping -c 3 @{VM_IP_NET1}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    "Verification of intra_network_inter_openvswitch network connectivity"
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]
    ...    ping -c 3 @{VM_IP_NET1}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]
    ...    ping -c 3 @{VM_IP_NET2}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]
    ...    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    "Verification of inter_network_intra_openvswitch network connectivity"
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]
    ...    ping -c 3 @{VM_IP_NET2}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[1]
    ...    ping -c 3 @{VM_IP_NET2}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    Verification of inter_network_intra_openvswitch network connectivity between Enterprise Hosts
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]
    ...    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[1]
    ...    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]
    ...    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[2]
    ...    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]
    ...    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[1]
    ...    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]
    ...    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[2]
    ...    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]
    ...    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[1]
    ...    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]
    ...    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[2]
    ...    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes

Dissociate L3VPN
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociate L3VPN from networks
    OpenStackOperations.Get ControlNode Connection
    Log Many    "Number of network"    ${NUM_OF_NET}
    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETS}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}
    \    VpnOperations.Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    BuiltIn.Should Not Contain    ${resp}    ${network_id}

VM Creation Quota Update
    [Arguments]    ${num_instances}
    [Documentation]    Update VM Creation Quota
    ${rc}    ${output}=    Run And Return Rc And Output    openstack project list
    Log    ${output}
    Should Not Be True    ${rc}
    ${split_output} =    Split String    ${output}
    ${index} =    Get Index From List    ${split_output}    admin
    ${rc}    ${output}=    Run And Return Rc And Output    openstack quota set --instances ${num_instances} ${split_output[${index-2}]}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}
