*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://uuid/
${EXT_NET1_ID}    7da709ff-397f-4778-a0e8-994811272fdb
${EXT_SUBNET1_ID}    00289199-e288-464a-ab2f-837ca67101a7
${TNT1_ID}        cde2563ead464ffa97963c59e002c0cf

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

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Add Multiple Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}
    Log    ${mininet_conn_id}

Get manager connection
    [Documentation]    This will verify if the OVS manager is connected
    [Tags]    OVSDB netvirt
    Verify OVS Reports Connected

Check netvirt is loaded
    [Documentation]    Check if the netvirt piece has been loaded into the karaf instance
    [Tags]    Check netvirt is loaded
    ${netvirt}=    Create Dictionary    netvirt:1=1
    Wait Until Keyword Succeeds    6s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${netvirt}    ${OPERATIONAL_NODES_NETVIRT}

Check External Net for Tenant
    [Documentation]    Check External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${resp}=    Create Dictionary    "networks" : [ ]=1
    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${resp}    ${ODLREST}/networks

Create External Net for Tenant
    [Documentation]    Create External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    Log    ${Data}
    Put And Check At URI In Cluster    ${original_cluster_list}    1    ${ODLREST}/networks    ${Data}
