*** Settings ***
Documentation     Test suite to verify live Migaration of VM instance also verify the connectivity
...               of VM instance while Migrating the instance,
Suite Setup       Suite Setup
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
    FOR    ${vm}    IN    @{vm_list}
        BuiltIn.Wait Until Keyword Succeeds    6x    20s    OpenStackOperations.Check If Migration Is Complete    ${vm}
    END
    ${vm_host_after_migration} =    OpenStackOperations.Get Hypervisor Host Of Vm    @{NET_1_VMS}[0]
    BuiltIn.Run Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    BuiltIn.Should Match    ${vm_host_after_migration}    ${vm_host_before_migration}
    ...    ELSE    BuiltIn.Should Not Match    ${vm_host_after_migration}    ${vm_host_before_migration}
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    RemoteBash.Write_Bare_Ctrl_C
    ${output} =    SSHLibrary.Read Until    packet loss
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    DevstackUtils.Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 10 @{NET1_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    64 bytes

*** Keywords ***
Suite Setup
    LiveMigration.Live Migration Suite Setup
    OpenstackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNETS_RANGE}[0]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    OpenStackOperations.Get Suite Debugs
