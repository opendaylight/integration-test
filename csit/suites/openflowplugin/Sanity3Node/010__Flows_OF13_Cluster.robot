*** Settings ***
Suite Setup       Create Controllers Sessions
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           Collections
Library           XML
Library           SSHLibrary
Library           ../../../libraries/XmlComparator.py
Variables         ../../../variables/Variables.py
Library           RequestsLibrary
Library           ../../../libraries/Common.py

*** Variables ***
${switch_idx}     1
${switch_name}    s${switch_idx}
${url_m1_shard}    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-1-shard-inventory-config,type=DistributedConfigDatastore
${url_m2_shard}    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-2-shard-inventory-config,type=DistributedConfigDatastore
${url_m3_shard}    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-3-shard-inventory-config,type=DistributedConfigDatastore
${get_pers_url}    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/distributed-datastore-provider:distributed-config-datastore-provider/distributed-config-store-module

*** Test Cases ***
Logging Initial Cluster Information
    ${resp}=    Get Controller Response    session1    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-1-shard-inventory-config,type=DistributedConfigDatastore
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session1    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-1-shard-inventory-operational,type=DistributedOperationalDatastore
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session1    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/distributed-datastore-provider:distributed-config-datastore-provider/distributed-config-store-module
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session1    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/distributed-datastore-provider:distributed-operational-datastore-provider/distributed-operational-store-module
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session2    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-2-shard-inventory-config,type=DistributedConfigDatastore
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session2    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-2-shard-inventory-operational,type=DistributedOperationalDatastore
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session2    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/distributed-datastore-provider:distributed-config-datastore-provider/distributed-config-store-module
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session2    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/distributed-datastore-provider:distributed-operational-datastore-provider/distributed-operational-store-module
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session3    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-3-shard-inventory-config,type=DistributedConfigDatastore
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session3    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-3-shard-inventory-operational,type=DistributedOperationalDatastore
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session3    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/distributed-datastore-provider:distributed-config-datastore-provider/distributed-config-store-module
    Log    ${resp.content}
    ${resp}=    Get Controller Response    session3    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/distributed-datastore-provider:distributed-operational-datastore-provider/distributed-operational-store-module
    Log    ${resp.content}

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

Create Controllers Sessions
    Create Session    session1    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Create Session    session2    http://${CONTROLLER1}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Create Session    session3    http://${CONTROLLER2}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

Get Controller Response
    [Arguments]    ${session}    ${url}
    ${headers}=    Create Dictionary    Accept    application/xml
    ${resp}=    Get    ${session}    ${url}    headers=${headers}
    Return From Keyword    ${resp}
