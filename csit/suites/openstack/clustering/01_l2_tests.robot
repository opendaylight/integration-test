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

