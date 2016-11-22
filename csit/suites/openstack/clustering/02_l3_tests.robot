*** Settings ***
Documentation     Test suite to check connectivity in L3 using routers.
Suite Setup       Devstack Suite Setup    source_pwd=yes
Suite Teardown    Close All Connections
Test Teardown     Run Keywords    Show Debugs    ${NET_1_VM_INSTANCES}    ${NET_2_VM_INSTANCES}
...               AND    Get OvsDebugInfo
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/ClusterManagement.robot

*** Variables ***
@{NETWORKS_NAME}    l3_net_1    l3_net_2
@{SUBNETS_NAME}    l3_sub_net_1    l3_sub_net_2
@{NET_1_VM_INSTANCES}    VmInstance1_net_1    VmInstance2_net_1    VmInstance3_net_1
@{NET_2_VM_INSTANCES}    VmInstance1_net_2    VmInstance2_net_2    VmInstance3_net_2
@{NET_1_VM_IPS}    90.0.0.3    90.0.0.4    90.0.0.5
@{NET_2_VM_IPS}    100.0.0.3    100.0.0.4    100.0.0.5
@{GATEWAY_IPS}    90.0.0.1    100.0.0.1
@{DHCP_IPS}       90.0.0.2    100.0.0.2
@{SUBNETS_RANGE}    90.0.0.0/24    100.0.0.0/24
@{odl_1_and_2_down}    ${1}    ${2}
@{odl_2_and_3_down}    ${2}    ${3}

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three contorllers.
    ClusterManagement.ClusterManagement Setup

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Create Network    ${NetworkElement}

Create Subnets For l3_net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    l3_net_1    l3_sub_net_1    @{SUBNETS_RANGE}[0]

Create Subnets For l3_net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    l3_net_2    l3_sub_net_2    @{SUBNETS_RANGE}[1]

Take Down ODL1
    [Documentation]    Kill the karaf in First Controller
    ClusterManagement.Kill Single Member    1

Create Vm Instances For l3_net_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    l3_net_1    ${NET_1_VM_INSTANCES}    sg=csit

Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    ClusterManagement.Start Single Member    1

Take Down ODL2
    [Documentation]    Kill the karaf in Second Controller
    ClusterManagement.Kill Single Member    2

Create Vm Instances For l3_net_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    l3_net_2    ${NET_2_VM_INSTANCES}    sg=csit

Bring Up ODL2
    [Documentation]    Bring up ODL2 again
    ClusterManagement.Start Single Member    2

Take Down ODL3
    [Documentation]    Kill the karaf in Third Controller
    ClusterManagement.Kill Single Member    3

Create Router router_2
    [Documentation]    Create Router and Add Interface to the subnets. this fails sometimes.
    OpenStackOperations.Create Router    router_2
    [Teardown]    Report_Failure_Due_To_Bug    6117

Create Router router_3
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    router_3

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    router_3    ${interface}

Verify Created Routers
    [Documentation]    Check created routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    Log    ${data}
    Should Contain    ${data}    router_3

Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    ClusterManagement.Start Single Member    3

Ping Vm Instance1 In l3_net_2 From l3_net_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l3_net_1    @{NET_2_VM_IPS}[0]

Ping Vm Instance2 In l3_net_2 From l3_net_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l3_net_1    @{NET_2_VM_IPS}[1]

Ping Vm Instance3 In l3_net_2 From l3_net_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l3_net_1    @{NET_2_VM_IPS}[2]

Ping Vm Instance1 In l3_net_1 From l3_net_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l3_net_2    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In l3_net_1 From l3_net_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l3_net_2    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In l3_net_1 From l3_net_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    OpenStackOperations.Ping Vm From DHCP Namespace    l3_net_2    @{NET_1_VM_IPS}[2]

Take Down ODL1 and ODL2
    [Documentation]    Kill the karaf in First and Second Controller
    ClusterManagement.Kill Members From List Or All    ${odl_1_and_2_down}

Connectivity Tests From Vm Instance1 In l3_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]    @{NET_2_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l3_net_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance2 In l3_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l3_net_1    @{NET_1_VM_IPS}[1]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance3 In l3_net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l3_net_1    @{NET_1_VM_IPS}[2]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Bring Up ODL1 and ODL2
    [Documentation]    Bring up ODL1 and ODL2 again
    ClusterManagement.Start Members From List Or All    ${odl_1_and_2_down}

Take Down ODL2 and ODL3
    [Documentation]    Kill the karaf in First and Second Controller
    ClusterManagement.Kill Members From List Or All    ${odl_2_and_3_down}

Connectivity Tests From Vm Instance1 In l3_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[1]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l3_net_2    @{NET_2_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance2 In l3_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l3_net_2    @{NET_2_VM_IPS}[1]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance3 In l3_net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    OpenStackOperations.Test Operations From Vm Instance    l3_net_2    @{NET_2_VM_IPS}[2]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Bring Up ODL2 and ODL3
    [Documentation]    Bring up ODL2 and ODL3 again.
    ClusterManagement.Start Members From List Or All    ${odl_2_and_3_down}

Delete Vm Instances In l3_net_1
    [Documentation]    Delete Vm instances using instance names in l3_net_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Delete Vm Instances In l3_net_2
    [Documentation]    Delete Vm instances using instance names in l3_net_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Remove Interface    router_3    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    OpenStackOperations.Delete Router    router_2
    OpenStackOperations.Delete Router    router_3

Verify Deleted Routers
    [Documentation]    Check deleted routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    Log    ${data}
    Should Not Contain    ${data}    router_3

Delete Sub Networks In l3_net_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    l3_sub_net_1

Delete Sub Networks In l3_net_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    l3_sub_net_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Delete Network    ${NetworkElement}
