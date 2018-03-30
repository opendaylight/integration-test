*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          DataModels.robot
Resource          DevstackUtils.robot
Resource          L2GatewayOperations.robot
Resource          SetupUtils.robot
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot
Variables         ../variables/netvirt/Modules.py

*** Keywords ***
Collect VM IP Addresses
    [Arguments]    ${fail_on_none}    @{vm_list}
    [Documentation]    Using the console-log on the provided ${vm_list} to search for the string "obtained" which
    ...    correlates to the instance receiving it's IP address via DHCP. Also retrieved is the ip of the nameserver
    ...    if available in the console-log output. The keyword will also return a list of the learned ips as it
    ...    finds them in the console log output, and will have "None" for Vms that no ip was found.
    ${ip_list}    Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${rc}    ${vm_ip_line}=    Run And Return Rc And Output    openstack console log show ${vm} | grep -i "obtained"
    \    @{vm_ip}    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${vm_ip_length}    Get Length    ${vm_ip}
    \    Run Keyword If    ${vm_ip_length}>0    Append To List    ${ip_list}    @{vm_ip}[0]
    \    ...    ELSE    Append To List    ${ip_list}    None
    \    ${rc}    ${dhcp_ip_line}=    Run And Return Rc And Output    openstack console log show ${vm} | grep "^nameserver"
    \    ${dhcp_ip}    Get Regexp Matches    ${dhcp_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${dhcp_ip_length}    Get Length    ${dhcp_ip}
    \    Run Keyword If    ${dhcp_ip_length}<=0    Append To List    ${dhcp_ip}    None
    \    ${vm_console_output}=    Run    openstack console log show ${vm}
    \    Log    ${vm_console_output}
    ${dhcp_length}    Get Length    ${dhcp_ip}
    Run Keyword If    '${fail_on_none}' == 'true'    Should Not Contain    ${ip_list}    None
    Run Keyword If    '${fail_on_none}' == 'true'    Should Not Contain    ${dhcp_ip}    None
    Return From Keyword If    ${dhcp_length}==0    ${ip_list}    ${EMPTY}
    [Return]    ${ip_list}    ${dhcp_ip}

Collect IP
    [Arguments]    ${VM_Name}
    ${rc}    ${vm_ip_line}=    Run And Return Rc And Output    openstack server list | grep -i "${VM_Name}"
    ${vm_ip}    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    [Return]    ${vm_ip}

Get ComputeNode Connection
    [Arguments]    ${compute_ip}
    ${compute_conn_id}=    SSHLibrary.Open Connection    ${compute_ip}    prompt=]>
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=30s
    [Return]    ${compute_conn_id}

Verify VM UP Status
    [Arguments]    ${vm_name}
    [Documentation]    Run these commands to check whether the created vm instance is ready to login.
    ${output}=    Run And Return Rc And Output    openstack console log show ${vm_name}
    #${status}=    encode('utf-8').${output}
    #${status}=    Decode Bytes To String    ${output}    UTF-8
    #Log    ${status}
    #Should Contain    ${status}    finished at
    Sleep    500s

Poll VM UP Boot Status
    [Arguments]    ${vm_name}    ${retry}=1800s    ${retry_interval}=5s
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    Wait Until Keyword Succeeds    ${retry}    ${retry_interval}    Verify VM UP Status    ${vm_name}

Create ANY SecurityGroup Rule
    [Arguments]    ${sg_name}    ${dir}    ${ether_type}=IPv4    ${additional_args}=${EMPTY}
    [Documentation]    Create Security Group Rule without Protocol
    ${rc}    ${output}=    Run And Return Rc And Output    neutron security-group-rule-create ${sg_name} --direction ${dir} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}

Create Availabilityzone
    [Arguments]    ${hypervisor_ip}    ${zone_name}    ${aggregate_name}
    [Documentation]    Creates the Availabilityzone for given host IP
    ${hostname}=    Get Hypervisor Hostname From IP    ${hypervisor_ip}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate create --zone ${zone_name} ${aggregate_name}
    Log    ${output}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate add host ${aggregate_name} ${hostname}
    Should Not Be True    ${rc}
    [Return]    ${zone_name}

Delete Availabilityzone
    [Arguments]    ${hypervisor_ip}    ${aggregate_name}
    [Documentation]    Removes the Availabilityzone for given host IP
    ${hostname}=    Get Hypervisor Hostname From IP    ${hypervisor_ip}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate remove host ${aggregate_name} ${hostname}
    Log    ${output}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate delete ${aggregate_name}
    Log    ${output}
    Should Not Be True    ${rc}

Ssh From VM Instance Should Not Succeed
    [Arguments]    ${vm_ip}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh from another VM instance
    Log    ${vm_ip}
    ${output}=    Write Commands Until Expected Prompt    ssh ${user}@${vm_ip}    ${OS_SYSTEM_PROMPT}    timeout=90s
    Should Contain Any    ${output}    Connection timed out    No route to host
    Log    ${output}

Ssh From VM Instance
    [Arguments]    ${vm_ip}    ${user}=cirros    ${password}=cubswin:)    ${first_login}=True
    [Documentation]    Login to the vm instance using ssh from another VM instance
    Log    ${vm_ip}
    ${output} =    Run Keyword If    "${first_login}" == "True"    Write Commands Until Expected Prompt    ssh ${user}@${vm_ip}    (y/n)
    ...    ELSE    Write Commands Until Expected Prompt    ssh ${user}@${vm_ip}    password:
    Log    ${output}
    ${output} =    Run Keyword If    "${first_login}" == "True"    Write Commands Until Expected Prompt    y    password:
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ${password}    $
    Log    ${output}
    ${rcode} =    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output} =    Write Commands Until Expected Prompt    ifconfig    $
    Should Contain    ${output}    ${vm_ip}
    ${output} =    Write Commands Until Expected Prompt    exit    $
    [Return]    ${output}

Get ControlNode Connection By IP
    [Arguments]    ${OS_CONTROL_NODE_IP}
    ${control_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=30s
    Switch Connection    ${control_conn_id}

TCP connection timed out
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    TCP communication check fail.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${src_ip}
    ${net_id}=    Get Net Id    ${net_name}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    Connection timed out

Kill ovs-vswitchd in compute node
    [Arguments]    ${OS_COMPUTE_IP}
    [Documentation]    Kill ovsdb-server in compute node
    ${output}=    Get ComputeNode Connection    ${OS_COMPUTE_IP}
    Log    ${output}
    ${Output}=    Write Commands Until Prompt    ifconfig
    ${Output}=    Write Commands Until Prompt    ps -ef | grep ovs-vswitchd | awk '{print$2}'
    ${split}=    Split String    ${Output}    \n
    ${length}=    Get Length    ${split}
    Log    @{split}[0]
    Log    @{split}[1]
    ${Output}=    Write Commands Until Prompt    sudo kill -15 @{split}[0]
    ${Output}=    Write Commands Until Prompt    sudo kill -15 @{split}[1]

Kill ovsdb-server in compute node
    [Arguments]    ${OS_COMPUTE_IP}
    [Documentation]    Kill ovsdb-server in compute node1
    ${output}=    Get ComputeNode Connection    ${OS_COMPUTE_IP}
    Log    ${output}
    ${Output}=    Write Commands Until Prompt    ifconfig
    ${Output}=    Write Commands Until Prompt    ps -ef | grep ovsdb-server | awk '{print$2}'
    ${split}=    Split String    ${Output}    \n
    ${length}=    Get Length    ${split}
    Log    @{split}[0]
    Log    @{split}[1]
    ${Output}=    Write Commands Until Prompt    kill -15 @{split}[0]
    ${Output}=    Write Commands Until Prompt    kill -15 @{split}[1]

Kill ovs-vswitchd in control node
    [Arguments]    ${OS_CONTROL_NODE_IP}
    [Documentation]    Kill ovs-vswitchd in control node
    ${output}=    Get ControlNode Connection by IP    ${OS_CONTROL_NODE_IP}
    Log    ${output}
    ${Output}=    Write Commands Until Prompt    ifconfig
    ${Output}=    Write Commands Until Prompt    ps -ef | grep ovs-vswitchd | awk '{print$2}'
    ${split}=    Split String    ${Output}    \n
    ${length}=    Get Length    ${split}
    Log    @{split}[0]
    Log    @{split}[1]
    ${Output}=    Write Commands Until Prompt    kill -15 @{split}[0]
    ${Output}=    Write Commands Until Prompt    kill -15 @{split}[1]

Kill ovsdb-server in control node
    [Arguments]    ${OS_CONTROL_NODE_IP}
    [Documentation]    Kill ovsdb-server in control node
    ${output}=    Get ControlNode Connection by IP    ${OS_CONTROL_NODE_IP}
    Log    ${output}
    ${Output}=    Write Commands Until Prompt    ifconfig
    ${Output}=    Write Commands Until Prompt    ps -ef | grep ovsdb-server | awk '{print$2}'
    ${split}=    Split String    ${Output}    \n
    ${length}=    Get Length    ${split}
    Log    @{split}[0]
    Log    @{split}[1]
    ${Output}=    Write Commands Until Prompt    kill -15 @{split}[0]
    ${Output}=    Write Commands Until Prompt    kill -15 @{split}[1]

Server Remove Floating ip
    [Arguments]    ${vm_name}    ${floating_ip}
    [Documentation]    Remove floating ip from server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove floating ip ${vm_name} ${floating_ip}
    Log    ${output}
    Should Not Be True    ${rc}

Floating ip Delete
    [Arguments]    ${floating_ip}
    [Documentation]    Delete floating ip's and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip delete ${floating_ip}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Router Unset
    [Arguments]    ${router_name}    ${cmd}
    [Documentation]    Update the router with the command. Router name and command should be passed as argument.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router unset ${router_name} ${cmd}
    Should Not Be True    ${rc}

Test Netcat Operations Internal to external
    [Arguments]    ${pnf_prompt}    ${vm_src}    ${net_dest}    ${dest_ip}    ${port}=1234    ${nc_should_succeed}=True
    ...    ${additional_args}=${EMPTY}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections between Vm instances
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    #Copy To VM Instance    ${net_dest}    ${dest_ip}
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    Run    sudo python /tmp/udp_server.py ${vm_src} ${port} > /tmp/data_dump.txt &
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    ${nc_l_output}=    Run    cat /tmp/data_dump.txt
    Should Match Regexp    ${nc_l_output}    ${client_data}
    ${rc}    ${output}=    Run And Return Rc And Output    rm -rf /tmp/data_dump.txt

Test Netcat Operations Internal to external TCP
    [Arguments]    ${pnf_prompt}    ${vm_src}    ${net_dest}    ${dest_ip}    ${port}=1234    ${nc_should_succeed}=True
    ...    ${additional_args}=${EMPTY}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections between Vm instances
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    #Copy To VM Instance    ${net_dest}    ${dest_ip}
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    Run    sudo python /tmp/tcp_server.py ${vm_src} ${port} > /tmp/data_dump.txt &
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    ${nc_l_output}=    Run    cat /tmp/data_dump.txt
    Should Match Regexp    ${nc_l_output}    ${client_data}
    ${rc}    ${output}=    Run And Return Rc And Output    rm -rf /tmp/data_dump.txt

Test Netcat Operations Internal to external VLAN
    [Arguments]    ${pnf_prompt}    ${vm_src}    ${net_dest}    ${dest_ip}    ${port}=1234    ${nc_should_succeed}=True
    ...    ${additional_args}=${EMPTY}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections between Vm instances
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    #Copy To VM Instance    ${net_dest}    ${dest_ip}
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    Run    sudo ip netns exec vlantest python /tmp/udp_server.py ${vm_src} ${port} > /tmp/data_dump.txt &
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    ${nc_l_output}=    Run    cat /tmp/data_dump.txt
    Should Match Regexp    ${nc_l_output}    ${client_data}
    ${rc}    ${output}=    Run And Return Rc And Output    rm -rf /tmp/data_dump.txt

Test Netcat Operations Internal to external TCP VLAN
    [Arguments]    ${pnf_prompt}    ${vm_src}    ${net_dest}    ${dest_ip}    ${port}=1234    ${nc_should_succeed}=True
    ...    ${additional_args}=${EMPTY}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections between Vm instances
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    #Copy To VM Instance    ${net_dest}    ${dest_ip}
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    Run    sudo ip netns exec vlantest python /tmp/tcp_server.py ${vm_src} ${port} > /tmp/data_dump.txt &
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    ${nc_l_output}=    Run    cat /tmp/data_dump.txt
    Should Match Regexp    ${nc_l_output}    ${client_data}
    ${rc}    ${output}=    Run And Return Rc And Output    rm -rf /tmp/data_dump.txt

Floating ip List
    [Documentation]    List floating ip's and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip list
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

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

Associate Floating ip to VM
    [Arguments]    ${vm_name}    ${ip}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add floating ip ${vm_name} ${ip}
    Log    ${output}
    Should Not Be True    ${rc}

Server Show
    [Arguments]    ${vm_name}
    [Documentation]    Show server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show ${vm_name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Test Netcat Operations To Vm Instance
    [Arguments]    ${net_name}    ${vm_ip}    ${dest_ip}    ${additional_args}=${EMPTY}    ${port}=12345    ${nc_should_succeed}=True
    ...    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections to the controller
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${vm_ip}
    ${output}=    Execute Command on VM Instance    ${net_name}    ${vm_ip}    ( ( echo "${server_data}" | sudo nc -l ${additional_args} ${port} ) & )
    Log    ${output}
    ${output}=    Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo route -n
    Log    ${output}
    ${output}=    Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo arp -an
    ${rc}    ${nc_output}=    Run And Return Rc And Output    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${dest_ip} ${port}
    Log    ${nc_output}
    ${rc}    ${output}    Run And Return Rc And Output    sudo netstat -nlap | grep ${port}
    Log    ${output}
    Run Keyword If    "${nc_should_succeed}" == "True"    Should Match Regexp    ${nc_output}    ${server_data}
    ...    ELSE    Should Not Match Regexp    ${nc_output}    ${server_data}

Create Vm Instances DefaultSG
    [Arguments]    ${net_name}    ${vm_instance_names}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${min}=1    ${max}=1
    ...    ${additional_args}=${EMPTY}
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id}=    Get Net Id    ${net_name}
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image ${image} --flavor ${flavor} --nic net-id=${net_id} ${VmElement} --min ${min} --max ${max} ${additional_args}
    \    Should Not Be True    ${rc}
    \    Log    ${output}

TCP connection refused
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    TCP communication check fail.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${src_ip}
    ${net_id}=    Get Net Id    ${net_name}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    Connection refused

Test Netcat Operations Between IPV6_Vm Instance
    [Arguments]    ${net_src}    ${vm_src}    ${net_dest}    ${dest_ip}    ${port}=1234    ${nc_should_succeed}=True
    ...    ${additional_args}=${EMPTY}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections between Vm instances
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${vm_src} ${dest_ip}
    ${net_id}=    Get Net Id    ${net_src}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -6 -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${vm_src} -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}=    Write    ( ( echo "${server_data}" | sudo nc -l ${additional_args} -p ${port} ) & )
    Log    ${output}
    #${output}=    Write Commands Until Prompt    sudo netstat -nla | grep ${port}
    #Log    ${output}
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    ${output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo route -n
    Log    ${output}
    ${output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo arp -an
    Log    ${output}
    Run Keyword If    "${nc_should_succeed}" == "True"    Should Match Regexp    ${nc_output}    ${server_data}
    ...    ELSE    Should Not Match Regexp    ${nc_output}    ${server_data

Test Operations From IPV6_Vm Instance
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)    ${ttl}=64
    ...    ${ping_should_succeed}=True    ${check_metadata}=True
    [Documentation]    Login to the vm instance using ssh in the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${src_ip}
    ${net_id}=    Get Net Id    ${net_name}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -6 -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route -n    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route -A inet6    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ip -6 neigh    ${OS_SYSTEM_PROMPT}
    : FOR    ${dest_ip}    IN    @{dest_ips}
    \    Log    ${dest_ip}
    \    ${string_empty}=    Run Keyword And Return Status    Should Be Empty    ${dest_ip}
    \    Run Keyword If    ${string_empty}    Continue For Loop
    \    Run Keyword If    ${rcode} and "${ping_should_succeed}" == "True"    Check Ping    ${dest_ip}    ttl=${ttl}
    \    ...    ELSE    Check No Ping    ${dest_ip}    ttl=${ttl}
    ${ethertype}=    Get Regexp Matches    ${src_ip}    ${IP_REGEX}
    Run Keyword If    ${rcode} and "${check_metadata}" and ${ethertype} == "True"    Check Metadata Access
    [Teardown]    Exit From Vm Console

Collect IPV6
    [Arguments]    @{vm_list}
    : FOR    ${vm}    IN    @{vm_list}
    \    Log    ${vm}
    \    ${rc}    ${vm_ip_line}=    Run And Return Rc And Output    openstack server list | grep -i "${vm}" | awk {'print $8'} | cut -d'=' -f2
    \    Log    ${vm_ip_line}
    [Return]    ${vm_ip_line}

Collect Fedora_IPV6
    [Arguments]    @{vm_list}
    : FOR    ${vm}    IN    @{vm_list}
    \    Log    ${vm}
    \    ${rc}    ${vm_ip_line}=    Run And Return Rc And Output    openstack server list | grep -i "${vm}" | awk {'print $9'} | cut -d'=' -f2
    \    Log    ${vm_ip_line}
    [Return]    ${vm_ip_line}

Create Fedora VM for dhcpv6-stateful
    [Arguments]    ${net1_name}    ${net2_name}    ${vm_instance_names}    ${image}    ${flavor}    ${sg}
    [Documentation]    To create a Fedora Vm in dhcpv6-stateful mode using two nic cards
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image ${image} --flavor ${flavor} --nic net-id=${net1_name} --nic net-id=${net2_name} --security-group ${sg} --key-name vm_keys ${vm_instance_names}
    Sleep    40s
    ${vm_instance_name}=    Create List    ${vm_instance_names}
    : FOR    ${vm}    IN    @{vm_instance_name}
    \    Poll VM Is ACTIVE    ${vm}
    ${NET1_VM_IPS}    Collect IP    @{vm_instance_name}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    : FOR    ${vm}    IN    @{vm_instance_name}
    \    Poll VM UP Boot Status    ${vm}
    ${devstack_conn_id}=    Get ControlNode Connection
    ${net_id}=    Get Net Id    ${net1_name}
    Log    ${net_id}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no fedora@@{NET1_VM_IPS}[0] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${MAC_Line}=    Write Commands Until Expected Prompt    ip link show eth1 | awk '/ether/ {print $2}'    $
    ${MAC}    Split String    ${MAC_Line}    \n
    Log    @{MAC}[0]
    ${output}=    Write Commands Until Expected Prompt    sudo cat <<EOF >ifcfg-eth1    >
    ${output}=    Write Commands Until Expected Prompt    BOOTPROTO=dhcpv6    >
    ${output}=    Write Commands Until Expected Prompt    DEVICE=eth1    >
    ${output}=    Write Commands Until Expected Prompt    ONBOOT=yes    >
    ${output}=    Write Commands Until Expected Prompt    TYPE=Ethernet    >
    ${output}=    Write Commands Until Expected Prompt    USERCTL=no    >
    ${output}=    Write Commands Until Expected Prompt    DHCPV6C=yes    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${output}=    Write Commands Until Expected Prompt    sudo cp ifcfg-eth1 /etc/sysconfig/network-scripts/.    $
    ${output}=    Write Commands Until Expected Prompt    sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo ifup eth1    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ping6 2004:db9:cafe:e::2    $
    Log    ${output}
    Should Contain    ${output}    64 bytes
    Write    exit

Test Operations From Fedora IPV6_Vm Instance
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=fedora    ${ttl}=64    ${ping_should_succeed}=True
    ...    ${check_metadata}=True
    [Documentation]    Login to the vm instance using ssh in the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${src_ip}
    ${net_id}=    Get Net Id    ${net_name}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -6 i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route -n    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route -A inet6    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ip -6 neigh    ${OS_SYSTEM_PROMPT}
    : FOR    ${dest_ip}    IN    @{dest_ips}
    \    Log    ${dest_ip}
    \    ${string_empty}=    Run Keyword And Return Status    Should Be Empty    ${dest_ip}
    \    Run Keyword If    ${string_empty}    Continue For Loop
    \    Run Keyword If    ${rcode} and "${ping_should_succeed}" == "True"    Check Ping    ${dest_ip}    ttl=${ttl}
    \    ...    ELSE    Check No Ping    ${dest_ip}    ttl=${ttl}
    ${ethertype}=    Get Regexp Matches    ${src_ip}    ${IP_REGEX}
    Run Keyword If    ${rcode} and "${check_metadata}" and ${ethertype} == "True"    Check Metadata Access
    [Teardown]    Exit From Vm Console

Test Netcat Operations Between Fedora_IPV6_Vm Instance
    [Arguments]    ${net_src}    ${vm_src}    ${net_dest}    ${dest_ip}    ${port}=1234    ${nc_should_succeed}=True
    ...    ${additional_args}=${EMPTY}    ${user}=fedora    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections between Vm instances
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    ${vm_src} ${dest_ip}
    ${net_id}=    Get Net Id    ${net_src}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -6 i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${vm_src} -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}=    Write    ( ( echo "${server_data}" | sudo nc -l ${additional_args} -p ${port} ) & )
    Log    ${output}
    #${output}=    Write Commands Until Prompt    sudo netstat -nla | grep ${port}
    #Log    ${output}
    ${nc_output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${vm_src} ${port}
    Log    ${nc_output}
    ${output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo route -n
    Log    ${output}
    ${output}=    Execute Command on VM Instance    ${net_dest}    ${dest_ip}    sudo arp -an
    Log    ${output}
    Run Keyword If    "${nc_should_succeed}" == "True"    Should Match Regexp    ${nc_output}    ${server_data}
    ...    ELSE    Should Not Match Regexp    ${nc_output}    ${server_data}

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
    [Documentation]    Disables Live Migration in all computes
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

Server Migrate
    [Arguments]    ${vm_instance_name}    ${additional_args}=${EMPTY}
    [Documentation]    server migrate
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server migrate ${vm_instance_name} ${additional_args}
    Should Not Be True    ${rc}
    Log    ${output}

Create Vm Instances V4Fixed-IP
    [Arguments]    ${net_name}    ${vm}    ${fixed}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    ...    ${min}=1    ${max}=1
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id}=    Get Net Id    ${net_name}
    : FOR    ${VmElement}    IN    @{vm}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack server create --image ${image} --flavor ${flavor} --nic net-id=${net_id}${fixed} ${VmElement} --security-group ${sg} --min ${min} --max ${max}
    \    Should Not Be True    ${rc}
    \    Log    ${output}

Server Remove Fixed ip
    [Arguments]    ${fixed_ip}    ${vm_name}    ${network_name}
    [Documentation]    Remove fixed ip to server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove fixed ip ${vm_name} ${fixed_ip}
    Log    ${output}
    Should Not Be True    ${rc}

Server Remove Port
    [Arguments]    ${vm}    ${port}
    [Documentation]    Remove the port to the given VM.
    ${output}=    Run And Return Rc And Output    openstack server remove port ${vm} ${port}
    Log    ${output}

Unset SubNet
    [Arguments]    ${subnet_name}    ${additional_args}=${EMPTY}
    [Documentation]    Unset subnet with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet unset ${subnet_name} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Unset Port
    [Arguments]    ${port_name}    ${additional_args}=${EMPTY}
    [Documentation]    Unset port with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port unset ${port_name} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}

Crudini Edit
    [Arguments]    ${os_node_cxn}    ${conf_file}    ${section}    ${key}    ${value}
    [Documentation]    Crudini edit on a configuration file
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo crudini --verbose --set --inplace ${conf_file} ${section} ${key} ${value}    return_rc=True    return_stdout=True
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

SubNet Set
    [Arguments]    ${subnet}    ${additional_args}
    [Documentation]    unset SubNet for the Network with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet set ${additional_args} ${subnet}
    Log    ${output}
    Should Not Be True    ${rc}

Server Add Port
    [Arguments]    ${vm}    ${port}
    [Documentation]    Remove the port to the given VM.
    ${output}=    Run And Return Rc And Output    openstack server add port ${vm} ${port}
    Log    ${output}

Get DumpFlows
    [Arguments]    ${openstack_node_ip}
    SSHLibrary.Open Connection    ${openstack_node_ip}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}    90s
    Close Connection
    [Return]    ${output}

Server Add Fixed ip
    [Arguments]    ${fixed_ip}    ${vm_name}    ${network_name}
    [Documentation]    Add fixed ip to server with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server add fixed ip --fixed-ip-address ${fixed_ip} ${vm_name} ${network_name}
    Log    ${output}
    Should Not Be True    ${rc}
