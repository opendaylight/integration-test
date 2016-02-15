*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Create Network
    [Arguments]    ${network_name}
    [Documentation]    Create Network with neutron request.
    ${output}=    Write Commands Until Prompt    cd /opt/stack/devstack
    Log    ${output}
    ${output}=    Write Commands Until Prompt    ls
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
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${GatewayIpElement}    IN    @{GATEWAY_IPS}
    \    Should Contain    ${output}    ${GatewayIpElement}

Verify Dhcp Ips
    [Documentation]    Verifies the Dhcp Ips with dump flow.
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${DhcpIpElement}    IN    @{DHCP_IPS}
    \    Should Contain    ${output}    ${DhcpIpElement}

Verify No Dhcp Ips
    [Documentation]    Verifies the Dhcp Ips with dump flow.
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
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
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${GatewayIpElement}    IN    @{GATEWAY_IPS}
    \    Should Not Contain    ${output}    ${GatewayIpElement}

Create Vm Instance
    [Arguments]    ${net_id}    ${network_name}
    [Documentation]    Create Vm Instance with the net id of the Netowrk.
    ${VmElement}=    Set Variable If    "${network_name}"=="net1_network"    MyFirstInstance    MySecondInstance
    ${output}=    Write Commands Until Prompt     nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic net-id=${net_id} ${VmElement}
    Log    ${output}

Create Vm Instances
    [Arguments]    ${net_id}
    [Documentation]    Create Four Vm Instance with the net id of the Netowrk.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_NAME}
    \    ${output}=    Write Commands Until Prompt     nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic net-id=${net_id} ${VmElement}
    Log    ${output}

Ping Vm Instances
    [Arguments]    ${net_id}    ${is_vm_delete}=NONE
    [Documentation]    Reach all Vm Instance with the net id of the Netowrk.
    @{VM_IPS}=    Set Variable If    ${is_vm_delete}==true    10.0.0.4    10.0.0.5    10.0.0.6    
    : FOR    ${VmIpElement}    IN    @{VM_IPS}
    \    ${output}=    Write Commands Until Prompt     sudo ip netns exec qdhcp-${net_id} ping -c 3 ${VmIpElement}    20s
    \    Log    ${output}
    \    Should Contain    ${output}    64 bytes

Not Ping Vm Instances
    [Arguments]    ${net_id}
    [Documentation]    Should Not Reach removed Vm Instance.
    ${output}=    Write Commands Until Prompt     sudo ip netns exec qdhcp-${net_id} ping -c 3 10.0.0.3
    Log    ${output}
    Should Contain    ${output}    Destination Host Unreachable

Delete Vm Instance
    [Arguments]    ${vm_name}
    [Documentation]    Delete Vm instances using instance names.
    ${output}=   Write Commands Until Prompt     nova delete ${vm_name}
    Log    ${output}

Get Net Id
    [Arguments]    ${network_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    ${output}=   Write Commands Until Prompt    neutron net-list | grep "${network_name}" | get_field 1
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    \
    ${net_id}=    Get from List    ${splitted_output}    0
    Log    ${net_id}
    [Return]    ${net_id}

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    ${output}=   Write Commands Until Prompt     neutron -v router-create router_1
    Log    ${output}
    : FOR    ${SubnetElement}    IN    @{SUBNETS_NAME}
    \    ${output}=   Write Commands Until Prompt     neutron -v router-interface-add router_1 ${SubnetElement}
    Log    ${output}

Remove Interface
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${SubnetElement}    IN    @{SUBNETS_NAME}
    \    ${output}=   Write Commands Until Prompt     neutron -v router-interface-delete router_1 ${SubnetElement}
    \    Log    ${output}

Delete Router
    [Documentation]    Delete Router and Interface to the subnets.
    ${output}=   Write Commands Until Prompt     neutron -v router-delete router_1
    Log    ${output}

