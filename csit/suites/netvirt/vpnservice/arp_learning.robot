*** Settings ***
Documentation     Test suite for ARP Request. More test cases to be added in subsequent patches.
Suite Setup       VpnOperations.Basic Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${SECURITY_GROUP}    vpna_sg
@{NETWORKS}       vpna_net_1    vpna_net_2    vpna_net_3
@{SUBNETS}        vpna_sub_1    vpna_sub_2    vpna_sub_3
@{SUBNET_CIDRS}    10.10.10.0/24    10.20.20.0/24    10.30.30.0/24
@{PORTS}          vpna_net_1_port_1    vpna_net_1_port_2    vpna_net_2_port_1    vpna_net_2_port_2    vpna_net_3_port_1    vpna_net_3_port_2
@{NET_1_VMS}      vpna_net_1_vm_1    vpna_net_1_vm_2
@{NET_2_VMS}      vpna_net_2_vm_1    vpna_net_2_vm_2
@{NET_3_VMS}      vpna_net_3_vm_1    vpna_net_3_vm_2
${ROUTER}        vpna_router
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261111
@{VPN_NAMES}      vpna_1
${RD1}            ["2200:2"]
${RD2}            ["2200:3"]
${EXPORT_RT}      ["2200:2","2200:3"]
${IMPORT_RT}      ["2200:2","2200:3"]
${SUB_IF}         eth0:1
@{EXTRA_NW_IP}    192.168.10.110    192.168.20.110
${FIB_ENTRY_2}    192.168.10.110
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 192.168.10.110 192.168.10.110
${RPING_MIP_IP_2}    sudo arping -I eth0:1 -c 5 -b -s 192.168.20.110 192.168.20.110
${RPING_EXP_STR}    broadcast

*** Test Cases ***
Create Neutron Networks
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    ${neutron_networks} =    OpenStackOperations.List Networks
    : FOR    ${network}    IN    @{NETWORKS}
    \    BuiltIn.Should Contain    ${neutron_networks}    ${network}
    ${NET_ID} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    BuiltIn.Set Suite Variable    ${NET_ID}

Create Neutron Subnets
    : FOR    ${i}    IN RANGE    0    3
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${i}]    @{SUBNETS}[${i}]    @{SUBNET_CIDRS}[${i}]
    ${neutron_subnets} =    OpenStackOperations.List Subnets
    : FOR    ${subnet}    IN    @{SUBNETS}
    \    BuiltIn.Should Contain    ${neutron_subnets}    ${subnet}

Add Ssh Allow All Rule
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Neutron Ports
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{EXTRA_NW_IP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{EXTRA_NW_IP}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[2]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{EXTRA_NW_IP}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{EXTRA_NW_IP}
    OpenStackOperations.Create Port    @{NETWORKS}[2]    @{PORTS}[4]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{EXTRA_NW_IP}
    OpenStackOperations.Create Port    @{NETWORKS}[2]    @{PORTS}[5]    sg=${SECURITY_GROUP}    allowed_address_pairs=@{EXTRA_NW_IP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORTS}

Create Nova VMs
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{NET_2_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[4]    @{NET_3_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[5]    @{NET_3_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    @{NET_3_VM_IPS}    ${NET_3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_3_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_DHCP_IP}    None

Create Router
    OpenStackOperations.Create Router    ${ROUTER}
    OpenStackOperations.Add Router Interface    ${ROUTER}    @{SUBNETS}[1]
    OpenStackOperations.Add Router Interface    ${ROUTER}    @{SUBNETS}[2]

Create L3VPN
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${NET_ID}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=${VPN_NAMES[0]}    rd=${RD1}    exportrt=${EXPORT_RT}    importrt=${IMPORT_RT}    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[0]

Associate L3VPN To ROUTER
    VpnOperations.Associate L3VPN To Network    networkid=${NET_ID}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${NET_ID}
    ${ROUTER_ID} =    OpenStackOperations.Get Router Id    ${ROUTER}
    BuiltIn.Set Suite Variable    ${ROUTER_ID}
    VpnOperations.Associate VPN to Router    routerid=${ROUTER_ID}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${ROUTER_ID}

Verify Setup
    [Documentation]    Verify that VMs received ip and ping is happening between different VM
    ${vms} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}    @{NET_3_VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRIES_URL}    ${vms}
    Verify Ping On Same Networks
    Verify Ping On Different Networks

Verify GARP Requests
    [Documentation]    Verify that GARP request are sent to controller
    BuiltIn.Set Test Variable    ${fib_entry_1}    @{NET_1_VM_IPS}[0]
    BuiltIn.Set Test Variable    ${fib_entry_3}    @{NET_1_VM_IPS}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    ${output} =    VpnOperations.Get Fib Entries    session
    ${resp} =    BuiltIn.Should Match Regexp    ${output}    destPrefix\\":\\"${fib_entry_3}\/32".*"${OS_COMPUTE_2_IP}\\"
    ${resp} =    BuiltIn.Should Match Regexp    ${output}    destPrefix\\":\\"${fib_entry_1}\/32".*"${OS_COMPUTE_1_IP}\\"
    ${rx_packet1_before} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ifconfig eth0
    ${rx_packet0_before} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ifconfig eth0
    ${config_extra_route_ip1} =    BuiltIn.Catenate    sudo ifconfig ${SUB_IF} @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${config_extra_route_ip1}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ifconfig
    BuiltIn.Should Contain    ${output}    ${SUB_IF}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${RPING_MIP_IP}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply
    ${rx_packet1_after} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ifconfig eth0
    ${rx_packet0_after} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ifconfig eth0
    BuiltIn.Should Not Be Equal    ${rx_packet0_before}    ${rx_packet0_after}
    BuiltIn.Should Not Be Equal    ${rx_packet1_before}    ${rx_packet1_after}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    Verify Learnt IP    ${FIB_ENTRY_2}    session
    ${output} =    VpnOperations.Get Fib Entries    session
    ${resp} =    BuiltIn.Should Match Regexp    ${output}    destPrefix\\":\\"${fib_entry_3}\\/32".*"${OS_COMPUTE_2_IP}\\"
    ${resp} =    BuiltIn.Should Match Regexp    ${output}    destPrefix\\":\\"${fib_entry_1}\\/32".*"${OS_COMPUTE_1_IP}\\"
    ${resp} =    BuiltIn.Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\\/32".*"${OS_COMPUTE_2_IP}\\"
    Verify Ping To Sub Interface    ${FIB_ENTRY_2}

Verify MIP Migration
    [Documentation]    Verify that after migration of movable ip across compute nodes, the controller updates the routes
    ${unconfig_extra_route_ip1} =    BuiltIn.Catenate    sudo ifconfig ${SUB_IF} down
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${unconfig_extra_route_ip1}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ifconfig
    BuiltIn.Should Not Contain    ${output}    ${SUB_IF}
    ${config_extra_route_ip1} =    BuiltIn.Catenate    sudo ifconfig ${SUB_IF} @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${config_extra_route_ip1}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ifconfig
    BuiltIn.Should Contain    ${output}    ${SUB_IF}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ifconfig ${SUB_IF}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${RPING_MIP_IP}
    BuiltIn.Should Contain    ${output}    Received 0 reply
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    Verify Learnt IP    ${FIB_ENTRY_2}    session
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${RPING_MIP_IP}
    ${output}    VpnOperations.Get Fib Entries    session
    ${resp}=    BuiltIn.Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\\/32".*"${OS_COMPUTE_1_IP}\\"
    Verify Ping To Sub Interface    ${FIB_ENTRY_2}
    ${unconfig_extra_route_ip1} =    BuiltIn.Catenate    sudo ifconfig ${SUB_IF} down
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${unconfig_extra_route_ip1}

Verify ping to subnet gateway
    [Documentation]    Verify ping happens to subnet gateway. To be submitted in next patch
    [Tags]    not-implemented    exclude
    TODO

If anything other than subnet ip then no reply
    [Documentation]    If anything other than subnet ip then no reply. To be submitted in next patch
    [Tags]    not-implemented    exclude
    TODO

Validate multiple mip migration
    [Documentation]    Validate multiple mip migration. To be submitted in next patch
    [Tags]    not-implemented    exclude
    TODO

Same DPN MIP Migration
    [Documentation]    Same DPN MIP Migration. To be submitted in next patch
    [Tags]    not-implemented    exclude
    TODO

Cleanup
    [Documentation]    Delete the setup
    VpnOperations.Dissociate L3VPN From Networks    networkid=${NET_ID}    vpnid=@{VPN_INSTANCE_IDS}[0]
    VpnOperations.Dissociate VPN to Router    routerid=${ROUTER_ID}    vpnid=@{VPN_INSTANCE_IDS}[0]
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    OpenStackOperations.Remove Interface    ${ROUTER}    @{SUBNETS}[1]
    OpenStackOperations.Remove Interface    ${ROUTER}    @{SUBNETS}[2]
    OpenStackOperations.Delete Router    ${ROUTER}
    @{vms} =    BuiltIn.Create List    @{NET_1_VMS}    @{NET_2_VMS}    @{NET_3_VMS}
    @{sgs} =    BuiltIn.Create List    ${SECURITY_GROUP}
    OpenStackOperations.Neutron Cleanup    ${vms}    ${NETWORKS}    ${SUBNETS}    ${PORTS}    ${sgs}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    OpenStackOperations.OpenStack Suite Setup
    TemplatedRequests.Create Default Session    timeout=10

Verify Ping On Same Networks
    [Documentation]    Verify ping among VM of same network
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ping -c 3 @{NET_1_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[1]    ping -c 3 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{NET_3_VM_IPS}[0]    ping -c 3 @{NET_3_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify Ping On Different Networks
    [Documentation]    Verify ping among VMs of different network
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 @{NET_3_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[1]    ping -c 3 @{NET_3_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{NET_3_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Utils.Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    BuiltIn.Log    ${flow_output}
    ${resp} =    BuiltIn.Should Contain    ${flow_output}    table=50
    ${resp} =    BuiltIn.Should Contain    ${flow_output}    table=21,
    @{vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}    @{NET_3_VM_IPS}
    ${resp} =    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp} =    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    : FOR    ${ip}    IN    @{vm_ips}
    \    ${resp} =    Should Match regexp    ${flow_output}    table=21.*nw_dst=${ip}

Verify Ping To Sub Interface
    [Arguments]    ${sub_interface_ip}
    [Documentation]    Verify ping to the sub-interface
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 ${sub_interface_ip}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 ${sub_interface_ip}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{NET_3_VM_IPS}[0]    ping -c 3 ${sub_interface_ip}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify Learnt IP
    [Arguments]    ${ip}    ${session}
    [Documentation]    Check that sub interface ip has been learnt after ARP request
    ${resp}    RequestsLibrary.Get Request    ${session}    /restconf/operational/odl-l3vpn:learnt-vpn-vip-to-port-data/
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Contain    ${resp.content}    ${ip}

TODO
    Fail    "Not implemented"
