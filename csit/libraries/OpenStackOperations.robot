*** Settings ***
Documentation     Netvirt library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Create Network
    [Arguments]    ${network_name}
    [Documentation]    Create Network with neutron request.
    ${output}=    Write Commands Until Prompt    cd /opt/stack/new/devstack && cat localrc
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
    [Arguments]    ${network_name}
    [Documentation]    Create SubNet for the Network with neutron request.
    ${subnet}=    Set Variable If    "${network_name}"=="net1_network"    subnet1    subnet2
    ${range_ip}=    Set Variable If    "${network_name}"=="net1_network"    10.0.0.0/24    20.0.0.0/24
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
    : FOR    ${DhcpIpElement}    IN    @{DHCP_IPS}
    \    Should Contain    ${output}    ${DhcpIpElement}

Verify No Dhcp Ips
    [Documentation]    Verifies the Dhcp Ips with dump flow.
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${DhcpIpElement}    IN    @{DHCP_IPS}
    \    Should Not Contain    ${output}    ${DhcpIpElement}

Delete SubNet
    [Arguments]    ${network_name}
    [Documentation]    Delete SubNet for the Network with neutron request.
    ${subnet}=    Set Variable If    "${network_name}"=="net1_network"    subnet1    subnet2
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

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    ${output}=    Write Commands Until Prompt    neutron -v router-create router_1
    Log    ${output}
    : FOR    ${SubnetElement}    IN    @{SUBNETS_NAME}
    \    ${output}=    Write Commands Until Prompt    neutron -v router-interface-add router_1 ${SubnetElement}
    Log    ${output}

Remove Interface
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${SubnetElement}    IN    @{SUBNETS_NAME}
    \    ${output}=    Write Commands Until Prompt    neutron -v router-interface-delete router_1 ${SubnetElement}
    \    Log    ${output}

Delete Router
    [Documentation]    Delete Router and Interface to the subnets.
    ${output}=    Write Commands Until Prompt    neutron -v router-delete router_1
    Log    ${output}
