*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Source Password
    [Arguments]    ${force}=no    ${source_pwd}=yes
    [Documentation]    Sourcing the Openstack PAsswords for neutron configurations
    Run Keyword If    '${source_pwd}' == 'yes' or '${force}' == 'yes'    Write Commands Until Prompt    cd ${DEVSTACK_DEPLOY_PATH}; source openrc admin admin

Get Tenant ID From Security Group
    [Documentation]    Returns tenant ID by reading it from existing default security-group.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-show default | grep "| tenant_id" | awk '{print $4}'
    Log    ${output}
    [Return]    ${output}

Get Tenant ID From Network
    [Arguments]    ${network_uuid}
    [Documentation]    Returns tenant ID by reading it from existing network.
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/networks/network/${network_uuid}/
    Log    ${resp.content}
    ${matches} =    Get Lines Containing String    ${resp.content}    tenant-id
    ${matches}=    Fetch From Right    ${matches}    :
    ${tenant_id}=    Strip String    ${matches}    characters=}]"
    [Return]    ${tenant_id}

Create Network
    [Arguments]    ${network_name}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Network with neutron request.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${command}    Set Variable If    "${verbose}" == "TRUE"    neutron -v net-create ${network_name} ${additional_args}    neutron net-create ${network_name} ${additional_args} | grep -w id | awk '{print $4}'
    ${output}=    Write Commands Until Prompt    ${command}    30s
    Log    ${output}
    [Return]    ${output}

List Networks
    [Documentation]    List networks and return output with neutron client.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron net-list    30s
    Close Connection
    Log    ${output}
    [Return]    ${output}

List Subnets
    [Documentation]    List subnets and return output with neutron client.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron subnet-list    30s
    Close Connection
    Log    ${output}
    [Return]    ${output}

Delete Network
    [Arguments]    ${network_name}
    [Documentation]    Delete Network with neutron request.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v net-delete ${network_name}    30s
    Close Connection
    Log    ${output}
    Should Match Regexp    ${output}    Deleted network: ${network_name}|Deleted network\\(s\\): ${network_name}

Create SubNet
    [Arguments]    ${network_name}    ${subnet}    ${range_ip}
    [Documentation]    Create SubNet for the Network with neutron request.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${network_name} ${range_ip} --name ${subnet}    30s
    Close Connection
    Log    ${output}
    Should Contain    ${output}    Created a new subnet

Create Port
    [Arguments]    ${network_name}    ${port_name}    ${sg}=default
    [Documentation]    Create Port with neutron request.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v port-create ${network_name} --name ${port_name} --security-group ${sg}    30s
    Close Connection
    Log    ${output}
    Should Contain    ${output}    Created a new port

Delete Port
    [Arguments]    ${port_name}
    [Documentation]    Delete Port with neutron request.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v port-delete ${port_name}    30s
    Close Connection
    Log    ${output}
    Should Contain    ${output}    Deleted port: ${port_name}

List Ports
    [Documentation]    List ports and return output with neutron client.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron port-list    30s
    Close Connection
    Log    ${output}
    [Return]    ${output}

Verify Gateway Ips
    [Documentation]    Verifies the Gateway Ips with dump flow.
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${GatewayIpElement}    IN    @{GATEWAY_IPS}
    \    Should Contain    ${output}    ${GatewayIpElement}

Verify Dhcp Ips
    [Documentation]    Verifies the Dhcp Ips with dump flow.
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${DhcpIpElement}    IN    @{DHCP_IPS}
    \    Should Contain    ${output}    ${DhcpIpElement}

Verify No Dhcp Ips
    [Documentation]    Verifies the Dhcp Ips with dump flow.
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${DhcpIpElement}    IN    @{DHCP_IPS}
    \    Should Not Contain    ${output}    ${DhcpIpElement}

Delete SubNet
    [Arguments]    ${subnet}
    [Documentation]    Delete SubNet for the Network with neutron request.
    Log    ${subnet}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-delete ${subnet}
    Close Connection
    Log    ${output}
    Should Match Regexp    ${output}    Deleted subnet: ${subnet}|Deleted subnet\\(s\\): ${subnet}

Verify No Gateway Ips
    [Documentation]    Verifies the Gateway Ips removed with dump flow.
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${GatewayIpElement}    IN    @{GATEWAY_IPS}
    \    Should Not Contain    ${output}    ${GatewayIpElement}

Delete Vm Instance
    [Arguments]    ${vm_name}
    [Documentation]    Delete Vm instances using instance names.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova force-delete ${vm_name}    40s
    Close Connection

Get Net Id
    [Arguments]    ${network_name}    ${devstack_conn_id}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron net-list | grep "${network_name}" | awk '{print $2}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${net_id}=    Get from List    ${splitted_output}    0
    Log    ${net_id}
    [Return]    ${net_id}

Get Port Id
    [Arguments]    ${port_name}    ${devstack_conn_id}
    [Documentation]    Retrieve the port id for the given port name to attach specific vm instance to a particular port
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron port-list | grep "${port_name}" | awk '{print $2}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${port_id}=    Get from List    ${splitted_output}    0
    Log    ${port_id}
    [Return]    ${port_id}

Get Router Id
    [Arguments]    ${router1}    ${devstack_conn_id}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron router-list | grep "${router1}" | awk '{print $2}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${router_id}=    Get from List    ${splitted_output}    0
    Log    ${router_id}
    [Return]    ${router_id}

Create Vm Instances
    [Arguments]    ${net_name}    ${vm_instance_names}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    ${output}=    Write Commands Until Prompt    nova boot --image ${image} --flavor ${flavor} --nic net-id=${net_id} ${VmElement} --security-groups ${sg}    30s
    \    Log    ${output}

Create Vm Instance With Port On Compute Node
    [Arguments]    ${port_name}    ${vm_instance_name}    ${compute_node}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${port_name}    ${devstack_conn_id}
    ${hostname_compute_node}=    Run Command On Remote System    ${compute_node}    hostname
    ${output}=    Write Commands Until Prompt    nova boot --image ${image} --flavor ${flavor} --nic port-id=${port_id} ${vm_instance_name} --security-groups ${sg} --availability-zone nova:${hostname_compute_node}    30s
    Log    ${output}
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${vm_instance_name}

Verify VM Is ACTIVE
    [Arguments]    ${vm_name}
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova show ${vm_name} | grep OS-EXT-STS:vm_state    30s
    Log    ${output}
    Should Contain    ${output}    active

Verify VMs Received DHCP Lease
    [Arguments]    @{vm_list}
    [Documentation]    Using nova console-log on the provided ${vm_name} to search for the string "obtained" which
    ...    correlates to the instance receiving it's IP address via DHCP. This should provide a good indication
    ...    that the instance is fully up and ready.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${output}=    Write Commands Until Prompt    nova console-log ${vm} | grep -i "obtained"    30s
    \    Log    ${output}
    \    Should Contain    ${output}    obtained

View Vm Console
    [Arguments]    ${vm_instance_names}
    [Documentation]    View Console log of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    ${output}=    Write Commands Until Prompt    nova show ${VmElement}
    \    Log    ${output}
    \    ${output}=    Write Commands Until Prompt    nova console-log ${VmElement}
    \    Log    ${output}

Ping Vm From DHCP Namespace
    [Arguments]    ${net_name}    ${vm_ip}
    [Documentation]    Reach all Vm Instance with the net id of the Netowrk.
    Log    ${vm_ip}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    Log    ${net_id}
    ${output}=    Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}    20s
    Log    ${output}
    Close Connection
    Should Contain    ${output}    64 bytes

Ping From DHCP Should Not Succeed
    [Arguments]    ${net_name}    ${vm_ip}
    [Documentation]    Should Not Reach Vm Instance with the net id of the Netowrk.
    Log    ${vm_ip}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    Log    ${net_id}
    ${output}=    Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}    20s
    Close Connection
    Log    ${output}
    Should Not Contain    ${output}    64 bytes

Ping From Instance
    [Arguments]    ${dest_vm}
    [Documentation]    Ping to the expected destination ip.
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 ${dest_vm}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    [Return]    ${output}

Curl Metadata Server
    [Documentation]    Ping to the expected destination ip.
    ${output}=    Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    Write Commands Until Prompt    exit
    Should Contain    ${output}    200

Close Vm Instance
    [Documentation]    Exit the vm instance.
    ${output}=    Write Commands Until Prompt    exit
    Log    ${output}

Check If Console Is VmInstance
    [Arguments]    ${console}=cirros
    [Documentation]    Check if the session has been able to login to the VM instance
    ${output}=    Write Commands Until Expected Prompt    id    ${OS_SYSTEM_PROMPT}
    Should Contain    ${output}    ${console}

Exit From Vm Console
    [Documentation]    Check if the session has been able to login to the VM instance and exit the instance
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance    cirros
    Run Keyword If    ${rcode}    Write Commands Until Prompt    exit
    Get OvsDebugInfo

Check Ping
    [Arguments]    ${ip_address}
    [Documentation]    Run Ping command on the IP available as argument
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 ${ip_address}    ${OS_SYSTEM_PROMPT}
    Should Contain    ${output}    64 bytes

Check Metadata Access
    [Documentation]    Try curl on the Metadataurl and check if it is okay
    ${output}=    Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    Should Contain    ${output}    200

Execute Command on VM Instance
    [Arguments]    ${net_name}    ${src_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network, executes a command inside the VM and returns the ouput.
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    ${net_name}    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${src_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no    d:
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode} =    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output} =    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}
    [Teardown]    Exit From Vm Console
    [Return]    ${output}

Test Operations From Vm Instance
    [Arguments]    ${net_name}    ${src_ip}    ${list_of_local_dst_ips}    ${l2_or_l3}=l2    ${list_of_external_dst_ips}=${NONE}    ${user}=cirros
    ...    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${src_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no    d:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    : FOR    ${dest_ip}    IN    @{list_of_local_dst_ips}
    \    Log    ${dest_ip}
    \    Run Keyword If    ${rcode}    Check Ping    ${dest_ip}
    Run Keyword If    ${rcode}    Check Metadata Access
    Run Keyword If    '${l2_or_l3}' == 'l3'    Ping Other Instances    ${list_of_external_dst_ips}
    [Teardown]    Exit From Vm Console

Ping Other Instances
    [Arguments]    ${list_of_external_dst_ips}
    [Documentation]    Check reachability with other network's instances.
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    : FOR    ${dest_ip}    IN    @{list_of_external_dst_ips}
    \    Log    ${dest_ip}
    \    Run Keyword If    ${rcode}    Check Ping    ${dest_ip}

Create Router
    [Arguments]    ${router_name}
    [Documentation]    Create Router and Add Interface to the subnets.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v router-create ${router_name}    30s
    Close Connection
    Should Contain    ${output}    Created a new router

Add Router Interface
    [Arguments]    ${router_name}    ${interface_name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v router-interface-add ${router_name} ${interface_name}
    Close Connection
    Should Contain    ${output}    Added interface

Remove Interface
    [Arguments]    ${router_name}    ${interface_name}
    [Documentation]    Remove Interface to the subnets.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v router-interface-delete ${router_name} ${interface_name}
    Close Connection
    Should Contain    ${output}    Removed interface from router

Update Router
    [Arguments]    ${router_name}    ${cmd}
    [Documentation]    Update the router with the command. Router name and command should be passed as argument.
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    neutron router-update ${router_name} ${cmd}    30s
    Close Connection
    Should Contain    ${output}    Updated

Show Router
    [Arguments]    ${router_name}    ${options}
    [Documentation]    Show information of a given router. Router name and optional fields should be sent as arguments.
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    neutron router-show ${router_name} ${options}    30s
    Log    ${output}
    Close Connection

Delete Router
    [Arguments]    ${router_name}
    [Documentation]    Delete Router and Interface to the subnets.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v router-delete ${router_name}    60s
    Close Connection
    Should Contain    ${output}    Deleted router:

Get DumpFlows And Ovsconfig
    [Arguments]    ${openstack_node_ip}
    [Documentation]    Get the OvsConfig and Flow entries from OVS from the Openstack Node
    Log    ${openstack_node_ip}
    SSHLibrary.Open Connection    ${openstack_node_ip}    prompt=${DEFAULT_LINUX_PROMPT}
    Utils.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    Write Commands Until Expected Prompt    ip -o link    ]>
    Write Commands Until Expected Prompt    ip -o addr    ]>
    Write Commands Until Expected Prompt    ip route    ]>
    Write Commands Until Expected Prompt    arp -an    ]>
    ${nslist}=    Write Commands Until Expected Prompt    ip netns list | awk '{print $1}'    ]>
    @{lines}    Split To Lines    ${nslist}
    : FOR    ${line}    IN    @{lines}
    \    Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip -o link    ]>
    \    Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip -o addr    ]>
    \    Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip route    ]>
    Write Commands Until Expected Prompt    sudo ovs-vsctl show    ]>
    Write Commands Until Expected Prompt    sudo ovs-vsctl list Open_vSwitch    ]>
    Write Commands Until Expected Prompt    sudo ovs-ofctl show br-int -OOpenFlow13    ]>
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ]>
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-groups br-int -OOpenFlow13    ]>
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-group-stats br-int -OOpenFlow13    ]>

Get ControlNode Connection
    ${control_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=30s
    Source Password    force=yes
    [Return]    ${control_conn_id}

Get OvsDebugInfo
    [Documentation]    Get the OvsConfig and Flow entries from all Openstack nodes
    Run Keyword If    0 < ${NUM_OS_SYSTEM}    Get DumpFlows And Ovsconfig    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Get DumpFlows And Ovsconfig    ${OS_COMPUTE_1_IP}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Get DumpFlows And Ovsconfig    ${OS_COMPUTE_2_IP}

Show Debugs
    [Arguments]    ${vm_indices}
    [Documentation]    Run these commands for debugging, it can list state of VM instances and ip information in control node
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo ip netns list
    Log    ${output}
    : FOR    ${index}    IN    @{vm_indices}
    \    ${output}=    Write Commands Until Prompt    nova show ${index}    30s
    \    Log    ${output}
    Close Connection
    List Networks
    List Subnets
    List Ports

Create Security Group
    [Arguments]    ${sg_name}    ${desc}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova secgroup-create ${sg_name} ${desc}    40s
    Close Connection

Create Security Rule
    [Arguments]    ${direction}    ${protocol}    ${min_port}    ${max_port}    ${remote_ip}    ${sg_name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-rule-create --direction ${direction} --protocol ${protocol} --port-range-min ${min_port} --port-range-max ${max_port} --remote-ip-prefix ${remote_ip} ${sg_name}
    Close Connection

Neutron Security Group Show
    [Arguments]    ${SecurityGroupRuleName}    ${additional_args}=${EMPTY}
    [Documentation]    Displays the neutron security group configurations that belongs to a given neutron security group name
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron security-group-show ${SecurityGroupRuleName} ${additional_args}
    Log    ${cmd}
    ${output}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${output}
    Close Connection
    [Return]    ${output}

Neutron Port Show
    [Arguments]    ${PortName}    ${additional_args}=${EMPTY}
    [Documentation]    Display the port configuration that belong to a given neutron port
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron port-show ${PortName} ${additional_args}
    Log    ${cmd}
    ${output}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${output}
    Close Connection
    [Return]    ${output}

Neutron Security Group Create
    [Arguments]    ${SecurityGroupName}    ${additional_args}=${EMPTY}
    [Documentation]    Create a security group with specified name ,description & protocol value according to security group template
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron security-group-create ${SecurityGroupName} ${additional_args}
    Log    ${cmd}
    ${output}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${output}
    Should Contain    ${output}    Created a new security_group
    ${sgp_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${sgp_id}
    Close Connection
    [Return]    ${output}    ${sgp_id}

Neutron Security Group Update
    [Arguments]    ${SecurityGroupName}    ${additional_args}=${EMPTY}
    [Documentation]    Updating security groups
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron security-group-update ${SecurityGroupName} ${additional_args}
    Log    ${cmd}
    ${output}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${output}
    Close Connection
    [Return]    ${output}

Neutron Security Group Rule Create
    [Arguments]    ${Security_group_name}    &{Kwargs}
    [Documentation]    Creates neutron security rule with neutron request with or without optional params, here security group name is mandatory args, rule with optional params can be created by passing the optional args values ex: direction=${INGRESS_EGRESS}, Then these optional params are catenated with mandatory args, example of usage: "Neutron Security Group Rule Create ${SGP_SSH} direction=${RULE_PARAMS[0]} ethertype=${RULE_PARAMS[1]} ..."
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Run Keyword If    ${Kwargs}    Log    ${Kwargs}
    ${description}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    description    default=${None}
    ${direction}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    direction    default=${None}
    ${ethertype}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    ethertype    default=${None}
    ${port_range_max}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    port_range_max    default=${None}
    ${port_range_min}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    port_range_min    default=${None}
    ${protocol}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    protocol    default=${None}
    ${remote_group_id}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    remote_group_id    default=${None}
    ${remote_ip_prefix}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    remote_ip_prefix    default=${None}
    ${cmd}=    Set Variable    neutron security-group-rule-create ${Security_group_name}
    ${cmd}=    Run Keyword If    '${description}'!='None'    Catenate    ${cmd}    --description ${description}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${direction}'!='None'    Catenate    ${cmd}    --direction ${direction}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${ethertype}'!='None'    Catenate    ${cmd}    --ethertype ${ethertype}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${port_range_max}'!='None'    Catenate    ${cmd}    --port_range_max ${port_range_max}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${port_range_min}'!='None'    Catenate    ${cmd}    --port_range_min ${port_range_min}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${protocol}'!='None'    Catenate    ${cmd}    --protocol ${protocol}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${remote_group_id}'!='None'    Catenate    ${cmd}    --remote_group_id ${remote_group_id}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${remote_ip_prefix}'!='None'    Catenate    ${cmd}    --remote_ip_prefix ${remote_ip_prefix}
    ...    ELSE    Catenate    ${cmd}
    ${output}=    Write Commands Until Prompt    ${cmd}    30s
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Contain    ${output}    Created a new security_group_rule
    Close Connection
    [Return]    ${output}    ${rule_id}

Create Neutron Port With Additional Params
    [Arguments]    ${network_name}    ${port_name}    ${additional_args}=${EMPTY}
    [Documentation]    Create Port With given additional parameters
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron -v port-create ${network_name} --name ${port_name} ${additional_args}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    Should Contain    ${output}    Created a new port
    ${port_id}=    Should Match Regexp    ${OUTPUT}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${port_id}
    Close Connection
    [Return]    ${OUTPUT}    ${port_id}
