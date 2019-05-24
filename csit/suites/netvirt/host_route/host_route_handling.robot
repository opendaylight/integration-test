*** Settings ***
Documentation     Test suite for VM based Host Route Handling
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{NETWORKS}       host_route_network_1    host_route_network_2    host_route_network_3    host_route_network_4
@{SUBNETS}        host_route_subnet_1    host_route_subnet_2    host_route_subnet_3    host_route_subnet_4
@{SUBNET_CIDR}    10.10.10.0    10.20.20.0    10.30.30.0    10.40.40.0
${PREFIX24}       /24
${SECURITY_GROUP}    host_route_security_group
@{PORTS}          host_route_port_1    host_route_port_2    host_route_port_3    host_route_port_4    host_route_port_5    host_route_port_6    host_route_port_7
@{GATEWAY_PORTS}    host_route_gw_port_1    host_route_gw_port_2    host_route_gw_port_3    host_route_gw_port_4    host_route_gw_port_5    host_route_gw_port_6    host_route_gw_port_7
${ALLOWED_ADDRESS_PAIR}    0.0.0.0/0
${NETWORK_1_VMS}    host_route_vm_1
@{NETWORK_2_VMS}    host_route_vm_2    host_route_vm_3
@{NETWORK_3_VMS}    host_route_vm_4    host_route_vm_5
@{NETWORK_4_VMS}    host_route_vm_6    host_route_vm_7
@{GATEWAY_VMS}    host_route_gw_vm_1    host_route_gw_vm_2
${ROUTER}         host_route_router_1
@{NON_NEUTRON_DESTINATION}    5.5.5.0    6.6.6.0
${NON_NEUTRON_NEXTHOP}    10.10.10.250

*** Test Cases ***
Verify creation of host route via openstack subnet create option
    [Documentation]    Creating subnet host route via openstack cli and verifying in controller and openstack.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDR}[0]${PREFIX24}    --host-route destination=@{SUBNET_CIDR}[2]${PREFIX24},gateway=${NON_NEUTRON_NEXTHOP}
    ${SUBNET_GW_IP}    BuiltIn.Create List
    FOR    ${subnet}    IN    @{SUBNETS}
        ${ip} =    OpenStackOperations.Get Subnet Gateway Ip    ${subnet}
        Collections.Append To List    ${SUBNET_GW_IP}    ${ip}
    END
    BuiltIn.Set Suite Variable    ${SUBNET_GW_IP}
    ${elements} =    BuiltIn.Create List    "destination":"@{SUBNET_CIDR}[2]${PREFIX24}","nexthop":"${NON_NEUTRON_NEXTHOP}"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}
    Verify Hostroutes In Subnet    @{SUBNETS}[0]    destination='@{SUBNET_CIDR}[2]${PREFIX24}',\\sgateway='${NON_NEUTRON_NEXTHOP}'
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}    allowed_address_pairs=${ALLOWED_ADDRESS_PAIR}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    ${NETWORK_1_VMS}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{GATEWAY_PORTS}[0]    sg=${SECURITY_GROUP}    allowed_address_pairs=${ALLOWED_ADDRESS_PAIR}
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{GATEWAY_PORTS}[0]    @{GATEWAY_PORTS}[1]    @{GATEWAY_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{GATEWAY_PORTS}[4]    @{GATEWAY_PORTS}[5]    @{GATEWAY_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${NETWORK_1_VM_IPS}    ${NETWORK_1_DHCP_IP}    ${VM_COSOLE_OUTPUT} =    OpenStackOperations.Get VM IP    true    ${NETWORK_1_VMS}
    BuiltIn.Set Suite Variable    ${NETWORK_1_VM_IPS}
    @{GATEWAY_VM_IPS}    ${GATEWAY_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{GATEWAY_VMS}
    BuiltIn.Set Suite Variable    @{GATEWAY_VM_IPS}
    #TODO: Verifiy the routes in VM.
    OpenStackOperations.Show Debugs    ${NETWORK_1_VMS}    @{GATEWAY_VMS}
    OpenStackOperations.Get Suite Debugs

Verify creation of host route via openstack subnet update option
    [Documentation]    Creating host route using subnet update option and setting nexthop ip to subnet gateway ip. Verifying in controller and openstack.
    OpenStackOperations.Update SubNet    @{SUBNETS}[0]    --host-route destination=@{NON_NEUTRON_DESTINATION}[0]${PREFIX24},gateway=@{SUBNET_GW_IP}[0]
    ${elements} =    BuiltIn.Create List    "destination":"@{NON_NEUTRON_DESTINATION}[0]${PREFIX24}","nexthop":"@{SUBNET_GW_IP}[0]"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}
    Verify Hostroutes In Subnet    @{SUBNETS}[0]    destination='@{NON_NEUTRON_DESTINATION}[0]${PREFIX24}',\\sgateway='@{SUBNET_GW_IP}[0]'

Verify removal of host route
    [Documentation]    Removing subnet host routes via cli and verifying in controller and openstack.
    OpenStackOperations.Unset SubNet    @{SUBNETS}[0]    --host-route destination=@{NON_NEUTRON_DESTINATION}[0]${PREFIX24},gateway=@{SUBNET_GW_IP}[0]
    ${elements} =    BuiltIn.Create List    "destination":"@{NON_NEUTRON_DESTINATION}[0]${PREFIX24}","nexthop":"@{SUBNET_GW_IP}[0]"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements Not At URI    ${SUBNETWORK_URL}    ${elements}
    Verify No Hostroutes In Subnet    @{SUBNETS}[0]    destination='@{NON_NEUTRON_DESTINATION}[0]${PREFIX24}',\\sgateway='@{SUBNET_GW_IP}[0]'

Verify creation of host route via openstack subnet set option with VM port as next hop IP
    [Documentation]    Creating host route using subnet update option and setting nexthop to gateway vm ip and verifying in controller and openstack.
    OpenStackOperations.Update SubNet    @{SUBNETS}[0]    --host-route destination=@{SUBNET_CIDR}[2]${PREFIX24},gateway=@{GATEWAY_VM_IPS}[0]
    ${elements} =    BuiltIn.Create List    "destination":"@{SUBNET_CIDR}[2]${PREFIX24}","nexthop":"@{GATEWAY_VM_IPS}[0]"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}
    Verify Hostroutes In Subnet    @{SUBNETS}[0]    destination='@{SUBNET_CIDR}[2]${PREFIX24}',\\sgateway='@{GATEWAY_VM_IPS}[0]'

Verify creation of host route via openstack subnet set option with VM port as next hop IP with change in destination prefix
    [Documentation]    Creating host route using subnet update option and setting nexthop ip to gateway vm ip and changing destination prefix.
    ...    Verifying in controller and openstack.
    OpenStackOperations.Update SubNet    @{SUBNETS}[0]    --host-route destination=@{SUBNET_CIDR}[1]${PREFIX24},gateway=@{GATEWAY_VM_IPS}[0]
    ${elements} =    BuiltIn.Create List    "destination":"@{SUBNET_CIDR}[1]${PREFIX24}","nexthop":"@{GATEWAY_VM_IPS}[0]"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}
    Verify Hostroutes In Subnet    @{SUBNETS}[0]    destination='@{SUBNET_CIDR}[1]${PREFIX24}',\\sgateway='@{GATEWAY_VM_IPS}[0]'

Verify creation of host route via openstack subnet set option with change in next hop IP
    [Documentation]    Creating host route using subnet update option and setting nexthop ip to new gateway vm ip without changing the
    ...    destination prefix. Verifying in controller and openstack.
    OpenStackOperations.Update SubNet    @{SUBNETS}[0]    --host-route destination=@{SUBNET_CIDR}[1]${PREFIX24},gateway=@{GATEWAY_VM_IPS}[1]
    ${elements} =    BuiltIn.Create List    "destination":"@{SUBNET_CIDR}[1]${PREFIX24}","nexthop":"@{GATEWAY_VM_IPS}[1]"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}
    Verify Hostroutes In Subnet    @{SUBNETS}[0]    destination='@{SUBNET_CIDR}[1]${PREFIX24}',\\sgateway='@{GATEWAY_VM_IPS}[1]'

*** Keywords ***
Suite Setup
    [Documentation]    Creates initial setup.
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    FOR    ${network}    IN    @{NETWORKS}
        OpenStackOperations.Create Network    ${network}
    END
    FOR    ${i}    IN RANGE    1    4
        OpenStackOperations.Create SubNet    @{NETWORKS}[${i}]    @{SUBNETS}[${i}]    @{SUBNET_CIDR}[${i}]${PREFIX24}
        OpenStackOperations.Create Port    @{NETWORKS}[${i}]    @{PORTS}[${i}]    sg=${SECURITY_GROUP}    allowed_address_pairs=${ALLOWED_ADDRESS_PAIR}
        OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[${i}]    @{NETWORK_${i+1}_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
        OpenStackOperations.Create Port    @{NETWORKS}[${i}]    @{PORTS}[${i+3}]    sg=${SECURITY_GROUP}    allowed_address_pairs=${ALLOWED_ADDRESS_PAIR}
        OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[${i+3}]    @{NETWORK_${i+1}_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
        OpenStackOperations.Create Port    @{NETWORKS}[${i}]    @{GATEWAY_PORTS}[${i}]    sg=${SECURITY_GROUP}    allowed_address_pairs=${ALLOWED_ADDRESS_PAIR}
        OpenStackOperations.Create Port    @{NETWORKS}[${i}]    @{GATEWAY_PORTS}[${i+3}]    sg=${SECURITY_GROUP}    allowed_address_pairs=${ALLOWED_ADDRESS_PAIR}
    END
    @{NETWORK_2_VM_IPS}    ${NETWORK_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NETWORK_2_VMS}
    BuiltIn.Set Suite Variable    @{NETWORK_2_VM_IPS}
    @{NETWORK_3_VM_IPS}    ${NETWORK_3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NETWORK_3_VMS}
    BuiltIn.Set Suite Variable    @{NETWORK_3_VM_IPS}
    @{NETWORK_4_VM_IPS}    ${NETWORK_4_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NETWORK_4_VMS}
    BuiltIn.Set Suite Variable    @{NETWORK_4_VM_IPS}
    OpenStackOperations.Show Debugs    @{NETWORK_2_VMS}    @{NETWORK_3_VMS}    @(NETWORK_4_VMS)
    OpenStackOperations.Get Suite Debugs

Verify Hostroutes In Subnet
    [Arguments]    ${subnet_name}    @{elements}
    [Documentation]    Show subnet with openstack request and verifies given hostroute in subnet.
    ${output} =    OpenStackOperations.Show SubNet    ${subnet_name}
    FOR    ${element}    IN    @{elements}
        BuiltIn.Should Match Regexp    ${output}    ${element}
    END

Verify No Hostroutes In Subnet
    [Arguments]    ${subnet_name}    @{elements}
    [Documentation]    Show subnet with openstack request and verifies no given hostroute in subnet.
    ${output} =    OpenStackOperations.Show SubNet    ${subnet_name}
    FOR    ${element}    IN    @{elements}
        BuiltIn.Should Not Match Regexp    ${output}    ${element}
    END
