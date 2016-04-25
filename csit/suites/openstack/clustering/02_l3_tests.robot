*** Settings ***
Documentation    Test suite to check connectivity in L3 using routers.
Suite Setup    Devstack Suite Setup Tests
Library    SSHLibrary
Library    OperatingSystem
Library    RequestsLibrary
Resource    ../../../libraries/Utils.robot
Resource    ../../../libraries/OpenStackOperations.robot
Resource    ../../../libraries/DevstackUtils.robot
Resource    ../../../libraries/ClusterKeywords.robot

*** Variables ***
@{NETWORKS_NAME}    net_1    net_2
@{SUBNETS_NAME}    sub_net_1    sub_net_2
@{NET_1_VM_INSTANCES}    VmInstance1_net_1    VmInstance2_net_1
@{NET_2_VM_INSTANCES}    VmInstance1_net_2    VmInstance2_net_2
@{NET_1_VM_IPS}    90.0.0.3    90.0.0.4
@{NET_2_VM_IPS}    100.0.0.3    100.0.0.4
@{GATEWAY_IPS}    90.0.0.1    100.0.0.1
@{DHCP_IPS}    90.0.0.2    100.0.0.2
${KARAF_HOME}     ${WORKSPACE}${/}${BUNDLEFOLDER}
@{odl_1_and_2_down}    1    2
@{odl_2_and_3_down}    2    3

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    Source Password      devstack_path=/opt/stack/devstack
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}    devstack_path=/opt/stack/devstack

Create Subnets For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    net_1    sub_net_1    90.0.0.0/24

Create Subnets For net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    net_2    sub_net_2    100.0.0.0/24

Take Down ODL1
    [Documentation]   Kill the karaf in First Controller
    ClusterKeywords.Kill Multiple Controllers    1
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove Values From List    ${new_cluster_list}    1
    Set Suite Variable    ${new_cluster_list}

Create Vm Instances For net_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Log    ${devstack_conn_id}
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    net_1
    Create Vm Instances    ${net_id}    ${NET_1_VM_INSTANCES}
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

Create Vm Instances For net_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Switch Connection    ${devstack_conn_id}
    Source Password      devstack_path=/opt/stack/devstack
    ${net_id}=    Get Net Id    net_2
    Set Suite Variable    ${net_id}
    Create Vm Instances    ${net_id}    ${NET_2_VM_INSTANCES}
    [Teardown]    Show Debugs      ${NET_2_VM_INSTANCES}

Bring Up ODL2
    [Documentation]  Bring up ODL2 again
    ClusterKeywords.Start Multiple Controllers    300s    2
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Take Down ODL3
    [Documentation]   Kill the karaf in Third Controller
    ClusterKeywords.Kill Multiple Controllers    3
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove Values From List    ${new_cluster_list}    3
    Set Suite Variable    ${new_cluster_list}

Create Routers
    [Documentation]    Create Router and Add Interface to the subnets.
    Switch Connection    ${devstack_conn_id}
    Source Password      devstack_path=/opt/stack/devstack
    Wait Until Keyword Succeeds    10s      5s      Create Router    router_2

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR     ${interface}    IN     @{SUBNETS_NAME}
    \    Add Router Interface     router_2     ${interface}

Bring Up ODL3
    [Documentation]  Bring up ODL3 again
    ClusterKeywords.Start Multiple Controllers    300s    3
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Ping Vm Instance In net_2 From net_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Switch Connection    ${devstack_conn_id}
    Source Password      devstack_path=/opt/stack/devstack
    ${net_id}=    Get Net Id    net_1
    ${output}    Ping Vm From DHCP Namespace    ${net_id}    100.0.0.3
    Should Contain    ${output}    64 bytes

Ping Vm Instance In net_1 From net_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    ${net_id}=    Get Net Id    net_2
    ${output}    Ping Vm From DHCP Namespace    ${net_id}    90.0.0.3
    Should Contain    ${output}    64 bytes

Take Down ODL1 and ODL2
    [Documentation]   Kill the karaf in First and Second Controller
    : FOR    ${index}    IN    @{odl_1_and_2_down}
    \    ClusterKeywords.Kill Multiple Controllers    ${index}

Connectivity Tests From Vm Instances In net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    net_1
    ${dst_ip_list}=    Create List    90.0.0.4    90.0.0.2
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    100.0.0.3    100.0.0.2
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${net_id}    90.0.0.3    ${dst_ip_list}    l2_or_l3=l3    other_dst_ip_list=${other_dst_ip_list}

Bring Up ODL1 and ODL2
    [Documentation]  Bring up ODL1 and ODL2 again
    : FOR    ${index}    IN    @{odl_1_and_2_down}
    \    ClusterKeywords.Start Multiple Controllers    300s    ${index}

Take Down ODL2 and ODL3
    [Documentation]   Kill the karaf in First and Second Controller
    : FOR    ${index}    IN    @{odl_2_and_3_down}
    \    ClusterKeywords.Kill Multiple Controllers    ${index}

Connectivity Tests From Vm Instances In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    Switch Connection    ${devstack_conn_id}
    Source Password      devstack_path=/opt/stack/devstack
    ${net_id}=    Get Net Id    net_2
    ${dst_ip_list}=    Create List    100.0.0.4    100.0.0.2
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    90.0.0.3    90.0.0.2
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance     ${net_id}    100.0.0.3    ${dst_ip_list}    l2_or_l3=l3    other_dst_ip_list=${other_dst_ip_list}

Bring Up ODL2 and ODL3
    [Documentation]  Bring up ODL2 and ODL3 again.
    : FOR    ${index}    IN    @{odl_2_and_3_down}
    \    ClusterKeywords.Start Multiple Controllers    300s    ${index}

Delete Vm Instances In net_1
    [Documentation]    Delete Vm instances using instance names in net_1.
    Switch Connection    ${devstack_conn_id}
    Source Password      devstack_path=/opt/stack/devstack
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In net_2
    [Documentation]    Delete Vm instances using instance names in net_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR     ${interface}    IN     @{SUBNETS_NAME}
    \     Remove Interface     router_2     ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    router_2

Delete Sub Networks In net_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    sub_net_1

Delete Sub Networks In net_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    sub_net_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
