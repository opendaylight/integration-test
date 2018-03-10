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
@{NET_1_OPT_VM_INSTANCES}    VM-1
@{NET_2_OPT_VM_INSTANCES}    VM-2
@{ROUTERS}        router1    router2
${SECURITY_GROUP_1}    SG1
${PORT}           port1
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
${GATEWAY_IP}     30.0.0.12
${FIXED_IP}       30.0.0.14
${INTERNAL_NW_GATEWAY}    30.0.0.2
${DNS_NAME_SERVER}    8.8.8.8
@{Allowed_Add_Mac}    "mac-address":"aa:aa:aa:aa:aa:aa"
@{Allowed_Add_ip}    "ip-address":"30.0.0.25"
@{Mac_Add}        "mac-address":"aa:aa:aa:aa:aa:aa"
@{host_id}        "neutron-binding:host-id":"2"
@{Binding_Profile}    vif_model=avp
@{Fixed_IP_Check}    "ip-address":"30.0.0.14"
@{Floating_IP_Check}    "floating-ip-address":"101.0.0.26"
@{Route_Dest}     "destination":"30.0.0.0/24"
@{Route_NextHop}    "nexthop":"30.0.0.12"
@{State_True}     "admin-state-up":true
@{Router_Name}    "name":"router2"
@{Distributed_True}    "distributed":true
@{State_False}    "admin-state-up":false
@{NetworkShared}    "shared":true
@{Network_external}    "neutron-L3-ext:external":true
@{Network_internal}    "neutron-L3-ext:external":false
@{SUBNETS_NAME_CHECK}    l2_subnet_1
@{SUBNETS_NO_DHCP_CHECK}    enable-dhcp":false
@{SUBNETS_DHCP_CHECK}    enable-dhcp":true
@{SUBNETS_DNS_NAMESERVERS_CHECK}    "dns-nameservers":["8.8.8.8"]
${FLOATING_IP}    101.0.0.26
${ALLOWED_IP_ADDRESS}    30.0.0.25
${ALLOWED_MAC_ADDRESS}    aa:aa:aa:aa:aa:aa
${EXTERNAL_NW_GATEWAY}    10.10.10.2
@{external_pnf}    10.10.10.1
@{PROVIDER}       flat1

*** Test Cases ***
Components Required
    [Documentation]    Create required components internal network, external network,
    ...    instance and security group for test suite.
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    protocol=icmp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${VM1}=    Create List    @{NET_1_OPT_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}
    Poll VM Is ACTIVE    @{NET_1_OPT_VM_INSTANCES}[0]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_OPT_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_OPT_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_OPT_VM_INSTANCES}
    ${VM1_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${NET_1_OPT_VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM1_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_OPT_VM_INSTANCES}
    Poll VM Is ACTIVE    @{NET_2_OPT_VM_INSTANCES}[0]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_2_OPT_VM_INSTANCES}
    ${NET2_VM_IPS}    ${NET2_DHCP_IP}    Collect VM IP Addresses    false    @{NET_2_OPT_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_2_OPT_VM_INSTANCES}
    ${VM2_IPS}=    Collections.Combine Lists    ${NET2_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${NET_2_OPT_VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM2_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET2_VM_IPS}
    Set Suite Variable    ${NET2_DHCP_IP}
    Should Not Contain    ${NET2_VM_IPS}    None
    Should Not Contain    ${NET2_DHCP_IP}    None
    Create Network    ${EXTERNAL_NET_NAME}    --provider-network-type flat --provider-physical-network @{PROVIDER}[0]
    Update Network    ${EXTERNAL_NET_NAME}    additional_args=--external
    Create Subnet    ${EXTERNAL_NET_NAME}    ${EXTERNAL_SUBNET_NAME}    ${EXTERNAL_SUBNET}    --gateway ${EXTERNAL_GATEWAY} --allocation-pool ${EXTERNAL_SUBNET_ALLOCATION_POOL}
    Neutron Security Group Create    ${SECURITY_GROUP_1}
    Delete All Security Group Rules    ${SECURITY_GROUP_1}
    Neutron Security Group Rule Create    ${SECURITY_GROUP_1}    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0

Network set with attribute disable-port-security
    [Documentation]    Network set with attribute enable-port-security and verify network updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--disable-port-security
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    False
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_external}

Network set with attribute enable-port-security
    [Documentation]    Network set with attribute enable-port-security and verify network updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--enable-port-security
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    True
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_external}

Network set with attribute external
    [Documentation]    Network set with attribute external and verify network updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--external
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    External
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_external}

Network set with attribute internal
    [Documentation]    Network set with attribute internal and verify network updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--internal
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    Internal
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${Network_internal}

Network set with attribute disable
    [Documentation]    Network set with attribute disable and verify network updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--disable
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    DOWN
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${State_False}

Network set with attribute enable
    [Documentation]    Network set with attribute enable and verify network updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--enable
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    UP
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${State_True}

Network set with attribute share
    [Documentation]    Network set with attribute share and verify network updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--share
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should Contain    ${output}    True
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${NetworkShared}
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--no-share

SubNet set with no-dhcp
    [Documentation]    Subnet set with no-dhcp and verify subnet updated.
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--no-dhcp
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    False
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_NO_DHCP_CHECK}

SubNet set with dhcp
    [Documentation]    Subnet set with dhcp and verify subnet updated.
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--dhcp
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    True
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_DHCP_CHECK}

SubNet set with dns-nameserver
    [Documentation]    Subnet set with dns-nameserver and verify subnet updated.
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--dns-nameserver ${DNS_NAME_SERVER}
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Contain    ${output}    ${DNS_NAME_SERVER}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_DNS_NAMESERVERS_CHECK}

SubNet set with no-dns-nameserver
    [Documentation]    Subnet set with no-dns-nameserver and verify subnet updated.
    Update SubNet    @{SUBNETS_NAME}[0]    additional_args=--no-dns-nameserver
    ${output}=    Show SubNet    @{SUBNETS_NAME}[0]
    Should Not Contain    ${output}    ${DNS_NAME_SERVER}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_NAME_CHECK}

Router Disable
    [Documentation]    Create router with option disable and check in config datastore.
    Create Router    @{ROUTERS}[0] --disable
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    DOWN
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${State_False}
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Delete Router    @{ROUTERS}[0]

Router Distributed
    [Documentation]    Create router with option distributed and check in config datastore.
    Create Router    @{ROUTERS}[0] --distributed
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    True
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${Distributed_True}
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Delete Router    router1

Update Router
    [Documentation]    Create router and set Router name check in config datastore.
    Create Router    @{ROUTERS}[0]
    Update Router    @{ROUTERS}[0]    cmd=--name router2
    ${output}=    OpenStack CLI    cmd=openstack router show router2
    Should Contain    ${output}    router2
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    router2
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${Router_Name}
    Delete Router    router2

Update Router Enable
    [Documentation]    Create router with option disable. Update router to enable and check in config datastore.
    Create Router    @{ROUTERS}[0] --disable
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Update Router    @{ROUTERS}[0]    cmd=--enable
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    UP
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${State_True}

Update Router Disable
    [Documentation]    Update created router to disable and check in config datastore.
    Update Router    @{ROUTERS}[0]    cmd=--disable
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    DOWN
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${State_False}

Update Router Distributed
    [Documentation]    Update created router to distributed and check in config datastore.
    Update Router    @{ROUTERS}[0]    cmd=--distributed
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    True
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${Distributed_True}

Update Router Centralized
    [Documentation]    Update created router to centralized and check if updated in config datastore
    Update Router    @{ROUTERS}[0]    cmd=--centralized
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    False
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${State_False}

Update Router Route Destination
    [Documentation]    Update created router route and check in config datastore
    Update Router    @{ROUTERS}[0]    cmd=--route destination=@{SUBNETS_RANGE}[0],gateway=${GATEWAY_IP}
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    ${GATEWAY_IP}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${Route_Dest}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${Route_NextHop}

Unset Router Route Destination
    [Documentation]    Unset router route destination and verify router updated.
    Router Unset    @{ROUTERS}[0]    cmd=--route destination=@{SUBNETS_RANGE}[0],gateway=${GATEWAY_IP}
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Not Contain    ${output}    @{SUBNETS_RANGE}[0]

Router External Gateway
    [Documentation]    Attach external gateway to created router.
    Add Router Gateway    @{ROUTERS}[0]    ${EXTERNAL_NET_NAME}
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Delete Router    @{ROUTERS}[0]

Create Floating ip
    [Documentation]    Create floating ip and check in config datastore.
    @{ip}=    Create Floating IPs    ${EXTERNAL_NET_NAME}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}
    ${floating_ip_id}=    Get Floating ip Id    @{ip}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/floatingips/floatingip/${floating_ip_id}    ${ip}
    Floating ip Delete    @{ip}

Create Port With Fixed IP
    [Documentation]    Create port with fixed ip and check in config datastore
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[0],ip-address=${FIXED_IP}
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    ${FIXED_IP}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${Fixed_IP_Check}

Unset Port With Fixed IP
    [Documentation]    Unset port with fixed ip and check in config datastore.
    Unset Port    ${PORT}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[0],ip-address=${FIXED_IP}
    Reboot Nova VM    @{NET_1_OPT_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_OPT_VM_INSTANCES}[0]
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    ${FIXED_IP}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${State_True}

Update Port With Fixed IP
    [Documentation]    Update port with fixed ip and check in config datastore.
    Update Port    ${PORT}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[0],ip-address=${FIXED_IP}
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    ${FIXED_IP}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${Fixed_IP_Check}

Update Port With No Fixed IP
    [Documentation]    Update port with no fixed ip and verify port updated.
    Update Port    ${PORT}    additional_args=--no-fixed-ip
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    ${FIXED_IP}
    Delete Port    ${PORT}

Create port with Security Group
    [Documentation]    Create port with security group and check in config datastore.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=--security-group ${SECURITY_GROUP_1}
    ${SG_ID}=    Get Security Group Id    ${SECURITY_GROUP_1}
    @{sg_id}=    Create List    ${SG_ID}
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    @{SG_ID}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${sg_id}

Unset port with Security Group
    [Documentation]    Unset port with security group and verify port updated.
    Unset Port    ${PORT}    additional_args=--security-group ${SECURITY_GROUP_1}
    ${SG_ID}=    Get Security Group Id    ${SECURITY_GROUP_1}
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    ${SG_ID}

Update port with Security Group
    [Documentation]    Update port with security group and check in config datastore.
    Update Port    ${PORT}    additional_args=--security-group ${SECURITY_GROUP_1}
    ${SG_ID}=    Get Security Group Id    ${SECURITY_GROUP_1}
    @{sg_id}=    Create List    ${SG_ID}
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    @{SG_ID}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${sg_id}

Update port with No Security Group
    [Documentation]    Update port with no security group and verify port udated.
    Update Port    ${PORT}    additional_args=--no-security-group
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    ${SECURITY_GROUP_1}
    Delete Port    ${PORT}

Create Port With Allowed Addresses
    [Documentation]    Create port with allowed addresses and check in config datastore.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=--allowed-address ip-address=${ALLOWED_IP_ADDRESS},mac-address=${ALLOWED_MAC_ADDRESS}
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    ip_address='${ALLOWED_IP_ADDRESS}', mac_address='${ALLOWED_MAC_ADDRESS}'
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${Allowed_Add_Mac}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${Allowed_Add_ip}

Unset Port With Allowed Addresses
    [Documentation]    Unset port with allowed addresses and verify port updated.
    Unset Port    ${PORT}    additional_args=--allowed-address ip-address=${ALLOWED_IP_ADDRESS},mac-address=${ALLOWED_MAC_ADDRESS}
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    ip_address='${ALLOWED_IP_ADDRESS}', mac_address='${ALLOWED_MAC_ADDRESS}'
    Delete Port    ${PORT}

Disable Port
    [Documentation]    Create port with option disable and check in config datastore.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=--disable
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    DOWN
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${State_False}

Update Enable Port
    [Documentation]    Update port with option enable and check in config datastore.
    Update Port    ${Port}    additional_args=--enable
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    UP
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${State_True}

Update Disable Port
    [Documentation]    Update port with option disable and check in config datastore.
    Update Port    ${Port}    additional_args=--disable
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    DOWN
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${State_False}
    Delete Port    ${PORT}

Create Port With Host ID
    [Documentation]    Create port with host id and check in config datastore.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=--host 2
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    2
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${host_id}
    Delete Port    ${PORT}

Create Port With Mac Address
    [Documentation]    Create port with mac address and check in config datastore.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=--mac-address=${ALLOWED_MAC_ADDRESS}
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    ${ALLOWED_MAC_ADDRESS}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${Mac_Add}
    Delete Port    ${PORT}

Create port with No Security Group
    [Documentation]    Create port with no security group and verify port updated.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=--no-security-group
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    default
    Delete Port    ${PORT}

Update Port With Host ID
    [Documentation]    Create port with host id and check in config datastore.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}
    Update Port    ${PORT}    additional_args=--host 2
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    2
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${PORT}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/port/${port_id}    ${host_id}
    Delete Port    ${PORT}

Unset Port With Binding Profile
    [Documentation]    Unset port with binding profile and verify port updated.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    --binding-profile vif_model=avp
    Unset Port    ${PORT}    additional_args=--binding-profile vif_model
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    vif_model='avp'
    Delete Port    ${PORT}

SSH With Login Attribute
    [Documentation]    Create router add interfaces and associate floating ip. ssh by login attribute.
    Create Router    @{ROUTERS}[0] --disable
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    ${EXTERNAL_NET_NAME}
    ${VM1}=    Create List    @{NET_1_OPT_VM_INSTANCES}[0]
    @{ip}=    Create And Associate Floating IPs    ${EXTERNAL_NET_NAME}    @{VM1}
    Set Suite Variable    @{ip}
    Server SSH    @{NET_1_OPT_VM_INSTANCES}[0]    additional_args=--login cirros

SSH With Port Attribute
    [Documentation]    ssh by port attribute for the created VM.
    Server SSH    @{NET_1_OPT_VM_INSTANCES}[0]    additional_args=--port 22

SSH With Public Attribute
    [Documentation]    ssh by public attribute for the created VM and remove interfaces.
    Server SSH    @{NET_1_OPT_VM_INSTANCES}[0]    additional_args=--public
    Floating ip Delete    @{ip}
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Delete Router    @{ROUTERS}[0]

Create Floating ip With Port
    [Documentation]    create port and associate floating ip and check in config datastore.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}
    Create Router    @{ROUTERS}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    ${EXTERNAL_NET_NAME}
    @{ip}=    Create Floating IPs    ${EXTERNAL_NET_NAME}    additional_args=--port ${PORT}
    ${rc}    ${server_output}=    Run And Return Rc And Output    openstack floating ip list -cID -fvalue
    Log    ${server_output}
    @{floating_id}=    Split String    ${server_output}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${portid}=    Get Port Id    ${PORT}
    @{port_id}=    Create List    ${portid}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/floatingips/floatingip/@{floating_id}[0]    ${port_id}
    Floating ip Delete    @{floating_id}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Delete Port    ${PORT}
    Delete Router    @{ROUTERS}[0]

Create Floating ip With Floating ip address
    [Documentation]    create floating ip with floating ip address and check in config datastore.
    @{ip}=    Create Floating IPs    ${EXTERNAL_NET_NAME}    additional_args=--floating-ip-address ${FLOATING_IP}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}
    ${floating_ip_id}=    Get Floating ip Id    @{ip}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/floatingips/floatingip/${floating_ip_id}    ${Floating_IP_Check}
    Floating ip Delete    @{ip}

Create Router Disable And Check SNAT
    [Documentation]    Create router with option disable and check SNAT communication.
    Create Router    @{ROUTERS}[0] --disable
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    ${EXTERNAL_NET_NAME}
    ${des_ip_1}=    Create List    @{external_pnf}[0]
    Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Delete Router    @{ROUTERS}[0]

Disable Router and Check Ping
    [Documentation]    Create router with option disable. Add router to subnet of networks and check ping.
    Create Router    @{ROUTERS}[0] --disable
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${des_ip_1}=    Create List    @{NET2_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    ${des_ip_2}    ping_should_succeed=False
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Delete Router    @{ROUTERS}[0]
    [Teardown]    Run Keywords    Clear Interfaces

Set Router Route and Check Ping
    [Documentation]    create two network with vm's. create router with disable. add router to subnet of networks. check ping.
    Create Router    @{ROUTERS}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Update Router    @{ROUTERS}[0]    cmd=--route destination=@{SUBNETS_RANGE}[0],gateway=${INTERNAL_NW_GATEWAY}
    ${des_ip_1}=    Create List    @{NET2_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Router Unset    @{ROUTERS}[0]    cmd=--route destination=@{SUBNETS_RANGE}[0],gateway=${INTERNAL_NW_GATEWAY}
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Delete Router    @{ROUTERS}[0]
    [Teardown]    Run Keywords    Clear Interfaces

Create Server With Port ID
    [Documentation]    create server with port and check server updated.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}
    Update Port    ${PORT}    additional_args=--host 2
    Create Vm Instance With Port    ${PORT}    @{NET_1_OPT_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_OPT_VM_INSTANCES}[0]
    Should Contain    ${output}    2
    Delete Port    ${PORT}

Disable port Security
    [Documentation]    Create port and disable port security
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}    additional_args=--disable-port-security
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    default

Update Enable port Security
    [Documentation]    Update port with enable port security and verify port updated.
    Update Port    ${PORT}    additional_args=--enable-port-security
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    default

Update Disable port Security
    [Documentation]    Update port with disable port security and verify port updated.
    Update Port    ${PORT}    additional_args=--disable-port-security --no-security-group
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    default
    Delete Port    ${PORT}

Set Router Route With External and Check Ping
    [Documentation]    Create router add interfaces and update router with route. check ping between VM's.
    Create Router    @{ROUTERS}[1]
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[1]    ${EXTERNAL_NET_NAME}
    Update Router    @{ROUTERS}[1]    cmd=--route destination=${EXTERNAL_SUBNET},gateway=101.0.0.2
    ${des_ip_1}=    Create List    @{external_pnf}[0]
    Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Router Unset    @{ROUTERS}[1]    cmd=--route destination=${EXTERNAL_SUBNET},gateway=101.0.0.2
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    Delete Router    @{ROUTERS}[1]
    [Teardown]    Run Keywords    Clear Interfaces
    ...    AND    Clear L2_Network

*** keywords ***
Clear Interfaces
    [Documentation]    Remove Interfaces
    ${rc}    ${router_output}=    Run And Return Rc And Output    openstack router list -cID -fvalue
    Log    ${router_output}
    @{routers}=    Split String    ${router_output}    \n
    ${rc}    ${subnet_output}=    Run And Return Rc And Output    openstack subnet list -cID -fvalue
    Log    ${subnet_output}
    @{subnets}=    Split String    ${subnet_output}    \n
    : FOR    ${router}    IN    @{routers}
    \    Run Keyword And Ignore Error    Router Unset    ${router}    cmd=--route destination=@{SUBNETS_RANGE}[0],gateway=${INTERNAL_NW_GATEWAY}
    \    Run Keyword And Ignore Error    Router Unset    ${router}    cmd=--route destination=${EXTERNAL_SUBNET},gateway=101.0.0.2
    \    Run Keyword And Ignore Error    Remove Interfaces    ${router}    ${subnets}
