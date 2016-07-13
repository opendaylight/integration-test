*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup Tests    source_pwd=yes
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/ClusterOvsdb.robot
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/ClusterOvsdb.robot

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
@{cluster_down_list}    1    2
@{SUBNETS_RANGE}    70.0.0.0/24    80.0.0.0/24

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three contorllers.
    ClusterKeywords.Create Controller Sessions

Create Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check OVS Manager Connection Status
    [Documentation]    This will verify if the OVS manager is connected
    ${output}=    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${OS_CONTROL_NODE_IP}
    Log    ${output}
    Set Suite Variable    ${status}    is_connected: true
    ${dictionary}=    Create Dictionary    ${status}=9
    Utils.Check Item Occurrence    ${output}    ${dictionary}

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For l2_net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_net_1    l2_sub_net_1    @{SUBNETS_RANGE}[0]

Create Subnets For l2_net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_net_2    l2_sub_net_2    @{SUBNETS_RANGE}[1]

Create Bridge Manually and Verify Before Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${original_cluster_list}    ${OS_CONTROL_NODE_IP}

Add Tap Device Manually and Verify Before Fail
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${original_cluster_list}    ${OS_CONTROL_NODE_IP}

Delete the Bridge Manually and Verify Before Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${original_cluster_list}    ${OS_CONTROL_NODE_IP}

Take Down ODL1
    [Documentation]    Kill the karaf in First Controller
    ClusterKeywords.Kill Multiple Controllers    1
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove From List    ${new_cluster_list}    0
    Set Suite Variable    ${new_cluster_list}

Create Bridge Manually and Verify After Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${new_cluster_list}    ${OS_CONTROL_NODE_IP}

Add Tap Device Manually and Verify After Fail
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${new_cluster_list}    ${OS_CONTROL_NODE_IP}

Delete the Bridge Manually and Verify After Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${new_cluster_list}    ${OS_CONTROL_NODE_IP}

Create Vm Instances For l2_net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Log    ${devstack_conn_id}
    Create Vm Instances    l2_net_1    ${NET_1_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    ClusterKeywords.Start Multiple Controllers    300s    1
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Create Bridge Manually and Verify After Recover
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${original_cluster_list}    ${OS_CONTROL_NODE_IP}

Add Tap Device Manually and Verify After Recover
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${original_cluster_list}    ${OS_CONTROL_NODE_IP}

Delete the Bridge Manually and Verify After Recover
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${original_cluster_list}    ${OS_CONTROL_NODE_IP}

Take Down ODL2
    [Documentation]    Kill the karaf in Second Controller
    ClusterKeywords.Kill Multiple Controllers    2
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove From List    ${new_cluster_list}    1
    Set Suite Variable    ${new_cluster_list}

Create Vm Instances For l2_net_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_net_2    ${NET_2_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_2_VM_INSTANCES}

Bring Up ODL2
    [Documentation]    Bring up ODL2 again
    ClusterKeywords.Start Multiple Controllers    300s    2
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Ping Vm Instance1 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_net_1    @{NET_1_VM_IPS}[2]

Ping Vm Instance1 In l2_net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_net_2    @{NET_2_VM_IPS}[0]

Ping Vm Instance2 In l2_net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_net_2    @{NET_2_VM_IPS}[1]

Ping Vm Instance3 In l2_net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_net_2    @{NET_2_VM_IPS}[2]

Take Down ODL3
    [Documentation]    Kill the karaf in Third Controller
    ClusterKeywords.Kill Multiple Controllers    3
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove From List    ${new_cluster_list}    2
    Set Suite Variable    ${new_cluster_list}

Connectivity Tests From Vm Instance1 In l2_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_net_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}

Connectivity Tests From Vm Instance2 In l2_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_net_1    @{NET_1_VM_IPS}[1]    ${dst_ip_list}

Connectivity Tests From Vm Instance3 In l2_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_net_1    @{NET_1_VM_IPS}[2]    ${dst_ip_list}

Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    ClusterKeywords.Start Multiple Controllers    300s    3
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Take Down ODL1 and ODL2
    [Documentation]    Kill the karaf in First and Second Controller
    : FOR    ${index}    IN    @{cluster_down_list}
    \    ClusterKeywords.Kill Multiple Controllers    ${index}

Connectivity Tests From Vm Instance1 In l2_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[1]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_net_2    @{NET_2_VM_IPS}[0]    ${dst_ip_list}

Connectivity Tests From Vm Instance2 In l2_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_net_2    @{NET_2_VM_IPS}[1]    ${dst_ip_list}

Connectivity Tests From Vm Instance3 In l2_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[1]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_net_2    @{NET_2_VM_IPS}[2]    ${dst_ip_list}

Bring Up ODL1 and ODL2
    [Documentation]    Bring up ODL1 and ODL2 again.
    : FOR    ${index}    IN    @{cluster_down_list}
    \    ClusterKeywords.Start Multiple Controllers    300s    ${index}

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    VmInstance1_l2_net_1

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping From DHCP Should Not Succeed    l2_network_1    @{NET_1_VM_IPS}[0]

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_sub_net_1

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_sub_net_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}

Delete Internal bridge and Verify
    [Documentation]    Delete internal bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Internal Bridge Manually And Verify    ${original_cluster_list}
    [Teardown]    Report_Failure_Due_To_Bug    6262

Delete External bridge and Verify
    [Documentation]    Delete external bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete External Bridge Manually And Verify    ${original_cluster_list}
    [Teardown]    Report_Failure_Due_To_Bug    6262

Cleans Up Test Environment For Next Suite
    [Documentation]    Cleans up test environment, close existing sessions in teardown.
    Log    ${original_cluster_list}
    ClusterOvsdb.Configure Exit Netvirt Connection    ${original_cluster_list}
    [Teardown]    Report_Failure_Due_To_Bug    6262

