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
${ODL_ENABLE_L3_FWD}    yes
${AS_ID}          100
${SECURITY_GROUP}    sg-vpnservice
${Req_no_of_net}    6
${Req_no_of_subNet}    6
${Req_no_of_ports}    12
${Req_no_of_vms_per_dpn}    6
${Req_no_of_ports_per_dpn}    4
${Req_no_of_vms_dpn}    1
${Req_no_of_routers}    2
@{vm_delete}    VM11    VM13    VM12   VM14
@{VM_INSTANCES_REBOOT}    VM11
@{port_delete}    PORT11    PORT13    PORT12    PORT14
${req_no_cidr}   10.1.0.0/16
@{REQ_NETWORKS}       NET1    NET2    NET3    NET4    NET5    NET6
@{VM_INSTANCES_DPN1}    VM11    VM12    VM21    VM22    VM31    VM32
@{VM_INSTANCES_DPN2}    VM13    VM14    VM23    VM24    VM33    VM34
@{VM_INSTANCES_DPN1_PORTS}    PORT11    PORT12    PORT21    PORT22    PORT31    PORT32
@{VM_INSTANCES_DPN2_PORTS}    PORT13    PORT14    PORT23    PORT24    PORT33    PORT34
@{VM_INSTANCES}    VM11    VM12    VM21    VM22    VM31    VM32
...               VM13    VM14    VM23    VM24    VM33    VM34
@{REQ_PORT_LIST}      PORT11    PORT12    PORT13    PORT14    PORT21    PORT22
...               PORT23    PORT24    PORT31    PORT32    PORT33    PORT34
@{REQ_SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6
@{ROUTER1_INTERFACE}    SUBNET1    SUBNET2    SUBNET3
@{REQ_SUBNET_CIDR}    10.1.0.0/24    10.2.0.0/24    10.3.0.0/24    10.4.0.0/24    10.5.0.0/24    10.6.0.0/24    10.7.0.0/24
@{REQ_SUBNET_CIDR_FIB}    10.1.0.0/24    10.2.0.0/24    10.3.0.0/24
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222    4ae8cd92-48ca-49b5-94e1-b2921a263333
@{VPN_NAME}       vpn1    vpn2    vpn3
@{REQ_ROUTERS}        RTR1    RTR2
@{L3VPN_RD}       2200:2
@{CREATE_RD}      ["2200:2"]    ["100:3"]    ["100:4"]
@{CREATE_EXPORT_RT}    ["2200:2"]    ["100:3"]    ["100:4"]
@{CREATE_IMPORT_RT}    ["2200:2"]    ["100:3"]    ["100:4"]
${LOGIN_PSWD}     admin123
${REQ_PING_REGEXP}    , 0% packet loss
${REQ_PING_REGEXP_FAIL}    , 100% packet loss
@{CREATE_l3VNI}    200    300    400
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${CONFIG_API}     /restconf/config
@{net_del}    NET1
@{sub_add}    SUBNET1
${zone}    TZA
${OVSDB_STATE}    state=ACTIVE
${VM_IP_NET5}    10.1.0.200
${VM_IP_NET6}    224.1.0.200
@{ALLOWED_IP}     10.1.0.100    10.2.0.100    10.3.0.100    10.1.0.110
@{ALLOWED_IP_PORT}     10.1.0.100    10.2.0.100
@{ALLOWED_IP_PORT1}     10.2.0.100    10.3.0.100
@{ALLOWED_IP_PORT2}     10.3.0.100    10.1.0.100
@{MASK}           32    255.255.255.0
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 10.1.0.100 10.1.0.100
${RPING_MIP_IP1}    sudo arping -I eth0:1 -c 5 -b -s 10.2.0.100 10.2.0.100
${RPING_MIP_IP2}    sudo arping -I eth0:1 -c 5 -b -s 10.3.0.100 10.3.0.100
${RPING_MIP_IP3}    sudo arping -I eth0:1 -c 5 -b -s 10.1.0.110 10.1.0.110
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
@{REQ_VM_INSTANCES_NET1}    VM11    VM12    VM13    VM14
@{REQ_VM_INSTANCES_NET2}    VM21    VM22    VM23    VM24
@{REQ_VM_INSTANCES_NET3}    VM31    VM32    VM33    VM34
${LOOPBACK_IP}    5.5.5.2
${DCGW_RD}        2200:2

*** Test Cases ***
Delete And Reconfigure neutron port, subnet, network Hosting EP Host
    [Documentation]    Delete And Reconfigure “neutron port, subnet, network” Hosting EP Host
    Get ControlNode Connection
    BuiltIn.Log    Delete the VMs from DPNs
    : FOR    ${vm}    IN    @{vm_delete}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    BuiltIn.Log    Delete the Ports from DPNs
    : FOR    ${port_del}    IN    @{port_delete}
    \    OpenStackOperations.Delete Port    ${port_del}
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${PORT_URL}    ${port_delete}
    BuiltIn.Log    Delete the Network from DPNs
    OpenStackOperations.Delete Network    @{net_del}[0]
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${NETWORK_URL}    ${net_del}
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    Get ControlNode Connection
    BuiltIn.Log    Add the deleted network, port and VM
    OpenStackOperations.Create Network    @{net_del}[0]
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${net_del}
    OpenStackOperations.Create SubNet    @{net_del}[0]    @{sub_add}[0]    ${req_no_cidr}
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${sub_add}
    BuiltIn.Log    Creating Port
    : FOR    ${port_del}    IN    @{port_delete}
    \    OpenStackOperations.Create Port    @{net_del}[0]    ${port_del}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${port_delete[0]}    ${vm_delete[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${port_delete[1]}    ${vm_delete[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${port_delete[2]}    ${vm_delete[2]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${port_delete[3]}    ${vm_delete[3]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    Set Global Variable    @{VM_IP_NET1}
    ${Req_no_of_net} =    Evaluate    1
    Associate L3VPN To Networks    ${Req_no_of_net}
    BuiltIn.Log    Creating Sub Interface for NET1
    : FOR    ${vm_ip}    IN    @{VM_IP_NET1}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    Verify Ping between Inter Intra And Enetrprise host  

Verify Subnet Route Programming On CSS And EP’s Host Routes In Different VPNs Reachable From DC-GW & VMs On Remote DPNs
    [Documentation]    Verify Subnet Route Programming On CSS And EP’s Host Routes In Different VPNs Reachable From DC-GW & VMs On Remote DPNs
    Verify Ping between Inter Intra And Enetrprise host
    comment    TODO

Verify the subnet route when neutron port hosting subnet route is down/up on single VSwitch topology
    [Documentation]    Verify the subnet route when neutron port hosting subnet route is down/up
    BuiltIn.Log    Check the host route is added to fib, before VM reboots
    Get ControlNode Connection
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface_down    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    BuiltIn.Log    "Check the host route is added to fib, after VM reboots"
    Verify Ping between Inter Intra And Enetrprise host

Verify Enterprise Hosts Reachability After VM Reboot
    [Documentation]    Verify Enterprise Hosts Reachability After VM Reboot
    BuiltIn.Log    Check the host route is added to fib, before VM reboots
    Get ControlNode Connection
    ${nslist} =    Utils.Write Commands Until Expected Prompt    ip netns list    ${DEFAULT_LINUX_PROMPT_STRICT}
    Log    ${nslist}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1[0]}
    :FOR    ${VM}    IN    @{VM_INSTANCES_REBOOT}
    \    OpenStackOperations.Reboot Nova VM    ${VM}
    ${nslist} =    Utils.Write Commands Until Expected Prompt    ip netns list    ${DEFAULT_LINUX_PROMPT_STRICT}
    Log    ${nslist}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1[0]}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    BuiltIn.Log    "Check the host route is added to fib, after VM reboots"
    Verify Ping between Inter Intra And Enetrprise host


#Verify EP Hosts Reachability After Active ITM Tunnel Failover
#    [Documentation]    Verify EP Hosts Reachability After Active ITM Tunnel Failover
#    VERIFY_FIBFLOWTABLE_AFTER_DCGW_TO_EPHOST_PING
#    BuiltIn.Log    Down the tunnel bridge between Compute1 and Compute2 then verify tunnel status
#    VpnOperations.ITM Get Tunnels      
#    VpnOperations.ITM Delete Tunnel    ${zone}    
#    Create ITM Tunnel And Verify
#    VpnOperations.ITM Get Tunnels
#    VERIFY_FIBFLOWTABLE_AFTER_DCGW_TO_EPHOST_PING
 
Verify the subnet route for multiple subnets on multi VSwitch topology when DC-GW is restarted
    [Documentation]    Verify The Subnet Route For One Subnet When DC-GW Is Restarted
    BgpOperations.Restart bgp Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Restart BGP Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create BGP Config On DCGW
    Verify Ping between Inter Intra And Enetrprise host

Verify the subnet route for multiple subnets on multi VSwitch topology when QBGP is restarted
    [Documentation]    Verify EP Hosts Reachability After Qbgp Restart
    BgpOperations.Restart bgp Processes On ODL    ${ODL_SYSTEM_IP}
    Verify Ping between Inter Intra And Enetrprise host

Verify the subnet route when VSwitch hosting subnet route is restarted on single VSwitch topology
    [Documentation]    Verify the subnet route when VSwitch hosting subnet route is restarted on single VSwitch topology
    Get ControlNode Connection
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    BuiltIn.Log    Restart OVSDB
    OVSDB.Restart OVSDB    ${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Get Ovsdb State    ${OS_COMPUTE_2_IP}
    Verify Ping between Inter Intra And Enetrprise host

Verify The Subnet Route When The Network Is Removed From The Vpn
    [Documentation]    Verify The Subnet Route When The Network Is Removed From The Vpn
    Get ControlNode Connection
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    BuiltIn.Log    Dissociate L3VPN From Networks
    ${Req_no_of_net} =    Evaluate    3
    Dissociate L3VPN    ${Req_no_of_net}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}
    \    BuiltIn.Should Not Contain    ${output}    ${IP}
    BuiltIn.Log    Assocaite Net1, Net2 and Net3 to L3VPN
    ${Req_no_of_net} =    Evaluate    3
    Associate L3VPN To Networks    ${Req_no_of_net}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}
    \    BuiltIn.Should Contain    ${output}    ${IP}
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    Verify Ping between Inter Intra And Enetrprise host

#Verify The Subnet Route For One Subnet When Tunnel Goes Down Between VSwitches
#    [Documentation]    Verify The Subnet Route For One Subnet When Tunnel Goes Down Between VSwitches
#    VERIFY_FIBFLOWTABLE_AFTER_DCGW_TO_EPHOST_PING
#    BuiltIn.Log    "Down the tunnel bridge between Compute1 and Compute2 then verify tunnel status"
#    VpnOperations.ITM Get Tunnels
#    VpnOperations.ITM Delete Tunnel    ${zone}
#    Create ITM Tunnel And Verify
#    VpnOperations.ITM Get Tunnels
#    VERIFY_FIBFLOWTABLE_AFTER_DCGW_TO_EPHOST_PING

Verify the subnet route when VSwitch hosting subnet Enterprise Host is restarted on single VSwitch topology
    [Documentation]    Validate The EP1 Host Reachability After Rebooting The CSS Other Than The CSS Hosting EP1 Host route
    Get ControlNode Connection
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    BuiltIn.Log    Restart OVSDB
    OVSDB.Restart OVSDB    ${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Get Ovsdb State    ${OS_COMPUTE_2_IP}
    Verify Ping between Inter Intra And Enetrprise host

Verify the subnet route when VSwitch hosting subnet Enterprise Host is restarted on single multiple VSwitch topology
    [Documentation]    Verify Enterprise Hosts Reachability OVS Control Plane Restart On CSS
    BuiltIn.Log    Restart OVSDB
    OVSDB.Restart OVSDB    ${OS_COMPUTE_1_IP}
    OVSDB.Restart OVSDB    ${OS_COMPUTE_2_IP}
    BuiltIn.Log    Getting the OVSDB State
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Get Ovsdb State    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Get Ovsdb State    ${OS_COMPUTE_2_IP}
    BuiltIn.Log    VERIFY TUNNELS BETWEEN DPNS IS UP
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    VpnOperations.Verify Tunnel Status as UP
    Verify Ping between Inter Intra And Enetrprise host

Verify the subnet route for one subnet on a single VSwitch
    [Documentation]    Verify the subnet route for one subnet on a single VSwitch
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET2}[1]    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    Should Contain    ${output2}    @{ALLOWED_IP}    
    Verify Ping between Inter Intra And Enetrprise host

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
    Verify Ping between Inter Intra And Enetrprise host

Verify that the broadcast traffic is always transmitted over ELAN path for network which is associated to l3vpn
    [Documentation]    Verify that the broadcast traffic is always transmitted over ELAN path for network which is associated to l3vpn
    Get ControlNode Connection
    Verify Ping between Inter Intra And Enetrprise host
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

Verify that the multicast traffic is always transmitted over ELAN path for network which is associated to l3vpn
    [Documentation]    Verify that the multicast traffic is always transmitted over ELAN path for network which is associated to l3vpn
    Verify Ping between Inter Intra And Enetrprise host
    Get ControlNode Connection
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

Delete And Reconfigure neutron port, subnet, network Hosting EP Host
    [Documentation]    Delete And Reconfigure “neutron port, subnet, network” Hosting EP Host
    Get ControlNode Connection
    BuiltIn.Log    Delete the VMs from DPNs
    : FOR    ${vm}    IN    @{vm_delete}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    BuiltIn.Log    Delete the Ports from DPNs
    : FOR    ${port_del}    IN    @{port_delete}
    \    OpenStackOperations.Delete Port    ${port_del}
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${PORT_URL}    ${port_delete}
    BuiltIn.Log    Delete the Network from DPNs
    OpenStackOperations.Delete Network    @{net_del}[0]
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${NETWORK_URL}    ${net_del}
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    Get ControlNode Connection
    BuiltIn.Log    Add the deleted network, port and VM
    OpenStackOperations.Create Network    @{net_del}[0]
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${net_del}
    OpenStackOperations.Create SubNet    @{net_del}[0]    @{sub_add}[0]    ${req_no_cidr}
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${sub_add}
    BuiltIn.Log    Creating Port
    : FOR    ${port_del}    IN    @{port_delete}
    \    OpenStackOperations.Create Port    ${net_del}    ${port_del}    sg=${SECURITY_GROUP}
    \    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${port_delete}
    Create Vm Instance With Port On Compute Node    ${port_delete[0]}    ${vm_delete[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${port_delete[1]}    ${vm_delete[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${port_delete[2]}    ${vm_delete[2]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${port_delete[3]}    ${vm_delete[3]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    BuiltIn.Wait Until Keyword Succeeds    180s    10s
    ...    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET1}
    ${Req_no_of_net} =    Evaluate    1
    Associate L3VPN To Networks    ${Req_no_of_net}
    BuiltIn.Log    Creating Sub Interface for NET1
    : FOR    ${vm_ip}    IN    @{VM_IP_NET1}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    BuiltIn.Log    FIB-Show
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    Verify Ping between Inter Intra And Enetrprise host    

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
    \     BuiltIn.Should Contain    ${NET_LIST}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    OpenStackOperations.Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${SUB_LIST}    OpenStackOperations.List Subnets
    BuiltIn.Log    ${SUB_LIST}
    BuiltIn.Log    REQUIRED SUBNET IS
    BuiltIn.Log    ${SUB_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[${index}]}

Security Group Rule with Remote IP Prefix
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}    ${additional_args}==${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of ports under previously created subnets
    : FOR    ${index}    IN RANGE    0    ${Req_no_of_ports_per_dpn}
    \    ${port_name}    Get From List    ${REQ_PORT_LIST}    ${index}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer    ${net}
    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT}
    #\    Create Port    ${network}    ${port_name}    allowed_address_pairs=@{ALLOWED_IP_PORT}
    ${start} =    Evaluate    ${index}+1
    ${Req_no_of_ports_per_dpn_net2} =    Evaluate    ${start}+${Req_no_of_ports_per_dpn}
    : FOR    ${index}    IN RANGE    ${start}    ${Req_no_of_ports_per_dpn_net2}
    \    ${port_name}    Get From List    ${REQ_PORT_LIST}    ${index}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer    ${net}
    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT1}
    #\    Create Port    ${network}    ${port_name}    allowed_address_pairs=@{ALLOWED_IP_PORT1}
    ${start} =    Evaluate    ${index}+1
    ${Req_no_of_ports_per_dpn_net3} =    Evaluate    ${start}+${Req_no_of_ports_per_dpn}
    : FOR    ${index}    IN RANGE    ${start}    ${Req_no_of_ports_per_dpn_net3}
    \    ${port_name}    Get From List    ${REQ_PORT_LIST}    ${index}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer    ${net}
    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT2}
    #\    Create Port    ${network}    ${port_name}    allowed_address_pairs=@{ALLOWED_IP_PORT2}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${VM_INSTANCES_DPN1_PORTS[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${VM_INSTANCES_DPN2_PORTS[${index}]}    ${VM_INSTANCES_DPN2[${index}]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    @{VM_IP_NET2}    ${NET2_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET2}
    @{VM_IP_NET3}    ${NET3_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET3}
    Set Suite Variable    @{VM_IP_NET1}
    Set Suite Variable    @{VM_IP_NET2}
    Set Suite Variable    @{VM_IP_NET3}
    BuiltIn.Should Not Contain    ${VM_IP_NET1}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET2}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET3}    None
#    [Teardown]    Run Keywords    Show Debugs    @{REQ_VM_INSTANCES_NET1}    @{REQ_VM_INSTANCES_NET2}    @{REQ_VM_INSTANCES_NET3}
#    ...    AND    Get Test Teardown Debugs

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    Log    Create tunnels between the 2 compute nodes
    VM Creation Quota Update    30
    Create ITM Tunnel And Verify
    Get ControlNode Connection
    Create Neutron Networks    ${Req_no_of_net}
    Create Neutron Subnets    ${Req_no_of_subNet}
    Security Group Rule with Remote IP Prefix
    Create Neutron Ports    ${Req_no_of_ports}   
    Create Nova VMs    ${Req_no_of_vms_per_dpn}
    BuiltIn.Log    STARTING ENTERPRISE NETWORK HOST CONFIGURATION
    Create Sub Interfaces And Verify
    Get ControlNode Connection
    Create Routers    ${Req_no_of_routers}
    BuiltIn.Log    CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID
    ${Req_no_of_L3VPN} =    Evaluate    1
    Create L3VPN    ${Req_no_of_L3VPN}
    BuiltIn.Log    ASSOCIATE net1 AND net2 TO EVPN FROM CSC
    ${Req_no_of_net} =    Evaluate    3
    Associate L3VPN To Networks    ${Req_no_of_net}
    Create BGP Config On ODL
    Create BGP Config On DCGW
    Get ControlNode Connection
    BuiltIn.Log    VERIFY TUNNELS BETWEEN DPNS IS UP
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
    BuiltIn.Log    CREATE EXTERNAL TUNNEL ENDPOINT BTW ODL AND DCGW
    Create External Tunnel Endpoint
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    Log    ${output2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ${RPING_MIP_IP}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ${RPING_MIP_IP1}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]    ${RPING_MIP_IP2}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply

Create ITM Tunnel And Verify
    [Documentation]    Create ITM Tunnel And Verify
    ${node_1_dpid}=    Get DPID    ${OS_COMPUTE_1_IP}
    ${node_2_dpid}=    Get DPID    ${OS_COMPUTE_2_IP}
    ${node_3_dpid}=    Get DPID    ${OS_CONTROL_NODE_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_CONTROL_NODE_IP}
    Set Global Variable    ${node_1_adapter}
    Set Global Variable    ${node_2_adapter}
    Set Global Variable    ${node_3_adapter}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet}=    Set Variable    ${first_two_octets}.56.0/24
    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}
    ${gateway1}=    Get Default Gateway    ${OS_CONTROL_NODE_IP}
    ${gateway2}=    Get Default Gateway    ${OS_COMPUTE_2_IP}
    Issue Command On Karaf Console    tep:add ${node_1_dpid} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:add ${node_2_dpid} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:add ${node_3_dpid} ${node_3_adapter} 0 ${OS_CONTROL_NODE_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:commit
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Log    ${output}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    VpnOperations.Verify Tunnel Status as UP

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

Create Routers
    [Arguments]    ${NUM_OF_ROUTERS}
    [Documentation]    Create Router
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTERS}
    \    OpenStackOperations.Create Router    ${REQ_ROUTERS[${index}]}
    ${router_output} =    OpenStackOperations.List Routers
    BuiltIn.Log    ${router_output}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTERS}
    \    BuiltIn.Should Contain    ${router_output}    ${REQ_ROUTERS[${index}]}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${REQ_ROUTERS}

Delete L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Delete L3VPN
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
#    VpnOperations.VPN Delete L3VPN    vpnid=d5f3a2b9-2268-4faf-b552-ceddabe57bf4
#    VpnOperations.VPN Delete L3VPN    vpnid=cd0a3beb-10c8-40fe-8978-0250a11c0899

Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Creates L3VPN and verify the same
    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    tenantid=${tenant_id}
    #\    ...    l3vni=${CREATE_L3VNI[${index}]}    tenantid=${tenant_id}
#    \    ...    tenantid=${tenant_id}
    \    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    BuiltIn.Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    BuiltIn.Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    BuiltIn.Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
#    \    BuiltIn.Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*

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
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
    BuiltIn.Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
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
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    BuiltIn.Should Contain    ${resp}    ${network_id}

Dissociate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociates L3VPN to networks and verify
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}
    \    VpnOperations.Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
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

Verify Ping between Inter Intra And Enetrprise host
    [Documentation]    PING EPHOST AND CHECK FIB FOR ENTERPRISE HOST ROUTES 
    ${exp_result}    ConvertToInteger    0
    BuiltIn.Log    "Verification of intra_network_intra_openvswitch network connectivity"
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 @{VM_IP_NET1}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[3]    ping -c 3 @{VM_IP_NET1}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    "Verification of intra_network_inter_openvswitch network connectivity"
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 @{VM_IP_NET1}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ping -c 3 @{VM_IP_NET2}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    "Verification of inter_network_intra_openvswitch network connectivity"
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 @{VM_IP_NET2}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[1]    ping -c 3 @{VM_IP_NET2}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    "Verification of inter_network_intra_openvswitch network connectivity between EP Hosts"
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[1]    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[2]    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes

    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[1]    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[2]    ping -c 3 @{ALLOWED_IP}[2]
    BuiltIn.Should Contain    ${output}    64 bytes

    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[1]    ping -c 3 @{ALLOWED_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[2]    ping -c 3 @{ALLOWED_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
#    BuiltIn.Log    LIST ROUTES ON ODL
#    ${output} =    Show Quagga Configuration On ODL    ${ODL_SYSTEM_IP}    ${DCGW_RD}    
#    BuiltIn.Log    ${output}
#    Get ControlNode Connection
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    BuiltIn.Log    LIST ROUTES ON QUAGGA
    ${output} =    Execute Show Command On quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    BuiltIn.Log    ${output}

Add Interfaces To Routers
    [Documentation]    Add Interfaces
    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE}
    \    OpenStackOperations.Add Router Interface    @{REQ_ROUTERS}[0]    ${INTERFACE}
    ${interface_output} =    OpenStackOperations.Show Router Interface    @{REQ_ROUTERS}[0]
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE}
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE} 
    \    BuiltIn.Should Contain    ${interface_output}    ${subnet_id}

Dissociate L3VPN
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociate L3VPN from networks
    Get ControlNode Connection
    Log Many    "Number of network"    ${NUM_OF_NET}
    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETS}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    
    \    VpnOperations.Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    BuiltIn.Should Not Contain    ${resp}    ${network_id}

VM Creation Quota Update
    [Arguments]    ${num_instances}
    [Documentation]    Update VM Creation Quota
    ${rc}    ${output}=    Run And Return Rc And Output    openstack project list
    Log    ${output}
    Should Not Be True    ${rc}
    ${split_output}=    Split String    ${output}
    ${index} =    Get Index From List    ${split_output}    admin
    ${rc}    ${output}=    Run And Return Rc And Output    openstack quota set --instances ${num_instances} ${split_output[${index-2}]}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output} 
