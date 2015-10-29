*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    Delete All Sessions
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list}      ovsdb://uuid/
${EXT_NET1_ID}    7da709ff-397f-4778-a0e8-994811272fdb
${EXT_SUBNET1_ID}    00289199-e288-464a-ab2f-837ca67101a7
${TNT1_ID}        cde2563ead464ffa97963c59e002c0cf

*** Test Cases ***
Verify Net-virt Features
    [Documentation]    Check Net-virt Console related features (odl-ovsdb-openstack)
    KarafKeywords.Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_1_IP}
    KarafKeywords.Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_2_IP}
    KarafKeywords.Verify Feature Is Installed    odl-ovsdb-openstack    ${ODL_SYSTEM_3_IP}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    ClusterOvsdb.Check Ovsdb Shards Status

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Ovsdb.Add Multiple Managers to OVS
    Set Suite Variable    ${mininet_conn_id}
    Log    ${mininet_conn_id}

Get manager connection
    [Documentation]    This will verify if the OVS manager is connected
    [Tags]    OVSDB netvirt
    Ovsdb.Verify OVS Reports Connected

Check netvirt is loaded
    [Documentation]    Check if the netvirt piece has been loaded into the karaf instance
    [Tags]    Check netvirt is loaded
    ${netvirt}=    Create Dictionary    netvirt:1=1
    Wait Until Keyword Succeeds    6s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${OPERATIONAL_NODES_NETVIRT}    dictionary=${netvirt}

Check External Net for Tenant
    [Documentation]    Check External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${resp}=    Create Dictionary    "networks" : [ ]=1
    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${NEUTRON_NETWORKS_API}    dictionary=${resp}

Create External Net for Tenant
    [Documentation]    Create External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${session} =    Resolve_Http_Session_For_Member    member_index=1
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    ${session}    ${NEUTRON_NETWORKS_API}    data=${Data}    headers=${HEADERS}
    Log    ${resp.content}
    Log    ${resp.status_code}
    ${status_code}=    Convert To String    ${resp.status_code}
    Should Match Regexp    ${status_code}    20(0|1)
    ClusterManagement.Check_Json_Member_List_Or_All    ${NEUTRON_NETWORKS_API}    ${Data}
