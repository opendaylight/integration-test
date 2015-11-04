*** Settings ***
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           Collections
Library           XML
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/XmlComparator.py
Resource          ../../../libraries/ClusterKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${switch_idx}     1
${switch_name}    s${switch_idx}
${url_m1_shard}    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-1-shard-inventory-config,type=DistributedConfigDatastore
${url_m2_shard}    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-2-shard-inventory-config,type=DistributedConfigDatastore
${url_m3_shard}    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-3-shard-inventory-config,type=DistributedConfigDatastore
${get_pers_url}    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/distributed-datastore-provider:distributed-config-datastore-provider/distributed-config-store-module

*** Test Cases ***
Find Leader and Select Follower For Inventory
    @{cluster_list}    Create Original Cluster List
    ${leader}    @{followers}    Get Shard Status    inventory    @{cluster_list}
    ${follower}=    Get From List    ${followers}    0
    Set Suite Variable    @{original_cluster_list}    @{cluster_list}
    Set Suite Variable    ${original_leader}    ${leader}
    Set Suite Variable    ${original_follower}    ${follower}

Add Flow 1 To Controller1
    Init Flow Variables    1    1    1
    Log    ${data}
    ${resp}=    Put    session1    ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}    data=${data}
    Log    ${resp.content}
    ${msg}=    Set Variable    Adding flow for ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Add Flow 2 To Controller2
    Init Flow Variables    1    2    2
    Log    ${data}
    ${resp}=    Put    session2    ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}    data=${data}
    Log    ${resp.content}
    ${msg}=    Set Variable    Adding flow for ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Add Flow 3 To Controller3
    Init Flow Variables    1    3    3
    Log    ${data}
    ${resp}=    Put    session3    ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}    data=${data}
    Log    ${resp.content}
    ${msg}=    Set Variable    Adding flow for ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Show Switch Content After Add
    Sleep    5s
    Write    sh ovs-vsctl show
    Read Until    mininet>
    Write    sh ovs-ofctl dump-flows s1 -O OpenFlow13
    Read Until    mininet>

Check Flow 1 Configured On Controller1
    Init Flow Variables    1    1    1
    ${resp}=    Get Controller Response    session1    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 1 Operational On Controller1
    Init Flow Variables    1    1    1
    ${resp}=    Get Controller Response    session1    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 1 Configured On Controller2
    Init Flow Variables    1    1    1
    ${resp}=    Get Controller Response    session2    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 1 Operational On Controller2
    Init Flow Variables    1    1    1
    ${resp}=    Get Controller Response    session2    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 1 Configured On Controller3
    Init Flow Variables    1    1    1
    ${resp}=    Get Controller Response    session3    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 1 Operational On Controller3
    Init Flow Variables    1    1    1
    ${resp}=    Get Controller Response    session3    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 2 Configured On Controller1
    Init Flow Variables    1    2    2
    ${resp}=    Get Controller Response    session1    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/2
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 2 Operational On Controller1
    Init Flow Variables    1    2    2
    ${resp}=    Get Controller Response    session1    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 2 Configured On Controller2
    Init Flow Variables    1    2    2
    ${resp}=    Get Controller Response    session2    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/2
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 2 Operational On Controller2
    Init Flow Variables    1    2    2
    ${resp}=    Get Controller Response    session2    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 2 Configured On Controller3
    Init Flow Variables    1    2    2
    ${resp}=    Get Controller Response    session3    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/2
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 2 Operational On Controller3
    Init Flow Variables    1    2    2
    ${resp}=    Get Controller Response    session3    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 3 Configured On Controller1
    Init Flow Variables    1    3    3
    ${resp}=    Get Controller Response    session1    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/3
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 3 Operational On Controller1
    Init Flow Variables    1    3    3
    ${resp}=    Get Controller Response    session1    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 3 Configured On Controller2
    Init Flow Variables    1    3    3
    ${resp}=    Get Controller Response    session2    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/3
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 3 Operational On Controller2
    Init Flow Variables    1    3    3
    ${resp}=    Get Controller Response    session2    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 3 Configured On Controller3
    Init Flow Variables    1    3    3
    ${resp}=    Get Controller Response    session3    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/3
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Check Flow 3 Operational On Controller3
    Init Flow Variables    1    3    3
    ${resp}=    Get Controller Response    session3    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${True}    ${pres}    msg=${msg}

Delete Flow 1 On Controller1
    Init Flow Variables    1    1    1
    ${resp}=    Delete    session1    ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}
    Log    ${resp.content}
    ${msg}=    Set Variable    Delete flow for ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Delete Flow 2 On Controller2
    Init Flow Variables    1    2    2
    ${resp}=    Delete    session2    ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}
    Log    ${resp.content}
    ${msg}=    Set Variable    Delete flow for ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Delete Flow 3 On Controller3
    Init Flow Variables    1    3    3
    ${resp}=    Delete    session3    ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}
    Log    ${resp.content}
    ${msg}=    Set Variable    Delete flow for ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Show Switch Content After Delete
    Sleep    5s
    Write    sh ovs-ofctl dump-flows s1 -O OpenFlow13
    Read Until    mininet>

Check Flow 1 Not Configured On Controller1
    ${resp}=    Get Controller Response    session1    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 1 Not Operational On Controller1
    ${resp}=    Get Controller Response    session1    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

Check Flow 1 Not Configured On Controller2
    ${resp}=    Get Controller Response    session2    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 1 Not Operational On Controller2
    ${resp}=    Get Controller Response    session2    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

Check Flow 1 Not Configured On Controller3
    ${resp}=    Get Controller Response    session3    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 1 Not Operational On Controller3
    ${resp}=    Get Controller Response    session3    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

Check Flow 2 Not Configured On Controller1
    ${resp}=    Get Controller Response    session1    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/2
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 2 Not Operational On Controller1
    ${resp}=    Get Controller Response    session1    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

Check Flow 2 Not Configured On Controller2
    ${resp}=    Get Controller Response    session2    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/2
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 2 Not Operational On Controller2
    ${resp}=    Get Controller Response    session2    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

Check Flow 2 Not Configured On Controller3
    ${resp}=    Get Controller Response    session3    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/2
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 2 Not Operational On Controller3
    ${resp}=    Get Controller Response    session3    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

Check Flow 3 Not Configured On Controller1
    ${resp}=    Get Controller Response    session1    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/3
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 3 Not Operational On Controller1
    ${resp}=    Get Controller Response    session1    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

Check Flow 3 Not Configured On Controller2
    ${resp}=    Get Controller Response    session2    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/3
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 3 Not Operational On Controller2
    ${resp}=    Get Controller Response    session2    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

Check Flow 3 Not Configured On Controller3
    ${resp}=    Get Controller Response    session3    ${CONFIG_NODES_API}/node/openflow:1/table/1/flow/3
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404

Check Flow 3 Not Operational On Controller3
    ${resp}=    Get Controller Response    session3    ${OPERATIONAL_NODES_API}/node/openflow:1/table/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Should Be Equal    ${False}    ${pres}    msg=${msg}

*** Keywords ***
Init Flow Variables
    [Arguments]    ${tableid}    ${flowid}    ${priority}
    ${data}=    Get Flow Content    ${tableid}    ${flowid}    ${priority}
    ${xmlroot}=    Parse Xml    ${data}
    ${table_id}=    Set Variable    ${tableid}
    ${flow_id}=    Set Variable    ${flowid}
    ${flow_priority}=    Set Variable    ${priority}
    Set Suite Variable    ${table_id}
    Set Suite Variable    ${flow_id}
    Set Suite Variable    ${flow_priority}
    Set Suite Variable    ${data}
    Set Suite Variable    ${xmlroot}

Get Controller Response
    [Arguments]    ${session}    ${url}
    ${headers}=    Create Dictionary    Accept=application/xml
    ${resp}=    Get    ${session}    ${url}    headers=${headers}
    Return From Keyword    ${resp}
