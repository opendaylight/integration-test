*** Settings ***
Documentation     Test suite for RESTCONF LACP inventory
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${node1}          openflow:1
${agg-id1}        1
${agg-id2}        2
${agg1-connector-id1}    1
${agg1-connector-id2}    2
${agg2-connector-id1}    3
${agg2-connector-id2}    4

*** Test Cases ***
Get list of nodes and LACP reference on Inventory
    [Documentation]    Get the nodes data
    ${resp}    Get    session    ${OPERATIONAL_NODES_API}
    Verify LACP RESTAPI Response Code for node
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    non-lag-groupid
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    lacp-aggregators

Get the Specific Node Inventory and Lacp aggregator details
    [Documentation]    Get the lacp-aggregator data for specific node
    ${resp}    Get    session    ${OPERATIONAL_NODES_API}/node/${node1}
    Verify LACP RESTAPI Response Code for node
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    ${agg-id1}
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    ${agg-id2}

Get information of each lacp-aggregator for a node
    [Documentation]    Get each lacp-aggregator data for a node
    ${resp}    Get    session    ${OPERATIONAL_NODES_API}/node/${node1}/lacp-aggregators/${agg-id1}
    Verify LACP RESTAPI Response Code for node
    Verify LACP connector associated for aggregator    ${resp.content}    ${node1}    ${agg1-connector-id1}
    Verify LACP connector associated for aggregator    ${resp.content}    ${node1}    ${agg1-connector-id2}
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    lag-groupid
    ${resp}    Get    session    ${OPERATIONAL_NODES_API}/node/${node1}/lacp-aggregators/${agg-id2}
    Verify LACP RESTAPI Response Code for node
    Verify LACP connector associated for aggregator    ${resp.content}    ${node1}    ${agg2-connector-id1}
    Verify LACP connector associated for aggregator    ${resp.content}    ${node1}    ${agg2-connector-id2}
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    lag-groupid

Get node connector data for node 1
    [Documentation]    Get the node connector inventory for node 1
    ${resp}    Get    session    ${OPERATIONAL_NODES_API}/node/${node1}/node-connector/${node1}:${agg1-connector-id1}
    Verify LACP RESTAPI Response Code for node
    Verify specific LACP node connector data for node    ${resp.content}    ${agg-id1}    agg-id
    ${resp}    Get    session    ${OPERATIONAL_NODES_API}/node/${node1}/node-connector/${node1}:${agg1-connector-id2}
    Verify LACP RESTAPI Response Code for node
    Verify specific LACP node connector data for node    ${resp.content}    ${agg-id1}    agg-id
    ${resp}    Get    session    ${OPERATIONAL_NODES_API}/node/${node1}/node-connector/${node1}:${agg2-connector-id1}
    Verify LACP RESTAPI Response Code for node
    Verify specific LACP node connector data for node    ${resp.content}    ${agg-id2}    agg-id
    ${resp}    Get    session    ${OPERATIONAL_NODES_API}/node/${node1}/node-connector/${node1}:${agg2-connector-id2}
    Verify LACP RESTAPI Response Code for node
    Verify specific LACP node connector data for node    ${resp.content}    ${agg-id2}    agg-id

*** Keywords ***
Verify LACP RESTAPI Response Code for node
    [Documentation]    Will check for the response code of the REST query
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${node1}

Verify LACP RESTAPI Aggregator and Tag Contents
    [Arguments]    ${resp.content}    ${content-lookup}
    [Documentation]    Will check for the LACP Specific tags or Aggregator ID for node
    Should Contain    ${resp.content}    ${content-lookup}

Verify LACP connector associated for aggregator
    [Arguments]    ${resp.content}    ${node}    ${agg-connector-id}
    [Documentation]    Will check for the LACP connector info for each aggregator
    Should Contain    ${resp.content}    ${node}:${agg-connector-id}

Verify specific LACP node connector data for node
    [Arguments]    ${resp.content}    ${agg-id}    ${connector}
    [Documentation]    Will check for node connectory info for node
    Should Contain    ${resp.content}    ${connector}='${agg-id}'
