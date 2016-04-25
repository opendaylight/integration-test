*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup Tests
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/ClusterKeywords.robot

*** Variables ***
@{NETWORKS_NAME}    net_1    net_2
@{SUBNETS_NAME}    sub_net_1    sub_net_2
@{NET_1_VM_INSTANCES}    VmInstance1_net_1    VmInstance2_net_1
@{NET_2_VM_INSTANCES}    VmInstance1_net_2    VmInstance2_net_2
@{NET_1_VM_IPS}    70.0.0.3    70.0.0.4
@{NET_2_VM_IPS}    80.0.0.3    80.0.0.4
@{VM_IPS_NOT_DELETED}    70.0.0.4
@{GATEWAY_IPS}    70.0.0.1    80.0.0.1
@{DHCP_IPS}    70.0.0.2    80.0.0.2
${ODLREST}    /controller/nb/v2/neutron/networks
${OSREST}    /v2.0/networks
${KARAF_HOME}     ${WORKSPACE}${/}${BUNDLEFOLDER}
@{cluster_down_list}    1    2

*** Test Cases ***
Create Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check OVS Manager Connection Status
    [Documentation]    This will verify if the OVS manager is connected
    ${output}=   Write Commands Until Prompt    sudo ovs-vsctl show
    Log    ${output}
    Set Suite Variable    ${status}    is_connected: true
    ${dictionary}=    Create Dictionary    ${status}=9
    Utils.Check Item Occurrence    ${output}    ${dictionary}

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}    devstack_path=/opt/stack/devstack

Create Subnets For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    net_1    sub_net_1    70.0.0.0/24

Create Subnets For net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    net_2    sub_net_2    80.0.0.0/24

Take Down ODL1
    [Documentation]   Kill the karaf in First Controller
    ClusterKeywords.Kill Multiple Controllers    1
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove Values From List    ${new_cluster_list}    1
    Set Suite Variable    ${new_cluster_list}

Create Vm Instances For net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
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
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    net_2
    Set Suite Variable    ${net_id}
    Create Vm Instances    ${net_id}    ${NET_2_VM_INSTANCES}
    [Teardown]    Show Debugs      ${NET_2_VM_INSTANCES}

Bring Up ODL2
    [Documentation]  Bring up ODL2 again
    ClusterKeywords.Start Multiple Controllers    300s    2
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Ping All Vm Instances In net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    net_1
    : FOR    ${VmIpElement}    IN    @{NET_1_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}
    \    Should Contain    ${output}    64 bytes

Ping All Vm Instances In net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    net_2
    : FOR    ${VmIpElement}    IN    @{NET_2_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}
    \    Should Contain    ${output}    64 bytes

Take Down ODL3
    [Documentation]   Kill the karaf in Third Controller
    ClusterKeywords.Kill Multiple Controllers    3
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Remove Values From List    ${new_cluster_list}    3
    Set Suite Variable    ${new_cluster_list}

Add Key-Pair For Vm Instance
    [Documentation]    Creates key pair to ssh to the vm instance.
    Switch Connection    ${devstack_conn_id}
    ${output}=   Write Commands Until Prompt    nova keypair-add test > test.pem
    Log    ${output}
    ${output}=   Write Commands Until Prompt    chmod 600 test.pem
    Log    ${output}

List The Available Key Pair List
    [Documentation]    Check the existing key pairs available.
    ${output}=   Write Commands Until Prompt    nova keypair-list
    Log    ${output}

Login to Vm Instances In net_1 Using Ssh
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    net_1
    Ssh Vm Instance    ${net_id}    70.0.0.3

Ping Vm Instance From Instance In network_1
    [Documentation]    Check reachability of vm instances by pinging.
    ${output}=    Ping From Instance    70.0.0.4
    Should Contain    ${output}    64 bytes

Ping Dhcp Server From Instance In net_1
    [Documentation]    ping the dhcp server from instance.
    ${output}=    Ping From Instance    70.0.0.2
    Should Contain    ${output}    64 bytes

Ping Metadata Server From Instance In net_1
    [Documentation]    ping the metadata server from instance.
    Curl Metadata Server

Bring Up ODL3
    [Documentation]  Bring up ODL3 again
    ClusterKeywords.Start Multiple Controllers    300s    3
    ${new_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${new_cluster_list}

Take Down ODL1 and ODL2
    [Documentation]   Kill the karaf in First and Second Controller
    : FOR    ${index}    IN    @{cluster_down_list}
    \    ClusterKeywords.Kill Multiple Controllers    ${index}

Login to Vm Instances In net_2 Using Ssh
    [Documentation]    Logging to the vm instance using generated key pair.
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    net_2
    Ssh Vm Instance    ${net_id}    80.0.0.3

Ping Vm Instance From Instance In net_2
    [Documentation]    Check reachability of vm instances by pinging.
    ${output}=    Ping From Instance    80.0.0.4
    Should Contain    ${output}    64 bytes

Ping Dhcp Server From Instance In net_2
    [Documentation]    ping the dhcp server from instance.
    ${output}=    Ping From Instance    80.0.0.2
    Should Contain    ${output}    64 bytes

Ping Metadata Server From Instance In network_2
    [Documentation]    ping the metadata server from instance.
    Curl Metadata Server

Bring Up ODL1 and ODL2
    [Documentation]  Bring up ODL1 and ODL2 again.
    : FOR    ${index}    IN    @{cluster_down_list}
    \    ClusterKeywords.Start Multiple Controllers    300s    ${index}

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Switch Connection    ${devstack_conn_id}
    Delete Vm Instance    VmInstance1_net_1

Ping All Vm Instances
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    net_1
    : FOR    ${VmIpElement}    IN    @{VM_IPS_NOT_DELETED}
    \    ${output}=    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}
    \    Should Contain    ${output}    64 bytes

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping Vm From DHCP Namespace    ${net_id}    70.0.0.3
    Should Contain    ${output}    Destination Host Unreachable

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
    Delete SubNet    sub_net_1

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    sub_net_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
