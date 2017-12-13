*** Settings ***
Documentation     Test suite to validate BGP vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BGP Vpnservice Suite Setup
Suite Teardown    BGP Vpnservice Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       bgp_net_1    bgp_net_2    bgp_net_3    bgp_net_4
@{SUBNETS}        bgp_sub_1    bgp_sub_2    bgp_sub_3    bgp_sub_4
@{SUBNET_CIDR}    101.1.1.0/8    102.1.1.0/16    103.1.1.0/24    104.1.1.0/24
@{PORTS}          bgp_port_101    bgp_port_102    bgp_port_103    bgp_port_104
@{VM_NAMES}       bgp_vm_101    bgp_vm_102    bgp_vm_103    bgp_vm_104
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112
@{RD_LIST}        ["2200:2"]    ["2300:2"]
@{VPN_NAMES}      bgp_vpn_101    bgp_vpn_102
${LOOPBACK_IP}    5.5.5.2
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${AS_ID}          500
${DCGW_RD}        2200:2
${SECURITY_GROUP}    bgp_sg

*** Test Cases ***
Create BGP Config On ODL
    [Documentation]    Create BGP Config on ODL
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP Config on DCGW
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[0]    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${ODL_SYSTEM_IP}

Verify BGP Neighbor Status
    [Documentation]    Verify BGP status established
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    15s    BgpOperations.Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    BuiltIn.Log    ${output}
    ${output1} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    BuiltIn.Log    ${output1}
    BuiltIn.Should Contain    ${output1}    ${LOOPBACK_IP}

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Verify Routes Exchange Between ODL And DCGW
    [Documentation]    Verify routes exchange between ODL and DCGW
    ${fib_values} =    BuiltIn.Create List    ${LOOPBACK_IP}    @{VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Utils.Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${DCGW_RD}/    ${fib_values}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Verify Routes On Quagga    ${DCGW_SYSTEM_IP}    ${DCGW_RD}    ${fib_values}
    [Teardown]    BuiltIn.Run Keywords    Report_Failure_Due_To_Bug    7607
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Delete External Tunnel Endpoint
    [Documentation]    Delete external tunnel endpoint
    BgpOperations.Delete External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Not Contain    ${output}    ${DCGW_SYSTEM_IP}

Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    BgpOperations.Delete BGP Configuration On ODL    session
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    BuiltIn.Should Not Contain    ${output}    ${DCGW_SYSTEM_IP}
    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/

Delete BGP Config On DCGW
    [Documentation]    Delete BGP Configuration on DCGW
    ${output} =    BgpOperations.Delete BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
    BuiltIn.Log    ${output}
    BuiltIn.Should Not Contain    ${output}    ${ODL_SYSTEM_IP}

*** Keywords ***
BGP Vpnservice Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP}
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    BgpOperations.Create Basic Configuartion for BGP VPNservice Suite

BGP Vpnservice Suite Teardown
    BgpOperations.Delete Basic Configuartion for BGP VPNservice Suite
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.OpenStack Suite Teardown

Create Basic Configuartion for BGP VPNservice Suite
    [Documentation]    Create basic configuration for BGP VPNservice suite
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    ${length} =    BuiltIn.Get Length    ${SUBNETS}
    : FOR    ${idx}    IN RANGE    ${length}
    \    OpenStackOperations.Create SubNet    ${NETWORKS[${idx}]}    ${SUBNETS[${idx}]}    @{SUBNET_CIDR}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    : FOR    ${network}    ${port}    IN ZIP    ${NETWORKS}    ${PORTS}
    \    OpenStackOperations.Create Port    ${network}    ${port}    sg=${SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${PORTS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{VM_NAMES}[0]    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{VM_NAMES}[1]    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{VM_NAMES}[2]    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{VM_NAMES}[3]    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    @{VM_IPS}    ${DHCP_IPS} =    OpenStackOperations.Get VM IPs    @{VM_NAMES}
    BuiltIn.Set Suite Variable    @{VM_IPS}
    BuiltIn.Should Not Contain    ${VM_IPS}    None
    BuiltIn.Should Not Contain    ${DHCP_IPS}    None
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RD_LIST}[0]    exportrt=@{RD_LIST}[0]    importrt=@{RD_LIST}[0]    tenantid=${tenant_id}
    : FOR    ${network}    IN    @{NETWORKS}
    \    ${network_id} =    Get Net Id    ${network}
    \    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Log    ${resp}

Delete Basic Configuartion for BGP VPNservice Suite
    [Documentation]    Delete basic configuration for BGP Vpnservice suite
    : FOR    ${network}    IN    @{NETWORKS}
    \    ${network_id} =    OpenStackOperations.Get Net Id    ${network}
    \    VpnOperations.Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    : FOR    ${vm}    IN    @{VM_NAMES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Delete Port    ${port}
    : FOR    ${subnet}    IN    @{SUBNETS}
    \    OpenStackOperations.Delete SubNet    ${subnet}
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}
