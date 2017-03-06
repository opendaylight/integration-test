*** Settings ***
Documentation     Test suite to check North-South connectivity in L3 using a router and an external network
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
@{NETWORKS_NAME}    l3_net
@{SUBNETS_NAME}    l3_subnet
@{VM_INSTANCES_FLOATING}    VmInstanceFloating1    VmInstanceFloating2
@{VM_INSTANCES_SNAT}    VmInstanceSnat3    VmInstanceSnat4
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

Create Vm Instances
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM_INSTANCES_FLOATING}    sg=csit
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM_INSTANCES_SNAT}    sg=csit

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{VM_INSTANCES_FLOATING}    @{VM_INSTANCES_SNAT}
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}
    ${FLOATING_VM_COUNT}    Get Length    ${VM_INSTANCES_FLOATING}
    ${SNAT_VM_COUNT}    Get Length    ${VM_INSTANCES_SNAT}
    ${LOOP_COUNT}    Evaluate    ${FLOATING_VM_COUNT}+${SNAT_VM_COUNT}
    : FOR    ${index}    IN RANGE    1    ${LOOP_COUNT}
    \    ${FLOATING_VM_IPS}    ${FLOATING_DHCP_IP}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease
    \    ...    @{VM_INSTANCES_FLOATING}
    \    ${SNAT_VM_IPS}    ${SNAT_DHCP_IP}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease
    \    ...    @{VM_INSTANCES_SNAT}
    \    ${FLOATING_VM_LIST_LENGTH}=    Get Length    ${FLOATING_VM_IPS}
    \    ${SNAT_VM_LIST_LENGTH}=    Get Length    ${SNAT_VM_IPS}
    \    Exit For Loop If    ${FLOATING_VM_LIST_LENGTH}==${FLOATING_VM_COUNT} and ${SNAT_VM_LIST_LENGTH}==${SNAT_VM_COUNT}
    Append To List    ${FLOATING_VM_IPS}    ${FLOATING_DHCP_IP}
    Set Suite Variable    ${FLOATING_VM_IPS}
    Append To List    ${SNAT_VM_IPS}    ${SNAT_DHCP_IP}
    Set Suite Variable    ${SNAT_VM_IPS}
    [Teardown]    Run Keywords    Show Debugs    ${VM_INSTANCES_FLOATING}    ${VM_INSTANCES_SNAT}
    ...    AND    Get Test Teardown Debugs

Create External Network And Subnet
    Run Keyword If    '${OPENSTACK_BRANCH}'=='stable/mitaka'    Create Network    ${external_net_name}     --router:external --provider:network_type=flat --provider:physical_network=${external_physical_network}
    ...    ELSE    Create Network    ${external_net_name}     --external --provider-network-type flat --provider-physical-network ${external_physical_network}
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

Create And Associate Floating IPs for VMs
    [Documentation]    Create and associate a floating IP for the VM
    ${VM_FLOATING_IPS}    OpenStackOperations.Create And Associate Floating IPs    ${external_net_name}    @{VM_INSTANCES_FLOATING}
    Set Suite Variable    ${VM_FLOATING_IPS}
    [Teardown]    Run Keywords    Show Debugs    ${VM_INSTANCES_FLOATING}
    ...    AND    Get Test Teardown Debugs

Ping External Gateway From Control Node
    [Documentation]    Check reachability of external gateway by pinging it from the control node.
    OpenStackOperations.Ping Vm From Control Node    ${external_gateway}

Ping Vm Instance1 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]

Ping Vm Instance2 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[1]

Prepare SNAT - Install Netcat On Controller
    Install Netcat On Controller

SNAT - TCP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    Test Netcat Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{SNAT_VM_IPS}[0]    ${external_gateway}

SNAT - UDP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    Test Netcat Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{SNAT_VM_IPS}[0]    ${external_gateway}    -u

SNAT - TCP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    Test Netcat Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{SNAT_VM_IPS}[1]    ${external_gateway}

SNAT - UDP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    Test Netcat Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{SNAT_VM_IPS}[1]    ${external_gateway}    -u

Delete Vm Instances
    [Documentation]    Delete Vm instances using instance names.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_FLOATING}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_SNAT}
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
