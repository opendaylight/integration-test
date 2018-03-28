*** Settings ***
Documentation     Test suite to check communication within and across networks.
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
${SECURITY_GROUP3}    sg-dhcp
@{NETWORKS_NAME}    l2_network_1    l2_network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_GRP_NAME}    NET1-VM
@{NET_2_VM_GRP_NAME}    NET2-VM
@{NET_1_VM_INSTANCES_MAX}    NET1-VM-1    NET1-VM-2
@{NET_2_VM_INSTANCES_MAX}    NET2-VM-1    NET2-VM-2
@{NET_1_VM_INSTANCES}    NET1-VM-1    NET1-VM-2
@{NET_2_VM_INSTANCES}    NET2-VM-1    NET2-VM-2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
@{port}           1111    2222    234    1234    6    17    50
...               51    132    136
@{uriOutput}      "admin-state-up":
${user}           cirros
${password}       cubswin:)
${external_gateway}    101.0.0.250
@{external_pnf}    101.0.0.1    101.0.0.2
${pnf_password}    automation
${pnf_user}       root
${pnf_prompt}     \    #
${external_subnet}    101.0.0.0/24
${external_subnet_allocation_pool}    start=101.0.0.18,end=101.0.0.248
${EXTERNAL_NET_NAME}    external-net-1
${EXTERNAL_SUBNET_NAME}    external-subnet-1
${PROVIDER}       flat1
${Test1}          Data1
${Test2}          Data2

*** Test Cases ***
Create Network1 Components
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP3}
    Delete All Security Group Rules    ${SECURITY_GROUP3}
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP3}    min=2    max=2    image=cirros
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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    ${SECURITY_GROUP3}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32

Create Network2 Components
    [Documentation]    Create Single Network and Two VM instances
    ...    add Sg rule login to the VM instance from DHCP Namespace
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_VM_GRP_NAME}    sg=${SECURITY_GROUP3}    min=2    max=2    image=cirros
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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    ${SECURITY_GROUP3}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32

Attach Router
    [Documentation]    Attach router Between Network1 and Network2.
    Create Router    router_1
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}

Permit ALL icmp protocol
    [Documentation]    Permit ALL icmp communication.
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{sg_list}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit tcp protocol
    [Documentation]    permit tcp communication.
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[4]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit udp protocol
    [Documentation]    permit udp communication.
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[5]    additional_args=-u
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit ALL ICMP across networks
    [Documentation]    Permit icmp communication.
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[0]    @{sg_list}[0]
    Add Security Group To VM    @{NET_2_VM_INSTANCES}[1]    @{sg_list}[0]
    ${dst_list}=    Create List    @{NET1_VM_IPS}    @{NET2_VM_IPS}
    Log    ${dst_list}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${dst_list}
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[0]    ${dst_list}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit tcp all protocol across networks
    [Documentation]    permit cidr for tcp all communication.
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit udp all protocol across networks
    [Documentation]    permit cidr for udp all communication.
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP3}
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Remove Interface    router_1    ${interface}
    Delete Router    router_1
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
    [Teardown]    Run Keywords    Clear L2_Network

Permit TCP in External Networks
    [Documentation]    Create External network and check tcp communication between VM and External host
    [Tags]    Ex
    Create Network    ${EXTERNAL_NET_NAME}    --external --provider-network-type flat --provider-physical-network ${PROVIDER}
    Create SubNet    ${EXTERNAL_NET_NAME}    ${EXTERNAL_SUBNET_NAME}[0]    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create Router    router_1
    Add Router Interface    router_1    @{SUBNETS_NAME}[0]
    Add Router Gateway    router_1    ${EXTERNAL_NET_NAME}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    min=2    max=2    image=cirros    flavor=cirros
    ...    sg=@{sg_list}[0]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    Neutron Security Group Create    ${SECURITY_GROUP}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Add Security Group To VM    @{NET_1_VM_INSTANCES_MAX}[0]    ${SECURITY_GROUP}
    Add Security Group To VM    @{NET_1_VM_INSTANCES_MAX}[1]    ${SECURITY_GROUP}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    300s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    ${devstack_conn_id}=    Get ControlNode Connection
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

Permit UDP in External Networks
    [Documentation]    Create External network and check udp communication between VM and External host
    [Tags]    Ex
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit ICMP in External Networks
    [Documentation]    Create External network and check icmp communication between VM and External host
    [Tags]    Ex
    ${dst_list}=    Create List    @{NET1_VM_IPS}    @{external_pnf}[0]
    Log    ${dst_list}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${dst_list}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit ICMP in External Networks with FIP
    [Documentation]    Create External network and check icmp communication between VM and External host
    [Tags]    Ex
    @{ip_list}=    Create And Associate Floating IPs    ${EXTERNAL_NET_NAME}    @{NET_1_VM_INSTANCES}[0]
    Set Suite Variable    ${ip_list}
    ${dst_list}=    Create List    @{NET1_VM_IPS}    @{external_pnf}[0]
    Log    ${dst_list}
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${dst_list}
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit TCP in External Networks with FIP
    [Documentation]    Create External network and check tcp communication between VM and External host
    [Tags]    Ex
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET1_VM_IPS}[1] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ssh ${pnf_user}@@{external_pnf}[0]    password:
    ${output}=    Write Commands Until Expected Prompt    ${pnf_password}    ${pnf_prompt}
    Log    ${output}
    Exit From Vm Console
    [Teardown]    Run Keywords    Get Test Teardown Debugs

Permit UDP in External Networks with FIP
    [Documentation]    Create External network and check udp communication between VM and External host
    [Tags]    Ex
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    additional_args=-u
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    router_1    l2_subnet_1
    Router Unset    router_1    cmd=--external-gateway
    Delete Router    router_1
    Delete SubNet    l2_subnet_1
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Network    ${EXTERNAL_NET_NAME}
    [Teardown]    Run Keywords    Clear L2_Network
