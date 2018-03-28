*** Settings ***
Documentation     Test suite to permit and deny communication by using remote-sg and remote-ip
...               security groups with different protocols.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
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
@{ICMP_DENY_SUBNETS_RANGE}    10.0.0.0    20.0.0.0
@{CIDR_SUBNETS_RANGE}    30.0.0.0    40.0.0.0
${network1_vlan_id}    1235
@{port_Nub}       53    1328    80    443    143    993    389
...               1433    3306    110    995    3389    25    465
...               22    21
@{port}           1111    2222    234    1234    6    17    50
...               51    132    136
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
    [Tags]    run
    #TESTCASE ICMP
    Clear L2_Network
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
    [Tags]    run
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
    [Tags]    run
    Create Router    router_1
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}

Permit icmp 1 protocol
    [Documentation]    Permit icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny icmp 1 protocol
    [Documentation]    Deny icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    TCP connection timed out    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit ALL icmp protocol
    [Documentation]    Permit ALL icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny ALL icmp protocol
    [Documentation]    Deny icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    TCP connection timed out    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit ALL ICMP with remote-ip
    [Documentation]    Permit icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=1    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=1    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=1    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    ${des_ip_1}=    Create List    @{NET2_VM_IPS}
    Log    ${des_ip_1}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}
    Log    ${des_ip_2}
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[0]    ${des_ip_2}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny ALL ICMP with remote-ip
    [Documentation]    Deny icmp communication.
    [Tags]    re-run
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1    remote_ip_prefix=@{ICMP_DENY_SUBNETS_RANGE}[0]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=1    remote_ip_prefix=@{ICMP_DENY_SUBNETS_RANGE}[0]/24
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=1    remote_ip_prefix=@{ICMP_DENY_SUBNETS_RANGE}[1]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=1    remote_ip_prefix=@{ICMP_DENY_SUBNETS_RANGE}[1]/24
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    ${SECURITY_GROUP}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    ${SECURITY_GROUP2}
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    ${SECURITY_GROUP2}
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    ${SECURITY_GROUP2}
    ${des_ip}=    Create List    @{NET2_VM_IPS}[0]
    Log    ${des_ip}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[1]    ${des_ip}    ping_should_succeed=false
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    ${SECURITY_GROUP}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    ${SECURITY_GROUP2}
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    ${SECURITY_GROUP2}
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit ALL ICMP with remote-Security Group
    [Documentation]    Permit icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=1    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=1    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=1    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    ${des_ip_1}=    Create List    @{NET2_VM_IPS}
    Log    ${des_ip_1}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}
    Log    ${des_ip_2}
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[0]    ${des_ip_2}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny ALL ICMP with remote-Security Group
    [Documentation]    Deny icmp communication.
    [Tags]    re-run
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Create    ${SECURITY_GROUP3}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=1    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=1    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=1    remote_group_id=${SECURITY_GROUP}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    ${SECURITY_GROUP}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    ${SECURITY_GROUP2}
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    ${SECURITY_GROUP2}
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    ${SECURITY_GROUP2}
    ${des_ip}=    Create List    @{NET2_VM_IPS}[0]
    Log    ${des_ip}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[1]    ${des_ip}    ping_should_succeed=false
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    ${SECURITY_GROUP}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP3}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit ICMP type-code protocol
    [Documentation]    Permit ICMP type-code protocol
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=0.0.0.0/0
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny ICMP type-code protocol
    [Documentation]    Deny ICMP type-code protocol
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=0.0.0.0/0
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    TCP connection timed out    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit ICMP type-code with remote-ip
    [Documentation]    Permit icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    ${des_ip_1}=    Create List    @{NET2_VM_IPS}
    Log    ${des_ip_1}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}
    Log    ${des_ip_2}
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[0]    ${des_ip_2}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny ICMP type-code with remote-ip
    [Documentation]    Deny icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=@{ICMP_DENY_SUBNETS_RANGE}[0]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=@{ICMP_DENY_SUBNETS_RANGE}[0]/24
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=@{ICMP_DENY_SUBNETS_RANGE}[1]/24
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=@{ICMP_DENY_SUBNETS_RANGE}[1]/24
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    ${des_ip_1}=    Create List    @{NET2_VM_IPS}
    Log    ${des_ip_1}
    TCP connection timed out    l2_network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}
    Log    ${des_ip_2}
    TCP connection timed out    l2_network_2    @{NET2_VM_IPS}[0]    ${des_ip_2}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit ICMP type-code with remote-Security Group
    [Documentation]    Permit icmp communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    ${des_ip_1}=    Create List    @{NET2_VM_IPS}
    Log    ${des_ip_1}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}
    Log    ${des_ip_2}
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[0]    ${des_ip_2}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny ICMP type-code with remote-Security Group
    [Documentation]    Deny ICMP type-code with remote-Security Group.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Create    ${SECURITY_GROUP3}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_group_id=${SECURITY_GROUP3}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_group_id=${SECURITY_GROUP3}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_group_id=${SECURITY_GROUP3}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0    remote_group_id=${SECURITY_GROUP3}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    ${des_ip_1}=    Create List    @{NET2_VM_IPS}
    Log    ${des_ip_1}
    TCP connection refused    l2_network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}
    Log    ${des_ip_2}
    TCP connection refused    l2_network_2    @{NET2_VM_IPS}[0]    ${des_ip_2}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    #TESTCASE Permit other protocols
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit DNS protocol
    [Documentation]    Permit DNS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit HTTP protocol
    [Documentation]    Permit HTTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[2]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit HTTPS protocol
    [Documentation]    Permit HTTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=443    port_range_min=443
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=443    port_range_min=443
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[3]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit IMAP protocol
    [Documentation]    Permit IMAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=143    port_range_min=143
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=143    port_range_min=143
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[4]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit IMAPS protocol
    [Documentation]    Permit IMAPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=993    port_range_min=993
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=993    port_range_min=993
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[5]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit LDAP protocol
    [Documentation]    Permit LDAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=389    port_range_min=389
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=389    port_range_min=389
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[6]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit MS SQL protocol
    [Documentation]    Permit MS SQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=1433    port_range_min=1433
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=1433    port_range_min=1433
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[7]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit MYSQL protocol
    [Documentation]    Permit MYSQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3306    port_range_min=3306
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3306    port_range_min=3306
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[8]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit POP3 protocol
    [Documentation]    Permit POP3 protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=110    port_range_min=110
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=110    port_range_min=110
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[9]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit POP3S protocol
    [Documentation]    Permit POP3S protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=995    port_range_min=995
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=995    port_range_min=995
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[10]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit RDP protocol
    [Documentation]    Permit RDP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3389    port_range_min=3389
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3389    port_range_min=3389
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[11]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SMTP protocol
    [Documentation]    Permit SMTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=25    port_range_min=25
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=25    port_range_min=25
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[12]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SMTPS protocol
    [Documentation]    Permit SMTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=465    port_range_min=465
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=465    port_range_min=465
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[13]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SSH protocol
    [Documentation]    Permit SSH protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    ${net_id}=    Get Net Id    l2_network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit FTP protocol
    [Documentation]    Permit FTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=21    port_range_min=21
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=21    port_range_min=21
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port_Nub}[15]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    #TESTCASE Permit other protocols with remote-ip
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit DNS protocol with remote-ip
    [Documentation]    Permit DNS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit HTTP protocol with remote-ip
    [Documentation]    Permit HTTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[2]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit HTTPS protocol with remote-ip
    [Documentation]    Permit HTTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=443    port_range_min=443    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=443    port_range_min=443    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=443    port_range_min=443    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=443    port_range_min=443    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[3]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit IMAP protocol with remote-ip
    [Documentation]    Permit IMAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=143    port_range_min=143    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=143    port_range_min=143    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=143    port_range_min=143    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=143    port_range_min=143    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[4]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit IMAPS protocol with remote-ip
    [Documentation]    Permit IMAPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=993    port_range_min=993    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=993    port_range_min=993    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=993    port_range_min=993    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=993    port_range_min=993    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[5]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit LDAP protocol with remote-ip
    [Documentation]    Permit LDAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=389    port_range_min=389    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=389    port_range_min=389    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=389    port_range_min=389    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=389    port_range_min=389    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[6]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit MS SQL protocol with remote-ip
    [Documentation]    Permit MS SQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[7]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit MYSQL protocol with remote-ip
    [Documentation]    Permit MYSQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[8]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit POP3 protocol with remote-ip
    [Documentation]    Permit POP3 protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=110    port_range_min=110    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=110    port_range_min=110    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=110    port_range_min=110    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=110    port_range_min=110    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[9]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit POP3S protocol with remote-ip
    [Documentation]    Permit POP3S protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=995    port_range_min=995    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=995    port_range_min=995    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=995    port_range_min=995    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=995    port_range_min=995    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[10]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit RDP protocol with remote-ip
    [Documentation]    Permit RDP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[11]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SMTP protocol with remote-ip
    [Documentation]    Permit SMTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=25    port_range_min=25    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=25    port_range_min=25    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=25    port_range_min=25    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=25    port_range_min=25    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[12]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SMTPS protocol with remote-ip
    [Documentation]    Permit SMTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=465    port_range_min=465    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=465    port_range_min=465    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=465    port_range_min=465    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=465    port_range_min=465    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[13]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    #TESTCASE Permit other protocols with remote-SG
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit DNS protocol with remote-Security Group
    [Documentation]    Permit DNS protocol communication.
    [Tags]    run
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[0]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${vm}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit HTTP protocol with remote-Security Group
    [Documentation]    Permit HTTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[2]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit HTTPS protocol with remote-Security Group
    [Documentation]    Permit HTTPS protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[3]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit IMAP protocol with remote-Security Group
    [Documentation]    Permit IMAP protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[4]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit IMAPS protocol with remote-Security Group
    [Documentation]    Permit IMAPS protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[5]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit LDAP protocol with remote-Security Group
    [Documentation]    Permit LDAP protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[6]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit MS SQL protocol with remote-Security Group
    [Documentation]    Permit MS SQL protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[7]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit MYSQL protocol with remote-Security Group
    [Documentation]    Permit MYSQL protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[8]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit POP3 protocol with remote-Security Group
    [Documentation]    Permit POP3 protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[9]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit POP3S protocol with remote-Security Group
    [Documentation]    Permit POP3S protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[10]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit RDP protocol with remote-Security Group
    [Documentation]    Permit RDP protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[11]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SMTP protocol with remote-Security Group
    [Documentation]    Permit SMTP protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[12]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Permit SMTPS protocol with remote-Security Group
    [Documentation]    Permit SMTPS protocol communication.
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
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{port_Nub}[13]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    #TESTCASE Deny other protocol
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

DNS protocol
    [Documentation]    Deny DNS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny HTTP protocol
    [Documentation]    Deny HTTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny HTTPS protocol
    [Documentation]    Deny HTTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=443    port_range_min=443
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=443    port_range_min=443
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny IMAP protocol
    [Documentation]    Deny IMAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=143    port_range_min=143
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=143    port_range_min=143
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny IMAPS protocol
    [Documentation]    Deny IMAPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=993    port_range_min=993
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=993    port_range_min=993
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny LDAP protocol
    [Documentation]    Deny LDAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=389    port_range_min=389
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=389    port_range_min=389
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny MS SQL protocol
    [Documentation]    Deny MS SQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=1433    port_range_min=1433
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=1433    port_range_min=1433
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny MYSQL protocol
    [Documentation]    Deny MYSQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3306    port_range_min=3306
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3306    port_range_min=3306
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny POP3 protocol
    [Documentation]    Deny POP3 protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=110    port_range_min=110
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=110    port_range_min=110
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny POP3S protocol
    [Documentation]    Deny POP3S protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=995    port_range_min=995
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=995    port_range_min=995
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny RDP protocol
    [Documentation]    Deny RDP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3389    port_range_min=3389
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3389    port_range_min=3389
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny SMTP protocol
    [Documentation]    Deny SMTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=25    port_range_min=25
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=25    port_range_min=25
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny SMTPS protocol
    [Documentation]    Deny SMTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=465    port_range_min=465
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=465    port_range_min=465
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny SSH protocol
    [Documentation]    Deny SSH protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Ping From DHCP Should Not Succeed    l2_network_1    @{NET1_VM_IPS}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    #TESTCASE Deny other protocol with remote-ip
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny DNS protocol with remote-ip
    [Documentation]    Deny DNS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny HTTP protocol with remote-ip
    [Documentation]    Deny HTTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny HTTPS protocol with remote-ip
    [Documentation]    Deny HTTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=443    port_range_min=443    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=443    port_range_min=443    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=443    port_range_min=443    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=443    port_range_min=443    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny IMAP protocol with remote-ip
    [Documentation]    Deny IMAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=143    port_range_min=143    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=143    port_range_min=143    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=143    port_range_min=143    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=143    port_range_min=143    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny IMAPS protocol with remote-ip
    [Documentation]    Deny IMAPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=993    port_range_min=993    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=993    port_range_min=993    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=993    port_range_min=993    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=993    port_range_min=993    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny LDAP protocol with remote-ip
    [Documentation]    Deny LDAP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=389    port_range_min=389    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=389    port_range_min=389    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=389    port_range_min=389    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=389    port_range_min=389    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny MS SQL protocol with remote-ip
    [Documentation]    Deny MS SQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=1433    port_range_min=1433    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny MYSQL protocol with remote-ip
    [Documentation]    Deny MYSQL protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=3306    port_range_min=3306    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny POP3 protocol with remote-ip
    [Documentation]    Deny POP3 protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=110    port_range_min=110    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=110    port_range_min=110    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=110    port_range_min=110    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=110    port_range_min=110    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny POP3S protocol with remote-ip
    [Documentation]    Deny POP3S protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=995    port_range_min=995    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=995    port_range_min=995    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=995    port_range_min=995    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=995    port_range_min=995    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny RDP protocol with remote-ip
    [Documentation]    Deny RDP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=3389    port_range_min=3389    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny SMTP protocol with remote-ip
    [Documentation]    Deny SMTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=25    port_range_min=25    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=25    port_range_min=25    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=25    port_range_min=25    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=25    port_range_min=25    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny SMTPS protocol with remote-ip
    [Documentation]    Deny SMTPS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=465    port_range_min=465    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=465    port_range_min=465    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=465    port_range_min=465    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=465    port_range_min=465    remote_ip_prefix=@{SUBNETS_RANGE}[1]
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

Deny SSH protocol with remote-ip
    [Documentation]    Deny SSH protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22    remote_ip_prefix=@{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=22    port_range_min=22    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=22    port_range_min=22    remote_ip_prefix=@{SUBNETS_RANGE}[1]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP2}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    ${SECURITY_GROUP}
    Ping From DHCP Should Not Succeed    l2_network_1    @{NET1_VM_IPS}[0]
    Ping From DHCP Should Not Succeed    l2_network_2    @{NET2_VM_IPS}[0]
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP2}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP2}
    Delete SecurityGroup    ${SECURITY_GROUP}
    #TESTCASE Deny other protocol with remote-SG
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear Security Group

Deny DNS protocol with remote-Security Group
    [Documentation]    Deny DNS protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Delete All Security Group Rules    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${SECURITY_GROUP}
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

Deny HTTP protocol with remote-Security Group
    [Documentation]    Deny HTTP protocol communication.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Create    ${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${SECURITY_GROUP2}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP2}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${SECURITY_GROUP}
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
    ...    AND    Clear L2_Network

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
