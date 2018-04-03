*** Settings ***
Documentation     Test suite to verify live Migaration of VM instance also verify the connectivity
...               of VM instance while Migrating the instance,
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
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
${SECURITY_GROUP}    Migration_sg
@{NETWORKS_NAME}    Migration_network_1
@{SUBNETS_NAME}    Migration_subnet_1
@{NET_1_VM_INSTANCES}    Migration_Instance_1    Migration_Instance_2
@{SUBNETS_RANGE}    30.0.0.0/24

*** test cases ***
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

Migrate Instance
    [Documentation]    migrate the server to different host.
    ...    and check the connectivity during Migration
    ${rc}    ${hypervisors}    Run And Return Rc And Output    openstack hypervisor list -c "Hypervisor Hostname" -fvalue
    ${hypervisor_list}=    Get Hypervisor HostName
    ${VM_HOST}=    OpenStack CLI    openstack server show @{NET_1_VM_INSTANCES}[0] | grep "OS-EXT-SRV-ATTR:hypervisor_hostname" | awk '{print $4}'
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write    sudo ip netns exec qdhcp-${net_id} ping @{NET1_VM_IPS}[0]
    Run Keyword If    '${VM_HOST}' == '@{hypervisor_list}[0]'    Server Migrate    @{NET_1_VM_INSTANCES}[0]    additional_args=--live @{hypervisor_list}[1]
    ...    ELSE    Server Migrate    @{NET_1_VM_INSTANCES}[0]    additional_args=--live @{hypervisor_list}[0]
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Not Contain    ${output}    ${VM_HOST}
    Switch Connection    ${devstack_conn_id}
    Write_Bare_Ctrl_C
    ${output}=    Read Until    packet loss
    Should Contain    ${output}    64 bytes
    ${output}=    Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 10 @{NET1_VM_IPS}[0]
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
