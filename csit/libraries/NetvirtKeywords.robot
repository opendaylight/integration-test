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

Delete SubNet
    [Arguments]    ${subnet_name}
    [Documentation]    Delete SubNet with neutron request.
    : FOR    ${SubnetElement}    IN    @{SUBNETS_NAME}
    \    ${output}=    Write Commands Until Prompt    neutron -v subnet-delete ${SubnetElement}
    Log    ${output}

Create Vm Instance
    [Arguments]    ${net_id}
    [Documentation]    Create Vm Instance with the net id of the Netowrk.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_NAME}
    \    ${output}=    Write Commands Until Prompt     nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic net-id=${net_id} ${VmElement}
    Log    ${output}

Show Details Of Instance
    [Arguments]   ${instace_name}
    [Documentation]    Show the details of Vm Instance with the net id of the Netowrk.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_NAME}
    \    ${output}=    Write Commands Until Prompt    nova show ${VmElement}
    Log    ${output}

Delete Vm Instances Using NetId
    [Arguments]    ${vm_netid}
    [Documentation]    Delete Vm instances using instance names.
    ${output}=   Write Commands Until Prompt     nova delete ${vm_netid}
    Log    ${output}

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

Get Instance Id
    [Arguments]    ${instace_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    ${output}=   Write Commands Until Prompt    nova show ${instace_name} | grep " id " | get_field 2
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    \
    ${instance_id}=    Get from List    ${splitted_output}    0
    Log    ${instance_id}
    [Return]    ${instance_id}

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    ${output}=   Write Commands Until Prompt     neutron -v router-create router1
    Log    ${output}
    : FOR    ${SubnetElement}    IN    @{SUBNETS_NAME}
    \    ${output}=   Write Commands Until Prompt     neutron -v router-interface-add router1 ${SubnetElement}
    Log    ${output}

Delete Router
    [Documentation]    Delete Router and Interface to the subnets.
    ${output}=   Write Commands Until Prompt     neutron -v router-delete router1
    Log    ${output}

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

Advanced Creates a networks
    [Documentation]   Creates a network that all tenants can use.
    ${output}=   Write Commands Until Prompt     neutron -v net-create --shared public-net
    Log    ${output}

Creates a subnet with a specified gateway IPS
    [Arguments]    ${network_name}
    [Documentation]   Creates a subnet with a specified gateway IP address.
    ${output}=   Write Commands Until Prompt     neutron -v subnet-create --gateway 10.0.0.254 ${network_name} 10.0.0.0/24
    Log    ${output}

Creates a subnet that has no gateway IPS
    [Arguments]    ${network_name}
    [Documentation]   Creates a subnet that has no gateway IP address.
    ${output}=   Write Commands Until Prompt     neutron -v subnet-create --no-gateway ${network_name} 10.0.0.0/24
    Log    ${output}

Creates a subnet with DHCP disabled
    [Arguments]    ${network_name}
    [Documentation]   Creates a subnet with DHCP disabled.
    ${output}=   Write Commands Until Prompt     neutron subnet-create ${network_name} 10.0.0.0/24 --enable-dhcp False
    Log    ${output}

Set of host routes
    [Arguments]    ${subnet_name}
    [Documentation]   Specifies a set of host routes.
    ${output}=   Write Commands Until Prompt     neutron -v subnet-create ${subnet_name} 40.0.0.0/24 --host-routes type=dict list=true destination=40.0.1.0/24, nexthop=40.0.0.2
    Log    ${output}

Creates a subnet with a specified set of dns name servers
    [Arguments]    ${subnet_name}
    [Documentation]  Creates a subnet with a specified set of dns name servers .
    ${output}=   Write Commands Until Prompt     neutron -v subnet-create ${subnet_name} 40.0.0.0/24 --dns-nameservers list=true 8.8.4.4 8.8.8.8
    Log    ${output}

Displays all ports and IPS
    [Arguments]    ${subnet_name}
    [Documentation]  Creates a subnet with a specified set of dns name servers .
    ${output}=   Write Commands Until Prompt     neutron -v port-list --network_id NET_ID
    Log    ${output}
