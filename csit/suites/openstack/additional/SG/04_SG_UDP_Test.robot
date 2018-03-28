*** Settings ***
Documentation     Test suite to verify security groups basic and advanced functionalities of UDP, including negative tests.
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
@{SECURITY_GROUP}    sg-remote    sg_1    sg_2    sg_3    sg_dhcp
@{NETWORKS_NAME}    network_1    network_2    network_3
@{NETWORKS_IPV6}    NET1_IPV6
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2    l2_subnet_3
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{NET_2_VM_INSTANCES}    MyThirdInstance_3
@{NET_3_VM_INSTANCES}    VM1    VM2    VM3
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    50.0.0.0/24
${password}    cubswin:)
${user}    cirros
${Test1}    Data1
${Test2}    Data2
${Test3}    Data3

*** Test Cases ***


Create Zone
    [Documentation]    Create Availabilityzone create for test suite
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Create Network1 Components
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

    Neutron Security Group Create    @{SECURITY_GROUP}[4]
    Delete All Security Group Rules    @{SECURITY_GROUP}[4]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=@{SECURITY_GROUP}[4]    min=1    max=1    image=cirros    flavor=cirros

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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32



Create Network2 Components
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]

    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_VM_INSTANCES}    sg=@{SECURITY_GROUP}[4]    min=1    max=1    image=cirros    flavor=cirros

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
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32


UDP Communication with Two SG udp egress/ingress
    [Documentation]    Check UDP Communication with ingress/egress udp on SG1
    ...    Ingress/egress rule udp on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication with Custom SG udp egress/ingress and Default SG
    [Documentation]    Check UDP Communication with ingress/egress udp on SG1
    ...    and Default SG ,create VM1 using SG1 and VM2 using default SG
    ...    add SG1 to VM2 Check UDP communication then remove SG1 from VM2
    ...    Check UDP communication

    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]

    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication with Two SG udp egress/ingress and Protocol 17
    [Documentation]    Check UDP Communication with ingress/egress udp on SG1
    ...    Ingress/egress rule with protocol number 17 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=17    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication with Two SG udp egress/ingress and ANY Rule
    [Documentation]    Check UDP Communication with ingress/egress udp on SG1
    ...    Ingress/egress ANY rule on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs



UDP Communication with Two SG udp egress/ingress with port 1328
    [Documentation]    Check UDP Communication with ingress/egress udp with port 1328 on SG1
    ...    Ingress/egress rule udp with port 1328 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check UDP communication then remove SG2 from the VM's check the UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs

UDP Communication with Two SG udp egress/ingress with port 1328 and port range 1000:2000
    [Documentation]    Check UDP Communication with ingress/egress udp with port 1328 on SG1
    ...    Ingress/egress rule udp with port range 1000:2000 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check UDP communication then remove SG2 from the VM's check the UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication with Two SG udp egress/ingress with port range 1000:2000
    [Documentation]    Check UDP Communication with ingress/egress udp with port range 1000:2000 on SG1
    ...    Ingress/egress rule udp with port range 1000:2000 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check UDP communication then remove SG2 from the VM's check the UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]


    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication with Two SG udp egress/ingress with port range 1000:2000 and port 1328
    [Documentation]    Check UDP Communication with ingress/egress udp with port range 1000:2000 on SG1
    ...    Ingress/egress rule udp with port 1328 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check UDP communication then remove SG2 from the VM's check the UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication with Three SG udp egress/ingress with Remote CIDR
    [Documentation]    Create 3 SG's(SG1,SG2,SG3) and delete all the rules
    ...    Create VM1 using SG1 and VM2 using SG3, in SG1 add udp ingress/egress rules
    ...    with Remote CIDR as VM2 similarly in SG2 and SG2 add udp ingress/egress rules
    ...    with Remote CIDR as VM1 add SG2 to the VM1 Check UDP communication from VM1 to VM2
    ...    then remove SG2 from the VM1 check the UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication with Three SG udp egress/ingress Custom port 1328 with Remote CIDR
    [Documentation]    Create 3 SG's(SG1,SG2,SG3) and delete all the rules
    ...    Create VM1 using SG1 and VM2 using SG3, in SG1 add udp ingress/egress rules udp port 1328
    ...    with Remote CIDR as VM2 similarly in SG2 and SG2 add udp ingress/egress rules udp port 1328
    ...    with Remote CIDR as VM1 add SG2 to the VM1 Check UDP communication from VM1 to VM2
    ...    then remove SG2 from the VM1 check the UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs

UDP Communication with Three SG udp egress/ingress port Range with Remote CIDR
    [Documentation]    Create 3 SG's(SG1,SG2,SG3) and delete all the rules
    ...    Create VM1 using SG1 and VM2 using SG3, in SG1 add udp ingress/egress rules udp port range 1000:2000
    ...    with Remote CIDR as VM2 similarly in SG2 and SG2 add udp ingress/egress rules udp port range 1000:2000
    ...    with Remote CIDR as VM1 add SG2 to the VM1 Check UDP communication from VM1 to VM2
    ...    then remove SG2 from the VM1 check the UDP communication

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]


    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs




UDP Communication with Two SG udp egress/ingress Remote SG
    [Documentation]    Check UDP Communication using Remote SG
    ...    create SG1 and SG2,make SG1 remote SG as SG2, SG2 remote SG as SG1
    ...    Create two VM's with Remote SG Check udp communication between them

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs

UDP Communication with Two SG udp egress/ingress Remote SG with custom port
    [Documentation]    Check UDP Communication using Remote SG
    ...    create SG1 and SG2 with udp port 1328,make SG1 remote SG as SG2, SG2 remote SG as SG1
    ...    Create two VM's with Remote SG Check udp communication between them

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication with Two SG udp egress/ingress Remote SG with custom port range
    [Documentation]    Check UDP Communication using Remote SG
    ...    create SG1 and SG2 with udp port range 1000:2000,make SG1 remote SG as SG2, SG2 remote SG as SG1
    ...    Create two VM's with Remote SG Check udp communication between them
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs

UDP Communication From VM to DHCP Dynamic changes in SG(Addition)
    [Documentation]    UDP communication From VM to DHCP and check the result

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]

    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} nc -u -l -p 1328 >> test.txt &    >
    Log    ${output}

    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -u @{NET2_DHCP_IP}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}


    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    >
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test1}
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs


UDP Communication From DHCP to VM Dynamic changes in SG(Addition)
    [Documentation]    UDP communication From DHCP to VM and check the result

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}

    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test1}
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs

UDP Communication From DHCP to VM with port as 1328 Dynamic changes in SG(Addition)
    [Documentation]    UDP communication From DHCP to VM with port as 1328 and check the result

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=udp
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}

    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test1}
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs

UDP Communication From VM to DHCP with port as 1328 Dynamic changes in SG(Addition)
    [Documentation]    UDP communication From VM to DHCP with port as 1328 communication and check the result

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=udp
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} nc -u -l -p 1328 >> test.txt &    >
    Log    ${output}

    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -u @{NET2_DHCP_IP}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}


    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    >
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test1}
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs

UDP Communication From VM to DHCP and DHCP to VM Dynamic changes in SG(Addition)
    [Documentation]    UDP communication From VM to DHCP and DHCP to VM and check the result

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} nc -u -l -p 1328 >> test.txt &    >
    Log    ${output}

    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -u @{NET2_DHCP_IP}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}

    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    >
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test1}


    ${devstack_conn_id_3}=    Get ControlNode Connection
    ${devstack_conn_id_4}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_3}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_4}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test2} ${crtl_n}

    Switch Connection    ${devstack_conn_id_3}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test2}

    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group
    ...   AND    Get Test Teardown Debugs

Two SG's UDP Communication From DHCP to VM Dynamic changes in SG(Addition)
    [Documentation]   UDP communication By Adding two SG's one after other and check the result

    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp

    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}     @{SECURITY_GROUP}[1]
    \    Add Security Group To VM    ${VmElement}     @{SECURITY_GROUP}[2]

    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}

    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test1}

    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]

    ${devstack_conn_id_3}=    Get ControlNode Connection
    ${devstack_conn_id_4}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_3}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_4}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test2} ${crtl_n}

    Switch Connection    ${devstack_conn_id_3}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test2}


    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Sleep    10s
    ${devstack_conn_id_5}=    Get ControlNode Connection
    ${devstack_conn_id_6}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_5}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_6}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test3} ${crtl_n}

    Switch Connection    ${devstack_conn_id_5}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Not Contain    ${server_output}    ${Test3}

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear L2_Network
    ...   AND    Get Test Teardown Debugs


Two SG's at the same time UDP Communication From DHCP to VM Dynamic changes in SG(Addition)
    [Documentation]    UDP communication By Adding two SG's at the same time and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Create Vm Instances    network_1    ${NET_2_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2]
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
    ${LOOP_COUNT}    Get Length    ${NET2_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}     @{SECURITY_GROUP}[0]
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}

    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test1}

    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[1]

    ${devstack_conn_id_3}=    Get ControlNode Connection
    ${devstack_conn_id_4}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_3}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_4}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test2} ${crtl_n}

    Switch Connection    ${devstack_conn_id_3}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Contain    ${server_output}    ${Test2}


    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Remove Security Group From VM    ${VmElement}    @{SECURITY_GROUP}[2]

    Sleep    10s
    ${devstack_conn_id_5}=    Get ControlNode Connection
    ${devstack_conn_id_6}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_5}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_6}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test3} ${crtl_n}

    Switch Connection    ${devstack_conn_id_5}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Should Not Contain    ${server_output}    ${Test3}


    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network   network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear L2_Network

Remove UDP and Add SG2 without Rules During UDP Communication Dynamic changes in SG(Addition)
    [Documentation]    Remove add SG2 Without rules Security Group during UDP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone1}
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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nohup nc -u -l -p 1111 & ${crtl_n}    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -u @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}


    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt          cat nohup.out        $
    ${server_output_1}=    Read
    Should Contain    ${server_output}    ${Test1}


    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[1]
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add security group ${VmElement} @{SECURITY_GROUP}[2]

    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}
    Write    ${crtl_c}
    ${client_output}=    Read
    Log   ${client_output}
    Exit From Vm Console

    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt          cat nohup.out        $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test2}

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network   network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear L2_Network

Remove SG2 and Add UDP without Rules During UDP Communication Dynamic changes in SG(Addition)
    [Documentation]    Remove SG2 and Add Security Group during UDP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]    additional_args=--availability-zone ${zone1}
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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nohup nc -u -l -p 1111 & ${crtl_n}    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -u @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}


    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Should Not Contain    ${server_output}    ${Test1}


    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[2]
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add security group ${VmElement} @{SECURITY_GROUP}[1]

    Sleep    10s
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Contain X Times    ${stdout}    udp    2

    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}
    Write    ${crtl_c}
    ${client_output}=    Read
    Log   ${client_output}
    Exit From Vm Console

    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt          cat nohup.out        $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test2}

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network   network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear L2_Network

Only UDP Add and Remove Rules Communication Dynamic changes in SG(Addition)
    [Documentation]    Add and Remove Security Group during UDP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    @{SECURITY_GROUP}[0]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nohup nc -u -l -p 1111 & ${crtl_n}    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -u @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}

    #: FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    #\    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[1]
    #: FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]

    Sleep    10s
    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}
    Write    ${crtl_c}
    ${client_output}=    Read
    Log   ${client_output}
    Exit From Vm Console

    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt          cat nohup.out        $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test2}
    Should Contain    ${server_output}    ${Test1}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network   network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Only UDP Remove and Add Communication Dynamic changes in SG(Addition)
    [Documentation]    Remove and Add Security Group during UDP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone1}
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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    @{SECURITY_GROUP}[0]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nohup nc -u -l -p 1111 & ${crtl_n}    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -u @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}

    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Should Not Contain    ${server_output}    ${Test1}

    #: FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    #\    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[1]
    #: FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp

    Sleep    10s
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Contain X Times    ${stdout}    udp    2

    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}
    Write    ${crtl_c}
    ${client_output}=    Read
    Log   ${client_output}
    Exit From Vm Console

    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test2}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network   network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Only UDP Add Remove and Add Communication Dynamic changes in SG(Addition)
    [Documentation]    Add Remove and Add Security Group during TCP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone1}
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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    @{SECURITY_GROUP}[0]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nohup nc -u -l -p 1111 & ${crtl_n}    $
    Exit From Vm Console

    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -u @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}

    #: FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    #\    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[1]
    #: FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Sleep    10s

    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}

    #: FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    #\    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[1]
    #: FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp

    Sleep    10s
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Contain X Times    ${stdout}    udp    2

    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test3}${crtl_n}
    Write    ${crtl_c}
    ${client_output}=    Read
    Log   ${client_output}
    Exit From Vm Console

    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Write     kill `pidof nc`
    Log   ${server_output}
    #Log   ${server_output_1}
    Exit From Vm Console
    #Switch Connection    ${devstack_conn_id_2}
    #${client_output}=    Read
    #Log   ${client_output}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test3}
    Should Not Contain    ${server_output}    ${Test2}
    Should Contain    ${server_output}    ${Test1}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network   network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    [Teardown]    Run Keywords    Clear L2_Network

UDP Communication Three VM with Remote SG
    [Documentation]    Check UDP Communication using Remote SG
    ...    create SG1 and SG2,make SG1 remote SG as SG2, SG2 remote SG as SG1
    ...    Create three VM's with Remote SG Check udp between them
    ...    Remove VM's one by one and check the corresponding Flow
    ...    got removed in compute nodes
    Create Network    @{NETWORKS_NAME}[2]
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=@{SECURITY_GROUP}[1]
    ${VM1}=    Create List    @{NET_3_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_3_VM_INSTANCES}[1]
    ${VM3}=    Create List    @{NET_3_VM_INSTANCES}[2]
    Create Vm Instances    network_3    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_3    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_3    ${VM3}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]    additional_args=--availability-zone ${zone1}

    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    : FOR    ${VmElement}    IN    @{NET_3_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}    @{SECURITY_GROUP}[0]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_3_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_3_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_3_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Test Netcat Operations Between Vm Instance    network_3    @{NET1_VM_IPS}[0]    network_3    @{NET1_VM_IPS}[2]    additional_args=-u
    Test Netcat Operations Between Vm Instance    network_3    @{NET1_VM_IPS}[1]    network_3    @{NET1_VM_IPS}[2]    additional_args=-u
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[1]
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[1]
    Close Connection
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[2]
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Close Connection
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_3
    Delete Network    network_3
    [Teardown]    Run Keywords    Clear L2_Network

UDP Communication with Three SG udp egress/ingress port Range with Remote CIDR Prefix /24
    [Documentation]    Create 3 SG's(SG1,SG2,SG3) and delete all the rules
    ...    Create VM1 using SG1 and VM2 using SG3, in SG1 add udp ingress/egress rules udp port range 1000:2000
    ...    with Remote CIDR as VM2 similarly in SG2 and SG2 add udp ingress/egress rules udp port range 1000:2000
    ...    with Remote CIDR as VM1 add SG2 to the VM1 Check UDP communication from VM1 to VM2
    ...    then remove SG2 from the VM1 check the UDP communication
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[3]

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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/24
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/24
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/24
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[1]/24
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[0]/24
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=udp    remote_ip_prefix=@{NET1_VM_IPS}[0]/24
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]

    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328    additional_args=-u

    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    [Teardown]    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2

*** Keywords ***
Clear Security Group
    [Documentation]    This test case will clear all Security Group From
    ...    instance except dhcp SG.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    \    Run    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[0]
    \    Run    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[1]
    \    Run    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[2]
    \    Run    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[3]
    Run    openstack security group delete @{SECURITY_GROUP}[0]
    Run    openstack security group delete @{SECURITY_GROUP}[1]
    Run    openstack security group delete @{SECURITY_GROUP}[2]
    Run    openstack security group delete @{SECURITY_GROUP}[3]

