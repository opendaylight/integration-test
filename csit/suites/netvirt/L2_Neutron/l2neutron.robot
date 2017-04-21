*** Settings ***
Documentation     Test suite to validate L2 Neutron functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{EXTRA_NW_IP}    40.1.1.2    50.1.1.2
@{EXTRA_NW_SUBNET}    40.1.1.0/24    50.1.1.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4
@{ELAN1_PORT_LIST}    PORT1    PORT3
@{ELAN2_PORT_LIST}    PORT2    PORT4
${VM_NAMES}       VM11    VM12    VM21    VM22
@{VM_INSTANCES_DPN1}    VM11    VM21
@{VM_INSTANCES_DPN2}    VM12    VM22
${ROUTER}         ROUTER_1
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111
${VPN_NAME}       vpn1
${CREATE_RD}      ["2200:2"]
${CREATE_EXPORT_RT}    ["2200:2"]
${CREATE_IMPORT_RT}    ["2200:2"]
${EPH1_CFG}       sudo ifconfig eth0:1 10.1.1.110 netmask 255.255.255.0 up
${EPH2_CFG}       sudo ifconfig eth0:1 20.1.1.110 netmask 255.255.255.0 up
${EPH2_UNCFG}     sudo ifconfig eth0:1 down
@{BROADCAST_IP}    10.1.1.255    20.1.1.255
${MULTICAST_IP}    224.0.0.1
${SECURITY_GROUP}    sg-l2neutron
${PING_CMD11}     "ping 10.1.1.110 -c 25"
${PING_CMD22}     "ping 20.1.1.210 -c 25"
${VAR_BASE_BGP}    ${CURDIR}/../../../variables/bgpfunctional
${BGP_AS_ID}      500
@{DCGW_INTERFACE_IPS}    30.1.1.1    31.1.1.1    32.1.1.1    33.1.1.1    34.1.1.1
@{DCGW_SUBNETMASK}    8    16    24    24    32
@{DCGW_INTERFACE_NAMES}    int1    int2    int3    int4    int5
${LOOPBACK_IP}    3.3.3.3
${LOOPBACK_NAME}    lo
${RD_DCGW}        100:31

*** Test Cases ***
TC01 Broadcast/Unicast testing with L3VPN service
    [Documentation]    Generate broadcast&Unicast traffic from VM1 & Verify
    Log    Verification of FIB Entries and Flow
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${VM_IP_NET20}
    ${SRCMAC_CPN1} =    Create List    ${VM_MACAddr_ELAN1[0]}
    ${SRCMAC_CPN2} =    Create List    ${VM_MACAddr_ELAN2[0]}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CPN1}    ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${SRCMAC_CPN2}    ${VM_MACAddr_ELAN2}
    ${ELAN_Packets_1}    ${VPN_Packets_1}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[0]}    ${VM_MACAddr_ELAN2[1]}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${BROADCAST_IP[0]}
    ${ELAN_Packets_2}    ${VPN_Packets_2}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[0]}    ${VM_MACAddr_ELAN2[1]}
    Should Be True    ${ELAN_Packets_1} < ${ELAN_Packets_2}
    Should Be True    ${VPN_Packets_1} == ${VPN_Packets_2}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET10[1]}
    Should Contain    ${output}    64 bytes
    ${ELAN_Packets_3}    ${VPN_Packets_3}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[0]}    ${VM_MACAddr_ELAN2[1]}
    Should Be True    ${ELAN_Packets_2} < ${ELAN_Packets_3}
    Should Be True    ${VPN_Packets_2} == ${VPN_Packets_3}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${ELAN_Packets_4}    ${VPN_Packets_4}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[0]}    ${VM_MACAddr_ELAN2[1]}
    Should Be True    ${VPN_Packets_4} > ${VPN_Packets_3}

TC02 Verify subnet route for 1 subnet on single CSS
    [Documentation]    Verify subnet route for 1 subnet on single CSS
    ${dcgwRoutes} =    Create List    ${LOOPBACK_IP}    ${DCGW_INTERFACE_IPS[0]}
    Log    Verification of FIB Entries and Flow after ping tests
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ${PING_CMD11}
    Should Contain    ${output}    64 bytes
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD_DCGW}/    ${dcgwRoutes}
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_DCGW}    ${VM_IP_NET10[0]}

TC03 Verify subnet route after OVS restart
    [Documentation]    Verify subnet route after OVS restart
    ${dcgwRoutes} =    Create List    ${LOOPBACK_IP}    ${DCGW_INTERFACE_IPS[0]}
    Log    Restarting OVS1
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_DCGW}    ${VM_IP_NET10[0]}
    Utils.Run Command On Mininet    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_DCGW}    ${VM_IP_NET10[1]}
    Wait Until Keyword Succeeds    30s    5s    Verify Route is deleted On Quagga    ${RD_DCGW}    ${VM_IP_NET10[0]}
    Utils.Run Command On Mininet    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    Checking the subnet route and FIB entries after restart
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_1_IP}
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ${PING_CMD11}
    Should Contain    ${output}    64 bytes
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD_DCGW}/    ${dcgwRoutes}
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_DCGW}    ${VM_IP_NET10[0]}

TC04 Verify the subnet route when the network is removed from the vpn
    [Documentation]    Verify subnet route before and after dissociating L3VPN
    ${dcgwRoutes} =    Create List    ${LOOPBACK_IP}    ${DCGW_INTERFACE_IPS[0]}
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    Dissociate L3VPN From Networks    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements Not At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD_DCGW}/    ${VM_IP_NET10[0]}
    Wait Until Keyword Succeeds    30s    5s    Verify Route is deleted On Quagga    ${RD_DCGW}    ${VM_IP_NET10[0]}
    Associate L3VPN To Network    networkid=${net_id}    vpnid=${VPN_INSTANCE_IDS[0]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD_DCGW}/    ${dcgwRoutes}
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_LIST}    ${VM_IP_NET10[0]}

TC05 Verify the subnet route when neutron port hosting subnet route is down/up
    [Documentation]    Verify the subnet route when neutron port hosting subnet route is down/up
    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    sudo reboot
    Wait Until Keyword Succeeds    30s    5s    Verify Route is deleted On Quagga    ${RD_DCGW}    ${VM_IP_NET10[0]}
    Wait Until Keyword Succeeds    180s    5s    Verify VM Is ACTIVE    ${VM_IP_NET10[0]}
    ${VM_IP_NET10}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_NET10}
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_LIST}    ${VM_IP_NET10[0]}

TC06 Verify the subnet route after disabling Enterpise host on DPN2
    [Documentation]    Verify that the DPN after disabling enterprise host will learn subnet routes dynamically
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET20[0]}    ${EPH2_UNCFG}
    Log    ${output}
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_LIST}    ${VM_IP_NET10[1]}
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_LIST}    ${VM_IP_NET10[0]}

TC07 Verify the subnet route for one subnet when tunnel goes down between DPNs
    [Documentation]    Verify the subnet route for one subnet when the ITM tunnel goes down between DPN1 & DPN2
    ${Zone_Name}    ITM Get Tunnels
    ITM Delete Tunnel    ${Zone_Name}
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ${PING_CMD11}
    Should Contain    ${output}    0 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[1]}    ${PING_CMD22}
    Should Contain    ${output}    0 bytes

TC08 Verify the subnet route when the neutron port is deleted
    [Documentation]    Verify the subnet route when the neutron port acting like gateway for Subnet Route is deleted
    Delete Vm Instance    ${VM_INSTANCES_DPN1[0]}
    Wait Until Keyword Succeeds    30s    5s    Verify Route is deleted On Quagga    ${RD_DCGW}    ${VM_IP_NET10[0]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements Not At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD_DCGW}/    ${VM_IP_NET10[0]}
    Wait Until Keyword Succeeds    30s    5s    Verify Routes on DCGW    ${RD_LIST}    ${VM_IP_NET20[0]}

*** Keywords ***
Start Suite
    [Documentation]    Run before the suite execution
    DevstackUtils.Devstack Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Add Ssh Allow Rule    ${SECURITY_GROUP}
    Basic VPN service Setup
    DCGW Suite Setup
    Configure Enterprise Network Host

Stop Suite
    [Documentation]    Run after the tests execution
    DCGW Suite Teardown
    Unconfigure ODL Setup
    Delete Ssh Allow Rule    ${SECURITY_GROUP}
    Close All Connections

Add Ssh Allow Rule
    [Arguments]    ${sg_name}
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

DCGW Suite Setup
    [Documentation]    Login to the DCGW
    ${dcgw_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    Set Suite Variable    ${dcgw_conn_id}
    Log    ${dcgw_conn_id}
    Utils.Flexible SSH Login    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    Start Quagga Processes On DCGW    ${TOOLS_SYSTEM_IP}
    Create BGP Config On DCGW
    Add Interfaces On DCGW    ${DCGW_INTERFACE_NAMES}    ${DCGW_INTERFACE_IPS}    ${DCGW_SUBNETMASK}

Basic VPN service Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs
    Log    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/networks/    ${NETWORKS}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/subnets/    ${SUBNETS}
    Log    Create four ports under previously created subnets
    ${allowed_address_pairs_args}=    Set Variable    --allowed-address-pairs type=dict list=true ip_address=${EXTRA_NW_SUBNET[0]} ip_address=${EXTRA_NW_SUBNET[1]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_DPN1[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_DPN1[1]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_DPN2[0]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_DPN2[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    ${VM_INSTANCES_NET10} =    Create List    ${VM_INSTANCES_DPN1[0]}    ${VM_INSTANCES_DPN2[0]}
    ${VM_INSTANCES_NET20} =    Create List    ${VM_INSTANCES_DPN1[1]}    ${VM_INSTANCES_DPN2[1]}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    60s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Check for routes
    ${VM_IP_NET10}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_NET10}
    Log    ${VM_IP_NET10}
    Set Suite Variable    ${VM_IP_NET10}
    ${VM_IP_NET20}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_NET20}
    Log    ${VM_IP_NET20}
    Set Suite Variable    ${VM_IP_NET20}
    ${VM_MACAddr_ELAN1}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${ELAN1_PORT_LIST}
    Log    ${VM_MACAddr_ELAN1}
    Set Suite Variable    ${VM_MACAddr_ELAN1}
    ${VM_MACAddr_ELAN2}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${ELAN2_PORT_LIST}
    Log    ${VM_MACAddr_ELAN2}
    Set Suite Variable    ${VM_MACAddr_ELAN2}
    Log    Create Router
    Create Router    ${ROUTER[0]}
    ${router_list} =    Create List    ${ROUTER[0]}
    Wait Until Keyword Succeeds    30s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}
    Log    Add Interfaces to router
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTER[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTER[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    Log    Creates a L3VPN and then verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD[0]}    exportrt=${CREATE_EXPORT_RT[0]}    importrt=${CREATE_IMPORT_RT[0]}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    Log    Associating network to Router
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTER[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}
    # Configure BGP
    Create BGP Configuration On ODL    localas=${BGP_AS_ID[0]}    routerid=${ODL_SYSTEM_IP}
    AddNeighbor To BGP Configuration On ODL    remoteas=${BGP_AS_ID[0]}    neighborAddr=${TOOLS_SYSTEM_IP}
    ${output} =    Get BGP Configuration On ODL
    Log    ${output}
    Should Contain    ${output}    ${TOOLS_SYSTEM_IP}
    ${output}=    Issue Command On Karaf Console    display-bgp-config
    Log    ${output}
    Create external tunnel endpoint Configuration    destIp=${TOOLS_SYSTEM_IP}
    ${output} =    Get External Tunnel Endpoint Configuration    ${TOOLS_SYSTEM_IP}
    Should Contain    ${output}    ${TOOLS_SYSTEM_IP}

Configure Enterprise Network Host
    [Documentation]    Bring up EPhosts on DPN1 & DPN2
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    ${EPH1_CFG}
    Log    ${output}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET20[0]}    ${EPH2_CFG}
    Log    ${output}

Unconfigure ODL Setup
    [Documentation]    Delete the created L3VPN, Router, VMs, ports, subnet and networks
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID}
    #Delete Interface
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTER[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTER[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTER[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Not Contain    ${router_output}    ${ROUTER[0]}
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}

Verify VMs received IP
    [Arguments]    ${VM_NAMES}
    [Documentation]    Verify VM Instance received IP
    ${VM_IPS}    ${DHCP_IP1}    Verify VMs Received DHCP Lease    @{VM_NAMES}
    Log    ${VM_IPS}
    Should Not Contain    ${VM_IPS}    None
    [Return]    ${VM_IPS}

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

Get PacketCount from Flow Table
    [Arguments]    ${cnIp}    ${dest_ip}    ${dest_mac}
    [Documentation]    Get the packet count from given table using the destination nw_dst=ip or dl_dst=mac
    ${ELAN_REGEX} =    Set Variable    table=${ELAN_DMACTABLE}, n_packets=\\d+,\\s.*,dl_dst=${dest_mac}
    ${L3VPN_REGEX} =    Set Variable    table=${L3_TABLE}, n_packets=\\d+,\\s.*,nw_dst=${dest_ip}
    ${PACKET_COUNT_REGEX} =    Set Variable    n_packets=\\d+
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${flowEntry} =    Get Regexp Matches    ${flowOutput}    ${ELAN_REGEX}
    Log    ${flowEntry}
    ${match} =    Get Regexp Matches    ${flowEntry[0]}    ${PACKET_COUNT_REGEX}
    Log    ${match}
    ${n_packets} =    Split String    ${match[0]}    separator==
    ${n_packets_ELAN} =    Get from List    ${n_packets}    1
    ${n_packets_ELAN} =    Convert To Integer    ${n_packets_ELAN}
    Log    ${n_packets_ELAN}
    ${flowEntry} =    Get Regexp Matches    ${flowOutput}    ${L3VPN_REGEX}
    Log    ${flowEntry}
    ${match} =    Get Regexp Matches    ${flowEntry[0]}    ${PACKET_COUNT_REGEX}
    Log    ${match}
    ${n_packets} =    Split String    ${match[0]}    separator==
    ${n_packets_L3VPN}=    Get from List    ${n_packets}    1
    ${n_packets_L3VPN} =    Convert To Integer    ${n_packets_L3VPN}
    Log    ${n_packets_L3VPN}
    [Return]    ${n_packets_ELAN}    ${n_packets_L3VPN}

Delete Ssh Allow Rule
    [Arguments]    ${sg_name}
    [Documentation]    Delete Security group
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-delete ${sg_name}    40s
    Log    ${output}
    Should Match Regexp    ${output}    Deleted security_group: ${sg_name}|Deleted security_group\\(s\\): ${sg_name}
    Close Connection

Verify Flows Are Present For ELAN Service
    [Arguments]    ${ip}    ${srcMacAddrs}    ${destMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN service
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=${ELAN_SMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log    ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${sMac_output}    ${sMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_DMACTABLE}
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log    ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{destMacAddrs}
    \    ${resp}=    Should Contain    ${dMac_output}    ${dMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    Log    ${sMac_output}

Add Interfaces On DCGW
    [Arguments]    ${interface_Names}    ${interface_IPs}    ${subnetMask}    ${conn_id}=${dcgw_conn_id}    ${user}=zebra    ${password}=zebra
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    DCGW Connect Telnet Session    ${conn_id}    ${user}    ${password}
    Execute Command On DCGW Telnet Session    enable
    Execute Command On DCGW Telnet Session    ${password}
    Execute Command On DCGW Telnet Session    configure terminal
    ${length}=    Get Length    ${interface_Names}
    : FOR    ${idx}    IN RANGE    ${length}
    \    Execute Command On DCGW Telnet Session    interface ${interface_Names[${idx}]}
    \    Execute Command On DCGW Telnet Session    ip address ${interface_IPs[${idx}]}/${subnetMask[${idx}]}
    \    Execute Command On DCGW Telnet Session    exit
    Execute Command On DCGW Telnet Session    end
    ${output} =    Execute Command On DCGW Telnet Session    show running-config
    Log    ${output}
    Execute Command On DCGW Telnet Session    exit

Create BGP Config On DCGW
    [Documentation]    Configure BGP Config on DCGW
    Configure BGP And Add Neighbor On DCGW    ${TOOLS_SYSTEM_IP}    ${BGP_AS_ID[0]}    ${TOOLS_SYSTEM_IP}    ${HA_PROXY_IP}    ${VPN_NAME[0]}    ${RD_DCGW}
    ...    ${LOOPBACK_IP}
    Add Loopback Interface On DCGW    ${TOOLS_SYSTEM_IP}    ${LOOPBACK_NAME}    ${LOOPBACK_IP}
    ${output} =    Execute Show Command On Quagga    ${TOOLS_SYSTEM_IP}    show running-config
    Log    ${output}
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${TOOLS_SYSTEM_IP}    ${HA_PROXY_IP}
    Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${TOOLS_SYSTEM_IP}    show ip bgp vrf ${RD_DCGW}
    Log    ${output1}
    Should Contain    ${output1}    ${LOOPBACK_IP}

Verify Route is deleted On Quagga
    [Arguments]    ${dcgw_ip}    ${rd}    ${ip_list}
    [Documentation]    Verify routes on quagga
    ${output} =    Execute Show Command On quagga    ${dcgw_ip}    show ip bgp vrf ${rd}
    Log    ${output}
    : FOR    ${ip}    IN    @{ip_list}
    \    Should Not Contain    ${output}    ${ip}
