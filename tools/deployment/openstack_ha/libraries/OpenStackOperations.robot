*** Settings ***
Documentation       Openstack library. This library is useful for tests to create network, subnet, router and vm instances

Library             Collections
Library             OperatingSystem
Library             RequestsLibrary
Library             SSHLibrary
Library             String
Resource            DataModels.robot
Resource            DevstackUtils.robot
Resource            L2GatewayOperations.robot
Resource            OVSDB.robot
Resource            SetupUtils.robot
Resource            SSHKeywords.robot
Resource            Tcpdump.robot
Resource            Utils.robot
Resource            ../variables/Variables.robot
Resource            ../variables/netvirt/Variables.robot
Variables           ../variables/netvirt/Modules.py


*** Keywords ***
Get Tenant ID From Security Group
    [Documentation]    Returns tenant ID by reading it from existing default security-group.
    ${output} =    OpenStack CLI    openstack security group show default | grep "| tenant_id" | awk '{print $4}'
    RETURN    ${output}

Get Tenant ID From Network
    [Documentation]    Returns tenant ID by reading it from existing network.
    [Arguments]    ${network_uuid}
    ${resp} =    TemplatedRequests.Get_From_Uri
    ...    uri=${CONFIG_API}/neutron:neutron/networks/network/${network_uuid}/
    ...    accept=${ACCEPT_EMPTY}
    ...    session=session
    ${temp_vars} =    BuiltIn.Set Variable    ['network'][0]['tenant-id']
    ${tenant_id} =    Utils.Extract Value From Content    ${resp}    ${temp_vars}
    RETURN    ${tenant_id}

Create Network
    [Documentation]    Create Network with neutron request.
    [Arguments]    ${network_name}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    ${output} =    OpenStack CLI    openstack network create ${network_name} ${additional_args}
    RETURN    ${output}

Update Network
    [Documentation]    Update Network with neutron request.
    [Arguments]    ${network_name}    ${additional_args}=${EMPTY}
    ${cmd} =    BuiltIn.Set Variable If
    ...    '${OPENSTACK_BRANCH}'=='stable/newton'
    ...    neutron -v net-update ${network_name} ${additional_args}
    ...    openstack network set ${network_name} ${additional_args}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

Show Network
    [Documentation]    Show Network with neutron request.
    [Arguments]    ${network_name}
    ${output} =    OpenStack CLI    openstack network show ${network_name}
    RETURN    ${output}

List Networks
    [Documentation]    List networks and return output with neutron client.
    ${output} =    OpenStack CLI    openstack network list
    RETURN    ${output}

List Subnets
    [Documentation]    List subnets and return output with neutron client.
    ${output} =    OpenStack CLI    openstack subnet list
    RETURN    ${output}

Delete Network
    [Documentation]    Delete Network with neutron request.
    [Arguments]    ${network_name}
    ${output} =    OpenStack CLI    openstack network delete ${network_name}

Create SubNet
    [Documentation]    Create SubNet for the Network with neutron request.
    [Arguments]    ${network_name}    ${subnet_name}    ${range_ip}    ${additional_args}=${EMPTY}
    ${output} =    OpenStack CLI
    ...    openstack subnet create --network ${network_name} --subnet-range ${range_ip} ${subnet_name} ${additional_args}

Update SubNet
    [Documentation]    Update subnet with neutron request.
    [Arguments]    ${subnet_name}    ${additional_args}=${EMPTY}
    ${cmd} =    BuiltIn.Set Variable If
    ...    '${OPENSTACK_BRANCH}'=='stable/newton'
    ...    neutron -v subnet-update ${subnet_name} ${additional_args}
    ...    openstack subnet set ${subnet_name} ${additional_args}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

Show SubNet
    [Documentation]    Show subnet with neutron request.
    [Arguments]    ${subnet_name}
    ${output} =    OpenStack CLI    openstack subnet show ${subnet_name}
    RETURN    ${output}

Create Port
    [Documentation]    Create Port with neutron request.
    [Arguments]    ${network_name}    ${port_name}    ${sg}=default    ${additional_args}=${EMPTY}    ${allowed_address_pairs}=${EMPTY}
    # if allowed_address_pairs is not empty we need to create the arguments to pass to the port create command. They are
    # in a different format with the neutron vs openstack cli.
    ${address_pair_length} =    BuiltIn.Get Length    ${allowed_address_pairs}
    ${allowed_pairs_argv} =    BuiltIn.Set Variable If
    ...    '${OPENSTACK_BRANCH}'=='stable/newton' and '${address_pair_length}'=='2'
    ...    --allowed-address-pairs type=dict list=true ip_address=${allowed_address_pairs}[0] ip_address=${allowed_address_pairs}[1]
    ${allowed_pairs_argv} =    BuiltIn.Set Variable If
    ...    '${OPENSTACK_BRANCH}'!='stable/newton' and '${address_pair_length}'=='2'
    ...    --allowed-address ip-address=${allowed_address_pairs}[0] --allowed-address ip-address=${allowed_address_pairs}[1]
    ...    ${allowed_pairs_argv}
    ${allowed_pairs_argv} =    BuiltIn.Set Variable If
    ...    '${address_pair_length}'=='0'
    ...    ${EMPTY}
    ...    ${allowed_pairs_argv}
    ${cmd} =    BuiltIn.Set Variable If
    ...    '${OPENSTACK_BRANCH}'=='stable/newton'
    ...    neutron -v port-create ${network_name} --name ${port_name} --security-group ${sg} ${additional_args} ${allowed_pairs_argv}
    ...    openstack port create --network ${network_name} ${port_name} --security-group ${sg} ${additional_args} ${allowed_pairs_argv}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'

Update Port
    [Documentation]    Update port with neutron request.
    [Arguments]    ${port_name}    ${additional_args}=${EMPTY}
    ${output} =    OpenStack CLI    openstack port set ${port_name} ${additional_args}
    RETURN    ${output}

Show Port
    [Documentation]    Show port with neutron request.
    [Arguments]    ${port_name}
    ${output} =    OpenStack CLI    openstack port show ${port_name}
    RETURN    ${output}

Delete Port
    [Documentation]    Delete Port with neutron request.
    [Arguments]    ${port_name}
    ${output} =    OpenStack CLI    openstack port delete ${port_name}

Create user
    [Arguments]    ${user_name}    ${domain}    ${password}    ${rc_file}=${EMPTY}
    IF    "${rc_file}" != "${EMPTY}"
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    source ${rc_file};openstack user create ${user_name} --domain ${domain} --password ${password}
    ELSE
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    openstack user create ${user_name} --domain ${domain} --password ${password}
    END
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Role Add
    [Arguments]    ${project_name}    ${user_name}    ${role}    ${rc_file}=${EMPTY}
    IF    "${rc_file}" != "${EMPTY}"
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    source ${rc_file};openstack role add --project ${project_name} --user ${user_name} ${role}
    ELSE
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    openstack role add --project ${project_name} --user ${user_name} ${role}
    END
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Create Endpoint
    [Arguments]    ${region_name}    ${host_name}    ${service_category}    ${endpoint_category}    ${port}    ${rc_file}=${EMPTY}
    IF    "${rc_file}" != "${EMPTY}"
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    source ${rc_file};openstack endpoint create --region ${region_name} ${service_category} ${endpoint_category} http://${host_name}:${port}
    ELSE
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    openstack endpoint create --region ${region_name} ${service_category} ${endpoint_category} http://${host_name}:${port}
    END
    Log    ${output}
    Should Not Be True    ${rc}

List Ports
    [Documentation]    List ports and return output with neutron client.
    ${output} =    OpenStack CLI    openstack port list
    RETURN    ${output}

List Nova VMs
    [Documentation]    List VMs and return output with nova client.
    ${output} =    OpenStack CLI    openstack server list --all-projects
    RETURN    ${output}

Create And Associate Floating IPs
    [Documentation]    Create and associate floating IPs to VMs with nova request
    [Arguments]    ${external_net}    @{vm_list}
    ${ip_list} =    BuiltIn.Create List    @{EMPTY}
    FOR    ${vm}    IN    @{vm_list}
        ${output} =    OpenStack CLI    openstack floating ip create ${external_net}
        @{ip} =    String.Get Regexp Matches    ${output}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
        ${ip_length} =    BuiltIn.Get Length    ${ip}
        IF    ${ip_length}>0
            Collections.Append To List    ${ip_list}    ${ip}[0]
        ELSE
            Collections.Append To List    ${ip_list}    None
        END
        ${output} =    OpenStack CLI    openstack server add floating ip ${vm} ${ip}[0]
    END
    RETURN    ${ip_list}

Delete Floating IP
    [Documentation]    Delete floating ip with neutron request.
    [Arguments]    ${fip}
    ${output} =    OpenStack CLI    openstack floating ip delete ${fip}

Delete SubNet
    [Documentation]    Delete SubNet for the Network with neutron request.
    [Arguments]    ${subnet}
    ${output} =    OpenStack CLI    openstack subnet delete ${subnet}

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    [Arguments]    ${vm_name}
    ${output} =    OpenStack CLI    openstack server delete ${vm_name}

Get Net Id
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    [Arguments]    ${network_name}
    ${output} =    OpenStack CLI    openstack network list | grep "${network_name}" | awk '{print $2}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${net_id} =    Collections.Get from List    ${splitted_output}    0
    RETURN    ${net_id}

Get Subnet Id
    [Documentation]    Retrieve the subnet id for the given subnet name
    [Arguments]    ${subnet_name}
    ${output} =    OpenStack CLI    openstack subnet show "${subnet_name}" | grep " id " | awk '{print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${subnet_id} =    Collections.Get from List    ${splitted_output}    0
    RETURN    ${subnet_id}

Get Port Id
    [Documentation]    Retrieve the port id for the given port name to attach specific vm instance to a particular port
    [Arguments]    ${port_name}
    ${output} =    OpenStack CLI    openstack port list | grep "${port_name}" | awk '{print $2}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${port_id} =    Collections.Get from List    ${splitted_output}    0
    RETURN    ${port_id}

Get Router Id
    [Documentation]    Retrieve the router id for the given router name
    [Arguments]    ${router1}
    ${output} =    OpenStack CLI    openstack router show "${router1}" |awk '/ id / {print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${router_id} =    Collections.Get from List    ${splitted_output}    0
    RETURN    ${router_id}

Create Vm Instances
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    [Arguments]    ${net_name}    ${vm_instance_names}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default    ${min}=1
    ...    ${max}=1
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    FOR    ${vm}    IN    @{vm_instance_names}
        ${output} =    OpenStack CLI
        ...    openstack server create --image ${image} --flavor ${flavor} --nic net-id=${net_id} ${vm} --security-group ${sg} --min ${min} --max ${max}
    END

Create Vm Instance On Compute Node
    [Documentation]    Create a VM instance on a specific compute node.
    [Arguments]    ${net_name}    ${vm_name}    ${node_hostname}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    OpenStack CLI
    ...    openstack server create ${vm_name} --image ${image} --flavor ${flavor} --nic net-id=${net_id} --security-group ${sg} --availability-zone nova:${node_hostname}

Create Vm Instance With Port
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    [Arguments]    ${port_name}    ${vm_instance_name}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${port_id} =    OpenStackOperations.Get Port Id    ${port_name}
    ${output} =    OpenStack CLI
    ...    openstack server create --image ${image} --flavor ${flavor} --nic port-id=${port_id} ${vm_instance_name} --security-group ${sg}

Create Vm Instance With Ports
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    [Arguments]    ${port_name}    ${port2_name}    ${vm_instance_name}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${port_id} =    OpenStackOperations.Get Port Id    ${port_name}
    ${port2_id} =    OpenStackOperations.Get Port Id    ${port2_name}
    ${output} =    OpenStack CLI
    ...    openstack server create --image ${image} --flavor ${flavor} --nic port-id=${port_id} --nic port-id=${port2_id} ${vm_instance_name} --security-group ${sg}

Create Vm Instance With Port On Compute Node
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    [Arguments]    ${port_name}    ${vm_instance_name}    ${node_hostname}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${port_id} =    OpenStackOperations.Get Port Id    ${port_name}
    ${output} =    OpenStack CLI
    ...    openstack server create --image ${image} --flavor ${flavor} --nic port-id=${port_id} --security-group ${sg} --availability-zone nova:${node_hostname} ${vm_instance_name}

Get Hypervisor Hostname From IP
    [Documentation]    Returns the hostname found for the given IP address if it's listed in hypervisor list. For debuggability
    ...    the full listing is logged first, then followed by a grep | cut to focus on the actual hostname to return
    [Arguments]    ${hypervisor_ip}
    ${output} =    OpenStack CLI    openstack hypervisor list
    ${hostname} =    OpenStack CLI    openstack hypervisor list -f value | grep "${hypervisor_ip} " | cut -d" " -f 2
    RETURN    ${hostname}

Create Nano Flavor
    [Documentation]    Create a nano flavor
    ${output} =    OpenStack CLI    openstack flavor create m1.nano --id auto --ram 64 --disk 0 --vcpus 1

Verify VM Is ACTIVE
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    [Arguments]    ${vm_name}
    ${output} =    OpenStack CLI    openstack server show ${vm_name} | grep OS-EXT-STS:vm_state
    BuiltIn.Should Contain    ${output}    active

Poll VM Is ACTIVE
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    [Arguments]    ${vm_name}    ${retry}=600s    ${retry_interval}=30s
    BuiltIn.Wait Until Keyword Succeeds
    ...    ${retry}
    ...    ${retry_interval}
    ...    OpenStackOperations.Verify VM Is ACTIVE
    ...    ${vm_name}

Collect VM IP Addresses
    [Documentation]    Using the console-log on the provided ${vm_list} to search for the string "obtained" which
    ...    correlates to the instance receiving it's IP address via DHCP. Also retrieved is the ip of the nameserver
    ...    if available in the console-log output. The keyword will also return a list of the learned ips as it
    ...    finds them in the console log output, and will have "None" for Vms that no ip was found.
    [Arguments]    ${fail_on_none}    @{vm_list}
    ${ip_list} =    Create List    @{EMPTY}
    FOR    ${vm}    IN    @{vm_list}
        ${rc}    ${vm_ip_line} =    Run And Return Rc And Output
        ...    openstack console log show ${vm} | grep -i "obtained"
        @{vm_ip} =    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
        ${vm_ip_length} =    Get Length    ${vm_ip}
        IF    ${vm_ip_length}>0
            Append To List    ${ip_list}    ${vm_ip}[0]
        ELSE
            Append To List    ${ip_list}    None
        END
        ${rc}    ${dhcp_ip_line} =    Run And Return Rc And Output
        ...    openstack console log show ${vm} | grep "^nameserver"
        ${dhcp_ip} =    Get Regexp Matches    ${dhcp_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
        ${dhcp_ip_length} =    Get Length    ${dhcp_ip}
        IF    ${dhcp_ip_length}<=0    Append To List    ${dhcp_ip}    None
        ${vm_console_output} =    Run    openstack console log show ${vm}
        Log    ${vm_console_output}
    END
    ${dhcp_length} =    Get Length    ${dhcp_ip}
    IF    '${fail_on_none}' == 'true'
        Should Not Contain    ${ip_list}    None
    END
    IF    '${fail_on_none}' == 'true'
        Should Not Contain    ${dhcp_ip}    None
    END
    #    Should Be True    ${dhcp_length} <= 1
    IF    ${dhcp_length}==0    RETURN    ${ip_list}    ${EMPTY}
    RETURN    ${ip_list}    ${dhcp_ip}

Get Match
    [Documentation]    Wrapper around String.Get Regexp Matches to return None if not found or the first match if found.
    [Arguments]    ${text}    ${regexp}    ${index}=0
    @{matches} =    String.Get Regexp Matches    ${text}    ${regexp}
    ${matches_length} =    BuiltIn.Get Length    ${matches}
    BuiltIn.Set Suite Variable    ${OS_MATCH}    None
    IF    ${matches_length} > ${index}
        BuiltIn.Set Suite Variable    ${OS_MATCH}    ${matches}[${index}]
    END
    RETURN    ${OS_MATCH}

Get VM IP
    [Documentation]    Get the vm ip address and nameserver by scraping the vm's console log.
    ...    Get VM IP returns three values: [0] the vm IP, [1] the DHCP IP and [2] the vm console log.
    [Arguments]    ${fail_on_none}    ${vm}
    ${vm_console_output} =    OpenStack CLI With No Log    openstack console log show ${vm}
    ${vm_ip} =    BuiltIn.Set Variable    None
    ${dhcp_ip} =    BuiltIn.Set Variable    None
    ${match} =    OpenStackOperations.Get Match    ${vm_console_output}    ${REGEX_OBTAINED}
    ${vm_ip} =    OpenStackOperations.Get Match    ${match}    ${REGEX_IPV4}    0
    ${match} =    OpenStackOperations.Get Match    ${vm_console_output}    ${REGEX_IPROUTE}
    ${dhcp_ip} =    OpenStackOperations.Get Match    ${match}    ${REGEX_IPV4}    1
    IF    '${fail_on_none}' == 'true'
        BuiltIn.Should Not Contain    ${vm_ip}    None
    END
    IF    '${fail_on_none}' == 'true'
        BuiltIn.Should Not Contain    ${dhcp_ip}    None
    END
    RETURN    ${vm_ip}    ${dhcp_ip}    ${vm_console_output}

Get VM IPs
    [Documentation]    Get the instance IP addresses and nameserver address for the list of given vms.
    ...    First poll for the vm instance to be in the active state, then poll for the vm ip address and nameserver.
    ...    Get VM IPs returns two things: [0] a list of the ips for the vms passed to this keyword (may contain values
    ...    of None) and [1] the dhcp ip address found in the last vm checked.
    ...    TODO: there is a potential issue for a caller that passes in VMs belonging to different networks that
    ...    may have different dhcp server addresses. Not sure what TODO about that, but noting it here for reference.
    [Arguments]    @{vms}
    @{vm_ips} =    BuiltIn.Create List    @{EMPTY}
    FOR    ${vm}    IN    @{vms}
        OpenStackOperations.Poll VM Is ACTIVE    ${vm}
        ${status}    ${ips_and_console_log} =    BuiltIn.Run Keyword And Ignore Error
        ...    BuiltIn.Wait Until Keyword Succeeds
        ...    180s
        ...    15s
        ...    OpenStackOperations.Get VM IP
        ...    true
        ...    ${vm}
        # If there is trouble with Get VM IP, the status will be FAIL and the return value will be a string of what went
        # wrong. We need to handle both the PASS and FAIL cases. In the FAIL case we know we wont have access to the
        # console log, as it would not be returned; so we need to grab it again to log it. We also can append 'None' to
        # the vm ip list if status is FAIL.
        IF    "${status}" == "PASS"    BuiltIn.Log    ${ips_and_console_log[2]}
        IF    "${status}" == "PASS"
            Collections.Append To List    ${vm_ips}    ${ips_and_console_log[0]}
        END
        IF    "${status}" == "FAIL"
            Collections.Append To List    ${vm_ips}    None
        END
        IF    "${status}" == "FAIL"
            ${vm_console_output} =    OpenStack CLI    openstack console log show ${vm}
        ELSE
            ${vm_console_output} =    Set Variable    ${None}
        END
        IF    "${status}" == "FAIL"    BuiltIn.Log    ${vm_console_output}
    END
    OpenStackOperations.Copy DHCP Files From Control Node
    RETURN    @{vm_ips}    ${ips_and_console_log[1]}

Collect VM IPv6 SLAAC Addresses
    [Documentation]    For each VM parse output of "openstack server show" to get its IPv6 address from Neutron DB.
    ...    Then try to connect to each VM by SSH and execute there "ip -6 a" command. This double-check allows to
    ...    obtain and compare IP info (Neutron DB vs dnsmasque/ODL DHCP) and to test L2 connectivity as well.
    ...    Returns an empty list if no IPv6 addresses found or if SSH connection fails.
    ...    Otherwise, returns a list of IPv6 addresses.
    [Arguments]    ${fail_on_none}    ${vm_list}    ${network}    ${subnet}
    ${ipv6_list} =    BuiltIn.Create List    @{EMPTY}
    FOR    ${vm}    IN    @{vm_list}
        ${output} =    OpenStack CLI    openstack server show ${vm} -f shell
        ${pattern} =    String.Replace String    ${subnet}    ::/64    (:[a-f0-9]{,4}){,4}
        @{vm_ipv6} =    String.Get Regexp Matches    ${output}    ${pattern}
        ${vm_ip_length} =    BuiltIn.Get Length    ${vm_ipv6}[0]
        IF    ${vm_ip_length}>0
            ${ipv6_data_from_vm} =    OpenStackOperations.Execute Command on VM Instance
            ...    ${network}
            ...    ${vm_ipv6[0]}
            ...    ip -6 a
        ELSE
            ${ipv6_data_from_vm} =    Set Variable    ${None}
        END
        @{ipv6} =    String.Get Regexp Matches    ${ipv6_data_from_vm}    ${pattern}
        ${ipv6_addr_list_length} =    BuiltIn.Get Length    @{ipv6}
        IF    ${ipv6_addr_list_length}>0
            Collections.Append To List    ${ipv6_list}    ${ipv6[0]}
        ELSE
            Collections.Append To List    ${ipv6_list}    None
        END
    END
    RETURN    ${ipv6_list}

View Vm Console
    [Documentation]    View Console log of the created vm instances using nova show.
    [Arguments]    ${vm_instance_names}
    FOR    ${vm}    IN    @{vm_instance_names}
        ${output} =    OpenStack CLI    openstack server show ${vm}
        ${output} =    OpenStack CLI    openstack console log show ${vm}
    END

Ping Vm From DHCP Namespace
    [Documentation]    Reach all Vm Instance with the net id of the Netowrk.
    [Arguments]    ${net_name}    ${vm_ip}
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log
    ...    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}
    ...    20s
    BuiltIn.Should Contain    ${output}    64 bytes

Ping From DHCP Should Not Succeed
    [Documentation]    Should Not Reach Vm Instance with the net id of the Netowrk.
    [Arguments]    ${net_name}    ${vm_ip}
    IF    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}    RETURN
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log
    ...    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}
    ...    20s
    BuiltIn.Should Not Contain    ${output}    64 bytes

Ping Vm From Control Node
    [Documentation]    Ping VM floating IP from control node
    [Arguments]    ${vm_floating_ip}    ${additional_args}=${EMPTY}
    OpenStackOperations.Get ControlNode Connection
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log
    ...    ping ${additional_args} -c 3 ${vm_floating_ip}
    ...    20s
    BuiltIn.Should Contain    ${output}    64 bytes

Curl Metadata Server
    [Documentation]    Ping to the expected destination ip.
    ${output} =    Utils.Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    DevstackUtils.Write Commands Until Prompt    exit
    BuiltIn.Should Contain    ${output}    200

Close Vm Instance
    [Documentation]    Exit the vm instance.
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    exit

Check If Console Is VmInstance
    [Documentation]    Check if the session has been able to login to the VM instance
    [Arguments]    ${console}=cirros
    ${output} =    Utils.Write Commands Until Expected Prompt    id    ${OS_SYSTEM_PROMPT}
    BuiltIn.Should Contain    ${output}    ${console}

Exit From Vm Console
    [Documentation]    Check if the session has been able to login to the VM instance and exit the instance
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance    cirros
    IF    ${rcode}    DevstackUtils.Write Commands Until Prompt    exit

Check Ping
    [Documentation]    Run Ping command on the IP available as argument
    [Arguments]    ${ip_address}    ${ttl}=64
    ${ethertype} =    String.Get Regexp Matches    ${ip_address}    ${IP_REGEX}
    IF    ${ethertype}
        ${output} =    Utils.Write Commands Until Expected Prompt
        ...    ping -t ${ttl} -c 3 ${ip_address}
        ...    ${OS_SYSTEM_PROMPT}
    ELSE
        ${output} =    Utils.Write Commands Until Expected Prompt
        ...    ping6 -t ${ttl} -c 3 ${ip_address}
        ...    ${OS_SYSTEM_PROMPT}
    END
    BuiltIn.Should Contain    ${output}    64 bytes

Check No Ping
    [Documentation]    Run Ping command to the IP given as argument, executing 3 times and expecting NOT to see "64 bytes"
    [Arguments]    ${ip_address}    ${ttl}=64
    ${output} =    Utils.Write Commands Until Expected Prompt
    ...    ping -t ${ttl} -c 3 ${ip_address}
    ...    ${OS_SYSTEM_PROMPT}
    BuiltIn.Should Not Contain    ${output}    64 bytes

Check Metadata Access
    [Documentation]    Try curl on the Metadataurl and check if it is okay
    ${output} =    Utils.Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    BuiltIn.Should Contain    ${output}    200

Execute Command on VM Instance
    [Documentation]    Login to the vm instance using ssh in the network, executes a command inside the VM and returns the ouput.
    [Arguments]    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    Utils.Write Commands Until Expected Prompt
    ...    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
    ...    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance
    IF    ${rcode}
        ${output} =    Utils.Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}
    ELSE
        ${output} =    Set Variable    ${None}
    END
    RETURN    ${output}
    [Teardown]    Exit From Vm Console

Test Operations From Vm Instance
    [Documentation]    Login to the vm instance using ssh in the network.
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)    ${ttl}=64
    ...    ${ping_should_succeed}=True    ${check_metadata}=True
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    Utils.Write Commands Until Expected Prompt
    ...    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null
    ...    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance
    IF    ${rcode}
        Utils.Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    END
    IF    ${rcode}
        Utils.Write Commands Until Expected Prompt    route -n    ${OS_SYSTEM_PROMPT}
    END
    IF    ${rcode}
        Utils.Write Commands Until Expected Prompt    route -A inet6    ${OS_SYSTEM_PROMPT}
    END
    IF    ${rcode}
        Utils.Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    END
    IF    ${rcode}
        Utils.Write Commands Until Expected Prompt    ip -f inet6 neigh show    ${OS_SYSTEM_PROMPT}
    END
    FOR    ${dest_ip}    IN    @{dest_ips}
        ${string_empty} =    BuiltIn.Run Keyword And Return Status    Should Be Empty    ${dest_ip}
        IF    ${string_empty}            CONTINUE
        IF    ${rcode} and "${ping_should_succeed}" == "True"
            OpenStackOperations.Check Ping    ${dest_ip}    ttl=${ttl}
        ELSE
            OpenStackOperations.Check No Ping    ${dest_ip}    ttl=${ttl}
        END
    END
    ${ethertype} =    String.Get Regexp Matches    ${src_ip}    ${IP_REGEX}
    IF    ${rcode} and "${check_metadata}" and ${ethertype} == "True"
        OpenStackOperations.Check Metadata Access
    END
    [Teardown]    Exit From Vm Console

Test Netcat Operations From Vm Instance
    [Documentation]    Use Netcat to test TCP/UDP connections to the controller
    [Arguments]    ${net_name}    ${vm_ip}    ${dest_ip}    ${additional_args}=${EMPTY}    ${port}=12345    ${user}=cirros
    ...    ${password}=cubswin:)
    ${client_data} =    BuiltIn.Set Variable    Test Client Data
    ${server_data} =    BuiltIn.Set Variable    Test Server Data
    OpenStackOperations.Get ControlNode Connection
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log
    ...    ( ( echo "${server_data}" | sudo timeout 60 nc -l ${additional_args} ${port} ) & )
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo netstat -nlap | grep ${port}
    ${nc_output} =    OpenStackOperations.Execute Command on VM Instance
    ...    ${net_name}
    ...    ${vm_ip}
    ...    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${dest_ip} ${port}
    BuiltIn.Log    ${output}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo route -n
    BuiltIn.Log    ${output}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo arp -an
    BuiltIn.Log    ${output}
    BuiltIn.Should Match Regexp    ${nc_output}    ${server_data}

Ping Other Instances
    [Documentation]    Check reachability with other network's instances.
    [Arguments]    ${list_of_external_dst_ips}
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance
    FOR    ${dest_ip}    IN    @{list_of_external_dst_ips}
        OpenStackOperations.Check Ping    ${dest_ip}
    END

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    [Arguments]    ${router_name}
    ${output} =    OpenStack CLI    openstack router create ${router_name}

List Routers
    [Documentation]    List Routers and return output with neutron client.
    ${output} =    OpenStack CLI    openstack router list -f value
    RETURN    ${output}

Add Router Interface
    [Arguments]    ${router_name}    ${interface_name}
    ${output} =    OpenStack CLI    openstack router add subnet ${router_name} ${interface_name}

Show Router Interface
    [Documentation]    List Routers interface associated with given Router and return output with neutron client.
    [Arguments]    ${router_name}
    ${output} =    OpenStack CLI    openstack port list --router ${router_name} -f value
    RETURN    ${output}

Add Router Gateway
    [Arguments]    ${router_name}    ${external_network_name}
    ${cmd} =    BuiltIn.Set Variable If
    ...    '${OPENSTACK_BRANCH}'=='stable/newton'
    ...    neutron -v router-gateway-set ${router_name} ${external_network_name}
    ...    openstack router set ${router_name} --external-gateway ${external_network_name}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Should Be True    '${rc}' == '0'

Remove Interface
    [Documentation]    Remove Interface to the subnets.
    [Arguments]    ${router_name}    ${interface_name}
    ${output} =    OpenStack CLI    openstack router remove subnet ${router_name} ${interface_name}

Remove Gateway
    [Documentation]    Remove external gateway from the router.
    [Arguments]    ${router_name}
    BuiltIn.Log    openstack router unset ${router_name} --external-gateway

Update Router
    [Documentation]    Update the router with the command. Router name and command should be passed as argument.
    [Arguments]    ${router_name}    ${cmd}
    ${output} =    OpenStack CLI    openstack router set ${router_name} ${cmd}

Show Router
    [Documentation]    Show information of a given router. Router name and optional fields should be sent as arguments.
    [Arguments]    ${router_name}    ${options}
    ${output} =    OpenStack CLI    openstack router show ${router_name}

Delete Router
    [Documentation]    Delete Router and Interface to the subnets.
    [Arguments]    ${router_name}
    ${output} =    OpenStack CLI    openstack router delete ${router_name}

Get DumpFlows And Ovsconfig
    [Documentation]    Get the OvsConfig and Flow entries from OVS from the Openstack Node
    [Arguments]    ${conn_id}
    SSHLibrary.Switch Connection    ${conn_id}
    Utils.Write Commands Until Expected Prompt    ip -o link    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    ip -o addr    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    ip route    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    arp -an    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${nslist} =    Utils.Write Commands Until Expected Prompt
    ...    ip netns list | awk '{print $1}'
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{lines} =    Split To Lines    ${nslist}    end=-1
    FOR    ${line}    IN    @{lines}
        Utils.Write Commands Until Expected Prompt
        ...    sudo ip netns exec ${line} ip -o link
        ...    ${DEFAULT_LINUX_PROMPT_STRICT}
        Utils.Write Commands Until Expected Prompt
        ...    sudo ip netns exec ${line} ip -o addr
        ...    ${DEFAULT_LINUX_PROMPT_STRICT}
        Utils.Write Commands Until Expected Prompt
        ...    sudo ip netns exec ${line} ip route
        ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    END
    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl list Open_vSwitch    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl show br-int -OOpenFlow13
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl dump-flows br-int -OOpenFlow13
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl dump-groups br-int -OOpenFlow13
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl dump-group-stats br-int -OOpenFlow13
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}

Get Karaf Log Type From Test Start
    [Arguments]    ${ip}    ${test_name}    ${type}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    ${cmd} =    BuiltIn.Set Variable
    ...    sed '1,/ROBOT MESSAGE: Starting test ${test_name}/d' ${log_file} | grep '${type}'
    ${output} =    Utils.Run Command On Controller    ${ip}    ${cmd}    ${user}    ${password}    ${prompt}
    RETURN    ${output}

Get Karaf Log Types From Test Start
    [Arguments]    ${ip}    ${test_name}    ${types}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    FOR    ${type}    IN    @{types}
        OpenStackOperations.Get Karaf Log Type From Test Start
        ...    ${ip}
        ...    ${test_name}
        ...    ${type}
        ...    ${user}
        ...    ${password}
        ...    ${prompt}
        ...    ${log_file}
    END

Get Karaf Log Events From Test Start
    [Arguments]    ${test_name}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ${log_types} =    BuiltIn.Create List    ERROR    WARN    Exception
    IF    0 < ${NUM_ODL_SYSTEM}
        OpenStackOperations.Get Karaf Log Types From Test Start    ${ODL_SYSTEM_IP}    ${test_name}    ${log_types}
    END
    IF    1 < ${NUM_ODL_SYSTEM}
        OpenStackOperations.Get Karaf Log Types From Test Start    ${ODL_SYSTEM_2_IP}    ${test_name}    ${log_types}
    END
    IF    2 < ${NUM_ODL_SYSTEM}
        OpenStackOperations.Get Karaf Log Types From Test Start    ${ODL_SYSTEM_3_IP}    ${test_name}    ${log_types}
    END

Get ControlNode Connection
    SSHLibrary.Switch Connection    ${OS_CNTL_CONN_ID}
    RETURN    ${OS_CNTL_CONN_ID}

Get OvsDebugInfo
    [Documentation]    Get the OvsConfig and Flow entries from all Openstack nodes
    IF    0 < ${NUM_OS_SYSTEM}
        OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CNTL_CONN_ID}
    END
    IF    1 < ${NUM_OS_SYSTEM}
        OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    END
    IF    2 < ${NUM_OS_SYSTEM}
        OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP2_CONN_ID}
    END

Get Test Teardown Debugs
    [Arguments]    ${test_name}=${TEST_NAME}
    OpenStackOperations.Get OvsDebugInfo
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${HA_PROXY_IP}    ${netvirt_data_models}
    OpenStackOperations.Get Karaf Log Events From Test Start    ${test_name}

Get Test Teardown Debugs For SFC
    [Arguments]    ${test_name}=${TEST_NAME}
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${HA_PROXY_IP}    ${netvirt_sfc_data_models}

Show Debugs
    [Documentation]    Run these commands for debugging, it can list state of VM instances and ip information in control node
    [Arguments]    @{vm_indices}
    OpenStackOperations.Get ControlNode Connection
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo ip netns list
    FOR    ${index}    IN    @{vm_indices}
        ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    nova show ${index}
        BuiltIn.Log    ${output}
    END
    OpenStackOperations.List Nova VMs
    OpenStackOperations.List Routers
    OpenStackOperations.List Networks
    OpenStackOperations.List Subnets
    OpenStackOperations.List Ports
    OpenStackOperations.List Security Groups

List Security Groups
    [Documentation]    Logging keyword to display all security groups using the openstack cli. Assumes openstack
    ...    credentials are already sourced
    ${output} =    OpenStack CLI    openstack security group list
    RETURN    ${output}

Neutron Security Group Show
    [Documentation]    Displays the neutron security group configurations that belongs to a given neutron security group name
    [Arguments]    ${SecurityGroupRuleName}
    ${output} =    OpenStack CLI    openstack security group show ${SecurityGroupRuleName}
    RETURN    ${output}

Neutron Port Show
    [Documentation]    Display the port configuration that belong to a given neutron port
    [Arguments]    ${PortName}
    ${output} =    OpenStack CLI    openstack port show ${PortName}
    RETURN    ${output}

Neutron Security Group Create
    [Documentation]    Create a security group with specified name ,description & protocol value according to security group template
    [Arguments]    ${SecurityGroupName}    ${additional_args}=${EMPTY}
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStack CLI    openstack security group create ${SecurityGroupName} ${additional_args}
    ${sgp_id} =    BuiltIn.Should Match Regexp    ${output}    ${REGEX_UUID}
    RETURN    ${output}    ${sgp_id}

Neutron Security Group Update
    [Documentation]    Updating security groups
    [Arguments]    ${SecurityGroupName}    ${additional_args}=${EMPTY}
    ${output} =    OpenStack CLI    openstack security group set ${SecurityGroupName} ${additional_args}
    RETURN    ${output}

Delete SecurityGroup
    [Documentation]    Delete Security group
    [Arguments]    ${sg_name}
    ${output} =    OpenStack CLI    openstack security group delete ${sg_name}

Neutron Security Group Rule Create
    [Documentation]    Creates neutron security rule with Openstack CLI with or without optional params, here security group name is mandatory args, rule with optional params can be created by passing the optional args values ex: direction=${INGRESS_EGRESS}, Then these optional params are BuiltIn.Catenated with mandatory args, example of usage: "OpenStack Neutron Security Group Rule Create ${SGP_SSH} direction=${RULE_PARAMS[0]} ethertype=${RULE_PARAMS[1]} ..."
    [Arguments]    ${Security_group_name}    &{Kwargs}
    IF    ${Kwargs}    BuiltIn.Log    ${Kwargs}
    IF    ${Kwargs}
        ${description} =    Collections.Pop From Dictionary    ${Kwargs}    description    default=${None}
    ELSE
        ${description} =    Set Variable    ${None}
    END
    IF    ${Kwargs}
        ${direction} =    Collections.Pop From Dictionary    ${Kwargs}    direction    default=${None}
    ELSE
        ${direction} =    Set Variable    ${None}
    END
    IF    ${Kwargs}
        ${ethertype} =    Collections.Pop From Dictionary    ${Kwargs}    ethertype    default=${None}
    ELSE
        ${ethertype} =    Set Variable    ${None}
    END
    IF    ${Kwargs}
        ${port_range_max} =    Collections.Pop From Dictionary    ${Kwargs}    port_range_max    default=${None}
    ELSE
        ${port_range_max} =    Set Variable    ${None}
    END
    IF    ${Kwargs}
        ${port_range_min} =    Collections.Pop From Dictionary    ${Kwargs}    port_range_min    default=${None}
    ELSE
        ${port_range_min} =    Set Variable    ${None}
    END
    IF    ${Kwargs}
        ${protocol} =    Collections.Pop From Dictionary    ${Kwargs}    protocol    default=${None}
    ELSE
        ${protocol} =    Set Variable    ${None}
    END
    IF    ${Kwargs}
        ${remote_group_id} =    Collections.Pop From Dictionary    ${Kwargs}    remote_group_id    default=${None}
    ELSE
        ${remote_group_id} =    Set Variable    ${None}
    END
    IF    ${Kwargs}
        ${remote_ip_prefix} =    Collections.Pop From Dictionary    ${Kwargs}    remote_ip_prefix    default=${None}
    ELSE
        ${remote_ip_prefix} =    Set Variable    ${None}
    END
    ${cmd} =    BuiltIn.Set Variable    openstack security group rule create ${Security_group_name}
    IF    '${description}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --description ${description}
    ELSE
        ${cmd} =    BuiltIn.Catenate    ${cmd}
    END
    IF    '${direction}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --${direction}
    ELSE
        ${cmd} =    BuiltIn.Catenate    ${cmd}
    END
    IF    '${ethertype}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --ethertype ${ethertype}
    ELSE
        ${cmd} =    BuiltIn.Catenate    ${cmd}
    END
    IF    '${port_range_min}'!='None' and '${port_range_max}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --dst-port ${port_range_min}:${port_range_max}
    ELSE IF    '${port_range_max}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --dst-port ${port_range_max}
    ELSE IF    '${port_range_min}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --dst-port ${port_range_min}
    ELSE
        ${cmd} =    BuiltIn.Catenate    ${cmd}
    END
    IF    '${protocol}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --protocol ${protocol}
    ELSE
        ${cmd} =    BuiltIn.Catenate    ${cmd}
    END
    IF    '${remote_group_id}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --remote-group ${remote_group_id}
    ELSE
        ${cmd} =    BuiltIn.Catenate    ${cmd}
    END
    IF    '${remote_ip_prefix}'!='None'
        ${cmd} =    BuiltIn.Catenate    ${cmd}    --src-ip ${remote_ip_prefix}
    ELSE
        ${cmd} =    BuiltIn.Catenate    ${cmd}
    END
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    ${rule_id} =    BuiltIn.Should Match Regexp    ${output}    ${REGEX_UUID}
    BuiltIn.Log    ${rule_id}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}    ${rule_id}

Security Group Create Without Default Security Rules
    [Documentation]    Create Neutron Security Group with no default rules, using specified name and optional arguments.
    [Arguments]    ${sg_name}    ${additional_args}=${EMPTY}
    OpenStackOperations.Neutron Security Group Create    ${sg_name}    ${additional_args}
    Delete All Security Group Rules    ${sg_name}

Delete All Security Group Rules
    [Documentation]    Delete all security rules from a specified security group
    [Arguments]    ${sg_name}
    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list ${sg_name} -cID -fvalue
    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
    FOR    ${rule}    IN    @{sg_rules}
        ${output} =    OpenStack CLI    openstack security group rule delete ${rule}
    END

Create Allow All SecurityGroup
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    [Arguments]    ${sg_name}    ${ether_type}=IPv4
    OpenStackOperations.Neutron Security Group Create    ${sg_name}
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg_name}
    ...    direction=ingress
    ...    ethertype=${ether_type}
    ...    port_range_max=65535
    ...    port_range_min=1
    ...    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg_name}
    ...    direction=egress
    ...    ethertype=${ether_type}
    ...    port_range_max=65535
    ...    port_range_min=1
    ...    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg_name}
    ...    direction=ingress
    ...    ethertype=${ether_type}
    ...    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg_name}
    ...    direction=egress
    ...    ethertype=${ether_type}
    ...    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg_name}
    ...    direction=ingress
    ...    ethertype=${ether_type}
    ...    port_range_max=65535
    ...    port_range_min=1
    ...    protocol=udp
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg_name}
    ...    direction=egress
    ...    ethertype=${ether_type}
    ...    port_range_max=65535
    ...    port_range_min=1
    ...    protocol=udp

Create Neutron Port With Additional Params
    [Documentation]    Create Port With given additional parameters
    [Arguments]    ${network_name}    ${port_name}    ${additional_args}=${EMPTY}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output
    ...    neutron -v port-create ${network_name} --name ${port_name} ${additional_args}
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    ${port_id} =    BuiltIn.Should Match Regexp    ${OUTPUT}    ${REGEX_UUID}
    RETURN    ${OUTPUT}    ${port_id}

Get Ports MacAddr
    [Documentation]    Retrieve the port MacAddr for the given list of port name and return the MAC address list.
    [Arguments]    ${ports}
    ${macs} =    BuiltIn.Create List
    FOR    ${port}    IN    @{ports}
        ${mac} =    OpenStackOperations.Get Port Mac    ${port}
        Collections.Append To List    ${macs}    ${mac}
    END
    RETURN    ${macs}

Get Port Ip
    [Documentation]    Keyword would return the IP of the ${port_name} received.
    [Arguments]    ${port_name}
    ${output} =    OpenStack CLI    openstack port list | grep "${port_name}" | awk -F\\' '{print $2}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${port_ip} =    Collections.Get from List    ${splitted_output}    0
    RETURN    ${port_ip}

Get Port Mac
    [Documentation]    Keyword would return the MAC ID of the ${port_name} received.
    [Arguments]    ${port_name}
    ${output} =    OpenStack CLI    openstack port show ${port_name} | grep mac_address | awk '{print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${port_mac} =    Collections.Get from List    ${splitted_output}    0
    RETURN    ${port_mac}

Create L2Gateway
    [Documentation]    Keyword to create an L2 Gateway ${gw_name} for bridge ${bridge_name} connected to interface ${intf_name} (Using Neutron CLI).
    [Arguments]    ${bridge_name}    ${intf_name}    ${gw_name}
    ${rc}    ${l2gw_output} =    OperatingSystem.Run And Return Rc And Output
    ...    ${L2GW_CREATE} name=${bridge_name},interface_names=${intf_name} ${gw_name}
    BuiltIn.Log    ${l2gw_output}
    RETURN    ${l2gw_output}

Update L2Gateway
    [Documentation]    Keyword to add {intf_name_list} to an existing L2 Gateway ${gw_name} (Using Neutron CLI).
    [Arguments]    ${bridge_name}    ${gw_name}    ${intf_name_1}    ${intf_name_2}
    ${rc}    ${l2gw_output} =    Run And Return Rc And Output
    ...    ${L2GW_UPDATE} name=${bridge_name},interface_names="${intf_name_1};${intf_name_2}" ${gw_name}
    Log    ${l2gw_output}
    RETURN    ${l2gw_output}

Create L2Gateway Connection
    [Documentation]    Keyword would create a new L2 Gateway Connection for ${gw_name} to ${net_name} (Using Neutron CLI).
    [Arguments]    ${gw_name}    ${net_name}
    ${rc}    ${l2gw_output} =    OperatingSystem.Run And Return Rc And Output
    ...    ${L2GW_CONN_CREATE} ${gw_name} ${net_name}
    BuiltIn.Log    ${l2gw_output}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${l2gw_output}

Get All L2Gateway
    [Documentation]    Keyword to return all the L2 Gateways available (Using Neutron CLI).
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_GET_YAML}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

Get All L2Gateway Connection
    [Documentation]    Keyword to return all the L2 Gateway connections available (Using Neutron CLI).
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_GET_CONN_YAML}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

Get L2Gateway
    [Documentation]    Keyword to check if the ${gw_id} is available in the L2 Gateway list (Using Neutron CLI).
    [Arguments]    ${gw_id}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_SHOW} ${gw_id}
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

Get L2gw Id
    [Documentation]    Keyword to retrieve the L2 Gateway ID for the ${l2gw_name} (Using Neutron CLI).
    [Arguments]    ${l2gw_name}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output
    ...    ${L2GW_GET} | grep "${l2gw_name}" | awk '{print $2}'
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${l2gw_id} =    Collections.Get from List    ${splitted_output}    0
    RETURN    ${l2gw_id}

Get L2gw Connection Id
    [Documentation]    Keyword to retrieve the L2 Gateway Connection ID for the ${l2gw_name} (Using Neutron CLI).
    [Arguments]    ${l2gw_name}
    ${l2gw_id} =    OpenStackOperations.Get L2gw Id    ${l2gw_name}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output
    ...    ${L2GW_GET_CONN} | grep "${l2gw_id}" | awk '{print $2}'
    BuiltIn.Should Be True    '${rc}' == '0'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${l2gw_conn_id} =    Collections.Get from List    ${splitted_output}    0
    RETURN    ${l2gw_conn_id}

Neutron Port List Rest
    [Documentation]    Keyword to get all ports details in Neutron (Using REST).
    ${resp} =    RequestsLibrary.Get Request    session    ${PORT_URL}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    RETURN    ${resp.content}

Get Neutron Port Rest
    [Documentation]    Keyword to get the specific port details in Neutron (Using REST).
    [Arguments]    ${port_id}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/${GET_PORT_URL}/${port_id}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    RETURN    ${resp.content}

Update Port Rest
    [Documentation]    Keyword to update ${port_id} with json data received in ${json_data} (Using REST).
    [Arguments]    ${port_id}    ${json_data}
    BuiltIn.Log    ${json_data}
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_API}/${GET_PORT_URL}/${port_id}    ${json_data}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    RETURN    ${resp.content}

Create And Configure Security Group
    [Documentation]    Create Security Group with given name, and default allow rules for TCP/UDP/ICMP protocols.
    [Arguments]    ${sg-name}
    OpenStackOperations.Neutron Security Group Create    ${sg-name}
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg-name}
    ...    direction=ingress
    ...    port_range_max=65535
    ...    port_range_min=1
    ...    protocol=tcp
    ...    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg-name}
    ...    direction=egress
    ...    port_range_max=65535
    ...    port_range_min=1
    ...    protocol=tcp
    ...    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg-name}
    ...    direction=ingress
    ...    protocol=icmp
    ...    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg-name}
    ...    direction=egress
    ...    protocol=icmp
    ...    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg-name}
    ...    direction=ingress
    ...    port_range_max=65535
    ...    port_range_min=1
    ...    protocol=udp
    ...    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create
    ...    ${sg-name}
    ...    direction=egress
    ...    port_range_max=65535
    ...    port_range_min=1
    ...    protocol=udp
    ...    remote_ip_prefix=0.0.0.0/0

Add Security Group To VM
    [Documentation]    Add the security group provided to the given VM.
    [Arguments]    ${vm}    ${sg}
    ${output} =    OpenStack CLI    openstack server add security group ${vm} ${sg}

Remove Security Group From VM
    [Documentation]    Remove the security group provided to the given VM.
    [Arguments]    ${vm}    ${sg}
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStack CLI    openstack server remove security group ${vm} ${sg}

Create SFC Flow Classifier
    [Documentation]    Create a flow classifier for SFC
    [Arguments]    ${name}    ${src_ip}    ${dest_ip}    ${protocol}    ${dest_port}    ${neutron_src_port}
    ${output} =    OpenStack CLI
    ...    openstack sfc flow classifier create --ethertype IPv4 --source-ip-prefix ${src_ip}/32 --destination-ip-prefix ${dest_ip}/32 --protocol ${protocol} --destination-port ${dest_port}:${dest_port} --logical-source-port ${neutron_src_port} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    RETURN    ${output}

Delete SFC Flow Classifier
    [Documentation]    Delete a SFC flow classifier
    [Arguments]    ${name}
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStack CLI    openstack sfc flow classifier delete ${name}
    RETURN    ${output}

Create SFC Port Pair
    [Documentation]    Creates a neutron port pair for SFC
    [Arguments]    ${name}    ${port_in}    ${port_out}
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStack CLI    openstack sfc port pair create --ingress=${port_in} --egress=${port_out} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    RETURN    ${output}

Delete SFC Port Pair
    [Documentation]    Delete a SFC port pair
    [Arguments]    ${name}
    ${output} =    OpenStack CLI    openstack sfc port pair delete ${name}
    RETURN    ${output}

Create SFC Port Pair Group
    [Documentation]    Creates a port pair group with a single port pair for SFC
    [Arguments]    ${name}    ${port_pair}
    ${output} =    OpenStack CLI    openstack sfc port pair group create --port-pair ${port_pair} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    RETURN    ${output}

Create SFC Port Pair Group With Two Pairs
    [Documentation]    Creates a port pair group with two port pairs for SFC
    [Arguments]    ${name}    ${port_pair1}    ${port_pair2}
    ${output} =    OpenStack CLI
    ...    openstack sfc port pair group create --port-pair ${port_pair1} --port-pair ${port_pair2} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    RETURN    ${output}

Delete SFC Port Pair Group
    [Documentation]    Delete a SFC port pair group
    [Arguments]    ${name}
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStack CLI    openstack sfc port pair group delete ${name}
    RETURN    ${output}

Create SFC Port Chain
    [Documentation]    Creates a port pair chain with two port groups and a singel classifier.
    [Arguments]    ${name}    ${pg1}    ${pg2}    ${fc}
    ${output} =    OpenStack CLI
    ...    openstack sfc port chain create --port-pair-group ${pg1} --port-pair-group ${pg2} --flow-classifier ${fc} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    RETURN    ${output}

Delete SFC Port Chain
    [Documentation]    Delete a SFC port chain
    [Arguments]    ${name}
    ${output} =    OpenStack CLI    openstack sfc port chain delete ${name}
    RETURN    ${output}

Reboot Nova VM
    [Documentation]    Reboot NOVA VM
    [Arguments]    ${vm_name}
    ${output} =    OpenStack CLI    openstack server reboot --wait ${vm_name}
    BuiltIn.Wait Until Keyword Succeeds    35s    10s    OpenStackOperations.Verify VM Is ACTIVE    ${vm_name}

Remove RSA Key From KnownHosts
    [Documentation]    Remove RSA
    [Arguments]    ${vm_ip}
    OpenStackOperations.Get ControlNode Connection
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo cat /root/.ssh/known_hosts    30s
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log
    ...    sudo ssh-keygen -f "/root/.ssh/known_hosts" -R ${vm_ip}
    ...    30s
    ${output} =    DevstackUtils.Write Commands Until Prompt    sudo cat "/root/.ssh/known_hosts"    30s

Wait For Routes To Propogate
    [Documentation]    Check propagated routes
    [Arguments]    ${networks}    ${subnets}
    OpenStackOperations.Get ControlNode Connection
    FOR    ${INDEX}    IN RANGE    0    1
        ${net_id} =    OpenStackOperations.Get Net Id    ${networks}[${INDEX}]
        ${is_ipv6} =    String.Get Regexp Matches    ${subnets}[${INDEX}]    ${IP6_REGEX}
        ${length} =    BuiltIn.Get Length    ${is_ipv6}
        ${cmd} =    BuiltIn.Set Variable If    ${length} == 0    ip route    ip -6 route
        ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ${cmd}    ]>
        BuiltIn.Should Contain    ${output}    ${subnets}[${INDEX}]
    END

Neutron Cleanup
    [Arguments]    ${vms}=@{EMPTY}    ${networks}=@{EMPTY}    ${subnets}=@{EMPTY}    ${ports}=@{EMPTY}    ${sgs}=@{EMPTY}
    FOR    ${vm}    IN    @{vms}
        BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    ${vm}
    END
    FOR    ${port}    IN    @{ports}
        BuiltIn.Run Keyword And Ignore Error    Delete Port    ${port}
    END
    FOR    ${subnet}    IN    @{subnets}
        BuiltIn.Run Keyword And Ignore Error    Delete SubNet    ${subnet}
    END
    FOR    ${network}    IN    @{networks}
        BuiltIn.Run Keyword And Ignore Error    Delete Network    ${network}
    END
    FOR    ${sg}    IN    @{sgs}
        BuiltIn.Run Keyword And Ignore Error    Delete SecurityGroup    ${sg}
    END

OpenStack List All
    [Documentation]    Get a list of different OpenStack resources that might be in use.
    @{modules} =    BuiltIn.Create List    server    port    network    subnet    security group
    ...    security group rule    floating ip    router
    FOR    ${module}    IN    @{modules}
        ${output} =    OpenStack CLI    openstack ${module} list
    END

OpenStack CLI Get List
    [Documentation]    Return a json list from the output of an OpenStack command.
    [Arguments]    ${cmd}
    @{list} =    BuiltIn.Create List
    ${json} =    OpenStack CLI    ${cmd}
    @{list} =    RequestsLibrary.To Json    ${json}
    BuiltIn.Log    ${list}
    RETURN    @{list}

OpenStack CLI
    [Documentation]    Run the given OpenStack ${cmd} and log the output.
    [Arguments]    ${cmd}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

OpenStack CLI With No Log
    [Documentation]    Run the given OpenStack ${cmd} and do not log the output.
    [Arguments]    ${cmd}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

OpenStack Cleanup All
    [Documentation]    Cleanup all Openstack resources with best effort. The keyword will query for all resources
    ...    in use and then attempt to delete them. Errors are ignored to allow the cleanup to continue.
    @{fips} =    OpenStack CLI Get List    openstack floating ip list -f json
    FOR    ${fip}    IN    @{fips}
        BuiltIn.Run Keyword And Ignore Error    Delete Floating IP    ${fip['ID']}
    END
    @{vms} =    OpenStack CLI Get List    openstack server list -f json
    FOR    ${vm}    IN    @{vms}
        BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    ${vm['ID']}
    END
    @{routers} =    OpenStack CLI Get List    openstack router list -f json
    FOR    ${router}    IN    @{routers}
        BuiltIn.Run Keyword And Ignore Error    Cleanup Router    ${router['ID']}
    END
    @{ports} =    OpenStack CLI Get List    openstack port list -f json
    FOR    ${port}    IN    @{ports}
        BuiltIn.Run Keyword And Ignore Error    Delete Port    ${port['ID']}
    END
    @{networks} =    OpenStack CLI Get List    openstack network list -f json
    FOR    ${network}    IN    @{networks}
        BuiltIn.Run Keyword And Ignore Error    Delete Subnet    ${network['Subnets']}
        BuiltIn.Run Keyword And Ignore Error    Delete Network    ${network['ID']}
    END
    @{security_groups} =    OpenStack CLI Get List    openstack security group list -f json
    FOR    ${security_group}    IN    @{security_groups}
        IF    "${security_group['Name']}" != "default"
            BuiltIn.Run Keyword And Ignore Error    Delete SecurityGroup    ${security_group['ID']}
        END
    END
    OpenStack List All

Cleanup Router
    [Documentation]    Delete a router, but first remove any interfaces or gateways so that the delete will be successful.
    [Arguments]    ${id}
    @{ports} =    OpenStack CLI Get List    openstack port list --router ${id} -f json --long
    FOR    ${port}    IN    @{ports}
        ${subnet_id} =    OpenStackOperations.Get Match    ${port['Fixed IP Addresses']}    ${REGEX_UUID}    0
        IF    "${port['Device Owner']}" == "network:router_gateway"
            BuiltIn.Run Keyword And Ignore Error    Remove Gateway    ${id}
        END
        IF    "${port['Device Owner']}" == "network:router_interface"
            BuiltIn.Run Keyword And Ignore Error    Remove Interface    ${id}    ${subnet_id}
        END
    END
    BuiltIn.Run Keyword And Ignore Error    Delete Router    ${id}

OpenStack Suite Setup
    [Documentation]    Wrapper teardown keyword that can be used in any suite running in an openstack environement
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    @{tcpdump_port_6653_conn_ids} =    OpenStackOperations.Start Packet Capture On Nodes
    ...    tcpdump_port_6653
    ...    port 6653
    ...    @{OS_ALL_IPS}
    BuiltIn.Set Suite Variable    @{tcpdump_port_6653_conn_ids}
    IF    "${PRE_CLEAN_OPENSTACK_ALL}"=="True"    OpenStack Cleanup All
    OpenStackOperations.Add OVS Logging On All OpenStack Nodes

OpenStack Suite Teardown
    [Documentation]    Wrapper teardown keyword that can be used in any suite running in an openstack environement
    ...    to clean up all openstack resources. For example, all instances, networks, ports, etc will be listed and
    ...    and deleted. As other global cleanup tasks are needed, they can be added here and the suites will all
    ...    benefit automatically.
    OpenStack Cleanup All
    OpenStackOperations.Stop Packet Capture On Nodes    ${tcpdump_port_6653_conn_ids}
    SSHLibrary.Close All Connections

Copy DHCP Files From Control Node
    [Documentation]    Copy the current DHCP files to the robot vm. The keyword must be called
    ...    after the subnet(s) are created and before the subnet(s) are deleted.
    ${suite_} =    BuiltIn.Evaluate    """${SUITE_NAME}""".replace(" ","_").replace("/","_").replace(".","_")
    ${dstdir} =    BuiltIn.Set Variable    /tmp/qdhcp/${suite_}
    OperatingSystem.Create Directory    ${dstdir}
    OpenStackOperations.Get ControlNode Connection
    BuiltIn.Run Keyword And Ignore Error
    ...    SSHLibrary.Get Directory
    ...    /opt/stack/data/neutron/dhcp
    ...    ${dstdir}
    ...    recursive=True

Is Feature Installed
    [Arguments]    ${features}=none
    FOR    ${feature}    IN    @{features}
        ${status}    ${output} =    BuiltIn.Run Keyword And Ignore Error
        ...    BuiltIn.Should Contain
        ...    ${CONTROLLERFEATURES}
        ...    ${feature}
        IF    "${status}" == "PASS"    RETURN    True
    END
    RETURN    False

Add OVS Logging On All OpenStack Nodes
    [Documentation]    Add higher levels of OVS logging to all the OpenStack nodes
    IF    0 < ${NUM_OS_SYSTEM}    OVSDB.Add OVS Logging    ${OS_CNTL_CONN_ID}
    IF    1 < ${NUM_OS_SYSTEM}    OVSDB.Add OVS Logging    ${OS_CMP1_CONN_ID}
    IF    2 < ${NUM_OS_SYSTEM}    OVSDB.Add OVS Logging    ${OS_CMP2_CONN_ID}

Reset OVS Logging On All OpenStack Nodes
    [Documentation]    Reset the OVS logging to all the OpenStack nodes
    IF    0 < ${NUM_OS_SYSTEM}    OVSDB.Reset OVS Logging    ${OS_CNTL_CONN_ID}
    IF    1 < ${NUM_OS_SYSTEM}    OVSDB.Reset OVS Logging    ${OS_CMP1_CONN_ID}
    IF    2 < ${NUM_OS_SYSTEM}    OVSDB.Reset OVS Logging    ${OS_CMP2_CONN_ID}

Start Packet Capture On Nodes
    [Documentation]    Wrapper keyword around the TcpDump packet capture that is catered to the Openstack setup.
    ...    The caller must pass the three arguments with a variable number of ips at the end,
    ...    but ${EMPTY} can be used for the tag and filter.
    [Arguments]    ${tag}    ${filter}    @{ips}
    ${suite_} =    BuiltIn.Evaluate    """${SUITE_NAME}""".replace(" ","_").replace("/","_").replace(".","_")
    ${tag_} =    BuiltIn.Catenate    SEPARATOR=__    ${tag}    ${suite_}
    @{conn_ids} =    Tcpdump.Start Packet Capture on Nodes    tag=${tag_}    filter=${filter}    ips=${ips}
    RETURN    @{conn_ids}

Stop Packet Capture On Nodes
    [Arguments]    ${conn_ids}=@{EMPTY}
    Tcpdump.Stop Packet Capture on Nodes    ${conn_ids}

Create Project
    [Arguments]    ${domain}    ${description}    ${name}    ${rc_file}=${EMPTY}
    IF    "${rc_file}" != "${EMPTY}"
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    source ${rc_file};openstack project create --domain ${domain} --description {description} ${name}
    ELSE
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    openstack project create --domain ${domain} --description {description} ${name}
    END
    Log    ${output}
    Should Not Be True    ${rc}

Create Service
    [Arguments]    ${name}    ${description}    ${category}    ${rc_file}=${EMPTY}
    IF    "${rc_file}" != "${EMPTY}"
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    source ${rc_file};openstack service create --name ${name} --description ${description} ${category}
    ELSE
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    openstack service create --name ${name} --description ${description} ${category}
    END
    Log    ${output}
    Should Not Be True    ${rc}

Create Image
    [Arguments]    ${name}    ${file_path}    ${rc_file}=${EMPTY}
    IF    "${rc_file}" != "${EMPTY}"
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    source ${rc_file};openstack image create ${name} --file ${file_path} --disk-format qcow2 --container-format bare --public
    ELSE
        ${rc}    ${output} =    Set Variable    ${None}    ${None}
    END
    Log    ${output}
    Should Not Be True    ${rc}

Create Flavor
    [Arguments]    ${name}    ${ram}    ${disk}    ${rc_file}=${EMPTY}
    IF    "${rc_file}" != "${EMPTY}"
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    source ${rc_file};openstack flavor create ${name} --ram ${ram} --disk ${disk}
    ELSE
        ${rc}    ${output} =    Set Variable    ${None}    ${None}
    END
    Log    ${output}
    Should Not Be True    ${rc}

Create Keypair
    [Arguments]    ${keypair_name}    ${key_path}    ${rc_file}=${EMPTY}
    IF    "${rc_file}" != "${EMPTY}"
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    source ${rc_file};openstack keypair create ${keypair_name} --public-key ${key_path}.pub
    ELSE
        ${rc}    ${output} =    Set Variable    ${None}    ${None}
    END
    Log    ${output}
    Should Not Be True    ${rc}
