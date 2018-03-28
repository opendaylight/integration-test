*** Settings ***
Documentation     Test suite to verify external network communication
...               using multiple external networks and routers.
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
@{NETWORKS_NAME}    network_5    network_6    network_7
@{SUBNETS_NAME}    l2_subnet_5    l2_subnet_6    l2_subnet_7
@{NET_1_VM_INSTANCES}    MyFirstInstance_1
@{NET_2_VM_INSTANCES}    MySecondInstance_1
@{NET_3_VM_INSTANCES}    MyThirdInstance_1
@{ROUTERS}        router1    router2    router3
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    50.0.0.0/24
${subnet_1_allocation_pool}    start=40.0.0.10,end=40.0.0.248
${subnet_2_allocation_pool}    start=50.0.0.10,end=50.0.0.248
@{external_gateway}    101.0.0.250    102.0.0.250
@{vlan_external_gateway}    105.0.0.250    106.0.0.250
@{external_pnf}    101.0.0.1    102.0.0.1
@{vlan_external_pnf}    105.0.0.2    106.0.0.2
${pnf_password}    automation
${pnf_user}       root
${pnf_prompt}     \    #
@{external_subnet}    101.0.0.0/24    102.0.0.0/24
@{vlan_external_subnet}    105.0.0.0/24    106.0.0.0/24
@{vlan_external_subnet_allocation_pool}    start=105.0.0.4,end=105.0.0.249    start=106.0.0.4,end=106.0.0.249
@{external_subnet_allocation_pool}    start=101.0.0.4,end=101.0.0.249    start=102.0.0.4,end=102.0.0.249
@{EXTERNAL_NET_NAME}    external-net-1    external-net-2    external-net-3    external-net-4
@{EXTERNAL_SUBNET_NAME}    external-subnet-1    external-subnet-2    external-subnet-2    external-subnet-4
@{PROVIDER}       flat1    flat2
@{VLAN_PROVIDER}    vlantest
@{VLAN_PROVIDER_SEGMENT}    28    29
${password}       cubswin:)
${user}           cirros

*** Test Cases ***
Components Required
    [Documentation]    Create required external networks, networks, routers and instances.
    Create Network    @{EXTERNAL_NET_NAME}[0]    --external --provider-network-type flat --provider-physical-network @{PROVIDER}[0]
    Create SubNet    @{EXTERNAL_NET_NAME}[0]    @{EXTERNAL_SUBNET_NAME}[0]    @{external_subnet}[0]    --gateway @{external_gateway}[0] --allocation-pool @{external_subnet_allocation_pool}[0]
    Create Network    @{EXTERNAL_NET_NAME}[1]    --external --provider-network-type vlan --provider-physical-network ${VLAN_PROVIDER} --provider-segment @{VLAN_PROVIDER_SEGMENT}[0]
    Create SubNet    @{EXTERNAL_NET_NAME}[1]    @{EXTERNAL_SUBNET_NAME}[1]    @{vlan_external_subnet}[0]    --gateway @{vlan_external_gateway}[0] --allocation-pool @{vlan_external_subnet_allocation_pool}[0]
    Create Network    @{EXTERNAL_NET_NAME}[2]    --external --provider-network-type flat --provider-physical-network @{PROVIDER}[1]
    Create SubNet    @{EXTERNAL_NET_NAME}[2]    @{EXTERNAL_SUBNET_NAME}[2]    @{external_subnet}[1]    --gateway @{external_gateway}[1] --allocation-pool @{external_subnet_allocation_pool}[1]
    Create Network    @{EXTERNAL_NET_NAME}[3]    --external --provider-network-type vlan --provider-physical-network ${VLAN_PROVIDER} --provider-segment @{VLAN_PROVIDER_SEGMENT}[1]
    Create SubNet    @{EXTERNAL_NET_NAME}[3]    @{EXTERNAL_SUBNET_NAME}[3]    @{vlan_external_subnet}[1]    --gateway @{vlan_external_gateway}[1] --allocation-pool @{vlan_external_subnet_allocation_pool}[1]
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
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
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Create Router    @{ROUTERS}[0]
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]    additional_args=--allocation-pool ${subnet_1_allocation_pool}
    ${VM2}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_2_VM_INSTANCES}[0]
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
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET2_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Create Router    @{ROUTERS}[1]
    Create Network    @{NETWORKS_NAME}[2]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]    additional_args=--allocation-pool ${subnet_2_allocation_pool}
    ${VM3}=    Create List    @{NET_3_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[2]    ${VM3}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_3_VM_INSTANCES}[0]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_3_VM_INSTANCES}[0]
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
    ${LOOP_COUNT}    Get Length    ${NET3_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET3_DHCP_IP}[${index}]/32
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Create Router    @{ROUTERS}[2]

Create External Network Type Flat CT1
    [Documentation]    Check created external network exists with python client
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]
    [Teardown]    Run Keywords    Clear Interfaces

Check Openstack operations on External Network Type Flat CT1
    [Documentation]    Add Interfaces, Create and associate floating ip and remove interfaces.
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[0]    @{NET_1_VM_INSTANCES}[0]
    Server Remove Floating ip    @{NET_1_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

External Network Type Flat Communication CT1
    [Documentation]    Add Interfaces and check communication from VM to
    ...    External host with and without floating ip.
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=4444
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[0]    @{NET_1_VM_INSTANCES}[0]
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=2211
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Server Remove Floating ip    @{NET_1_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Create External Network Type Vlan CT1
    [Documentation]    Create External network and check if exists
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[1]
    [Teardown]    Run Keywords    Clear Interfaces

Check Openstack operations on External Network Type Vlan CT1
    [Documentation]    Create External network and check openstack operations
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[1]
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[1]    @{NET_1_VM_INSTANCES}[0]
    Server Remove Floating ip    @{NET_1_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

External Network Type Vlan Communication CT1
    [Documentation]    Create External network and check communication from VM to External host
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[1]
    Test Netcat Operations Internal to external TCP VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=2222
    Test Netcat Operations Internal to external VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[1]    @{NET_1_VM_INSTANCES}[0]
    Test Netcat Operations Internal to external TCP VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    port=2233
    Test Netcat Operations Internal to external VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    additional_args=-u
    Server Remove Floating ip    @{NET_1_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Create Multiple External Network Type Flat CT2
    [Documentation]    Create External network and check if exists
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[2]
    [Teardown]    Run Keywords    Clear Interfaces

Check openstack operation on Multiple External Network Type Flat CT2
    [Documentation]    Create External network and check communication from VM to External host
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[2]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[0]    @{NET_2_VM_INSTANCES}[0]
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Multiple External Network Type Flat Communication CT2
    [Documentation]    Create External network and check communication from VM to External host
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[2]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_6
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    sudo ip route add 101.0.0.0/24 via 40.0.0.6 &    $
    Exit From Vm Console
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=2244
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[0]    @{NET_2_VM_INSTANCES}[0]
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=2255
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Create Multiple External Network Type Vlan CT2
    [Documentation]    Create External network and check if exists
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[1]
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[3]
    [Teardown]    Run Keywords    Clear Interfaces

Check openstack openrations on Multiple External Network Type Vlan CT2
    [Documentation]    Create External network and check openstack operations
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[1]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[3]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[1]    @{NET_2_VM_INSTANCES}[0]
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Multiple External Network Type Vlan Communication CT2
    [Documentation]    Create External network and check communication from VM to External host
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[1]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[3]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_6
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    sudo ip route add 105.0.0.0/24 via 40.0.0.6 &    $
    Exit From Vm Console
    Test Netcat Operations Internal to external TCP VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=2266
    Test Netcat Operations Internal to external VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[1]    @{NET_2_VM_INSTANCES}[0]
    Test Netcat Operations Internal to external TCP VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=2277
    Test Netcat Operations Internal to external VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Create External Network Type Flat CT3
    [Documentation]    Create External network and check if exists
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]
    [Teardown]    Run Keywords    Clear Interfaces

Check openstack operations on External with Two Internal Network Type Flat Communication CT3
    [Documentation]    Create External network and check openstack operations
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[2]
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[0]    @{NET_2_VM_INSTANCES}[0]
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[2]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

External with Two Internal Network Type Flat Communication CT3
    [Documentation]    Create External network and check communication from VM to External host
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[2]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_6
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    sudo ip route add 101.0.0.0/24 via 40.0.0.6 &    $
    Exit From Vm Console
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=2288
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[0]    @{NET_2_VM_INSTANCES}[0]
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=2299
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[2]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Create External Network Type Vlan CT3
    [Documentation]    Create External network and check if exists
    ${output}=    Show Network    @{EXTERNAL_NET_NAME}[1]
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[1]
    [Teardown]    Run Keywords    Clear Interfaces

Check openstack operation on External with Two Internal Network Type Vlan CT3
    [Documentation]    Create External network and check openstack operations
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[1]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[2]
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[1]    @{NET_2_VM_INSTANCES}[0]
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[2]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

External with Two Internal Network Type Vlan Communication CT3
    [Documentation]    Create External network and check communication from VM to External host
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[1]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[2]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_6
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    sudo ip route add 105.0.0.0/24 via 40.0.0.6 &    $
    Exit From Vm Console
    Test Netcat Operations Internal to external TCP VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=3311
    Test Netcat Operations Internal to external VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[1]    @{NET_2_VM_INSTANCES}[0]
    Test Netcat Operations Internal to external TCP VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=3322
    Test Netcat Operations Internal to external VLAN    ${pnf_prompt}    @{vlan_external_pnf}[0]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[2]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Create Multiple External Network Type Flat CT4
    [Documentation]    Create External network and check if exists
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[2]
    [Teardown]    Run Keywords    Clear Interfaces

Check openstack operations on Multiple External and Multiple Internal Network Type Flat Communication CT4
    [Documentation]    Create External network and check openstack operations
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[2]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.4
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router2 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[2]
    Add Router Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[1]
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[0]    @{NET_2_VM_INSTANCES}[0]
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[2]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Multiple External and Multiple Internal Network Type Flat Communication CT4
    [Documentation]    Create External network and check communication from VM to External host
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[2]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.4
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router2 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[2]
    Add Router Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[1]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_6
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    sudo ip route add 101.0.0.0/24 via 40.0.0.4 &    $
    Write Commands Until Expected Prompt    sudo ip route add 102.0.0.0/24 via 40.0.0.6 &    $
    Exit From Vm Console
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=3333
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[0]    @{NET_2_VM_INSTANCES}[0]
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=3344
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[2]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Create Multiple External Network Type Vlan CT4
    [Documentation]    Create External network and check if exists
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[1]
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[3]
    [Teardown]    Run Keywords    Clear Interfaces

Check openstack operation on Multiple External and Multiple Internal Network Type Vlan Communication CT4
    [Documentation]    Create External network and check openstack operations
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[1]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[3]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.3
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router2 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[2]
    Add Router Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[1]
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[1]    @{NET_2_VM_INSTANCES}[0]
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[2]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Multiple External and Multiple Internal Network Type Vlan Communication CT4
    [Documentation]    Create External network and check communication from VM to External host
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[1]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[3]
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.4
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router2 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[1],ip-address=40.0.0.6
    Add Router Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[2]
    Add Router Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[1]
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_6
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    sudo ip route add 105.0.0.0/24 via 40.0.0.4 &    $
    Write Commands Until Expected Prompt    sudo ip route add 106.0.0.0/24 via 40.0.0.6 &    $
    Exit From Vm Console
    Test Netcat Operations Internal to external TCP VLAN    ${pnf_prompt}    @{vlan_external_pnf}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=3355
    Test Netcat Operations Internal to external VLAN    ${pnf_prompt}    @{vlan_external_pnf}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    @{ip_list}=    Create And Associate Floating IPs    @{EXTERNAL_NET_NAME}[1]    @{NET_2_VM_INSTANCES}[0]
    Test Netcat Operations Internal to external TCP VLAN    ${pnf_prompt}    @{vlan_external_pnf}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    port=3366
    Test Netcat Operations Internal to external VLAN    ${pnf_prompt}    @{vlan_external_pnf}[1]    @{NETWORKS_NAME}[1]    @{NET2_VM_IPS}[0]    additional_args=-u
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip_list}[0]
    Floating ip Delete    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[1]
    Remove Interface    @{ROUTERS}[2]    @{SUBNETS_NAME}[2]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    [Teardown]    Run Keywords    Clear Interfaces

Components Deletion
    [Documentation]    Delete Required Network and Instance for testcases.
    Delete Vm Instance    @{NET_3_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    Delete Router    @{ROUTERS}[0]
    Delete Router    @{ROUTERS}[1]
    Delete Router    @{ROUTERS}[2]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    Delete SubNet    @{SUBNETS_NAME}[2]
    Delete Network    @{NETWORKS_NAME}[2]
    Delete Network    @{EXTERNAL_NET_NAME}[0]
    Delete Network    @{EXTERNAL_NET_NAME}[1]
    Delete Network    @{EXTERNAL_NET_NAME}[2]
    Delete Network    @{EXTERNAL_NET_NAME}[3]
    [Teardown]    Run Keywords    Clear L2_Network

*** keywords ***
Clear Interfaces
    [Documentation]    Remove Interfaces
    ${rc}    ${router_output}=    Run And Return Rc And Output    openstack router list -cID -fvalue
    Log    ${router_output}
    @{routers}=    Split String    ${router_output}    \n
    ${rc}    ${subnet_output}=    Run And Return Rc And Output    openstack subnet list -cID -fvalue
    Log    ${subnet_output}
    @{subnets}=    Split String    ${subnet_output}    \n
    : FOR    ${router}    IN    @{routers}
    \    Run Keyword And Ignore Error    Remove Interfaces    ${router}    ${subnets}
