*** Settings ***
Documentation     Test suite to verify openstack CLI basic functionalities (create, set and unset).
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../libraries/CLI_OpenStackOperations.robot
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/DataModels.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
${fixed_ip}       40.0.0.20
${SECURITY_GROUP_1}    SG1
${PORT}           port1
${POOL_NAME}      subnet_pool
${PREF_IP}        30.0.0.0/24
${PREF_LEN}       32
${POOL_DESC}      subnetpool
${SECURITY_GROUP}    sg-connectivity
${SECURITY_GROUP2}    sg-connectivity2
@{NET_1_VM_GRP_NAME}    NET1-VM
@{NET_1_VM_INSTANCES_MAX}    NET1-VM-1    NET1-VM-2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    2001:db8:cafe:e::/64    100.64.2.0/24    192.168.90.0/24
${user}           cirros
${password}       cubswin:)
${hostname}       compute2.example.local
@{Fixed_IP_Check}    "ip-address":"40.0.0.14"
@{State_False}    "admin-state-up":false
@{external_pnf}    10.10.10.1
${pnf_password}    automation
${pnf_user}       root
${pnf_prompt}     \    #
@{PROVIDER}       flat1
${DNS_NAME_SERVER}    8.8.8.8
@{NetworkShared}    "shared":true
${ALLOCATIONPOOL_START}    30.0.0.20
${ALLOCATIONPOOL_END}    30.0.0.100
${ALLOCATIONPOOL_START_1}    192.168.90.20
${ALLOCATIONPOOL_END_1}    192.168.90.40
${ALLOCATIONPOOL_CHECK}    30.0.0.20-30.0.0.100
${UP_ALLOCATIONPOOL_START}    30.0.0.101
${UP_ALLOCATIONPOOL_END}    30.0.0.200
${UP_ALLOCATIONPOOL_CHECK}    30.0.0.101-30.0.0.200
${ROUTE_GATEWAY}    192.168.90.2
@{Network_update}    network_update
@{Network_phy_net}    "neutron-provider-ext:physical-network":"vlantest"
@{Network_seg}    "neutron-provider-ext:segmentation-id":"28"
@{Network_external}    "neutron-L3-ext:external":true
@{Network_type}    "neutron-networks:network-type-vlan"
@{SUBNETS_UPDATE}    updatedSubnet
@{SUBNETS_NAME_CHECK}    l2_subnet_1
@{SUBNETS_ALLOCATION_POOL_CHECK}    "allocation-pools":[{"start":"30.0.0.20","end":"30.0.0.100"}]
@{SET_SUBNETS_ALLOCATION_POOL_CHECK}    "allocation-pools":[{"start":"30.0.0.101","end":"30.0.0.200"}]
@{SUBNETS_NO_DHCP_CHECK}    enable-dhcp":false
@{SUBNETS_DNS_NAMESERVERS_CHECK}    "dns-nameservers":["8.8.8.8"]
@{SUBNETS_IP_VERSION_6_CHECK}    "ip-version":"neutron-constants:ip-version-v6"
@{SUBNETS_IPV6_RA_MODE_CHECK}    "ipv6-ra-mode":"neutron-constants:dhcpv6-slaac"
@{SUBNETS_IPV6_ADDRESS_MODE_CHECK}    "ipv6-address-mode":"neutron-constants:dhcpv6-slaac"
@{SUBNETS_GATEWAY}    "gateway-ip":"192.168.90.2"
@{SUBNETS_HOST_ROUTE}    "host-routes":[{"destination":"30.0.0.0/24","nexthop":"192.168.90.2"}]
@{ICMP_TYPE}      "port-range-min":8
@{ICMP_CODE}      "port-range-min":0
@{v4-fixed}       30.0.0.20
@{v6-fixed}       2001:db8:cafe:e:f816:3eff:fe71:3bfe
@{VM_Check}       NET1-VM

*** Test Cases ***
Create Zone
    [Documentation]    Create Availabilityzone create for test suite to create instances in specific zones.
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Network create with attribute disable
    [Documentation]    Network create with attribute disable and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--disable
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    DOWN
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${State_False}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network create with attribute share
    [Documentation]    Network create with attribute share and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--share
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    True
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${NetworkShared}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network create with attribute provider-physical-network
    [Documentation]    Network create with attribute provider-physical-network and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    --external --default --provider-network-type flat --provider-physical-network vlantest
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    vlantest
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_phy_net}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network create with attribute provider-segment
    [Documentation]    Network create with attribute provider-segment and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type vlan --provider-physical-network vlantest --provider-segment 28
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    28
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_seg}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network create with attribute external
    [Documentation]    Network create with attribute external and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type vlan --provider-physical-network vlantest --provider-segment 28
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    External
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_external}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network create with attribute enable-port-security
    [Documentation]    Network create with attribute enable-port-security and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--enable-port-security
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    True
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_seg}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network set with attribute provider-network-type
    [Documentation]    Network set with attribute provider-network-type and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type vlan --provider-physical-network vlantest --provider-segment 28
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    vlan
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_type}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network set with attribute provider-physical-network
    [Documentation]    Network set with attribute provider-physical-network and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type vlan --provider-physical-network vlantest --provider-segment 28
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    vlantest
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_phy_net}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network set with attribute provider-segment
    [Documentation]    Network set with attribute provider-segment and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type vlan --provider-physical-network vlantest --provider-segment 28
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    28
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_seg}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Network set with attribute name
    [Documentation]    Network set with attribute name and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--name network_update
    ${output}=    Show Network    network_update
    Should Contain    ${output}    network_update
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_update
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_update}
    Delete Network    network_update
    [Teardown]    Run Keywords    Clear L2_Network

Subnet create with attribute subnet-pool
    [Documentation]    Subnet create with attribute subnet-pool and verify in config datastore.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet pool create --share --pool-prefix 203.0.113.0/24 --default-prefix-length 26 subnetpool4
    Log    ${output}
    Should Not Be True    ${rc}
    Create Network    @{NETWORKS_NAME}[0]
    ${rc}    ${SubnetOutput}=    Run And Return Rc And Output    openstack subnet create --ip-version 4 --subnet-pool subnetpool4 --network @{NETWORKS_NAME}[0] @{SUBNETS_NAME}[0]
    Log    ${SubnetOutput}
    Should Not Be True    ${rc}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    @{SUBNETS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_NAME_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    ${rc}    ${Output}=    Run And Return Rc And Output    openstack subnet pool delete subnetpool4
    Log    ${Output}
    Should Not Be True    ${rc}
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with allocation-pool
    [Documentation]    Subnet create with allocation-pool and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--allocation-pool start=${ALLOCATIONPOOL_START},end=${ALLOCATIONPOOL_END}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    ${ALLOCATIONPOOL_CHECK}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_ALLOCATION_POOL_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with no-dhcp
    [Documentation]    Subnet create with no-dhcp and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--no-dhcp
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    False
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_NO_DHCP_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with dns-nameserver
    [Documentation]    Subnet create with dns-nameserver and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--dns-nameserver ${DNS_NAME_SERVER}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    ${DNS_NAME_SERVER}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_DNS_NAMESERVERS_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with ip-version
    [Documentation]    Subnet create with ip-version and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    | 6
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_IP_VERSION_6_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with ipv6-ra-mode
    [Documentation]    Subnet create with ipv6-ra-mode and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    slaac
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_IPV6_RA_MODE_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with ipv6-address-mode
    [Documentation]    Subnet create with ipv6-address-mode and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    slaac
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_IPV6_ADDRESS_MODE_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with host-route destination and gateway
    [Documentation]    Subnet create with host-route destination and gateway and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[3]    additional_args=--host-route destination=@{SUBNETS_RANGE}[0],gateway=${ROUTE_GATEWAY}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    destination='@{SUBNETS_RANGE}[0]', gateway='${ROUTE_GATEWAY}'
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_HOST_ROUTE}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with gateway
    [Documentation]    Subnet create with gateway and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[4]    additional_args=--gateway ${ROUTE_GATEWAY} --allocation-pool start=${ALLOCATION_POOL_START_1},end=${ALLOCATION_POOL_END_1}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    ${ROUTE_GATEWAY}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_GATEWAY}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet create with use-default-subnet-pool
    [Documentation]    Subnet create with use-default-subnet-pool.
    Create SubNet Pool    ${POOL_NAME}    ${PREF_LEN}    ${POOL_DESC}    ${PREF_IP}    additional_args=--default
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--use-default-subnet-pool
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    #Should Contain    ${output}    ${ROUTE_GATEWAY}
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_GATEWAY}
    Delete Network    @{NETWORKS_NAME}[0]
    Delete SubNet Pool    ${POOL_NAME}
    [Teardown]    Run Keywords    Clear L2_Network

SubNet set with allocation-pool
    [Documentation]    Subnet set with allocation-pool and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--allocation-pool start=${ALLOCATIONPOOL_START},end=${ALLOCATIONPOOL_END}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--allocation-pool start=${UP_ALLOCATIONPOOL_START},end=${UP_ALLOCATIONPOOL_END}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    ${UP_ALLOCATIONPOOL_CHECK}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SET_SUBNETS_ALLOCATION_POOL_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet set with no-allocation-pool
    [Documentation]    Subnet set with no-allocation-pool and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--allocation-pool start=${ALLOCATIONPOOL_START},end=${ALLOCATIONPOOL_END}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--allocation-pool start=${UP_ALLOCATIONPOOL_START},end=${UP_ALLOCATIONPOOL_END} --no-allocation-pool
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    ${UP_ALLOCATIONPOOL_CHECK}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SET_SUBNETS_ALLOCATION_POOL_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet set with name
    [Documentation]    Subnet set with name and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--name updatedSubnet
    ${output}=    Show SubNet    updatedSubnet
    Should Contain    ${output}    updatedSubnet
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_UPDATE}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet set with gateway
    [Documentation]    Subnet set with gateway and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[4]    additional_args=--allocation-pool start=${ALLOCATIONPOOL_START_1},end=${ALLOCATIONPOOL_END_1}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--gateway ${ROUTE_GATEWAY}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    ${ROUTE_GATEWAY}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_GATEWAY}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet set with host-route destination and gateway
    [Documentation]    Subnet set with host-route destination and gateway and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[3]
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--host-route destination=@{SUBNETS_RANGE}[0],gateway=${ROUTE_GATEWAY}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    destination='@{SUBNETS_RANGE}[0]', gateway='${ROUTE_GATEWAY}'
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_HOST_ROUTE}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet set with no-host-route destination
    [Documentation]    Subnet set with no-host-route destination and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[3]    additional_args=--host-route destination=@{SUBNETS_RANGE}[1],gateway=${ROUTE_GATEWAY}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--no-host-route --host-route destination=@{SUBNETS_RANGE}[0],gateway=${ROUTE_GATEWAY}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    destination='@{SUBNETS_RANGE}[0]', gateway='${ROUTE_GATEWAY}'
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_HOST_ROUTE}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

SubNet unset with allocation-pool
    [Documentation]    Subnet unset with allocation-pool and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--allocation-pool start=${ALLOCATIONPOOL_START},end=${ALLOCATIONPOOL_END}
    SubNet Unset    @{SUBNETS_NAME}[0]    additional_args=--allocation-pool start=${ALLOCATIONPOOL_START},end=${ALLOCATIONPOOL_END}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Not Contain    ${output}    ${ALLOCATIONPOOL_CHECK}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_NAME_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]

SubNet unset with dns-nameserver
    [Documentation]    Subnet unset with dns-nameserver and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--dns-nameserver ${DNS_NAME_SERVER}
    SubNet Unset    @{SUBNETS_NAME}[0]    additional_args=--dns-nameserver ${DNS_NAME_SERVER}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Not Contain    ${output}    ${DNS_NAME_SERVER}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_NAME_CHECK}
    Delete Network    @{NETWORKS_NAME}[0]

SubNet unset with host-route destination and gateway
    [Documentation]    Subnet unset with host-route destination and gateway and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[3]    additional_args=--host-route destination=@{SUBNETS_RANGE}[0],gateway=${ROUTE_GATEWAY}
    Unset SubNet    @{SUBNETS_NAME}[0]    additional_args=--host-route destination=@{SUBNETS_RANGE}[0],gateway=${ROUTE_GATEWAY}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Not Contain    ${output}    destination='@{SUBNETS_RANGE}[0]', gateway='${ROUTE_GATEWAY}'
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_HOST_ROUTE}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Security Group create with icmp type
    [Documentation]    Security Group create with icmp type and verify in config datastore.
    Create ICMP type code protocol permit SecurityGroup    ${SECURITY_GROUP}
    ${output}=    Secuirty Group rule list    ${SECURITY_GROUP}
    Should Contain    ${output}    type=8
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-rules    ${ICMP_TYPE}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Clear L2_Network

Security Group create with icmp code
    [Documentation]    Security Group create with icmp code and verify in config datastore.
    Create ICMP type code protocol permit SecurityGroup    ${SECURITY_GROUP}
    ${output}=    Secuirty Group rule list    ${SECURITY_GROUP}
    Should Contain    ${output}    type=8:code=0
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-rules    ${ICMP_CODE}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Clear L2_Network

Security Group rule create with remote-group-id
    [Documentation]    Security Group rule create with remote-group-id.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Create protocol TCP remote-SG SecurityGroup CLI    ${SECURITY_GROUP}    ${SECURITY_GROUP2}
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack security group rule list ${SECURITY_GROUP} -c"Remote Security Group" -fvalue
    Log    ${OutputList}
    Should Not Be True    ${rc}
    #@{REMOTE_SG_CHECK}    "remote-group-id":"${OutputList}"
    ${output}=    Secuirty Group rule list    ${SECURITY_GROUP}
    Should Contain    ${output}    ${OutputList}
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-rules    ${REMOTE_SG_CHECK}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Clear L2_Network

Security Group update with name
    [Documentation]    Security Group update with name and verify security group updated.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Update    ${SECURITY_GROUP}    additional_args=--name ${SECURITY_GROUP2}
    ${output}=    Neutron Security Group Show    ${SECURITY_GROUP2}
    Should Contain    ${output}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Clear L2_Network

Server create with v4-fixed-ip
    [Documentation]    Server create with fixed-ip and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances V4Fixed-IP    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    ,v4-fixed-ip=@{v4-fixed}[0]    sg=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    30.0.0.20
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    Delete Vm Instance    NET1-VM
    [Teardown]    Run Keywords    Clear L2_Network

Server create with v6-fixed-ip
    [Documentation]    Server create and verify server created.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    #Create Vm Instances V4Fixed-IP    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    ,v6-fixed-ip=2001:db8:cafe:e:f816:3eff:fe71:3bfe    sg=${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=1    max=1
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    3s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    3s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v6-fixed}
    Delete Vm Instance    NET1-VM
    [Teardown]    Run Keywords    Clear L2_Network

Server create with port
    [Documentation]    Server create with port.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Port    @{NETWORKS_NAME}[0]    port1
    Create Vm Instance With Port    port1    NET1-VM    sg=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    Delete Vm Instance    NET1-VM
    Delete Port    port1
    [Teardown]    Run Keywords    Clear L2_Network

Server create with auto
    [Documentation]    Server create with auto and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances auto or none    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    auto    sg=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${NET1_VM_IPS}
    Delete Vm Instance    NET1-VM
    [Teardown]    Run Keywords    Clear L2_Network

Server create with none
    [Documentation]    Server create with none.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances auto or none    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    none    sg=${SECURITY_GROUP}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${VM_Check}
    Delete Vm Instance    NET1-VM
    [Teardown]    Run Keywords    Clear L2_Network

Server create with hint
    [Documentation]    Server create with hint.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${Output}=    Run And Return Rc And Output    openstack server group create --policy anti-affinity Anti -cid -fvalue
    Log    ${Output}
    Should Not Be True    ${rc}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    additional_args=--hint group=${Output}    sg=${SECURITY_GROUP}    min=1    max=1
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    Delete Vm Instance    NET1-VM
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Server create with config-drive
    [Documentation]    Server create with config-drive.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    additional_args=--config-drive=true    sg=${SECURITY_GROUP}    min=1    max=1
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    Delete Vm Instance    NET1-VM
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Server create with min
    [Documentation]    Server create with min.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    20s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    #Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show ${vm}
    \    Should Contain    ${output}    ${vm}
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Server create with availability-zone
    [Documentation]    Server create with availability-zone and verify created in specific zone.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    additional_args=--availability-zone=compute1    sg=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    compute1
    Delete Vm Instance    NET1-VM
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Server create with max
    [Documentation]    Server create with max and verify created servers.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    20s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    #Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show ${vm}
    \    Should Contain    ${output}    ${vm}
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Server create with wait
    [Documentation]    Server create with wait.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    additional_args=--wait    sg=${SECURITY_GROUP}    min=1    max=1
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    Delete Vm Instance    NET1-VM
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Server Migrate
    [Documentation]    Create server and migrate it to different host.
    Enable Live Migration In All Compute Nodes
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM1}    additional_args=--availability-zone ${zone1}
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[1]
    Server Migrate    @{NET_1_VM_INSTANCES}[1]    additional_args=--live ${hostname}
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[1]
    Should Contain    ${output}    MIGRATING
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    Disable Live Migration In All Compute Nodes
    [Teardown]    Run Keywords    Clear L2_Network

Server reboot wait
    [Documentation]    Server reboot wait.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=1    max=1
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Reboot Nova VM    NET1-VM
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    10s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    Delete Vm Instance    NET1-VM
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Server reboot hard
    [Documentation]    Server reboot hard.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=1    max=1
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server reboot --hard NET1-VM
    Log    ${output}
    Should Not Be True    ${rc}
    : FOR    ${vm}    IN    @{NET_1_VM_GRP_NAME}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    30s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM
    Should Contain    ${output}    NET1-VM
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    Delete Vm Instance    NET1-VM
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Server set Name
    [Documentation]    Server set Name
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=1    max=1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server set --name VM_updated NET1-VM
    Log    ${output}
    Should Not Be True    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show VM_updated
    Should Contain    ${output}    VM_updated
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${v4-fixed}
    Delete Vm Instance    VM_updated
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Create Floating ip With Fixed ip address
    [Documentation]    create floating ip with fixed ip address and verify in config datastore.
    Create Network    ${EXTERNAL_NET_NAME}    --external --provider-network-type flat --provider-physical-network vlantest
    Create Subnet    ${EXTERNAL_NET_NAME}    ${EXTERNAL_SUBNET_NAME}    ${EXTERNAL_SUBNET}    additional_args=--gateway ${EXTERNAL_GATEWAY} --allocation-pool ${EXTERNAL_SUBNET_ALLOCATION_POOL}
    @{ip}=    Create Floating IPs    ${EXTERNAL_NET_NAME}    additional_args=--fixed-ip-address ${fixed_ip}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}
    ${floating_ip_id}=    Get Floating ip Id    @{ip}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/floatingips/floatingip/${floating_ip_id}    ${Fixed_IP_Check}
    Floating ip Delete    @{ip}
    Delete Network    ${EXTERNAL_NET_NAME}
    [Teardown]    Run Keywords    Clear L2_Network

Create and Update Network to External
    [Documentation]    Create Network and update to external and check SNAT communication.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP_1}
    Neutron Security Group Rule Create    ${SECURITY_GROUP_1}    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type flat --provider-physical-network @{PROVIDER}[0]
    Update Subnet    @{SUBNETS_NAME}[0]    additional_args=--gateway ${EXTERNAL_GATEWAY} --allocation-pool ${EXTERNAL_SUBNET_ALLOCATION_POOL}
    ${VM1}=    Create List    @{NET_1_VM_GRP_NAME}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    sg=${SECURITY_GROUP_1}
    Poll VM Is ACTIVE    @{NET_1_VM_GRP_NAME}[0]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}[0]
    ${VM1_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${NET_1_VM_GRP_NAME}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM1_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ssh ${pnf_user}@@{external_pnf}[0]    (y/n)
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    y    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${pnf_password}    ${pnf_prompt}
    Log    ${output}
    Delete Vm Instance    @{NET_1_VM_GRP_NAME}[0]
    Delete SecurityGroup    ${SECURITY_GROUP_1}
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Disable Network And Check Ping
    [Documentation]    Create network and check ping between VM's.
    #Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan --disable
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535
    \    ...    remote_ip_prefix=0.0.0.0/0
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_1_VM_INSTANCES}    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[1]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Update Subnet With Allocation Pool
    [Documentation]    update subnet with allocation pool and verify in config datastore.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--allocation-pool start=${ALLOCATIONPOOL_START},end=${ALLOCATIONPOOL_END}
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--allocation-pool start=${UP_ALLOCATIONPOOL_START},end=${UP_ALLOCATIONPOOL_END}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535
    \    ...    remote_ip_prefix=0.0.0.0/0
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[1]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SET_SUBNETS_ALLOCATION_POOL_CHECK}
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Create port with No Security Group And Check Ping
    [Documentation]    create port with no security group and check ping from DHCP.
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]    additional_args=--allocation-pool start=40.0.0.20,end=40.0.0.100
    Create Port    @{NETWORKS_NAME}[1]    ${PORT}    additional_args=--no-security-group
    Create Vm Instance With Port    ${PORT}    @{NET_1_VM_GRP_NAME}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_GRP_NAME}[0]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_GRP_NAME}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_GRP_NAME}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_GRP_NAME}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[1]    @{NET1_VM_IPS}[0]
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    default
    Delete Vm Instance    @{NET_1_VM_GRP_NAME}[0]
    Delete Port    ${PORT}
    Delete Network    @{NETWORKS_NAME}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Network Disable port Security
    [Documentation]    Create network with disable port security and check ping between VM's.
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan --disable-port-security
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535
    \    ...    remote_ip_prefix=0.0.0.0/0
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_1_VM_INSTANCES}    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[1]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Update Network Disable port Security
    [Documentation]    Update network with disable port security and check ping between VM's.
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535
    \    ...    remote_ip_prefix=0.0.0.0/0
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_1_VM_INSTANCES}    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[1]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Update Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan --disable-port-security
    Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone created for test suite.
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2
