*** Settings ***
Documentation     Test suite to verify security groups basic and advanced functionalities of ICMP, including negative tests.
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
@{SECURITY_GROUP}    sg-remote    sg_1    sg_2
@{NETWORKS_NAME}    network_1    network_2    network_3
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2    l2_subnet_3
@{NET_1_VM_INSTANCES}    NET1-VM1    NET1-VM2    NET1-VM3
@{NET_2_VM_INSTANCES}    NET2-VM1
@{NET_3_VM_INSTANCES}    NET3-VM1    NET3-VM2    NET3-VM3
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    50.0.0.0/24
@{ROUTERS}   router1    router2
@{NETWORK_GW}    30.0.0.1    40.0.0.1
${password}    cubswin:)
${user}    cirros
@{SG_DHCP}    sg-dhcp1    sg-dhcp2

*** Test Cases ***

Create Zone
    [Documentation]    Create Availabilityzone create for test suite
    [Tags]    Rerun
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Create Network1 Components
    [Documentation]    Create Single Network and four VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SG_DHCP}[0]
    Delete All Security Group Rules    @{SG_DHCP}[0]
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VM3}=    Create List    @{NET_1_VM_INSTANCES}[2]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[0]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[0]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM3}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[0]    additional_args=--availability-zone ${zone2}
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
    \    Neutron Security Group Rule Create    @{SG_DHCP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32


Create Network2 Components
    [Documentation]    Create Second Network and Six VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Create    @{SG_DHCP}[1]
    Delete All Security Group Rules    @{SG_DHCP}[1]
    ${VM1}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    network_2    ${VM1}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[1]    additional_args=--availability-zone ${zone1}
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
    ${LOOP_COUNT}    Get Length    ${NET2_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SG_DHCP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32


ICMP Communication Default SG Rules Removed
    [Documentation]    Check ICMP Communication After Removing Default SG
    ...    Rules
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    :FOR   ${INDEX}    IN RANGE    0    ${length}
    \    Delete All Security Group Rules     @{sg_list}[${INDEX}]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group


ICMP Communication with Default SG and Ingress ICMP Rule
    [Documentation]    Check ICMP Communication using Default SG with ingress ICMP
    ...    Rule
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    :FOR   ${INDEX}    IN RANGE    0    ${length}
    \    Neutron Security Group Rule Create    @{sg_list}[${INDEX}]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group



ICMP Communication with Default SG and Egress ICMP Rule
    [Documentation]    Check ICMP Communication using Default SG with egress ICMP
    ...    Rule
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    :FOR   ${INDEX}    IN RANGE    0    ${length}
    \    Neutron Security Group Rule Create    @{sg_list}[${INDEX}]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group



ICMP Communication with Default SG and Ingress/Egress ICMP Rule
    [Documentation]    Check ICMP Communication using Default SG with ingress/egress ICMP
    ...    Rule
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    :FOR   ${INDEX}    IN RANGE    0    ${length}
    \    Neutron Security Group Rule Create    @{sg_list}[${INDEX}]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    \    Neutron Security Group Rule Create    @{sg_list}[${INDEX}]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[1]

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication From DHCP After Default SG Rules Removed
    [Documentation]    Check ICMP Communication From DHCP After Removing Default SG
    ...    Rules
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    :FOR   ${INDEX}    IN RANGE    0    ${length}
    \    Delete All Security Group Rules     @{sg_list}[${INDEX}]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]

    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG same zone
    [Documentation]    Check ICMP Communication with ingress on SG1
    ...    Egress rule on SG2
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG different zone
    [Documentation]    Check ICMP Communication with ingress on SG1
    ...    Egress rule on SG2
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG same zone icmp type/code
    [Documentation]    Check ICMP Communication with ingress icmp code 0 type 8 on SG1
    ...    Egress rule icmp code 0 type 8 on SG2
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0     remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG different zone icmp type/code
    [Documentation]    Check ICMP Communication with ingress icmp code 0 type 8 on SG1
    ...    Egress rule icmp code 0 type 8 on SG2
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0     remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG same zone icmp type/code after VM create
    [Documentation]    Check ICMP Communication with ingress icmp code 0 type 8 on SG1
    ...    Egress rule icmp code 0 type 8 on SG2
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0     remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG different zone icmp type/code after VM create
    [Documentation]    Check ICMP Communication with ingress icmp code 0 type 8 on SG1
    ...    Egress rule icmp code 0 type 8 on SG2
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0     remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[1]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG same zone icmp egress/ingress
    [Documentation]    Check ICMP Communication with ingress icmp on SG1
    ...    Egress rule icmp on SG2 add both SG to created VM
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG different zone icmp egress/ingress
    [Documentation]    Check ICMP Communication with ingress icmp on SG1
    ...    Egress rule icmp on SG2 add both SG to created VM
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[1]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP communication Dynamic changes in SG
    [Documentation]    Check communication ICMP On Dynamic Security Group Changes
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]

    ${crtl_c}    Evaluate    chr(int(3))
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write    sudo ip netns exec qdhcp-${net_id} ping @{NET1_VM_IPS}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    sleep    60s
    Switch Connection    ${devstack_conn_id_1}
    Write    ${crtl_c}
    ${output}=    Read Until    packet loss
    Should Not Contain    ${output}    0% packet loss

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ICMP communication Dynamic changes in SG Rules
    [Documentation]    Check communication ICMP On Dynamic Security Group Rule Changes
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]

    ${crtl_c}    Evaluate    chr(int(3))
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write    sudo ip netns exec qdhcp-${net_id} ping @{NET1_VM_IPS}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    sleep    60s
    Write    ${crtl_c}
    ${output}=    Read Until    packet loss
    Should Not Contain    ${output}    0% packet loss

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG icmp egress/ingress_1
    [Documentation]    Check ICMP Communication with ingress/egress icmp on SG1
    ...    Ingress/egress rule icmp on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check ICMP communication
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication Across the Network
    [Documentation]    Create Two Security Groups, SG1 with ingress ICMP rule
    ...    SG2 with egress ICMP rule apply SG1 to VM instance created on network1
    ...    apply SG2 to VM instance created on network2 test ping from network2 to network1
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]

    Create Router    @{ROUTERS}[0]
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    @{ROUTERS}[0]
    ${router_list} =    Create List    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${des_ip_1}

    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Delete Router    @{ROUTERS}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG icmp egress/ingress_2
    [Documentation]    Check ICMP Communication with ingress/egress icmp on SG1
    ...    Ingress/egress rule with icmp type and code on SG2, create VM's using SG1 and add SG2 VM's
    ...    Check ICMP communication
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG icmp egress/ingress_3
    [Documentation]    Check ICMP Communication with ingress/egress icmp with icmp type and code on SG1
    ...    Ingress/egress rule icmp on SG2, create VM's using SG1 and add SG2 VM's
    ...    Check ICMP communication
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG icmp egress/ingress_4
    [Documentation]    Check ICMP Communication with ingress/egress icmp on SG1
    ...    Ingress/egress rule with protocol number 1 on SG2, create VM's using SG1 and add SG2 VM's
    ...    Check ICMP communication
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=1    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=1    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG icmp egress/ingress_5
    [Documentation]    Check ICMP Communication with ingress/egress icmp with icmp type and code on SG1
    ...    Ingress/egress rule with protocol number 1 on SG2, create VM's using SG1 and add SG2 VM's
    ...    Check ICMP communication
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=1    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=1    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG icmp egress/ingress_6
    [Documentation]    Check ICMP Communication with ingress/egress icmp with icmp type and code on SG1
    ...    Ingress/egress ANY rule  on SG2, create VM's using SG1 and add SG2 VM's
    ...    Check ICMP communication
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    icmp_type=8    icmp_code=0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    icmp_type=8    icmp_code=0
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG icmp egress/ingress_7
    [Documentation]    Check ICMP Communication with ingress/egress icmp on SG1
    ...    Ingress/egress ANY rule on SG2, create VM's using SG1 and add SG2 VM's
    ...    Check ICMP communication
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG Dynamic Removal
    [Documentation]    Check ICMP Communication with ingress/egress icmp on SG1
    ...    Ingress/egress Tcp on SG2, create VM's using SG1 and remove  SG1 VM's add
    ...    SG2 during ping
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${vm_src}=    Create List    @{NET1_VM_IPS}[0]
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${crtl_c}    Evaluate    chr(int(3))
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}=    Write    ping @{NET1_VM_IPS}[1]
    Log    ${output}
    Switch Connection    ${devstack_conn_id_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    sleep    60s
    Switch Connection    ${devstack_conn_id_1}
    Write    ${crtl_c}
    ${output}=    Read Until    packet loss
    Should Not Contain    ${output}    0% packet loss

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group


ICMP Communication with Two SG Dynamic Addition
    [Documentation]    Check ICMP Communication with ingress/egress icmp on SG1
    ...    Ingress/egress Tcp on SG2, create VM's using SG2 and remove  SG2 VM's add
    ...    SG1 during ping
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]


    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${vm_src}=    Create List    @{NET1_VM_IPS}[0]

    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${crtl_c}    Evaluate    chr(int(3))
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}=    Write    ping @{NET1_VM_IPS}[1]
    Log    ${output}
    Switch Connection    ${devstack_conn_id_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    sleep    60s
    Switch Connection    ${devstack_conn_id_1}
    Write    ${crtl_c}
    ${output}=    Read Until    packet loss
    Should Contain    ${output}    64 bytes

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG Rule Dynamic Removal
    [Documentation]    Check ICMP Communication with ingress/egress icmp on SG1
    ...    create VM's using SG1 and remove  SG1 Rules During ping
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]


    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${vm_src}=    Create List    @{NET1_VM_IPS}[0]

    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${crtl_c}    Evaluate    chr(int(3))
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}=    Write    ping @{NET1_VM_IPS}[1]
    Log    ${output}
    Switch Connection    ${devstack_conn_id_2}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    sleep    60s
    Switch Connection    ${devstack_conn_id_1}
    Write    ${crtl_c}
    ${output}=    Read Until    packet loss
    Should Not Contain    ${output}    0% packet loss

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG Rule Dynamic Addition
    [Documentation]    Create SG1 and delete all rules
    ...    create VM's using SG1 and initiate ping between VM's
    ...    add ICMP ingress.egress rules to SG1 during ping
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]


    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${vm_src}=    Create List    @{NET1_VM_IPS}[0]

    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${crtl_c}    Evaluate    chr(int(3))
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}=    Write    ping @{NET1_VM_IPS}[1]
    Log    ${output}
    Switch Connection    ${devstack_conn_id_2}
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp
    sleep    60s
    Switch Connection    ${devstack_conn_id_1}
    Write    ${crtl_c}
    ${output}=    Read Until    packet loss
    Should Contain    ${output}    64 bytes

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG Rule Dynamic Removal/Addition
    [Documentation]    Check ICMP Communication with ingress/egress icmp on SG1
    ...    create VM's using SG1 and remove  SG1 Rules again add same Rule During ping
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${vm_src}=    Create List    @{NET1_VM_IPS}[0]

    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${crtl_c}    Evaluate    chr(int(3))
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}=    Write    ping @{NET1_VM_IPS}[1]
    Log    ${output}
    Switch Connection    ${devstack_conn_id_2}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    sleep    30s
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp
    sleep    30s
    Switch Connection    ${devstack_conn_id_1}
    Write    ${crtl_c}
    ${output}=    Read Until    packet loss
    Should Not Contain    ${output}    0% packet loss

    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG Same Rules_1
    [Documentation]    Check ICMP Communication with ingress/Egress icmp on SG1
    ...    Ingress/Egress rule on SG2,Create VM with SG1 and Add SG2 then
    ...    Remove Both SG from the VM
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]

    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG Same Rules_2
    [Documentation]    Check ICMP Communication with ingress/Egress icmp on SG1
    ...    Ingress/Egress rule on SG2,Create VM with SG2 and Add SG1 then
    ...    Remove Both SG from the VM
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]

    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

Delete Network1 Components
    [Documentation]    Delete Instances and Networks of first Network
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[2]
    Delete SecurityGroup    @{SG_DHCP}[0]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1

Delete Network2 Components
    [Documentation]    Delete Instances and Networks of Second Network
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete SecurityGroup    @{SG_DHCP}[1]
    Delete SubNet    l2_subnet_2
    Delete Network    network_2
    [Teardown]    Run Keywords    Clear L2_Network

ICMP Communication with Remote SG_1
    [Documentation]    Check ICMP Communication using Remote SG
    ...    Create three VM's with Remote SG Check ping between them
    ...    Remove VM's one by one and check the corresponding Flow
    ...    got removed in compute nodes
    Create Network    @{NETWORKS_NAME}[2]
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]

    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    :FOR   ${INDEX}    IN RANGE    0    ${length}
    \    Delete All Security Group Rules     @{sg_list}[${INDEX}]
    Create Vm Instances    network_3    ${NET_3_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{sg_list}[0]   additional_args=--availability-zone ${zone1}

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
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[1]    ${des_ip_1}
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
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[2]
    Close Connection
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SubNet    l2_subnet_3
    Delete Network    network_3
    [Teardown]    Run Keywords    Clear L2_Network

ICMP Communication with Remote SG_2
    [Documentation]    Check ICMP Communication using Remote SG
    ...    create SG1 and SG2.make SG1 remote SG as SG2, SG2 remote SG as SG1
    ...    Create three VM's with Remote SG Check ping between them
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
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=icmp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=icmp    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_group_id=@{SECURITY_GROUP}[1]
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
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[1]    ${des_ip_1}
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

ICMP Communication with Remote SG_3
    [Documentation]    Check ICMP Communication using Default SG
    ...    Create three VM's with Default SG
    ...    Remove All rules from the Default SG and check the corresponding Flow
    ...    got removed in compute nodes
    Create Network    @{NETWORKS_NAME}[2]
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    :FOR   ${INDEX}    IN RANGE    0    ${length}
    \    Delete All Security Group Rules     @{sg_list}[${INDEX}]
    Create Vm Instances    network_3    ${NET_3_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{sg_list}[0]    additional_args=--availability-zone ${zone1}

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
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[1]    ${des_ip_1}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    :FOR   ${INDEX}    IN RANGE    0    ${length}
    \    Delete All Security Group Rules     @{sg_list}[${INDEX}]
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[1]
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Close Connection
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[1]
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[2]
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[2]
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Close Connection
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SubNet    l2_subnet_3
    Delete Network    network_3
    [Teardown]    Run Keywords    Clear L2_Network

ICMP Communication with Two SG same zone Three Vm Instance
    [Documentation]    Check ICMP Communication with ingress icmp on SG1
    ...    Egress rule icmp on SG2 add SG2 to VM1 and VM2 and add SG1 to
    ...    VM3 check icmp communication from VM1 to VM3, VM2 to VM3
    ...    then add SG1 to VM2 and check icmp communication from VM1 to VM2
    Create Network    @{NETWORKS_NAME}[2]
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    ${VM1}=    Create List    @{NET_3_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_3_VM_INSTANCES}[1]
    ${VM3}=    Create List    @{NET_3_VM_INSTANCES}[2]
    Create Vm Instances    network_3    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_3    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_3    ${VM3}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone1}

    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
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
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[1]    ${des_ip_1}
    Add Security Group To VM    @{NET_3_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[0]    ${des_ip_2}

    : FOR    ${VmElement}    IN    @{NET_3_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_3
    Delete Network    network_3
    [Teardown]    Run Keywords    Clear L2_Network

ICMP Communication with Two SG different zone Three Vm Instance
    [Documentation]    Check ICMP Communication with ingress icmp on SG1
    ...    Egress rule icmp on SG2 add SG2 to VM1 and VM2 and add SG1 to
    ...    VM3 check icmp communication from VM1 to VM3, VM2 to VM3
    ...    then add SG1 to VM2 and check icmp communication from VM1 to VM2
    Create Network    @{NETWORKS_NAME}[2]
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]
    Neutron Security Group Create   @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create   @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    ${VM1}=    Create List    @{NET_3_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_3_VM_INSTANCES}[1]
    ${VM3}=    Create List    @{NET_3_VM_INSTANCES}[2]
    Create Vm Instances    network_3    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_3    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_3    ${VM3}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone1}

    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
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
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[2]
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[1]    ${des_ip_1}
    Add Security Group To VM    @{NET_3_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_3    @{NET1_VM_IPS}[0]    ${des_ip_2}

    : FOR    ${VmElement}    IN    @{NET_3_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_3
    Delete Network    network_3
    [Teardown]    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    [Tags]    Rerun
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
    \    Run    openstack server remove security group ${VmElement} @{sg_list}[0]
    Run    openstack security group delete @{SECURITY_GROUP}[0]
    Run    openstack security group delete @{SECURITY_GROUP}[1]
    Run    openstack security group delete @{SECURITY_GROUP}[2]
    Run    openstack security group delete @{sg_list}[0]
