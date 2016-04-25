*** Settings ***
Documentation    Test suite to verify packet flows between vm instances.
Suite Setup    Devstack Suite Setup Tests     source_pwd=yes
Suite Teardown      Close All Connections
Library    SSHLibrary
Library    OperatingSystem
Library    RequestsLibrary
Library    Collections
Resource    ../../../libraries/Utils.robot
Resource    ../../../libraries/OpenStackOperations.robot
Resource    ../../../libraries/DevstackUtils.robot
Resource    ../../../libraries/OVSDB.robot
Library    ../../../libraries/Common.py
Variables    ../../../variables/Variables.py
Resource    ../../../libraries/ClusterKeywords.robot

*** Variables ***
@{NETWORKS_NAME}    l2_net_1    l2_net_2
@{SUBNETS_NAME}    l2_sub_net_1    l2_sub_net_2
@{NET_1_VM_INSTANCES}    VmInstance1_l2_net_1    VmInstance2_net_1
@{NET_2_VM_INSTANCES}    VmInstance1_l2_net_2    VmInstance2_net_2
@{NET_1_VM_IPS}    70.0.0.3    70.0.0.4
@{NET_2_VM_IPS}    80.0.0.3    80.0.0.4
@{VM_IPS_NOT_DELETED}    70.0.0.4
@{GATEWAY_IPS}    70.0.0.1    80.0.0.1
@{DHCP_IPS}    70.0.0.2    80.0.0.2
@{cluster_down_list}    1    2
@{SUBNETS_RANGE}    70.0.0.0/24    80.0.0.0/24

*** Test Cases ***
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
    \    Create Network    ${NetworkElement}    devstack_path=/opt/stack/devstack

Create Subnets For l2_net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_net_1    l2_sub_net_1    @{SUBNETS_RANGE}[0]     devstack_path=/opt/stack/devstack

Create Subnets For l2_net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_net_2    l2_sub_net_2    @{SUBNETS_RANGE}[1]     devstack_path=/opt/stack/devstack

Take Down ODL1
    [Documentation]   Kill the karaf in First Controller
    ClusterKeywords.Kill Multiple Controllers    1
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove Values From List    ${new_cluster_list}    1
    Set Suite Variable    ${new_cluster_list}

Create Vm Instances For l2_net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Log    ${devstack_conn_id}
    ${net_id}=    Get Net Id    l2_net_1
    Create Vm Instances    ${net_id}    ${NET_1_VM_INSTANCES}     devstack_path=/opt/stack/devstack
    [Teardown]    Show Debugs      ${NET_1_VM_INSTANCES}

Bring Up ODL1
    [Documentation]  Bring up ODL1 again
    ClusterKeywords.Start Multiple Controllers    300s    1
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Take Down ODL2
    [Documentation]   Kill the karaf in Second Controller
    ClusterKeywords.Kill Multiple Controllers    2
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove Values From List    ${new_cluster_list}    2
    Set Suite Variable    ${new_cluster_list}

Create Vm Instances For l2_net_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    l2_net_2
    Set Suite Variable    ${net_id}
    Create Vm Instances    ${net_id}    ${NET_2_VM_INSTANCES}    devstack_path=/opt/stack/devstack
    [Teardown]    Show Debugs      ${NET_2_VM_INSTANCES}

Bring Up ODL2
    [Documentation]  Bring up ODL2 again
    ClusterKeywords.Start Multiple Controllers    300s    2
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Ping All Vm Instances In l2_net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    l2_net_1
    : FOR    ${VmIpElement}    IN    @{NET_1_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}     devstack_path=/opt/stack/devstack
    \    Should Contain    ${output}    64 bytes

Ping All Vm Instances In l2_net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    l2_net_2
    : FOR    ${VmIpElement}    IN    @{NET_2_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}     devstack_path=/opt/stack/devstack
    \    Should Contain    ${output}    64 bytes

Take Down ODL3
    [Documentation]   Kill the karaf in Third Controller
    ClusterKeywords.Kill Multiple Controllers    3
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove Values From List    ${new_cluster_list}    3
    Set Suite Variable    ${new_cluster_list}

Connectivity Tests From Vm Instances In l2_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    l2_net_1
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance      ${net_id}    @{NET_1_VM_IPS}[0]    ${dst_ip_list}     devstack_path=/opt/stack/devstack

Bring Up ODL3
    [Documentation]  Bring up ODL3 again
    ClusterKeywords.Start Multiple Controllers    300s    3
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Take Down ODL1 and ODL2
    [Documentation]   Kill the karaf in First and Second Controller
    : FOR    ${index}    IN    @{cluster_down_list}
    \    ClusterKeywords.Kill Multiple Controllers    ${index}

Connectivity Tests From Vm Instances In l2_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    l2_net_2
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[1]    @{DHCP_IPS}[1]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance     ${net_id}    @{NET_2_VM_IPS}[0]    ${dst_ip_list}     devstack_path=/opt/stack/devstack

Bring Up ODL1 and ODL2
    [Documentation]  Bring up ODL1 and ODL2 again.
    : FOR    ${index}    IN    @{cluster_down_list}
    \    ClusterKeywords.Start Multiple Controllers    300s    ${index}

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    VmInstance1_l2_net_1     devstack_path=/opt/stack/devstack

Ping All Vm Instances
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    l2_net_1
    : FOR    ${VmIpElement}    IN    @{VM_IPS_NOT_DELETED}
    \    ${output}=    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}      devstack_path=/opt/stack/devstack
    \    Should Contain    ${output}    64 bytes

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping Vm From DHCP Namespace    ${net_id}    @{NET_1_VM_IPS}[0]      devstack_path=/opt/stack/devstack
    Should Contain    ${output}    Destination Host Unreachable

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}         devstack_path=/opt/stack/devstack

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}     devstack_path=/opt/stack/devstack

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_sub_net_1     devstack_path=/opt/stack/devstack

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_sub_net_2     devstack_path=/opt/stack/devstack

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}      devstack_path=/opt/stack/devstack
