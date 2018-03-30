*** Settings ***
Documentation     Test suite to verify IPV6 Functionality for other scenarios in
...               slaac/dhcpv6-stateless and dhcpv6-stateful modes
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        skip_if_${SECURITY_GROUP_MODE}    #Test Teardown    Get Test Teardown Debugs
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
@{subnet_address_mode}    dhcpv6-stateful
@{subnet_ra_mode}    dhcpv6-stateful
@{SECURITY_GROUP}    sg1    sg2    sg3    sg4    sg-remote    sg_additional    sg_dhcp
...               sg5    sg6
@{SECURITY_GROUP1}    sg11    sg22    sg33    sg44    sg55    sg66
@{NETWORKS_IPV6}    NET1_IPV6    NET2_IPV6    NET3_IPV6
@{SUBNETS_NAME}    SUBNET1_IPV6    SUBNET2_IPV6    SUBNET3_IPV6
@{IPV6_VM}        VM1_IPV6    VM2_IPV6    VM3_IPV6
@{NET1-VM}        NET1-VM1    NET1-VM2
@{NET2-VM}        NET2-VM1    NET2-VM2
@{SUBNETS_RANGE}    2003:db8:cafe:e::/64    2007:db9:cafe:e::/64    2002:db9:cafe:e::/64
@{SUBNETS_CIDR}    2001:db8:0:2::/64    2002:db8:0:2::/64    2003:db8:0:2::/64
${NET1_ADDR_POOL}    --allocation-pool start=2003:db8:cafe:e::2,end=2003:db8:cafe:e::10
${ROUTERS}        router1
${image}          fedora
${flavor}         fedora
@{IPV4_NETWORKS}    NET1_IPV4    NET2_IPV4
@{IPV4_SUBNETS}    SUBNET1_IPV4    SUBNET2_IPV4
@{IPV4_SUBNETS_RANGE}    20.0.0.0/24    40.0.0.0/24
@{NET_1_VM_INSTANCES}    IPv4_VM1    IPv4_VM2
@{Tcp_SG}         tcp_sg
@{port_Nub}       123    30    48
@{SG1}            ipv4_sg
${password}       cubswin:)
${user}           fedora

*** Test Cases ***
Check Ping from Dhcp for ipv6 address-mode in slaac
    [Documentation]    Check ping from dhcp to vm when ipv6 subnet is configured for address-mode in slaac
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    ethertype=IPv6
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${IPV6_VM}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{IPV6_VM}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    300s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{IPV6_VM}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{IPV6_VM}
    Log    ${VM_IP_NETV6}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${IPV6_VM}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${IPV6_VM}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    ${src_ip}=    Collect IPV6    @{IPV6_VM}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping6 ${src_ip}    30s
    Should Contain    ${output}    56 bytes
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${src_ip}    ${des_ip_21}
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{IPV6_VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Clear L2_Network

Check Ping from Dhcp for ipv6 address-mode in dhcpv6-stateless
    [Documentation]    Check ping from dhcp to vm when ipv6 subnet is configured for address-mode in dhcpv6-stateless
    ...    and also across vm's
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${IPV6_VM}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{IPV6_VM}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    300s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{IPV6_VM}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{IPV6_VM}
    Log    ${VM_IP_NETV6}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${IPV6_VM}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${IPV6_VM}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    ${src_ip}=    Collect IPV6    @{IPV6_VM}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping6 ${src_ip}    30s
    Should Contain    ${output}    56 bytes
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${src_ip}    ${des_ip_21}
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{IPV6_VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Clear L2_Network

Check Ping from Dhcp for ipv6 ra-mode in slaac
    [Documentation]    Check ping from dhcp to vm when ipv6 subnet is configured for ra-mode in slaac
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${IPV6_VM}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{IPV6_VM}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    300s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{IPV6_VM}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{IPV6_VM}
    Log    ${VM_IP_NETV6}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${IPV6_VM}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${IPV6_VM}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    ${src_ip}=    Collect IPV6    @{IPV6_VM}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping6 ${src_ip}    30s
    Should Contain    ${output}    56 bytes
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${src_ip}    ${des_ip_21}
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{IPV6_VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Clear L2_Network

Check Ping from Dhcp for ipv6 ra-mode in dhcpv6-stateless
    [Documentation]    Check ping from dhcp to vm when ipv6 subnet is configured for ra-mode in dhcpv6-stateless
    ...    and also across vm's
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${IPV6_VM}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{IPV6_VM}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    300s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{IPV6_VM}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{IPV6_VM}
    Log    ${VM_IP_NETV6}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${IPV6_VM}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${IPV6_VM}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    ${src_ip}=    Collect IPV6    @{IPV6_VM}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping6 ${src_ip}    30s
    Should Contain    ${output}    56 bytes
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${src_ip}    ${des_ip_21}
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{IPV6_VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Clear L2_Network

Check Ping from Dhcp for ipv6 ra-mode in dhcpv6-stateful
    [Documentation]    Check ping from dhcp to vm when ipv6 subnet is configured for ra-mode in dhcpv6-stateful
    ...    and also across vm's
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Create Network    @{IPV4_NETWORKS}[0]
    Create SubNet    @{IPV4_NETWORKS}[0]    @{IPV4_SUBNETS}[0]    @{IPV4_SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    ethertype=IPv6
    Create Fedora VM for dhcpv6-stateful    @{IPV4_NETWORKS}[0]    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    sg=@{sg_list}[0]    image=fedora    flavor=fedora
    ${src_ip}=    Collect IPV6    @{IPV6_VM}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping6 ${src_ip}    30s
    Should Contain    ${output}    56 bytes
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${src_ip}    ${des_ip_21}
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{IPV6_VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Clear L2_Network

Check Ping from Dhcp for ipv6 address-mode in dhcpv6-stateful
    [Documentation]    Check ping from dhcp to vm when ipv6 subnet is configured for address-mode in dhcpv6-stateful
    ...    and also across vm's
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Create Network    @{IPV4_NETWORKS}[0]
    Create SubNet    @{IPV4_NETWORKS}[0]    @{IPV4_SUBNETS}[0]    @{IPV4_SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    Create Fedora VM for dhcpv6-stateful    @{IPV4_NETWORKS}[0]    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    sg=@{sg_list}[0]    image=fedora    flavor=fedora
    ${src_ip}=    Collect IPV6    @{IPV6_VM}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping6 ${src_ip}    30s
    Should Contain    ${output}    56 bytes
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${src_ip}    ${des_ip_21}
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{IPV6_VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Clear L2_Network

Check ICMP and TCP Communication across networks:Test1
    [Documentation]    Check ping and ssh across networks when ipv6 one subnet is configured for address-mode in dhcpv6-stateless
    ...    and the other subnet in ra-mode as slaac
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Create Network    @{NETWORKS_IPV6}[1]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_IPV6}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_CIDR}[1]    ${net1_additional_args}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    ${VM1}=    Create List    @{IPV6_VM}[2]
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    300s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{VM1}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{VM1}
    Log    ${VM_IP_NETV6}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM1}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM1}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    ${VM2}=    Create List    @{NET2-VM}[0]
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[0]
    : FOR    ${vm}    IN    @{VM2}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    300s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{VM2}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{VM2}
    Log    ${VM_IP_NETV6}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM2}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM2}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[2]
    ${des_ip_2}=    Collect IPV6    @{NET2-VM}[0]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${desp_ip_1}    ${des_ip_21}
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[1]    ${des_ip_1}    @{port_Nub}[0]
    Delete Vm Instance    @{IPV6_VM}[2]
    Delete Vm Instance    @{NET2-VM}[0]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    Delete Network    @{NETWORKS_IPV6}[1]
    [Teardown]    Clear L2_Network

Check ICMP and TCP Communication across networks:Test 2
    [Documentation]    Check ping and ssh across networks when ipv6 one subnet is configured for address-mode in dhcpv6-stateful
    ...    and the other subnet in ra-mode as slaac
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Create Network    @{NETWORKS_IPV6}[1]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=slaac
    Create SubNet    @{NETWORKS_IPV6}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_CIDR}[1]    ${net1_additional_args}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    Create Network    @{IPV4_NETWORKS}[0]
    Create SubNet    @{IPV4_NETWORKS}[0]    @{IPV4_SUBNETS}[0]    @{IPV4_SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    ethertype=IPv6
    Create Fedora VM for dhcpv6-stateful    @{IPV4_NETWORKS}[0]    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    sg=@{sg_list}[0]    image=fedora    flavor=fedora
    ${First_VM}    Collect IPV6    @{IPV6_VM}[0]
    Create Fedora VM for dhcpv6-stateful    @{IPV4_NETWORKS}[0]    @{NETWORKS_IPV6}[1]    @{NET2-VM}[1]    sg=@{sg_list}[0]    image=fedora    flavor=fedora
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_2}=    Collect IPV6    @{NET2-VM}[1]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${desp_ip_1}    ${des_ip_21}
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[1]    ${des_ip_1}    @{port_Nub}[0]
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{NET2-VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    Delete Network    @{NETWORKS_IPV6}[1]
    [Teardown]    Clear L2_Network

Check ICMP and TCP Communication across networks:Test 3
    [Documentation]    Check ping and ssh across networks when ipv6 one subnet is configured for address-mode in dhcpv6-stateful
    ...    and the other subnet in ra-mode as dhcpv6-stateless
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=dhcpv6-stateful
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Create Network    @{NETWORKS_IPV6}[1]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-ra-mode=dhcpv6-stateless
    Create SubNet    @{NETWORKS_IPV6}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_CIDR}[1]    ${net1_additional_args}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    Create Network    @{IPV4_NETWORKS}[0]
    Create SubNet    @{IPV4_NETWORKS}[0]    @{IPV4_SUBNETS}[0]    @{IPV4_SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    Create Fedora VM for dhcpv6-stateful    @{IPV4_NETWORKS}[0]    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    sg=@{sg_list}[0]    image=fedora    flavor=fedora
    ${First_VM}    Collect IPV6    @{IPV6_VM}[0]
    Create Fedora VM for dhcpv6-stateful    @{IPV4_NETWORKS}[0]    @{NETWORKS_IPV6}[1]    @{NET2-VM}[1]    sg=@{sg_list}[0]    image=fedora    flavor=fedora
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_2}=    Collect IPV6    @{NET2-VM}[1]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${desp_ip_1}    ${des_ip_21}
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[1]    ${des_ip_1}    @{port_Nub}[0]
    Delete Vm Instance    @{IPV6_VM}[0]
    Delete Vm Instance    @{NET2-VM}[1]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS}
    Delete Network    @{NETWORKS_IPV6}[0]
    Delete Network    @{NETWORKS_IPV6}[1]
    [Teardown]    Clear L2_Network
