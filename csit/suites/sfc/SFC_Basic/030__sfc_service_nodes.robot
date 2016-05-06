*** Settings ***
Documentation     Test suite for SFC Service Nodes, Operates Nodes from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot


*** Test Cases ***
Put Service Nodes
    [Documentation]    Add Service Nodes from JSON file
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_NODES_FILE}
    ${jsonbody}    To Json    ${body}
    ${nodes}    Get From Dictionary    ${jsonbody}    service-nodes
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_NODES_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${node}    Get From Dictionary    ${result}    service-nodes
    Lists Should be Equal    ${node}    ${nodes}

Delete All Service Nodes
    [Documentation]    Delete all Service Nodes
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_NODES_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_NODES_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Node
    [Documentation]    Get one Service Node
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    ${elements}=    Create List    node-101    firewall-101-2    10.3.1.101
    Check For Elements At URI    ${SERVICE_NODES_URI}service-node/node-101    ${elements}

Get A Non-existing Service Node
    [Documentation]    Get A Non-existing Service Node
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_NODES_URI}service-node/non-existing-sf
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Node
    [Documentation]    Delete A Service Node
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Remove All Elements At URI    ${SERVICE_NODES_URI}service-node/node-101
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_NODES_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    node-101

Delete A Non-existing Service Node
    [Documentation]    Delete A Non existing Service Node
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_NODES_FILE}
    ${jsonbody}    To Json    ${body}
    ${nodes}    Get From Dictionary    ${jsonbody}    service-nodes
    Remove All Elements At URI    ${SERVICE_NODES_URI}service-node/non-existing-sn
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_NODES_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${node}    Get From Dictionary    ${result}    service-nodes
    Lists Should be Equal    ${node}    ${nodes}

Put one Service Node
    [Documentation]    Put one Service Node
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Add Elements To URI From File    ${SN_NODE100_URI}    ${SN_NODE100_FILE}
    ${elements}=    Create List    node-100    10.3.1.100    dpi-100-1    firewall-102-1
    Check For Elements At URI    ${SN_NODE100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_NODES_URI}    ${elements}

Clean All Service Nodes After Tests
    [Documentation]    Delete all Service Nodes From Datastore After Tests
    Remove All Elements At URI    ${SERVICE_NODES_URI}

*** keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Run Keyword If    '${ODL_STREAM}' == 'stable-lithium'    Set Suite Variable    ${VERSION_DIR}    lithium
    ...    ELSE    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_NODES_URI}    /restconf/config/service-node:service-nodes/
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-nodes.json
    Set Suite Variable    ${SN_NODE100_URI}    /restconf/config/service-node:service-nodes/service-node/node-100
    Set Suite Variable    ${SN_NODE100_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sn_node_100.json

