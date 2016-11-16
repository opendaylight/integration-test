*** Settings ***
Documentation     Test suite to check North-South connectivity in L3 using a router and an external network
Suite Setup       Devstack Suite Setup Tests    source_pwd=yes
Suite Teardown    Close All Connections
Test Teardown     Run Keywords    Show Debugs    ${VM_INSTANCES}
...               AND    Get OvsDebugInfo
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    l3_net
@{SUBNETS_NAME}    l3_sub_net
@{VM_INSTANCES}    VmInstance1_net
@{VM_IPS}    90.0.0.3
@{DHCP_IPS}       90.0.0.2
@{SUBNETS_RANGE}    90.0.0.0/24
${external_gateway}    10.10.10.250
${external_subnet}    10.10.10.0/24
${external_physical_network}    physnet1
${vm_floating_ip}    10.10.10.3

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three contorllers.
    ClusterManagement.ClusterManagement Setup

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Create Network    ${NetworkElement}

Create Subnets For l3_net
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    l3_net    l3_sub_net    @{SUBNETS_RANGE}[0]

Create External Network
    Create Network    external-net --router:external --provider:network_type=flat --provider:physical_network=${external_physical_network}
    Create Subnet    external-net    external-subnet    ${external_subnet}   --gateway ${external_gateway}

Create Router router
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    router
    [Teardown]

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    router    ${interface}

Add Router Gateway To Router
    [Documentation]    Add Router Gateway
    OpenStackOperations.Add Router Gateway    router    external-net

Verify Created Routers
    [Documentation]    Check created routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    Log    ${data}
    Should Contain    ${data}    router_3


Create Vm Instances For l3_net
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    l3_net    ${VM_INSTANCES}    sg=csit

Ping External Gateway From Control Node
    [Documentation]    Check reachability of VM instances through floating IPs by pinging them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From Control Node    ${external_gateway}

Ping Vm Instance1 Floating IP From Control Node
    [Documentation]    Check reachability of VM instances through floating IPs by pinging them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From Control Node    ${vm_floating_ip}

Delete Vm Instances In l3_net
    [Documentation]    Delete Vm instances using instance names in l3_net.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Remove Interface    router_3    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    OpenStackOperations.Delete Router    router

Verify Deleted Routers
    [Documentation]    Check deleted routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    Log    ${data}
    Should Not Contain    ${data}    router

Delete Sub Networks In l3_net
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    l3_sub_net

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Delete Network    ${NetworkElement}
