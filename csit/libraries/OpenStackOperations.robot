*** Settings ***
Documentation    Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library    SSHLibrary
Resource    Utils.robot
Variables    ../variables/Variables.py

*** Keywords ***
Source Password
    [Arguments]     ${devstack_path}=/opt/stack/new/devstack     ${force}=no
    [Documentation]    Sourcing the Openstack PAsswords for neutron configurations
    Run Keyword If    '${source_pwd}' == 'yes' or '${force}' == 'yes'     Write Commands Until Prompt    cd ${devstack_path}; source openrc admin admin

Create Network
    [Arguments]    ${network_name}    ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Create Network with neutron request.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}     force=yes
    ${output}=    Write Commands Until Prompt    neutron -v net-create ${network_name}    30s
    Log    ${output}
    Should Contain    ${output}    Created a new network

Delete Network
    [Arguments]    ${network_name}     ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Delete Network with neutron request.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=    Write Commands Until Prompt    neutron -v net-delete ${network_name}
    Log    ${output}
    Should Contain    ${output}    Deleted network: ${network_name}

Create SubNet
    [Arguments]    ${network_name}    ${subnet}    ${range_ip}      ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Create SubNet for the Network with neutron request.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${network_name} ${range_ip} --name ${subnet}    30s
    Log    ${output}
    Should Contain    ${output}    Created a new subnet

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
    [Arguments]    ${subnet}     ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Delete SubNet for the Network with neutron request.
    Log    ${subnet}
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-delete ${subnet}
    Log    ${output}
    Should Contain    ${output}    Deleted subnet: ${subnet}

Verify No Gateway Ips
    [Documentation]    Verifies the Gateway Ips removed with dump flow.
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${GatewayIpElement}    IN    @{GATEWAY_IPS}
    \    Should Not Contain    ${output}    ${GatewayIpElement}

Delete Vm Instance
    [Arguments]    ${vm_name}      ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Delete Vm instances using instance names.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=    Write Commands Until Prompt    nova delete ${vm_name}
    Should Contain     ${output}     ${vm_name}

Get Net Id
    [Arguments]    ${network_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    ${output}=    Write Commands Until Prompt    neutron net-list | grep "${network_name}" | get_field 1
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${net_id}=    Get from List    ${splitted_output}    0
    Log    ${net_id}
    [Return]    ${net_id}

Create Vm Instances
    [Arguments]    ${net_id}    ${vm_instance_names}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.tiny      ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    ${output}=    Write Commands Until Prompt    nova boot --image ${image} --flavor ${flavor} --nic net-id=${net_id} ${VmElement}
    \    Log    ${output}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VmElement}

Verify VM Is ACTIVE
    [Arguments]    ${vm_name}
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    ${output}=    Write Commands Until Prompt    nova show ${vm_name}
    Log    ${output}
    @{output}=    Split String    ${output}    |
    Log    ${output}
    ${status}=    Get from List    ${output}    107
    Log    ${status}
    Should Be Equal As Strings    ${status}    ACTIVE

View Vm Console
    [Arguments]    ${vm_instance_names}
    [Documentation]    View Console log of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    ${output}=    Write Commands Until Prompt    nova show ${VmElement}
    \    Log    ${output}
    \    ${output}=    Write Commands Until Prompt    nova console-log ${VmElement}
    \    Log    ${output}

Ping Vm From DHCP Namespace
    [Arguments]    ${net_id}    ${vm_ip}     ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Reach all Vm Instance with the net id of the Netowrk.
    Log    ${vm_ip}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}    20s
    Log    ${output}
    [Return]    ${output}

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
    [Documentation]     Check if the session has been able to login to the VM instance
    ${output}=       Write Commands Until Expected Prompt      id       ${OS_SYSTEM_PROMPT}
    Should Contain    ${output}    ${console}

Exit From Vm Console
    [Documentation]     Check if the session has been able to login to the VM instance and exit the instance
    ${rcode}=    Run Keyword And Return Status      Check If Console Is VmInstance    cirros
    Run Keyword If     ${rcode}     Write Commands Until Prompt     exit
    Get OvsDebugInfo

Test Operations From Vm Instance
    [Arguments]    ${net_id}    ${src_ip}    ${list_of_local_dst_ips}    ${l2_or_l3}=l2    ${list_of_external_dst_ips}=${NONE}    ${user}=cirros    ${password}=cubswin:)    ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Login to the vm instance using ssh in the network.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=   Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${src_ip}    (yes/no)?
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    yes    d:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    route    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${dest_vm}=    Get From List    ${list_of_local_dst_ips}    0
    Log    ${dest_vm}
    ${output}=   Write Commands Until Expected Prompt    ping -c 3 ${dest_vm}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    Should Contain     ${output}     64 bytes
    ${dest_dhcp}=    Get From List    ${list_of_local_dst_ips}    1
    Log    ${dest_dhcp}
    ${output}=   Write Commands Until Expected Prompt    ping -c 3 ${dest_dhcp}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    Should Contain     ${output}     64 bytes
    ${output}=   Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    Should Contain     ${output}     200
    Run Keyword If    '${l2_or_l3}' == 'l3'    Ping Other Instances    ${list_of_external_dst_ips}
    [Teardown]      Exit From Vm Console

Ping Other Instances
    [Arguments]    ${list_of_external_dst_ips}
    [Documentation]    Check reachability with other network's instances.
    ${dest_vm}=    Get From List    ${list_of_external_dst_ips}    0
    Log    ${dest_vm}
    ${output}=   Write Commands Until Expected Prompt    ping -c 3 ${dest_vm}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    Should Contain     ${output}     64 bytes
    ${dest_dhcp}=    Get From List    ${list_of_external_dst_ips}    1
    Log    ${dest_dhcp}
    ${output}=   Write Commands Until Expected Prompt    ping -c 3 ${dest_dhcp}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    Should Contain     ${output}     64 bytes

Create Router
    [Arguments]    ${router_name}     ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Create Router and Add Interface to the subnets.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=    Write Commands Until Prompt    neutron -v router-create ${router_name}
    Should Contain    ${output}    Created a new router

Add Router Interface
    [Arguments]    ${router_name}    ${interface_name}     ${devstack_path}=/opt/stack/new/devstack
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=    Write Commands Until Prompt    neutron -v router-interface-add ${router_name} ${interface_name}
    Should Contain    ${output}    Added interface

Remove Interface
    [Arguments]    ${router_name}    ${interface_name}      ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Remove Interface to the subnets.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=    Write Commands Until Prompt    neutron -v router-interface-delete ${router_name} ${interface_name}
    Should Contain    ${output}    Removed interface from router

Delete Router
    [Arguments]    ${router_name}      ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Delete Router and Interface to the subnets.
    Switch Connection    ${devstack_conn_id}
    Source Password        devstack_path=${devstack_path}
    ${output}=    Write Commands Until Prompt    neutron -v router-delete ${router_name}
    Should Contain    ${output}    Deleted router:

Get DumpFlows And Ovsconfig
    [Arguments]    ${openstack_node_ip}
    [Documentation]    Get the OvsConfig and Flow entries from OVS from the Openstack Node
    ${os_node_ssh_conn}=      SSHLibrary.Open Connection    ${openstack_node_ip}    prompt=${DEFAULT_LINUX_PROMPT}
    Utils.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    Switch Connection      ${os_node_ssh_conn}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    Write Commands Until Prompt     sudo ovs-vsctl show
    Write      sudo ovs-ofctl dump-flows br-int -OOpenFlow13;ifconfig
    Read Until      ${openstack_node_ip}

Get OvsDebugInfo
    [Documentation]    Get the OvsConfig and Flow entries from all Openstack nodes
    Run Keyword If     0 < ${NUM_OS_SYSTEM}       Get DumpFlows And Ovsconfig     ${OS_CONTROL_NODE_IP}
    Run Keyword If     1 < ${NUM_OS_SYSTEM}       Get DumpFlows And Ovsconfig     ${OS_COMPUTE_1_IP}
    Run Keyword If     2 < ${NUM_OS_SYSTEM}       Get DumpFlows And Ovsconfig     ${OS_COMPUTE_2_IP}

Show Debugs
    [Arguments]    ${vm_indices}
    [Documentation]    Run these commands for debugging, it can list state of VM instances and ip information in control node
    ${output}=    Write Commands Until Prompt    sudo ip netns list
    Log    ${output}
    : FOR    ${index}    IN    @{vm_indices}
    \    ${output}=    Write Commands Until Prompt    nova show ${index}
    \    Log    ${output}
