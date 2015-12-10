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
    Write Commands Until Prompt    neutron -v net-delete ${network_name}
    Log    ${output}

Create SubNet
    [Arguments]    ${network_name}
    [Documentation]    Create SubNet for the Network with neutron request.
    : FOR    ${SubnetElement}    IN    @{SUBNETS_NAME}
    \    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${network_name} 10.0.0.0/24 --name ${SubnetElement}
    Log    ${output}

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
