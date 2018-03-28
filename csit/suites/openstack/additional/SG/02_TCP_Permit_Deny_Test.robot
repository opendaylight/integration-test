*** Settings ***
Documentation     Test suite to verify security groups TCP Permit/Deny Functionality, including negative tests.
...               These test cases are not so relevant for transparent mode, so each test case will be tagged with
...               "skip_if_transparent" to allow any underlying keywords to return with a PASS without risking
...               a false failure. The real value of this suite will be in stateful mode.
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

*** Variables ***
@{SECURITY_GROUP}    sg-remote    sg_1    sg_2    sg_dhcp
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{NET_2_VM_INSTANCES}    MyThirdInstance_3
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24

*** Test Cases ***
Create Network1 Components
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=@{SECURITY_GROUP}[3]    min=1    max=1    image=cirros
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
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32

TCP Communication Security Group Changes_1
    [Documentation]    Check that dynamic changes in security group are reflected
    ...    Permit to Deny
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=1111
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=1111    nc_should_succeed=False
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication Security Group Changes_2
    [Documentation]    Check that dynamic changes in security group are reflected
    ...    Deny to Permit
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=1111    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=1111
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication Security Group Rule Changes_3
    [Documentation]    Check that dynamic changes in security group Rules are reflected
    ...    Permit to Deny
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=1111
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=1111    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication Security Group Rules Changes_4
    [Documentation]    Check that dynamic changes in security group rules are reflected
    ...    Deny to Permit
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=1111    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=1111
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network
