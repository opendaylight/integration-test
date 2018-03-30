*** Settings ***
Documentation     Test suite to verify IPV6 API, where the subnets,router,port,server and security group api are tested .
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        skip_if_${SECURITY_GROUP_MODE}    #Test Teardown    Clear Interfaces
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/OpenStackOperations_legacy.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../variables/netvirt/Variables.robot

*** Variables ***
@{SECURITY_GROUP}    sg1    sg2    sg-remote    sg_additional    sg_dhcp
@{NETWORKS_NAME}    NET1_IPV6    NET2_IPV6
@{SUBNETS_NAME}    SUBNET1_IPV6    SUBNET2_IPV6
@{IPV6_VM}        VM1_IPV6    VM2_IPV6
@{SUBNETS_RANGE}    2003:db8:cafe:e::/64    2007:db9:cafe:e::/64
${NET1_ADDR_POOL}    --allocation-pool start=2003:db8:cafe:e::2,end=2003:db8:cafe:e::10
${ROUTERS}        router1
${PORT}           port1
${NET1_ADDR_POOL_update}    --allocation-pool start=2003:db8:cafe:e::11,end=2003:db8:cafe:e:ffff:ffff:ffff:fffe
${gateway-ip}     2003:db8:cafe:e::2
${Gateway_ip_updated}    --gateway 2003:db8:cafe:e::1
${route-destination}    --host-route gateway=2003:db8:cafe:e::1,destination=2008:db9:cafe:e::/64
${fixed-ip}       --fixed-ip subnet=SUBNET2_IPV6,ip-address=2007:db9:cafe:e::8
${server_fixed_ip}    2007:db9:cafe:e::e
${v6-fixed-ip}    --fixed-ip subnet=SUBNET2_IPV6,ip-address=2007:db9:cafe:e:f816:3eff:fe61:a189
${allowed-ip}     --allowed-address ip-address=2007:db9:cafe:e::6
${route_dest_gateway}    --route destination=2007:db9:cafe:e::/64,gateway=2003:db8:cafe:e::2
@{allocation-pools}    "allocation-pools":[{"start":"2003:db8:cafe:e::2","end":"2003:db8:cafe:e::10"}]
@{update_allocation_pools}    "allocation-pools":[{"start":"2003:db8:cafe:e::11","end":"2003:db8:cafe:e:ffff:ffff:ffff:fffe"}]
${allocation_pools}    2003:db8:0:2::2-2003:db8:0:2:ffff:ffff:ffff:fffe
${updated_allocation_pools}    2003:db8:cafe:e::4-2003:db8:cafe:e::10
@{ip_version}     "ip-version":"neutron-constants:ip-version-v6"
@{address_mode_slaac}    "ipv6-address-mode":"neutron-constants:dhcpv6-slaac"
@{address_mode_dhcpv6_stateful}    "ipv6-address-mode":"neutron-constants:dhcpv6-stateful"
@{address_mode_dhcpv6_stateless}    "ipv6-address-mode":"neutron-constants:dhcpv6-stateless"
@{ra_mode_dhcpv6_stateful}    "ipv6-ra-mode":"neutron-constants:dhcpv6-stateful"
@{ra_mode_slaac}    "ipv6-ra-mode":"neutron-constants:dhcpv6-slaac"
@{ra_mode_dhcpv6_stateless}    "ipv6-ra-mode":"neutron-constants:dhcpv6-stateless"
@{gatewayIP}      "gateway-ip":"2003:db8:cafe:e::2"
@{updated_gatewayIP}    "gateway-ip":"2003:db8:cafe:e::1"
@{RouteDestination}    "host-routes":[{"destination":"2008:db9:cafe:e::/64","nexthop":"2003:db8:cafe:e::1"}]
@{host-route}     "routes":[{"nexthop":"2003:db8:cafe:e::2","destination":"2007:db9:cafe:e::/64"}]
@{fixed_ip}       2007:db9:cafe:e::8
@{check_server_fixed_ip}    2007:db9:cafe:e::e
@{v6_fixed_ip}    2003:db8:cafe:e:f816:3eff:fe61:a189
@{v6_port_ip}     2007:db9:cafe:e:f816:3eff:fea1:e170
${gateway_ip}     2003:db8:cafe:e::2
${gateway_ip_update}    2003:db8:cafe:e::4
@{allowed_ip}     2007:db9:cafe:e::6
@{security_group_name}    "name":"sg1"
@{security_group_name1}    "name":"sg2"
@{SUBNETS_IP_VERSION_6_CHECK}    "ip-version":"neutron-constants:ip-version-v6"
@{SUBNETS_NAME_RA_MODE_CHECK}    "ipv6-ra-mode":"neutron-constants:dhcpv6-slaac"

*** Test Cases ***
Create Zone
    [Documentation]    Creating Availabilityzone create for test suite
    [Tags]    Rerun
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

SubNet create with IP version 6
    [Documentation]    Create subnet with IP version 6 and check in the neutron data store.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--ip-version=6
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    | 6
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${ip_version}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 ip-address-mode in slaac
    [Documentation]    Create subnet with IPv6 in ipv6-address-mode as slaac and check in the neutron data store.
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    slaac
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${address_mode_slaac}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 ip-address-mode in dhcpv6-stateful
    [Documentation]    Subnet create with IPv6 in ipv6-address-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    dhcpv6-stateful
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${address_mode_dhcpv6_stateful}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 ip-address-mode in dhcpv6-stateless
    [Documentation]    Subnet create with IPv6 in ipv6-address-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    dhcpv6-stateless
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${address_mode_dhcpv6_stateless}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 ip-ra-mode in slaac
    [Documentation]    Subnet create with IPv6 in ipv6-ra-mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    slaac
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${ra_mode_slaac}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 ip-ra-mode in dhcpv6-stateful
    [Documentation]    Subnet create with IPv6 in ipv6-ra-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    dhcpv6-stateful
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${ra_mode_dhcpv6_stateful}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 ip-ra-mode in dhcpv6-stateless
    [Documentation]    Subnet create with IPv6 in ipv6-ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    dhcpv6-stateless
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${ra_mode_dhcpv6_stateless}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 in slaac
    [Documentation]    Subnet create with IPv6 in ipv6-address and ipv6-ra mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    slaac
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${ra_mode_slaac}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${address_mode_slaac}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 in dhcpv6-stateless
    [Documentation]    Subnet create with IPv6 in ipv6-address and ipv6-ra mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless --ipv6-ra-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    dhcpv6-stateless
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${ra_mode_dhcpv6_stateless}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${address_mode_dhcpv6_stateless}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with IPv6 in dhcpv6-stateful
    [Documentation]    Subnet create with IPv6 in ipv6-address and ipv6-ra mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful --ipv6-ra-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    dhcpv6-stateful
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${ra_mode_dhcpv6_stateful}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${address_mode_dhcpv6_stateful}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with allocation-pool in slaac
    [Documentation]    Subnet create with allocation-pool for ipv6 address-mode and ra-mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::2-2003:db8:cafe:e::10
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${allocation-pools}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with allocation-pool in dhcpv6-stateful
    [Documentation]    Subnet create with allocation-pool for ipv6 address-mode and ra-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful --ipv6-ra-mode=dhcpv6-stateful ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::2-2003:db8:cafe:e::10
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${allocation-pools}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with allocation-pool in dhcpv6-stateless
    [Documentation]    Subnet create with allocation-pool for ipv6 address-mode and ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless --ipv6-ra-mode=dhcpv6-stateless ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::2-2003:db8:cafe:e::10
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${allocation-pools}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with allocation-pool in slaac
    [Documentation]    Subnet update with allocation-pool for ipv6 address-mode and ra-mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    SubNet Set    @{SUBNETS_NAME}[0]    additional_args=${NET1_ADDR_POOL_update}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::11-2003:db8:cafe:e:ffff:ffff:ffff:fffe
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${update_allocation_pools}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with allocation-pool in dhcpv6_stateful
    [Documentation]    Subnet update with allocation-pool for ipv6 address-mode and ra-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful --ipv6-ra-mode=dhcpv6-stateful ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    SubNet Set    @{SUBNETS_NAME}[0]    additional_args=${NET1_ADDR_POOL_update}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::11-2003:db8:cafe:e:ffff:ffff:ffff:fffe
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${update_allocation_pools}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with allocation-pool in dhcpv6_stateless
    [Documentation]    Subnet update with allocation-pool for ipv6 address-mode and ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless --ipv6-ra-mode=dhcpv6-stateless ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    SubNet Set    @{SUBNETS_NAME}[0]    additional_args=${NET1_ADDR_POOL_update}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::11-2003:db8:cafe:e:ffff:ffff:ffff:fffe
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${update_allocation_pools}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with gateway-ip in slaac
    [Documentation]    Subnet create with gateway-ip for ipv6 address-mode and ra-mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac --gateway=${gateway-ip}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::2
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${gatewayIP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with gateway-ip in dhcpv6-stateful
    [Documentation]    Subnet create with gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful --ipv6-ra-mode=dhcpv6-stateful --gateway=${gateway-ip}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::2
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${gatewayIP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with gateway-ip in dhcpv6-stateless
    [Documentation]    Subnet create with gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless --ipv6-ra-mode=dhcpv6-stateless --gateway=${gateway-ip}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::2
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${gatewayIP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with gateway-ip in slaac
    [Documentation]    Subnet update with gateway-ip for ipv6 address-mode and ra-mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    SubNet Set    @{SUBNETS_NAME}[0]    additional_args=${Gateway_ip_updated}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${updated_gatewayIP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with gateway-ip in dcpv6-stateful
    [Documentation]    Subnet update with gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful --ipv6-ra-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=${Gateway_ip_updated}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${updated_gatewayIP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with gateway-ip in dcpv6-stateless
    [Documentation]    Subnet update with gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless --ipv6-ra-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=${Gateway_ip_updated}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${updated_gatewayIP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with route-destination and gateway-ip in slaac
    [Documentation]    Subnet create with route-destination,gateway-ip for ipv6 address-mode and ra-mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${route-destination}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::/64
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${RouteDestination}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with route-destination and gateway-ip in dhcpv6-stateful
    [Documentation]    Subnet create with route-destination,gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful --ipv6-ra-mode=dhcpv6-stateful ${route-destination}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::/64
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${RouteDestination}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Subnet creation with route-destination and gateway-ip in dhcpv6-stateless
    [Documentation]    Subnet create with route-destination,gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless --ipv6-ra-mode=dhcpv6-stateless ${route-destination}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::/64
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${RouteDestination}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with route-destination and gateway-ip in slaac
    [Documentation]    Subnet update with route-destination,gateway-ip for ipv6 address-mode and ra-mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::/64
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${RouteDestination}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with route-destination and gateway-ip in dhcpv6-stateful
    [Documentation]    Subnet update with route-destination,gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful --ipv6-ra-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::/64
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${RouteDestination}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet with route-destination and gateway-ip in dhcpv6-statless
    [Documentation]    Subnet update with route-destination,gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless --ipv6-ra-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should contain    ${output}    2003:db8:cafe:e::/64
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${RouteDestination}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Unset Subnet with route-destination and gateway-ip in slaac
    [Documentation]    Unset Subnet with route-destination,gateway-ip for ipv6 address-mode and ra-mode as slaac
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    ${output}=    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${RouteDestination}
    Unset SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    ${output1}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Not contain    ${output1}    destination=2008:db9:cafe:e::/64,gateway=2003:db8:cafe:e::1
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Unset Subnet with route-destination and gateway-ip in dhcpv6-stateful
    [Documentation]    Unset Subnet with route-destination,gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateful
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful --ipv6-ra-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    Unset SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Not contain    ${output}    destination=2008:db9:cafe:e::/64,gateway=2003:db8:cafe:e::1
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Unset Subnet with route-destination and gateway-ip in dhcpv6-stateless
    [Documentation]    Unset Subnet with route-destination,gateway-ip for ipv6 address-mode and ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless --ipv6-ra-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    Unset SubNet    @{SUBNETS_NAME}[0]    additional_args=${route-destination}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Not contain    ${output}    destination=2008:db9:cafe:e::/64,gateway=2003:db8:cafe:e::1
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Create Network Components
    [Documentation]    Create single network and subnet with router
    Create Network    @{NETWORKS_NAME}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    ${net1_additional_args}

Router set with route-destination and gateway-ip in slaac
    [Documentation]    Router set with route-destination,gateway-ip for ipv6 address-mode and ra-mode as slaac
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    ${output}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Update Router    ${ROUTERS}    ${route_dest_gateway}
    ${output}=    OpenStack CLI    cmd=openstack router show ${ROUTERS}
    Should contain    ${output}    destination='2007:db9:cafe:e::/64', gateway='2003:db8:cafe:e::2'
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers    ${host-route}
    Router Unset    ${ROUTERS}    cmd=${route_dest_gateway}
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}
    ${output1}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Should not be Equal    ${output}    ${output1}

Router unset with route-destination and gateway-ip in slaac
    [Documentation]    Router unset with route-destination,gateway-ip for ipv6 address-mode and ra-mode as slaac
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Update Router    ${ROUTERS}    ${route_dest_gateway}
    ${output}=    OpenStack CLI    cmd=openstack router show ${ROUTERS}
    Router Unset    ${ROUTERS}    cmd=${route_dest_gateway}
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}

Router remove
    [Documentation]    Router remove subnet interface
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show ${ROUTERS}
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}

Router delete
    [Documentation]    Router delete subnet interface
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show ${ROUTERS}
    SSHLibrary.Open Connection    ${OS_COMPUTE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}
    SSHLibrary.Open Connection    ${OS_COMPUTE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout1}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should not be Equal    ${stdout}    ${stdout1}

Port create with allowed-ip address
    [Documentation]    Port creation with allowed-ip address
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=${allowed-ip}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports    ${allowed_ip}
    Delete Port    ${PORT}

Port create with fixed-ip address
    [Documentation]    Port creation with fixed-ip address
    [Tags]    re-run
    Create Network    @{NETWORKS_NAME}[1]
    ${net1_additional_args}=    Catenate    --ip-version=6 --no-dhcp
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]    ${net1_additional_args}
    Create Port    @{NETWORKS_NAME}[1]    ${PORT}    additional_args=${fixed-ip}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports    ${fixed_ip}
    Delete Port    ${PORT}

Port set with fixed-ip address
    [Documentation]    Port update with fixed-ip address
    Create Port    @{NETWORKS_NAME}[1]    ${PORT}
    Update Port    ${PORT}    additional_args=${fixed-ip}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports    ${fixed_ip}

Port unset with fixed-ip address
    [Documentation]    Port unset with fixed-ip address
    ${output}=    Show port    ${PORT}
    Unset Port    ${PORT}    additional_args=${fixed-ip}
    ${output1}=    Show port    ${PORT}
    Should not be Equal    ${output}    ${output1}
    Delete Port    ${PORT}

Port delete
    [Documentation]    Port deletion with allowed-ip address
    Create Port    @{NETWORKS_NAME}[1]    ${PORT}    additional_args=${allowed-ip}
    Delete Port    ${PORT}

Server create
    [Documentation]    Server create with v6-option
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${NETWORKS}=    Create List    @{NETWORKS_NAME}[1]
    ${SUBNETS}=    Create List    @{SUBNETS_RANGE}[1]
    ${VM1}=    Create List    @{IPV6_VM}[1]
    Create Vm Instances V4Fixed-IP    @{NETWORKS_NAME}[1]    ${VM1}    ,v6-fixed-ip=2007:db9:cafe:e:f816:3eff:fea1:e170    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports    ${v6_port_ip}
    Delete Vm Instance    @{IPV6_VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS}
    [Teardown]    Run Keywords    Clear Interfaces

Server add port
    [Documentation]    Server add port
    ${output}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Create Port    @{NETWORKS_NAME}[1]    ${PORT}    additional_args=${fixed-ip}
    ${VM1}=    Create List    @{IPV6_VM}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Server Add Port    @{IPV6_VM}[1]    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports    ${fixed_ip}
    ${output1}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Should not be Equal    ${output}    ${output1}
    Delete Vm Instance    @{IPV6_VM}[1]
    Delete Port    ${PORT}
    [Teardown]    Run Keywords    Clear Interfaces

Server remove port
    [Documentation]    Server remove port
    ${output}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Create Port    @{NETWORKS_NAME}[1]    ${PORT}    additional_args=${fixed-ip}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instance With Port    port1    ${IPV6_VM}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    ${output1}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Should not be Equal    ${output}    ${output1}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports    ${fixed_ip}
    Server Remove Port    @{IPV6_VM}[1]    ${PORT}
    Delete Vm Instance    @{IPV6_VM}[1]
    [Teardown]    Run Keywords    Clear Interfaces

Server add fixed-ip
    [Documentation]    Server add fixed-ip
    ${output}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    ${VM1}=    Create List    @{IPV6_VM}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    Server Add Fixed ip    ${server_fixed_ip}    @{IPV6_VM}[1]    @{NETWORKS_NAME}[1]
    ${output1}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Should not be Equal    ${output}    ${output1}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports    ${check_server_fixed_ip}
    Delete Vm Instance    @{IPV6_VM}[1]
    [Teardown]    Run Keywords    Clear Interfaces

Server remove fixed-ip
    [Documentation]    Server remove fixed-ip
    ${VM1}=    Create List    @{IPV6_VM}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${IPV6_VM}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    Server Add Fixed ip    ${server_fixed_ip}    @{IPV6_VM}[1]    @{NETWORKS_NAME}[1]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports    ${check_server_fixed_ip}
    Server Remove Fixed ip    ${server_fixed_ip}    @{IPV6_VM}[1]    @{NETWORKS_NAME}[1]
    Delete Vm Instance    @{IPV6_VM}[0]
    [Teardown]    Run Keywords    Clear Interfaces

Server reboot
    [Documentation]    Server reboot
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${VM1}=    Create List    @{IPV6_VM}[1]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    Reboot Nova VM    @{IPV6_VM}[1]
    ${output}=    Server Show    @{IPV6_VM}[1]
    Should contain    ${output}    @{IPV6_VM}[1]
    Delete Vm Instance    @{IPV6_VM}[1]
    [Teardown]    Run Keywords    Clear Interfaces

Server delete
    [Documentation]    Deleting the created server
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${VM1}=    Create List    @{IPV6_VM}[1]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]    additional_args=--availability-zone ${zone2}
    SSHLibrary.Open Connection    ${OS_COMPUTE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Delete Vm Instance    @{IPV6_VM}[1]
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout1}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should not be Equal    ${stdout}    ${stdout1}
    [Teardown]    Run Keywords    Clear Interfaces

Security rule create with ethertype
    [Documentation]    Security rule creation with ethertype as IPv6
    ${output}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=1    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=1    ethertype=IPv6
    ${VM1}=    Create List    @{IPV6_VM}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    sg=@{SECURITY_GROUP}[0]    image=cirros    flavor=cirros
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${output1}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-groups    ${security_group_name}
    Should not be Equal    ${output}    ${output1}
    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete Vm Instance    @{IPV6_VM}[0]
    [Teardown]    Run Keywords    Clear Interfaces

Security rule create with remote-ip
    [Documentation]    Security rule creation with remote-ip for IPv6
    ${output}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=1    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=1    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=1    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=1    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    ${VM1}=    Create List    @{IPV6_VM}[0]
    ${VM2}=    Create List    @{IPV6_VM}[1]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    sg=@{SECURITY_GROUP}[0]    image=cirros    flavor=cirros
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM2}    sg=@{SECURITY_GROUP}[1]    image=cirros    flavor=cirros
    ${output1}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Should not be Equal    ${output}    ${output1}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-groups    ${security_group_name}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-groups    ${security_group_name1}
    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{IPV6_VM}[1]
    [Teardown]    Run Keywords    Clear Interfaces

Security rule create with remote-sg
    [Documentation]    Security rule creation with remote-sg for IPv6
    ${output}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[0]
    ${VM1}=    Create List    @{IPV6_VM}[0]
    ${VM2}=    Create List    @{IPV6_VM}[1]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    sg=@{SECURITY_GROUP}[0]    image=cirros    flavor=cirros
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM2}    sg=@{SECURITY_GROUP}[1]    image=cirros    flavor=cirros
    ${output1}=    Get DumpFlows    ${OS_CONTROL_NODE_1_IP}
    Should not be Equal    ${output}    ${output1}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-groups    ${security_group_name}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-groups    ${security_group_name1}
    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{IPV6_VM}[1]
    [Teardown]    Run Keywords    Clear Interfaces

Security rule deletion
    [Documentation]    Security rule delete
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=1    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=1    ethertype=IPv6
    ${VM1}=    Create List    @{IPV6_VM}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    sg=@{SECURITY_GROUP}[0]    image=cirros    flavor=cirros    additional_args=--availability-zone ${zone2}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout1}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should not be Equal    ${stdout}    ${stdout1}
    Delete Vm Instance    @{IPV6_VM}[0]
    [Teardown]    Run Keywords    Clear Interfaces

Delete Network Components
    [Documentation]    Delete Subnet and Networks of first Network
    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    [Tags]    re-run
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2

*** keywords ***
Clear Interfaces
    [Documentation]    Clear Networks
    ${rc}    ${router_output}=    Run And Return Rc And Output    openstack router list -cID -fvalue
    Log    ${router_output}
    @{routers}=    Split String    ${router_output}    \n
    ${rc}    ${subnet_output}=    Run And Return Rc And Output    openstack subnet list -cID -fvalue
    Log    ${subnet_output}
    @{subnets}=    Split String    ${subnet_output}    \n
    : FOR    ${router}    IN    @{routers}
    \    Run Keyword And Ignore Error    Remove Interfaces    ${router}    ${subnets}
    : FOR    ${router}    IN    @{routers}
    \    Run Keyword And Ignore Error    Delete Router    ${router}
    ${rc}    ${server_output}=    Run And Return Rc And Output    openstack server list -cID -fvalue
    Log    ${server_output}
    @{servers}=    Split String    ${server_output}    \n
    : FOR    ${server}    IN    @{servers}
    \    Run    openstack server delete ${server}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    : FOR    ${sg}    IN    @{sgs}
    \    Run    openstack security group delete ${sg}
