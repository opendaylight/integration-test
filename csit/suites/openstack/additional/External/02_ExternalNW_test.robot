*** Settings ***
Documentation     Test suite to verify multiple external before and after service in.
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
@{NETWORKS_NAME}    network_5    network_6
@{SUBNETS_NAME}    l2_subnet_5    l2_subnet_6
@{NET_1_VM_INSTANCES}    MyFirstInstance_1
@{NET_2_VM_INSTANCES}    MySecondInstance_1
@{ROUTERS}        router1    router2    router3
@{NETWORK_GW}     30.0.0.1    40.0.0.1
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    2001:db8:cafe:e::/64    100.64.2.0/24    192.168.90.0/24
${subnet_1_allocation_pool}    start=30.0.0.10,end=30.0.0.248
${subnet_2_allocation_pool}    start=40.0.0.10,end=40.0.0.248
@{CIDR_SUBNETS_RANGE}    30.0.0.0    40.0.0.0
${network1_vlan_id}    1235
@{port}           1111    2222    234    1234    6    17    50
...               51    132    136
${user}           cirros
${password}       cubswin:)
@{external_gateway}    101.0.0.250    102.0.0.1
@{vlan_external_gateway}    105.0.0.250    106.0.0.1
@{external_pnf}    101.0.0.1    101.0.0.2
@{vlan_external_pnf}    105.0.0.1    105.0.0.2
${pnf_password}    automation
${pnf_user}       root
${pnf_prompt}     \    #
@{external_subnet}    101.0.0.0/24    102.0.0.0/24
@{vlan_external_subnet}    105.0.0.0/24    106.0.0.0/24
@{vlan_external_subnet_allocation_pool}    start=105.0.0.4,end=105.0.0.249    start=106.0.0.4,end=106.0.0.249
@{external_subnet_allocation_pool}    start=101.0.0.4,end=101.0.0.249    start=102.0.0.4,end=102.0.0.249
@{EXTERNAL_NET_NAME}    external-net-1    external-net-2
@{EXTERNAL_SUBNET_NAME}    external-subnet-1    external-subnet-2
@{PROVIDER}       flat1    flat2

*** Test Cases ***
Create External Network in before service in Type Flat
    [Documentation]    Create External network and check if exists
    Create Network    @{EXTERNAL_NET_NAME}[0]    --external --provider-network-type flat --provider-physical-network @{PROVIDER}[0]
    Create SubNet    @{EXTERNAL_NET_NAME}[0]    @{EXTERNAL_SUBNET_NAME}[0]    @{external_subnet}[0]    --gateway @{external_gateway}[0] --allocation-pool @{external_subnet_allocation_pool}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]

Create Virtual LAN in before service in Type Flat
    [Documentation]    Create Network and check if exists
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]

Create Router in before service in Type Flat
    [Documentation]    Create router and check if exists
    Create Router    @{ROUTERS}[0]
    ${output}=    List Routers
    Should contain    ${output}    @{ROUTERS}[0]

Add External Gateway in before service in Type Flat
    [Documentation]    Add external gateway to router and check if exists
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Add Subnet in before service in Type Flat
    [Documentation]    Add interface to router and check if exists
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Create Instance in before service in Type Flat
    [Documentation]    Create Instance and check if exists
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    ${VM1}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_2_VM_INSTANCES}[0]
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_2_VM_INSTANCES}[0]
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

Check Connectivity in before service in Type Flat
    [Documentation]    Check connectivity from Vm to External
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    port=5555
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    additional_args=-u

Create floating ip in before service in Type Flat
    [Documentation]    Create floating ip and check if exists
    @{ip}=    Create Floating IPs    @{EXTERNAL_NET_NAME}[0]
    Set Suite Variable    @{ip}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}

Associate floating ip to VM in before service in Type Flat
    [Documentation]    Associate floating ip to VM and check if exists
    Associate Floating ip to VM    @{NET_2_VM_INSTANCES}[0]    @{ip}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should contain    ${output}    @{ip}[0]

Check Connectivity after associating floating ip in before service in Type Flat
    [Documentation]    Check connectivity from Vm to External after associating floating ip
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    port=1111
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    additional_args=-u

Remove floating ip from VM in before service in Type Flat
    [Documentation]    Remove floating ip from VM and check
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should Not Contain    ${output}    @{ip}[0]

Delete floating ip in before service in Type Flat
    [Documentation]    Delete floating ip and check
    Floating ip Delete    @{ip}[0]
    ${output}=    Floating ip List
    Should Not Contain    ${output}    @{ip}

Delete Vm Instance in before service in Type Flat
    [Documentation]    Delete VM instance and check
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete SecurityGroup    @{sg_list}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not contain    ${output}    @{NET_2_VM_INSTANCES}[0]

Dissconnect Router and internal network in before service in Type Flat
    [Documentation]    Remove interface from router and check
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Dissconnect Router and external network in before service in Type Flat
    [Documentation]    Remove external gateway from router and check
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Delete Router in before service in Type Flat
    [Documentation]    Delete router and check
    Delete Router    @{ROUTERS}[0]
    ${output}=    List Routers
    Should Not Contain    ${output}    @{ROUTERS}[0]

Delete Network in before service in Type Flat
    [Documentation]    Delete Network and check
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Network    @{EXTERNAL_NET_NAME}[0]
    ${output}=    List Networks
    Should Not contain    ${output}    @{NETWORKS_NAME}[0]
    Should Not contain    ${output}    @{EXTERNAL_NET_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Create Multiple External Network before service in Type Flat
    [Documentation]    Create Multiple External network and check if exists
    Create Network    @{EXTERNAL_NET_NAME}[0]    --external --provider-network-type flat --provider-physical-network flat1
    Create SubNet    @{EXTERNAL_NET_NAME}[0]    @{EXTERNAL_SUBNET_NAME}[0]    @{external_subnet}[0]    --gateway @{external_gateway}[0] --allocation-pool @{external_subnet_allocation_pool}[0]
    Create Network    @{EXTERNAL_NET_NAME}[1]    --external --provider-network-type flat --provider-physical-network flat2
    Create SubNet    @{EXTERNAL_NET_NAME}[1]    @{EXTERNAL_SUBNET_NAME}[1]    @{external_subnet}[1]    --gateway @{external_gateway}[1] --allocation-pool @{external_subnet_allocation_pool}[1]
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]

Create Virtual LAN before service in Multiple External Type Flat
    [Documentation]    Create Network and check if exists
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--allocation-pool ${subnet_1_allocation_pool}
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Create Router in before service in Multiple External Type Flat
    [Documentation]    Create router and check if exists
    Create Router    @{ROUTERS}[0]
    Create Router    @{ROUTERS}[1]
    ${output}=    List Routers
    Should contain    ${output}    @{ROUTERS}[0]
    Should contain    ${output}    @{ROUTERS}[1]

Add External Gateway before service in Multiple External Type Flat
    [Documentation]    Add external gateway to router and check if exists
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[1]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Add Subnet before service in Multiple External Type Flat
    [Documentation]    Add interface to router and check if exists
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[0],ip-address=30.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[1]
    Should Contain    ${output}    @{ROUTERS}[0]

Create Instance before service in Multiple External Type Flat
    [Documentation]    Create Instance and check if exists
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    ${VM1}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_2_VM_INSTANCES}[0]
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_2_VM_INSTANCES}[0]
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

Check Connectivity before service in Multiple External Type Flat
    [Documentation]    Check connectivity from Vm to External
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_5
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    sudo ip route add 101.0.0.0/24 via 30.0.0.6 &    $
    Exit From Vm Console
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    port=1122
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    additional_args=-u

Create floating ip before service in Multiple External Type Flat
    [Documentation]    Create floating ip and check if exists
    @{ip}=    Create Floating IPs    @{EXTERNAL_NET_NAME}[0]
    Set Suite Variable    @{ip}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}

Associate floating ip to VM before service in Multiple External Type Flat
    [Documentation]    Associate floating ip to VM and check if exists
    Associate Floating ip to VM    @{NET_2_VM_INSTANCES}[0]    @{ip}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should contain    ${output}    @{ip}[0]

Check Connectivity after associating floating ip before service in Multiple External Type Flat
    [Documentation]    Check connectivity from Vm to External after associating floating ip
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    port=1133
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    additional_args=-u

Remove floating ip from VM before service in Multiple External Type Flat
    [Documentation]    Remove floating ip from VM and check
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should Not Contain    ${output}    @{ip}[0]

Delete floating ip before service in Multiple External Type Flat
    [Documentation]    Delete floating ip and check
    Floating ip Delete    @{ip}[0]
    ${output}=    Floating ip List
    Should Not Contain    ${output}    @{ip}

Delete Vm Instance in before service Multiple External Type Flat
    [Documentation]    Delete VM instance and check
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete SecurityGroup    @{sg_list}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not contain    ${output}    @{NET_2_VM_INSTANCES}[0]

Dissconnect Router and internal network before service in Multiple External Type Flat
    [Documentation]    Remove interface from router and check
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Dissconnect Router and external network before service in Multiple External Type Flat
    [Documentation]    Remove external gateway from router and check
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Delete Router before service in Multiple External Type Flat
    [Documentation]    Delete router and check
    Delete Router    @{ROUTERS}[0]
    Delete Router    @{ROUTERS}[1]
    ${output}=    List Routers
    Should Not Contain    ${output}    @{ROUTERS}[0]
    Should Not Contain    ${output}    @{ROUTERS}[1]

Delete Network Multiple External Network before service in Multiple External Type Flat
    [Documentation]    Delete Network and check
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Network    @{EXTERNAL_NET_NAME}[0]
    Delete Network    @{EXTERNAL_NET_NAME}[1]
    ${output}=    List Networks
    Should Not contain    ${output}    @{NETWORKS_NAME}[0]
    Should Not contain    ${output}    @{EXTERNAL_NET_NAME}[0]
    Should Not contain    ${output}    @{EXTERNAL_NET_NAME}[1]
    [Teardown]    Run Keywords    Clear L2_Network

Create Virtual LAN After service in Type Flat
    [Documentation]    Create Network and check if exists
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Create Router in After service in Type Flat
    [Documentation]    Create router and check if exists
    Create Router    @{ROUTERS}[0]
    ${output}=    List Routers
    Should contain    ${output}    @{ROUTERS}[0]

Add Subnet in After service in Type Flat
    [Documentation]    Add interface to router and check if exists
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Create Instance in After service in Type Flat
    [Documentation]    Create Instance and check if exists
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    ${VM1}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_2_VM_INSTANCES}[0]
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_2_VM_INSTANCES}[0]
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

Create External Network in After service in Type Flat
    [Documentation]    Create External network and check if exists
    Create Network    @{EXTERNAL_NET_NAME}[0]    --external --provider-network-type flat --provider-physical-network @{PROVIDER}[0]
    Create SubNet    @{EXTERNAL_NET_NAME}[0]    @{EXTERNAL_SUBNET_NAME}[0]    @{external_subnet}[0]    --gateway @{external_gateway}[0] --allocation-pool @{external_subnet_allocation_pool}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]

Add External Gateway in After service in Type Flat
    [Documentation]    Add external gateway to router and check if exists
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Check Connectivity in After service in Type Flat
    [Documentation]    Check connectivity from Vm to External
    Sleep    10s
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    port=1144
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    additional_args=-u

Create floating ip in After service in Type Flat
    [Documentation]    Create floating ip and check if exists
    @{ip}=    Create Floating IPs    @{EXTERNAL_NET_NAME}[0]
    Set Suite Variable    @{ip}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}

Associate floating ip to VM in After service in Type Flat
    [Documentation]    Associate floating ip to VM and check if exists
    Associate Floating ip to VM    @{NET_2_VM_INSTANCES}[0]    @{ip}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should contain    ${output}    @{ip}[0]

Check Connectivity after associating floating ip in After service in Type Flat
    [Documentation]    Check connectivity from Vm to External after associating floating ip
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    port=1155
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    additional_args=-u

Remove floating ip from VM in After service in Type Flat
    [Documentation]    Remove floating ip from VM and check
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should Not Contain    ${output}    @{ip}[0]

Delete floating ip in After service in Type Flat
    [Documentation]    Delete floating ip and check
    Floating ip Delete    @{ip}[0]
    ${output}=    Floating ip List
    Should Not Contain    ${output}    @{ip}

Delete Vm Instance in After service in Type Flat
    [Documentation]    Delete VM instance and check
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete SecurityGroup    @{sg_list}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not Contain    ${output}    @{NET_2_VM_INSTANCES}[0]

Dissconnect Router and internal network in After service in Type Flat
    [Documentation]    Remove interface from router and check
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Dissconnect Router and external network in After service in Type Flat
    [Documentation]    Remove external gateway from router and check
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Delete Router in After service in Type Flat
    [Documentation]    Delete router and check
    Delete Router    @{ROUTERS}[0]
    ${output}=    List Routers
    Should Not Contain    ${output}    @{ROUTERS}[0]

Delete Network in After service in Type Flat
    [Documentation]    Delete Network and check
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Network    @{EXTERNAL_NET_NAME}[0]
    ${output}=    List Networks
    Should Not contain    ${output}    @{NETWORKS_NAME}[0]
    Should Not contain    ${output}    @{EXTERNAL_NET_NAME}[0]
    [Teardown]    Run Keywords    Clear L2_Network

Create Virtual LAN After service in Type Flat Multiple External
    [Documentation]    Create Network and check if exists
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]    additional_args=--allocation-pool ${subnet_1_allocation_pool}
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Create Router in After service in Type Flat Multiple External
    [Documentation]    Create router and check if exists
    Create Router    @{ROUTERS}[0]
    Create Router    @{ROUTERS}[1]
    ${output}=    List Routers
    Should contain    ${output}    @{ROUTERS}[0]
    Should contain    ${output}    @{ROUTERS}[1]

Add Subnet in After service in Type Flat Multiple External
    [Documentation]    Add interface to router and check if exists
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    ${rc}    ${port_id}=    Run And Return Rc And Output    openstack port list --router router1 --device-owner network:router_interface -fvalue -c ID
    Update Port    ${port_id}    additional_args=--no-fixed-ip
    Update Port    ${port_id}    additional_args=--fixed-ip subnet=@{SUBNETS_NAME}[0],ip-address=30.0.0.6
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Create Instance in After service in Type Flat Multiple External
    [Documentation]    Create Instance and check if exists
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    ${VM1}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_2_VM_INSTANCES}[0]
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_2_VM_INSTANCES}[0]
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

Create Multiple External Network After service in Type Flat Multiple External
    [Documentation]    Create External network and check if exists
    Create Network    @{EXTERNAL_NET_NAME}[0]    --external --provider-network-type flat --provider-physical-network flat1
    Create SubNet    @{EXTERNAL_NET_NAME}[0]    @{EXTERNAL_SUBNET_NAME}[0]    @{external_subnet}[0]    --gateway @{external_gateway}[0] --allocation-pool @{external_subnet_allocation_pool}[0]
    Create Network    @{EXTERNAL_NET_NAME}[1]    --external --provider-network-type flat --provider-physical-network flat2
    Create SubNet    @{EXTERNAL_NET_NAME}[1]    @{EXTERNAL_SUBNET_NAME}[1]    @{external_subnet}[1]    --gateway @{external_gateway}[1] --allocation-pool @{external_subnet_allocation_pool}[1]
    ${output}=    List Networks
    Should contain    ${output}    @{EXTERNAL_NET_NAME}[0]

Add External Gateway in After service in Type Flat Multiple External
    [Documentation]    Add external gateway to router and check if exists
    Add Router Gateway    @{ROUTERS}[0]    @{EXTERNAL_NET_NAME}[0]
    Add Router Gateway    @{ROUTERS}[1]    @{EXTERNAL_NET_NAME}[1]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Check Connectivity in After service in Type Flat Multiple External
    [Documentation]    Check connectivity from Vm to External
    ${crtl_c}    Evaluate    chr(int(3))
    ${crtl_n}    Evaluate    chr(int(13))
    ${devstack_conn_id_1}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id_1}
    ${net_id}=    Get Net Id    network_5
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{NET2_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Write Commands Until Expected Prompt    sudo ip route add 101.0.0.0/24 via 30.0.0.6 &    $
    Exit From Vm Console
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    port=1166
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    additional_args=-u

Create floating ip in After service in Type Flat Multiple External
    [Documentation]    Create floating ip and check if exists
    @{ip}=    Create Floating IPs    @{EXTERNAL_NET_NAME}[0]
    Set Suite Variable    @{ip}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}

Associate floating ip to VM in After service in Type Flat Multiple External
    [Documentation]    Associate floating ip to VM and check if exists
    Associate Floating ip to VM    @{NET_2_VM_INSTANCES}[0]    @{ip}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should contain    ${output}    @{ip}[0]

Check Connectivity after associating floating ip in After service in Type Flat Multiple External
    [Documentation]    Check connectivity from Vm to External after associating floating ip
    Test Netcat Operations Internal to external TCP    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    port=1177
    Test Netcat Operations Internal to external    ${pnf_prompt}    @{external_pnf}[0]    @{NETWORKS_NAME}[0]    @{NET2_VM_IPS}[0]    additional_args=-u

Remove floating ip from VM in After service in Type Flat Multiple External
    [Documentation]    Remove floating ip from VM and check
    Server Remove Floating ip    @{NET_2_VM_INSTANCES}[0]    @{ip}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should Not Contain    ${output}    @{ip}[0]

Delete floating ip in After service in Type Flat Multiple External
    [Documentation]    Delete floating ip and check
    Floating ip Delete    @{ip}[0]
    ${output}=    Floating ip List
    Should Not Contain    ${output}    @{ip}

Delete Vm Instance in After service in Type Flat Multiple External
    [Documentation]    Delete VM instance and check
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete SecurityGroup    @{sg_list}[0]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not contain    ${output}    @{NET_2_VM_INSTANCES}[0]

Dissconnect Router and internal network in After service in Type Flat Multiple External
    [Documentation]    Remove interface from router and check
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Dissconnect Router and external network in After service in Type Flat Multiple External
    [Documentation]    Remove external gateway from router and check
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[0]
    Should Contain    ${output}    @{ROUTERS}[0]

Delete Router in After service in Type Flat Multiple External
    [Documentation]    Delete router and check
    Delete Router    @{ROUTERS}[0]
    Delete Router    @{ROUTERS}[1]
    ${output}=    List Routers
    Should Not Contain    ${output}    @{ROUTERS}[0]
    Should Not Contain    ${output}    @{ROUTERS}[1]

Delete Network Multiple External Network in After service in Type Flat Multiple External
    [Documentation]    Delete Network and check
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Network    @{EXTERNAL_NET_NAME}[0]
    Delete Network    @{EXTERNAL_NET_NAME}[1]
    ${output}=    List Networks
    Should Not contain    ${output}    @{NETWORKS_NAME}[0]
    Should Not contain    ${output}    @{EXTERNAL_NET_NAME}[0]
    Should Not contain    ${output}    @{EXTERNAL_NET_NAME}[1]
    [Teardown]    Run Keywords    Clear L2_Network
