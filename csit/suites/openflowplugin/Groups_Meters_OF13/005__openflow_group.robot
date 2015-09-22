*** Settings ***
Documentation     Test suite for OpenFlow group
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${REST_CONTEXT}    /restconf/operational/opendaylight-inventory:nodes/
${REST_CONTEXT_CF}    /restconf/config/opendaylight-inventory:nodes/node/openflow:1
${REST_CONTEXT_OP}    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1
${GROUP}          ${CURDIR}/../../../variables/xmls/g4.xml
${FLOW}           ${CURDIR}/../../../variables/xmls/f50.xml
${GROUP_NAME}     Foo
${FLOW_NAME}      forward

*** Test Cases ***
Get list of nodes
    [Documentation]    Get the inventory to make sure openflow:1 comes up
    ${node_list}=    Create List    openflow:1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REST_CONTEXT_OP}    ${node_list}

Add a group
    [Documentation]    Add a group using RESTCONF
    [Tags]    Push
    ${body}    OperatingSystem.Get File    ${GROUP}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Put    session    ${REST_CONTEXT_CF}/group/1    headers=${HEADERS_XML}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after adding group config
    [Documentation]    Get the group stat in config
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT_CF}/group/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${GROUP_NAME}

Verify after adding group operational
    [Documentation]    Get the group stat in operational
    ${elements}=    Create List    group-statistics    ref-count    packet-count    byte-count    buckets    weight    group-select
    Wait Until Keyword Succeeds    6s    2s    Check For Elements At URI    ${REST_CONTEXT_OP}/group/1    ${elements}

Add a flow that includes a group
    [Documentation]    Push a flow through RESTCONF
    [Tags]    Push
    ${body}    OperatingSystem.Get File    ${FLOW}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Put    session    ${REST_CONTEXT_CF}/table/0/flow/1    headers=${HEADERS_XML}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after adding flow config
    [Documentation]    Verify the flow
    [Tags]    Get
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT_CF}/table/0/flow/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${FLOW_NAME}

Verify after adding flow operational
    [Documentation]    Verify the flow
    ${elements}=    Create List    group-action    group-id
    Wait Until Keyword Succeeds    6s    2s    Check For Elements At URI    ${REST_CONTEXT_OP}/table/0/flow/1    ${elements}

Remove the flow
    [Documentation]    Remove the flow
    ${resp}    RequestsLibrary.Delete    session    ${REST_CONTEXT_CF}/table/0/flow/1
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting flow
    [Documentation]    Verify the flow removal
    [Tags]    Get
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT_CF}/table/0/flow/1
    Should Not Contain    ${resp.content}    ${FLOW_NAME}

Delete the group
    [Documentation]    Remove the group
    [Tags]    Delete
    ${resp}    RequestsLibrary.Delete    session    ${REST_CONTEXT_CF}/group/1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting group
    [Documentation]    Verify the flow removal
    [Tags]    Get
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT_CF}/group/1
    Should Not Contain    ${resp.content}    ${GROUP_NAME}
