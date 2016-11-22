*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup    source_pwd=yes
Suite Teardown    Close All Connections
Test Teardown     Run Keywords    Show Debugs    ${NET_1_VM_INSTANCES}    ${NET_2_VM_INSTANCES}
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

Create Bridge Manually and Verify Before Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}

Add Tap Device Manually and Verify Before Fail
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${OS_CONTROL_NODE_IP}

Delete the Bridge Manually and Verify Before Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}

Take Down ODL1
    [Documentation]    Kill the karaf in First Controller
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    1
    Set Suite Variable    ${new_cluster_list}

Create Bridge Manually and Verify After Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}    ${new_cluster_list}

Add Tap Device Manually and Verify After Fail
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${OS_CONTROL_NODE_IP}    ${new_cluster_list}

Delete the Bridge Manually and Verify After Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}    ${new_cluster_list}

Create Vm Instances For l2_net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Log    ${devstack_conn_id}
    OpenStackOperations.Create Vm Instances    l2_net_1    ${NET_1_VM_INSTANCES}    sg=csit

Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    ClusterManagement.Start Single Member    1

Create Bridge Manually and Verify After Recover
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}

Add Tap Device Manually and Verify After Recover
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${OS_CONTROL_NODE_IP}

Delete the Bridge Manually and Verify After Recover
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}

Take Down ODL2
    [Documentation]    Kill the karaf in Second Controller
    ClusterManagement.Kill Single Member    2

Create Vm Instances For l2_net_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    l2_net_2    ${NET_2_VM_INSTANCES}    sg=csit

Bring Up ODL2
    [Documentation]    Bring up ODL2 again
    ClusterManagement.Start Single Member    2

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

Ping Vm Instance1 In l2_net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_2    @{NET_2_VM_IPS}[0]

Ping Vm Instance2 In l2_net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_2    @{NET_2_VM_IPS}[1]

Ping Vm Instance3 In l2_net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l2_net_2    @{NET_2_VM_IPS}[2]

Take Down ODL3
    [Documentation]    Kill the karaf in Third Controller
    ClusterManagement.Kill Single Member    3

Connectivity Tests From Vm Instance1 In l2_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l2_net_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}

Connectivity Tests From Vm Instance2 In l2_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l2_net_1    @{NET_1_VM_IPS}[1]    ${dst_ip_list}

Connectivity Tests From Vm Instance3 In l2_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l2_net_1    @{NET_1_VM_IPS}[2]    ${dst_ip_list}

Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    ClusterManagement.Start Single Member    3

Take Down ODL1 and ODL2
    [Documentation]    Kill the karaf in First and Second Controller
    ClusterManagement.Kill Members From List Or All    ${cluster_down_list}

Connectivity Tests From Vm Instance1 In l2_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[1]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l2_net_2    @{NET_2_VM_IPS}[0]    ${dst_ip_list}

Connectivity Tests From Vm Instance2 In l2_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l2_net_2    @{NET_2_VM_IPS}[1]    ${dst_ip_list}

Connectivity Tests From Vm Instance3 In l2_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[1]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l2_net_2    @{NET_2_VM_IPS}[2]    ${dst_ip_list}

Bring Up ODL1 and ODL2
    [Documentation]    Bring up ODL1 and ODL2 again.
    ClusterManagement.Start Members From List Or All    ${cluster_down_list}

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    OpenStackOperations.Delete Vm Instance    VmInstance1_l2_net_1

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    OpenStackOperations.Ping From DHCP Should Not Succeed    l2_network_1    @{NET_1_VM_IPS}[0]

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

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
