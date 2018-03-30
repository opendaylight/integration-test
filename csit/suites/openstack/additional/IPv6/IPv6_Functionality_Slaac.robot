*** Settings ***
Documentation     Test suite to verify IPV6 Basic Functionality and security-group
...               functionality in slaac and dhcpv6-stateless mode
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Force Tags        skip_if_${SECURITY_GROUP_MODE}
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
@{subnet_address_mode}    slaac    dhcpv6-stateless
@{subnet_ra_mode}    slaac    dhcpv6-stateless
@{SECURITY_GROUP}    sg1    sg2    sg3    sg4    sg-remote    sg_additional    sg_dhcp
...               sg5    sg6
@{SECURITY_GROUP1}    sg11    sg22    sg33    sg44    sg55    sg66
@{NETWORKS_IPV6}    NET1_IPV6    NET2_IPV6    NET3_IPV6
@{SUBNETS_NAME}    SUBNET1_IPV6    SUBNET2_IPV6    SUBNET3_IPV6
@{IPV6_VM}        VM1_IPV6    VM2_IPV6    VM3_IPV6
@{NET1-VM}        NET1-VM1    NET1-VM2
@{NET2-VM}        NET2-VM1    NET2-VM2
@{SUBNETS_RANGE}    2003:db8:cafe:e::/64    2007:db9:cafe:e::/64    2004:db9:cafe:e::/64
@{SUBNETS_CIDR}    2001:db8:0:2::/64    2002:db8:0:2::/64    2003:db8:0:2::/64
${NET1_ADDR_POOL}    --allocation-pool start=2003:db8:cafe:e::2,end=2003:db8:cafe:e::10
${ROUTERS}        router1
${image}          cirros
${flavor}         cirros
@{IPv4_NETWORKS_NAME}    NET1_IPV4    NET2_IPV4
@{IPv4_SUBNETS_NAME}    SUBNET1_IPV4    SUBNET2_IPV4
@{IPv4_SUBNETS_RANGE}    20.0.0.0/24    40.0.0.0/24
@{NET_1_VM_INSTANCES}    IPv4_VM1    IPv4_VM2
@{NET1_VM_INSTANCE}    IPv4_VM11    IPv4_VM12
@{Tcp_SG}         tcp_sg
@{port_Nub}       123    30    48
@{SG1}            ipv4_sg
${password}       cubswin:)
${user}           cirros

*** Test Cases ***
Create Zone
    [Documentation]    Creating Availabilityzone create for test suite
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Create Secuirty rule for tcp
    [Documentation]    Creating an ingress security rule for tcp protocol
    Neutron Security Group Create    @{Tcp_SG}[0]
    Delete All Security Group Rules    @{Tcp_SG}[0]
    Neutron Security Group Rule Create    @{Tcp_SG}[0]    direction=ingress    protocol=tcp    ethertype=IPv6

Create IPv6 Network1 Components
    [Documentation]    Creating single IPv6 network and subnet with router
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=@{subnet_address_mode}[0] --ipv6-ra-mode=@{subnet_ra_mode}[0]
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
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
    Add Security Group To VM    @{IPV6_VM}[0]    @{Tcp_SG}[0]
    Add Security Group To VM    @{IPV6_VM}[1]    @{Tcp_SG}[0]
    Delete Vm Instance    @{IPV6_VM}[2]
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${NET1-VM}    sg=@{sg_list}[0]    image=cirros    flavor=cirros    additional_args=--availability-zone ${zone1}
    : FOR    ${vm}    IN    @{NET1-VM}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    300s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{NET1-VM}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{NET1-VM}
    Log    ${VM_IP_NETV6}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET1-VM}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${NET1-VM}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    Add Security Group To VM    @{NET1-VM}[0]    @{Tcp_SG}[0]
    Add Security Group To VM    @{NET1-VM}[1]    @{Tcp_SG}[0]
    ${VM1}=    Create List    @{IPV6_VM}[2]
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${VM1}    sg=@{sg_list}[0]    image=cirros    flavor=cirros    additional_args=--availability-zone ${zone2}
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
    Add Security Group To VM    @{IPV6_VM}[2]    @{Tcp_SG}[0]

Create IPv6 Network2 Components
    [Documentation]    Creating second IPv6 network and subnet with router
    Create Network    @{NETWORKS_IPV6}[1]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=@{subnet_address_mode}[0] --ipv6-ra-mode=@{subnet_ra_mode}[0]
    Create SubNet    @{NETWORKS_IPV6}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_CIDR}[1]    ${net1_additional_args}
    Add Router Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${VM1}=    Create List    @{NET2-VM}[0]
    Create Vm Instances    @{NETWORKS_IPV6}[1]    ${VM1}    sg=@{sg_list}[0]    min=1    max=1    image=${image}
    ...    flavor=${flavor}
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[1]}    ::/64    (:[a-f0-9]{,4}){,4}
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
    #Should Not Contain    ${VM_IP_NETV6}    None
    Add Security Group To VM    @{NET2-VM}[0]    @{Tcp_SG}[0]

Create IPv4 Network Components
    [Documentation]    Create Single IPv4 Network and two VM instances
    ...    add ICMP Sg rule and a sg rule to login to the VM instance from DHCP Namespace
    Create Network    @{IPv4_NETWORKS_NAME}[0]
    Create SubNet    @{IPv4_NETWORKS_NAME}[0]    @{IPv4_SUBNETS_NAME}[0]    @{IPv4_SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    @{IPv4_NETWORKS_NAME}[0]    ${NET1_VM_INSTANCE}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{NET1_VM_INSTANCE}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET1_VM_INSTANCE}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET1_VM_INSTANCE}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET1_VM_INSTANCE}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    #Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{NET1_VM_INSTANCE}
    \    Poll VM Boot Status    ${vm}

Check Communication from dhcp
    [Documentation]    To check Ping from dhcp to the vm
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    ethertype=IPv6
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${src_ip}=    Collect IPV6    @{IPV6_VM}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping6 -c 10 ${src_ip}    ]>
    Should Contain    ${output}    64 bytes from ${src_ip}

Multicast Ping
    [Documentation]    check multicast ping
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${src_ip}=    Collect IPV6    @{IPV6_VM}[1]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -6 -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ping6 -l eth0 ff02::1    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ip -6 neigh    ${OS_SYSTEM_PROMPT}

Check Basic Functionality between vm's in same node(ICMP-Communication)
    [Documentation]    To check Ping between VM's in the same network within the same node using default-sg
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_11}=    Create List    ${des_ip_1}
    log    ${des_ip_11}
    ${des_ip_2}=    Collect IPV6    @{NET1-VM}[0]
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_1}    ${des_ip_21}

Check Basic Functionality between vm's in different node(ICMP-Communication)
    [Documentation]    To Check Ping between VM's in the same network within the different nodes using default-sg
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[2]
    ${des_ip_11}=    Create List    ${des_ip_1}
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_1}    ${des_ip_21}

Check Basic Functionality across vm's in different networks(ICMP-Communication)
    [Documentation]    To Check Ping between VM's in the different networks using default-sg
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_2}=    Collect IPV6    @{NET2-VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[1]    ${des_ip_2}    ${des_ip_11}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_1}    ${des_ip_21}

Check Basic Functionality between vm's in same node(TCP-Communication)
    [Documentation]    To check TCP communication between VM's in the same network within the same node using default-sg
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_2}=    Collect IPV6    @{NET1-VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]

Check Basic Functionality between vm's in different node(TCP-Communication)
    [Documentation]    To Check TCP communication between VM's in the same network within the same node using default-sg
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[2]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{port_Nub}[0]

Check Basic Functionality across vm's in different networks(TCP-Communication)
    [Documentation]    To Check TCP communication between VM's in the different networks using default-sg
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_2}=    Collect IPV6    @{NET2-VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[1]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]

Check Basic Functionality between vm's in same node(UDP-Communication)
    [Documentation]    To check UDP communication between VM's in the same network within the same node using default-sg
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_2}=    Collect IPV6    @{NET1-VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u

Check Basic Functionality between vm's in different node(UDP-Communication)
    [Documentation]    To Check UDP communication between VM's in the same network within the same node
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[2]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u

Check Basic Functionality across vm's in different networks(UDP-Communication)
    [Documentation]    To Check UDP communication between VM's in the different networks using default-sg
    ${des_ip_1}=    Collect IPV6    @{NET1-VM}[1]
    ${des_ip_2}=    Collect IPV6    @{NET2-VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[1]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u

Check SecurityGroup Functionality for ICMP within same network
    [Documentation]    To Check ICMP communication between VM's in the same network using own-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    ethertype=IPv6
    Remove Security Group From VM    @{IPV6_VM}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{IPV6_VM}[1]    @{sg_list}[0]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]

Check SecurityGroup Functionality for TCP within same network
    [Documentation]    To Check TCP communication between VM's in the same network using own-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Neutron Security Group Create    @{SECURITY_GROUP}[4]
    Delete All Security Group Rules    @{SECURITY_GROUP}[4]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=egress    protocol=tcp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[4]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[3]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[4]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[4]

Check SecurityGroup Functionality for UDP within same network
    [Documentation]    To Check UDP communication between VM's in the same network using own-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=udp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=udp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]

Check SecurityGroup Functionality for ANY Protocol within same network
    [Documentation]    To Check ANY protocol communication between VM's in the same network using own-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=udp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=udp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]

Check SecurityGroup Functionality for ICMP across different networks
    [Documentation]    To Check ICMP communication between VM's across different networks using own-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Neutron Security Group Create    @{SECURITY_GROUP}[4]
    Delete All Security Group Rules    @{SECURITY_GROUP}[4]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=egress    protocol=icmp    ethertype=IPv6
    Remove Security Group From VM    @{NET2-VM}[0]    @{sg_list}[0]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET2-VM}[0]    @{SECURITY_GROUP}[4]
    ${des_ip_1}=    Collect IPV6    @{NET2-VM}[0]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[3]
    ...    AND    Remove Security Group From VM    @{NET2-VM}[0]    @{SECURITY_GROUP}[4]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[4]

Check SecurityGroup Functionality for TCP across different networks
    [Documentation]    To Check TCP communication between VM's across different networks using own-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET2-VM}[0]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Collect IPV6    @{NET2-VM}[0]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[1]    ${des_ip_1}    @{port_Nub}[0]
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    ...    AND    Remove Security Group From VM    @{NET2-VM}[0]    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]

Check SecurityGroup Functionality for UDP across different networks
    [Documentation]    To Check UDP communication between VM's across different networks using own-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=udp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=udp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET2-VM}[0]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Collect IPV6    @{NET2-VM}[0]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[1]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    ...    AND    Remove Security Group From VM    @{NET2-VM}[0]    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]

Check SecurityGroup Functionality for ANY Protocol across different networks
    [Documentation]    To Check ANY protocol communication between VM's across different networks using own-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=udp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=udp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET2-VM}[0]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Collect IPV6    @{NET2-VM}[0]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[1]    ${des_ip_1}    @{port_Nub}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[1]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    ...    AND    Remove Security Group From VM    @{NET2-VM}[0]    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]

Check Remote-SG Functionality for ICMP protocol
    [Documentation]    To Check ICMP communication between VM's within the same network using remote-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Remove Security Group From VM    @{IPV6_VM}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{IPV6_VM}[1]    @{sg_list}[0]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[3]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[3]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[3]

Check Remote-SG Functionality for TCP protocol
    [Documentation]    To Check TCP communication between VM's within the same network using remote-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[2]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[2]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]

Check Remote-SG Functionality for UDP protocol
    [Documentation]    To Check UDP communication between VM's within the same network using remote-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[4]
    Delete All Security Group Rules    @{SECURITY_GROUP}[4]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=udp    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[4]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=udp    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[4]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=ingress    protocol=udp    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=egress    protocol=udp    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[4]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[4]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[4]

Check Remote-SG Functionality for ANY protocol
    [Documentation]    To Check ANY protocol communication between VM's within the same network using remote-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[2]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[3]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[2]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[3]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[3]

Check Remote-CIDR Functionality for ICMP protocol
    [Documentation]    To Check ICMP communication between VM's within the same network using remote-cidr
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=1    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=1    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=1    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=1    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[1]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]

Check Remote-CIDR Functionality for TCP protocol
    [Documentation]    To Check TCP communication between VM's within the same network using remote-cidr
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=tcp    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=tcp    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=tcp    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[1]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]

Check Remote-CIDR Functionality for UDP protocol
    [Documentation]    To Check UDP communication between VM's within the same network using remote-cidr
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=udp    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=udp    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=udp    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=udp    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[1]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]

Check Remote-CIDR Functionality for ANY protocol
    [Documentation]    To Check ANY protocol communication between VM's within the same network using remote-cidr
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    ethertype=IPv6    remote_ip_prefix=@{SUBNETS_CIDR}[1]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_11}=    Create List    ${des_ip_1}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]

Check Remote-SG Functionality for ICMP protocol with three vm's
    [Documentation]    To Check ICMP communication between VM's within the same network using remote-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[5]
    Delete All Security Group Rules    @{SECURITY_GROUP}[5]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[5]    direction=ingress    protocol=1    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[5]    direction=egress    protocol=1    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[5]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=1    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[5]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[5]
    Add Security Group To VM    @{IPV6_VM}[2]    @{SECURITY_GROUP}[2]
    ${des_ip_0}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[2]
    ${des_ip_11}=    Create List    ${des_ip_1}
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    ${des_ip_11}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    ${des_ip_21}    ping_should_succeed=False
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[2]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[5]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[2]    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[5]

Check Remote-SG Functionality for TCP protocol with three vm's
    [Documentation]    To Check TCP communication between VM's within the same network using remote-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=tcp    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[3]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{IPV6_VM}[2]    @{SECURITY_GROUP}[1]
    ${des_ip_0}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[2]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{port_Nub}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{port_Nub}[0]    nc_should_succeed=False
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[3]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[2]    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[3]

Check Remote-SG Functionality for UDP protocol with three vm's
    [Documentation]    To Check UDP communication between VM's within the same network using remote-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[4]
    Delete All Security Group Rules    @{SECURITY_GROUP}[4]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=udp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=udp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=ingress    protocol=udp    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=egress    protocol=udp    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[4]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[0]
    Add Security Group To VM    @{IPV6_VM}[2]    @{SECURITY_GROUP}[4]
    ${des_ip_0}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[2]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{NETWORKS_IPV6}[2]    ${des_ip_2}    @{port_Nub}[0]    additional_args=-u
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    @{NETWORKS_IPV6}[2]    ${des_ip_2}    @{port_Nub}[0]    additional_args=-u
    ...    nc_should_succeed=False
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[4]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[0]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[2]    @{SECURITY_GROUP}[4]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[4]

Check Remote-SG Functionality for ANY protocol with three vm's
    [Documentation]    To Check ANY Protocol communication between VM's within the same network using remote-sg
    Neutron Security Group Create    @{SECURITY_GROUP}[6]
    Delete All Security Group Rules    @{SECURITY_GROUP}[6]
    Neutron Security Group Create    @{SECURITY_GROUP}[7]
    Delete All Security Group Rules    @{SECURITY_GROUP}[7]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[6]    direction=ingress    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[6]    direction=egress    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[7]    direction=ingress    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[6]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[7]    direction=egress    ethertype=IPv6    remote_group_id=@{SECURITY_GROUP}[7]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[6]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[7]
    Add Security Group To VM    @{IPV6_VM}[2]    @{SECURITY_GROUP}[6]
    ${des_ip_0}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[2]
    ${des_ip_11}=    Create List    ${des_ip_1}
    ${des_ip_21}=    Create List    ${des_ip_2}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    ${des_ip_11}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    ${des_ip_21}    ping_should_succeed=False
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[0]    additional_args=-u
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[6]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[7]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[2]    @{SECURITY_GROUP}[6]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[6]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[7]

Check SG Functionality for TCP protocol within a given range
    [Documentation]    To Check TCP communication between VM's within a given port-range
    Neutron Security Group Create    @{SECURITY_GROUP1}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP1}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[0]    direction=ingress    protocol=tcp    ethertype=IPv6    port_range_max=40    port_range_min=24
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[0]    direction=egress    protocol=tcp    ethertype=IPv6    port_range_max=40    port_range_min=24
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP1}[0]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP1}[0]
    ${des_ip_0}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[1]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_0}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[2]    nc_should_succeed=False
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[0]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[0]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[0]

Check SG Functionality for UDP protocol within a given range
    [Documentation]    To Check TCP communication between VM's within a given port-range
    Neutron Security Group Create    @{SECURITY_GROUP1}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP1}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[1]    direction=ingress    protocol=udp    ethertype=IPv6    port_range_max=40    port_range_min=24
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[1]    direction=egress    protocol=udp    ethertype=IPv6    port_range_max=40    port_range_min=24
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP1}[1]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP1}[1]
    ${des_ip_0}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[1]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[1]    ${des_ip_0}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[1]    additional_args=-u
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[1]    ${des_ip_0}    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{port_Nub}[2]    additional_args=-u
    ...    nc_should_succeed=False
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[1]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[1]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[1]

Dynamic protocol change (ICMP to TCP)
    [Documentation]    To Check ICMP communication between VM's, then change the rules to tcp protocol and check for tcp communication
    Neutron Security Group Create    @{SECURITY_GROUP1}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP1}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[2]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[2]    direction=egress    protocol=icmp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP1}[2]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP1}[2]
    ${des_ip_1}=    Collect IPV6    @{IPV6_VM}[0]
    ${des_ip_2}=    Collect IPV6    @{IPV6_VM}[1]
    ${des_ip_11}=    Create List    ${des_ip_1}
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}
    Delete All Security Group Rules    @{SECURITY_GROUP1}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[2]    direction=ingress    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[2]    direction=egress    protocol=tcp    ethertype=IPv6
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_1}    @{NETWORKS_IPV6}[0]    ${des_ip_2}    @{port_Nub}[1]
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    ${des_ip_2}    ${des_ip_11}    ping_should_succeed=False
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[2]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[2]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[2]

Dynamic protocol change (ANY to ICMP)
    [Documentation]    To Check ICMP communication between VM's, then change the rules to tcp protocol and check for tcp communication
    Neutron Security Group Create    @{SECURITY_GROUP1}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP1}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[3]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[3]    direction=egress    protocol=icmp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP1}[3]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP1}[3]
    ${des_ip_1}=    Create List    @{IPV6_VM}[1]
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    ${des_ip_1}
    Delete All Security Group Rules    @{SECURITY_GROUP1}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[3]    direction=ingress    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[3]    direction=egress    protocol=tcp    ethertype=IPv6
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[1]    @{port_Nub}[1]
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    ${des_ip_1}    ping_should_succeed=False
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP}[3]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP}[3]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP}[3]

Create Vm with two NIC Cards
    [Documentation]    To Check if the vm's has been assigned with both the network's IP and to check for the communication to the dhcp and router
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Network    @{IPv4_NETWORKS_NAME}[1]
    Create SubNet    @{IPv4_NETWORKS_NAME}[1]    @{IPv4_SUBNETS_NAME}[1]    @{IPv4_SUBNETS_RANGE}[1]
    Create Network    @{NETWORKS_IPV6}[2]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=@{subnet_address_mode}[0] --ipv6-ra-mode=@{subnet_ra_mode}[0]
    Create SubNet    @{NETWORKS_IPV6}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]    ${net1_additional_args}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image fedora --flavor fedora --nic net-id=@{IPv4_NETWORKS_NAME}[1] --nic net-id=@{NETWORKS_IPV6}[2] --security-group @{sg_list}[0] --key-name vm_keys @{NET_1_VM_INSTANCES}[1]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${NET1_VM_IPS}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM UP Boot Status    ${vm}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${fed_user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${MAC_Line}=    Write Commands Until Expected Prompt    ip link show eth1 | awk '/ether/ {print $2}'    $
    ${MAC}    Split String    ${MAC_Line}    \n
    Log    @{MAC}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo cat <<EOF >ifcfg-eth1    >
    ${output}=    Write Commands Until Expected Prompt    BOOTPROTO=dhcpv6    >
    ${output}=    Write Commands Until Expected Prompt    DEVICE=eth1    >
    ${output}=    Write Commands Until Expected Prompt    ONBOOT=yes    >
    ${output}=    Write Commands Until Expected Prompt    TYPE=Ethernet    >
    ${output}=    Write Commands Until Expected Prompt    USERCTL=no    >
    ${output}=    Write Commands Until Expected Prompt    DHCPV6C=yes    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${output}=    Write Commands Until Expected Prompt    sudo cp ifcfg-eth1 /etc/sysconfig/network-scripts/.    $
    ${output}=    Write Commands Until Expected Prompt    sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo ifup eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping6 -c 10 2004:db9:cafe:e::2    $
    Log    ${output}
    Should Contain    ${output}    64 bytes from 2004:db9:cafe:e::2
    Write    exit
    [Teardown]    Run Keywords    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    ...    AND    Delete SubNet    @{SUBNETS_NAME}[2]
    ...    AND    Delete SubNet    @{IPv4_SUBNETS_NAME}[1]
    ...    AND    Delete Network    @{IPv4_NETWORKS_NAME}[1]
    ...    AND    Delete Network    @{NETWORKS_IPV6}[2]

Create IPv6 and IPv4 vm's with the same SG
    [Documentation]    Create two VM's for each under ipv6 and ipv4,
    ...    apply the same sg and check for the respective communication.
    ...    Then update the sg and check for the communication
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[5]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[5]    direction=egress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[5]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[5]    direction=egress    protocol=icmp
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Add Security Group To VM    @{IPV6_VM}[0]    @{SECURITY_GROUP1}[5]
    Add Security Group To VM    @{IPV6_VM}[1]    @{SECURITY_GROUP1}[5]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP1}[5]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP1}[5]
    ${des_ip_1}=    Create List    @{IPV6_VM}[1]
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    ${des_ip_1}
    ${des_ip_2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    Test Operations From IPV6_Vm Instance    @{IPv4_NETWORKS_NAME}[0]    @{NET_1_VM_INSTANCES}[0]    ${des_ip_2}
    Delete All Security Group Rules    @{SECURITY_GROUP1}[5]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[5]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[5]    direction=egress    protocol=icmp    ethertype=IPv6
    ${des_ip_1}=    Create List    @{IPV6_VM}[1]
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[0]    ${des_ip_1}
    ${des_ip_2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    Test Operations From IPV6_Vm Instance    @{IPv4_NETWORKS_NAME}[0]    @{NET_1_VM_INSTANCES}[0]    ${des_ip_2}    ping_should_succeed=False
    [Teardown]    Run Keywords    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP1}[5]
    ...    AND    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP1}[5]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[0]    @{SECURITY_GROUP1}[5]
    ...    AND    Remove Security Group From VM    @{IPV6_VM}[1]    @{SECURITY_GROUP1}[5]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP1}[5]

Migrating Server
    [Documentation]    Migrate a server from one compute node to another and check for the VM's communication
    Enable Live Migration In All Compute Nodes
    Neutron Security Group Create    @{SECURITY_GROUP1}[4]
    Delete All Security Group Rules    @{SECURITY_GROUP1}[4]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[4]    direction=ingress    protocol=icmp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[4]    direction=egress    protocol=icmp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[2]    @{SECURITY_GROUP1}[4]
    Add Security Group To VM    @{NET1-VM}[0]    @{SECURITY_GROUP1}[4]
    Server Migrate    @{IPV6_VM}[2]    additional_args=--live ${zone1}
    ${des_ip_1}=    Create List    @{IPV6_VM}[2]
    Test Operations From IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    @{NET1-VM}[0]    ${des_ip_1}
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[2]    @{SECURITY_GROUP1}[4]
    ...    AND    Remove Security Group From VM    @{NET1-VM}[0]    @{SECURITY_GROUP1}[4]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP1}[4]

Update SG during Migration
    [Documentation]    Migrate a server from one compute node to another and check for the VM's communication
    Server Migrate    @{IPV6_VM}[2]    additional_args=--live ${zone2}
    Delete All Security Group Rules    @{SECURITY_GROUP1}[4]
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[4]    direction=ingress    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    @{SECURITY_GROUP1}[4]    direction=egress    protocol=tcp    ethertype=IPv6
    Add Security Group To VM    @{IPV6_VM}[2]    @{SECURITY_GROUP1}[4]
    Add Security Group To VM    @{NET1-VM}[0]    @{SECURITY_GROUP1}[4]
    Test Netcat Operations Between IPV6_Vm Instance    @{NETWORKS_IPV6}[0]    @{IPV6_VM}[2]    @{NETWORKS_IPV6}[0]    @{NET1-VM}[0]    @{port_Nub}[0]
    [Teardown]    Run Keywords    Remove Security Group From VM    @{IPV6_VM}[2]    @{SECURITY_GROUP1}[4]
    ...    AND    Remove Security Group From VM    @{NET1-VM}[0]    @{SECURITY_GROUP1}[4]
    ...    AND    Delete SecurityGroup    @{SECURITY_GROUP1}[4]

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2

Delete Network Components
    [Documentation]    Delete Subnet and Networks of first Network
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS}
    [Teardown]    Run Keywords    Clear L2_Network
