*** Settings ***
Documentation     Test suite to verify openstack CLI basic functionalities(create, read,
...               update and delete).
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Force Tags        skip_if_${SECURITY_GROUP_MODE}
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../libraries/CLI_OpenStackOperations.robot
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/OpenStackInstallUtils.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/KarafKeywords.robot

*** Variables ***
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{NET_2_VM_INSTANCES}    MyThirdInstance_3
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
@{ROUTERS}        router1    router2
${fixed_ip}       30.0.0.220
@{SECURITY_GROUP}    SG1    SG2
${VOLUME_NAME}    VOL1
${PORT}           port1
@{POOL_NAME}      subnet_pool_1    subnet_pool_2
@{PREF_IP}        20.0.0.0/24    30.0.0.0/24
${PREF_LEN}       32
@{POOL_DESC}      subnetpool_1
${UP_PREF_IP}     40.0.0.0/24
@{FLAVOR_NAME}    my_flavor_1
${Host2}          compute2.example.local
${external_gateway}    192.160.1.250
${external_subnet}    192.160.1.0/24
${external_subnet_allocation_pool}    start=192.160.1.2,end=192.160.1.249
${external_net_name}    external-net
${external_subnet_name}    external-subnet

*** Test Cases ***
Create Zone
    [Documentation]    Create Availabilityzone for test suite to create instances in specific zones.
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Components Required
    [Documentation]    Create required components internal network, external network,
    ...    instance, router and security group for test suite.
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create Network    ${external_net_name}
    Update Network    ${external_net_name}    additional_args=--external
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    additional_args=--gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM2}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[1]
    Create Router    @{ROUTERS}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[0]

Create Network
    [Documentation]    Create network and verify created network with python client.
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[1]

Network Exists
    [Documentation]    List networks and check network exists with python client.
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[1]

Update Network
    [Documentation]    Set network properties and verify network properties updated with python client.
    Update Network    @{NETWORKS_NAME}[1]    additional_args=--share
    ${output}=    Show Network    @{NETWORKS_NAME}[1]
    Should contain    ${output}    share

Network Details
    [Documentation]    Display network Details with python client.
    ${output}=    Show Network    @{NETWORKS_NAME}[1]
    Should contain    ${output}    @{NETWORKS_NAME}[1]

Delete Network
    [Documentation]    Delete network and verify network is deleted with python client.
    Delete Network    @{NETWORKS_NAME}[1]
    ${output}=    List Networks
    Should not contain    ${output}    @{NETWORKS_NAME}[1]

Create Subnet
    [Documentation]    Create subnet and verify created subnet is listed with python client.
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${output}=    List Subnets
    Should contain    ${output}    @{SUBNETS_NAME}[1]

Subnet Exists
    [Documentation]    List subnets and check subnet exists with python client.
    ${output}=    List Subnets
    Should contain    ${output}    @{SUBNETS_NAME}[1]

Update Subnet
    [Documentation]    Set subnet with property and verify subnet property is updated with python client.
    SubNet Unset    @{SUBNETS_NAME}[1]    additional_args=--allocation-pool start=40.0.0.2,end=40.0.0.254
    Update SubNet    @{SUBNETS_NAME}[1]    additional_args=--allocation-pool start=40.0.0.2,end=40.0.0.254
    ${output}=    Show Subnet    @{SUBNETS_NAME}[1]
    Should contain    ${output}    40.0.0.2-40.0.0.254

Subnet Details
    [Documentation]    Display subnet details with python client.
    ${output}=    Show Subnet    @{SUBNETS_NAME}[1]
    Should contain    ${output}    @{SUBNETS_NAME}[1]

Subnet Unset
    [Documentation]    Unset subnet properties and verify properties removed with python client.
    SubNet Unset    @{SUBNETS_NAME}[1]    additional_args=--allocation-pool start=40.0.0.2,end=40.0.0.254
    ${output}=    Show Subnet    @{SUBNETS_NAME}[1]
    Should Not contain    ${output}    40.0.0.2-40.0.0.254
    Update SubNet    @{SUBNETS_NAME}[1]    additional_args=--allocation-pool start=40.0.0.2,end=40.0.0.254

Subnet Delete
    [Documentation]    Delete subnet and verify subnet is deleted with python client.
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    ${output}=    List Subnets
    Should not contain    ${output}    @{SUBNETS_NAME}[1]

Create Instance
    [Documentation]    Create instance and verify created instance with python client.
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Instance Exists
    [Documentation]    List instances and check instance exists with python client.
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Update Instance
    [Documentation]    Set instance property and verify property is updated with python client.
    Update Instance    @{NET_1_VM_INSTANCES}[0]    additional_args=--property instance=1
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    instance='1'

Server Unset
    [Documentation]    Unset server property and verify property is removed with python client.
    Server Unset    @{NET_1_VM_INSTANCES}[0]    additional_args=--property instance
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    instance='1'

Instance Details
    [Documentation]    Display instance details with python client.
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Add Fixed ip
    [Documentation]    Add fixed ip to server and verify fixed ip is updated with python client.
    Server Add Fixed ip    ${fixed_ip}    @{NET_1_VM_INSTANCES}[0]    @{NETWORKS_NAME}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    30.0.0.220

Server Remove Fixed ip
    [Documentation]    Remove fixed ip from server and verify fixed ip removed from server with python client.
    Server Remove Fixed ip    @{NET_1_VM_INSTANCES}[0]    ${fixed_ip}
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    30.0.0.220

Server Add floating ip
    [Documentation]    Associate floating ip to server and verify floating ip is updated with python client.
    ${router_output} =    List Router
    Log    ${router_output}
    Should Contain    ${router_output}    @{ROUTERS}[0]
    ${router_list} =    Create List    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    ${external_net_name}
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    @{ip_list}=    Create And Associate Floating IPs    ${external_net_name}    @{VM1}
    Set Suite Variable    @{ip_list}
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{ip_list}[0]

Server Remove floating ip
    [Documentation]    Remove floating ip from server and verify floting ip is removed from server with python client.
    Server Remove Floating ip    @{NET_1_VM_INSTANCES}[0]    @{ip_list}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Floating ip Delete    @{ip_list}[0]

Server Add Security Group
    [Documentation]    Add security group to server and verify security group added to server with python client.
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[1]
    Should contain    ${output}    SG1

Server Remove Security Group
    [Documentation]    Remove security group from server and verify security group removed from server with python client.
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[1]
    Should Not Contain    ${output}    SG1

Server Lock
    [Documentation]    Lock server and verify server is locked with python client.
    Server Lock    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show Version    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    True

Server Unlock
    [Documentation]    Unlock server and verify server is unlocked with python client.
    Server Unlock    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show Version    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    False

Server Pause
    [Documentation]    Pause server and verify server is paused with python client.
    Server Pause    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    paused

Server Unpause
    [Documentation]    Unpause server and verify server is active with python client.
    Server Unpause    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    active

Server Reboot
    [Documentation]    Reboot server and verify server is rebooted with python client.
    Reboot Nova VM    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Rebuild
    [Documentation]    Rebuild server and verify server is rebuild with python client.
    Server Rebuild    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Rescue
    [Documentation]    Rescue server and verify server is in rescue with python client.
    Server Rescue    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Wait Until Keyword Succeeds    60s    10s    Should Contain    ${output}    rescuing

Server Unrescue
    [Documentation]    Unrescue server and verify server is active with python client.
    Wait Until Keyword Succeeds    90s    10s    Server Unrescue    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    active

Server New Flavor
    [Documentation]    Create small flavor and resize server with small flavor with python client.
    Create Small Flavor
    Server Resize    @{NET_1_VM_INSTANCES}[0]    flavor=m1.small
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Suspend
    [Documentation]    Suspend server and verify server is suspended with python client.
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    Server Suspend    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    suspended

Server Resume
    [Documentation]    Resume server and verify server is active with python client.
    Server Resume    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    ACTIVE

Server Shelve
    [Documentation]    Shelve server and verfiy server is shelved with python client.
    Server Shelve    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Wait Until Keyword Succeeds    60s    10s    Should Contain    ${output}    shelving

Server Unshelve
    [Documentation]    Unshelve server and verify server is active with python client.
    Wait Until Keyword Succeeds    90s    10s    Server Unshelve    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    active

Server Stop
    [Documentation]    Stop server and verify server is stopped with python client.
    Server Stop    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain Any    ${output}    Shutdown    powering-off

Server Start
    [Documentation]    Start server and verify server is active with python client.
    Wait Until Keyword Succeeds    60s    10s    Server Start    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    active

Server SSH
    [Documentation]    Create security rule. Add to server and ssh through server with python client.
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[0]
    Server SSH    @{NET_1_VM_INSTANCES}[0]    additional_args=--private
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[1]
    Should Contain    ${output}    status

Server Add Volume
    [Documentation]    Create volume. Add volume to server and verify server is updated with volume with python client.
    Create Volume    ${Volume_Name}    additional_args=--image cirros --size 8 --availability-zone nova
    Add Volume to VM    @{NET_1_VM_INSTANCES}[0]    ${Volume_Name}    additional_args=--device /dev/vdb
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    ${Volume_Name}
    Remove Volume From VM    @{NET_1_VM_INSTANCES}[0]    ${Volume_Name}

Server Dump Create
    [Documentation]    Create server dump with python client.
    Server Dump Create    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Remove Volume
    [Documentation]    Create volue. Add volume to server and remove volume from server with python client.
    Create Volume    ${Volume_Name}    additional_args=--image cirros --size 8 --availability-zone nova
    Add Volume to VM    @{NET_1_VM_INSTANCES}[0]    ${Volume_Name}    additional_args=--device /dev/vdb
    Remove Volume From VM    @{NET_1_VM_INSTANCES}[0]    ${Volume_Name}
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    ${Volume_Name}

Server Restore
    [Documentation]    Enable server restore in control and compute nodes.
    ...    Delete server and restore server deleted with python client.
    ...    Disable server restore in control and compute nodes.
    Enable Server Restore In All Control Nodes
    Enable Server Restore In All Compute Nodes
    ${rc}    ${server_output}=    Run And Return Rc And Output    openstack server show MyFirstInstance_1 | grep id
    Log    ${server_output}
    ${server_id}=    Split String    ${server_output}
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    ${output}=    List Nova VMs
    Should Not Contain    ${output}    @{NET_1_VM_INSTANCES}[0]
    Server Restore    @{server_id}[3]
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_1_VM_INSTANCES}[0]
    Disable Server Restore In All Compute Nodes
    Disable Server Restore In All Control Nodes

Delete Instance
    [Documentation]    Delete instance and verify instance deleted with python client.
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    ${output}=    List Nova VMs
    Should Not Contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Create Router
    [Documentation]    Create router and verify created router with python client.
    Create Router    @{ROUTERS}[1]
    ${output}=    List Router
    Should contain    ${output}    @{ROUTERS}[1]

Router Exists
    [Documentation]    List routers and check router exists with python client.
    ${output}=    List Router
    Should contain    ${output}    @{ROUTERS}[1]

Update Router
    [Documentation]    Set Router with prperty with python client.
    Update Router    @{ROUTERS}[1]    cmd=--enable
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[1]
    Should contain    ${output}    @{ROUTERS}[1]

Unset Router
    [Documentation]    Add external gateway and unset router external gateway with python client.
    Add Router Gateway    @{ROUTERS}[1]    ${external_net_name}
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway

Router Details
    [Documentation]    Display router Details with python client.
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[1]
    Should contain    ${output}    @{ROUTERS}[1]

Router Interface
    [Documentation]    Add Router Interface to subnet and verify interface is added with python client.
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    ${output}=    Show Router Interface    @{ROUTERS}[1]
    Should Contain    ${output}    30.0.0.1

Remove Router Interface
    [Documentation]    Remove router interface from subnet and verify interface is removed with python client.
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    ${output}=    Show Router Interface    @{ROUTERS}[1]
    Should Not Contain    ${output}    30.0.0.1

Router Add Port
    [Documentation]    Create port and add port to router with python client.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}
    ${output}=    List Ports
    Router Add Port    @{ROUTERS}[1]    ${PORT}
    ${output}=    OpenStack CLI    cmd=openstack router show @{ROUTERS}[1]
    Should contain    ${output}    @{ROUTERS}[1]

Router Remove Port
    [Documentation]    Remove port form router and verify port is removed with python client.
    Router Remove Port    @{ROUTERS}[1]    ${PORT}
    ${output}=    List Ports
    Should Not Contain    ${output}    ${PORT}

Delete Router
    [Documentation]    Delete router and verify router is deleted with python client.
    Delete Router    @{ROUTERS}[1]
    ${output}=    List Router
    Should Not Contain    ${output}    @{ROUTERS}[1]

Create Floating ip
    [Documentation]    Create floating ip and verify created floating ip with python client.
    @{ip}=    Create Floating IPs    ${external_net_name}
    Set Suite Variable    @{ip}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}

Floating ip List
    [Documentation]    list floating ips and check floating ip exists with python client.
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}

Floating ip Details
    [Documentation]    Display floating ip details with python client.
    ${output}=    Show Floating ip    @{ip}
    Should Contain    ${output}    @{ip}

Delete Floating ip
    [Documentation]    Delete floating ip and verify floating ip deleted with python client.
    Floating ip Delete    @{ip}
    ${output}=    Floating ip List
    Should Not Contain    ${output}    @{ip}

Security Group Create
    [Documentation]    Create security group and verify created security group with python client.
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    ${output}=    Security Group List
    Should Contain    ${output}    @{SECURITY_GROUP}[1]

Security Group List
    [Documentation]    List security groups and check security group exists with python client.
    ${output}=    Security Group List
    Should Contain    ${output}    @{SECURITY_GROUP}[1]

Update Security Group
    [Documentation]    Set security group property and verify security group property is updated with python client.
    Neutron Security Group Update    @{SECURITY_GROUP}[1]    additional_args=--description Security_Group
    ${output}=    Neutron Security Group Show    @{SECURITY_GROUP}[1]
    Should Contain    ${output}    Security_Group

Security Group Details
    [Documentation]    Display security group details with python client.
    ${output}=    Neutron Security Group Show    @{SECURITY_GROUP}[1]
    Should Contain    ${output}    @{SECURITY_GROUP}[1]

Delete Security Group
    [Documentation]    Delete security group and verify security group deleted with python client.
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ${output}=    Security Group List
    Should Not Contain    ${output}    @{SECURITY_GROUP}[1]

Security Group Rule Create
    [Documentation]    Create security group rule and verify created security group rule with python client.
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0
    ${output}=    Security Group Rule List
    Should Contain    ${output}    tcp

Security Group Rules List
    [Documentation]    List security group rules and check security group rule exists with python client.
    ${output}=    Security Group Rule List
    Should Contain    ${output}    tcp

Security Group Rule Details
    [Documentation]    Display security group rule details with python client.
    ${output}=    Show Security Group Rules    @{SECURITY_GROUP}[0]
    Should Contain    ${output}    tcp

Security Group Rule Delete
    [Documentation]    Delete security group rule and verify security group rule deleted with python client.
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    ${output}=    Security Group Rule List
    Should Not Contain    ${output}    tcp

Create Port
    [Documentation]    Create port and verify created port with python client.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}
    ${output}=    List Ports
    Should Contain    ${output}    ${PORT}

List Port
    [Documentation]    List ports and check port exists with python client.
    ${output}=    List Ports
    Should Contain    ${output}    ${PORT}

Update Port
    [Documentation]    Set port with property and verify properties are updated in port with python client.
    Update Port    ${PORT}    additional_args=--allowed-address ip-address=10.0.0.25,mac-address=aa:aa:aa:aa:aa:aa
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    10.0.0.25

Unset Port
    [Documentation]    Unset port with property and verify properties are removed from port with python client.
    Unset Port    ${PORT}    additional_args=--allowed-address ip-address=10.0.0.25,mac-address=aa:aa:aa:aa:aa:aa
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    10.0.0.25

Show Port
    [Documentation]    Display port details with python client.
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    port1

Delete Port
    [Documentation]    Delete port and verify port is deleted with python client.
    Delete Port    ${PORT}
    ${output}=    List Ports
    Should Not Contain    ${output}    ${PORT}

Create SubNet Pool
    [Documentation]    Create subnet pool and verify created subnet pool with python client.
    Create SubNet Pool    @{POOL_NAME}[0]    ${PREF_LEN}    @{POOL_DESC}[0]    @{PREF_IP}[0]
    ${output}=    List SubNet Pool
    Should Contain    ${output}    @{POOL_NAME}[0]

List SubNet Pool
    [Documentation]    List subnet pools and check subnet pool exists with python client.
    ${output}=    List SubNet Pool
    Should Contain    ${output}    @{POOL_NAME}[0]

Details SubNet Pool
    [Documentation]    Display subnet pool details with python client.
    ${output}=    Show SubNet Pool    @{POOL_NAME}[0]
    Should Contain    ${output}    @{POOL_NAME}[0]

Update SubNet Pool
    [Documentation]    Set subnet pool properties and verify subnet pool is updated with python client.
    Set SubNet Pool    ${UP_PREF_IP}    @{POOL_NAME}[0]
    ${output}=    Show SubNet Pool    @{POOL_NAME}[0]
    Should Contain    ${output}    ${UP_PREF_IP}

Unset SubNet Pool
    [Documentation]    Unset Subnet pool property and verify subnet pool property is removed with python client.
    Unset SubNet Pool    ${UP_PREF_IP}    @{POOL_NAME}[0]
    ${output}=    Show SubNet Pool    @{POOL_NAME}[0]
    Should Not Contain    ${output}    ${UP_PREF_IP}

Delete SubNet Pool
    [Documentation]    Delete subnet pool and verify subnet pool is deleted with python client.
    Delete SubNet Pool    @{POOL_NAME}[0]
    ${output}=    List SubNet Pool
    Should Not Contain    ${output}    @{POOL_NAME}[0]

Create Flavor
    [Documentation]    Create flavor and verify created flavor with python client.
    Flavor Create    @{FLAVOR_NAME}[0]
    ${output}=    List Flavor
    Should Contain    ${output}    @{FLAVOR_NAME}[0]

List Flavor
    [Documentation]    List flavors and verify flavor exists with python client.
    ${output}=    List Flavor
    Should Contain    ${output}    @{FLAVOR_NAME}[0]

Flavor Details
    [Documentation]    Display flavor details with python client.
    ${output}=    Show Flavor    @{FLAVOR_NAME}[0]
    Should Contain    ${output}    @{FLAVOR_NAME}[0]

Set Flavor
    [Documentation]    Set flavor property and verify flavor propert is updated with python client.
    Set Flavor    @{FLAVOR_NAME}[0]    232
    ${output}=    Show Flavor    @{FLAVOR_NAME}[0]
    Should Contain    ${output}    232

UnSet Flavor
    [Documentation]    Unset flavor property and verify flavor property is removed with python client.
    UnSet Flavor    @{FLAVOR_NAME}[0]
    ${output}=    Show Flavor    @{FLAVOR_NAME}[0]
    Should Not Contain    ${output}    232

Delete Flavor
    [Documentation]    Delete flavor and verify flavor is deleted with python client.
    Delete Flavor    @{FLAVOR_NAME}[0]
    ${output}=    List Flavor
    Should Not Contain    ${output}    @{FLAVOR_NAME}[0]

Server Migrate
    [Documentation]    Enable live migration in all compute nodes.
    ...    Create server and migrate it to different host.
    ...    Verify server is migrated to different host with python client.
    ...    Disable live migration in all compute nodes.
    Enable Live Migration In All Compute Nodes
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    ${VM1}=    Create List    @{NET_2_VM_INSTANCES}[0]
    Create Vm Instances    @{NETWORKS_NAME}[1]    ${VM1}    image=cirros    flavor=cirros    sg=@{sg_list}[0]    additional_args=--availability-zone ${zone1}
    Poll VM Is ACTIVE    @{NET_2_VM_INSTANCES}[0]
    Server Migrate    @{NET_2_VM_INSTANCES}[0]    additional_args=--live ${Host2}
    Poll VM Is ACTIVE    @{NET_2_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_2_VM_INSTANCES}[0]
    Should Contain    ${output}    ${Host2}
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    Disable Live Migration In All Compute Nodes

Update Floating ip
    [Documentation]    Create floating ip. Create port and set floating ip to port with python client.
    @{ip}=    Create Floating IPs    ${external_net_name}
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}
    ${port_ip}=    Get Port Ip    ${PORT}
    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Add Router Gateway    @{ROUTERS}[0]    ${external_net_name}
    Floating ip Set    ${PORT}    ${port_ip}    @{ip}
    ${output}=    Show Floating ip    @{ip}
    Should Contain    ${output}    @{ip}
    Floating ip UnSet    @{ip}
    Delete Port    ${PORT}
    Floating ip Delete    @{ip}
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway

Components Deletion
    [Documentation]    Delete components internal network, external network, router
    ...    Instance and security group created for test suite.
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Network    ${external_net_name}
    Delete Router    @{ROUTERS}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete Flavor    m1.small
    [Teardown]    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone created for test suite.
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2
