*** Settings ***
Documentation     Test suite for quicking testing if the environme setup is correct
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Default Tags      TCP_BASIC
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           json
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/UscUtils.robot

*** Test Cases ***
View Channel
    ${topo}    Create Dictionary    topology-id=usc
    ${input}    Create Dictionary    input=${topo}
    ${data}    json.dumps    ${input}
    ${resp}    Post Request    session    ${REST_VIEW_CHANNEL}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "topology"
