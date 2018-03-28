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
