*** Settings ***
Documentation     Test suite for Ovsdb Openstack Cluster.
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{NETWORKS_NAME}    net1_network    net2_network
@{SUBNETS_NAME}    subnet1    subnet2
@{VM_INSTANCES_NAME}    MyFirstInstance    MySecondInstance
@{VM_IPS}    10.0.0.3    20.0.0.3
@{GATEWAY_IPS}    10.0.0.1    20.0.0.1
@{DHCP_IPS}    10.0.0.2    20.0.0.2

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Verify Net-virt Features
    [Documentation]    Check Net-virt Console related features (odl-ovsdb-openstack)
    Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_1_IP}
    Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_2_IP}
    Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_3_IP}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Get OVS Manager Connection Status
    [Documentation]    This will verify if the OVS manager is connected
    [Tags]    OVSDB Openstack netvirt
    Log    ${OPENSTACK_CONTROL_NODE_IP}
    SSHLibrary.Open Connection    ${OPENSTACK_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${DEVSTACK_SYSTEM_USER}
    Utils.Flexible SSH Login    ${DEVSTACK_SYSTEM_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    Log    ${DEVSTACK_SYSTEM_PASSWORD}
    ${output}=   Write Commands Until Prompt    sudo ovs-vsctl show
    Log    ${output}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}    ovsdb
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For net1_network
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    net1_network    subnet1    10.0.0.0/24

Create Subnets For net2_network
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    net2_network    subnet2    20.0.0.0/24

List Ports
    ${output}=   Write Commands Until Prompt     neutron -v port-list
    Log    ${output}

List Available Networks
    ${output}=   Write Commands Until Prompt     neutron -v net-list
    Log    ${output}

List Tenants
    ${output}=   Write Commands Until Prompt     keystone tenant-list
    Log    ${output}

List Nova
    ${output}=   Write Commands Until Prompt     nova list
    Log    ${output}

List Nova Images
    ${output}=   Write Commands Until Prompt     nova image-list
    Log    ${output}

List Nova Flavor
    ${output}=   Write Commands Until Prompt     nova flavor-list
    Log    ${output}

Create Vm Instances
    [Documentation]    Create Vm instances using flavor and image names.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    ${net_id}=    Get Net Id    ${NetworkElement}
    \    Create Vm Instance    ${net_id}    ${NetworkElement}
