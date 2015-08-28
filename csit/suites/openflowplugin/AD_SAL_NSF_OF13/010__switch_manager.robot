*** Settings ***
Documentation     Test suite for Switch Manager
Suite Setup       Create Session    ${ODL_CONTROLLER_SESSION}    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/SwitchManager.py
Variables         ../../../variables/Variables.py
Library           ../../../libraries/Topology.py

*** Variables ***
${REST_CONTEXT}    /controller/nb/v2/switchmanager

*** Test Cases ***
List all nodes
    [Documentation]    List all nodes and their properties in the network.
    [Tags]    adsal
    Log    ${TOPO_TREE_LEVEL}
    ${topo_nodes}    Get Nodes From Topology    ${TOPO_TREE_LEVEL}
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/default/nodes
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    ${jsondata}=    To JSON    ${resp.content}
    ${nodes}    Extract All Nodes    ${jsondata}
    List Should Contain Sublist    ${nodes}    ${topo_nodes}

Check node 1 connectors
    [Documentation]    List node connectors and verify all connectors are there
    [Tags]    adsal
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/default/node/OF/00:00:00:00:00:00:00:01
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    s1-eth1
    Should Contain    ${resp.content}    s1-eth2

Check node 2 connectors
    [Documentation]    List node connectors and verify all connectors are there
    [Tags]    adsal
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/default/node/OF/00:00:00:00:00:00:00:02
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    s2-eth1
    Should Contain    ${resp.content}    s2-eth2
    Should Contain    ${resp.content}    s2-eth3

Check node 3 connectors
    [Documentation]    List node connectors and verify all connectors are there
    [Tags]    adsal
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/default/node/OF/00:00:00:00:00:00:00:03
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    s3-eth1
    Should Contain    ${resp.content}    s3-eth2
    Should Contain    ${resp.content}    s3-eth3

Add property to node
    [Documentation]    Add a property to node
    [Tags]    adsal
    Add property to node    OF    00:00:00:00:00:00:00:02    description    Switch2
    Node property should exist    OF    00:00:00:00:00:00:00:02    description    Switch2
    #Remove property from node
    #    [Documentation]    Remove a property from node
    #    Remove property from node    OF    00:00:00:00:00:00:00:02    description
    #    Node property should not exist    OF    00:00:00:00:00:00:00:02    description    Switch2

Add property to nodeconnector
    [Documentation]    Add a property to nodeconnector
    [Tags]    adsal
    Add property to nodeconnector    OF    00:00:00:00:00:00:00:02    OF    2    bandwidth    1000
    Nodeconnector property should exist    OF    00:00:00:00:00:00:00:02    OF    2    bandwidth    ${1000}

Remove property from nodeconnector
    [Documentation]    Remove a property from nodeconnector
    [Tags]    adsal
    Remove property from nodeconnector    OF    00:00:00:00:00:00:00:02    OF    2    bandwidth
    Nodeconnector property should not exist    OF    00:00:00:00:00:00:00:02    OF    2    bandwidth    ${1000}

*** Keywords ***
Get node
    [Arguments]    ${node_id}    ${node_type}
    [Documentation]    Get a specific node
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/nodes
    Should Be Equal As Strings    ${resp.status_code}    200    Response status code error
    ${result}    TO JSON    ${resp.content}
    ${node}    Create Dictionary    id=${node_id}    type={node_type}
    ${content}    Extract All Nodes    ${result}
    Log    ${content}
    List Should Contain Value    ${content}    ${node}

Add property to node
    [Arguments]    ${node_type}    ${node_id}    ${property}    ${value}
    [Documentation]    Add property to node
    ${resp}    RequestsLibrary.Put    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/node/${node_type}/${node_id}/property/${property}/${value}
    Should Be Equal As Strings    ${resp.status_code}    201    Response status code error

Remove property from node
    [Arguments]    ${node_type}    ${node_id}    ${property}
    [Documentation]    Remove property from node
    ${resp}    RequestsLibrary.Delete    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/node/${node_type}/${node_id}/property/${property}
    Should Be Equal As Strings    ${resp.status_code}    204    Response status code error

Add property to nodeconnector
    [Arguments]    ${node_type}    ${node_id}    ${nc_type}    ${nc_id}    ${property}    ${value}
    [Documentation]    Add property to nodeconnector
    ${resp}    RequestsLibrary.Put    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/nodeconnector/${node_type}/${node_id}/${nc_type}/${nc_id}/property/${property}/${value}
    Should Be Equal As Strings    ${resp.status_code}    201    Response status code error

Remove property from nodeconnector
    [Arguments]    ${node_type}    ${node_id}    ${nc_type}    ${nc_id}    ${property}
    [Documentation]    Remove property from nodeconnector
    ${resp}    RequestsLibrary.Delete    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/nodeconnector/${node_type}/${node_id}/${nc_type}/${nc_id}/property/${property}
    Should Be Equal As Strings    ${resp.status_code}    204    Response status code error

Node property should exist
    [Arguments]    ${node_type}    ${node_id}    ${property}    ${value}
    [Documentation]    Property of node should exist
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/nodes
    Should Be Equal As Strings    ${resp.status_code}    200    Response status code error
    ${result}    TO JSON    ${resp.content}
    Log    ${result}
    ${nodes}    Extract All Nodes    ${result}
    ${property_values}    Extract Node Property Values    ${result}    ${property}
    ${node}    Create Dictionary    id=${node_id}    type=${node_type}
    ${property_value}    Create Dictionary    value=${value}
    Log    ${property_value}
    List Should Contain Value    ${nodes}    ${node}
    List Should Contain Value    ${property_values}    ${property_value}

Node property should not exist
    [Arguments]    ${node_type}    ${node_id}    ${property}    ${value}
    [Documentation]    Property of node should not exist
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/nodes
    Should Be Equal As Strings    ${resp.status_code}    200    Response status code error
    ${result}    TO JSON    ${resp.content}
    Log    ${result}
    ${nodes}    Extract All Nodes    ${result}
    ${properties}    Extract Node Property Values    ${result}    ${property}
    ${node}    Create Dictionary    id=${node_id}    type=${node_type}
    ${property}    Create Dictionary    value=${value}
    Log    ${property}
    List Should Contain Value    ${nodes}    ${node}
    List Should Not Contain Value    ${properties}    ${property}

Nodeconnector property should exist
    [Arguments]    ${node_type}    ${node_id}    ${nc_type}    ${nc_id}    ${property}    ${value}
    [Documentation]    Property of nodeconnector should exist
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/node/${node_type}/${node_id}
    Should Be Equal As Strings    ${resp.status_code}    200    Response status code error
    ${result}    TO JSON    ${resp.content}
    Log    ${result}
    ${property_values}    Extract Nodeconnector Property Values    ${result}    ${property}
    Log    ${property_values}
    ${property_value}    Create Dictionary    value=${value}
    List Should Contain Value    ${property_values}    ${property_value}

Nodeconnector property should not exist
    [Arguments]    ${node_type}    ${node_id}    ${nc_type}    ${nc_id}    ${property}    ${value}
    [Documentation]    Property of nodeconnector should not exist
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/${CONTAINER}/node/${node_type}/${node_id}
    Should Be Equal As Strings    ${resp.status_code}    200    Response status code error
    ${result}    TO JSON    ${resp.content}
    Log    ${result}
    ${property_values}    Extract Nodeconnector Property Values    ${result}    ${property}
    Log    ${property_values}
    ${property_value}    Create Dictionary    value=${value}
    List Should not Contain Value    ${property_values}    ${property_value}

List all nodeconnectors of node
    [Arguments]    ${node_type}    ${node_id}
    [Documentation]    List all nodeconnectors and properties of node
