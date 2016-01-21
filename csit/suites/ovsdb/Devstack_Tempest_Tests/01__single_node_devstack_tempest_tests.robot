*** Settings ***
Documentation     Test suite to deploy devstack with networking-odl
Suite Setup       Devstack Suite Setup
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/NetvirtKeywords.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    net1_network    net2_network    net3_network    net4_network
@{SUBNETS_NAME}    subnet1    subnet2    subnet3    subnet4
@{VM_INSTANCES_NAME}    MyFirstInstance    MySecondInstance    MyThirdInstance    MyFourthInstance
@{VM_IPS}    10.0.0.3    20.0.0.3    30.0.0.3    40.0.0.3
@{GATEWAY_IPS}    10.0.0.1    20.0.0.1


*** Test Cases ***
Run Devstack Gate Wrapper
    Write Commands Until Prompt    unset GIT_BASE
    Write Commands Until Prompt    env
    ${output}=    Write Commands Until Prompt    ./devstack-gate/devstack-vm-gate-wrap.sh    timeout=3600s    #60min
    Log    ${output}
    Should Not Contain    ${output}    ERROR: the main setup script run by this job failed
    # workaround for https://bugs.launchpad.net/networking-odl/+bug/1512418
    Write Commands Until Prompt    cd /opt/stack/new/tempest-lib
    Write Commands Until Prompt    sudo python setup.py install
    [Teardown]    Show Devstack Debugs

Validate Neutron and Networking-ODL Versions
    ${output}=    Write Commands Until Prompt    cd /opt/stack/new/neutron; git branch;
    Should Contain    ${output}    * ${OPENSTACK_BRANCH}
    ${output}=    Write Commands Until Prompt    cd /opt/stack/new/networking-odl; git branch;
    Should Contain    ${output}    * ${NETWORKING-ODL_BRANCH}

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Test subnet
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create net1_network 10.0.0.0/24 --name subnet1
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create net2_network 20.0.0.0/24 --name subnet2
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create net3_network 30.0.0.0/24 --name subnet3
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create net4_network 40.0.0.0/24 --name subnet4
    Log    ${output}

Test List Ports
    ${output}=   Write Commands Until Prompt     neutron -v port-list
    Log    ${output}

Test List Available Networks
    ${output}=   Write Commands Until Prompt     neutron -v net-list
    Log    ${output}
    ${output}=   Write Commands Until Prompt    neutron net-list -F id -F name -f json
    Log    ${output}

Test Tenant list
    ${output}=   Write Commands Until Prompt     keystone tenant-list
    Log    ${output}

Test novalist
    ${output}=   Write Commands Until Prompt     nova list
    Log    ${output}

Test imagelist
    ${output}=   Write Commands Until Prompt     nova image-list
    Log    ${output}

Test flavor list
    ${output}=   Write Commands Until Prompt     nova flavor-list
    Log    ${output}

Create Vm Instances
    [Documentation]    Create Vm instances using flavor and image names.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    ${net_id}=    Get Net Id    ${NetworkElement}
    Create Vm Instance    ${net_id}

Test Details of Created Vm Instance
    [Documentation]    View Details of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_NAME}
    \    ${output}=     Show Details Of Instance   ${VmElement}
    Log    ${output}

Verify Created Vm Instance In Dump Flow
    [Documentation]    Verify the existence of the created vm instance ips in the dump flow.
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${VmIpElement}    IN    @{VM_IPS}
    \    Should Contain    ${output}    ${VmIpElement}

Delete Vm Instances Using Ids
    [Documentation]    Delete Vm instances using instance names.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_NAME}
    \    ${instance_id}=    Get Instance Id    ${VmElement}
    \    Delete Vm Instances Using NetId    ${instance_id}

Verify Instance Removed For The Deleted Network
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    30.0.0.3

Delete Sub Networks
    ${output}=    Write Commands Until Prompt    neutron -v subnet-delete subnet3
    Log    ${output}

Delete Networks
    ${output}=    Write Commands Until Prompt    neutron -v net-delete net3_network
    Log    ${output}

Verify Dhcp Removed For The Deleted Network
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    30.0.0.2

Verify Gateway Ip Removed For The Deleted Network
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    30.0.0.1

Verify No Presence Of Removed Network In Dump Flow
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    30.0.0.3

Create Routers
    [Documentation]    Create Router and Add Interface to the subnets.
    Create Router
