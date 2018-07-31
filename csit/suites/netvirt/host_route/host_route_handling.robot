*** Settings ***
Documentation     Test suite for VM based Host Route Handling
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
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
@{NON_NEUTRON_DESTINATION}    5.5.5.0    6.6.6.0
${NON_NEUTRON_NEXTHOP}    10.10.10.250

*** Test Cases ***
Verify creation of host route via openstack subnet create option
    [Documentation]    Creating subnet host route via openstack cli and verifying in controller and openstack.
    OpenStackOperations.Create SubNet    ${NETWORKS[${0}]}    ${SUBNETS[${0}]}    ${SUBNET_CIDR[${0}]}${PREFIX24}    --host-route destination=${SUBNET_CIDR[${2}]}${PREFIX24},gateway=${NON_NEUTRON_NEXTHOP}
    ${SUBNET_GW_IP}    BuiltIn.Create List
    : FOR    ${subnet}    IN    @{SUBNETS}
    \    ${ip} =    OpenStackOperations.Get Subnet Gateway Ip    ${subnet}
    \    Collections.Append To List    ${SUBNET_GW_IP}    ${ip}
    BuiltIn.Set Suite Variable    ${SUBNET_GW_IP}
    ${elements} =    BuiltIn.Create List    "destination":"${SUBNET_CIDR[${2}]}${PREFIX24}","nexthop":"${NON_NEUTRON_NEXTHOP}"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}
    Verify Hostroutes In Subnet    ${SUBNETS[${0}]}    destination='${SUBNET_CIDR[${2}]}${PREFIX24}',\\sgateway='${NON_NEUTRON_NEXTHOP}'

Verify creation of host route via openstack subnet update option
    [Documentation]    Creating host route using subnet update option and setting nexthop ip to subnet gateway ip. Verifying in controller and openstack.
    OpenStackOperations.Update SubNet    ${SUBNETS[${0}]}    --host-route destination=${NON_NEUTRON_DESTINATION[${0}]}${PREFIX24},gateway=${SUBNET_GW_IP[${0}]}
    ${elements} =    BuiltIn.Create List    "destination":"${NON_NEUTRON_DESTINATION[${0}]}${PREFIX24}","nexthop":"${SUBNET_GW_IP[${0}]}"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}
    Verify Hostroutes In Subnet    ${SUBNETS[${0}]}    destination='${NON_NEUTRON_DESTINATION[${0}]}${PREFIX24}',\\sgateway='${SUBNET_GW_IP[${0}]}'

Verify removal of host route
    [Documentation]    Removing subnet host routes via cli and verifying in controller and openstack
    OpenStackOperations.Unset SubNet    ${SUBNETS[${0}]}    --host-route destination=${NON_NEUTRON_DESTINATION[${0}]}${PREFIX24},gateway=${SUBNET_GW_IP[${0}]}
    ${elements} =    BuiltIn.Create List    "destination":"${NON_NEUTRON_DESTINATION[${0}]}${PREFIX24}","nexthop":"${SUBNET_GW_IP[${0}]}"
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements Not At URI    ${SUBNETWORK_URL}    ${elements}
    Verify No Hostroutes In Subnet    ${SUBNETS[${0}]}    destination='${NON_NEUTRON_DESTINATION[${0}]}${PREFIX24}',\\sgateway='${SUBNET_GW_IP[${0}]}'

*** Keywords ***
Suite Setup
    [Documentation]    Creates initial setup
    VpnOperations.Basic Suite Setup
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    : FOR    ${i}    IN RANGE    1    4
    \    OpenStackOperations.Create SubNet    ${NETWORKS[${i}]}    ${SUBNETS[${i}]}    ${SUBNET_CIDR[${i}]}${PREFIX24}

Verify Hostroutes In Subnet
    [Arguments]    ${subnet_name}    @{elements}
    [Documentation]    Show subnet with openstack request and verifies given hostroute in subnet
    ${output} =    OpenStackOperations.Show SubNet    ${subnet_name}
    : FOR    ${element}    IN    @{elements}
    \    BuiltIn.Should Match Regexp    ${output}    ${element}

Verify No Hostroutes In Subnet
    [Arguments]    ${subnet_name}    @{elements}
    [Documentation]    Show subnet with openstack request and verifies no given hostroute in subnet
    ${output} =    OpenStackOperations.Show SubNet    ${subnet_name}
    : FOR    ${element}    IN    @{elements}
    \    BuiltIn.Should Not Match Regexp    ${output}    ${element}
