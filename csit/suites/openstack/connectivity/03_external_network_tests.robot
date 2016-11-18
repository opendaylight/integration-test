*** Settings ***
Documentation     Test suite to check North-South connectivity in L3 using a router and an external network
Suite Setup       Devstack Suite Setup    source_pwd=yes
Suite Teardown    Close All Connections
Test Teardown     Get OvsDebugInfo
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    l3_net
@{SUBNETS_NAME}    l3_subnet
@{VM_INSTANCES}    VmInstance1_net    VmInstance2_net
@{SUBNETS_RANGE}    90.0.0.0/24
${external_gateway}    10.10.10.250
${external_subnet}    10.10.10.0/24
${external_physical_network}    physnet1
${external_net_name}    external-net
${external_subnet_name}    external-subnet

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three controllers
    ClusterManagement.ClusterManagement Setup

Create Private Network
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Create Network    ${NetworkElement}

Create Subnet For Private Network
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Create External Network And Subnet
    Create Network    ${external_net_name} --router:external --provider:network_type=flat --provider:physical_network=${external_physical_network}
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway}

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    router1

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    router1    ${interface}

Add Router Gateway To Router
    [Documentation]    Add Router Gateway
    OpenStackOperations.Add Router Gateway    router1    ${external_net_name}

Verify Created Routers
    [Documentation]    Check created routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    Log    ${data}
    Should Contain    ${data}    router1

Create Vm Instances
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM_INSTANCES}    sg=csit

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}
    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES}    parse_dhcp_ip=false
    [Teardown]    Run Keywords    Show Debugs    ${VM_INSTANCES}
    ...    AND    Get OvsDebugInfo

Create And Associate Floating IPs for VMs
    [Documentation]    Create and associate a floating IP for the VM
    ${VM_FLOATING_IPS}    OpenStackOperations.Create And Associate Floating IPs    ${external_net_name}    @{VM_INSTANCES}
    Set Suite Variable    ${VM_FLOATING_IPS}
    [Teardown]    Run Keywords    Show Debugs    ${VM_INSTANCES}
    ...    AND    Get OvsDebugInfo

Ping External Gateway From Control Node
    [Documentation]    Check reachability of external gateway by pinging it from the control node.
    OpenStackOperations.Ping Vm From Control Node    ${external_gateway}

Ping Vm Instance1 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]

Ping Vm Instance2 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[1]

Delete Vm Instances
    [Documentation]    Delete Vm instances using instance names.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Remove Interface    router1    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    OpenStackOperations.Delete Router    router1

Verify Deleted Routers
    [Documentation]    Check deleted routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    Log    ${data}
    Should Not Contain    ${data}    router1

Delete Sub Networks
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS_NAME}[0]

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Delete Network    ${NetworkElement}
    OpenStackOperations.Delete Network    ${external_net_name}
