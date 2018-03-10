*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Resource          DataModels.robot
Resource          Utils.robot
Resource          SSHKeywords.robot
Resource          L2GatewayOperations.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot
Variables         ../variables/netvirt/Modules.py

*** Keywords ***
SubNet Unset
    [Arguments]    ${subnet}    ${additional_args}=${EMPTY}
    [Documentation]    unset SubNet for the Network with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet unset ${subnet} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}

List SubNet Pool
    [Documentation]    List subnetpool with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet pool list
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Create SubNet Pool
    [Arguments]    ${pool_name}    ${pref_len}    ${pool_des}    ${pref_ip}    ${additional_args}=${EMPTY}
    [Documentation]    subnet pool create
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet pool create --default-prefix-length ${pref_len} --description ${pool_des} --pool-prefix ${pref_ip} ${pool_name} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}

Delete SubNet Pool
    [Arguments]    ${pool_name}
    [Documentation]    subnet pool delete
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet pool delete ${pool_name}
    Log    ${output}
    Should Not Be True    ${rc}

Show SubNet Pool
    [Arguments]    ${pool_name}
    [Documentation]    Show subnet pool with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet pool show ${pool_name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Set SubNet Pool
    [Arguments]    ${pref_ip}    ${pool_name}
    [Documentation]    set subnet pool create
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet pool set --pool-prefix ${pref_ip} ${pool_name}
    Log    ${output}
    Should Not Be True    ${rc}

Unset SubNet Pool
    [Arguments]    ${pref_ip}    ${pool_name}
    [Documentation]    unset subnet pool create
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet pool unset --pool-prefix ${pref_ip} ${pool_name}
    Log    ${output}
    Should Not Be True    ${rc}

Server Add Fixed ip
    [Arguments]    ${fixed_ip}    ${vm_name}    ${network_name}
    [Documentation]    Add fixed ip to server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add fixed ip --fixed-ip-address ${fixed_ip} ${vm_name} ${network_name}
    Log    ${output}
    Should Not Be True    ${rc}

Server Add Floating ip
    [Arguments]    ${vm_name}    ${floating_ip}
    [Documentation]    Add floating ip to server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add floating ip ${vm_name} ${floating_ip}
    Log    ${output}
    Should Not Be True    ${rc}

Show Floating ip
    [Arguments]    ${floating_ip}
    [Documentation]    show floating ip and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip show ${floating_ip}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Get Security Group Id
    [Arguments]    ${sg_name}
    [Documentation]    Retrieve the security group id for the given sg name
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group show "${sg_name}" | grep " id " | awk '{print $4}'
    Log    ${output}
    Should Not Be True    ${rc}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${sg_id}=    Get from List    ${splitted_output}    0
    Log    ${sg_id}
    [Return]    ${sg_id}

Get Floating ip Id
    [Arguments]    ${floating_ip}
    [Documentation]    Retrieve the floating ip id for the given floating ip
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip show "${floating_ip}" | grep " id " | awk '{print $4}'
    Log    ${output}
    Should Not Be True    ${rc}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${floating_id}=    Get from List    ${splitted_output}    0
    Log    ${floating_id}
    [Return]    ${floating_id}

Floating ip UnSet
    [Arguments]    ${floating_ip}
    [Documentation]    unset port floating ip and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip unset --port ${floating_ip}
    Log    ${output}
    Should Not Be True    ${rc}

Server Rescue
    [Arguments]    ${vm_name}
    [Documentation]    Rescue server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server rescue ${vm_name}
    Log    ${output}
    Should Not Be True    ${rc}

Server Unrescue
    [Arguments]    ${vm_name}
    [Documentation]    Unrescue server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server unrescue ${vm_name}
    Log    ${output}
    Should Not Be True    ${rc}

Server Resize
    [Arguments]    ${vm_name}    ${flavor}=${EMPTY}
    [Documentation]    Resize server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server resize --flavor ${flavor} --wait ${vm_name}
    Log    ${output}
    Should Not Be True    ${rc}

Server Restore
    [Arguments]    ${vm_id}
    [Documentation]    Restore server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server restore ${vm_id}
    Log    ${output}
    Should Not Be True    ${rc}

Server SSH
    [Arguments]    ${vm_name}    ${additional_args}=${EMPTY}
    [Documentation]    ssh server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server ssh ${vm_name} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}

Server Start
    [Arguments]    ${vm_name}
    [Documentation]    server start with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server start ${vm_name}
    Log    ${output}
    Should Not Be True    ${rc}

Server Stop
    [Arguments]    ${vm_name}
    [Documentation]    server stop with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server stop ${vm_name}
    Log    ${output}
    Should Not Be True    ${rc}

Server Show Version
    [Arguments]    ${vm_name}
    [Documentation]    server show with os version 2.17 with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack --os-compute-api-version 2.17 server show ${vm_name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Unset Port
    [Arguments]    ${port_name}    ${additional_args}=${EMPTY}
    [Documentation]    Unset port with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port unset ${port_name} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}

Create Volume
    [Arguments]    ${volume_name}    ${additional_args}=${EMPTY}
    [Documentation]    Create Volume
    ${rc}    ${output}=    Run And Return Rc And Output    openstack volume create ${additional_args} ${volume_name}
    Should Not Be True    ${rc}
    Log    ${output}

Add Volume to VM
    [Arguments]    ${server}    ${volume}    ${additional_args}=${EMPTY}
    [Documentation]    add volume to server
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add volume ${server} ${volume} ${additional_args}
    Should Not Be True    ${rc}
    Log    ${output}

Remove Volume From VM
    [Arguments]    ${server}    ${volume}
    [Documentation]    add volume to server
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove volume ${server} ${volume}
    Should Not Be True    ${rc}
    Log    ${output}

Remove Volume
    [Arguments]    ${server}    ${volume}
    [Documentation]    remove volume
    ${rc}    ${output}=    Run And Return Rc And Output    openstack volume delete ${volume}
    Should Not Be True    ${rc}
    Log    ${output}

Update Instance
    [Arguments]    ${vm_instance_name}    ${additional_args}=${EMPTY}
    [Documentation]    update instance
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server set ${additional_args} ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Unset
    [Arguments]    ${vm_instance_name}    ${additional_args}=${EMPTY}
    [Documentation]    unset server
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server unset ${vm_instance_name} ${additional_args}
    Should Not Be True    ${rc}
    Log    ${output}

Server Dump Create
    [Arguments]    ${vm_instance_name}
    [Documentation]    server dump create
    ${rc}    ${output}=    Run And Return Rc And Output    openstack --os-compute-api-version 2.17 server dump create ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Lock
    [Arguments]    ${vm_instance_name}
    [Documentation]    server lock
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server lock ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Unlock
    [Arguments]    ${vm_instance_name}
    [Documentation]    server unlock
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server unlock ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Migrate
    [Arguments]    ${vm_instance_name}    ${additional_args}=${EMPTY}
    [Documentation]    server migrate
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server migrate ${additional_args} ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Pause
    [Arguments]    ${vm_instance_name}
    [Documentation]    server pause
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server pause ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Unpause
    [Arguments]    ${vm_instance_name}
    [Documentation]    server unpause
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server unpause ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Rebuild
    [Arguments]    ${vm_instance_name}    ${image}=cirros    ${password}=1234
    [Documentation]    server rebuild
    Write    source /tmp/client_rc
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server rebuild --image ${image} --password ${password} --wait ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Suspend
    [Arguments]    ${vm_instance_name}
    [Documentation]    server suspend
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server suspend ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Resume
    [Arguments]    ${vm_instance_name}
    [Documentation]    server resume
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server resume ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Shelve
    [Arguments]    ${vm_instance_name}
    [Documentation]    server shelve
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server shelve ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Server Unshelve
    [Arguments]    ${vm_instance_name}
    [Documentation]    server unshelve
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server unshelve ${vm_instance_name}
    Should Not Be True    ${rc}
    Log    ${output}

Create Small Flavor
    [Documentation]    Create a small flavor
    ${rc}    ${output}=    Run And Return Rc And Output    openstack flavor create m1.small --id auto --ram 2048 --disk 20 --vcpus 1
    Log    ${output}
    Should Not Be True    ${rc}

List Flavor
    [Documentation]    List Flavor
    ${rc}    ${output}=    Run And Return Rc And Output    openstack flavor list
    Should Not Be True    ${rc}
    Log    ${output}
    [Return]    ${output}

Flavor Create
    [Arguments]    ${flavor_name}
    [Documentation]    Create Flavor
    ${rc}    ${output}=    Run And Return Rc And Output    openstack flavor create ${flavor_name}
    Should Not Be True    ${rc}

Delete Flavor
    [Arguments]    ${flavor_name}
    [Documentation]    Delete Flavor
    ${rc}    ${output}=    Run And Return Rc And Output    openstack flavor delete ${flavor_name}
    Should Not Be True    ${rc}

Show Flavor
    [Arguments]    ${flavor_name}
    [Documentation]    List Flavor
    ${rc}    ${output}=    Run And Return Rc And Output    openstack flavor show ${flavor_name}
    Should Not Be True    ${rc}
    Log    ${output}
    [Return]    ${output}

Set Flavor
    [Arguments]    ${flavor_name}    ${additional_args}=${EMPTY}
    [Documentation]    Set Flavor
    ${rc}    ${output}=    Run And Return Rc And Output    openstack flavor set ${additional_args} ${flavor_name}
    Should Not Be True    ${rc}

UnSet Flavor
    [Arguments]    ${flavor_name}    ${additional_args}=${EMPTY}
    [Documentation]    UnSet Flavor
    ${rc}    ${output}=    Run And Return Rc And Output    openstack flavor unset ${additional_args} ${flavor_name}
    Should Not Be True    ${rc}

Router Add Port
    [Arguments]    ${router_name}    ${port_name}
    [Documentation]    Add port to router
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router add port ${router_name} ${port_name}
    Log    ${output}
    Should Not Be True    ${rc}

Router Remove Port
    [Arguments]    ${router_name}    ${port_name}
    [Documentation]    Remove port to router
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router remove port ${router_name} ${port_name}
    Log    ${output}
    Should Not Be True    ${rc}

Security Group List
    [Documentation]    List security group with Openstack CLI
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Delete Security Group Rule
    [Arguments]    ${rule}
    [Documentation]    delete security group rule with Openstack CLI
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group rule delete ${rule}
    Log    ${output}
    Should Not Be True    ${rc}

Security Group Rule List
    [Documentation]    List security group rules with Openstack CLI
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group rule list
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Show Security Group Rules
    [Arguments]    ${sg_name}
    [Documentation]    show security rules from a specified security group
    ${rc}    ${sg_rules_output}=    Run And Return Rc And Output    openstack security group rule list ${sg_name} -cID -fvalue
    Log    ${sg_rules_output}
    Should Not Be True    ${rc}
    @{sg_rules}=    Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group rule show ${rule}
    \    Log    ${output}
    \    Should Not Be True    ${rc}
    [Return]    ${output}

Server Remove Security Group
    [Arguments]    ${vm}    ${sg}
    [Documentation]    Remove the security group provided to the given VM.
    Write    source /tmp/client_rc
    ${output}=    Write Commands Until Prompt    openstack server remove security group ${vm} ${sg}
    Log    ${output}

Create UDPLITE protocol SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow packets for udplite protocol in this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=136    port_range_min=136    protocol=6
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=136    port_range_min=136    protocol=tcp

Create SCTP protocol SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow packets for sctp protocol in this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=132    port_range_min=132    protocol=6
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=132    port_range_min=132    protocol=tcp

Create AH protocol SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow packets for ah protocol in this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=51    port_range_min=51    protocol=6
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=51    port_range_min=51    protocol=tcp

Create ESP protocol SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow packets for esp protocol in this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=50    port_range_min=50    protocol=6
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=50    port_range_min=50    protocol=6

Create UDP protocol SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow packets for the protocol value 17 in this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    protocol=17
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp

Create UDP Deny protocol SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Deny packets for the protocol value 6 in this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    protocol=17

Create TCP protocol SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow packets for the protocol value 6 in this suite
    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    protocol=6

Create TCP Deny protocol SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Deny packets for the protocol value 6 in this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    protocol=6

Create TCP Port1111 SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow TCP of port 1111 packets for this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=1111    port_range_min=1111    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=1111    port_range_min=1111    protocol=tcp

Create TCP Port2222 SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow TCP of port 2222-3333 packets for this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=3333    port_range_min=2222    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=3333    port_range_min=2222    protocol=tcp

Create UDP Port1111 SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow UDP of port 1111 packets for this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=1111    port_range_min=1111    protocol=udp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=1111    port_range_min=1111    protocol=udp

Create UDP Port2222 SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow UDP of port 2222-3333 packets for this suite
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=3333    port_range_min=2222    protocol=udp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=3333    port_range_min=2222    protocol=udp

Create protocol CIDR permit for tcp SecuirtyGroup
    [Arguments]    ${sg_name}    ${remote_Ips}    ${ether_type}=IPv4
    [Documentation]    Allow tcp packets for this suite which has respective remote-ip
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=${remote_Ips}
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=${remote_Ips}

Create protocol CIDR deny for tcp SecuirtyGroup
    [Arguments]    ${sg_name}    ${remote_Ips}    ${ether_type}=IPv4
    [Documentation]    Allow tcp packets for this suite which has respective remote-ip
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    protocol=tcp

Create protocol CIDR permit for udp SecurityGroup
    [Arguments]    ${sg_name}    ${remote_Ips}    ${ether_type}=IPv4
    [Documentation]    Allow udp packets for this suite which has respective remote-ip
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    protocol=udp    port_range_max=65535    port_range_min=1    remote_ip_prefix=${remote_Ips}
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    protocol=udp    port_range_max=65535    port_range_min=1    remote_ip_prefix=${remote_Ips}

Create protocol CIDR deny for udp SecurityGroup
    [Arguments]    ${sg_name}    ${remote_Ips}    ${ether_type}=IPv4
    [Documentation]    Allow udp packets for this suite which has respective remote-ip
    Neutron Security Group Create    ${sg_name}
    Delete All Security Group Rules    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    protocol=udp

Create protocol TCP remote-SG SecurityGroup
    [Arguments]    ${sg_name}    ${remote_sg}    ${ether_type}=IPv4
    [Documentation]    Allow TCP packets for this suite which has respective remote-security-group
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    ...    remote_group_id=${remote_sg}
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    ...    remote_group_id=${remote_sg}

Create protocol UDP remote-SG SecurityGroup
    [Arguments]    ${sg_name}    ${remote_sg}    ${ether_type}=IPv4
    [Documentation]    Allow UDP packets for this suite which has respective remote-security-group
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=udp
    ...    remote_group_id=${remote_sg}
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=udp
    ...    remote_group_id=${remote_sg}

Create protocol 1 permit SecurityGroup
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with ICMP protocols.
    Neutron Security Group Create    ${sg-name}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=1

Create protocol 1 deny SecurityGroup
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with ICMP protocols.
    Neutron Security Group Create    ${sg-name}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=1

Create ICMP protocol permit SecurityGroup
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with ALL ICMP protocols.
    Neutron Security Group Create    ${sg-name}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    protocol=icmp

Create ICMP protocol deny SecurityGroup
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with ALL ICMP protocols.
    Neutron Security Group Create    ${sg-name}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    protocol=icmp

Create protocol ICMP remote-ip SecurityGroup
    [Arguments]    ${sg_name}    ${remote_Ips}    ${ether_type}=IPv4
    [Documentation]    Allow ICMP packets for this suite which has respective remote-ip
    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    protocol=1    remote_ip_prefix=${remote_Ips}
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    protocol=1    remote_ip_prefix=${remote_Ips}

Create protocol ICMP remote-SG SecurityGroup
    [Arguments]    ${sg_name}    ${remote_sg}    ${ether_type}=IPv4
    [Documentation]    Allow ICMP packets for this suite which has respective remote-security-group
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    protocol=1    remote_group_id=${remote_sg}
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    protocol=1    remote_group_id=${remote_sg}

Create ICMP type code protocol permit SecurityGroup
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with ALL ICMP protocols.
    Neutron Security Group Create    ${sg-name}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    ${cmd}=    Set Variable    openstack security group rule create ${sg-name} --ingress --protocol icmp --icmp-type 8 --icmp-code 0
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Not Be True    ${rc}
    ${cmd}=    Set Variable    openstack security group rule create ${sg-name} --egress --protocol icmp --icmp-type 8 --icmp-code 0
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Not Be True    ${rc}

Create ICMP type code protocol Deny SecurityGroup
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with ALL ICMP protocols.
    Neutron Security Group Create    ${sg-name}
    ${cmd}=    Set Variable    openstack security group rule create ${sg-name} --ingress --protocol icmp --icmp-type 8 --icmp-code 0
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Not Be True    ${rc}
    ${cmd}=    Set Variable    openstack security group rule create ${sg-name} --egress --protocol icmp --icmp-type 8 --icmp-code 0
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Not Be True    ${rc}

Create protocol ICMP type-code remote-ip SecurityGroup
    [Arguments]    ${sg_name}    ${remote_Ips}    ${ether_type}=IPv4
    [Documentation]    Allow ICMP packets for this suite which has respective remote-ip
    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    ${cmd}=    Set Variable    openstack security group rule create ${sg-name} --ingress --protocol icmp --icmp-type 8 --icmp-code 0 --remote-ip ${remote_Ips}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Not Be True    ${rc}
    ${cmd}=    Set Variable    openstack security group rule create ${sg-name} --egress --protocol icmp --icmp-type 8 --icmp-code 0 --remote-ip ${remote_Ips}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Not Be True    ${rc}

Create protocol ICMP type-code remote-security-group SecurityGroup
    [Arguments]    ${sg_name}    ${remote_sg}    ${ether_type}=IPv4
    [Documentation]    Allow ICMP packets for this suite which has respective remote-security-group
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    ${cmd}=    Set Variable    openstack security group rule create ${sg-name} --ingress --protocol icmp --icmp-type 8 --icmp-code 0 --remote-group ${remote_sg}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Not Be True    ${rc}
    ${cmd}=    Set Variable    openstack security group rule create ${sg-name} --egress --protocol icmp --icmp-type 8 --icmp-code 0 --remote-group ${remote_sg}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Not Be True    ${rc}

Create DNS protocol SecurityGroup
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with ALL DNS protocols.
    Neutron Security Group Create    ${sg-name}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53

Create protocol DNS remote-ip SecurityGroup
    [Arguments]    ${sg_name}    ${remote_Ips}    ${ether_type}=IPv4
    [Documentation]    Allow DNS packets for this suite which has respective remote-ip
    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=${remote_Ips}
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    protocol=tcp    port_range_max=53    port_range_min=53    remote_ip_prefix=${remote_Ips}

Create protocol DNS remote-SG SecurityGroup
    [Arguments]    ${sg_name}    ${remote_sg}    ${ether_type}=IPv4
    [Documentation]    Allow DNS packets for this suite which has respective remote-security-group
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${remote_sg}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=tcp    port_range_max=53    port_range_min=53    remote_group_id=${remote_sg}

Create HTTP protocol SecurityGroup
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with ALL HTTP protocols.
    Neutron Security Group Create    ${sg-name}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=22    port_range_min=22    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80

Create protocol HTTP remote-ip SecurityGroup
    [Arguments]    ${sg_name}    ${remote_Ips}    ${ether_type}=IPv4
    [Documentation]    Allow HTTP packets for this suite which has respective remote-ip
    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=${remote_Ips}
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    protocol=tcp    port_range_max=80    port_range_min=80    remote_ip_prefix=${remote_Ips}

Create protocol HTTP remote-SG SecurityGroup
    [Arguments]    ${sg_name}    ${remote_sg}    ${ether_type}=IPv4
    [Documentation]    Allow HTTP packets for this suite which has respective remote-security-group
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=22    port_range_min=22    protocol=tcp
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${remote_sg}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=tcp    port_range_max=80    port_range_min=80    remote_group_id=${remote_sg}

TCP connection timed out
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    TCP communication check fail.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${src_ip}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    Connection timed out

TCP connection refused
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    TCP communication check fail.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${src_ip}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    Connection refused

Unset SubNet
    [Arguments]    ${subnet_name}    ${additional_args}=${EMPTY}
    [Documentation]    Unset subnet with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet unset ${subnet_name} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Secuirty Group rule list
    [Arguments]    ${sg_name}
    [Documentation]    Secuirty Group rule list
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group rule list ${sg_name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Create protocol TCP remote-SG SecurityGroup CLI
    [Arguments]    ${sg_name}    ${remote_sg}    ${ether_type}=IPv4
    [Documentation]    Allow TCP packets for this suite which has respective remote-security-group
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    ...    remote_group_id=${remote_sg}

Create Vm Instance On Compute Node from net-id
    [Arguments]    ${networkName}    ${vm_instance_name}    ${compute_node}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id}=    Get Net Id    ${networkName}    ${devstack_conn_id}
    ${hostname_compute_node}=    Get Hypervisor Hostname From IP    ${compute_node}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image ${image} --flavor ${flavor} --nic net-id=${net_id} --security-group ${sg} --availability-zone nova:${hostname_compute_node} ${vm_instance_name}
    Log    ${output}
    Should Not Be True    ${rc}

Create Vm Instances V4Fixed-IP
    [Arguments]    ${net_name}    ${vm}    ${fixed}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    ...    ${min}=1    ${max}=1
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    : FOR    ${VmElement}    IN    @{vm}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image ${image} --flavor ${flavor} --nic net-id=${net_id}${fixed} ${VmElement} --security-group ${sg} --min ${min} --max ${max}
    \    Should Not Be True    ${rc}
    \    Log    ${output}

Create Vm Instances auto or none
    [Arguments]    ${net_name}    ${vm}    ${fixed}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    ...    ${min}=1    ${max}=1
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    : FOR    ${VmElement}    IN    @{vm}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack --os-compute-api-version 2.37 server create --image ${image} --flavor ${flavor} --nic ${fixed} ${VmElement} --security-group ${sg} --min ${min} --max ${max}
    \    Should Not Be True    ${rc}
    \    Log    ${output}

Create Availabilityzone
    [Arguments]    ${hypervisor_ip}    ${zone_name}    ${aggregate_name}
    [Documentation]    Creates the Availabilityzone for given host IP
    ${hostname}=    Get Hypervisor Hostname From IP    ${hypervisor_ip}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate create --zone ${zone_name} ${aggregate_name}
    Log    ${output}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate add host ${aggregate_name} ${hostname}
    Should Not Be True    ${rc}
    [Return]    ${zone_name}

Server Show
    [Arguments]    ${vm_name}
    [Documentation]    Show server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show ${vm_name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Server Remove Fixed ip
    [Arguments]    ${vm_name}    ${fixed_ip}
    [Documentation]    Remove fixed ip from server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove fixed ip ${vm_name} ${fixed_ip}
    Log    ${output}
    Should Not Be True    ${rc}

Delete Availabilityzone
    [Arguments]    ${hypervisor_ip}    ${aggregate_name}
    [Documentation]    Removes the Availabilityzone for given host IP
    ${hostname}=    Get Hypervisor Hostname From IP    ${hypervisor_ip}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate remove host ${aggregate_name} ${hostname}
    Log    ${output}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate delete ${aggregate_name}
    Log    ${output}
    Should Not Be True    ${rc}

Clear L2_Network
    [Documentation]    This test case will clear all the Network and VM instances
    ...    including SG and Router Attached to the Network.
    ${rc}    ${router_output}=    Run And Return Rc And Output    openstack router list -cID -fvalue
    Log    ${router_output}
    @{routers}=    Split String    ${router_output}    \n
    ${rc}    ${subnet_output}=    Run And Return Rc And Output    openstack subnet list -cID -fvalue
    Log    ${subnet_output}
    @{subnets}=    Split String    ${subnet_output}    \n
    : FOR    ${router}    IN    @{routers}
    \    Run Keyword And Ignore Error    Remove Interfaces    ${router}    ${subnets}
    : FOR    ${router}    IN    @{routers}
    \    Run Keyword And Ignore Error    Delete Router    ${router}
    ${rc}    ${server_output}=    Run And Return Rc And Output    openstack server list -cID -fvalue
    Log    ${server_output}
    @{servers}=    Split String    ${server_output}    \n
    : FOR    ${server}    IN    @{servers}
    \    Run    openstack server delete ${server}
    ${rc}    ${port_output}=    Run And Return Rc And Output    openstack port list -cID -fvalue
    Log    ${port_output}
    @{ports}=    Split String    ${port_output}    \n
    : FOR    ${port}    IN    @{ports}
    \    Run    openstack port delete ${port}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    : FOR    ${sg}    IN    @{sgs}
    \    Run    openstack security group delete ${sg}
    ${rc}    ${subnet_output}=    Run And Return Rc And Output    openstack subnet list -cID -fvalue
    Log    ${subnet_output}
    @{subnets}=    Split String    ${subnet_output}    \n
    : FOR    ${subnet}    IN    @{subnets}
    \    Run    openstack subnet delete ${subnet}
    ${rc}    ${network_output}=    Run And Return Rc And Output    openstack network list -cID -fvalue
    Log    ${network_output}
    @{networks}=    Split String    ${network_output}    \n
    : FOR    ${network}    IN    @{networks}
    \    Run    openstack network delete ${network}

Floating ip Set
    [Arguments]    ${port}    ${fixed_ip}    ${floating_ip}
    [Documentation]    set port,fixed ip floating ip and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip set --port ${port} --fixed-ip-address ${fixed_ip} ${floating_ip}
    Log    ${output}
    Should Not Be True    ${rc}

Create Floating IPs
    [Arguments]    ${external_net}    ${additional_args}=${EMPTY}
    [Documentation]    Create floating IPs with nova request
    ${ip_list}=    Create List    @{EMPTY}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip create ${external_net} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}
    @{ip}    Get Regexp Matches    ${output}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    ${ip_length}    Get Length    ${ip}
    Run Keyword If    ${ip_length}>0    Append To List    ${ip_list}    @{ip}[0]
    ...    ELSE    Append To List    ${ip_list}    None
    [Return]    ${ip_list}

Enable Server Restore In All Control Nodes
    [Documentation]    Enables Server Restore Option in all control
    ${control_1_cxn}=    Get ComputeNode Connection    ${OS_CONTROL_NODE_1_IP}
    Enable Server Restore Option With Nova Control    ${control_1_cxn}
    ${control_2_cxn}=    Get ComputeNode Connection    ${OS_CONTROL_NODE_2_IP}
    Enable Server Restore Option With Nova Control    ${control_2_cxn}
    ${control_3_cxn}=    Get ComputeNode Connection    ${OS_CONTROL_NODE_3_IP}
    Enable Server Restore Option With Nova Control    ${control_3_cxn}

Disable Server Restore In All Control Nodes
    [Documentation]    Enables Server Restore Option in all control
    ${control_1_cxn}=    Get ComputeNode Connection    ${OS_CONTROL_NODE_1_IP}
    Disable Server Restore Option With Nova Control    ${control_1_cxn}
    ${control_2_cxn}=    Get ComputeNode Connection    ${OS_CONTROL_NODE_2_IP}
    Disable Server Restore Option With Nova Control    ${control_2_cxn}
    ${control_3_cxn}=    Get ComputeNode Connection    ${OS_CONTROL_NODE_3_IP}
    Disable Server Restore Option With Nova Control    ${control_3_cxn}

Enable Server Restore Option With Nova Control
    [Arguments]    ${control_cxn}
    Switch Connection    ${control_cxn}
    Crudini Edit    ${control_cxn}    /etc/nova/nova.conf    DEFAULT    reclaim_instance_interval    14000
    Restart Service    ${control_cxn}    openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

Disable Server Restore Option With Nova Control
    [Arguments]    ${control_cxn}
    Switch Connection    ${control_cxn}
    Crudini Delete    ${control_cxn}    /etc/nova/nova.conf    DEFAULT    reclaim_instance_interval
    Restart Service    ${control_cxn}    openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

Enable Server Restore In All Compute Nodes
    [Documentation]    Enables Server Restore Option in all computes
    ${compute_1_cxn}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Enable Server Restore Option With Nova Compute    ${compute_1_cxn}
    ${compute_2_cxn}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Enable Server Restore Option With Nova Compute    ${compute_2_cxn}

Disable Server Restore In All Compute Nodes
    [Documentation]    Enables Server Restore Option in all computes
    ${compute_1_cxn}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Disable Server Restore Option With Nova Compute    ${compute_1_cxn}
    ${compute_2_cxn}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Disable Server Restore Option With Nova Compute    ${compute_2_cxn}

Enable Server Restore Option With Nova Compute
    [Arguments]    ${compute_cxn}
    Switch Connection    ${compute_cxn}
    Crudini Edit    ${compute_cxn}    /etc/nova/nova.conf    DEFAULT    reclaim_instance_interval    14000
    Restart Service    ${compute_cxn}    openstack-nova-compute libvirtd

Disable Server Restore Option With Nova Compute
    [Arguments]    ${compute_cxn}
    Switch Connection    ${compute_cxn}
    Crudini Delete    ${compute_cxn}    /etc/nova/nova.conf    DEFAULT    reclaim_instance_interval
    Restart Service    ${compute_cxn}    openstack-nova-compute libvirtd

Enable Live Migration In A Node
    [Arguments]    ${compute_cxn}
    Switch Connection    ${compute_cxn}
    Crudini Edit    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    listen_tls    0
    Crudini Edit    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    listen_tcp    0
    Crudini Edit    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    auth_tcp    '"none"'
    Crudini Edit    ${compute_cxn}    /etc/sysconfig/libvirtd    ''    LIBVIRTD_ARGS    '"--listen"'
    Crudini Edit    ${compute_cxn}    /etc/nova/nova.conf    DEFAULT    instances_path    '/var/lib/nova/instances_live_migration'
    Restart Service    ${compute_cxn}    openstack-nova-compute libvirtd

Enable Live Migration In All Compute Nodes
    [Documentation]    Enables Live Migration in all computes
    ${compute_1_cxn}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Enable Live Migration In A Node    ${compute_1_cxn}
    ${compute_2_cxn}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Enable Live Migration In A Node    ${compute_2_cxn}

Disable Live Migration In All Compute Nodes
    [Documentation]    Enables Live Migration in all computes
    ${compute_1_cxn}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Disable Live Migration In A Node    ${compute_1_cxn}
    ${compute_2_cxn}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Disable Live Migration In A Node    ${compute_2_cxn}

Disable Live Migration In A Node
    [Arguments]    ${compute_cxn}
    Switch Connection    ${compute_cxn}
    Crudini Delete    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    listen_tls
    Crudini Delete    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    listen_tcp
    Crudini Delete    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    auth_tcp
    Crudini Delete    ${compute_cxn}    /etc/sysconfig/libvirtd    ''    LIBVIRTD_ARGS
    Crudini Delete    ${compute_cxn}    /etc/nova/nova.conf    DEFAULT    instances_path
    Restart Service    ${compute_cxn}    openstack-nova-compute libvirtd

Crudini Edit
    [Arguments]    ${os_node_cxn}    ${conf_file}    ${section}    ${key}    ${value}
    [Documentation]    Crudini edit on a configuration file
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo crudini --verbose --set --inplace ${conf_file} ${section} ${key} ${value}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Crudini Delete
    [Arguments]    ${os_node_cxn}    ${conf_file}    ${section}    ${key}
    [Documentation]    Crudini edit on a configuration file
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo crudini --verbose --del --inplace ${conf_file} ${section} ${key}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Restart Service
    [Arguments]    ${os_node_cxn}    ${service}
    [Documentation]    Restart a service in CentOs
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo systemctl restart ${service}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Floating ip Delete
    [Arguments]    ${floating_ip}
    [Documentation]    Delete floating ip's and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip delete ${floating_ip}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Remove Interfaces
    [Arguments]    ${router_name}    ${subnet_names}
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${subnet_name}    IN    @{subnet_names}
    \    Run    openstack router remove subnet ${router_name} ${subnet_name}

Floating ip List
    [Documentation]    List floating ip's and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip list
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Router Unset
    [Arguments]    ${router_name}    ${cmd}
    [Documentation]    Update the router with the command. Router name and command should be passed as argument.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router unset ${router_name} ${cmd}
    Should Not Be True    ${rc}

Server Remove Floating ip
    [Arguments]    ${vm_name}    ${floating_ip}
    [Documentation]    Remove floating ip from server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove floating ip ${vm_name} ${floating_ip}
    Log    ${output}
    Should Not Be True    ${rc}

Get ComputeNode Connection
    [Arguments]    ${compute_ip}
    ${compute_conn_id}=    SSHLibrary.Open Connection    ${compute_ip}    prompt=]>
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=30s
    [Return]    ${compute_conn_id}
