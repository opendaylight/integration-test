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
@{ROUTERS}   router1    router2
${fixed_ip}    30.0.0.220
@{SECURITY_GROUP}    SG1    SG2
${VOLUME_NAME}    VOL1
${PORT}    port1
@{POOL_NAME}    subnet_pool_1
@{PREF_IP}    20.0.0.0/24
${PREF_LEN}    32
@{POOL_DESC}    subnetpool_1
${UP_PREF_IP}    40.0.0.0/24
@{FLAVOR_NAME}    my_flavor_1
${Host2}    compute2.example.local

${external_gateway}    192.160.1.250
${external_subnet}    192.160.1.0/24
${external_subnet_allocation_pool}    start=192.160.1.2,end=192.160.1.249
${external_net_name}    external-net
${external_subnet_name}    external-subnet

*** Test Cases ***
Create Zone
    [Documentation]    Create Availabilityzone create for test suite
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Components Required
    [Documentation]    Required Network and Instance for testcases.
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
    [Documentation]    Create Network and verify.
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[1]

Network Exists
    [Documentation]    Create Network and check if network exists.
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[1]

Update Network
    [Documentation]    Create and update network properties.
    Update Network    @{NETWORKS_NAME}[1]    additional_args=--share
    ${output}=    Show Network    @{NETWORKS_NAME}[1]
    Should contain    ${output}    share

Network Details
    [Documentation]    Create Network and show Network Details
    ${output}=    Show Network    @{NETWORKS_NAME}[1]
    Should contain    ${output}    @{NETWORKS_NAME}[1]

Delete Network
    [Documentation]    Create Network and delete network.
    Delete Network    @{NETWORKS_NAME}[1]
    ${output}=    List Networks
    Should not contain    ${output}    @{NETWORKS_NAME}[1]

Create Subnet
    [Documentation]    create subnet and verify.
    Create Network    @{NETWORKS_NAME}[1]    additional_args=--provider-network-type vxlan
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${output}=    List Subnets
    Should contain    ${output}    @{SUBNETS_NAME}[1]

Subnet Exists
    [Documentation]    Create Network subnet and check if Subnet exists.
    ${output}=    List Subnets
    Should contain    ${output}    @{SUBNETS_NAME}[1]

Update Subnet
    [Documentation]    Update subnet with allocation pools.
    SubNet Unset    @{SUBNETS_NAME}[1]    additional_args=--allocation-pool start=40.0.0.2,end=40.0.0.254
    Update SubNet    @{SUBNETS_NAME}[1]    additional_args=--allocation-pool start=40.0.0.2,end=40.0.0.254
    ${output}=    Show Subnet    @{SUBNETS_NAME}[1]
    Should contain    ${output}    allocation_pools

Subnet Details
    [Documentation]    Create and show subnet details.
    ${output}=    Show Subnet    @{SUBNETS_NAME}[1]
    Should contain    ${output}    @{SUBNETS_NAME}[1]

Subnet Unset
    [Documentation]    Create subnet and unset subnet properties.
    SubNet Unset    @{SUBNETS_NAME}[1]    additional_args=--allocation-pool start=40.0.0.2,end=40.0.0.254
    ${output}=    Show Subnet    @{SUBNETS_NAME}[1]
    Should contain    ${output}    allocation_pools
    Update SubNet    @{SUBNETS_NAME}[1]    additional_args=--allocation-pool start=40.0.0.2,end=40.0.0.254

Subnet Delete
    [Documentation]    Create Network subnet and delete subnet.
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    ${output}=    List Subnets
    Should not contain    ${output}    @{SUBNETS_NAME}[1]

Create Instance
    [Documentation]    Create instance and verify.
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
    [Documentation]    Create instance and check if instance exists.
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Update Instance
    [Documentation]    Create instance and update instance property.
    Update Instance    @{NET_1_VM_INSTANCES}[0]    additional_args=--property instance=1
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    instance='1'

Server Unset
    [Documentation]    Update and unset server property.
    Server Unset    @{NET_1_VM_INSTANCES}[0]    additional_args=--property instance
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    instance='1'

Instance Details
    [Documentation]    Create instance and show instance details.
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Add Fixed ip
    [Documentation]    Create server and Add fixed ip to server.
    Server Add Fixed ip    ${fixed_ip}    @{NET_1_VM_INSTANCES}[0]    @{NETWORKS_NAME}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    30.0.0.220

Server Remove Fixed ip
    [Documentation]    Create Server add fixed ip and remove fixed ip from server.
    Server Remove Fixed ip    @{NET_1_VM_INSTANCES}[0]    ${fixed_ip}
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    30.0.0.220

Server Add floating ip
    [Documentation]    Create server and associate floating ip to server.
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
    [Documentation]    Create Server associate floating ip and remove floating ip from Server.
    Server Remove Floating ip    @{NET_1_VM_INSTANCES}[0]    @{ip_list}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    @{ip_list}[0]
    Remove Interface    @{ROUTERS}[0]    @{SUBNETS_NAME}[0]
    Router Unset    @{ROUTERS}[0]    cmd=--external-gateway
    Floating ip Delete    @{ip_list}[0]

Server Add Security Group
    [Documentation]    Create Server and Security group. Add security group to server.
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[1]
    Should contain    ${output}    SG1

Server Remove Security Group
    [Documentation]    Create Server with default security group and remove default security group from server.
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[1]
    Should Not Contain    ${output}    SG1

Server Lock
    [Documentation]    Create and lock server.
    Server Lock    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show Version    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    True

Server Unlock
    [Documentation]    Create Server lock and unlock server.
    Server Unlock    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show Version    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    False

Server Pause
    [Documentation]    Create Server and pause.
    Server Pause    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    paused

Server Unpause
    [Documentation]    Create server pause and unpause server.
    Server Unpause    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    active

Server Reboot
    [Documentation]    Create server and reboot.
    Reboot Nova VM    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Rebuild
    [Documentation]    Create and rebuild server.
    Server Rebuild    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Rescue
    [Documentation]    Create server and verify rescue server.
    Server Rescue    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Wait Until Keyword Succeeds    60s    10s    Should Contain    ${output}    rescuing

Server Unrescue
    [Documentation]    Create server rescue and unrescue server.
    Wait Until Keyword Succeeds    90s    10s    Server Unrescue    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    active

Server New Flavor
    [Documentation]    Create server and New Flavor. Add new flavor to server.
    Create Small Flavor
    Server Resize    @{NET_1_VM_INSTANCES}[0]    flavor=m1.small
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Suspend
    [Documentation]    Create and suspend server.
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    Server Suspend    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    suspended

Server Resume
    [Documentation]    Create server. Suspend and resume server to verify.
    Server Resume    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    ACTIVE

Server Shelve
    [Documentation]    Create and shelve server.
    Server Shelve    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Wait Until Keyword Succeeds    60s    10s    Should Contain    ${output}    shelving

Server Unshelve
    [Documentation]    Create server shelve and unshelve server.
    Wait Until Keyword Succeeds    90s    10s    Server Unshelve    @{NET_1_VM_INSTANCES}[0]
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    active

Server Stop
    [Documentation]    Create and stop server.
    Server Stop    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain Any    ${output}    Shutdown    powering-off

Server Start
    [Documentation]    Create server. Stop and start server to verify.
    Wait Until Keyword Succeeds    60s    10s    Server Start    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    active

Server SSH
    [Documentation]    Create server and ssh server.
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0
    Add Security Group To VM    @{NET_1_VM_INSTANCES}[1]    @{SECURITY_GROUP}[0]
    Server SSH    @{NET_1_VM_INSTANCES}[0]    additional_args=--private
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[1]
    Should Contain    ${output}    status

Server Add Volume
    [Documentation]    Create server and add volume.
    Create Volume    ${Volume_Name}    additional_args=--image cirros --size 8 --availability-zone nova
    Add Volume to VM    @{NET_1_VM_INSTANCES}[0]    ${Volume_Name}    additional_args=--device /dev/vdb
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    ${Volume_Name}
    Remove Volume From VM    @{NET_1_VM_INSTANCES}[0]    ${Volume_Name}

Server Dump Create
    [Documentation]    Create server and add created dump.
    Server Dump Create    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Server Remove Volume
    [Documentation]    Create server and remove volume.
    Create Volume    ${Volume_Name}    additional_args=--image cirros --size 8 --availability-zone nova
    Add Volume to VM    @{NET_1_VM_INSTANCES}[0]    ${Volume_Name}    additional_args=--device /dev/vdb
    Remove Volume From VM    @{NET_1_VM_INSTANCES}[0]    ${Volume_Name}
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    ${Volume_Name}

Server Restore
    [Documentation]    Create server and restore server.
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
    [Documentation]    Create and delete instance.
    ${output}=    List Nova VMs
    Should Contain    ${output}    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    ${output}=    List Nova VMs
    Should Not Contain    ${output}    @{NET_1_VM_INSTANCES}[0]

Create Router
    [Documentation]    Create and check router.
    Create Router    @{ROUTERS}[1]
    ${output}=    List Router
    Should contain    ${output}    @{ROUTERS}[1]

Router Exists
    [Documentation]    Create router and check if router exists.
    ${output}=    List Router
    Should contain    ${output}    @{ROUTERS}[1]

Update Router
    [Documentation]    Create and Update Router with enable.
    Update Router    @{ROUTERS}[1]    cmd=--enable
    ${output}=    Show Router    @{ROUTERS}[1]
    Should contain    ${output}    @{ROUTERS}[1]

Unset Router
    [Documentation]    Create router add external gateway and unset router external gateway.
    Add Router Gateway    @{ROUTERS}[1]    ${external_net_name}
    Router Unset    @{ROUTERS}[1]    cmd=--external-gateway

Router Details
    [Documentation]    Create and show router Details.
    ${output}=    Show Router    @{ROUTERS}[1]
    Should contain    ${output}    @{ROUTERS}[1]

Router Interface
    [Documentation]    Create Network and add Router Interface to subnet.
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    ${output}=    Show Router Interface    @{ROUTERS}[1]
    Should Contain    ${output}    30.0.0.1

Remove Router Interface
    [Documentation]    Create Network add and remove router interface from subnet.
    Remove Interface    @{ROUTERS}[1]    @{SUBNETS_NAME}[0]
    ${output}=    Show Router Interface    @{ROUTERS}[1]
    Should Not Contain    ${output}    30.0.0.1

Router Add Port
    [Documentation]    Create Port and add router to port.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}
    ${output}=    List Ports
    Router Add Port    @{ROUTERS}[1]    ${PORT}
    ${output}=    Show Router    @{ROUTERS}[1]
    Should contain    ${output}    @{ROUTERS}[1]

Router Remove Port
    [Documentation]    Create port add router and remove router port.
    Router Remove Port    @{ROUTERS}[1]    ${PORT}
    ${output}=    Show Router    @{ROUTERS}[1]
    Should Not Contain    ${output}    ${PORT}

Delete Router
    [Documentation]    Create and delete router.
    Delete Router    @{ROUTERS}[1]
    ${output}=    List Router
    Should Not Contain    ${output}    @{ROUTERS}[1]

Add Floating ip
    [Documentation]    Create external network and add floating ip.
    @{ip}=    Create Floating IPs    ${external_net_name}
    Set Suite Variable    @{ip}
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}

Floating ip List
    [Documentation]    Create and list floating ip.
    ${output}=    Floating ip List
    Should Contain    ${output}    @{ip}

Floating ip Details
    [Documentation]    Create and show floating ip details.
    ${output}=    Show Floating ip    @{ip}
    Should Contain    ${output}    @{ip}

Delete Floating ip
    [Documentation]    Create and delete floating ip.
    Floating ip Delete    @{ip}
    ${output}=    Floating ip List
    Should Not Contain    ${output}    @{ip}

Security Group Create
    [Documentation]    Create and check security group.
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    ${output}=    Security Group List
    Should Contain    ${output}    @{SECURITY_GROUP}[1]

Security Group List
    [Documentation]    Create and list security group.
    ${output}=    Security Group List
    Should Contain    ${output}    @{SECURITY_GROUP}[1]

Update Security Group
    [Documentation]    Create and update security group description.
    Neutron Security Group Update    @{SECURITY_GROUP}[1]    additional_args=--description Security_Group
    ${output}=    Neutron Security Group Show    @{SECURITY_GROUP}[1]
    Should Contain    ${output}    Security_Group

Security Group Details
    [Documentation]    Create and display security group details.
    ${output}=    Neutron Security Group Show    @{SECURITY_GROUP}[1]
    Should Contain    ${output}    @{SECURITY_GROUP}[1]

Delete Security Group
    [Documentation]    Creste and delete security group.
    Delete SecurityGroup    @{SECURITY_GROUP}[1]
    ${output}=    Security Group List
    Should Not Contain    ${output}    @{SECURITY_GROUP}[1]

Security Group Rule Create
    [Documentation]    Create and check security group rule.
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=tcp    port_range_min=1    port_range_max=65535    remote_ip_prefix=0.0.0.0/0
    ${output}=    Security Group Rule List
    Should Contain    ${output}    tcp

Security Group Rules List
    [Documentation]    Create and list security group rules.
    ${output}=    Security Group Rule List
    Should Contain    ${output}    tcp

Security Group Rule Details
    [Documentation]    Create and show security group rule details.
    ${output}=    Show Security Group Rules    @{SECURITY_GROUP}[0]
    Should Contain    ${output}    tcp

Security Group Rule Delete
    [Documentation]    Create and delete security group rules.
    Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    ${output}=    Security Group Rule List
    Should Not Contain    ${output}    tcp

Create Port
    [Documentation]    Create and check port.
    Create Port    @{NETWORKS_NAME}[0]    ${PORT}
    ${output}=    List Ports
    Should Contain    ${output}    ${PORT}

List Port
    [Documentation]    Create and list ports.
    ${output}=    List Ports
    Should Contain    ${output}    ${PORT}

Update Port
    [Documentation]    Create and update port with allowed addresses.
    Update Port    ${PORT}    additional_args=--allowed-address ip-address=10.0.0.25,mac-address=aa:aa:aa:aa:aa:aa
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    10.0.0.25

Unset Port
    [Documentation]    Create and unset port with allowed addresses.
    Unset Port    ${PORT}    additional_args=--allowed-address ip-address=10.0.0.25,mac-address=aa:aa:aa:aa:aa:aa
    ${output}=    Show Port    ${PORT}
    Should Not Contain    ${output}    10.0.0.25

Show Port
    [Documentation]    Create and show port details.
    ${output}=    Show Port    ${PORT}
    Should Contain    ${output}    port1

Delete Port
    [Documentation]    Create and delete port.
    Delete Port    ${PORT}
    ${output}=    List Ports
    Should Not Contain    ${output}    ${PORT}

Create SubNet Pool
    [Documentation]    Check create subnet pool.
    Create SubNet Pool    @{POOL_NAME}[0]    ${PREF_LEN}    @{POOL_DESC}[0]    @{PREF_IP}[0]
    ${output}=    List SubNet Pool
    Should Contain    ${output}    @{POOL_NAME}[0]

List SubNet Pool
    [Documentation]    Create and list subnet pool.
    ${output}=    List SubNet Pool
    Should Contain    ${output}    @{POOL_NAME}[0]

Details SubNet Pool
    [Documentation]    Create subnet pool and display subnet pool details.
    ${output}=    Show SubNet Pool    @{POOL_NAME}[0]
    Should Contain    ${output}    @{POOL_NAME}[0]

Update SubNet Pool
    [Documentation]    Create and update subnet pool.
    Set SubNet Pool    ${UP_PREF_IP}    @{POOL_NAME}[0]
    ${output}=    Show SubNet Pool    @{POOL_NAME}[0]
    Should Contain    ${output}    ${UP_PREF_IP}

Unset SubNet Pool
    [Documentation]    Update Subnet pool and unset Subnet pool.
    Unset SubNet Pool    ${UP_PREF_IP}    @{POOL_NAME}[0]
    ${output}=    Show SubNet Pool    @{POOL_NAME}[0]
    Should Not Contain    ${output}    ${UP_PREF_IP}

Delete SubNet Pool
    [Documentation]    Create and delete subnet pool.
    Delete SubNet Pool    @{POOL_NAME}[0]
    ${output}=    List SubNet Pool
    Should Not Contain    ${output}    @{POOL_NAME}[0]

Create Flavor
    [Documentation]    Check Create flavor.
    Flavor Create    @{FLAVOR_NAME}[0]
    ${output}=    List Flavor
    Should Contain    ${output}    @{FLAVOR_NAME}[0]

List Flavor
    [Documentation]    Create Flavor and list flavor.
    ${output}=    List Flavor
    Should Contain    ${output}    @{FLAVOR_NAME}[0]

Flavor Details
    [Documentation]    Create flavor and Display flavor details.
    ${output}=    Show Flavor    @{FLAVOR_NAME}[0]
    Should Contain    ${output}    @{FLAVOR_NAME}[0]

Set Flavor
    [Documentation]    Create flavor and update flavor.
    Set Flavor    @{FLAVOR_NAME}[0]    232
    ${output}=    Show Flavor    @{FLAVOR_NAME}[0]
    Should Contain    ${output}    232

UnSet Flavor
    [Documentation]    Update the flavor and unset flavor.
    UnSet Flavor    @{FLAVOR_NAME}[0]
    ${output}=    Show Flavor    @{FLAVOR_NAME}[0]
    Should Not Contain    ${output}    232

Delete Flavor
    [Documentation]    Create flavor and delete flavor.
    Delete Flavor    @{FLAVOR_NAME}[0]
    ${output}=    List Flavor
    Should Not Contain    ${output}    @{FLAVOR_NAME}[0]

Server Migrate
    [Documentation]    Create server and migrate it to different host.
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
    Should Contain Any    ${output}    ${Host2}
    Delete Vm Instance    @{NET_2_VM_INSTANCES}[0]
    Delete SubNet    @{SUBNETS_NAME}[1]
    Delete Network    @{NETWORKS_NAME}[1]
    Disable Live Migration In All Compute Nodes

Update Floating ip
    [Documentation]    Create Port and Update port to assocaite the floating IP with port.
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
    [Documentation]    Delete Required Network and Instance for testcases.
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete SubNet    @{SUBNETS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Network    ${external_net_name}
    Delete Router    @{ROUTERS}[0]
    Delete SecurityGroup    @{SECURITY_GROUP}[0]
    Delete Flavor    m1.small
    [Teardown]    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2
