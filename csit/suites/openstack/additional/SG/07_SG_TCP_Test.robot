*** Settings ***
Documentation     Test suite to verify security groups basic and advanced functionalities of TCP, including negative tests.
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
@{NETWORKS_NAME}    network_1    network_2    network_3    network_4    network_5
@{NETWORKS_IPV6}    NET1_IPV6
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2    l2_subnet_3    l2_subnet_4    l2_subnet_5
@{SUBNETS_IPV6}    SUBNET1_IPV6
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1    MyThirdInstance_3
@{NET_2_VM_INSTANCES}    MyFourthInstance_4    MyFifthInstance_5
@{NET_3_VM_INSTANCES}    VM1    VM2    VM3
@{NET_4_VM_INSTANCES}    VM4    VM5    VM6    VM7    VM8
@{NET_5_VM_INSTANCES}    VM9    VM10    VM11    VM12    VM13
@{IPV6_VM}        VM1_IPV6    VM2_IPV6
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    50.0.0.0/24    60.0.0.0/24    70.0.0.0/24
@{ROUTERS}        router1    router2
@{NETWORK_GW}     30.0.0.1    40.0.0.1
${password}       cubswin:)
${user}           cirros
${Test1}          Data1
${Test2}          Data2
${Test3}          Data3

*** Test Cases ***
Create Zone
    [Documentation]    Create Availabilityzone create for test suite
    [Tags]    Re
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

TCP Communication Default SG Rules_1
    [Documentation]    Check TCP Communication Using Default SG
    ...    Rules
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    sg=@{sg_list}[0]    image=cirros    flavor=cirros    additional_args=--availability-zone ${zone1}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
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
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    Connection timed out
    Log    ${output}
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${NET1_DHCP_IP}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console

TCP Communication Default SG Rules_2
    [Documentation]    Check TCP Communication After Default SG
    ...    Rules Removed
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{sg_list}[0]
    Log    @{sg_list}[0]
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[1]
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[0]
    Switch Connection    ${devstack_conn_id}
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${NET1_DHCP_IP}    ping_should_succeed=False
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console

TCP Communication Default SG Rules_3
    [Documentation]    Check TCP Communication After Default SG
    ...    Rules Removed add ingress TCP rule and test ssh from DHCP name space,
    ...    try ssh between VM instance
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Log    @{sg_list}[0]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console

TCP Communication Default SG Rules_4
    [Documentation]    Check TCP Communication After Default SG
    ...    Rules Removed add ingress/egress TCP rule and
    ...    try ssh between VM instance
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Log    @{sg_list}[0]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]    first_login=False
    Exit From Vm Console

TCP Communication Default SG Rules_5
    [Documentation]    Check TCP Communication After Default SG
    ...    Rules Removed
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Log    @{sg_list}[0]
    Delete All Security Group Rules    @{sg_list}[0]
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Not Contain    ${stdout}    ip
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    Delete All Security Group Rules    @{sg_list}[0]

TCP Communication Default SG Rules_6
    [Documentation]    Check TCP Communication After Default SG
    ...    Rules Removed Create new VM instance try ssh from DHCP Namespace
    ${VM3}=    Create List    Third_instnace
    Create Vm Instances    network_1    ${VM3}    sg=@{sg_list}[0]    image=cirros    flavor=cirros    additional_args=--availability-zone ${zone1}
    : FOR    ${vm}    IN    @{VM3}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VM3}
    ${NET1_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VM3}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM3}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_IPS}
    Should Not Contain    ${NET1_IPS}    None
    Poll VM Boot Status    @{VM3}[0]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_IPS}[0] -o UserKnownHostsFile=/dev/null    Connection timed out
    Log    ${output}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}    @{VM3}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    Delete SecurityGroup    @{sg_list}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Remove TCP and Add ICMP During TCP Communication Dynamic changes in SG(Addition)
    [Documentation]    Remove Security Group during TCP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp
    ${VMs}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VMs}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VMs}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMs}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMs}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMs}
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{VMs}
    \    Poll VM Boot Status    ${vm}
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    ${devstack_conn_id_2}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    nohup nc -v -l -p 1111 & ${crtl_n}    $
    Write Commands Until Expected Prompt    ${crtl_n}    $
    #Exit From Vm Console
    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -w 300 @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}
    Sleep    90s
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Log    ${server_output}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test1}
    : FOR    ${VmElement}    IN    @{VMs}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[1]
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add security group ${VmElement} @{SECURITY_GROUP}[2]
    Sleep    20s
    Switch Connection    ${devstack_conn_id_2}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    #Write    nc @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test2}${crtl_n}
    Write    ${crtl_c}
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    Write    kill `pidof nc`
    Log    ${server_output}
    Exit From Vm Console
    Write    ${crtl_c}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test2}
    : FOR    ${VmElement}    IN    @{VMs}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear L2_Network

Remove ICMP and Add TCP During TCP Communication Dynamic changes in SG(Addition)
    [Documentation]    Remove ICMP and Add TCP Security Group during TCP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=icmp
    ${VMs}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VMs}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]
    : FOR    ${vm}    IN    @{VMs}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMs}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMs}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMs}
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{VMs}
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
    Write Commands Until Expected Prompt    nohup nc -v -l -p 1111 & ${crtl_n}    $
    Write Commands Until Expected Prompt    ${crtl_n}    $
    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -w 300 @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Log    ${server_output}
    Should Not Contain    ${server_output}    ${Test1}
    : FOR    ${VmElement}    IN    @{VMs}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove security group ${VmElement} @{SECURITY_GROUP}[2]
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add security group ${VmElement} @{SECURITY_GROUP}[1]
    Sleep    20s
    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}
    Write    ${crtl_c}
    ${client_output}=    Read
    Log    ${client_output}
    Exit From Vm Console
    Sleep    90s
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    Exit From Vm Console
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test2}
    : FOR    ${VmElement}    IN    @{VMs}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear L2_Network

Only TCP Add and Remove Communication Dynamic changes in SG(Addition)
    [Documentation]    Add and Remove Security Group during TCP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}    @{SECURITY_GROUP}[0]
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
    Write Commands Until Expected Prompt    nohup nc -v -l -p 1111 & ${crtl_n}    $
    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -w 300 @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}
    Sleep    90s
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Log    ${server_output}
    Should Contain    ${server_output}    ${Test1}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Sleep    20s
    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}
    Write    ${crtl_c}
    Exit From Vm Console
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test2}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Only TCP Remove and Add Communication Dynamic changes in SG(Addition)
    [Documentation]    Remove and Add Security Group during TCP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    ${VMs}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VMs}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VMs}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMs}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMs}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMs}
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${VmElement}    IN    @{VMs}
    \    Add Security Group To VM    ${VmElement}    @{SECURITY_GROUP}[0]
    : FOR    ${vm}    IN    @{VMs}
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
    Write Commands Until Expected Prompt    nohup nc -v -l -p 1111 & ${crtl_n}    $
    Write Commands Until Expected Prompt    ${crtl_n}    $
    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -w 300 @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Log    ${server_output}
    Should Not Contain    ${server_output}    ${Test1}
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Sleep    20s
    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}
    Write    ${crtl_c}
    Exit From Vm Console
    Sleep    90s
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test2}
    : FOR    ${VmElement}    IN    @{VMs}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Only TCP Add Remove and Add Communication Dynamic changes in SG(Addition)
    [Documentation]    Add Remove and Add Security Group during TCP communication and check the result
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${VmElement}    @{SECURITY_GROUP}[0]
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
    Write Commands Until Expected Prompt    nohup nc -v -l -p 1111 & ${crtl_n}    $
    Write Commands Until Expected Prompt    ${crtl_n}    $
    Switch Connection    ${devstack_conn_id_2}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write    nc -w 300 @{NET1_VM_IPS}[0] 1111${crtl_n}
    Write    ${Test1}${crtl_n}
    Sleep    90s
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Should Contain    ${server_output}    ${Test1}
    Log    ${server_output}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Sleep    10s
    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test2}${crtl_n}
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Log    ${server_output}
    Exit From Vm Console
    Should Not Contain    ${server_output}    ${Test2}
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Sleep    10s
    Switch Connection    ${devstack_conn_id_2}
    Write    ${Test3}${crtl_n}
    Exit From Vm Console
    Sleep    90s
    Switch Connection    ${devstack_conn_id_1}
    ${server_output}=    Write Commands Until Expected Prompt    cat nohup.out    $
    ${server_output_1}=    Read
    Write    kill `pidof nc`
    Log    ${server_output}
    Write    ${crtl_c}
    Exit From Vm Console
    Should Contain    ${server_output}    ${Test3}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Create Network1 Components
    [Documentation]    Create Single Network and Three VM instances
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[4]
    Delete All Security Group Rules    @{SECURITY_GROUP}[4]
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VM3}=    Create List    @{NET_1_VM_INSTANCES}[2]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[4]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[4]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM3}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[4]    additional_args=--availability-zone ${zone2}
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32

TCP Communication with Two SG same zone
    [Documentation]    Check TCP Communication with ingress on SG1
    ...    Egress rule on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG different zone
    [Documentation]    Check TCP Communication with ingress on SG1
    ...    Egress rule on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[2] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[2]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG same zone Tcp port 22
    [Documentation]    Check TCP Communication with ingress tcp with port 22 on SG1
    ...    Egress tcp rule with port 22 on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG different zone Tcp port 22
    [Documentation]    Check TCP Communication with ingress tcp with port 22 on SG1
    ...    Egress tcp rule with port 22 on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[2] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[2]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG same zone Tcp port Range 20-50
    [Documentation]    Check TCP Communication with ingress tcp with port range 22 to 50 on SG1
    ...    Egress tcp rule with port range 22 to 50 on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=50    port_range_min=20    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=50    port_range_min=20    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG different zone Tcp port Range 22-50
    [Documentation]    Check TCP Communication with ingress tcp with port range 22 to 50 on SG1
    ...    Egress tcp rule with port range 22 to 50 on SG2
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=50    port_range_min=20    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=50    port_range_min=20    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[2] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[2]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[2]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

Create Network2 Components
    [Documentation]    Create Single Network and Two VM instances
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${VM1}=    Create List    @{NET_2_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[1]
    Create Vm Instances    network_2    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[4]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_2    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[4]    additional_args=--availability-zone ${zone2}
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[4]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32

TCP Communication Using VM created on Compute zone
    [Documentation]    Check communication TCP using VM created on Compute zone
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[4]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    sleep    5s
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    Connection timed out
    Log    ${output}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication Using VM created on Control zone
    [Documentation]    Check communication TCP using VM created on Control zone
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[4]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    sleep    5s
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    Connection timed out
    Log    ${output}
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[4]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[4]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

Attach Router
    [Documentation]    Attach router Between Network1 and Network2.
    Create Router    ${ROUTERS[0]}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]

TCP Communication Across the Network Compute Zone
    [Documentation]    Create Two Security Groups, SG1 with ingress tcp rule
    ...    SG2 with egress tcp rule apply SG1 to VM instance created on network1
    ...    apply SG2 to VM instance created on network2 test ssh from network2 to network1
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication Across the Network Control Zone
    [Documentation]    Create Two Security Groups, SG1 with ingress tcp rule
    ...    SG2 with egress tcp rule apply SG1 to VM instance created on network1
    ...    apply SG2 to VM instance created on network2 test ssh from network2 to network1
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG tcp egress/ingress
    [Documentation]    Check TCP Communication with ingress/egress tcp on SG1
    ...    Ingress/egress rule tcp on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG tcp egress/ingress and Protocol 6
    [Documentation]    Check TCP Communication with ingress/egress tcp on SG1
    ...    Ingress/egress rule with protocol number 6 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=6    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=6    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG tcp egress/ingress and ANY Rule
    [Documentation]    Check TCP Communication with ingress/egress tcp on SG1
    ...    Ingress/egress ANY rule on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[2]    egress
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]    first_login=False
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG tcp egress/ingress with port 1328
    [Documentation]    Check TCP Communication with ingress/egress tcp with port 1328 on SG1
    ...    Ingress/egress rule tcp with port 1328 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check TCP communication then remove SG2 from the VM's check the TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG tcp egress/ingress with port 1328 and port range 1000:2000
    [Documentation]    Check TCP Communication with ingress/egress tcp with port 1328 on SG1
    ...    Ingress/egress rule tcp with port range 1000:2000 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check TCP communication then remove SG2 from the VM's check the TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG tcp egress/ingress with port range 1000:2000
    [Documentation]    Check TCP Communication with ingress/egress tcp with port range 1000:2000 on SG1
    ...    Ingress/egress rule tcp with port range 1000:2000 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check TCP communication then remove SG2 from the VM's check the TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Two SG tcp egress/ingress with port range 1000:2000 and port 1328
    [Documentation]    Check TCP Communication with ingress/egress tcp with port range 1000:2000 on SG1
    ...    Ingress/egress rule tcp with port 1328 on SG2 create VM's using SG1 and add SG2 VM's
    ...    Check TCP communication then remove SG2 from the VM's check the TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Three SG tcp egress/ingress with Remote CIDR
    [Documentation]    Create 3 SG's(SG1,SG2,SG3) and delete all the rules
    ...    Create VM1 using SG1 and VM2 using SG3, in SG1 add tcp ingress/egress rules
    ...    with Remote CIDR as VM2 similarly in SG2 and SG2 add tcp ingress/egress rules
    ...    with Remote CIDR as VM1 add SG2 to the VM1 Check TCP communication from VM1 to VM2
    ...    then remove SG2 from the VM1 check the TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Three SG tcp egress/ingress Custom port 1328 with Remote CIDR
    [Documentation]    Create 3 SG's(SG1,SG2,SG3) and delete all the rules
    ...    Create VM1 using SG1 and VM2 using SG3, in SG1 add tcp ingress/egress rules tcp port 1328
    ...    with Remote CIDR as VM2 similarly in SG2 and SG2 add tcp ingress/egress rules tcp port 1328
    ...    with Remote CIDR as VM1 add SG2 to the VM1 Check TCP communication from VM1 to VM2
    ...    then remove SG2 from the VM1 check the TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Three SG tcp egress/ingress port Range with Remote CIDR
    [Documentation]    Create 3 SG's(SG1,SG2,SG3) and delete all the rules
    ...    Create VM1 using SG1 and VM2 using SG3, in SG1 add tcp ingress/egress rules tcp port range 1000:2000
    ...    with Remote CIDR as VM2 similarly in SG2 and SG2 add tcp ingress/egress rules tcp port range 1000:2000
    ...    with Remote CIDR as VM1 add SG2 to the VM1 Check TCP communication from VM1 to VM2
    ...    then remove SG2 from the VM1 check the TCP communication
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[3]
    Delete All Security Group Rules    @{SECURITY_GROUP}[3]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[0]/32
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[3]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SecurityGroup    @{SECURITY_GROUP}[3]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Three SG tcp egress/ingress Remote SG
    [Documentation]    Create 2 SG's(SG1,SG2) and delete all the rules
    ...    Add Ingress/Egress Tcp rule with remote SG as Default in SG1 and SG2
    ...    Create VM's using SG1 and VM2 using SG1, Add SG2 and Default Sg to the VM's
    ...    check TCP communication then remove SG2 from the VM1 check the TCP communication
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=@{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Three SG tcp egress/ingress Remote SG and Custom port
    [Documentation]    Create 2 SG's(SG1,SG2) and delete all the rules
    ...    Add Ingress/Egress Tcp rule with port 1328 and remote SG as Default in SG1 and SG2
    ...    Create VM's using SG1 and VM2 using SG1, Add SG2 and Default Sg to the VM's
    ...    check TCP communication then remove SG2 from the VM1 check the TCP communication
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=1328    port_range_min=1328    protocol=tcp    remote_group_id=@{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication with Three SG tcp egress/ingress Remote SG and Custom Port Range
    [Documentation]    Create 2 SG's(SG1,SG2) and delete all the rules
    ...    Add Ingress/Egress Tcp rule with port range 1000:2000 and remote SG as Default in SG1 and SG2
    ...    Create VM's using SG1 and VM2 using SG1, Add SG2 and Default Sg to the VM's
    ...    check TCP communication then remove SG2 from the VM1 check the TCP communication
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_group_id=@{sg_list}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=2000    port_range_min=1000    protocol=tcp    remote_group_id=@{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[2]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    port=1328
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication From DHCP to VM instance Apply SG1 First
    [Documentation]    Check TCP communication From DHCP to VM instance
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[4]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    sleep    5s
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    sleep    5s
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    Connection timed out
    Log    ${output}
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[4]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear Security Group
    ...    AND    Get Test Teardown Debugs

TCP Communication From DHCP to VM instance Apply SG2 First
    [Documentation]    Check TCP communication From DHCP to VM instance
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[4]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[2]
    sleep    5s
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Exit From Vm Console
    Remove Security Group From VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    sleep    5s
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    Connection timed out
    Log    ${output}
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[4]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Two SG Ten Vm Instance Across Network
    [Documentation]    Check TCP Communication with ingress tcp with remote CIDR
    ...    and egress tcp rule on SG1
    ...    Egress rule tcp on SG2 add SG2 to VM2 and add SG1 to all other
    ...    VM's check tcp communication from VM2 to all VMs
    ...    tcp communication should fail other than VM2
    Create Network    @{NETWORKS_NAME}[3]
    Create SubNet    @{NETWORKS_NAME}[3]    @{SUBNETS_NAME}[3]    @{SUBNETS_RANGE}[3]
    Create Network    @{NETWORKS_NAME}[4]
    Create SubNet    @{NETWORKS_NAME}[4]    @{SUBNETS_NAME}[4]    @{SUBNETS_RANGE}[4]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    ${VM1}=    Create List    @{NET_4_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_4_VM_INSTANCES}[1]
    ${VM3}=    Create List    @{NET_4_VM_INSTANCES}[2]
    ${VM4}=    Create List    @{NET_4_VM_INSTANCES}[3]
    ${VM5}=    Create List    @{NET_4_VM_INSTANCES}[4]
    Create Vm Instances    network_4    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_4    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]
    Create Vm Instances    network_4    ${VM3}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_4    ${VM4}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_4    ${VM5}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_5    ${NET_5_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{NET_4_VM_INSTANCES}    @{NET_5_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_4_VM_INSTANCES}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_5_VM_INSTANCES}
    ${NET4_VM_IPS}    ${NET4_DHCP_IP}    Collect VM IP Addresses    false    @{NET_4_VM_INSTANCES}
    ${NET5_VM_IPS}    ${NET5_DHCP_IP}    Collect VM IP Addresses    false    @{NET_5_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_4_VM_INSTANCES}    ${NET_5_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET4_VM_IPS}    ${NET5_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET4_VM_IPS}
    Set Suite Variable    ${NET4_DHCP_IP}
    Set Suite Variable    ${NET5_VM_IPS}
    Set Suite Variable    ${NET5_DHCP_IP}
    Should Not Contain    ${NET4_VM_IPS}    None
    Should Not Contain    ${NET4_DHCP_IP}    None
    Should Not Contain    ${NET5_VM_IPS}    None
    Should Not Contain    ${NET5_DHCP_IP}    None
    : FOR    ${vm}    IN    @{NET_4_VM_INSTANCES}    @{NET_5_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET4_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET4_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET4_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET5_DHCP_IP}[${index}]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET4_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    : FOR    ${vm}    IN    @{NET_4_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[3]
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[4]
    ${net_id}=    Get Net Id    network_4
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET4_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET4_VM_IPS}[0]
    Ssh From VM Instance    vm_ip=@{NET4_VM_IPS}[2]
    Ssh From VM Instance    vm_ip=@{NET4_VM_IPS}[3]
    Ssh From VM Instance    vm_ip=@{NET4_VM_IPS}[4]
    Ssh From VM Instance    vm_ip=@{NET5_VM_IPS}[0]
    Ssh From VM Instance    vm_ip=@{NET5_VM_IPS}[1]
    Ssh From VM Instance    vm_ip=@{NET5_VM_IPS}[2]
    Ssh From VM Instance    vm_ip=@{NET5_VM_IPS}[3]
    Ssh From VM Instance    vm_ip=@{NET5_VM_IPS}[4]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET4_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET4_VM_IPS}[2]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{NET_4_VM_INSTANCES}    @{NET_5_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[3]
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[4]
    Delete Router    ${ROUTERS[0]}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_5
    Delete SubNet    l2_subnet_4
    Delete Network    network_5
    Delete Network    network_4
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication Three VM with Remote SG
    [Documentation]    Check TCP Communication using Remote SG
    ...    create SG1 and SG2,make SG1 remote SG as SG2, SG2 remote SG as SG1
    ...    Create three VM's with Remote SG Check tcp between them
    ...    Remove VM's one by one and check the corresponding Flow
    ...    got removed in compute nodes
    Create Network    @{NETWORKS_NAME}[2]
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[0]
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=@{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=@{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_group_id=@{SECURITY_GROUP}[1]
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Test Netcat Operations Between Vm Instance    network_3    @{NET1_VM_IPS}[0]    network_3    @{NET1_VM_IPS}[2]
    Test Netcat Operations Between Vm Instance    network_3    @{NET1_VM_IPS}[1]    network_3    @{NET1_VM_IPS}[2]
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[1]
    Sleep    10s
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 table=243
    Should Not Contain    ${stdout}    @{NET1_VM_IPS}[1]
    Close Connection
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[2]
    Sleep    10s
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

TCP Communication with Two SG same zone Three Vm Instance
    [Documentation]    Check TCP Communication with ingress tcp on SG1
    ...    Egress rule tcp on SG2 add SG2 to VM1 and VM2 and add SG1 to
    ...    VM3 check tcp communication from VM1 to VM3, VM2 to VM3
    ...    then add SG1 to VM2 and check tcp communication from VM1 to VM2
    Create Network    @{NETWORKS_NAME}[2]
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${net_id}=    Get Net Id    network_3
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[2]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[2]
    Exit From Vm Console
    Add Security Group To VM    @{NET_3_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{NET_3_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_3
    Delete Network    network_3
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Two SG same zone Ingress/Egress TCP
    [Documentation]    Check TCP Communication with ingress on SG1
    ...    Egress rule on SG2 Apply both SG during VM creation
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VMS}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    #Add Security Group To VM    ${VM1}    @{SECURITY_GROUP}[2]
    #Add Security Group To VM    ${VM2}    @{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMS}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMS}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMS}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VMS}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Two SG different zone Ingress/Egress TCP
    [Documentation]    Check TCP Communication with ingress on SG1
    ...    Egress rule on SG2 Apply both SG during VM creation
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VMS}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone2}
    #Add Security Group To VM    ${VM1}    @{SECURITY_GROUP}[2]
    #Add Security Group To VM    ${VM2}    @{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMS}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMS}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMS}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VMS}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Two SG same zone Ingress/Egress Tcp port 22
    [Documentation]    Check TCP Communication with ingress tcp with port 22 on SG1
    ...    Egress tcp rule with port 22 on SG2 Apply both SG during VM creation
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VMS}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMS}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMS}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMS}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VMS}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Two SG different zone Ingress/Egress Tcp port 22
    [Documentation]    Check TCP Communication with ingress tcp with port 22 on SG1
    ...    Egress tcp rule with port 22 on SG2 Apply both SG during VM creation
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VMS}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone2}
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMS}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMS}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMS}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VMS}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Two SG same zone Ingress/Egress Tcp port Range 20-50
    [Documentation]    Check TCP Communication with ingress tcp with port range 22 to 50 on SG1
    ...    Egress tcp rule with port range 22 to 50 on SG2 Apply both SG during VM creation
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=50    port_range_min=20    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=50    port_range_min=20    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VMS}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMS}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMS}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMS}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VMS}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Two SG different zone Ingress/Egress Tcp port Range 22-50
    [Documentation]    Check TCP Communication with ingress tcp with port range 22 to 50 on SG1
    ...    Egress tcp rule with port range 22 to 50 on SG2 Apply both SG during VM creation
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=50    port_range_min=20    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=50    port_range_min=20    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VMS}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone1}
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--security-group @{SECURITY_GROUP}[2] --availability-zone ${zone2}
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMS}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMS}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMS}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VMS}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_1
    Delete Network    network_1
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication Across the Network Using Default SG Compute Zone
    [Documentation]    Create VM instance Using Default SG
    ...    test ssh from network2 to network1
    Create Network    @{NETWORKS_NAME}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_2    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]    additional_args=--availability-zone ${zone1}
    : FOR    ${vm}    IN    @{VM1}    @{VM2}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VM1}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VM2}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VM1}
    ${NET2_VM_IPS}    ${NET2_DHCP_IP}    Collect VM IP Addresses    false    @{VM2}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM1}    ${VM2}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}    ${NET2_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Set Suite Variable    ${NET2_VM_IPS}
    Set Suite Variable    ${NET2_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Should Not Contain    ${NET2_VM_IPS}    None
    Should Not Contain    ${NET2_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VM1}    @{VM2}
    \    Poll VM Boot Status    ${vm}
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    ${LOOP_COUNT}    Get Length    ${NET2_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VM1}    @{VM2}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    l2_subnet_1
    Delete SubNet    l2_subnet_2
    Delete Network    network_1
    Delete Network    network_2
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication Across the Network Using Default SG Control Zone
    [Documentation]    Create VM instance Using Default SG
    ...    test ssh from network2 to network1
    Create Network    @{NETWORKS_NAME}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]    additional_args=--availability-zone ${zone1}
    Create Vm Instances    network_2    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]    additional_args=--availability-zone ${zone1}
    : FOR    ${vm}    IN    @{VM1}    @{VM2}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VM1}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VM2}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VM1}
    ${NET2_VM_IPS}    ${NET2_DHCP_IP}    Collect VM IP Addresses    false    @{VM2}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM1}    ${VM2}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}    ${NET2_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Set Suite Variable    ${NET2_VM_IPS}
    Set Suite Variable    ${NET2_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Should Not Contain    ${NET2_VM_IPS}    None
    Should Not Contain    ${NET2_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VM1}    @{VM2}
    \    Poll VM Boot Status    ${vm}
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    ${LOOP_COUNT}    Get Length    ${NET2_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VM1}    @{VM2}
    \    Poll VM Boot Status    ${vm}
    ${net_id}=    Get Net Id    network_2
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VM1}    @{VM2}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    l2_subnet_1
    Delete SubNet    l2_subnet_2
    Delete Network    network_1
    Delete Network    network_2
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Two SG five Vm Instance Same Network
    [Documentation]    Check TCP Communication with ingress tcp with remote CIDR
    ...    and egress tcp rule on SG1
    ...    Egress rule tcp on SG2 add SG2 to VM2 and add SG1 to VM1,VM3,VM4
    ...    VM5 check tcp communication from VM2 to all VMs
    ...    tcp communication should fail other than VM2
    Create Network    @{NETWORKS_NAME}[3]
    Create SubNet    @{NETWORKS_NAME}[3]    @{SUBNETS_NAME}[3]    @{SUBNETS_RANGE}[3]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    ${VM1}=    Create List    @{NET_4_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_4_VM_INSTANCES}[1]
    ${VM3}=    Create List    @{NET_4_VM_INSTANCES}[2]
    ${VM4}=    Create List    @{NET_4_VM_INSTANCES}[3]
    ${VM5}=    Create List    @{NET_4_VM_INSTANCES}[4]
    Create Vm Instances    network_4    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_4    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[2]
    Create Vm Instances    network_4    ${VM3}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_4    ${VM4}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_4    ${VM5}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{NET_4_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_4_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_4_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_4_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{NET_4_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=@{NET1_VM_IPS}[1]/32
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    : FOR    ${vm}    IN    @{NET_4_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${net_id}=    Get Net Id    network_4
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[0]
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[2]
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[3]
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[4]
    Exit From Vm Console
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[2]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{NET_4_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Delete SecurityGroup    @{SECURITY_GROUP}[2]
    Delete SubNet    l2_subnet_4
    Delete Network    network_4
    [Teardown]    Run Keywords    Clear L2_Network

TCP Communication with Custom SG tcp egress/ingress and Default SG
    [Documentation]    Check TCP Communication with ingress/egress tcp on SG1
    ...    and Default SG ,create VM1 using SG1 and VM2 using default SG
    ...    add SG1 to VM2 Check TCP communication then remove SG1 from VM2
    ...    Check TCP communication
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    ${VMS}=    Create List    @{NET_1_VM_INSTANCES}[0]    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VMS}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VMS}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VMS}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{VMS}
    \    Poll VM Boot Status    ${vm}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[1]
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Ssh From VM Instance Should Not Succeed    vm_ip=@{NET1_VM_IPS}[1]
    Exit From Vm Console
    : FOR    ${VmElement}    IN    @{VMS}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
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
