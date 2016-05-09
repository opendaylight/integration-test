*** Settings ***
Documentation     Test suite for Mgmt Object
Suite Setup       Create Session    session    http://${CONTROLLER}:${PORT}    auth=${AUTH}    headers=${HEADERS_CSE}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${POST_CSE}       ${CURDIR}/../../../variables/iotdm/setCSE.json
${POST_NODE}    ${CURDIR}/../../../variables/iotdm/setNode.json
${POST_MGMTOBJ}    ${CURDIR}/../../../variables/iotdm/setMgmtObject.json

*** Test Cases ***

1.1 Provision CSE
    ${body}    OperatingSystem.Get File    ${POST_CSE}
    ${resp}    RequestsLibrary.Post Request    session    ${POST_CSE_URI}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

1.2 create a node
    ${body}    OperatingSystem.Get File    ${POST_NODE}
    Create Session    session1    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS_NODE}
    ${resp}    RequestsLibrary.Post Request    session1    ${POST_NODE_URI}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

1.3 Check MAndatory Parameters for Firmware as Mgmt Object
    ${body}    OperatingSystem.Get File    ${POST_MGMTOBJ}
    Create Session    session2    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS1}
    ${resp}    RequestsLibrary.Post Request    session2    ${POST_MGMTOBJECT_URI}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
