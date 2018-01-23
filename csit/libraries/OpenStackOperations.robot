*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          DataModels.robot
Resource          DevstackUtils.robot
Resource          L2GatewayOperations.robot
Resource          OVSDB.robot
Resource          SetupUtils.robot
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot
Variables         ../variables/netvirt/Modules.py

*** Keywords ***
Get Tenant ID From Security Group
    [Documentation]    Returns tenant ID by reading it from existing default security-group.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group show default | grep "| tenant_id" | awk '{print $4}'
    Should Be True    '${rc}' == '0'
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
    ${rc}    ${output}=    Run And Return Rc And Output    openstack network create ${network_name} ${additional_args}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Update Network
    [Arguments]    ${network_name}    ${additional_args}=${EMPTY}
    [Documentation]    Update Network with neutron request.
    ${cmd}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    neutron -v net-update ${network_name} ${additional_args}    openstack network set ${network_name} ${additional_args}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Show Network
    [Arguments]    ${network_name}
    [Documentation]    Show Network with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack network show ${network_name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

List Networks
    [Documentation]    List networks and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack network list
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

List Subnets
    [Documentation]    List subnets and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet list
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Delete Network
    [Arguments]    ${network_name}
    [Documentation]    Delete Network with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack network delete ${network_name}
    Log    ${output}
    Should Be True    '${rc}' == '0'

Create SubNet
    [Arguments]    ${network_name}    ${subnet}    ${range_ip}    ${additional_args}=${EMPTY}
    [Documentation]    Create SubNet for the Network with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet create --network ${network_name} --subnet-range ${range_ip} ${subnet} ${additional_args}
    Log    ${output}
    Should Be True    '${rc}' == '0'

Update SubNet
    [Arguments]    ${subnet_name}    ${additional_args}=${EMPTY}
    [Documentation]    Update subnet with neutron request.
    ${cmd}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    neutron -v subnet-update ${subnet_name} ${additional_args}    openstack subnet set ${subnet_name} ${additional_args}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Show SubNet
    [Arguments]    ${subnet_name}
    [Documentation]    Show subnet with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet show ${subnet_name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Create Port
    [Arguments]    ${network_name}    ${port_name}    ${sg}=default    ${additional_args}=${EMPTY}    ${allowed_address_pairs}=${EMPTY}
    [Documentation]    Create Port with neutron request.
    # if allowed_address_pairs is not empty we need to create the arguments to pass to the port create command. They are
    # in a different format with the neutron vs openstack cli.
    ${address_pair_length}=    Get Length    ${allowed_address_pairs}
    ${allowed_pairs_argv}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton' and '${address_pair_length}'=='2'    --allowed-address-pairs type=dict list=true ip_address=@{allowed_address_pairs}[0] ip_address=@{allowed_address_pairs}[1]
    ${allowed_pairs_argv}=    Set Variable If    '${OPENSTACK_BRANCH}'!='stable/newton' and '${address_pair_length}'=='2'    --allowed-address ip-address=@{allowed_address_pairs}[0] --allowed-address ip-address=@{allowed_address_pairs}[1]    ${allowed_pairs_argv}
    ${allowed_pairs_argv}=    Set Variable If    '${address_pair_length}'=='0'    ${EMPTY}    ${allowed_pairs_argv}
    ${cmd}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    neutron -v port-create ${network_name} --name ${port_name} --security-group ${sg} ${additional_args} ${allowed_pairs_argv}    openstack port create --network ${network_name} ${port_name} --security-group ${sg} ${additional_args} ${allowed_pairs_argv}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    Log    ${output}
    Should Be True    '${rc}' == '0'

Update Port
    [Arguments]    ${port_name}    ${additional_args}=${EMPTY}
    [Documentation]    Update port with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port set ${port_name} ${additional_args}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Show Port
    [Arguments]    ${port_name}
    [Documentation]    Show port with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port show ${port_name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Delete Port
    [Arguments]    ${port_name}
    [Documentation]    Delete Port with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port delete ${port_name}
    Log    ${output}
    Should Be True    '${rc}' == '0'

List Ports
    [Documentation]    List ports and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port list
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

List Nova VMs
    [Documentation]    List VMs and return output with nova client.
    ${output}=    OpenStack CLI    openstack server list --all-projects
    [Return]    ${output}

Create And Associate Floating IPs
    [Arguments]    ${external_net}    @{vm_list}
    [Documentation]    Create and associate floating IPs to VMs with nova request
    ${ip_list}=    Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip create ${external_net}
    \    Log    ${output}
    \    Should Be True    '${rc}' == '0'
    \    @{ip}    Get Regexp Matches    ${output}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${ip_length}    Get Length    ${ip}
    \    Run Keyword If    ${ip_length}>0    Append To List    ${ip_list}    @{ip}[0]
    \    ...    ELSE    Append To List    ${ip_list}    None
    \    OpenStack CLI    openstack server add floating ip ${vm} @{ip}[0]
    [Return]    ${ip_list}

Delete Floating IP
    [Arguments]    ${fip}
    [Documentation]    Delete floating ip with neutron request.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip delete ${fip}
    Log    ${output}
    Should Be True    '${rc}' == '0'

Verify Gateway Ips
    [Documentation]    Verifies the Gateway Ips with dump flow.
    ${output}=    Write Commands Until Prompt And Log    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    : FOR    ${GatewayIpElement}    IN    @{GATEWAY_IPS}
    \    Should Contain    ${output}    ${GatewayIpElement}

Verify Dhcp Ips
    [Documentation]    Verifies the Dhcp Ips with dump flow.
    ${output}=    Write Commands Until Prompt And Log    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    : FOR    ${DhcpIpElement}    IN    @{DHCP_IPS}
    \    Should Contain    ${output}    ${DhcpIpElement}

Verify No Dhcp Ips
    [Documentation]    Verifies the Dhcp Ips with dump flow.
    ${output}=    Write Commands Until Prompt And Log    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    : FOR    ${DhcpIpElement}    IN    @{DHCP_IPS}
    \    Should Not Contain    ${output}    ${DhcpIpElement}

Delete SubNet
    [Arguments]    ${subnet}
    [Documentation]    Delete SubNet for the Network with neutron request.
    Log    ${subnet}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet delete ${subnet}
    Should Be True    '${rc}' == '0'

Verify No Gateway Ips
    [Documentation]    Verifies the Gateway Ips removed with dump flow.
    ${output}=    Write Commands Until Prompt And Log    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    : FOR    ${GatewayIpElement}    IN    @{GATEWAY_IPS}
    \    Should Not Contain    ${output}    ${GatewayIpElement}

Delete Vm Instance
    [Arguments]    ${vm_name}
    [Documentation]    Delete Vm instances using instance names.
    OpenStack CLI    openstack server delete ${vm_name}

Get Net Id
    [Arguments]    ${network_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    ${rc}    ${output}=    Run And Return Rc And Output    openstack network list | grep "${network_name}" | awk '{print $2}'
    Should Be True    '${rc}' == '0'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${net_id}=    Get from List    ${splitted_output}    0
    [Return]    ${net_id}

Get Subnet Id
    [Arguments]    ${subnet_name}
    [Documentation]    Retrieve the subnet id for the given subnet name
    ${rc}    ${output}=    Run And Return Rc And Output    openstack subnet show "${subnet_name}" | grep " id " | awk '{print $4}'
    Should Be True    '${rc}' == '0'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${subnet_id}=    Get from List    ${splitted_output}    0
    [Return]    ${subnet_id}

Get Port Id
    [Arguments]    ${port_name}
    [Documentation]    Retrieve the port id for the given port name to attach specific vm instance to a particular port
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port list | grep "${port_name}" | awk '{print $2}'
    Should Be True    '${rc}' == '0'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${port_id}=    Get from List    ${splitted_output}    0
    [Return]    ${port_id}

Get Router Id
    [Arguments]    ${router1}
    [Documentation]    Retrieve the router id for the given router name
    ${rc}    ${output}=    Run And Return Rc And Output    openstack router list -f table | grep "${router1}" | awk '{print $2}'
    Should Be True    '${rc}' == '0'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${router_id}=    Get from List    ${splitted_output}    0
    [Return]    ${router_id}

Create Vm Instances
    [Arguments]    ${net_name}    ${vm_instance_names}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default    ${min}=1
    ...    ${max}=1
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id}=    Get Net Id    ${net_name}
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --nic net-id=${net_id} ${VmElement} --security-group ${sg} --min ${min} --max ${max}

Create Vm Instance On Compute Node
    [Arguments]    ${net_name}    ${vm_name}    ${node_hostname}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create a VM instance on a specific compute node.
    ${image} =    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id} =    Get Net Id    ${net_name}
    OpenStack CLI    openstack server create ${vm_name} --image ${image} --flavor ${flavor} --nic net-id=${net_id} --security-group ${sg} --availability-zone nova:${node_hostname}

Create Vm Instance With Port
    [Arguments]    ${port_name}    ${vm_instance_name}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${port_id}=    Get Port Id    ${port_name}
    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --nic port-id=${port_id} ${vm_instance_name} --security-group ${sg}

Create Vm Instance With Ports
    [Arguments]    ${port_name}    ${port2_name}    ${vm_instance_name}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${port_id}=    Get Port Id    ${port_name}
    ${port2_id}=    Get Port Id    ${port2_name}
    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --nic port-id=${port_id} --nic port-id=${port2_id} ${vm_instance_name} --security-group ${sg}

Create Vm Instance With Port On Compute Node
    [Arguments]    ${port_name}    ${vm_instance_name}    ${node_hostname}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    ${image}    Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${port_id}=    Get Port Id    ${port_name}
    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --nic port-id=${port_id} --security-group ${sg} --availability-zone nova:${node_hostname} ${vm_instance_name}

Get Hypervisor Hostname From IP
    [Arguments]    ${hypervisor_ip}
    [Documentation]    Returns the hostname found for the given IP address if it's listed in hypervisor list. For debuggability
    ...    the full listing is logged first, then followed by a grep | cut to focus on the actual hostname to return
    ${rc}    ${output}    Run And Return Rc And Output    openstack hypervisor list
    Log    ${output}
    ${rc}    ${hostname}=    Run And Return Rc And Output    openstack hypervisor list -f value | grep "${hypervisor_ip} " | cut -d" " -f 2
    Log    ${hostname}
    Should Be True    '${rc}' == '0'
    [Return]    ${hostname}

Create Nano Flavor
    [Documentation]    Create a nano flavor
    ${rc}    ${output}=    Run And Return Rc And Output    openstack flavor create m1.nano --id auto --ram 64 --disk 0 --vcpus 1
    Log    ${output}
    Should Be True    '${rc}' == '0'

Verify VM Is ACTIVE
    [Arguments]    ${vm_name}
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    ${output}=    OpenStack CLI    openstack server show ${vm_name} | grep OS-EXT-STS:vm_state
    Should Contain    ${output}    active

Poll VM Is ACTIVE
    [Arguments]    ${vm_name}    ${retry}=600s    ${retry_interval}=30s
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    Wait Until Keyword Succeeds    ${retry}    ${retry_interval}    Verify VM Is ACTIVE    ${vm_name}

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
    Should Be True    ${dhcp_length} <= 1
    Return From Keyword If    ${dhcp_length}==0    ${ip_list}    ${EMPTY}
    [Return]    ${ip_list}    ${dhcp_ip}

Get Match
    [Arguments]    ${text}    ${regexp}    ${index}=0
    [Documentation]    Wrapper around Get Regexp Matches to return None if not found or the first match if found.
    @{matches} =    String.Get Regexp Matches    ${text}    ${regexp}
    ${matches_length} =    Get Length    ${matches}
    BuiltIn.Set Suite Variable    ${OS_MATCH}    None
    BuiltIn.Run Keyword If    ${matches_length} > ${index}    BuiltIn.Set Suite Variable    ${OS_MATCH}    @{matches}[${index}]
    [Return]    ${OS_MATCH}

Get VM IP
    [Arguments]    ${fail_on_none}    ${vm}
    [Documentation]    Get the vm ip address and nameserver by scraping the vm's console log.
    ...    Get VM IP returns three values: [0] the vm IP, [1] the DHCP IP and [2] the vm console log.
    ${rc}    ${vm_console_output}=    Run And Return Rc And Output    openstack console log show ${vm}
    ${vm_ip} =    Set Variable    None
    ${dhcp_ip} =    Set Variable    None
    ${match} =    Get Match    ${vm_console_output}    ${REGEX_OBTAINED}
    ${vm_ip} =    Get Match    ${match}    ${REGEX_IPV4}    0
    ${match} =    Get Match    ${vm_console_output}    ${REGEX_IPROUTE}
    ${dhcp_ip} =    Get Match    ${match}    ${REGEX_IPV4}    1
    BuiltIn.Run Keyword If    '${fail_on_none}' == 'true'    Should Not Contain    ${vm_ip}    None
    BuiltIn.Run Keyword If    '${fail_on_none}' == 'true'    Should Not Contain    ${dhcp_ip}    None
    [Return]    ${vm_ip}    ${dhcp_ip}    ${vm_console_output}

Get VM IPs
    [Arguments]    @{vms}
    [Documentation]    Get the instance IP addresses and nameserver address for the list of given vms.
    ...    First poll for the vm instance to be in the active state, then poll for the vm ip address and nameserver.
    ...    Get VM IPs returns two things: [0] a list of the ips for the vms passed to this keyword (may contain values
    ...    of None) and [1] the dhcp ip address found in the last vm checked.
    ...    TODO: there is a potential issue for a caller that passes in VMs belonging to different networks that
    ...    may have different dhcp server addresses. Not sure what TODO about that, but noting it here for reference.
    @{vm_ips}    BuiltIn.Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vms}
    \    Poll VM Is ACTIVE    ${vm}
    \    ${status}    ${ips_and_console_log}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    15s
    \    ...    Get VM IP    true    ${vm}
    \    # If there is trouble with Get VM IP, the status will be FAIL and the return value will be a string of what went
    \    # wrong. We need to handle both the PASS and FAIL cases. In the FAIL case we know we wont have access to the
    \    # console log, as it would not be returned; so we need to grab it again to log it. We also can append 'None' to
    \    # the vm ip list if status is FAIL.
    \    Run Keyword If    "${status}" == "PASS"    BuiltIn.Log    ${ips_and_console_log[2]}
    \    BuiltIn.Run Keyword If    "${status}" == "PASS"    Collections.Append To List    ${vm_ips}    ${ips_and_console_log[0]}
    \    BuiltIn.Run Keyword If    "${status}" == "FAIL"    Collections.Append To List    ${vm_ips}    None
    \    ${rc}    ${vm_console_output}=    BuiltIn.Run Keyword If    "${status}" == "FAIL"    Run And Return Rc And Output    openstack console log show ${vm}
    \    BuiltIn.Run Keyword If    "${status}" == "FAIL"    BuiltIn.Log    ${vm_console_output}
    Copy DHCP Files From Control Node
    [Return]    @{vm_ips}    ${ips_and_console_log[1]}

Collect VM IPv6 SLAAC Addresses
    [Arguments]    ${fail_on_none}    ${vm_list}    ${network}    ${subnet}
    [Documentation]    For each VM parse output of "openstack server show" to get its IPv6 address from Neutron DB.
    ...    Then try to connect to each VM by SSH and execute there "ip -6 a" command. This double-check allows to
    ...    obtain and compare IP info (Neutron DB vs dnsmasque/ODL DHCP) and to test L2 connectivity as well.
    ...    Returns an empty list if no IPv6 addresses found or if SSH connection fails.
    ...    Otherwise, returns a list of IPv6 addresses.
    ${ipv6_list}    Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${output}=    OpenStack CLI    openstack server show ${vm} -f shell
    \    ${pattern}=    Replace String    ${subnet}    ::/64    (:[a-f0-9]{,4}){,4}
    \    @{vm_ipv6}=    Get Regexp Matches    ${output}    ${pattern}
    \    ${vm_ip_length}    Get Length    ${vm_ipv6}[0]
    \    ${ipv6_data_from_vm}=    Run Keyword If    ${vm_ip_length}>0    Execute Command on VM Instance    ${network}    ${vm_ipv6[0]}
    \    ...    ip -6 a
    \    @{ipv6}=    Get Regexp Matches    ${ipv6_data_from_vm}    ${pattern}
    \    ${ipv6_addr_list_length}    Get Length    @{ipv6}
    \    Run Keyword If    ${ipv6_addr_list_length}>0    Append To List    ${ipv6_list}    ${ipv6[0]}
    \    ...    ELSE    Append To List    ${ipv6_list}    None
    [Return]    ${ipv6_list}

View Vm Console
    [Arguments]    ${vm_instance_names}
    [Documentation]    View Console log of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    OpenStack CLI    openstack server show ${VmElement}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack console log show ${VmElement}
    \    Log    ${output}
    \    Should Be True    '${rc}' == '0'

Ping Vm From DHCP Namespace
    [Arguments]    ${net_name}    ${vm_ip}
    [Documentation]    Reach all Vm Instance with the net id of the Netowrk.
    Get ControlNode Connection
    ${net_id}=    Get Net Id    ${net_name}
    ${output}=    Write Commands Until Prompt And Log    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}    20s
    Should Contain    ${output}    64 bytes

Ping From DHCP Should Not Succeed
    [Arguments]    ${net_name}    ${vm_ip}
    [Documentation]    Should Not Reach Vm Instance with the net id of the Netowrk.
    Return From Keyword If    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}
    Get ControlNode Connection
    ${net_id}=    Get Net Id    ${net_name}
    ${output}=    Write Commands Until Prompt And Log    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}    20s
    Should Not Contain    ${output}    64 bytes

Ping Vm From Control Node
    [Arguments]    ${vm_floating_ip}    ${additional_args}=${EMPTY}
    [Documentation]    Ping VM floating IP from control node
    Get ControlNode Connection
    ${output}=    Write Commands Until Prompt And Log    ping ${additional_args} -c 3 ${vm_floating_ip}    20s
    Should Contain    ${output}    64 bytes

Curl Metadata Server
    [Documentation]    Ping to the expected destination ip.
    ${output}=    Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    Write Commands Until Prompt    exit
    Should Contain    ${output}    200

Close Vm Instance
    [Documentation]    Exit the vm instance.
    ${output}=    Write Commands Until Prompt And Log    exit

Check If Console Is VmInstance
    [Arguments]    ${console}=cirros
    [Documentation]    Check if the session has been able to login to the VM instance
    ${output}=    Write Commands Until Expected Prompt    id    ${OS_SYSTEM_PROMPT}
    Should Contain    ${output}    ${console}

Exit From Vm Console
    [Documentation]    Check if the session has been able to login to the VM instance and exit the instance
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance    cirros
    Run Keyword If    ${rcode}    Write Commands Until Prompt    exit

Check Ping
    [Arguments]    ${ip_address}    ${ttl}=64
    [Documentation]    Run Ping command on the IP available as argument
    ${ethertype}=    Get Regexp Matches    ${ip_address}    ${IP_REGEX}
    ${output}=    Run Keyword If    ${ethertype}    Write Commands Until Expected Prompt    ping -t ${ttl} -c 3 ${ip_address}    ${OS_SYSTEM_PROMPT}
    ...    ELSE    Write Commands Until Expected Prompt    ping6 -t ${ttl} -c 3 ${ip_address}    ${OS_SYSTEM_PROMPT}
    Should Contain    ${output}    64 bytes

Check No Ping
    [Arguments]    ${ip_address}    ${ttl}=64
    [Documentation]    Run Ping command to the IP given as argument, executing 3 times and expecting NOT to see "64 bytes"
    ${output}=    Write Commands Until Expected Prompt    ping -t ${ttl} -c 3 ${ip_address}    ${OS_SYSTEM_PROMPT}
    Should Not Contain    ${output}    64 bytes

Check Metadata Access
    [Documentation]    Try curl on the Metadataurl and check if it is okay
    ${output}=    Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    Should Contain    ${output}    200

Execute Command on VM Instance
    [Arguments]    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network, executes a command inside the VM and returns the ouput.
    Get ControlNode Connection
    ${net_id} =    Get Net Id    ${net_name}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    ${rcode} =    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output} =    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}
    [Teardown]    Exit From Vm Console
    [Return]    ${output}

Test Operations From Vm Instance
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)    ${ttl}=64
    ...    ${ping_should_succeed}=True    ${check_metadata}=True
    [Documentation]    Login to the vm instance using ssh in the network.
    Get ControlNode Connection
    ${net_id}=    Get Net Id    ${net_name}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    password:
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route -n    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route -A inet6    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ip -f inet6 neigh show    ${OS_SYSTEM_PROMPT}
    : FOR    ${dest_ip}    IN    @{dest_ips}
    \    ${string_empty}=    Run Keyword And Return Status    Should Be Empty    ${dest_ip}
    \    Run Keyword If    ${string_empty}    Continue For Loop
    \    Run Keyword If    ${rcode} and "${ping_should_succeed}" == "True"    Check Ping    ${dest_ip}    ttl=${ttl}
    \    ...    ELSE    Check No Ping    ${dest_ip}    ttl=${ttl}
    ${ethertype}=    Get Regexp Matches    ${src_ip}    ${IP_REGEX}
    Run Keyword If    ${rcode} and "${check_metadata}" and ${ethertype} == "True"    Check Metadata Access
    [Teardown]    Exit From Vm Console

Test Netcat Operations From Vm Instance
    [Arguments]    ${net_name}    ${vm_ip}    ${dest_ip}    ${additional_args}=${EMPTY}    ${port}=12345    ${user}=cirros
    ...    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections to the controller
    ${client_data}    Set Variable    Test Client Data
    ${server_data}    Set Variable    Test Server Data
    Get ControlNode Connection
    ${output}=    Write Commands Until Prompt And Log    ( ( echo "${server_data}" | sudo timeout 60 nc -l ${additional_args} ${port} ) & )
    ${output}=    Write Commands Until Prompt And Log    sudo netstat -nlap | grep ${port}
    ${nc_output}=    Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${dest_ip} ${port}
    ${output}=    Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo route -n
    Log    ${output}
    ${output}=    Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo arp -an
    Log    ${output}
    Should Match Regexp    ${nc_output}    ${server_data}

Ping Other Instances
    [Arguments]    ${list_of_external_dst_ips}
    [Documentation]    Check reachability with other network's instances.
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    : FOR    ${dest_ip}    IN    @{list_of_external_dst_ips}
    \    Check Ping    ${dest_ip}

Create Router
    [Arguments]    ${router_name}
    [Documentation]    Create Router and Add Interface to the subnets.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack router create ${router_name}
    Should Be True    '${rc}' == '0'

List Routers
    [Documentation]    List Routers and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack router list -f value
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Add Router Interface
    [Arguments]    ${router_name}    ${interface_name}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack router add subnet ${router_name} ${interface_name}
    Should Be True    '${rc}' == '0'

Show Router Interface
    [Arguments]    ${router_name}
    [Documentation]    List Routers interface associated with given Router and return output with neutron client.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port list --router ${router_name} -f value
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Add Router Gateway
    [Arguments]    ${router_name}    ${external_network_name}
    ${cmd}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    neutron -v router-gateway-set ${router_name} ${external_network_name}    openstack router set ${router_name} --external-gateway ${external_network_name}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    Should Be True    '${rc}' == '0'

Remove Interface
    [Arguments]    ${router_name}    ${interface_name}
    [Documentation]    Remove Interface to the subnets.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack router remove subnet ${router_name} ${interface_name}
    Should Be True    '${rc}' == '0'

Remove Gateway
    [Arguments]    ${router_name}
    [Documentation]    Remove external gateway from the router.
    BuiltIn.Log    openstack router unset ${router_name} --external-gateway

Update Router
    [Arguments]    ${router_name}    ${cmd}
    [Documentation]    Update the router with the command. Router name and command should be passed as argument.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router set ${router_name} ${cmd}
    Should Be True    '${rc}' == '0'

Show Router
    [Arguments]    ${router_name}    ${options}
    [Documentation]    Show information of a given router. Router name and optional fields should be sent as arguments.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show ${router_name}
    Log    ${output}

Delete Router
    [Arguments]    ${router_name}
    [Documentation]    Delete Router and Interface to the subnets.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack router delete ${router_name}
    Log    ${output}
    Should Be True    '${rc}' == '0'

Get DumpFlows And Ovsconfig
    [Arguments]    ${conn_id}
    [Documentation]    Get the OvsConfig and Flow entries from OVS from the Openstack Node
    SSHLibrary.Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    ip -o link    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    ip -o addr    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    ip route    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    arp -an    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${nslist}=    Write Commands Until Expected Prompt    ip netns list | awk '{print $1}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{lines}    Split To Lines    ${nslist}    end=-1
    : FOR    ${line}    IN    @{lines}
    \    Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip -o link    ${DEFAULT_LINUX_PROMPT_STRICT}
    \    Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip -o addr    ${DEFAULT_LINUX_PROMPT_STRICT}
    \    Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip route    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-vsctl list Open_vSwitch    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-ofctl show br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-groups br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-group-stats br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}

Get Karaf Log Type From Test Start
    [Arguments]    ${ip}    ${test_name}    ${type}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    ${cmd}    Set Variable    sed '1,/ROBOT MESSAGE: Starting test ${test_name}/d' ${log_file} | grep '${type}'
    ${output}    Run Command On Controller    ${ip}    ${cmd}    ${user}    ${password}    ${prompt}
    [Return]    ${output}

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
    SSHLibrary.Switch Connection    ${OS_CNTL_CONN_ID}
    [Return]    ${OS_CNTL_CONN_ID}

Get OvsDebugInfo
    [Documentation]    Get the OvsConfig and Flow entries from all Openstack nodes
    Run Keyword If    0 < ${NUM_OS_SYSTEM}    Get DumpFlows And Ovsconfig    ${OS_CNTL_CONN_ID}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Get DumpFlows And Ovsconfig    ${OS_CMP2_CONN_ID}

Get Test Teardown Debugs
    [Arguments]    ${test_name}=${TEST_NAME}
    Get OvsDebugInfo
    Run Keyword And Ignore Error    Get Model Dump    ${HA_PROXY_IP}    ${netvirt_data_models}
    Get Karaf Log Events From Test Start    ${test_name}

Get Test Teardown Debugs For SFC
    [Arguments]    ${test_name}=${TEST_NAME}
    Run Keyword And Ignore Error    Get Model Dump    ${HA_PROXY_IP}    ${netvirt_sfc_data_models}

Show Debugs
    [Arguments]    @{vm_indices}
    [Documentation]    Run these commands for debugging, it can list state of VM instances and ip information in control node
    Get ControlNode Connection
    ${output}=    Write Commands Until Prompt And Log    sudo ip netns list
    : FOR    ${index}    IN    @{vm_indices}
    \    ${rc}    ${output}=    Run And Return Rc And Output    nova show ${index}
    \    Log    ${output}
    List Nova VMs
    List Routers
    List Networks
    List Subnets
    List Ports
    List Security Groups

List Security Groups
    [Documentation]    Logging keyword to display all security groups using the openstack cli. Assumes openstack
    ...    credentials are already sourced
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Neutron Security Group Show
    [Arguments]    ${SecurityGroupRuleName}
    [Documentation]    Displays the neutron security group configurations that belongs to a given neutron security group name
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group show ${SecurityGroupRuleName}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Neutron Port Show
    [Arguments]    ${PortName}
    [Documentation]    Display the port configuration that belong to a given neutron port
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port show ${PortName}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Neutron Security Group Create
    [Arguments]    ${SecurityGroupName}    ${additional_args}=${EMPTY}
    [Documentation]    Create a security group with specified name ,description & protocol value according to security group template
    Get ControlNode Connection
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group create ${SecurityGroupName} ${additional_args}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    ${sgp_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${sgp_id}
    [Return]    ${output}    ${sgp_id}

Neutron Security Group Update
    [Arguments]    ${SecurityGroupName}    ${additional_args}=${EMPTY}
    [Documentation]    Updating security groups
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group set ${SecurityGroupName} ${additional_args}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Delete SecurityGroup
    [Arguments]    ${sg_name}
    [Documentation]    Delete Security group
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group delete ${sg_name}
    Log    ${output}
    Should Be True    '${rc}' == '0'

Neutron Security Group Rule Create
    [Arguments]    ${Security_group_name}    &{Kwargs}
    [Documentation]    Creates neutron security rule with Openstack CLI with or without optional params, here security group name is mandatory args, rule with optional params can be created by passing the optional args values ex: direction=${INGRESS_EGRESS}, Then these optional params are catenated with mandatory args, example of usage: "Neutron Security Group Rule Create ${SGP_SSH} direction=${RULE_PARAMS[0]} ethertype=${RULE_PARAMS[1]} ..."
    Run Keyword If    ${Kwargs}    Log    ${Kwargs}
    ${description}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    description    default=${None}
    ${direction}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    direction    default=${None}
    ${ethertype}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    ethertype    default=${None}
    ${port_range_max}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    port_range_max    default=${None}
    ${port_range_min}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    port_range_min    default=${None}
    ${protocol}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    protocol    default=${None}
    ${remote_group_id}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    remote_group_id    default=${None}
    ${remote_ip_prefix}    Run Keyword If    ${Kwargs}    Pop From Dictionary    ${Kwargs}    remote_ip_prefix    default=${None}
    ${cmd}=    Set Variable    openstack security group rule create ${Security_group_name}
    ${cmd}=    Run Keyword If    '${description}'!='None'    Catenate    ${cmd}    --description ${description}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${direction}'!='None'    Catenate    ${cmd}    --${direction}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${ethertype}'!='None'    Catenate    ${cmd}    --ethertype ${ethertype}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${port_range_min}'!='None' and '${port_range_max}'!='None'    Catenate    ${cmd}    --dst-port ${port_range_min}:${port_range_max}
    ...    ELSE IF    '${port_range_max}'!='None'    Catenate    ${cmd}    --dst-port ${port_range_max}
    ...    ELSE IF    '${port_range_min}'!='None'    Catenate    ${cmd}    --dst-port ${port_range_min}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${protocol}'!='None'    Catenate    ${cmd}    --protocol ${protocol}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${remote_group_id}'!='None'    Catenate    ${cmd}    --remote-group ${remote_group_id}
    ...    ELSE    Catenate    ${cmd}
    ${cmd}=    Run Keyword If    '${remote_ip_prefix}'!='None'    Catenate    ${cmd}    --src-ip ${remote_ip_prefix}
    ...    ELSE    Catenate    ${cmd}
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}    ${rule_id}

Neutron Security Group Rule Create Legacy Cli
    [Arguments]    ${Security_group_name}    &{Kwargs}
    [Documentation]    Creates neutron security rule with neutron request with or without optional params, here security group name is mandatory args, rule with optional params can be created by passing the optional args values ex: direction=${INGRESS_EGRESS}, Then these optional params are catenated with mandatory args, example of usage: "Neutron Security Group Rule Create ${SGP_SSH} direction=${RULE_PARAMS[0]} ethertype=${RULE_PARAMS[1]} ..."
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
    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    ${rule_id}=    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${rule_id}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}    ${rule_id}

Security Group Create Without Default Security Rules
    [Arguments]    ${sg_name}    ${additional_args}=${EMPTY}
    [Documentation]    Create Neutron Security Group with no default rules, using specified name and optional arguments.
    Neutron Security Group Create    ${sg_name}    ${additional_args}
    Delete All Security Group Rules    ${sg_name}

Delete All Security Group Rules
    [Arguments]    ${sg_name}
    [Documentation]    Delete all security rules from a specified security group
    ${rc}    ${sg_rules_output}=    Run And Return Rc And Output    openstack security group rule list ${sg_name} -cID -fvalue
    Log    ${sg_rules_output}
    Should Be True    '${rc}' == '0'
    @{sg_rules}=    Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group rule delete ${rule}
    \    Log    ${output}
    \    Should Be True    '${rc}' == '0'

Create Allow All SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    protocol=icmp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    protocol=icmp
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=udp

Create Neutron Port With Additional Params
    [Arguments]    ${network_name}    ${port_name}    ${additional_args}=${EMPTY}
    [Documentation]    Create Port With given additional parameters
    ${rc}    ${output}=    Run And Return Rc And Output    neutron -v port-create ${network_name} --name ${port_name} ${additional_args}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    ${port_id}=    Should Match Regexp    ${OUTPUT}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${port_id}
    [Return]    ${OUTPUT}    ${port_id}

Get Ports MacAddr
    [Arguments]    ${portName_list}
    [Documentation]    Retrieve the port MacAddr for the given list of port name and return the MAC address list.
    ${MacAddr-list}    Create List
    : FOR    ${portName}    IN    @{portName_list}
    \    ${macAddr}=    OpenStackOperations.Get Port Mac    ${portName}
    \    Append To List    ${MacAddr-list}    ${macAddr}
    [Return]    ${MacAddr-list}

Get Port Ip
    [Arguments]    ${port_name}
    [Documentation]    Keyword would return the IP of the ${port_name} received.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port list | grep "${port_name}" | awk -F\\' '{print $2}'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${port_ip}=    Get from List    ${splitted_output}    0
    Should Be True    '${rc}' == '0'
    [Return]    ${port_ip}

Get Port Mac
    [Arguments]    ${port_name}
    [Documentation]    Keyword would return the MAC ID of the ${port_name} received.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack port show ${port_name} | grep mac_address | awk '{print $4}'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${port_mac}=    Get from List    ${splitted_output}    0
    Should Be True    '${rc}' == '0'
    [Return]    ${port_mac}

Create L2Gateway
    [Arguments]    ${bridge_name}    ${intf_name}    ${gw_name}
    [Documentation]    Keyword to create an L2 Gateway ${gw_name} for bridge ${bridge_name} connected to interface ${intf_name} (Using Neutron CLI).
    ${rc}    ${l2gw_output}=    Run And Return Rc And Output    ${L2GW_CREATE} name=${bridge_name},interface_names=${intf_name} ${gw_name}
    Log    ${l2gw_output}
    [Return]    ${l2gw_output}

Create L2Gateway Connection
    [Arguments]    ${gw_name}    ${net_name}
    [Documentation]    Keyword would create a new L2 Gateway Connection for ${gw_name} to ${net_name} (Using Neutron CLI).
    ${rc}    ${l2gw_output}=    Run And Return Rc And Output    ${L2GW_CONN_CREATE} ${gw_name} ${net_name}
    Log    ${l2gw_output}
    Should Be True    '${rc}' == '0'
    [Return]    ${l2gw_output}

Get All L2Gateway
    [Documentation]    Keyword to return all the L2 Gateways available (Using Neutron CLI).
    ${rc}    ${output}=    Run And Return Rc And Output    ${L2GW_GET_YAML}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get All L2Gateway Connection
    [Documentation]    Keyword to return all the L2 Gateway connections available (Using Neutron CLI).
    ${rc}    ${output}=    Run And Return Rc And Output    ${L2GW_GET_CONN_YAML}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get L2Gateway
    [Arguments]    ${gw_id}
    [Documentation]    Keyword to check if the ${gw_id} is available in the L2 Gateway list (Using Neutron CLI).
    ${rc}    ${output}=    Run And Return Rc And Output    ${L2GW_SHOW} ${gw_id}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get L2gw Id
    [Arguments]    ${l2gw_name}
    [Documentation]    Keyword to retrieve the L2 Gateway ID for the ${l2gw_name} (Using Neutron CLI).
    ${rc}    ${output}=    Run And Return Rc And Output    ${L2GW_GET} | grep "${l2gw_name}" | awk '{print $2}'
    Log    ${output}
    Should Be True    '${rc}' == '0'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${l2gw_id}=    Get from List    ${splitted_output}    0
    [Return]    ${l2gw_id}

Get L2gw Connection Id
    [Arguments]    ${l2gw_name}
    [Documentation]    Keyword to retrieve the L2 Gateway Connection ID for the ${l2gw_name} (Using Neutron CLI).
    ${l2gw_id}=    OpenStackOperations.Get L2gw Id    ${l2gw_name}
    ${rc}    ${output}=    Run And Return Rc And Output    ${L2GW_GET_CONN} | grep "${l2gw_id}" | awk '{print $2}'
    Should Be True    '${rc}' == '0'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${l2gw_conn_id}=    Get from List    ${splitted_output}    0
    [Return]    ${l2gw_conn_id}

Neutron Port List Rest
    [Documentation]    Keyword to get all ports details in Neutron (Using REST).
    ${resp} =    RequestsLibrary.Get Request    session    ${PORT_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Get Neutron Port Rest
    [Arguments]    ${port_id}
    [Documentation]    Keyword to get the specific port details in Neutron (Using REST).
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/${GET_PORT_URL}/${port_id}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Update Port Rest
    [Arguments]    ${port_id}    ${json_data}
    [Documentation]    Keyword to update ${port_id} with json data received in ${json_data} (Using REST).
    Log    ${json_data}
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_API}/${GET_PORT_URL}/${port_id}    ${json_data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Create And Configure Security Group
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with given name, and default allow rules for TCP/UDP/ICMP protocols.
    Neutron Security Group Create    ${sg-name}
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg-name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Add Security Group To VM
    [Arguments]    ${vm}    ${sg}
    [Documentation]    Add the security group provided to the given VM.
    ${output}=    OpenStack CLI    openstack server add security group ${vm} ${sg}

Remove Security Group From VM
    [Arguments]    ${vm}    ${sg}
    [Documentation]    Remove the security group provided to the given VM.
    Get ControlNode Connection
    OpenStack CLI    openstack server remove security group ${vm} ${sg}

Create SFC Flow Classifier
    [Arguments]    ${name}    ${src_ip}    ${dest_ip}    ${protocol}    ${dest_port}    ${neutron_src_port}
    [Documentation]    Create a flow classifier for SFC
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc flow classifier create --ethertype IPv4 --source-ip-prefix ${src_ip}/32 --destination-ip-prefix ${dest_ip}/32 --protocol ${protocol} --destination-port ${dest_port}:${dest_port} --logical-source-port ${neutron_src_port} ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    Should Contain    ${output}    ${name}
    [Return]    ${output}

Delete SFC Flow Classifier
    [Arguments]    ${name}
    [Documentation]    Delete a SFC flow classifier
    Get ControlNode Connection
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc flow classifier delete ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Create SFC Port Pair
    [Arguments]    ${name}    ${port_in}    ${port_out}
    [Documentation]    Creates a neutron port pair for SFC
    Get ControlNode Connection
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc port pair create --ingress=${port_in} --egress=${port_out} ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    Should Contain    ${output}    ${name}
    [Return]    ${output}

Delete SFC Port Pair
    [Arguments]    ${name}
    [Documentation]    Delete a SFC port pair
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc port pair delete ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Create SFC Port Pair Group
    [Arguments]    ${name}    ${port_pair}
    [Documentation]    Creates a port pair group with a single port pair for SFC
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc port pair group create --port-pair ${port_pair} ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    Should Contain    ${output}    ${name}
    [Return]    ${output}

Create SFC Port Pair Group With Two Pairs
    [Arguments]    ${name}    ${port_pair1}    ${port_pair2}
    [Documentation]    Creates a port pair group with two port pairs for SFC
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc port pair group create --port-pair ${port_pair1} --port-pair ${port_pair2} ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    Should Contain    ${output}    ${name}
    [Return]    ${output}

Delete SFC Port Pair Group
    [Arguments]    ${name}
    [Documentation]    Delete a SFC port pair group
    Get ControlNode Connection
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc port pair group delete ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Create SFC Port Chain
    [Arguments]    ${name}    ${pg1}    ${pg2}    ${fc}
    [Documentation]    Creates a port pair chain with two port groups and a singel classifier.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc port chain create --port-pair-group ${pg1} --port-pair-group ${pg2} --flow-classifier ${fc} ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    Should Contain    ${output}    ${name}
    [Return]    ${output}

Delete SFC Port Chain
    [Arguments]    ${name}
    [Documentation]    Delete a SFC port chain
    ${rc}    ${output}=    Run And Return Rc And Output    openstack sfc port chain delete ${name}
    Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Reboot Nova VM
    [Arguments]    ${vm_name}
    [Documentation]    Reboot NOVA VM
    OpenStack CLI    openstack server reboot --wait ${vm_name}
    Wait Until Keyword Succeeds    35s    10s    Verify VM Is ACTIVE    ${vm_name}

Remove RSA Key From KnownHosts
    [Arguments]    ${vm_ip}
    [Documentation]    Remove RSA
    Get ControlNode Connection
    ${output}=    Write Commands Until Prompt And Log    sudo cat /root/.ssh/known_hosts    30s
    ${output}=    Write Commands Until Prompt And Log    sudo ssh-keygen -f "/root/.ssh/known_hosts" -R ${vm_ip}    30s
    ${output}=    Write Commands Until Prompt    sudo cat "/root/.ssh/known_hosts"    30s

Wait For Routes To Propogate
    [Arguments]    ${networks}    ${subnets}
    [Documentation]    Check propagated routes
    Get ControlNode Connection
    : FOR    ${INDEX}    IN RANGE    0    1
    \    ${net_id}=    Get Net Id    @{networks}[${INDEX}]
    \    ${is_ipv6}=    Get Regexp Matches    @{subnets}[${INDEX}]    ${IP6_REGEX}
    \    ${length}=    Get Length    ${is_ipv6}
    \    ${cmd}=    Set Variable If    ${length} == 0    ip route    ip -6 route
    \    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ${cmd}    ]>
    \    Should Contain    ${output}    @{subnets}[${INDEX}]

Neutron Cleanup
    [Arguments]    ${vms}=@{EMPTY}    ${networks}=@{EMPTY}    ${subnets}=@{EMPTY}    ${ports}=@{EMPTY}    ${sgs}=@{EMPTY}
    : FOR    ${vm}    IN    @{vms}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    ${vm}
    : FOR    ${port}    IN    @{ports}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Port    ${port}
    : FOR    ${subnet}    IN    @{subnets}
    \    BuiltIn.Run Keyword And Ignore Error    Delete SubNet    ${subnet}
    : FOR    ${network}    IN    @{networks}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Network    ${network}
    : FOR    ${sg}    IN    @{sgs}
    \    BuiltIn.Run Keyword And Ignore Error    Delete SecurityGroup    ${sg}

OpenStack List All
    [Documentation]    Get a list of different OpenStack resources that might be in use.
    @{modules} =    BuiltIn.Create List    floating ip    server    router    port    network
    ...    subnet    security group    security group rule
    : FOR    ${module}    IN    @{modules}
    \    OpenStack CLI    openstack ${module} list

OpenStack CLI Get List
    [Arguments]    ${cmd}
    [Documentation]    Return a json list from the output of an OpenStack command.
    ${json} =    OpenStack CLI    ${cmd}
    @{list} =    RequestsLibrary.To Json    ${json}
    BuiltIn.Log    ${list}
    [Return]    @{list}

OpenStack CLI
    [Arguments]    ${cmd}
    [Documentation]    Run the given OpenStack ${cmd}.
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    ${output}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

OpenStack Cleanup All
    [Documentation]    Cleanup all Openstack resources with best effort. The keyword will query for all resources
    ...    in use and then attempt to delete them. Errors are ignored to allow the cleanup to continue.
    @{fips} =    OpenStack CLI Get List    openstack floating ip list -f json
    : FOR    ${fip}    IN    @{fips}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Floating IP    ${fip['ID']}
    @{vms} =    OpenStack CLI Get List    openstack server list -f json
    : FOR    ${vm}    IN    @{vms}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    ${vm['ID']}
    @{routers} =    OpenStack CLI Get List    openstack router list -f json
    : FOR    ${router}    IN    @{routers}
    \    BuiltIn.Run Keyword And Ignore Error    Cleanup Router    ${router['ID']}
    @{ports} =    OpenStack CLI Get List    openstack port list -f json
    : FOR    ${port}    IN    @{ports}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Port    ${port['ID']}
    @{networks} =    OpenStack CLI Get List    openstack network list -f json
    : FOR    ${network}    IN    @{networks}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Subnet    ${network['Subnets']}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Network    ${network['ID']}
    @{security_groups} =    OpenStack CLI Get List    openstack security group list -f json
    : FOR    ${security_group}    IN    @{security_groups}
    \    BuiltIn.Run Keyword If    "${security_group['Name']}" != "default"    BuiltIn.Run Keyword And Ignore Error    Delete SecurityGroup    ${security_group['ID']}
    OpenStack List All

Cleanup Router
    [Arguments]    ${id}
    [Documentation]    Delete a router, but first remove any interfaces or gateways so that the delete will be successful.
    @{ports} =    OpenStack CLI Get List    openstack port list --router ${id} -f json --long
    : FOR    ${port}    IN    @{ports}
    \    ${subnet_id} =    Get Match    ${port['Fixed IP Addresses']}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}    0
    \    BuiltIn.Run Keyword If    "${port['Device Owner']}" == "network:router_gateway"    BuiltIn.Run Keyword And Ignore Error    Remove Gateway    ${id}
    \    BuiltIn.Run Keyword If    "${port['Device Owner']}" == "network:router_interface"    BuiltIn.Run Keyword And Ignore Error    Remove Interface    ${id}    ${subnet_id}
    BuiltIn.Run Keyword And Ignore Error    Delete Router    ${id}

OpenStack Suite Setup
    [Documentation]    Wrapper teardown keyword that can be used in any suite running in an openstack environement
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Run Keyword If    "${PRE_CLEAN_OPENSTACK_ALL}"=="True"    OpenStack Cleanup All
    DevstackUtils.Devstack Suite Setup
    Add OVS Logging On All OpenStack Nodes

OpenStack Suite Teardown
    [Documentation]    Wrapper teardown keyword that can be used in any suite running in an openstack environement
    ...    to clean up all openstack resources. For example, all instances, networks, ports, etc will be listed and
    ...    and deleted. As other global cleanup tasks are needed, they can be added here and the suites will all
    ...    benefit automatically.
    OpenStack Cleanup All
    SSHLibrary.Close All Connections

Copy DHCP Files From Control Node
    [Documentation]    Copy the current DHCP files to the robot vm. The keyword must be called
    ...    after the subnet(s) are created and before the subnet(s) are deleted.
    ${suite_} =    BuiltIn.Evaluate    """${SUITE_NAME}""".replace(" ","_").replace("/","_").replace(".","_")
    ${dstdir} =    Set Variable    /tmp/qdhcp/${suite_}
    OperatingSystem.Create Directory    ${dstdir}
    Get ControlNode Connection
    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Get Directory    /opt/stack/data/neutron/dhcp    ${dstdir}    recursive=True

Is Feature Installed
    [Arguments]    ${features}=none
    : FOR    ${feature}    IN    ${features}
    \    ${status}    ${output}    Run Keyword And Ignore Error    Builtin.Should Contain    ${CONTROLLERFEATURES}    ${feature}
    \    Return From Keyword If    "${status}" == "PASS"    True
    [Return]    False

Add OVS Logging On All OpenStack Nodes
    [Documentation]    Add higher levels of OVS logging to all the OpenStack nodes
    Run Keyword If    0 < ${NUM_OS_SYSTEM}    OVSDB.Add OVS Logging    ${OS_CNTL_CONN_ID}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    OVSDB.Add OVS Logging    ${OS_CMP1_CONN_ID}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    OVSDB.Add OVS Logging    ${OS_CMP2_CONN_ID}

Reset OVS Logging On All OpenStack Nodes
    [Documentation]    Reset the OVS logging to all the OpenStack nodes
    Run Keyword If    0 < ${NUM_OS_SYSTEM}    OVSDB.Reset OVS Logging    ${OS_CNTL_CONN_ID}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    OVSDB.Reset OVS Logging    ${OS_CMP1_CONN_ID}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    OVSDB.Reset OVS Logging    ${OS_CMP2_CONN_ID}
