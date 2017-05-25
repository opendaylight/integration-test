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
${NODE_AMOUNT}    20

*** Test Cases ***
Install agent
    [Documentation]    install agent
    [Tags]    install
    OcpAgentKeywords.Install Agent

Create multiple emulators
    [Documentation]    get inventory node
    [Tags]    get node
    ${NODE_AMOUNT}=    Convert To Integer    ${NODE_AMOUNT}
    ${mininet_conn_id}=    OcpAgentKeywords.Start Emulator Multiple    number=${NODE_AMOUNT+1}
    ${resp}    Get Request    session    ${NODE_ID}TST-${NODE_AMOUNT}
    Should Be Equal As Strings    ${resp.status_code}    200

Get param from emulators
    [Documentation]    OCPPLUGIN get param
    [Tags]    OCPPLUGIN get
    ${NODE_AMOUNT}=    Convert To Integer    ${NODE_AMOUNT}
    : FOR    ${NODE_NUM}    IN RANGE    1    ${NODE_AMOUNT+1}
    \    ${resp}    Post Request    session    ${REST_GET_PARAM}    data={"input":{"nodeId":"ocp:TST-${NODE_NUM}","objId":"ALL","paramName":"ALL"}}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    Stop Emulator And Exit    ${mininet_conn_id}
