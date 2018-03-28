*** Settings ***
Documentation     Test suite to verify communication within and across networks
...               by changing security group rules.
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
@{SECURITY_GROUP}    sg-remote    sg_additional    sg_dhcp
@{NETWORKS_NAME}    network_1    network_2
@{NETWORKS_IPV6}    NET1_IPV6
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{SUBNETS_IPV6}    SUBNET1_IPV6
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{NET_2_VM_INSTANCES}    MyThirdInstance_3
@{IPV6_VM}        VM1_IPV6    VM2_IPV6
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
@{SUBNETS_CIDR}    2001:db8:0:2::/64
${NET1_ADDR_POOL}    --allocation-pool start=2001:db8:0:2::2,end=2001:db8:0:2:ffff:ffff:ffff:fffe
@{ROUTERS}        router1    router2
@{NETWORK_GW}     30.0.0.1    40.0.0.1
@{VM_INSTANCES_FLOATING}    VmInstanceFloating1    VmInstanceFloating2
@{VM_INSTANCES_SNAT}    VmInstanceSnat3    VmInstanceSnat4
${external_gateway}    101.0.0.250
@{external_pnf}    101.0.0.1    101.0.0.2
${pnf_password}    automation
${pnf_user}       root
${pnf_prompt}     \    #
${external_subnet}    101.0.0.0/24
${external_subnet_allocation_pool}    start=101.0.0.5,end=101.0.0.249
${external_net_name}    external-net
${external_subnet_name}    external-subnet
@{PROVIDER}       flat1    flat2
${password}       cubswin:)
${user}           cirros
${fed_user}       fedora
${Test1}          Data1
${Test2}          Data2

*** Test Cases ***
Create Zone
    [Documentation]    Create Availabilityzone create for test suite
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None
    #Default SG

Create Network1 Components(DefaultSG)
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    [Tags]    Ex1
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=@{sg_list}[0]    min=1    max=1    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    100s    5s    Collect VM IP Addresses
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    @{SECURITY_GROUP}[2]

Create Network2 Components(DefaultSG)
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_VM_INSTANCES}    sg=@{sg_list}[0]    min=1    max=1    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    100s    5s    Collect VM IP Addresses
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    @{SECURITY_GROUP}[2]

IP address distribution during VM creation(IPV4)
    [Documentation]    check VM gets IP address from DHCP agent
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Should Not Contain    ${NET2_VM_IPS}    None
    Should Not Contain    ${NET2_DHCP_IP}    None
    [Teardown]    Run Keywords    Get Test Teardown Debugs

IP address distribution during VM creation(IPV6)
    [Documentation]    create VM instance and check VM gets IP address from DHCPV6 agent
    [Tags]    run
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_IPV6}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS[1]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[1]}
    ${router_list} =    Create List    ${ROUTERS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[1]}    @{SUBNETS_IPV6}[0]
    Create Vm Instances DefaultSG    NET1_IPV6    ${IPV6_VM}    image=cirros    flavor=cirros
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
    : FOR    ${VmElement}    IN    @{IPV6_VM}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[1]}    @{SUBNETS_IPV6}[0]
    Delete Router    ${ROUTERS[1]}
    Delete SubNet    @{SUBNETS_IPV6}[0]
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Attach Router
    [Documentation]    Attach router Between Network1 and Network2.
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    ${ROUTERS[0]}    ${interface}

System assigned IP(Default SG)
    [Documentation]    Check communication ICMP using system assigned IP
    ${dst_ip}    Create List    40.0.0.2    40.0.0.1
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${dst_ip}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

System assigned MAC(Default SG)
    [Documentation]    Check communication ICMP using system assigned MAC
    ${dst_ip}    Create List    40.0.0.2    40.0.0.1
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${dst_ip}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

ICMP Communication within the Network (Default SG)
    [Documentation]    Check ICMP Communication within Network using Default SG
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${NET1_VM_IPS}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

ICMP Communication Across the Network (Default SG)
    [Documentation]    Check ICMP Communication Across Network using Default SG
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${NET2_VM_IPS}
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${NET2_VM_IPS}
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${NET1_VM_IPS}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication within the Network (Default SG)
    [Documentation]    Check TCP Communication within the Network using
    ...    Default SG
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication Across the Network (Default SG)
    [Documentation]    Check TCP Communication Across Network using Default SG
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

UDP Communication within the Network (Default SG)
    [Documentation]    Check UDP Communication within the Network using
    ...    Default SG
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    [Teardown]    Run Keywords    Get Test Teardown Debugs

UDP Communication Across the Network (Default SG)
    [Documentation]    Check UDP Communication Across Network using Default SG
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Create External (Default SG)
    [Documentation]    Create External network and Attach to internal network
    [Tags]    Ex1
    Create Network    ${external_net_name}    --provider-network-type flat --provider-physical-network @{PROVIDER}[0]
    Update Network    ${external_net_name}    --external
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Gateway    ${ROUTERS[0]}    ${external_net_name}
    ${VM_FLOATING_IPS}    OpenStackOperations.Create And Associate Floating IPs    ${external_net_name}    @{NET_1_VM_INSTANCES}
    Set Suite Variable    ${VM_FLOATING_IPS}

ICMP Communication External to Internal(Default SG)
    [Documentation]    Check ICMP Communication from External network to Internal VM instance
    ...    Using Default Security group
    #[Tags]    Ex
    ${rc}    ${output}=    Run And Return Rc And Output    ping -c 5 @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    [Teardown]    Run Keywords    Get Test Teardown Debugs

ICMP Communication Internal to External(Default SG)
    [Documentation]    Check ICMP Communication from Internal network Vm instance to External Host
    ...    Using Default Security group
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping -c 20 @{external_pnf}[0]    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    Should Contain    ${output}    64 bytes
    Exit From Vm Console
    #${des_ip}=    Create List    @{external_pnf}[0]
    #Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip}    ping_should_succeed=True
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication Internal to External(Default SG)
    [Documentation]    Check TCP Communication from Internal network Vm instance to External Host
    ...    Using Default Security group
    #[Tags]    Ex
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ssh ${pnf_user}@@{external_pnf}[0]    (y/n)
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    y    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${pnf_password}    ${pnf_prompt}
    Log    ${output}
    Exit From Vm Console
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication External to Internal(Default SG)
    [Documentation]    Check TCP Communication from External network to Internal VM instance
    ...    Using Default Security group
    [Tags]    Ex
    ${rc}    ${output}    Run And Return Rc And Output    ssh -o ConnectTimeout=10 ${user}@@{VM_FLOATING_IPS}[0]
    Should Contain Any    ${output}    Connection timed out    No route to host    Connection refused
    [Teardown]    Run Keywords    Get Test Teardown Debugs

UDP Communication Internal To External(Default SG)
    [Documentation]    Check UDP Communication from Internal network to External Host
    ...    Using Default Security group
    [Tags]    Ex1
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    #${crtl_c}    Evaluate    chr(int(3))
    #${crtl_n}    Evaluate    chr(int(13))
    #${client_data}    Set Variable    Test Client Data
    #${server_data}    Set Variable    Test Server Data
    #${robot_vm}=    Get Ssh Connection    127.0.0.1    ${pnf_user}    ${pnf_password}    ${pnf_prompt}
    #Switch Connection    ${robot_vm}
    #${output}=    Write    nc -u -l -p 1328 >out_file &
    ##Write    sh /root/nc.sh
    #${rc}    ${output}    Run And Return Rc And Output    sudo netstat -nlap | grep 1328
    #Log    ${output}
    #${devstack_conn_id_1}=    Get ControlNode Connection
    #Switch Connection    ${devstack_conn_id_1}
    #${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    #${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    #${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    #Log    ${output}
    #${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    #Write    echo "${client_data}" >> test_file
    #Write    echo "${client_data}" >> test_file
    #Write    echo "${client_data}" >> test_file
    #Write    echo "${client_data}" >> test_file
    #Write    echo "${client_data}" >> test_file
    #Write    nc -u @{external_pnf}[0] 1328 < test_file
    #Switch Connection    ${robot_vm}
    #${server_output}=    Write Commands Until Expected Prompt    cat out_file    ${pnf_prompt}
    #Log    ${server_output}
    #Write    kill -9 `pidof nc`
    #Switch Connection    ${devstack_conn_id_1}
    #Write    ${crtl_c}
    #Exit From Vm Console
    #Should Contain    ${server_output}    ${client_data}
    #${nc_output}=    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    sudo echo "${client_data}" | nc -v -w 5 -u @{external_pnf}[0] 1328
    #Log    ${nc_output}
    #${rc}    ${output}    Run And Return Rc And Output    kill -9 `pidof nc`
    #${rc}    ${output}    Run And Return Rc And Output    ps -ef | grep nc
    #Should Match Regexp    ${nc_output}    ${server_data}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

UDP Communication External to Internal(Default SG)
    [Documentation]    Check UDP Communication from External network to Internal VM instance
    ...    Using Default Security group
    #[Tags]    Ex1
    Test Netcat Operations To Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{VM_FLOATING_IPS}[0]    additional_args=-u    port=1328    nc_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS[0]}
    Delete Network    network_1
    Delete Network    ${external_net_name}
    #Default SG all rules removed
    [Teardown]    Run Keywords    Clear L2_Network

Create Network1 Components(DefaultSG Rules Removed)
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    [Tags]    Ex2
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    Delete All Security Group Rules    @{sg_list}[${INDEX}]
    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Delete All Security Group Rules    @{SECURITY_GROUP}[2]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=@{sg_list}[0]    min=1    max=1    image=cirros
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
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    @{SECURITY_GROUP}[2]

Create Network2 Components(DefaultSG Rules Removed)
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_VM_INSTANCES}    sg=@{sg_list}[0]    min=1    max=1    image=cirros
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
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Add Security Group To VM    ${vm}    @{SECURITY_GROUP}[2]

IP address distribution during VM creation Without SG Rules(IPV4)
    [Documentation]    create VM instance and check VM gets IP address from DHCP agent
    ...    using Default SG without rules
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Should Not Contain    ${NET2_VM_IPS}    None
    Should Not Contain    ${NET2_DHCP_IP}    None
    [Teardown]    Run Keywords    Get Test Teardown Debugs

IP address distribution during VM creation Without SG Rules(IPV6)
    [Documentation]    create VM instance and check VM gets IP address from DHCPV6 agent
    ...    using Default SG without rules
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_IPV6}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Create Router    ${ROUTERS[1]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[1]}
    ${router_list} =    Create List    ${ROUTERS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[1]}    @{SUBNETS_IPV6}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Create Vm Instances DefaultSG    NET1_IPV6    ${IPV6_VM}    image=cirros    flavor=cirros
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
    : FOR    ${VmElement}    IN    @{IPV6_VM}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[1]}    @{SUBNETS_IPV6}[0]
    Delete Router    ${ROUTERS[1]}
    Delete SubNet    @{SUBNETS_IPV6}[0]
    Delete Network    @{NETWORKS_IPV6}[0]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

System assigned IP(Default SG rules removed)
    [Documentation]    Check communication ICMP using system assigned IP
    ...    using Default SG without rules
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${dst_ip}    Create List    40.0.0.2    40.0.0.1
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${dst_ip}    ping_should_succeed=False
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

System assigned MAC(Default SG rules removed)
    [Documentation]    Check communication ICMP using system assigned MAC
    ...    using Default SG without rules
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${dst_ip}    Create List    40.0.0.2    40.0.0.1
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${dst_ip}    ping_should_succeed=False
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

ICMP Communication within the Network (Default SG rules removed)
    [Documentation]    Check ICMP Communication within Network using Default SG
    ...    without Rules
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    ${des_ip_2}=    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip_1}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip_2}    ping_should_succeed=False
    [Teardown]    Run Keywords    Get Test Teardown Debugs

ICMP Communication Across the Network (Default SG rules removed)
    [Documentation]    Check ICMP Communication Across Network using Default SG
    ...    without Rules
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${NET2_VM_IPS}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${NET2_VM_IPS}    ping_should_succeed=False
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${NET1_VM_IPS}    ping_should_succeed=False
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication within the Network (Default SG rules removed)
    [Documentation]    Check TCP Communication within the Network using
    ...    Default SG without rules
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication Across the Network (Default SG rules removed)
    [Documentation]    Check TCP Communication Across Network using Default SG
    ...    without rules
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

UDP Communication within the Network (Default SG rules removed)
    [Documentation]    Check UDP Communication within the Network using
    ...    Default SG without rules
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    nc_should_succeed=False    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False    additional_args=-u
    [Teardown]    Run Keywords    Get Test Teardown Debugs

UDP Communication Across the Network (Default SG rules removed)
    [Documentation]    Check UDP Communication Across Network using Default SG
    ...    without rules
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    nc_should_succeed=False    additional_args=-u
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    nc_should_succeed=False    additional_args=-u
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Create External (Default SG rules removed)
    [Documentation]    Create External network and Attach to internal network
    [Tags]    Ex2
    Create Network    ${external_net_name}    --provider-network-type flat --provider-physical-network @{PROVIDER}[0]
    Update Network    ${external_net_name}    --external
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Gateway    ${ROUTERS[0]}    ${external_net_name}
    ${VM_FLOATING_IPS}    OpenStackOperations.Create And Associate Floating IPs    ${external_net_name}    @{NET_1_VM_INSTANCES}
    Set Suite Variable    ${VM_FLOATING_IPS}

ICMP Communication External to Internal(Default SG Rules Removed)
    [Documentation]    Check ICMP Communication from External network to Internal VM instance
    ...    Using Default Security group
    ${rc}    ${output}=    Run And Return Rc And Output    ping -c 5 @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    [Teardown]    Run Keywords    Get Test Teardown Debugs

ICMP Communication Internal to External(Default SG Rules Removed)
    [Documentation]    Check ICMP Communication from Internal network Vm instance to External Host
    ...    Using Default Security group
    ${des_ip}=    Create List    @{external_pnf}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${des_ip}    ping_should_succeed=False
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${des_ip}    ping_should_succeed=False
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication Internal to External(Default SG Rules Removed)
    [Documentation]    Check TCP Communication from Internal network Vm instance to External Host
    ...    Using Default Security group
    [Tags]    Ex2
    Execute Command on VM Instance    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[0]    ssh -o ConnectTimeout=10 ${pnf_user}@${password}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

TCP Communication External to Internal(Default SG Rules Removed)
    [Documentation]    Check TCP Communication from External network to Internal VM instance
    ...    Using Default Security group
    ${rc}    ${output}    Run And Return Rc And Output    ssh -o ConnectTimeout=10 ${user}@@{VM_FLOATING_IPS}[0]
    Should Contain Any    ${output}    Connection timed out    No route to host    Connection refused
    [Teardown]    Run Keywords    Get Test Teardown Debugs

UDP Communication External to Internal(Default SG Rules Removed)
    [Documentation]    Check UDP Communication from External network to Internal VM instance
    ...    Using Default Security group
    Test Netcat Operations To Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[0]    additional_args=-u    port=1328    nc_should_succeed=False
    [Teardown]    Run Keywords    Get Test Teardown Debugs

UDP Communication Internal To External(Default SG Rules Removed)
    [Documentation]    Check UDP Communication from Internal network to External Host
    ...    Using Default Security group Rules Removed
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    ${rc}    ${output}    Run And Return Rc And Output    ( ( echo "${server_data}" | sudo timeout 60 nc -l -u 1328 ) & )
    Log    ${output}
    ${rc}    ${output}    Run And Return Rc And Output    sudo netstat -nlap | grep ${port}
    Log    ${output}
    ${nc_output}=    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    sudo echo "${client_data}" | nc -v -w 5 -u @{external_pnf}[0] 1328
    Log    ${nc_output}
    ${rc}    ${output}    Run And Return Rc And Output    kill -9 `pidof nc`
    Should Not Match Regexp    ${nc_output}    ${server_data}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS[0]}
    Delete Network    network_1
    Delete Network    ${external_net_name}
    #Own SG no rules added
    [Teardown]    Run Keywords    Clear L2_Network

IP address distribution during VM creation(IPV4 Own SG)
    [Documentation]    create VM instance and check VM gets IP address from DHCP agent
    [Tags]    NA    using Own Security Group
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
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
    [Teardown]    Run Keywords    Clear L2_Network

IP address distribution during VM creation(IPV6 Own SG)
    [Documentation]    create VM instance and check VM gets IP address from DHCPV6 agent
    [Tags]    NA    using Own Security Group
    Create Network    @{NETWORKS_IPV6}[0]
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_ADDR_POOL}
    Create SubNet    @{NETWORKS_IPV6}[0]    @{SUBNETS_IPV6}[0]    @{SUBNETS_CIDR}[0]    ${net1_additional_args}
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Create Router    ${ROUTERS[1]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[1]}
    ${router_list} =    Create List    ${ROUTERS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[1]}    @{SUBNETS_IPV6}[0]
    Create Vm Instances    NET1_IPV6    ${IPV6_VM}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
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
    : FOR    ${VmElement}    IN    @{IPV6_VM}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[1]}    @{SUBNETS_IPV6}[0]
    Delete Router    ${ROUTERS[1]}
    Delete SubNet    @{SUBNETS_IPV6}[0]
    Delete Network    @{NETWORKS_IPV6}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear L2_Network

System assigned IP(Own SG)
    [Documentation]    Check communication ICMP using system assigned IP
    [Tags]    NA
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Create Vm Instances    network_2    ${NET_2_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
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
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${LOOP_COUNT}    Get Length    ${NET2_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32
    ${dst_ip_1}    Create List    40.0.0.2
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${dst_ip_1}
    ${dst_ip_2}    Create List    40.0.0.1
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${dst_ip_2}    ping_should_succeed=False
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

System assigned MAC(Own SG)
    [Documentation]    Check communication ICMP using system assigned MAC
    [Tags]    NA
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${dst_ip_1}    Create List    40.0.0.2
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${dst_ip_1}
    ${dst_ip_2}    Create List    40.0.0.1
    Test Operations From Vm Instance    network_2    @{NET2_VM_IPS}[0]    ${dst_ip_2}    ping_should_succeed=False
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    l2_subnet_2
    Delete Network    network_2
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Non System assigned IP(Default SG)
    [Documentation]    Check communication ICMP using Non system assigned IP
    [Tags]    NA
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    #Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image fedora --flavor fedora --nic net-id=@{NETWORKS_NAME}[0] --nic net-id=@{NETWORKS_NAME}[1] --security-group @{sg_list}[0] --key-name vm_keys @{NET_1_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${NET1_VM_IPS}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${NET2_VM_IPS}    Collect IP    @{NET_2_VM_INSTANCES}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Set Suite Variable    ${NET2_VM_IPS}
    Should Not Contain    ${NET2_VM_IPS}    None
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM UP Boot Status    ${vm}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${fed_user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${MAC_Line}=    Write Commands Until Expected Prompt    ip link show eth1 | awk '/ether/ {print $2}'    $
    ${MAC}    Split String    ${MAC_Line}    \n
    Log    @{MAC}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo cat <<EOF >ifcfg-eth1    >
    ${output}=    Write Commands Until Expected Prompt    BOOTPROTO=dhcp    >
    ${output}=    Write Commands Until Expected Prompt    DEVICE=eth1    >
    ${output}=    Write Commands Until Expected Prompt    HWADDR=@{MAC}[0]    >
    ${output}=    Write Commands Until Expected Prompt    ONBOOT=yes    >
    ${output}=    Write Commands Until Expected Prompt    TYPE=Ethernet    >
    ${output}=    Write Commands Until Expected Prompt    USERCTL=no    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${output}=    Write Commands Until Expected Prompt    sudo cp ifcfg-eth1 /etc/sysconfig/network-scripts/.    $
    ${output}=    Write Commands Until Expected Prompt    sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo ifup eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 50.0.0.7 netmask 255.255.255.0    $
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.1    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    Write    exit
    : FOR    ${VmElement}    IN    @{VM1}    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Non System assigned MAC(Default SG)
    [Documentation]    Check communication ICMP using Non system assigned MAC
    [Tags]    NA
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    #Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image fedora --flavor fedora --nic net-id=@{NETWORKS_NAME}[0] --nic net-id=@{NETWORKS_NAME}[1] --security-group @{sg_list}[0] --key-name vm_keys @{NET_1_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${NET1_VM_IPS}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${NET2_VM_IPS}    Collect IP    @{NET_2_VM_INSTANCES}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Set Suite Variable    ${NET2_VM_IPS}
    Should Not Contain    ${NET2_VM_IPS}    None
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM UP Boot Status    ${vm}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${fed_user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${MAC_Line}=    Write Commands Until Expected Prompt    ip link show eth1 | awk '/ether/ {print $2}'    $
    ${MAC}    Split String    ${MAC_Line}    \n
    Log    @{MAC}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo cat <<EOF >ifcfg-eth1    >
    ${output}=    Write Commands Until Expected Prompt    BOOTPROTO=dhcp    >
    ${output}=    Write Commands Until Expected Prompt    DEVICE=eth1    >
    ${output}=    Write Commands Until Expected Prompt    HWADDR=@{MAC}[0]    >
    ${output}=    Write Commands Until Expected Prompt    ONBOOT=yes    >
    ${output}=    Write Commands Until Expected Prompt    TYPE=Ethernet    >
    ${output}=    Write Commands Until Expected Prompt    USERCTL=no    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${output}=    Write Commands Until Expected Prompt    sudo cp ifcfg-eth1 /etc/sysconfig/network-scripts/.    $
    ${output}=    Write Commands Until Expected Prompt    sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo ifup eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 down    $
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 hw ether aa:aa:aa:aa:aa:aa    $
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 up    $
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.1    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    Write    exit
    : FOR    ${VmElement}    IN    @{VM1}    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Non System assigned IP(Default SG Rules Removed)
    [Documentation]    Check communication ICMP using Non system assigned IP
    [Tags]    NA
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image fedora --flavor fedora --nic net-id=@{NETWORKS_NAME}[0] --nic net-id=@{NETWORKS_NAME}[1] --security-group @{sg_list}[0] --key-name vm_keys @{NET_1_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${NET1_VM_IPS}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${NET2_VM_IPS}    Collect IP    @{NET_2_VM_INSTANCES}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Set Suite Variable    ${NET2_VM_IPS}
    Should Not Contain    ${NET2_VM_IPS}    None
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM UP Boot Status    ${vm}
    Delete All Security Group Rules    @{sg_list}[0]
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${fed_user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${MAC_Line}=    Write Commands Until Expected Prompt    ip link show eth1 | awk '/ether/ {print $2}'    $
    ${MAC}    Split String    ${MAC_Line}    \n
    Log    @{MAC}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo cat <<EOF >ifcfg-eth1    >
    ${output}=    Write Commands Until Expected Prompt    BOOTPROTO=dhcp    >
    ${output}=    Write Commands Until Expected Prompt    DEVICE=eth1    >
    ${output}=    Write Commands Until Expected Prompt    HWADDR=@{MAC}[0]    >
    ${output}=    Write Commands Until Expected Prompt    ONBOOT=yes    >
    ${output}=    Write Commands Until Expected Prompt    TYPE=Ethernet    >
    ${output}=    Write Commands Until Expected Prompt    USERCTL=no    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${output}=    Write Commands Until Expected Prompt    sudo cp ifcfg-eth1 /etc/sysconfig/network-scripts/.    $
    ${output}=    Write Commands Until Expected Prompt    sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo ifup eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 50.0.0.7 netmask 255.255.255.0    $
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.1    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    Write    exit
    : FOR    ${VmElement}    IN    @{VM1}    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Non System assigned MAC(Default SG Rules Removed)
    [Documentation]    Check communication ICMP using Non system assigned MAC
    [Tags]    NA
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image fedora --flavor fedora --nic net-id=@{NETWORKS_NAME}[0] --nic net-id=@{NETWORKS_NAME}[1] --security-group @{sg_list}[0] --key-name vm_keys @{NET_1_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${NET1_VM_IPS}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${NET2_VM_IPS}    Collect IP    @{NET_2_VM_INSTANCES}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Set Suite Variable    ${NET2_VM_IPS}
    Should Not Contain    ${NET2_VM_IPS}    None
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM UP Boot Status    ${vm}
    Delete All Security Group Rules    @{sg_list}[0]
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${fed_user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${MAC_Line}=    Write Commands Until Expected Prompt    ip link show eth1 | awk '/ether/ {print $2}'    $
    ${MAC}    Split String    ${MAC_Line}    \n
    Log    @{MAC}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo cat <<EOF >ifcfg-eth1    >
    ${output}=    Write Commands Until Expected Prompt    BOOTPROTO=dhcp    >
    ${output}=    Write Commands Until Expected Prompt    DEVICE=eth1    >
    ${output}=    Write Commands Until Expected Prompt    HWADDR=@{MAC}[0]    >
    ${output}=    Write Commands Until Expected Prompt    ONBOOT=yes    >
    ${output}=    Write Commands Until Expected Prompt    TYPE=Ethernet    >
    ${output}=    Write Commands Until Expected Prompt    USERCTL=no    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${output}=    Write Commands Until Expected Prompt    sudo cp ifcfg-eth1 /etc/sysconfig/network-scripts/.    $
    ${output}=    Write Commands Until Expected Prompt    sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo ifup eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 down    $
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 hw ether aa:aa:aa:aa:aa:aa    $
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 up    $
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.1    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    Write    exit
    : FOR    ${VmElement}    IN    @{VM1}    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Non System assigned IP(Own SG)
    [Documentation]    Check communication ICMP using Non system assigned IP
    [Tags]    NA
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image fedora --flavor fedora --nic net-id=@{NETWORKS_NAME}[0] --nic net-id=@{NETWORKS_NAME}[1] --security-group @{SECURITY_GROUP}[1] --key-name vm_keys @{NET_1_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${NET1_VM_IPS}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${NET2_VM_IPS}    Collect IP    @{NET_2_VM_INSTANCES}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Set Suite Variable    ${NET2_VM_IPS}
    Should Not Contain    ${NET2_VM_IPS}    None
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM UP Boot Status    ${vm}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${fed_user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${MAC_Line}=    Write Commands Until Expected Prompt    ip link show eth1 | awk '/ether/ {print $2}'    $
    ${MAC}    Split String    ${MAC_Line}    \n
    Log    @{MAC}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo cat <<EOF >ifcfg-eth1    >
    ${output}=    Write Commands Until Expected Prompt    BOOTPROTO=dhcp    >
    ${output}=    Write Commands Until Expected Prompt    DEVICE=eth1    >
    ${output}=    Write Commands Until Expected Prompt    HWADDR=@{MAC}[0]    >
    ${output}=    Write Commands Until Expected Prompt    ONBOOT=yes    >
    ${output}=    Write Commands Until Expected Prompt    TYPE=Ethernet    >
    ${output}=    Write Commands Until Expected Prompt    USERCTL=no    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${output}=    Write Commands Until Expected Prompt    sudo cp ifcfg-eth1 /etc/sysconfig/network-scripts/.    $
    ${output}=    Write Commands Until Expected Prompt    sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo ifup eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 50.0.0.7 netmask 255.255.255.0    $
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.1    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    Write    exit
    : FOR    ${VmElement}    IN    @{VM1}    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Non System assigned MAC(Own SG)
    [Documentation]    Check communication ICMP using Non system assigned MAC
    [Tags]    NA
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image fedora --flavor fedora --nic net-id=@{NETWORKS_NAME}[0] --nic net-id=@{NETWORKS_NAME}[1] --security-group @{SECURITY_GROUP}[1] --key-name vm_keys @{NET_1_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${NET1_VM_IPS}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${NET2_VM_IPS}    Collect IP    @{NET_2_VM_INSTANCES}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Set Suite Variable    ${NET2_VM_IPS}
    Should Not Contain    ${NET2_VM_IPS}    None
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM UP Boot Status    ${vm}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${fed_user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${MAC_Line}=    Write Commands Until Expected Prompt    ip link show eth1 | awk '/ether/ {print $2}'    $
    ${MAC}    Split String    ${MAC_Line}    \n
    Log    @{MAC}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo cat <<EOF >ifcfg-eth1    >
    ${output}=    Write Commands Until Expected Prompt    BOOTPROTO=dhcp    >
    ${output}=    Write Commands Until Expected Prompt    DEVICE=eth1    >
    ${output}=    Write Commands Until Expected Prompt    HWADDR=@{MAC}[0]    >
    ${output}=    Write Commands Until Expected Prompt    ONBOOT=yes    >
    ${output}=    Write Commands Until Expected Prompt    TYPE=Ethernet    >
    ${output}=    Write Commands Until Expected Prompt    USERCTL=no    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${output}=    Write Commands Until Expected Prompt    sudo cp ifcfg-eth1 /etc/sysconfig/network-scripts/.    $
    ${output}=    Write Commands Until Expected Prompt    sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo ifup eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 down    $
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 hw ether aa:aa:aa:aa:aa:aa    $
    ${output}=    Write Commands Until Expected Prompt    sudo ifconfig eth1 up    $
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.2    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 40.0.0.1    $
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    Write    exit
    : FOR    ${VmElement}    IN    @{VM1}    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[1]
    Delete Router    ${ROUTERS[0]}
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    Should Not Be True    ${rc}
    [Teardown]    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2
