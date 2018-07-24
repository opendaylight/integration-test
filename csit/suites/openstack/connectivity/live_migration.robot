*** Settings ***
Documentation     Test suite to verify live Migaration of VM instance also verify the connectivity
...               of VM instance while Migrating the instance,
Suite Setup       LiveMigration.Live Migration Suite Setup
Suite Teardown    LiveMigration.Live Migration Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/LiveMigration.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/RemoteBash.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SECURITY_GROUP}    migration_sg
@{NETWORKS}       migration_net_1
@{SUBNETS}        migration_sub_1
@{NET_1_VMS}      migration_net_1_vm_1    migration_net_1_vm_2
@{SUBNETS_RANGE}    130.0.0.0/24

*** Test Cases ***
Create VXLAN Network migration_net_1
    [Documentation]    Create Network with neutron request.
    OpenstackOperations.Create Network    @{NETWORKS}[0]

Create Subnets For migration_net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNETS_RANGE}[0]

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances For migration_net_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Migrate Instance And Verify Connectivity While Migration And After
    [Documentation]    migrate the server to different host.
    ...    and check the connectivity during Migration
    ...    with a ping test from DHCP NS.
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${devstack_conn_id} =    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output} =    SSHLibrary.Write    sudo ip netns exec qdhcp-${net_id} ping @{NET1_VM_IPS}[0]
    ${vm_host_before_migration} =    OpenStackOperations.Get Hypervisor Host Of Vm    @{NET_1_VMS}[0]
    OpenStackOperations.Server Live Migrate    @{NET_1_VMS}[0]
    ${vm_list} =    BuiltIn.Create List    @{NET_1_VMS}[0]
    : FOR    ${vm}    IN    @{vm_list}
    \    BuiltIn.Wait Until Keyword Succeeds    6x    20s    OpenStackOperations.Check If Migration Is Complete    ${vm}
    ${vm_host_after_migration} =    OpenStackOperations.Get Hypervisor Host Of Vm    @{NET_1_VMS}[0]
    BuiltIn.Run Keyword If    "${OS_DEPLOY}" == "1cmb-0ctl-0cmp"    BuiltIn.Should Match    ${vm_host_after_migration}    ${vm_host_before_migration}
    ...    ELSE    BuiltIn.Should Not Match    ${vm_host_after_migration}    ${vm_host_before_migration}
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    RemoteBash.Write_Bare_Ctrl_C
    ${output} =    SSHLibrary.Read Until    packet loss
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    DevstackUtils.Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 10 @{NET1_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    64 bytes

Delete Vm Instances In migration_net_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Sub Networks In migration_net_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS}[0]

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${NetworkElement}

Delete SecurityGroup
    [Documentation]    Delete SecurityGroup with neutron request.
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}
