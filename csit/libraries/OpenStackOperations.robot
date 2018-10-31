*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           Collections
Library           Process
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          DataModels.robot
Resource          DevstackUtils.robot
Resource          KarafKeywords.robot
Resource          L2GatewayOperations.robot
Resource          ODLTools.robot
Resource          OVSDB.robot
Resource          SetupUtils.robot
Resource          SSHKeywords.robot
Resource          Tcpdump.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot
Variables         ../variables/netvirt/Modules.py

*** Keywords ***
Get Tenant ID From Security Group
    [Documentation]    Returns tenant ID by reading it from existing default security-group.
    ${output} =    OpenStack CLI    openstack security group show default | grep "| tenant_id" | awk '{print $4}'
    [Return]    ${output}

Get Tenant ID From Network
    [Arguments]    ${network_uuid}
    [Documentation]    Returns tenant ID by reading it from existing network.
    ${resp} =    TemplatedRequests.Get_From_Uri    uri=${CONFIG_API}/neutron:neutron/networks/network/${network_uuid}/    accept=${ACCEPT_EMPTY}    session=session
    ${tenant_id} =    Utils.Extract Value From Content    ${resp}    /network/0/tenant-id    strip
    [Return]    ${tenant_id}

Create Network
    [Arguments]    ${network_name}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Network with openstack request.
    ${output} =    OpenStack CLI    openstack network create ${network_name} ${additional_args}
    [Return]    ${output}

Update Network
    [Arguments]    ${network_name}    ${additional_args}=${EMPTY}
    [Documentation]    Update Network with neutron request.
    ${output} =    OpenStack CLI    openstack network set ${network_name} ${additional_args}
    [Return]    ${output}

Show Network
    [Arguments]    ${network_name}
    [Documentation]    Show Network with neutron request.
    ${output} =    OpenStack CLI    openstack network show ${network_name}
    [Return]    ${output}

List Networks
    [Documentation]    List networks and return output with neutron client.
    ${output} =    OpenStack CLI    openstack network list
    [Return]    ${output}

List Subnets
    [Documentation]    List subnets and return output with neutron client.
    ${output} =    OpenStack CLI    openstack subnet list
    [Return]    ${output}

Delete Network
    [Arguments]    ${network_name}
    [Documentation]    Delete Network with neutron request.
    ${output} =    OpenStack CLI    openstack network delete ${network_name}

Create SubNet
    [Arguments]    ${network_name}    ${subnet_name}    ${range_ip}    ${additional_args}=${EMPTY}
    [Documentation]    Create SubNet for the Network with neutron request.
    ${output} =    OpenStack CLI    openstack subnet create --network ${network_name} --subnet-range ${range_ip} ${subnet_name} ${additional_args}

Update SubNet
    [Arguments]    ${subnet_name}    ${additional_args}=${EMPTY}
    [Documentation]    Update subnet with openstack subnet set request.
    ${output} =    OpenStack CLI    openstack subnet set ${subnet_name} ${additional_args}
    [Return]    ${output}

Unset SubNet
    [Arguments]    ${subnet_name}    ${additional_args}=${EMPTY}
    [Documentation]    Update subnet with openstack subnet unset request
    ${output} =    OpenStack CLI    openstack subnet unset ${subnet_name} ${additional_args}
    [Return]    ${output}

Show SubNet
    [Arguments]    ${subnet_name}
    [Documentation]    Show subnet with neutron request.
    ${output} =    OpenStack CLI    openstack subnet show ${subnet_name}
    [Return]    ${output}

Create Port
    [Arguments]    ${network_name}    ${port_name}    ${sg}=default    ${additional_args}=${EMPTY}    ${allowed_address_pairs}=${EMPTY}
    [Documentation]    Create Port with neutron request.
    # if allowed_address_pairs is not empty we need to create the arguments to pass to the port create command. They are
    # in a different format with the neutron vs openstack cli.
    ${address_pair_length} =    BuiltIn.Get Length    ${allowed_address_pairs}
    ${allowed_pairs_argv} =    BuiltIn.Set Variable    ${EMPTY}
    ${allowed_pairs_argv} =    BuiltIn.Set Variable If    '${address_pair_length}'=='2'    --allowed-address ip-address=@{allowed_address_pairs}[0] --allowed-address ip-address=@{allowed_address_pairs}[1]    ${allowed_pairs_argv}
    ${output} =    OpenStack CLI    openstack port create --network ${network_name} ${port_name} --security-group ${sg} ${additional_args} ${allowed_pairs_argv}

Update Port
    [Arguments]    ${port_name}    ${additional_args}=${EMPTY}
    [Documentation]    Update port with neutron request.
    ${output} =    OpenStack CLI    openstack port set ${port_name} ${additional_args}
    [Return]    ${output}

Show Port
    [Arguments]    ${port_name}
    [Documentation]    Show port with neutron request.
    ${output} =    OpenStack CLI    openstack port show ${port_name}
    [Return]    ${output}

Delete Port
    [Arguments]    ${port_name}
    [Documentation]    Delete Port with neutron request.
    ${output} =    OpenStack CLI    openstack port delete ${port_name}

List Ports
    [Documentation]    List ports and return output with neutron client.
    ${output} =    OpenStack CLI    openstack port list
    [Return]    ${output}

List Nova VMs
    [Documentation]    List VMs and return output with nova client.
    ${output} =    OpenStack CLI    openstack server list --all-projects
    [Return]    ${output}

Create And Associate Floating IPs
    [Arguments]    ${external_net}    @{vm_list}
    [Documentation]    Create and associate floating IPs to VMs with nova request
    ${ip_list} =    BuiltIn.Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${output} =    OpenStack CLI    openstack floating ip create ${external_net}
    \    @{ip} =    String.Get Regexp Matches    ${output}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${ip_length} =    BuiltIn.Get Length    ${ip}
    \    BuiltIn.Run Keyword If    ${ip_length}>0    Collections.Append To List    ${ip_list}    @{ip}[0]
    \    ...    ELSE    Collections.Append To List    ${ip_list}    None
    \    ${output} =    OpenStack CLI    openstack server add floating ip ${vm} @{ip}[0]
    [Return]    ${ip_list}

Remove Floating Ip From Vm
    [Arguments]    ${vm_name}    ${fip}
    [Documentation]    Remove the Floating IP From VM Instance
    ${output} =    OpenStack CLI    openstack server remove floating ip ${vm_name} ${fip}

Delete Floating IP
    [Arguments]    ${fip}
    [Documentation]    Delete floating ip with neutron request.
    ${output} =    OpenStack CLI    openstack floating ip delete ${fip}

Delete SubNet
    [Arguments]    ${subnet}
    [Documentation]    Delete SubNet for the Network with neutron request.
    ${output} =    OpenStack CLI    openstack subnet delete ${subnet}

Delete Vm Instance
    [Arguments]    ${vm_name}
    [Documentation]    Delete Vm instances using instance names.
    ${output} =    OpenStack CLI    openstack server delete ${vm_name}

Get Net Id
    [Arguments]    ${network_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    ${output} =    OpenStack CLI    openstack network list | grep "${network_name}" | awk '{print $2}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${net_id} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${net_id}

Get Subnet Id
    [Arguments]    ${subnet_name}
    [Documentation]    Retrieve the subnet id for the given subnet name
    ${output} =    OpenStack CLI    openstack subnet show "${subnet_name}" | grep " id " | awk '{print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${subnet_id} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${subnet_id}

Get Port Id
    [Arguments]    ${port_name}
    [Documentation]    Retrieve the port id for the given port name to attach specific vm instance to a particular port
    ${output} =    OpenStack CLI    openstack port list | grep "${port_name}" | awk '{print $2}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${port_id} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${port_id}

Get Sub Port Id
    [Arguments]    ${portname}
    [Documentation]    Retrieve the first 10 chars of the UUID for the given port name
    ${port_id} =    OpenStackOperations.Get Port Id    ${portname}
    ${output} =    String.Get Regexp Matches    ${port_id}    \\w{8}-\\w{2}
    ${subport_id} =    Collections.Get from List    ${output}    0
    [Return]    ${subport_id}

Get Router Id
    [Arguments]    ${router1}
    [Documentation]    Retrieve the router id for the given router name
    ${output} =    OpenStack CLI    openstack router show "${router1}" |awk '/ id / {print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${router_id} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${router_id}

Add New Image From Url
    [Arguments]    ${image_url}    ${image_name}
    [Documentation]    To add new qcow2 images for testing.
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    wget ${image_url} -O /tmp/new_image.qcow2
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    ${output} =    OpenStack CLI    openstack image create ${image_name} --file /tmp/new_image.qcow2 --disk-format qcow2 --container-format bare --public

Create Flavor
    [Arguments]    ${flavor_name}    ${ram_in_mb}    ${disk_in_gb}    ${ncpu}=1
    [Documentation]    To create new flavors for instance deployment and testing
    ${output} =    OpenStack CLI    openstack flavor create ${flavor_name} --ram ${ram_in_mb} --disk ${disk_in_gb} --vcpus ${ncpu}

Create Keypair
    [Arguments]    ${keyname}    ${public_key_file}
    [Documentation]    To add keypairs to Openstack that can be used when ssh to instances using publickey authentication
    ${output} =    OpenStack CLI    openstack keypair create ${keyname} --public-key ${public_key_file}

Generate And Add Keypair
    [Arguments]    ${keyname}    ${keyfilename}
    [Documentation]    To generate keypair using ssh-keygen and add them to Openstack
    ${result} =    Process.Run Process    ssh-keygen -b 2048 -t rsa -f ${JENKINS_WORKSPACE}/${keyfilename} -q -N ""    shell=True
    BuiltIn.Log    ${result.stdout}
    BuiltIn.Log    ${result.stderr}
    BuiltIn.Should Be True    '${result.rc}' == '0'
    OpenStackOperations.Create Keypair    ${keyname}    ${JENKINS_WORKSPACE}/${keyfilename}.pub
    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Put_File    ${JENKINS_WORKSPACE}/${keyfilename}    /tmp

Create Vm Instances
    [Arguments]    ${net_name}    ${vm_instance_names}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default    ${min}=1
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    ..    ${max}=1
    ${image}    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    : FOR    ${vm}    IN    @{vm_instance_names}
    \    ${output} =    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --nic net-id=${net_id} ${vm} --security-group ${sg} --min ${min} --max ${max}

Create Vm Instance On Compute Node
    [Arguments]    ${net_name}    ${vm_name}    ${node_hostname}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create a VM instance on a specific compute node.
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    OpenStack CLI    openstack server create ${vm_name} --image ${image} --flavor ${flavor} --nic net-id=${net_id} --security-group ${sg} --availability-zone nova:${node_hostname}

Create Vm Instance With Port
    [Arguments]    ${port_name}    ${vm_instance_name}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create One VM instance using given ${port_name} and for given ${compute_node}
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${output} =    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --port ${port_name} --security-group ${sg} ${vm_instance_name}

Create Vm Instance With Ports And Key On Compute Node
    [Arguments]    ${port1_name}    ${port2_name}    ${vm_instance_name}    ${node_hostname}    ${image}=${EMPTY}    ${flavor}=m1.nano
    ...    ${sg}=default    ${keyname}=${EMPTY}
    [Documentation]    Create One VM instance using given ${port1_name} and ${port2_name} with keyname for ssh and also on a specific compute node
    ${image}    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${output} =    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --port ${port1_name} --port ${port2_name} ${vm_instance_name} --security-group ${sg} --availability-zone nova:${node_hostname} --key-name ${keyname}

Create Vm Instance With Port On Compute Node
    [Arguments]    ${port_name}    ${vm_instance_name}    ${node_hostname}    ${image}=${EMPTY}    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create One VM instance using given ${port_name} and for given ${node_hostname}
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${output} =    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --port ${port_name} --security-group ${sg} --availability-zone nova:${node_hostname} ${vm_instance_name}

Remove Security Group From Vm Instance
    [Arguments]    ${vm_instance_name}    ${security_group}
    [Documentation]    Delete the Security Group from the VM Instance.
    ${output} =    OpenStack CLI    openstack server remove security group ${vm_instance_name} ${security_group}

Create Vm Instance With Ports On Compute Node
    [Arguments]    ${port1_name}    ${port2_name}    ${vm_instance_name}    ${node_hostname}    ${image}=${EMPTY}    ${flavor}=m1.nano
    ...    ${sg}=default
    [Documentation]    Create One VM instance using given ${port1_name}, ${port2_name} and for given ${node_hostname} with no keys (cirros like)
    ${image} =    BuiltIn.Set Variable If    "${image}"=="${EMPTY}"    ${CIRROS_${OPENSTACK_BRANCH}}    ${image}
    ${port1_id} =    OpenStackOperations.Get Port Id    ${port1_name}
    ${port2_id} =    OpenStackOperations.Get Port Id    ${port2_name}
    ${output} =    OpenStack CLI    openstack server create --image ${image} --flavor ${flavor} --nic port-id=${port1_id} --nic port-id=${port2_id} --security-group ${sg} --availability-zone nova:${node_hostname} ${vm_instance_name}

Get Hypervisor Hostname From IP
    [Arguments]    ${hypervisor_ip}
    [Documentation]    Returns the hostname found for the given IP address if it's listed in hypervisor list. For debuggability
    ...    the full listing is logged first, then followed by a grep | cut to focus on the actual hostname to return
    ${output} =    OpenStack CLI    openstack hypervisor list
    ${hostname} =    OpenStack CLI    openstack hypervisor list -f value | grep "${hypervisor_ip} " | cut -d" " -f 2
    [Return]    ${hostname}

Create Nano Flavor
    [Documentation]    Create a nano flavor
    ${output} =    OpenStack CLI    openstack flavor create m1.nano --id auto --ram 64 --disk 0 --vcpus 1

Verify VM Is ACTIVE
    [Arguments]    ${vm_name}
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    ${output} =    OpenStack CLI    openstack server show ${vm_name} | grep OS-EXT-STS:vm_state
    BuiltIn.Should Contain    ${output}    active

Poll VM Is ACTIVE
    [Arguments]    ${vm_name}    ${retry}=600s    ${retry_interval}=30s
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    BuiltIn.Wait Until Keyword Succeeds    ${retry}    ${retry_interval}    OpenStackOperations.Verify VM Is ACTIVE    ${vm_name}

Get Match
    [Arguments]    ${text}    ${regexp}    ${index}=0
    [Documentation]    Wrapper around String.Get Regexp Matches to return None if not found or the first match if found.
    @{matches} =    String.Get Regexp Matches    ${text}    ${regexp}
    ${matches_length} =    BuiltIn.Get Length    ${matches}
    BuiltIn.Set Suite Variable    ${OS_MATCH}    None
    BuiltIn.Run Keyword If    ${matches_length} > ${index}    BuiltIn.Set Suite Variable    ${OS_MATCH}    @{matches}[${index}]
    [Return]    ${OS_MATCH}

Get VM IP
    [Arguments]    ${fail_on_none}    ${vm}
    [Documentation]    Get the vm ip address and nameserver by scraping the vm's console log.
    ...    Get VM IP returns three values: [0] the vm IP, [1] the DHCP IP and [2] the vm console log.
    ${vm_console_output} =    OpenStack CLI With No Log    openstack console log show ${vm}
    ${vm_ip} =    BuiltIn.Set Variable    None
    ${dhcp_ip} =    BuiltIn.Set Variable    None
    ${match} =    OpenStackOperations.Get Match    ${vm_console_output}    ${REGEX_OBTAINED}
    ${vm_ip} =    OpenStackOperations.Get Match    ${match}    ${REGEX_IPV4}    0
    ${match} =    OpenStackOperations.Get Match    ${vm_console_output}    ${REGEX_IPROUTE}
    ${dhcp_ip} =    OpenStackOperations.Get Match    ${match}    ${REGEX_IPV4}    1
    BuiltIn.Run Keyword If    '${fail_on_none}' == 'true'    BuiltIn.Should Not Contain    ${vm_ip}    None
    BuiltIn.Run Keyword If    '${fail_on_none}' == 'true'    BuiltIn.Should Not Contain    ${dhcp_ip}    None
    [Return]    ${vm_ip}    ${dhcp_ip}    ${vm_console_output}

Verify If Instance Is Arpingable From DHCP Namespace
    [Arguments]    ${net_name}    ${mac}    ${ip}
    [Documentation]    Get the Port IP and check the arp -a from DHCP NS to ensure that the VM's have been assigned IP's
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} arping ${ip} -c3    ${DEFAULT_LINUX_PROMPT_STRICT}    timeout=60s
    ${mac_uppercase} =    String.Convert To Upper Case    ${mac}
    BuiltIn.Should Contain    ${output}    [${mac_uppercase}]

Check If Instance Is Ready For Ssh Login Using PublicKey
    [Arguments]    ${net_name}    ${vm_ip}    ${user}=centos    ${idfile}=/tmp/odlkey    ${console}=cirros
    [Documentation]    Ensure the VM is reachable from ssh as tests would require. This keyword will use publickey authentication
    ${output} =    Execute Command on VM Instance with PublicKey Auth    ${net_name}    ${vm_ip}    ifconfig    user=${user}    idfile=${idfile}
    ...    console=${console}
    BuiltIn.Should Contain    ${output}    ${vm_ip}

Check If Instance Is Ready For Ssh Login Using Password
    [Arguments]    ${net_name}    ${vm_ip}    ${user}=cirros    ${console}=cirros
    [Documentation]    Ensure the VM is reachable from ssh as tests would require. This keyword will use password authentication
    ${output} =    Execute Command on VM Instance    ${net_name}    ${vm_ip}    ifconfig    console=${console}
    BuiltIn.Should Contain    ${output}    ${vm_ip}

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
    \    OpenStackOperations.Poll VM Is ACTIVE    ${vm}
    \    ${status}    ${ips_and_console_log}    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    180s    15s
    \    ...    OpenStackOperations.Get VM IP    true    ${vm}
    \    # If there is trouble with Get VM IP, the status will be FAIL and the return value will be a string of what went
    \    # wrong. We need to handle both the PASS and FAIL cases. In the FAIL case we know we wont have access to the
    \    # console log, as it would not be returned; so we need to grab it again to log it. We also can append 'None' to
    \    # the vm ip list if status is FAIL.
    \    BuiltIn.Run Keyword If    "${status}" == "PASS"    BuiltIn.Log    ${ips_and_console_log[2]}
    \    BuiltIn.Run Keyword If    "${status}" == "PASS"    Collections.Append To List    ${vm_ips}    ${ips_and_console_log[0]}
    \    BuiltIn.Run Keyword If    "${status}" == "FAIL"    Collections.Append To List    ${vm_ips}    None
    \    ${vm_console_output} =    BuiltIn.Run Keyword If    "${status}" == "FAIL"    OpenStack CLI    openstack console log show ${vm}
    \    BuiltIn.Run Keyword If    "${status}" == "FAIL"    BuiltIn.Log    ${vm_console_output}
    OpenStackOperations.Copy DHCP Files From Control Node
    [Return]    @{vm_ips}    ${ips_and_console_log[1]}

Get Subnet Gateway Ip
    [Arguments]    ${subnet_name}
    [Documentation]    Show information of a subnet and grep for subnet gateway ip address
    ${output} =    OpenStackOperations.OpenStack CLI    openstack subnet show ${subnet_name} | grep gateway_ip | awk '{print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${matches} =    Collections.Get Matches    ${splitted_output}    regexp=(\\d\.)+
    ${subnet_gateway_ip} =    String.Strip String    ${matches[0]}    characters=','
    [Return]    ${subnet_gateway_ip}

Collect VM IPv6 SLAAC Addresses
    [Arguments]    ${fail_on_none}    ${vm_list}    ${network}    ${subnet}
    [Documentation]    For each VM parse output of "openstack server show" to get its IPv6 address from Neutron DB.
    ...    Then try to connect to each VM by SSH and execute there "ip -6 a" command. This double-check allows to
    ...    obtain and compare IP info (Neutron DB vs dnsmasque/ODL DHCP) and to test L2 connectivity as well.
    ...    Returns an empty list if no IPv6 addresses found or if SSH connection fails.
    ...    Otherwise, returns a list of IPv6 addresses.
    ${ipv6_list} =    BuiltIn.Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${output} =    OpenStack CLI    openstack server show ${vm} -f shell
    \    ${pattern} =    String.Replace String    ${subnet}    ::/64    (:[a-f0-9]{,4}){,4}
    \    @{vm_ipv6} =    String.Get Regexp Matches    ${output}    ${pattern}
    \    ${vm_ip_length} =    BuiltIn.Get Length    ${vm_ipv6}[0]
    \    ${ipv6_data_from_vm} =    BuiltIn.Run Keyword If    ${vm_ip_length}>0    OpenStackOperations.Execute Command on VM Instance    ${network}    ${vm_ipv6[0]}
    \    ...    ip -6 a
    \    @{ipv6} =    String.Get Regexp Matches    ${ipv6_data_from_vm}    ${pattern}
    \    ${ipv6_addr_list_length}    BuiltIn.Get Length    @{ipv6}
    \    BuiltIn.Run Keyword If    ${ipv6_addr_list_length}>0    Collections.Append To List    ${ipv6_list}    ${ipv6[0]}
    \    ...    ELSE    Collections.Append To List    ${ipv6_list}    None
    [Return]    ${ipv6_list}

View Vm Console
    [Arguments]    ${vm_instance_names}
    [Documentation]    View Console log of the created vm instances using nova show.
    : FOR    ${vm}    IN    @{vm_instance_names}
    \    ${output} =    OpenStack CLI    openstack server show ${vm}
    \    ${output} =    OpenStack CLI    openstack console log show ${vm}

Ping Vm From DHCP Namespace
    [Arguments]    ${net_name}    ${vm_ip}
    [Documentation]    Reach all Vm Instance with the net id of the Netowrk.
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}    20s
    BuiltIn.Should Contain    ${output}    64 bytes

Ping From DHCP Should Not Succeed
    [Arguments]    ${net_name}    ${vm_ip}
    [Documentation]    Should Not Reach Vm Instance with the net id of the Netowrk.
    Return From Keyword If    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}    20s
    BuiltIn.Should Not Contain    ${output}    64 bytes

Ping Vm From Control Node
    [Arguments]    ${vm_floating_ip}    ${additional_args}=${EMPTY}
    [Documentation]    Ping VM floating IP from control node
    OpenStackOperations.Get ControlNode Connection
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    ping ${additional_args} -c 3 ${vm_floating_ip}    20s
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
    [Arguments]    ${console}=cirros
    [Documentation]    Check if the session has been able to login to the VM instance
    ${output} =    Utils.Write Commands Until Expected Prompt    id    ${OS_SYSTEM_PROMPT}
    BuiltIn.Should Contain    ${output}    ${console}

Exit From Vm Console
    [Arguments]    ${console}=cirros
    [Documentation]    Check if the session has been able to login to the VM instance and exit the instance
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance    ${console}
    BuiltIn.Run Keyword If    ${rcode}    DevstackUtils.Write Commands Until Prompt    exit

Check Ping
    [Arguments]    ${ip_address}    ${ttl}=64
    [Documentation]    Run Ping command on the IP available as argument
    ${ethertype} =    String.Get Regexp Matches    ${ip_address}    ${IP_REGEX}
    ${output} =    BuiltIn.Run Keyword If    ${ethertype}    Utils.Write Commands Until Expected Prompt    ping -t ${ttl} -c 3 ${ip_address}    ${OS_SYSTEM_PROMPT}
    ...    ELSE    Utils.Write Commands Until Expected Prompt    ping6 -t ${ttl} -c 3 ${ip_address}    ${OS_SYSTEM_PROMPT}
    BuiltIn.Should Contain    ${output}    64 bytes

Check No Ping
    [Arguments]    ${ip_address}    ${ttl}=64
    [Documentation]    Run Ping command to the IP given as argument, executing 3 times and expecting NOT to see "64 bytes"
    ${output} =    Utils.Write Commands Until Expected Prompt    ping -t ${ttl} -c 3 ${ip_address}    ${OS_SYSTEM_PROMPT}
    BuiltIn.Should Not Contain    ${output}    64 bytes

Check Metadata Access
    [Documentation]    Try curl on the Metadataurl and check if it is okay
    ${output} =    Utils.Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    BuiltIn.Should Contain    ${output}    200

Execute Command on VM Instance
    [Arguments]    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)    ${cmd_timeout}=30s
    ...    ${console}=cirros
    [Documentation]    Login to the vm instance using ssh in the network, executes a command inside the VM and returns the ouput.
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o MACs=hmac-sha1 -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance    ${console}
    ${output} =    BuiltIn.Run Keyword If    ${rcode}    Utils.Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}    timeout=${cmd_timeout}
    [Teardown]    Exit From Vm Console    ${console}
    [Return]    ${output}

Execute Command on VM Instance With PublicKey Auth
    [Arguments]    ${net_name}    ${vm_ip}    ${cmd}    ${user}=centos    ${idfile}=/tmp/odlkey    ${console}=cirros
    [Documentation]    Login to the vm instance using ssh publickey in the network, executes a command inside the VM and returns the ouput.
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ${idfile} ${user}@${vm_ip} -o MACs=hmac-sha1 -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=publickey    prompt=${OS_SYSTEM_PROMPT}    timeout=60s
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance    ${console}
    ${output} =    BuiltIn.Run Keyword If    ${rcode}    Utils.Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}
    [Teardown]    Exit From Vm Console    ${console}
    [Return]    ${output}

Copy File To VM Instance With PublicKey Auth
    [Arguments]    ${net_name}    ${vm_ip}    ${file_to_copy}    ${user}=centos    ${idfile}=/tmp/odlkey
    [Documentation]    Login to the vm instance using ssh publickey in the network, executes a command inside the VM and returns the ouput.
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${rc} =    SSHLibrary.Execute Command    sudo ip netns exec qdhcp-${net_id} scp -i ${idfile} -o MACs=hmac-sha1 -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=publickey ${file_to_copy} ${user}@${vm_ip}:/tmp/    return_stdout=False    return_rc=True
    BuiltIn.Should Be True    '${rc}' == '0'

Test Operations From Vm Instance
    [Arguments]    ${net_name}    ${src_ip}    ${dest_ips}    ${user}=cirros    ${password}=cubswin:)    ${ttl}=64
    ...    ${ping_should_succeed}=True    ${check_metadata}=True    ${console}=cirros
    [Documentation]    Login to the vm instance using ssh in the network.
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o MACs=hmac-sha1 -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    password:    10s
    ${output} =    Utils.Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance    ${console}
    BuiltIn.Run Keyword If    ${rcode}    Utils.Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    BuiltIn.Run Keyword If    ${rcode}    Utils.Write Commands Until Expected Prompt    route -n    ${OS_SYSTEM_PROMPT}
    BuiltIn.Run Keyword If    ${rcode}    Utils.Write Commands Until Expected Prompt    route -A inet6    ${OS_SYSTEM_PROMPT}
    BuiltIn.Run Keyword If    ${rcode}    Utils.Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    BuiltIn.Run Keyword If    ${rcode}    Utils.Write Commands Until Expected Prompt    ip -f inet6 neigh show    ${OS_SYSTEM_PROMPT}
    : FOR    ${dest_ip}    IN    @{dest_ips}
    \    ${string_empty} =    BuiltIn.Run Keyword And Return Status    Should Be Empty    ${dest_ip}
    \    BuiltIn.Run Keyword If    ${string_empty}    Continue For Loop
    \    BuiltIn.Run Keyword If    ${rcode} and "${ping_should_succeed}" == "True"    OpenStackOperations.Check Ping    ${dest_ip}    ttl=${ttl}
    \    ...    ELSE    OpenStackOperations.Check No Ping    ${dest_ip}    ttl=${ttl}
    ${ethertype} =    String.Get Regexp Matches    ${src_ip}    ${IP_REGEX}
    BuiltIn.Run Keyword If    ${rcode} and "${check_metadata}" and ${ethertype} == "True"    OpenStackOperations.Check Metadata Access
    [Teardown]    Exit From Vm Console    ${console}

Test Netcat Operations From Vm Instance
    [Arguments]    ${net_name}    ${vm_ip}    ${dest_ip}    ${additional_args}=${EMPTY}    ${port}=12345    ${user}=cirros
    ...    ${password}=cubswin:)
    [Documentation]    Use Netcat to test TCP/UDP connections to the controller
    ${client_data}    BuiltIn.Set Variable    Test Client Data
    ${server_data}    BuiltIn.Set Variable    Test Server Data
    OpenStackOperations.Get ControlNode Connection
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    ( ( echo "${server_data}" | sudo timeout 60 nc -l ${additional_args} ${port} ) & )
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo netstat -nlap | grep ${port}
    ${nc_output} =    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo echo "${client_data}" | nc -v -w 5 ${additional_args} ${dest_ip} ${port}
    BuiltIn.Log    ${output}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo route -n
    BuiltIn.Log    ${output}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${vm_ip}    sudo arp -an
    BuiltIn.Log    ${output}
    BuiltIn.Should Match Regexp    ${nc_output}    ${server_data}

Ping Other Instances
    [Arguments]    ${list_of_external_dst_ips}    ${console}=cirros
    [Documentation]    Check reachability with other network's instances.
    ${rcode} =    BuiltIn.Run Keyword And Return Status    OpenStackOperations.Check If Console Is VmInstance    ${console}
    : FOR    ${dest_ip}    IN    @{list_of_external_dst_ips}
    \    OpenStackOperations.Check Ping    ${dest_ip}

Create Router
    [Arguments]    ${router_name}
    [Documentation]    Create Router and Add Interface to the subnets.
    ${output} =    OpenStack CLI    openstack router create ${router_name}

List Routers
    [Documentation]    List Routers and return output with neutron client.
    ${output} =    OpenStack CLI    openstack router list -f value
    [Return]    ${output}

Add Router Interface
    [Arguments]    ${router_name}    ${interface_name}
    ${output} =    OpenStack CLI    openstack router add subnet ${router_name} ${interface_name}

Show Router Interface
    [Arguments]    ${router_name}
    [Documentation]    List Routers interface associated with given Router and return output with neutron client.
    ${output} =    OpenStack CLI    openstack port list --router ${router_name} -f value
    [Return]    ${output}

Add Router Gateway
    [Arguments]    ${router_name}    ${external_network_name}    ${additional_args}=${EMPTY}
    ${output} =    OpenStack CLI    openstack router set ${router_name} --external-gateway ${external_network_name} ${additional_args}

Remove Interface
    [Arguments]    ${router_name}    ${interface_name}
    [Documentation]    Remove Interface to the subnets.
    ${output} =    OpenStack CLI    openstack router remove subnet ${router_name} ${interface_name}

Remove Gateway
    [Arguments]    ${router_name}
    [Documentation]    Remove external gateway from the router.
    ${output} =    OpenStack CLI    openstack router unset ${router_name} --external-gateway

Update Router
    [Arguments]    ${router_name}    ${cmd}
    [Documentation]    Update the router with the command. Router name and command should be passed as argument.
    ${output} =    OpenStack CLI    openstack router set ${router_name} ${cmd}

Show Router
    [Arguments]    ${router_name}    ${additional_args}=${EMPTY}
    [Documentation]    Show information of a given router. Router name and optional fields should be sent as arguments.
    ${output} =    OpenStack CLI    openstack router show ${router_name} ${additional_args}
    [Return]    ${output}

Delete Router
    [Arguments]    ${router_name}
    [Documentation]    Delete Router and Interface to the subnets.
    ${output} =    OpenStack CLI    openstack router delete ${router_name}

Get DumpFlows And Ovsconfig
    [Arguments]    ${conn_id}
    [Documentation]    Get the OvsConfig and Flow entries from OVS from the Openstack Node
    SSHLibrary.Switch Connection    ${conn_id}
    Utils.Write Commands Until Expected Prompt    ip -o link    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    ip -o addr    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    ip route    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    arp -an    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${nslist} =    Utils.Write Commands Until Expected Prompt    ip netns list | awk '{print $1}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{lines}    Split To Lines    ${nslist}    end=-1
    : FOR    ${line}    IN    @{lines}
    \    Utils.Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip -o link    ${DEFAULT_LINUX_PROMPT_STRICT}
    \    Utils.Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip -o addr    ${DEFAULT_LINUX_PROMPT_STRICT}
    \    Utils.Write Commands Until Expected Prompt    sudo ip netns exec ${line} ip route    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl list Open_vSwitch    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl show ${INTEGRATION_BRIDGE} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows ${INTEGRATION_BRIDGE} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-groups ${INTEGRATION_BRIDGE} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-group-stats ${INTEGRATION_BRIDGE} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}

Get ControlNode Connection
    SSHLibrary.Switch Connection    ${OS_CNTL_CONN_ID}
    [Return]    ${OS_CNTL_CONN_ID}

Get OvsDebugInfo
    [Documentation]    Get the OvsConfig and Flow entries from all Openstack nodes
    : FOR    ${conn_id}    IN    @{OS_ALL_CONN_IDS}
    \    OpenStackOperations.Get DumpFlows And Ovsconfig    ${conn_id}

Get Test Teardown Debugs
    [Arguments]    ${test_name}=${SUITE_NAME}.${TEST_NAME}    ${fail}=${FAIL_ON_EXCEPTIONS}
    ODLTools.Get All    node_ip=${HA_PROXY_IP}    test_name=${test_name}
    OpenStackOperations.Get OvsDebugInfo
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${HA_PROXY_IP}    ${netvirt_data_models}
    KarafKeywords.Fail If Exceptions Found During Test    ${test_name}    fail=${fail}

Get Suite Debugs
    Get Test Teardown Debugs    test_name=${SUITE_NAME}    fail=False

Get Test Teardown Debugs For SFC
    [Arguments]    ${test_name}=${TEST_NAME}
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${HA_PROXY_IP}    ${netvirt_sfc_data_models}

Show Debugs
    [Arguments]    @{vm_indices}
    [Documentation]    Run these commands for debugging, it can list state of VM instances and ip information in control node
    OpenStackOperations.Get ControlNode Connection
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo ip netns list
    : FOR    ${index}    IN    @{vm_indices}
    \    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    nova show ${index}
    \    BuiltIn.Log    ${output}
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
    [Return]    ${output}

Neutron Security Group Show
    [Arguments]    ${SecurityGroupRuleName}
    [Documentation]    Displays the neutron security group configurations that belongs to a given neutron security group name
    ${output} =    OpenStack CLI    openstack security group show ${SecurityGroupRuleName}
    [Return]    ${output}

Neutron Port Show
    [Arguments]    ${PortName}
    [Documentation]    Display the port configuration that belong to a given neutron port
    ${output} =    OpenStack CLI    openstack port show ${PortName}
    [Return]    ${output}

Neutron Security Group Create
    [Arguments]    ${SecurityGroupName}    ${additional_args}=${EMPTY}
    [Documentation]    Create a security group with specified name ,description & protocol value according to security group template
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStack CLI    openstack security group create ${SecurityGroupName} ${additional_args}
    ${sgp_id} =    BuiltIn.Should Match Regexp    ${output}    ${REGEX_UUID}
    [Return]    ${output}    ${sgp_id}

Neutron Security Group Update
    [Arguments]    ${SecurityGroupName}    ${additional_args}=${EMPTY}
    [Documentation]    Updating security groups
    ${output} =    OpenStack CLI    openstack security group set ${SecurityGroupName} ${additional_args}
    [Return]    ${output}

Delete SecurityGroup
    [Arguments]    ${sg_name}
    [Documentation]    Delete Security group
    ${output} =    OpenStack CLI    openstack security group delete ${sg_name}

Neutron Security Group Rule Create
    [Arguments]    ${Security_group_name}    &{Kwargs}
    [Documentation]    Creates neutron security rule with Openstack CLI with or without optional params, here security group name is mandatory args, rule with optional params can be created by passing the optional args values ex: direction=${INGRESS_EGRESS}, Then these optional params are BuiltIn.Catenated with mandatory args, example of usage: "OpenStack Neutron Security Group Rule Create ${SGP_SSH} direction=${RULE_PARAMS[0]} ethertype=${RULE_PARAMS[1]} ..."
    BuiltIn.Run Keyword If    ${Kwargs}    BuiltIn.Log    ${Kwargs}
    ${description}    BuiltIn.Run Keyword If    ${Kwargs}    Collections.Pop From Dictionary    ${Kwargs}    description    default=${None}
    ${direction}    BuiltIn.Run Keyword If    ${Kwargs}    Collections.Pop From Dictionary    ${Kwargs}    direction    default=${None}
    ${ethertype}    BuiltIn.Run Keyword If    ${Kwargs}    Collections.Pop From Dictionary    ${Kwargs}    ethertype    default=${None}
    ${port_range_max}    BuiltIn.Run Keyword If    ${Kwargs}    Collections.Pop From Dictionary    ${Kwargs}    port_range_max    default=${None}
    ${port_range_min}    BuiltIn.Run Keyword If    ${Kwargs}    Collections.Pop From Dictionary    ${Kwargs}    port_range_min    default=${None}
    ${protocol}    BuiltIn.Run Keyword If    ${Kwargs}    Collections.Pop From Dictionary    ${Kwargs}    protocol    default=${None}
    ${remote_group_id}    BuiltIn.Run Keyword If    ${Kwargs}    Collections.Pop From Dictionary    ${Kwargs}    remote_group_id    default=${None}
    ${remote_ip_prefix}    BuiltIn.Run Keyword If    ${Kwargs}    Collections.Pop From Dictionary    ${Kwargs}    remote_ip_prefix    default=${None}
    ${cmd} =    BuiltIn.Set Variable    openstack security group rule create ${Security_group_name}
    ${cmd} =    BuiltIn.Run Keyword If    '${description}'!='None'    BuiltIn.Catenate    ${cmd}    --description ${description}
    ...    ELSE    BuiltIn.Catenate    ${cmd}
    ${cmd} =    BuiltIn.Run Keyword If    '${direction}'!='None'    BuiltIn.Catenate    ${cmd}    --${direction}
    ...    ELSE    BuiltIn.Catenate    ${cmd}
    ${cmd} =    BuiltIn.Run Keyword If    '${ethertype}'!='None'    BuiltIn.Catenate    ${cmd}    --ethertype ${ethertype}
    ...    ELSE    BuiltIn.Catenate    ${cmd}
    ${cmd} =    BuiltIn.Run Keyword If    '${port_range_min}'!='None' and '${port_range_max}'!='None'    BuiltIn.Catenate    ${cmd}    --dst-port ${port_range_min}:${port_range_max}
    ...    ELSE IF    '${port_range_max}'!='None'    BuiltIn.Catenate    ${cmd}    --dst-port ${port_range_max}
    ...    ELSE IF    '${port_range_min}'!='None'    BuiltIn.Catenate    ${cmd}    --dst-port ${port_range_min}
    ...    ELSE    BuiltIn.Catenate    ${cmd}
    ${cmd} =    BuiltIn.Run Keyword If    '${protocol}'!='None'    BuiltIn.Catenate    ${cmd}    --protocol ${protocol}
    ...    ELSE    BuiltIn.Catenate    ${cmd}
    ${cmd} =    BuiltIn.Run Keyword If    '${remote_group_id}'!='None'    BuiltIn.Catenate    ${cmd}    --remote-group ${remote_group_id}
    ...    ELSE    BuiltIn.Catenate    ${cmd}
    ${cmd} =    BuiltIn.Run Keyword If    '${remote_ip_prefix}'!='None'    BuiltIn.Catenate    ${cmd}    --src-ip ${remote_ip_prefix}
    ...    ELSE    BuiltIn.Catenate    ${cmd}
    ${output} =    OpenStack CLI    ${cmd}
    ${rule_id} =    BuiltIn.Should Match Regexp    ${output}    ${REGEX_UUID}
    [Return]    ${output}    ${rule_id}

Security Group Create Without Default Security Rules
    [Arguments]    ${sg_name}    ${additional_args}=${EMPTY}
    [Documentation]    Create Neutron Security Group with no default rules, using specified name and optional arguments.
    OpenStackOperations.Neutron Security Group Create    ${sg_name}    ${additional_args}
    Delete All Security Group Rules    ${sg_name}

Delete All Security Group Rules
    [Arguments]    ${sg_name}
    [Documentation]    Delete all security rules from a specified security group
    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list ${sg_name} -cID -fvalue
    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    ${output} =    OpenStack CLI    openstack security group rule delete ${rule}

Create Allow All SecurityGroup
    [Arguments]    ${sg_name}    ${ether_type}=IPv4    ${dual}=False
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Neutron Security Group Create    ${sg_name}
    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=udp
    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=${ether_type}    port_range_max=65535    port_range_min=1    protocol=udp
    BuiltIn.Run Keyword If    "${dual}"=="True"    Run Keywords    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=IPv6
    ...    port_range_max=65535    port_range_min=1    protocol=tcp
    ...    AND    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=IPv6    port_range_max=65535
    ...    port_range_min=1    protocol=tcp
    ...    AND    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=IPv6    protocol=icmp
    ...    AND    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=IPv6    protocol=icmp
    ...    AND    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=ingress    ethertype=IPv6    port_range_max=65535
    ...    port_range_min=1    protocol=udp
    ...    AND    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=egress    ethertype=IPv6    port_range_max=65535
    ...    port_range_min=1    protocol=udp

Create Neutron Port With Additional Params
    [Arguments]    ${network_name}    ${port_name}    ${additional_args}=${EMPTY}
    [Documentation]    Create Port With given additional parameters
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    neutron -v port-create ${network_name} --name ${port_name} ${additional_args}
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    ${port_id} =    BuiltIn.Should Match Regexp    ${OUTPUT}    ${REGEX_UUID}
    [Return]    ${OUTPUT}    ${port_id}

Get Ports MacAddr
    [Arguments]    ${ports}
    [Documentation]    Retrieve the port MacAddr for the given list of port name and return the MAC address list.
    ${macs}    BuiltIn.Create List
    : FOR    ${port}    IN    @{ports}
    \    ${mac} =    OpenStackOperations.Get Port Mac    ${port}
    \    Collections.Append To List    ${macs}    ${mac}
    [Return]    ${macs}

Get Port Ip
    [Arguments]    ${port_name}
    [Documentation]    Keyword would return the IP of the ${port_name} received.
    ${output} =    OpenStack CLI    openstack port list | grep "${port_name}" | awk -F\\' '{print $2}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${port_ip} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${port_ip}

Get Port Mac
    [Arguments]    ${port_name}
    [Documentation]    Keyword would return the MAC ID of the ${port_name} received.
    ${output} =    OpenStack CLI    openstack port show ${port_name} | grep mac_address | awk '{print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${port_mac} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${port_mac}

Get Port Mac Address From Ip
    [Arguments]    ${ip}
    [Documentation]    Retrieve the mac address for a port that matches any given ip.
    ${output} =    OpenStack CLI    openstack port list | grep -w ${ip} | awk '{print $5}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${mac_addr} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${mac_addr}

Create L2Gateway
    [Arguments]    ${bridge_name}    ${intf_name}    ${gw_name}
    [Documentation]    Keyword to create an L2 Gateway ${gw_name} for bridge ${bridge_name} connected to interface ${intf_name} (Using Neutron CLI).
    ${rc}    ${l2gw_output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_CREATE} name=${bridge_name},interface_names=${intf_name} ${gw_name}
    BuiltIn.Log    ${l2gw_output}
    [Return]    ${l2gw_output}

Update L2Gateway
    [Arguments]    ${bridge_name}    ${gw_name}    ${intf_name_1}    ${intf_name_2}
    [Documentation]    Keyword to add {intf_name_list} to an existing L2 Gateway ${gw_name} (Using Neutron CLI).
    ${rc}    ${l2gw_output}=    Run And Return Rc And Output    ${L2GW_UPDATE} name=${bridge_name},interface_names="${intf_name_1};${intf_name_2}" ${gw_name}
    Log    ${l2gw_output}
    [Return]    ${l2gw_output}

Create L2Gateway Connection
    [Arguments]    ${gw_name}    ${net_name}
    [Documentation]    Keyword would create a new L2 Gateway Connection for ${gw_name} to ${net_name} (Using Neutron CLI).
    ${rc}    ${l2gw_output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_CONN_CREATE} ${gw_name} ${net_name}
    BuiltIn.Log    ${l2gw_output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${l2gw_output}

Get All L2Gateway
    [Documentation]    Keyword to return all the L2 Gateways available (Using Neutron CLI).
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_GET_YAML}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get All L2Gateway Connection
    [Documentation]    Keyword to return all the L2 Gateway connections available (Using Neutron CLI).
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_GET_CONN_YAML}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get L2Gateway
    [Arguments]    ${gw_id}
    [Documentation]    Keyword to check if the ${gw_id} is available in the L2 Gateway list (Using Neutron CLI).
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_SHOW} ${gw_id}
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get L2gw Id
    [Arguments]    ${l2gw_name}
    [Documentation]    Keyword to retrieve the L2 Gateway ID for the ${l2gw_name} (Using Neutron CLI).
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_GET} | grep "${l2gw_name}" | awk '{print $2}'
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${l2gw_id} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${l2gw_id}

Get L2gw Connection Id
    [Arguments]    ${l2gw_name}
    [Documentation]    Keyword to retrieve the L2 Gateway Connection ID for the ${l2gw_name} (Using Neutron CLI).
    ${l2gw_id} =    OpenStackOperations.Get L2gw Id    ${l2gw_name}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${L2GW_GET_CONN} | grep "${l2gw_id}" | awk '{print $2}'
    BuiltIn.Should Be True    '${rc}' == '0'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${l2gw_conn_id} =    Collections.Get from List    ${splitted_output}    0
    [Return]    ${l2gw_conn_id}

Neutron Port List Rest
    [Documentation]    Keyword to get all ports details in Neutron (Using REST).
    ${resp} =    RequestsLibrary.Get Request    session    ${PORT_URL}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Get Neutron Port Rest
    [Arguments]    ${port_id}
    [Documentation]    Keyword to get the specific port details in Neutron (Using REST).
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/${GET_PORT_URL}/${port_id}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Update Port Rest
    [Arguments]    ${port_id}    ${json_data}
    [Documentation]    Keyword to update ${port_id} with json data received in ${json_data} (Using REST).
    BuiltIn.Log    ${json_data}
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_API}/${GET_PORT_URL}/${port_id}    ${json_data}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Get Neutron Network Rest
    [Arguments]    ${net_id}
    [Documentation]    Keyword to get the specific network details in Neutron (Using REST).
    ${resp} =    RequestsLibrary.Get Request    session    ${NETWORK_URL}/network/${net_id}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Create And Configure Security Group
    [Arguments]    ${sg-name}
    [Documentation]    Create Security Group with given name, and default allow rules for TCP/UDP/ICMP protocols.
    OpenStackOperations.Neutron Security Group Create    ${sg-name}
    OpenStackOperations.Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${sg-name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${sg-name}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${sg-name}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${sg-name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${sg-name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Add Security Group To VM
    [Arguments]    ${vm}    ${sg}
    [Documentation]    Add the security group provided to the given VM.
    ${output} =    OpenStack CLI    openstack server add security group ${vm} ${sg}

Remove Security Group From VM
    [Arguments]    ${vm}    ${sg}
    [Documentation]    Remove the security group provided to the given VM.
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStack CLI    openstack server remove security group ${vm} ${sg}

Create SFC Flow Classifier
    [Arguments]    ${name}    ${src_ip}    ${dest_ip}    ${protocol}    ${neutron_src_port}    ${args}=${EMPTY}
    [Documentation]    Create a flow classifier for SFC
    ${output} =    OpenStack CLI    openstack sfc flow classifier create --ethertype IPv4 --source-ip-prefix ${src_ip}/32 --destination-ip-prefix ${dest_ip}/32 --protocol ${protocol} --logical-source-port ${neutron_src_port} ${args} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    [Return]    ${output}

Delete SFC Flow Classifier
    [Arguments]    ${name}
    [Documentation]    Delete a SFC flow classifier
    ${output} =    OpenStack CLI    openstack sfc flow classifier delete ${name}
    [Return]    ${output}

Create SFC Port Pair
    [Arguments]    ${name}    ${port_in}    ${port_out}
    [Documentation]    Creates a neutron port pair for SFC
    ${output} =    OpenStack CLI    openstack sfc port pair create --ingress=${port_in} --egress=${port_out} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    [Return]    ${output}

Delete SFC Port Pair
    [Arguments]    ${name}
    [Documentation]    Delete a SFC port pair
    ${output} =    OpenStack CLI    openstack sfc port pair delete ${name}
    [Return]    ${output}

Create SFC Port Pair Group
    [Arguments]    ${name}    ${port_pair}
    [Documentation]    Creates a port pair group with a single port pair for SFC
    ${output} =    OpenStack CLI    openstack sfc port pair group create --port-pair ${port_pair} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    [Return]    ${output}

Create SFC Port Pair Group With Two Pairs
    [Arguments]    ${name}    ${port_pair1}    ${port_pair2}
    [Documentation]    Creates a port pair group with two port pairs for SFC
    ${output} =    OpenStack CLI    openstack sfc port pair group create --port-pair ${port_pair1} --port-pair ${port_pair2} ${name}
    BuiltIn.Should Contain    ${output}    ${name}
    [Return]    ${output}

Delete SFC Port Pair Group
    [Arguments]    ${name}
    [Documentation]    Delete a SFC port pair group
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStack CLI    openstack sfc port pair group delete ${name}
    [Return]    ${output}

Create SFC Port Chain
    [Arguments]    ${name}    ${args}=${EMPTY}
    [Documentation]    Creates a port pair chain with two port groups and a singel classifier.
    ${output} =    OpenStack CLI    openstack sfc port chain create ${name} ${args}
    BuiltIn.Should Contain    ${output}    ${name}
    [Return]    ${output}

Update SFC Port Chain With A New Flow Classifier
    [Arguments]    ${name}    ${fc}
    [Documentation]    Adds a Flow Classifier to a Port Chain
    ${output} =    OpenStack CLI    openstack sfc port chain set ${name} --flow-classifier ${fc}
    [Return]    ${output}

Update SFC Port Chain Removing A Flow Classifier
    [Arguments]    ${name}    ${fc}
    [Documentation]    Adds a Flow Classifier to a Port Chain
    ${output} =    OpenStack CLI    openstack sfc port chain unset ${name} --flow-classifier ${fc}
    [Return]    ${output}

Delete SFC Port Chain
    [Arguments]    ${name}
    [Documentation]    Delete a SFC port chain
    ${output} =    OpenStack CLI    openstack sfc port chain delete ${name}
    [Return]    ${output}

Reboot Nova VM
    [Arguments]    ${vm_name}
    [Documentation]    Reboot NOVA VM
    ${output} =    OpenStack CLI    openstack server reboot --wait ${vm_name}
    BuiltIn.Wait Until Keyword Succeeds    35s    10s    OpenStackOperations.Verify VM Is ACTIVE    ${vm_name}

Remove RSA Key From KnownHosts
    [Arguments]    ${vm_ip}
    [Documentation]    Remove RSA
    OpenStackOperations.Get ControlNode Connection
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo cat /root/.ssh/known_hosts    30s
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo ssh-keygen -f "/root/.ssh/known_hosts" -R ${vm_ip}    30s
    ${output} =    DevstackUtils.Write Commands Until Prompt    sudo cat "/root/.ssh/known_hosts"    30s

Wait For Routes To Propogate
    [Arguments]    ${networks}    ${subnets}
    [Documentation]    Check propagated routes
    OpenStackOperations.Get ControlNode Connection
    : FOR    ${INDEX}    IN RANGE    0    1
    \    ${net_id} =    OpenStackOperations.Get Net Id    @{networks}[${INDEX}]
    \    ${is_ipv6} =    String.Get Regexp Matches    @{subnets}[${INDEX}]    ${IP6_REGEX}
    \    ${length} =    BuiltIn.Get Length    ${is_ipv6}
    \    ${cmd} =    BuiltIn.Set Variable If    ${length} == 0    ip route    ip -6 route
    \    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    \    BuiltIn.Should Contain    ${output}    @{subnets}[${INDEX}]

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
    @{modules} =    BuiltIn.Create List    server    port    network    subnet    security group
    ...    security group rule    floating ip    router
    : FOR    ${module}    IN    @{modules}
    \    ${output} =    OpenStack CLI    openstack ${module} list

OpenStack CLI Get List
    [Arguments]    ${cmd}
    [Documentation]    Return a json list from the output of an OpenStack command.
    @{list} =    BuiltIn.Create List
    ${json} =    OpenStack CLI    ${cmd}
    @{list} =    RequestsLibrary.To Json    ${json}
    BuiltIn.Log    ${list}
    [Return]    @{list}

OpenStack CLI
    [Arguments]    ${cmd}
    [Documentation]    Run the given OpenStack ${cmd} and log the output.
    ${result} =    Process.Run Process    ${cmd}    shell=True
    BuiltIn.Log    ${result.stdout}
    BuiltIn.Log    ${result.stderr}
    BuiltIn.Should Be True    '${result.rc}' == '0'
    [Return]    ${result.stdout}

OpenStack CLI With No Log
    [Arguments]    ${cmd}
    [Documentation]    Run the given OpenStack ${cmd} and do not log the output.
    ${result} =    Process.Run Process    ${cmd}    shell=True
    BuiltIn.Should Be True    '${result.rc}' == '0'
    [Return]    ${result.stdout}

OpenStack Cleanup All
    [Documentation]    Cleanup all Openstack resources with best effort. The keyword will query for all resources
    ...    in use and then attempt to delete them. Errors are ignored to allow the cleanup to continue.
    @{fips} =    OpenStack CLI Get List    openstack floating ip list -f json
    : FOR    ${fip}    IN    @{fips}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Floating IP    ${fip['ID']}
    @{vms} =    OpenStack CLI Get List    openstack server list -f json
    : FOR    ${vm}    IN    @{vms}
    \    OpenStack CLI    openstack server show ${vm['ID']}
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
    \    ${subnet_id} =    OpenStackOperations.Get Match    ${port['Fixed IP Addresses']}    ${REGEX_UUID}    0
    \    BuiltIn.Run Keyword If    "${port['Device Owner']}" == "network:router_gateway"    BuiltIn.Run Keyword And Ignore Error    Remove Gateway    ${id}
    \    BuiltIn.Run Keyword If    "${port['Device Owner']}" == "network:router_interface"    BuiltIn.Run Keyword And Ignore Error    Remove Interface    ${id}    ${subnet_id}
    BuiltIn.Run Keyword And Ignore Error    Delete Router    ${id}

OpenStack Suite Setup
    [Documentation]    Wrapper teardown keyword that can be used in any suite running in an openstack environement
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    @{loggers} =    BuiltIn.Create List    org.apache.karaf.shell.support.ShellUtil    org.apache.sshd.server.session.ServerSessionImpl
    Setuputils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    OFF    ${loggers}
    DevstackUtils.Devstack Suite Setup
    @{tcpdump_port_6653_conn_ids} =    OpenStackOperations.Start Packet Capture On Nodes    tcpdump_port_6653    port 6653    @{OS_ALL_IPS}
    BuiltIn.Set Suite Variable    @{tcpdump_port_6653_conn_ids}
    BuiltIn.Run Keyword If    "${PRE_CLEAN_OPENSTACK_ALL}"=="True"    OpenStack Cleanup All
    OpenStackOperations.Add OVS Logging On All OpenStack Nodes
    Run_Keyword_If_At_Least_Oxygen    Wait Until Keyword Succeeds    60    2    ClusterManagement.Check Status Of Services Is OPERATIONAL    @{NETVIRT_DIAG_SERVICES}
    Verify Expected Default Tables On Nodes

OpenStack Suite Teardown
    [Documentation]    Wrapper teardown keyword that can be used in any suite running in an openstack environement
    ...    to clean up all openstack resources. For example, all instances, networks, ports, etc will be listed and
    ...    and deleted. As other global cleanup tasks are needed, they can be added here and the suites will all
    ...    benefit automatically.
    # TODO: followup patch will add the list of vms to pass to Show Debugs
    # OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    OpenStackOperations.Get Suite Debugs
    OpenStack Cleanup All
    OpenStackOperations.Stop Packet Capture On Nodes    ${tcpdump_port_6653_conn_ids}
    SSHLibrary.Close All Connections
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    KarafKeywords.Issue Command On Karaf Console    threads --list | wc -l    ${ODL_SYSTEM_${i+1}_IP}

Copy DHCP Files From Control Node
    [Documentation]    Copy the current DHCP files to the robot vm. The keyword must be called
    ...    after the subnet(s) are created and before the subnet(s) are deleted.
    ${suite_} =    BuiltIn.Evaluate    """${SUITE_NAME}""".replace(" ","_").replace("/","_").replace(".","_")
    ${dstdir} =    BuiltIn.Set Variable    /tmp/qdhcp/${suite_}
    OperatingSystem.Create Directory    ${dstdir}
    OpenStackOperations.Get ControlNode Connection
    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Get Directory    /opt/stack/data/neutron/dhcp    ${dstdir}    recursive=True

Is Feature Installed
    [Arguments]    ${features}=none
    : FOR    ${feature}    IN    @{features}
    \    ${status}    ${output}    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Should Contain    ${CONTROLLERFEATURES}    ${feature}
    \    Return From Keyword If    "${status}" == "PASS"    True
    [Return]    False

Add OVS Logging On All OpenStack Nodes
    [Documentation]    Add higher levels of OVS logging to all the OpenStack nodes
    : FOR    ${conn_id}    IN    @{OS_ALL_CONN_IDS}
    \    OVSDB.Add OVS Logging    ${conn_id}

Reset OVS Logging On All OpenStack Nodes
    [Documentation]    Reset the OVS logging to all the OpenStack nodes
    : FOR    ${conn_id}    IN    @{OS_ALL_CONN_IDS}
    \    OVSDB.Reset OVS Logging    ${conn_id}

Start Packet Capture On Nodes
    [Arguments]    ${tag}    ${filter}    @{ips}
    [Documentation]    Wrapper keyword around the TcpDump packet capture that is catered to the Openstack setup.
    ...    The caller must pass the three arguments with a variable number of ips at the end,
    ...    but ${EMPTY} can be used for the tag and filter.
    ${suite_} =    BuiltIn.Evaluate    """${SUITE_NAME}""".replace(" ","_").replace("/","_").replace(".","_")
    ${tag_} =    BuiltIn.Catenate    SEPARATOR=__    ${tag}    ${suite_}
    @{conn_ids} =    Tcpdump.Start Packet Capture on Nodes    tag=${tag_}    filter=${filter}    ips=${ips}
    [Return]    @{conn_ids}

Stop Packet Capture On Nodes
    [Arguments]    ${conn_ids}=@{EMPTY}
    Tcpdump.Stop Packet Capture on Nodes    ${conn_ids}

Server Live Migrate
    [Arguments]    ${vm_instance_name}
    [Documentation]    Keyword for live migration of VM instance
    ...    additional_agrs is to select particular migration(live/shared-migration/block-migration)
    ...    if the additional_agrs is not given default migration(shared-migration) will happen
    ${output} =    OpenStackOperations.OpenStack CLI    nova live-migration ${vm_instance_name}

Get Hypervisor Host Of Vm
    [Arguments]    ${vm_name}
    [Documentation]    Show server with neutron request.
    ${output} =    OpenStackOperations.OpenStack CLI    openstack server show -f value -c OS-EXT-SRV-ATTR:host ${vm_name}
    [Return]    ${output}

Check If Migration Is Complete
    [Arguments]    ${vm_name}
    [Documentation]    Show server and verify if task_state is not migrating
    ${output} =    OpenStackOperations.OpenStack CLI    openstack server show ${vm_name} | grep "OS-EXT-STS:task_state"
    BuiltIn.Should Not Contain    ${output}    migrating

Modify OpenStack Configuration File
    [Arguments]    ${conn_id}    ${file_name}    ${section}    ${key}    ${value}
    [Documentation]    Use crudini to modify any parameter in any Openstack configuration File
    SSHLibrary.Switch Connection    ${conn_id}
    ${output}    ${rc} =    SSHLibrary.Execute Command    sudo crudini --verbose --set --inplace ${file_name} ${section} ${key} ${value}    return_rc=True    return_stdout=True
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'

Restart DevStack Service
    [Arguments]    ${conn_id}    ${service_name}
    [Documentation]    Restart the Openstack Service
    SSHLibrary.Switch Connection    ${conn_id}
    ${output}    ${rc} =    SSHLibrary.Execute Command    sudo systemctl restart devstack@${service_name}.service    return_rc=True    return_stdout=True
    BuiltIn.Log    ${output}
    BuiltIn.Should Be True    '${rc}' == '0'

Get Network Segmentation Id
    [Arguments]    ${network_name}
    [Documentation]    Returns network segmentation id for the given network name.
    ${output} =    OpenStack CLI    openstack network show ${network_name} | grep segmentation_id | awk '{print $4}'
    @{list} =    String.Split String    ${output}
    [Return]    @{list}[0]

Verify Expected Default Tables On Nodes
    [Arguments]    ${node_ips}=@{OS_ALL_IPS}
    [Documentation]    Verify if Default Table Entries are programmed on all Nodes
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}
    Utils.Log Content    ${resp.content}
    ${failed_node_list} =    BuiltIn.Create List
    : FOR    ${node_ip}    IN    @{node_ips}
    \    ${failed_table_list} =    Verify Expected Default Tables    ${node_ip}
    \    ${failed_table_list_size} =    BuiltIn.Get Length    ${failed_table_list}
    \    BuiltIn.Run Keyword If    ${failed_table_list_size} > 0    Collections.Append To List    ${failed_node_list}    ${node_ip}
    Builtin.Should Be Empty    ${failed_node_list}

Verify Expected Default Tables
    [Arguments]    ${ovs_ip}
    [Documentation]    Verify if Default Table Entries are programmed on specific Node
    ${flow_dump} =    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-ofctl dump-flows ${INTEGRATION_BRIDGE} -OOpenFlow13
    BuiltIn.Log    ${flow_dump}
    ${failed_table_list} =    BuiltIn.Create List
    : FOR    ${table}    IN    @{DEFAULT_FLOW_TABLES}
    \    ${rc} =    Builtin.Run Keyword And Return Status    Builtin.Should Not Match Regexp    ${flow_dump}    .*table=${table}.*priority=0
    \    BuiltIn.Run Keyword If    ${rc}    Collections.Append To List    ${failed_table_list}    ${table}
    [Return]    ${failed_table_list}

Get Project Id
    [Arguments]    ${project_name}
    [Documentation]    Returns project ID for the given project name.
    ${project_id} =    OpenStack CLI    openstack project show ${project_name} -f value -c id
    [Return]    ${project_id}

Set Instance Quota For Project
    [Arguments]    ${num_instances}    ${project_id}
    [Documentation]    Set quota for the created instances using the specific project id.
    ${output} =    OpenStack CLI    openstack quota set --instances ${num_instances} ${project_id}
    [Return]    ${output}
