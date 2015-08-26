*** Settings ***
Documentation     Test suite for Topology Manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${node1}          "00:00:00:00:00:00:00:01"
${node2}          "00:00:00:00:00:00:00:02"
${node3}          "00:00:00:00:00:00:00:03"
${name}           test_userlink1
${REST_CONTEXT}    /controller/nb/v2/topology

*** Test Cases ***
Get Topology
    [Documentation]    Get Topology and validate the result.
    [Tags]    adsal
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${REST_CONTEXT}/${CONTAINER}    ${node1}    4
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${REST_CONTEXT}/${CONTAINER}    ${node1}    4
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${REST_CONTEXT}/${CONTAINER}    ${node1}    4

Add a userlink
    [Documentation]    Add a userlink, list to validate the result.
    [Tags]    adsal
    ${body}    Set Variable    {"name":"${name}", "status":"Success", "srcNodeConnector":"OF|1@OF|00:00:00:00:00:00:00:02", "dstNodeConnector":"OF|1@OF|00:00:00:00:00:00:00:03"}
    ${expected_content}    To JSON    ${body}
    ${resp}    RequestsLibrary.Put    session    ${REST_CONTEXT}/${CONTAINER}/userLink/${name}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/${CONTAINER}/userLinks
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${resp_content}    Get From Dictionary    ${result}    userLinks
    List Should Contain Value    ${resp_content}    ${expected_content}

Remove a userlink
    [Documentation]    Remove a userlink, list to validate the result.
    [Tags]    adsal
    ${expected_content}    Create Dictionary    name=${name}    status=Success    srcNodeConnector=OF|1@OF|00:00:00:00:00:00:00:02    dstNodeConnector=OF|1@OF|00:00:00:00:00:00:00:03
    ${resp}    RequestsLibrary.Delete    session    ${REST_CONTEXT}/${CONTAINER}/userLink/${name}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/${CONTAINER}/userLinks
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${resp_content}    Get From Dictionary    ${result}    userLinks
    List Should Not Contain Value    ${resp_content}    ${expected_content}
