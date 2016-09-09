*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup Tests    source_pwd=yes
Suite Teardown    Close All Connections
Test Teardown     Run Keywords    Show Debugs    ${NET_1_VM_INSTANCES}
...               AND    Show Debugs    ${NET_2_VM_INSTANCES}
...               AND    Get OvsDebugInfo
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterManagement.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS_NAME}    l2_net_1    l2_net_2
@{SUBNETS_NAME}    l2_sub_net_1    l2_sub_net_2
@{NET_1_VM_INSTANCES}    VmInstance1_l2_net_1    VmInstance2_net_1    VmInstance3_net_1
@{NET_2_VM_INSTANCES}    VmInstance1_l2_net_2    VmInstance2_net_2    VmInstance3_net_2
@{NET_1_VM_IPS}    70.0.0.3    70.0.0.4    70.0.0.5
@{NET_2_VM_IPS}    80.0.0.3    80.0.0.4    80.0.0.5
@{VM_IPS_NOT_DELETED}    70.0.0.4
@{GATEWAY_IPS}    70.0.0.1    80.0.0.1
@{DHCP_IPS}       70.0.0.2    80.0.0.2
@{cluster_down_list}    ${1}    ${2}
@{SUBNETS_RANGE}    70.0.0.0/24    80.0.0.0/24

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three contorllers.
    ClusterManagement.ClusterManagement Setup

Check OVS Manager Connection Status
    [Documentation]    This will verify if the OVS manager is connected
    ${output}=    Wait Until Keyword Succeeds    5s    1s    Ovsdb.Verify OVS Reports Connected    ${OS_CONTROL_NODE_IP}
    Log    ${output}
    Set Suite Variable    ${status}    is_connected: true
    ${dictionary}=    Create Dictionary    ${status}=9
    Utils.Check Item Occurrence    ${output}    ${dictionary}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP packets for testing
    Create Security Group      csit    "CSIT SSH Allow"
    Create Security Rule     ingress      tcp     1     65535     0.0.0.0/0      csit
    Create Security Rule     egress       tcp     1     65535     0.0.0.0/0      csit

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Create Network    ${NetworkElement}

Create Subnets For l2_net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    l2_net_1    l2_sub_net_1    @{SUBNETS_RANGE}[0]

Create Subnets For l2_net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    l2_net_2    l2_sub_net_2    @{SUBNETS_RANGE}[1]

Create Vm Instances For l2_net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Log    ${devstack_conn_id}
    OpenStackOperations.Create Vm Instances    l2_net_1    ${NET_1_VM_INSTANCES}     sg=csit

Ping Vm Instance1 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[2]

Take Down ODL1
    [Documentation]    Kill the karaf in First Controller
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    1
    Set Suite Variable    ${new_cluster_list}

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Create Vm Instances For l2_net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Log    ${devstack_conn_id}
    OpenStackOperations.Create Vm Instances    l2_net_1    ${NET_1_VM_INSTANCES}     sg=csit

Ping Vm Instance1 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[2]

Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    ClusterManagement.Start Single Member    1

Take Down ODL2
    [Documentation]    Kill the karaf in Third Controller
    ClusterManagement.Kill Single Member    2

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Create Vm Instances For l2_net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Log    ${devstack_conn_id}
    OpenStackOperations.Create Vm Instances    l2_net_1    ${NET_1_VM_INSTANCES}     sg=csit

Ping Vm Instance1 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[2]

Bring Up ODL2
    [Documentation]    Bring up ODL3 again
    ClusterManagement.Start Single Member    2

Take Down ODL3
    [Documentation]    Kill the karaf in Third Controller
    ClusterManagement.Kill Single Member    3

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Create Vm Instances For l2_net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Log    ${devstack_conn_id}
    OpenStackOperations.Create Vm Instances    l2_net_1    ${NET_1_VM_INSTANCES}     sg=csit

Ping Vm Instance1 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[2]

Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    ClusterManagement.Start Single Member    3

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    l2_sub_net_1

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    l2_sub_net_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Delete Network    ${NetworkElement}
