*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Create Network
    [Arguments]    ${network_name}    ${devstack_path}=/opt/stack/new/devstack
    [Documentation]    Create Network with neutron request.
    ${output}=    Write Commands Until Prompt    cd ${devstack_path} && cat localrc
    Log    ${output}
    ${output}=    Write Commands Until Prompt    source openrc admin admin
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v net-create ${network_name}
    Log    ${output}
    Should Contain    ${output}    Created a new network

Delete Network
    [Arguments]    ${network_name}
    [Documentation]    Delete Network with neutron request.
    ${output}=    Write Commands Until Prompt    neutron -v net-delete ${network_name}
    Log    ${output}
    Should Contain    ${output}    Deleted network: ${network_name}

Create SubNet
    [Arguments]    ${network_name}    ${subnet}    ${range_ip}
    [Documentation]    Create SubNet for the Network with neutron request.
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${network_name} ${range_ip} --name ${subnet}
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
    #: FOR    ${DhcpIpElement}    IN    @{DHCP_IPS}
    #\    Should Contain    ${output}    ${DhcpIpElement}

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
    ${output}=    Write Commands Until Prompt    neutron -v subnet-delete ${subnet}
    Log    ${output}
    Should Contain    ${output}    Deleted subnet: ${subnet}

Verify No Gateway Ips
    [Documentation]    Verifies the Gateway Ips removed with dump flow.
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${GatewayIpElement}    IN    @{GATEWAY_IPS}
    \    Should Not Contain    ${output}    ${GatewayIpElement}

Create Vm Instance
    [Arguments]    ${net_id}    ${network_name}
    [Documentation]    Create Vm Instance with the net id of the Netowrk.
    ${VmElement}=    Set Variable If    "${network_name}"=="net1_network"    MyFirstInstance    MySecondInstance
    ${output}=    Write Commands Until Prompt    nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic net-id=${net_id} ${VmElement}
    Log    ${output}

Delete Vm Instance
    [Arguments]    ${vm_name}
    [Documentation]    Delete Vm instances using instance names.
    ${output}=    Write Commands Until Prompt    nova delete ${vm_name}
    Log    ${output}

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
    [Arguments]    ${net_id}    ${vm_instance_names}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.tiny
    [Documentation]    Create Four Vm Instance with the net id of the Netowrk.
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    ${output}=    Write Commands Until Prompt    nova boot --image ${image} --flavor ${flavor} --nic net-id=${net_id} ${VmElement}
    \    Log    ${output}

View Vm Console
    [Arguments]    ${vm_instance_names}
    [Documentation]    View Console log of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{vm_instance_names}
    \    ${output}=    Write Commands Until Prompt    nova show ${VmElement}
    \    Log    ${output}
    \    ${output}=    Write Commands Until Prompt    nova console-log ${VmElement}
    \    Log    ${output}

Ping Vm From DHCP Namespace
    [Arguments]    ${net_id}    ${vm_ip}
    [Documentation]    Reach all Vm Instance with the net id of the Netowrk.
    Log    ${vm_ip}
    ${output}=    Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 3 ${vm_ip}    20s
    Log    ${output}
    [Return]    ${output}

Ping From Instance
    [Arguments]    ${dest_vm}
    [Documentation]    Ping to the expected destination ip.
    ${output}=    Write Commands Until Expected Prompt    ping -c 3 ${dest_vm}    $
    Log    ${output}
    [Return]    ${output}

Curl Metadata Server
    [Documentation]    Ping to the expected destination ip.
    ${output}=    Write Commands Until Expected Prompt    curl -i http://169.254.169.254    $
    Write Commands Until Prompt    exit
    Should Contain    ${output}    200

Close Vm Instance
    [Documentation]    Exit the vm instance.
    ${output}=    Write Commands Until Prompt    exit
    Log    ${output}

Ssh Vm Instance
    [Arguments]    ${net_id}    ${vm_ip}    ${user}=cirros    ${password}=cubswin:)    ${key_file}=test.pem
    [Documentation]    Login to the vm instance using ssh in the network.
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ${key_file} ${user}@${vm_ip}    (yes/no)?
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    yes    d:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ifconfig    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    route    $
    Log    ${output}

Create Router
    [Arguments]    ${router_name}
    [Documentation]    Create Router and Add Interface to the subnets.
    ${output}=    Write Commands Until Prompt    neutron -v router-create ${router_name}
    Should Contain    ${output}    Created a new router

Add Router Interface
    [Arguments]    ${router_name}    ${interface_name}
    ${output}=    Write Commands Until Prompt    neutron -v router-interface-add ${router_name} ${interface_name}
    Should Contain    ${output}    Added interface

Remove Interface
    [Arguments]    ${router_name}    ${interface_name}
    [Documentation]    Remove Interface to the subnets.
    ${output}=    Write Commands Until Prompt    neutron -v router-interface-delete ${router_name} ${interface_name}
    Should Contain    ${output}    Removed interface from router

Delete Router
    [Arguments]    ${router_name}
    [Documentation]    Delete Router and Interface to the subnets.
    ${output}=    Write Commands Until Prompt    neutron -v router-delete ${router_name}
    Should Contain    ${output}    Deleted router:

Get DumpFlows And Ovsconfig
    [Arguments]    ${openstack_node_ip}
    [Documentation]    Get the OvsConfig and Flow entries from OVS from the Openstack Node
    SSHLibrary.Open Connection    ${openstack_node_ip}    prompt=${DEFAULT_LINUX_PROMPT}
    Utils.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${show}=    Write Commands Until Prompt     sudo ovs-vsctl show
    Log    ${show}
    ${dumpFlow}=    Write Commands Until Prompt     sudo ovs-ofctl dump-flows br-int -OOpenFlow13
    Log    ${dumpFlow}
    Write     exit

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

Check Ping
    [Arguments]     ${ip_address}
    [Documentation]     Run Ping command on the IP available as argument
    ${output}=   Write Commands Until Expected Prompt    ping -c 3 ${dest_dhcp}    ${OS_SYSTEM_PROMPT}
    Should Contain     ${output}     64 bytes

Check Metadata Access
    [Documentation]      Try curl on the Metadataurl and check if it is okay
    ${output}=   Write Commands Until Expected Prompt    curl -i http://169.254.169.254    ${OS_SYSTEM_PROMPT}
    Should Contain     ${output}     200


Test Operations From Vm Instance
    [Arguments]    ${net_id}    ${src_ip}    ${list_of_local_dst_ips}    ${l2_or_l3}=l2    ${list_of_external_dst_ips}=${NONE}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network.
    Switch Connection    ${devstack_conn_id}
    Source Password
    ${output}=   Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${src_ip} -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no      d:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status      Check If Console Is VmInstance
    Run Keyword If     ${rcode}     Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Run Keyword If     ${rcode}     Write Commands Until Expected Prompt    route    ${OS_SYSTEM_PROMPT}
    ${dest_vm}=    Get From List    ${list_of_local_dst_ips}    0
    Log    ${dest_vm}
    Run Keyword If     ${rcode}     Check Ping      ${dest_vm}
    ${dest_dhcp}=    Get From List    ${list_of_local_dst_ips}    1
    Log    ${dest_dhcp}
    Run Keyword If     ${rcode}     Check Ping      ${dest_dhcp}
    ${dest_vm}=    Get From List    ${list_of_local_dst_ips}    2
    Log    ${dest_vm}
    Run Keyword If     ${rcode}     Check Ping      ${dest_vm}
    Run Keyword If     ${rcode}     Check Metadata Access
    Run Keyword If    '${l2_or_l3}' == 'l3'    Ping Other Instances    ${list_of_external_dst_ips}
    [Teardown]      Exit From Vm Console

Ping Other Instances
    [Arguments]    ${list_of_external_dst_ips}
    [Documentation]    Check reachability with other network's instances.
    ${rcode}=    Run Keyword And Return Status      Check If Console Is VmInstance
    ${dest_vm}=    Get From List    ${list_of_external_dst_ips}    0
    Log    ${dest_vm}
    Run Keyword If     ${rcode}     Check Ping      ${dest_vm}
    ${dest_dhcp}=    Get From List    ${list_of_external_dst_ips}    1
    Log    ${dest_dhcp}
    Run Keyword If     ${rcode}     Check Ping      ${dest_dhcp}
    ${dest_vm}=    Get From List    ${list_of_external_dst_ips}    2
    Log    ${dest_vm}
    Run Keyword If     ${rcode}     Check Ping      ${dest_vm}
