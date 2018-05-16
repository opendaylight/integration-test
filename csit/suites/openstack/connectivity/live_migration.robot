*** Settings ***
Documentation     Test suite to verify live Migaration of VM instance also verify the connectivity
...               of VM instance while Migrating the instance,
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/RemoteBash.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${SECURITY_GROUP}    migration_sg
@{NETWORKS_NAME}    migration_network_1
@{SUBNETS_NAME}    migration_subnet_1
@{NET_1_VM_INSTANCES}    migration_instance_1    migration_instance_2
@{SUBNETS_RANGE}    30.0.0.0/24

*** Test Cases ***
Configure Live Migration
    [Documentation]    Set instances to be created in the shared directory.
    OpenStackOperations.Modify OpenStack Configuration File    ${OS_CMP1_CONN_ID}    /etc/nova/nova-cpu.conf    DEFAULT    instances_path    ${CMP_INSTANCES_SHARED_PATH}
    OpenStackOperations.Modify OpenStack Configuration File    ${OS_CMP2_CONN_ID}    /etc/nova/nova-cpu.conf    DEFAULT    instances_path    ${CMP_INSTANCES_SHARED_PATH}
    OpenStackOperations.Restart DevStack Service    ${OS_CMP1_CONN_ID}    n-cpu
    OpenStackOperations.Restart DevStack Service    ${OS_CMP2_CONN_ID}    n-cpu

Create VXLAN Network (network_1)
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[0]

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances For l2_network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VM_INSTANCES}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Migrate Instance And Verify Connectivity While Migration And After
    [Documentation]    migrate the server to different host.
    ...    and check the connectivity during Migration
    ...    with a ping test from DHCP NS.
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write    sudo ip netns exec qdhcp-${net_id} ping @{NET1_VM_IPS}[0]
    ${VM_HOST} =    Get Hypervisor Host Of Vm    @{NET_1_VM_INSTANCES}[0]
    Server Live Migrate    @{NET_1_VM_INSTANCES}[0]
    ${VM1} =    Create List    @{NET_1_VM_INSTANCES}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    BuiltIn.Wait Until Keyword Succeeds    6x    20s    Check If Migration Is Complete    ${vm}
    ${output} =    Get Hypervisor Host Of Vm    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    ${VM_HOST}
    Switch Connection    ${devstack_conn_id}
    Write_Bare_Ctrl_C
    ${output} =    Read Until    packet loss
    Should Contain    ${output}    64 bytes
    ${output} =    Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 10 @{NET1_VM_IPS}[0]
    Should Contain    ${output}    64 bytes

Delete Vm Instances In Migration_network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Sub Networks In Migration_network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    @{SUBNETS_NAME}[0]

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}

Delete SecurityGroup
    [Documentation]    Delete SecurityGroup with neutron request.
    Delete SecurityGroup    ${SECURITY_GROUP}
