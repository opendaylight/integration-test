*** Settings ***
Documentation     Test suite to permit and deny communication by using port range
...               with different protocols.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           SSHLibrary    #Test Teardown    Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/DataModels.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/OpenStackOperations_legacy.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../variables/netvirt/Variables.robot

*** Variables ***
${net1}           l2_network_1
${SECURITY_GROUP}    sg-connectivity
${SECURITY_GROUP2}    sg-connectivity2
${SECURITY_GROUP3}    default-sg
${SG_DHCP}        sg_dhcp
@{NETWORKS_NAME}    l2_network_11    l2_network_22
@{SUBNETS_NAME}    l2_subnet_11    l2_subnet_22
@{NET_1_VM_GRP_NAME}    NETWORK1-VM
@{NET_2_VM_GRP_NAME}    NETWORK2-VM
@{NET_1_VM_INSTANCES}    NETWORK1-VM-1    NETWORK1-VM-2
@{NET_2_VM_INSTANCES}    NETWORK2-VM-1    NETWORK2-VM-2
@{NET_1_VM_INSTANCES_MAX}    NETWORK1-VM
@{NET_2_VM_INSTANCES_MAX}    NETWORK2-VM
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    2001:db8:cafe:e::/64    100.64.2.0/24    192.168.90.0/24
@{ICMP_DENY_SUBNETS_RANGE}    10.0.0.0    30.0.0.0
@{CIDR_SUBNETS_RANGE}    30.0.0.0    40.0.0.0
${network1_vlan_id}    1235
@{port_Nub}       53    1328    80    443    143    993    389
...               1433    3306    110    995    3389    25    465
...               22    21
@{port}           1111    2222    234    1234    6    17    50
...               51    132    136    22
@{uriOutput}      "admin-state-up":
${password}       cubswin:)
${user}           cirros
@{NETWORKS_IPV6}    NET1_IPV6
@{SUBNETS_IPV6}    SUBNET1_IPV6
@{IPV6_VM}        VM1_IPV6    VM2_IPV6
@{SUBNETS_CIDR}    2001:db8:0:2::/64
${NET1_ADDR_POOL}    --allocation-pool start=2001:db8:0:2::2,end=2001:db8:0:2:ffff:ffff:ffff:fffe
@{ROUTERS}        router1    router2

*** Test Cases ***
Create Network1 Components
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    [Tags]    re-run
    #TESTCASE ICMP
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    #Neutron Security Group Create    ${SG_DHCP}
    #Delete All Security Group Rules    ${SG_DHCP}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    sg=@{sg_list}[0]    min=2    max=2    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
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
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{sg_list}[0]
    #${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    #: FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    #\    Neutron Security Group Rule Create    ${SG_DHCP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    ...    # remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32

Create Network2 Components
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    [Tags]    re-run
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_VM_GRP_NAME}    sg=@{sg_list}[0]    min=2    max=2    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_2_VM_INSTANCES}
    ${NET2_VM_IPS}    ${NET2_DHCP_IP}    Collect VM IP Addresses    false    @{NET_2_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_2_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET2_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET2_VM_IPS}
    Set Suite Variable    ${NET2_DHCP_IP}
    Should Not Contain    ${NET2_VM_IPS}    None
    Should Not Contain    ${NET2_DHCP_IP}    None
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{sg_list}[0]
    #${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    #: FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    #\    Neutron Security Group Rule Create    ${SG_DHCP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    ...    # remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32

Attach Router
    [Documentation]    Attach router Between Network1 and Network2.
    [Tags]    re-run
    Create Router    router_1
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}

Deny HTTPS protocol with remote-Security Group
    [Documentation]    Deny HTTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=443    port_range_min=443    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=443    port_range_min=443    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=443    port_range_min=443    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=443    port_range_min=443    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny IMAP protocol with remote-Security Group
    [Documentation]    Deny IMAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=143    port_range_min=143    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=143    port_range_min=143    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=143    port_range_min=143    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=143    port_range_min=143    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny IMAPS protocol with remote-Security Group
    [Documentation]    Deny IMAPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=993    port_range_min=993    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=993    port_range_min=993    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=993    port_range_min=993    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=993    port_range_min=993    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny LDAP protocol with remote-Security Group
    [Documentation]    Deny LDAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=389    port_range_min=389    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=389    port_range_min=389    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=389    port_range_min=389    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=389    port_range_min=389    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny MS SQL protocol with remote-Security Group
    [Documentation]    Deny MS SQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny MYSQL protocol with remote-Security Group
    [Documentation]    Deny MYSQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny POP3 protocol with remote-Security Group
    [Documentation]    Deny POP3 protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=110    port_range_min=110    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=110    port_range_min=110    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=110    port_range_min=110    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=110    port_range_min=110    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny POP3S protocol with remote-Security Group
    [Documentation]    Deny POP3S protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=995    port_range_min=995    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=995    port_range_min=995    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=995    port_range_min=995    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=995    port_range_min=995    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny RDP protocol with remote-Security Group
    [Documentation]    Deny RDP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny SMTP protocol with remote-Security Group
    [Documentation]    Deny SMTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=25    port_range_min=25    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=25    port_range_min=25    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=25    port_range_min=25    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=25    port_range_min=25    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny SMTPS protocol with remote-Security Group
    [Documentation]    Deny SMTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=465    port_range_min=465    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=465    port_range_min=465    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=465    port_range_min=465    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=465    port_range_min=465    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny SSH protocol with remote-Security Group
    [Documentation]    Deny SSH protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Ping From DHCP Should Not Succeed    l2_network_1    @{NET1_VM_IPS}[0]
    Ping From DHCP Should Not Succeed    l2_network_2    @{NET2_VM_IPS}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    #TESTCASE TCP Protocol
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit tcp protocol with port 1111
    [Documentation]    permit tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=1111    port_range_min=1111
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=1111    port_range_min=1111
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny tcp protocol with port 1111
    [Documentation]    permit tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=1111    port_range_min=1111
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=1111    port_range_min=1111
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit tcp protocol with port 2222
    [Documentation]    permit tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=2222    port_range_min=2222
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=2222    port_range_min=2222
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[1]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny tcp protocol with port 2222
    [Documentation]    permit tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=2222    port_range_min=2222
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=2222    port_range_min=2222
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit CIDR for tcp protocol
    [Documentation]    permit cidr for tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny CIDR for tcp protocol
    [Documentation]    Deny cidr for tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit Remote-sg for tcp protocol
    [Documentation]    permit remote-sg for tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny Remote-sg for tcp protocol
    [Documentation]    permit remote-sg for tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit udp protocol with port 1111
    [Documentation]    permit udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=1111    port_range_min=1111    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=1111    port_range_min=1111    protocol=udp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1111    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny udp protocol with port 1111
    [Documentation]    deny udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=1111    port_range_min=1111    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=1111    port_range_min=1111    protocol=udp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=2222    additional_args=-u
    ...    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit udp protocol with port 2222-3333
    [Documentation]    permit udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=3333    port_range_min=2222    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=3333    port_range_min=2222    protocol=udp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=2222    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny udp protocol with port 2222-3333
    [Documentation]    permit udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=3333    port_range_min=2222    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=3333    port_range_min=2222    protocol=udp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1111    additional_args=-u
    ...    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit CIDR for udp protocol
    [Documentation]    permit cidr for udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=udp    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=udp    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=udp    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=udp    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny CIDR for udp protocol
    [Documentation]    Deny cidr for udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=udp
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=udp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit Remote-sg for udp protocol
    [Documentation]    permit remote-sg for udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny Remote-sg for udp protocol
    [Documentation]    deny remote-sg for udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit 0 protocol
    [Documentation]    permit tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=0
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=0    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=0
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit tcp protocol
    [Documentation]    permit tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=6
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[4]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny tcp protocol
    [Documentation]    Deny tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=6
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit udp protocol
    [Documentation]    permit udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=17
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=17
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[5]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny udp protocol
    [Documentation]    permit udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=17
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny esp protocol
    [Documentation]    permit esp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=50    port_range_min=50    protocol=6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=50    port_range_min=50    protocol=6
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit ah protocol
    [Documentation]    permit ah communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=51    port_range_min=51    protocol=6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=51    port_range_min=51    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[7]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny ah protocol
    [Documentation]    deny ah communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=51    port_range_min=51    protocol=6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=51    port_range_min=51    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SCTP protocol
    [Documentation]    permit SCTP communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=132    port_range_min=132    protocol=6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=132    port_range_min=132    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[8]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny SCTP protocol
    [Documentation]    deny SCTP communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=132    port_range_min=132    protocol=6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=132    port_range_min=132    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit UDPLITE protocol
    [Documentation]    permit udplite communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=136    port_range_min=136    protocol=6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=136    port_range_min=136    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[9]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny UDPLITE protocol
    [Documentation]    deny udplite communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=136    port_range_min=136    protocol=6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=136    port_range_min=136    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit CIDR for udp Other protocols
    [Documentation]    permit cidr for udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=17    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=17    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=17    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=17    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny CIDR for udp Other protocols
    [Documentation]    Deny cidr for udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=17
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=17
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit Remote-sg for udp Other protocols
    [Documentation]    permit remote-sg for udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny Remote-sg for udp Other protocols
    [Documentation]    deny remote-sg for udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit tcp all protocol
    [Documentation]    permit all tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=6
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[4]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny tcp all protocol
    [Documentation]    Deny tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=6
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit CIDR for tcp all protocol
    [Documentation]    permit cidr for tcp all communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=6    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=6    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=6    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=6    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny CIDR for tcp all protocol
    [Documentation]    Deny cidr for tcp all communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=6
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=6
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit Remote-sg for tcp all protocol
    [Documentation]    permit remote-sg for tcp all communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=6    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=6    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny Remote-sg for tcp all protocol
    [Documentation]    Deny remote-sg for tcp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=6    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=6    remote_group_id=${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit udp all protocol
    [Documentation]    permit udp all communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=17
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=17
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[5]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny udp all protocol
    [Documentation]    permit udp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=17
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit CIDR for udp all protocol
    [Documentation]    permit cidr for udp all communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=17    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=17    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[0]/24
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=17    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=17    port_range_max=65535    port_range_min=1    remote_ip_prefix=@{CIDR_SUBNETS_RANGE}[1]/24
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny CIDR for udp all protocol
    [Documentation]    Deny cidr for udp all communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=17
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=17
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit Remote-sg for udp all protocol
    [Documentation]    permit remote-sg for udp all communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny Remote-sg for udp all protocol
    [Documentation]    deny remote-sg for udp all communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_group_id=${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SSH protocol with remote-ip
    [Documentation]    Permit SSH protocol communication.
    [Tags]    re-run
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    ${net_id}=    Get Net Id    l2_network_11
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET2_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SSH protocol with remote-Security Group
    [Documentation]    Permit SSH protocol communication.
    [Tags]    re-run
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    ${net_id}=    Get Net Id    l2_network_11
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET2_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit icmpv6 protocol
    [Documentation]    Permit icmpv6 communication.
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_IPV6}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS[0]}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_IPV6}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    ethertype=IPv6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=58    ethertype=IPv6
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=58    ethertype=IPv6
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${IPV6_VM}    sg=${SECURITY_GROUP}    min=1    max=1    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{IPV6_VM}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    60s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{IPV6_VM}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{IPV6_VM}
    Log    ${VM_IP_NETV6}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${IPV6_VM}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}=    Write Commands Until Expected Prompt    ping6 -c 3 @{VM_IPS}[1]    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    Should Contain    ${output}    64 bytes
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{IPV6_VM}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_IPV6}[0]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    @{SUBNETS_IPV6}[0]
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Deny icmpv6 protocol
    [Documentation]    Deny icmpv6 communication.
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_IPV6}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS[0]}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_IPV6}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    ethertype=IPv6
    Create Vm Instances    @{NETWORKS_IPV6}[0]    ${IPV6_VM}    sg=${SECURITY_GROUP}    min=1    max=1    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{IPV6_VM}
    \    Poll VM Is ACTIVE    ${vm}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS_IPV6}    ${SUBNETS_CIDR}
    ${prefix_net10}=    Replace String    ${SUBNETS_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    Log    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5x    60s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${prefix_net10}    @{IPV6_VM}
    ${VM_IP_NETV6}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    @{IPV6_VM}
    Log    ${VM_IP_NETV6}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NETV6}
    Log Many    Obtained IPs    ${VM_IPS}
    ${LOOP_COUNT}    Get Length    ${IPV6_VM}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Log    ${VM_IP_NETV6}
    Set Suite Variable    ${VM_IP_NETV6}
    Should Not Contain    ${VM_IP_NETV6}    None
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    @{NETWORKS_IPV6}[0]
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping6 -c 3 @{VM_IPS}[1]    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{IPV6_VM}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_IPV6}[0]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    @{SUBNETS_IPV6}[0]
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Run Keywords    Clear L2_Network

*** Keywords ***
Clear Security Group
    [Documentation]    This test case will clear all Security Group From
    ...    instance.
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    : FOR    ${sg}    IN    @{sgs}
    \    Run    openstack server remove security group @{NET_1_VM_INSTANCES}[0] ${sg}
    \    Run    openstack server remove security group @{NET_1_VM_INSTANCES}[1] ${sg}
    \    Run    openstack server remove security group @{NET_2_VM_INSTANCES}[0] ${sg}
    \    Run    openstack server remove security group @{NET_2_VM_INSTANCES}[1] ${sg}
    \    Run    openstack security group delete ${sg}
