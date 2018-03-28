*** Settings ***
Documentation     Test suite to verify security groups basic and advanced functionalities of ANY, including negative tests.
...               These test cases are not so relevant for transparent mode, so each test case will be tagged with
...               "skip_if_transparent" to allow any underlying keywords to return with a PASS without risking
...               a false failure. The real value of this suite will be in stateful mode.
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

*** Variables ***
@{SECURITY_GROUP}    sg-remote    sg_1    sg_2    sg_3
@{NETWORKS_NAME}    network_1    network_2    network_3    network_4    network_5
@{NETWORKS_IPV6}    NET1_IPV6
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2    l2_subnet_3    l2_subnet_4    l2_subnet_5
@{SUBNETS_IPV6}    SUBNET1_IPV6
@{SG_DHCP}        sg-dhcp1    sg-dhcp2
@{NET_1_VM_INSTANCES}    NET1-VM1    NET1-VM2    NET1-VM3    NET1-VM4
@{NET_2_VM_INSTANCES}    NET2-VM1    NET2-VM2
@{NET_3_VM_INSTANCES}    NET3-VM1
@{IPV6_VM}        VM1_IPV6    VM2_IPV6
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    50.0.0.0/24    60.0.0.0/24    70.0.0.0/24
@{ROUTERS}        router1    router2
@{NETWORK_GW}     30.0.0.1    40.0.0.1
${password}       cubswin:)
${user}           cirros
${Test1}          Data1
${Test2}          Data2
${Test3}          Data3
${Test4}          Data4
${Test5}          Data5
${Test6}          Data6

*** Test Cases ***
Create Zone
    [Documentation]    Create Availabilityzone create for test suite
    [Tags]    Test
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Create Network1 Components
    [Documentation]    Create Single Network and four VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    [Tags]    Test
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SG_DHCP}[0]
    Delete All Security Group Rules    @{SG_DHCP}[0]
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VM3}=    Create List    @{NET_1_VM_INSTANCES}[2]
    ${VM4}=    Create List    @{NET_1_VM_INSTANCES}[3]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[0]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[0]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM3}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[0]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM4}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[0]    additional_args=--availability-zone ${zone2}
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
    \    Neutron Security Group Rule Create    @{SG_DHCP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32

Create Network2 Components
    [Documentation]    Create Second Network and Six VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    [Tags]    Test
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Create    @{SG_DHCP}[1]
    Delete All Security Group Rules    @{SG_DHCP}[1]
    ${VM1}=    Create List    @{NET_2_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[1]
    Create Vm Instances    network_2    ${VM1}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[1]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_2    ${VM2}    image=cirros    flavor=cirros    sg=@{SG_DHCP}[1]    additional_args=--availability-zone ${zone2}
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
    \    Neutron Security Group Rule Create    @{SG_DHCP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32

ANY ingress and Default SG
    [Documentation]    Check ANY ingress rule Can be added to Default SG
    ...    and ODL installing seperate flows during VM creation
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Create ANY SecurityGroup Rule    @{sg_list}[0]    ingress
    ${net_id}=    Get Net Id    network_1
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Contain X Times    ${stdout}    ip    8
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress and Default SG
    [Documentation]    Create VM instance using Default SG
    ...    Create SG1 with ingress/egress ANY protocol attach SG1 to the VM instance
    ...    check the flows for both SG's added in the compute node.
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${net_id}=    Get Net Id    network_1
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Contain X Times    ${stdout}    ip    7
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=213
    Should Contain X Times    ${stdout}    ip    5
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG same zone
    [Documentation]    Check TCP/UDP/ICMP Communication with ingress ANY Rule on SG1
    ...    Egress ANY rule on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG different zone
    [Documentation]    Check TCP/UDP/ICMP Communication with ingress ANY Rule on SG1
    ...    Egress ANY rule on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[3]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[3]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress and Default SG Change SG after Creation
    [Documentation]    Create VM instance using Default SG
    ...    Create SG1 with ingress/egress ANY protocol ,Remove Default SG then
    ...    attach SG1 to the VM instance check the flows for both SG's added in the compute node.
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Contain X Times    ${stdout}    ip    6
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=213
    Should Contain X Times    ${stdout}    ip    4
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Contain X Times    ${stdout}    ip    2
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=213
    Should Contain X Times    ${stdout}    ip    2
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG Change SG After VM Creation
    [Documentation]    Check TCP/UDP/ICMP Communication with ingress/Egress ANY Rule on SG1
    ...    Ingress/Egress rule with protocol 6 on SG2, Create VM using SG1 check tcp/udp/icmp
    ...    Communication, Remove SG1 then Add SG2 check the flows are removed properly
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=6    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Contain X Times    ${stdout}    ip    2
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=213
    Should Contain X Times    ${stdout}    ip    2
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Sleep    30s
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Not Contain    ${stdout}    ip
    Run Keyword IF    ${NUM_ODL_SYSTEM} == 3    Should Contain X Times    ${stdout}    tcp    14
    ...    ELSE    Should Contain X Times    ${stdout}    tcp    2
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=213
    Should Not Contain    ${stdout}    ip
    Run Keyword IF    ${NUM_ODL_SYSTEM} == 3    Should Contain X Times    ${stdout}    tcp    2
    ...    ELSE    Should Contain X Times    ${stdout}    tcp    2
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP ingress and Default SG Same Network
    [Documentation]    Check icmp ingress rule Can be added to Default SG
    ...    and ODL installing seperate flows during VM creation
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group

TCP ingress and Default SG Same Network
    [Documentation]    Check tcp ingress rule Can be added to Default SG
    ...    and ODL installing seperate flows during VM creation
    [Tags]    re-run
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SG_DHCP}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SG_DHCP}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    Connection timed out
    Log    ${output}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SG_DHCP}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SG_DHCP}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group

TCP Communication with Two SG same zone Three Vm Instance
    [Documentation]    Check TCP Communication with ingress/Egress rule protocol 6 on SG1
    ...    Ingress/Egress rule with protocol 6 on SG2,Make SG2 remote add SG2 to VM1 and VM3 and add SG1 to
    ...    VM2 check tcp communication from VM2 to VM3, VM2 to VM1
    [Tags]    re-run
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[2]
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

TCP Communication with Two SG different zone Three Vm Instance
    [Documentation]    Check TCP Communication with ingress/Egress rule protocol 6 on SG1
    ...    Ingress/Egress rule with protocol 6 on SG2,Make SG2 remote add SG2 to VM1 and VM3 and add SG1 to
    ...    VM2 check tcp communication from VM2 to VM3, VM2 to VM1
    [Tags]    re-run
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[3] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[2]
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

TCP Communication with Two SG same zone Three Vm Instance Remote CIDR
    [Documentation]    Check TCP Communication with ingress/Egress rule protocol 6 remote CIDR as VM2 IP on SG1
    ...    Ingress/Egress rule with protocol 6 remote CIDR as VM1 IP on SG2,add SG1 to VM1 ,SG2 to VM2 and add SG3 to
    ...    VM3 check tcp communication from VM1 to VM2, VM2 to VM1 and VM3 to VM1
    [Tags]    re-run
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[2]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[2]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[2] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

TCP Communication with Two SG different zone Three Vm Instance Remote CIDR
    [Documentation]    Check TCP Communication with ingress/Egress rule protocol 6 remote CIDR as VM2 IP on SG1
    ...    Ingress/Egress rule with protocol 6 remote CIDR as VM1 IP on SG2,add SG1 to VM1 ,SG2 to VM2 and add SG3 to
    ...    VM3 check tcp communication from VM1 to VM2, VM2 to VM1 and VM3 to VM1
    [Tags]    re-run
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[3]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[3]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[3]
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[3] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

ICMP ingress/egress with Three SG Same zone
    [Documentation]    Check ICMP Communication with ingress/Egress Rule on SG1
    ...    Ingress/Egress rule on SG2 and ANY ingress/egress on SG3
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[2]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_2}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

ICMP ingress/egress with Three SG diffrent zone
    [Documentation]    Check ICMP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 and ANY ingress/egress rule on SG3
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[3]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[3]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[3]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[3]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Three SG same zone
    [Documentation]    Check ANY Communication with ingress/egress Rule with remote ip as VM2 on SG1
    ...    ingress/egress rule with remote ip as VM1 on SG2 and ANY ingress/egress rule on SG3
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[3]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress    additional_args=--remote-ip @{NET1_VM_IPS}[1]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress    additional_args=--remote-ip @{NET1_VM_IPS}[1]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress    additional_args=--remote-ip @{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress    additional_args=--remote-ip @{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[2]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[2]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[2]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[2]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u    nc_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_2}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Three SG different zone
    [Documentation]    Check ANY Communication with ingress/egress Rule with remote ip as VM2 on SG1
    ...    ingress/egress rule with remote ip as VM1 on SG2 and ANY ingress/egress rule on SG3
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress    additional_args=--remote-ip @{NET1_VM_IPS}[3]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress    additional_args=--remote-ip @{NET1_VM_IPS}[3]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress    additional_args=--remote-ip @{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress    additional_args=--remote-ip @{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[3]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    additional_args=-u    nc_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[3]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG same zone with remote group
    [Documentation]    Check ICMP/TCP/UDP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule with remote group as SG1 on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress    additional_args=--remote-group @{SECURITY_GROUP}[1]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress    additional_args=--remote-group @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[2]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[2]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[2]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[2]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[2]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG different zone with remote group
    [Documentation]    Check ICMP/TCP/UDP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule with remote group as SG1 on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress    additional_args=--remote-group @{SECURITY_GROUP}[1]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress    additional_args=--remote-group @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[3]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[3]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG same zone Associate and Remove SG's
    [Documentation]    Check ICMP/TCP/UDP Communication with ANY ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 by associating and removing SG's
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY and ICMP ingress/egress with Two SG same zone
    [Documentation]    Check ICMP/TCP/UDP Communication with ANY ingress/egress Rule on SG1
    ...    ICMP ingress/egress rule on SG2 by associating and removing SG's
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=1
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=1
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY and TCP ingress/egress with Two SG same zone
    [Documentation]    Check ICMP/TCP/UDP Communication with ANY ingress/egress Rule on SG1
    ...    TCP ingress/egress rule on SG2 by associating and removing SG's
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=6
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY and UDP ingress/egress with Two SG same zone
    [Documentation]    Check ICMP/TCP/UDP Communication with ANY ingress/egress Rule on SG1
    ...    UDP ingress/egress rule on SG2 by associating and removing SG's
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=17
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

TCP ingress/egress with Two SG same zone
    [Documentation]    Check TCP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 by associating and removing SG's
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=6
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

Create Router
    [Documentation]    Create router for across network
    [Tags]    re-run
    Create Router    @{ROUTERS}[0]
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    @{ROUTERS}[0]
    ${router_list} =    Create List    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]

Two Network ICMP ingress/egress with Three SG same zone
    [Documentation]    Check ICMP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 and ANY ingress/egress rule on SG3
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET2_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET2_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[0]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

Two Network ICMP ingress/egress with Three SG diffrent zone
    [Documentation]    Check ICMP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 and ANY ingress/egress rule on SG3
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET2_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET2_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[1]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[1]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

Two Network ANY ingress/egress with Three SG same zone With Remote ip
    [Documentation]    Check ANY Communication with ingress/egress Rule with remote ip of VM2 on SG1
    ...    ingress/egress rule with remote ip of VM1 on SG2 and ANY ingress/egress rule on SG3
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress    additional_args=--remote-ip @{NET2_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress    additional_args=--remote-ip @{NET2_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress    additional_args=--remote-ip @{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress    additional_args=--remote-ip @{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[0]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

Two Network ANY ingress/egress with Three SG different zone With Remote ip
    [Documentation]    Check ANY Communication with ingress/egress Rule with remote ip of VM2 on SG1
    ...    ingress/egress rule with remote ip of VM1 on SG2 and ANY ingress/egress rule on SG3
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress    additional_args=--remote-ip @{NET2_VM_IPS}[1]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress    additional_args=--remote-ip @{NET2_VM_IPS}[1]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress    additional_args=--remote-ip @{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress    additional_args=--remote-ip @{NET1_VM_IPS}[0]/32
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[1]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    additional_args=-u    nc_should_succeed=False
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[1]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group

Two Network ANY ingress/egress with Two SG same zone With Remote group
    [Documentation]    Check ICMP/TCP/UDP Communication with ANY ingress/egress Rule on SG1
    ...    ingress/egress rule with remote group as SG1 on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress    additional_args=--remote-group @{SECURITY_GROUP}[1]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress    additional_args=--remote-group @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[0]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

Two Network ANY ingress/egress with Two SG different zone With Remote group
    [Documentation]    Check ICMP/TCP/UDP Communication with ANY ingress/egress Rule on SG1
    ...    ingress/egress rule with remote group as SG1 on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress    additional_args=--remote-group @{SECURITY_GROUP}[1]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress    additional_args=--remote-group @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[1]
    ${des_ip_3}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    additional_args=-u
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[1]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG same zone Across Network
    [Documentation]    Create Two Security Groups, SG1 with ingress ANY rule
    ...    SG2 with egress ANY rule apply SG1 to VM instance created on network1
    ...    apply SG2 to VM instance created on network2 test tcp/udp/icmp from network2 to network1
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[0]
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}    ping_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG different zone Across Network
    [Documentation]    Create Two Security Groups, SG1 with ingress ANY rule
    ...    SG2 with egress ANY rule apply SG1 to VM instance created on network1
    ...    apply SG2 to VM instance created on network2 test tcp/udp/icmp from network2 to network1
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[1]
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[1]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}    ping_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    additional_args=-u
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with One SG same zone Across Network
    [Documentation]    Create Security Group, SG1 with ingress/Egress ANY rule
    ...    Create Vm instance with SG1 and test tcp/udp/icmp from network2 to network1
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[0]
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with One SG different zone Across Network
    [Documentation]    Create Security Group, SG1 with ingress/Egress ANY rule
    ...    Create Vm instance with SG1 and test tcp/udp/icmp from network2 to network1
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET2_VM_IPS}[1]
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[1]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[1]    additional_args=-u
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ICMP ingress and Default SG Across Network
    [Documentation]    Check icmp ingress rule Can be added to Default SG
    ...    and ODL installing seperate flows during VM creation
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{sg_list}[0]
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]
    Ping From DHCP Should Not Succeed    network_2    @{NET2_VM_IPS}[0]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]
    Ping Vm From DHCP Namespace    network_2    @{NET2_VM_IPS}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{sg_list}[0]
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear Security Group

TCP Communication with Two SG same zone Three Vm Instance Across Network
    [Documentation]    Check TCP Communication with ingress/Egress rule protocol 6 on SG1
    ...    Ingress/Egress rule with protocol 6 on SG2,Make SG2 remote add SG2 to VM1 and VM3 and add SG1 to
    ...    VM2 check tcp communication from VM2 to VM3, VM2 to VM1
    ...    VM1 and VM2 created on network1,VM3 created on network2
    [Tags]    re-run
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET2_VM_IPS}[0]
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

TCP Communication with Two SG different zone Three Vm Instance Across Network
    [Documentation]    Check TCP Communication with ingress/Egress rule protocol 6 on SG1
    ...    Ingress/Egress rule with protocol 6 on SG2,Make SG2 remote add SG2 to VM1 and VM3 and add SG1 to
    ...    VM2 check tcp communication from VM2 to VM3, VM2 to VM1
    ...    VM1 and VM2 created on network1,VM3 created on network2
    [Tags]    re-run
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[3] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET2_VM_IPS}[0]
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG same zone Three Vm Instance Across Network
    [Documentation]    Check ICMP Communication with ingress/Egress rule protocol 1 on SG1
    ...    Ingress/Egress rule with protocol 1 on SG2,Make SG2 remote add SG2 to VM1 and VM3 and add SG1 to
    ...    VM2 check icmp communication from VM2 to VM3, VM2 to VM1
    ...    VM1 and VM2 created on network1,VM3 created on network2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=1    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=1    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=1    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=1    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Sleep    10s
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_3}=    Create List    @{NET2_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_3}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_3}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP Communication with Two SG different zone Three Vm Instance Across Network
    [Documentation]    Check ICMP Communication with ingress/Egress rule protocol 1 on SG1
    ...    Ingress/Egress rule with protocol 1 on SG2,Make SG2 remote add SG2 to VM1 and VM3 and add SG1 to
    ...    VM2 check icmp communication from VM2 to VM3, VM2 to VM1
    ...    VM1 and VM2 created on network1,VM3 created on network2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=1    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=1    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=1    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=1    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[3]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_3}=    Create List    @{NET2_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[3]    ${des_ip_2}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[3]    ${des_ip_3}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_3}    ping_should_succeed=False
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

TCP Communication with Two SG same zone Three Vm Instance Across Network CIDR
    [Documentation]    Check TCP Communication with ingress/Egress rule protocol 6 remote CIDR as VM2 IP on SG1
    ...    Ingress/Egress rule with protocol 6 remote CIDR as VM1 IP on SG2,add SG1 to VM1 ,SG2 to VM2 and add SG3 to
    ...    VM3 check tcp communication from VM1 to VM2, VM2 to VM1 and VM3 to VM1
    [Tags]    run
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]    first_login=False
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET2_VM_IPS}[0]
    Exit From Vm Console
    ${net_id_2}=    Get Net Id    network_2
    Log    ${net_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id_2} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

TCP Communication with Two SG different zone Three Vm Instance Across Network CIDR
    [Documentation]    Check TCP Communication with ingress/Egress rule protocol 6 remote CIDR as VM2 IP on SG1
    ...    Ingress/Egress rule with protocol 6 remote CIDR as VM1 IP on SG2,add SG1 to VM1 ,SG2 to VM2 and add SG3 to
    ...    VM3 check tcp communication from VM1 to VM2, VM2 to VM1 and VM3 to VM1
    [Tags]    run
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[3]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[3]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[3]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=6    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Sleep    10s
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[3]    first_login=False
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET2_VM_IPS}[0]
    Exit From Vm Console
    ${net_id_2}=    Get Net Id    network_2
    Log    ${net_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id_2} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[3]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

Delete Router Components
    [Documentation]    Delete Router components for across network
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Delete Router    @{ROUTERS}[0]

ICMP ingress/egress with Two SG same zone
    [Documentation]    Check ICMP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 by associating and deleting SG's
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=1
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=1
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=1
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=1
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_2}
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

UDP ingress/egress with Two SG same zone
    [Documentation]    Check UDP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 by associating and removing SG's
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=17
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=17
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=17
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ICMP ingress/egress with Dynamic change while ping operation
    [Documentation]    Check ICMP Communication with ingress/egress Rule on SG1
    ...    by dynamically removing rules while communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=1
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=1
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
    Switch Connection    ${devstack_conn_id_1}
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
    Switch Connection    ${devstack_conn_id_1}
    Write    ${crtl_c}
    ${output}=    Read Until    packet loss
    Should Not Contain    ${output}    0% packet loss
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG same zone Associate One After Other
    [Documentation]    Check TCP/ICMP/UDP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 by assosiating SG one after other
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
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
    Write Commands Until Expected Prompt    nc -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_2}
    Write    sudo ip netns exec qdhcp-${net_id} nc @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    Log    ${server_output}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test1}
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
    Write    ${Test2} ${crtl_n}
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    #Log    ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test2}
    Switch Connection    ${devstack_conn_id_2}
    Write    ${crtl_c}
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
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
    Write Commands Until Expected Prompt    nc -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_4}
    Write    sudo ip netns exec qdhcp-${net_id} nc @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test3} ${crtl_n}
    Switch Connection    ${devstack_conn_id_3}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    Log    ${server_output}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test3}
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
    Write    ${Test4} ${crtl_n}
    Switch Connection    ${devstack_conn_id_3}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    #Log    ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test4}
    Switch Connection    ${devstack_conn_id_4}
    Write    ${crtl_c}
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]
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
    Write    ${Test5} ${crtl_n}
    Switch Connection    ${devstack_conn_id_5}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    Log    ${server_output}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test5}
    Switch Connection    ${devstack_conn_id_5}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_6}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET2_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test6} ${crtl_n}
    Switch Connection    ${devstack_conn_id_5}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    #Log    ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test6}
    Switch Connection    ${devstack_conn_id_6}
    Write    ${crtl_c}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY and ICMP ingress/egress with SG same zone with remote group
    [Documentation]    Create ANY with ingress/egress Rule with remote group as SG2 on SG1
    ...    ICMP ingress/egress rule with remote group as SG1 on SG2 and check flows while deleting SG
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress    additional_args=--remote-group @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress    additional_args=--remote-group @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=1    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=1    remote_group_id=@{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Sleep    10s
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[1]
    Switch Connection    ${devstack_conn_id}
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[2]
    Sleep    10s
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[2]
    Switch Connection    ${devstack_conn_id}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group

ANY ingress/egress with Two SG same zone Associate at Same Time
    [Documentation]    Check ICMP/TCP/UDP Communication with ingress/egress Rule on SG1
    ...    ingress/egress rule on SG2 by associating SG's at the same time
    Create Network    @{NETWORKS_NAME}[2]
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    ${VM1}=    Create List    @{NET_3_VM_INSTANCES}[0]
    Create Vm Instances    network_3    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_3_VM_INSTANCES}
    ${NET3_VM_IPS}    ${NET3_DHCP_IP}    Collect VM IP Addresses    false    @{NET_3_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_3_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET3_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET3_VM_IPS}
    Set Suite Variable    ${NET3_DHCP_IP}
    Should Not Contain    ${NET3_VM_IPS}    None
    Should Not Contain    ${NET3_DHCP_IP}    None
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${des_ip_1}=    Create List    @{NET3_VM_IPS}[0]
    ${LOOP_COUNT}    Get Length    ${NET3_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET3_DHCP_IP}[${index}]/32
    : FOR    ${VmElement}    IN    @{NET_3_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}    @{SECURITY_GROUP}[0]
    Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[2]    @{NET3_VM_IPS}[0]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_3
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_2}
    Write    sudo ip netns exec qdhcp-${net_id} nc @{NET3_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test1} ${crtl_n}
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    Log    ${server_output}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test1}
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_3
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_2}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET3_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test2} ${crtl_n}
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    #Log    ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test2}
    Switch Connection    ${devstack_conn_id_2}
    Write    ${crtl_c}
    Remove Security Group From VM    @{NET_3_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[2]    @{NET3_VM_IPS}[0]
    ${devstack_conn_id_3}=    Get ControlNode Connection
    ${devstack_conn_id_4}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_3}
    ${net_id}=    Get Net Id    network_3
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_4}
    Write    sudo ip netns exec qdhcp-${net_id} nc @{NET3_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test3} ${crtl_n}
    Switch Connection    ${devstack_conn_id_3}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    Log    ${server_output}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test3}
    Switch Connection    ${devstack_conn_id_3}
    ${net_id}=    Get Net Id    network_3
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_4}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET3_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test4} ${crtl_n}
    Switch Connection    ${devstack_conn_id_3}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    #Log    ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test4}
    Switch Connection    ${devstack_conn_id_4}
    Write    ${crtl_c}
    Remove Security Group From VM    @{NET_3_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[2]    @{NET3_VM_IPS}[0]
    ${devstack_conn_id_5}=    Get ControlNode Connection
    ${devstack_conn_id_6}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_5}
    ${net_id}=    Get Net Id    network_3
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -u -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_6}
    Write    sudo ip netns exec qdhcp-${net_id} nc -u @{NET3_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test5} ${crtl_n}
    Switch Connection    ${devstack_conn_id_5}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    Log    ${server_output}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test5}
    Switch Connection    ${devstack_conn_id_5}
    ${net_id}=    Get Net Id    network_3
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nc -l -p 1328 >> test.txt &    $
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_6}
    Write    sudo ip netns exec qdhcp-${net_id} nc @{NET3_VM_IPS}[0] 1328 ${crtl_n}
    Write    ${Test6} ${crtl_n}
    Switch Connection    ${devstack_conn_id_5}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET3_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${server_output}=    Write Commands Until Expected Prompt    cat test.txt    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    #Log    ${server_output_1}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test6}
    Switch Connection    ${devstack_conn_id_6}
    Write    ${crtl_c}
    : FOR    ${VmElement}    IN    @{NET_3_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_3
    Delete Network    network_3

Delete Network1 Components
    [Documentation]    Delete Instances and Networks of first Network
    [Tags]    run
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[3]
    Delete SecurityGroup    @{SG_DHCP}[0]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1

Delete Network2 Components
    [Documentation]    Delete Instances and Networks of Second Network
    [Tags]    re-run
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[1]
    Delete SecurityGroup    @{SG_DHCP}[1]
    Delete SubNet    l2_subnet_2
    Delete Network    network_2
    [Teardown]    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    [Tags]    re-run
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2

*** Keywords ***
Clear Security Group
    [Documentation]    This test case will clear all Security Group From
    ...    instance.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    \    Run    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[0]
    \    Run    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[1]
    \    Run    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[2]
    \    Run    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[3]
    \    Run    openstack server remove security group ${VmElement} @{sg_list}[0]
    Run    openstack security group delete @{SECURITY_GROUP}[0]
    Run    openstack security group delete @{SECURITY_GROUP}[1]
    Run    openstack security group delete @{SECURITY_GROUP}[2]
    Run    openstack security group delete @{SECURITY_GROUP}[3]
    Run    openstack security group delete @{sg_list}[0]
