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

*** Variables ***
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
${ODLREST}        /controller/nb/v2/neutron
@{node_list}      ovsdb://uuid/
${EXT_NET1_ID}    7da709ff-397f-4778-a0e8-994811272fdb
${EXT_SUBNET1_ID}    00289199-e288-464a-ab2f-837ca67101a7
${TNT1_ID}        cde2563ead464ffa97963c59e002c0cf

*** Test Cases ***
Create Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Ensure controller is running
    [Documentation]    Check if the controller is running before sending restconf requests
    [Tags]    Check controller reachability
    ${dictionary}=    Create Dictionary    ovsdb://uuid/=5
    Wait Until Keyword Succeeds    4s    4s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Check netvirt is loaded
    [Documentation]    Check if the netvirt piece has been loaded into the karaf instance
    [Tags]    Check netvirt is loaded
    ${operational}=    Create Dictionary    netvirt:1=1
    Wait Until Keyword Succeeds    4s    4s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${operational}    ${OPERATIONAL_TOPO_API}

Check External Net for Tenant
    [Documentation]    Check External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${resp}    RequestsLibrary.Get    session    ${ODLREST}/networks
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Create External Net for Tenant
    [Documentation]    Create External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post    session    ${ODLREST}/networks    data=${Data}    headers=${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
