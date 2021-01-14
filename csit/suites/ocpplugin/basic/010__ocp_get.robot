*** Settings ***
Documentation     Test suite for OCPPLUGIN
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/Topology.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OcpAgentKeywords.robot
Variables         ../../../variables/Variables.py
Variables         ../../../variables/ocpplugin/Variables.py

*** Variables ***

*** Test Cases ***
Check if node exist
    [Documentation]    get inventory node
    [Tags]    get node
    OcpAgentKeywords.Install Agent
    ${mininet_conn_id}=    OcpAgentKeywords.Start Emulator Single
    ${resp}    GET On Session    session    ${NODE_ID}TST-100
    Should Be Equal As Strings    ${resp.status_code}    200

Get param from emulator
    [Documentation]    OCPPLUGIN get param
    [Tags]    OCPPLUGIN get
    ${resp}    Post Request    session    ${REST_GET_PARAM}    data={"input":{"nodeId":"ocp:TST-100","objId":"ALL","paramName":"ALL"}}
    Should Be Equal As Strings    ${resp.status_code}    200
    Stop Emulator And Exit    ${mininet_conn_id}
