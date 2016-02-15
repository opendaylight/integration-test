*** Settings ***
Documentation     Test suite to verify flows between vm instances.
Suite Setup       Devstack Suite Setup
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenstackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    net1_network    net2_network
@{SUBNETS_NAME}    subnet1    subnet2
@{VM_INSTANCES_NAME}    MyFirstInstance    MySecondInstance    MyThirdInstance    MyFourthInstance
@{VM_IPS}    10.0.0.3    10.0.0.4    10.0.0.5    10.0.0.6
@{GATEWAY_IPS}    10.0.0.1    20.0.0.1
@{DHCP_IPS}    10.0.0.2    20.0.0.2

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

tempest.api.network
    Run Tempest Tests    ${TEST_NAME}

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create SubNet    ${NetworkElement}

Create Vm Instances For A Network
    [Documentation]    Create More Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    net1_network
    Set Suite Variable    ${net_id}
    Create Vm Instances    ${net_id}

Show Details of Created Vm Instance
    [Documentation]    View Details of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_NAME}
    \    ${output}=   Write Commands Until Prompt     nova show ${VmElement}
    \    Log    ${output}

Show Console Log of Created Vm Instance
    [Documentation]    View Console log of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_NAME}
    \    ${output}=   Write Commands Until Prompt     nova console-log ${VmElement}
    \    Log    ${output}

List Networks With Namespaces
    ${output}=   Write Commands Until Prompt     sudo ip netns list
    Log    ${output}

Verify Created Vm Instance In Dump Flow
    [Documentation]    Verify the existence of the created vm instance ips in the dump flow.
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${VmIpElement}    IN    @{VM_IPS}
    \    Should Contain    ${output}    ${VmIpElement}

Ping All Vm Instances
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm Instances    ${net_id}

Verify Vm Communication After Ping With Flows
    [Documentation]    Verify reachability of vm instances with dump flow.
    : FOR    ${VmIpElement}    IN    @{VM_IPS}
    \    ${output3}=   Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep arp_tpa=${VmIpElement}
    \    Log    ${output3}
    \    Should Contain    ${output}    n_packets=1

Create Routers
    [Documentation]    Create Router and Add Interface to the subnets.
    Create Router

Verify Gateway Ip After Interface Added
    [Documentation]    Verify the existence of the gateway ips with the dump flow in Beryllium.
    Run Keyword If    "${ODL_VERSION}" == "lithium-latest"    Run Keyword And Ignore Error    Verify Gateway Ips
    ...    ELSE IF    "${ODL_VERSION}" != "lithium-latest"    Verify Gateway Ips

Verify Dhcp Flow Entries
    [Documentation]    Verify Created SubNets for the Networks with the dump flow in Beryllium.
    Run Keyword If    "${ODL_VERSION}" == "lithium-latest"    Run Keyword And Ignore Error    Verify Dhcp Ips
    ...    ELSE IF    "${ODL_VERSION}" != "lithium-latest"    Verify Dhcp Ips

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    MyFirstInstance

Verify Deleted Vm Instance Removed In Dump Flow
    [Documentation]    Verify the non-existence of the vm instance ips in the dump flow.
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    10.0.0.3

Ping All Vm Instances
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm Instances    ${net_id}    ${is_vm_delete}=true

No Ping For MyFirstInstance
    [Documentation]    Check reachability of vm instances by pinging to them.
    Not Ping Vm Instances    ${net_id}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    Remove Interface

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router

Verify Deleted Routers
    [Documentation]    Verify Deleted Routers for the Networks with dump flow.
    Verify No Gateway Ips

Delete Sub Networks
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete SubNet    ${NetworkElement}

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}

Verify Deleted Subnets
    [Documentation]    Verify Deleted SubNets for the Networks with dump flow.
    Verify No Dhcp Ips
