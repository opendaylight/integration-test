*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          Netvirt.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot

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
    ${resp}=    Get_From_Uri    uri=${CONFIG_API}/neutron:neutron/networks/network/${network_uuid}/    accept=${ACCEPT_EMPTY}    session=session
    ${tenant_id}=    Utils.Extract Value From Content    ${resp}    /network/0/tenant-id    strip
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
    [Arguments]    ${network_name}    ${subnet}    ${range_ip}    ${additional_args}=${EMPTY}
    [Documentation]    Create SubNet for the Network with neutron request.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${network_name} ${range_ip} --name ${subnet} ${additional_args}    30s
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
    Should Match Regexp    ${output}    Deleted port: ${port_name}|Deleted port\\(s\\): ${port_name}

List Ports
    [Documentation]    List ports and return output with neutron client.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron port-list    30s
    Close Connection
    Log    ${output}
    [Return]    ${output}

List Nova VMs
    [Documentation]    List VMs and return output with nova client.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova list    30s
    Close Connection
    Log    ${output}
    [Return]    ${output}

Create And Associate Floating IPs
    [Arguments]    ${external_net}    @{vm_list}
    [Documentation]    Create and associate floating IPs to VMs with nova request
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ip_list}=    Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${output}=    Write Commands Until Prompt    neutron floatingip-create ${external_net}    30s
    \    Log    ${output}
    \    @{ip}    Get Regexp Matches    ${output}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${ip_length}    Get Length    ${ip}
    \    Run Keyword If    ${ip_length}>0    Append To List    ${ip_list}    @{ip}[0]
    \    ...    ELSE    Append To List    ${ip_list}    None
    \    ${output}=    Write Commands Until Prompt    nova floating-ip-associate ${vm} @{ip}[0]    30s
    \    Log    ${output}
    [Return]    ${ip_list}

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

Get Subnet Id
    [Arguments]    ${subnet_name}    ${devstack_conn_id}
    [Documentation]    Retrieve the subnet id for the given subnet name
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron subnet-list | grep "${subnet_name}" | awk '{print $2}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${subnet_id}=    Get from List    ${splitted_output}    0
    Log    ${subnet_id}
    [Return]    ${subnet_id}

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
    [Documentation]    Retrieve the router id for the given router name
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
    [Documentation]    Using nova console-log on the provided ${vm_list} to search for the string "obtained" which
    ...    correlates to the instance receiving it's IP address via DHCP. Also retrieved is the ip of the nameserver
    ...    if available in the console-log output. The keyword will also return a list of the learned ips as it
    ...    finds them in the console log output, and will have "None" for Vms that no ip was found.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ip_list}    Create List    @{EMPTY}
    ${dhcp_ip}    Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${vm_ip_line}=    Write Commands Until Prompt    nova console-log ${vm} | grep -i "obtained"    30s
    \    Log    ${vm_ip_line}
    \    @{vm_ip}    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
    \    ${vm_ip_length}    Get Length    ${vm_ip}
    \    Run Keyword If    ${vm_ip_length}>0    Append To List    ${ip_list}    @{vm_ip}[0]
    \    ...    ELSE    Append To List    ${ip_list}    None
    \    ${dhcp_ip_line}=    Write Commands Until Prompt    nova console-log ${vm} | grep "^nameserver"    30s
    \    Log    ${dhcp_ip_line}
    \    @{dhcp_ip}    Get Regexp Matches    ${dhcp_ip_line}    [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
    \    Log    ${dhcp_ip}
    ${dhcp_length}    Get Length    ${dhcp_ip}
    Return From Keyword If    ${dhcp_length}==0    ${ip_list}    ${EMPTY}
    [Return]    ${ip_list}    @{dhcp_ip}[0]

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

Ping Vm From Control Node
    [Arguments]    ${vm_floating_ip}
    [Documentation]    Ping VM floating IP from control node
    Log    ${vm_floating_ip}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    ping -c 3 ${vm_floating_ip}    20s
    Log    ${output}
    Close Connection
    Should Contain    ${output}    64 bytes

Ping From Instance
    [Arguments]    ${dest_vm_ip}
    [Documentation]    Ping to the expected destination ip.
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 ${dest_vm_ip}    ${OS_SYSTEM_PROMPT}
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
    [Arguments]    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network, executes a command inside the VM and returns the ouput.
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    ${net_name}    ${devstack_conn_id}
    Log    ${vm_ip}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no    d:
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode} =    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output} =    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}
    [Teardown]    Exit From Vm Console
    [Return]    ${output}

Test Operations From Vm Instance
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${src_ip}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip}    d:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    : FOR    ${dest_ip}    IN    @{dest_ips}
    \    Log    ${dest_ip}
    \    ${string_empty}=    Run Keyword And Return Status    Should Be Empty    ${dest_ip}
    \    Run Keyword If    ${string_empty}    Continue For Loop
    \    Run Keyword If    ${rcode}    Check Ping    ${dest_ip}
    Run Keyword If    ${rcode}    Check Metadata Access
    [Teardown]    Exit From Vm Console

Ping Other Instances
    [Arguments]    ${list_of_external_dst_ips}
    [Documentation]    Check reachability with other network's instances.
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    : FOR    ${dest_ip}    IN    @{list_of_external_dst_ips}
    \    Log    ${dest_ip}
    \    Check Ping    ${dest_ip}

Create Router
    [Arguments]    ${router_name}
    [Documentation]    Create Router and Add Interface to the subnets.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v router-create ${router_name}    30s
    Close Connection
    Should Contain    ${output}    Created a new router

List Router
    [Documentation]    List Router and return output with neutron client.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron router-list    30s
    Close Connection
    Log    ${output}
    [Return]    ${output}

Add Router Interface
    [Arguments]    ${router_name}    ${interface_name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v router-interface-add ${router_name} ${interface_name}
    Close Connection
    Should Contain    ${output}    Added interface

Show Router Interface
    [Arguments]    ${router_name}
    [Documentation]    List Router interface associated with given Router and return output with neutron client.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron router-port-list ${router_name} -f csv    30s
    Close Connection
    Log    ${output}
    [Return]    ${output}

Add Router Gateway
    [Arguments]    ${router_name}    ${network_name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v router-gateway-set ${router_name} ${network_name}
    Close Connection
    Should Contain    ${output}    Set gateway

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
    Should Match Regexp    ${output}    Deleted router: ${router_name}|Deleted router\\(s\\): ${router_name}

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
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-ports-desc br-int -OOpenFlow13    ]>
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ]>
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-groups br-int -OOpenFlow13    ]>
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-group-stats br-int -OOpenFlow13    ]>

Get Karaf Log Type From Test Start
    [Arguments]    ${ip}    ${test_name}    ${type}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    ${cmd}    Set Variable    sed '1,/ROBOT MESSAGE: Starting test ${test_name}/d' ${log_file} | grep '${type}'
    ${output}    Run Command On Controller    ${ip}    ${cmd}    ${user}    ${password}    ${prompt}
    Log    ${output}

Get Karaf Log Types From Test Start
    [Arguments]    ${ip}    ${test_name}    ${types}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    : FOR    ${type}    IN    @{types}
    \    Get Karaf Log Type From Test Start    ${ip}    ${test_name}    ${type}    ${user}    ${password}
    \    ...    ${prompt}    ${log_file}

Get Karaf Log Events From Test Start
    [Arguments]    ${test_name}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ${log_types} =    Create List    ERROR    WARN    Exception
    Run Keyword If    0 < ${NUM_ODL_SYSTEM}    Get Karaf Log Types From Test Start    ${ODL_SYSTEM_IP}    ${test_name}    ${log_types}
    Run Keyword If    1 < ${NUM_ODL_SYSTEM}    Get Karaf Log Types From Test Start    ${ODL_SYSTEM_2_IP}    ${test_name}    ${log_types}
    Run Keyword If    2 < ${NUM_ODL_SYSTEM}    Get Karaf Log Types From Test Start    ${ODL_SYSTEM_3_IP}    ${test_name}    ${log_types}

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

Get Test Teardown Debugs
    [Arguments]    ${test_name}=${TEST_NAME}
    Get OvsDebugInfo
    Get Model Dump    ${HA_PROXY_IP}
    Get Karaf Log Events From Test Start    ${test_name}

Show Debugs
    [Arguments]    @{vm_indices}
    [Documentation]    Run these commands for debugging, it can list state of VM instances and ip information in control node
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo ip netns list
    Log    ${output}
    : FOR    ${index}    IN    @{vm_indices}
    \    ${output}=    Write Commands Until Prompt    nova show ${index}    30s
    \    Log    ${output}
    Close Connection
    List Nova VMs
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
