*** Settings ***
Documentation     Test suite for pushing/verify/remove a flow through RESTCONF
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${REST_CON}       restconf/config
${FILE}           ${CURDIR}/../../../variables/natapp/dynamic_globalIP.json
@{FLOWELMENTS}    idle_timeout=20    mod_nw_dst

*** Test Cases ***
Add a globalIP to Dynamic NAT
    [Documentation]    Push a list of GlobalIP to Dynamic NAT
    [Tags]    Push
    ${body}    OperatingSystem.Get File    ${FILE}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${REST_CON}/natapp:dynamicNat/    headers=${HEADERS}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after adding globalIP to Dynamic NAT
    [Documentation]    Verify the list of GlobalIP from Dynamic NAT
    [Tags]    Get
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CON}/natapp:dynamicNat/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    compare xml    ${body}    ${resp.content}

Verify flows after adding flow config on OVS
    [Documentation]    Checking Flows on switch
    [Tags]    Switch
    Switch Connection    ${mininet_conn_id}
    write    sh ovs-ofctl dump-flows s1
    ${switchoutput}    Read Until    >
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    Should Contain    ${switchoutput}    ${flowElement}
