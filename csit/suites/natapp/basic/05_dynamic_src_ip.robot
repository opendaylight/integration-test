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
${SET_NAT_TYPE_JSON}    ${CURDIR}/../../../variables/natapp/set_dynamic_type.json
${SET_NAT_TYPE}    /restconf/operations/natapp:nat-type
${REST_CON}       restconf/config
${FILE}           ${CURDIR}/../../../variables/natapp/dynamic_globalIP.json
@{FLOWELMENTS}    idle_timeout=20    mod_nw_src

*** Test Cases ***
Set NatType
    ${body}    OperatingSystem.Get File    ${SET_NAT_TYPE_JSON}
    ${resp}    RequestsLibrary.Post Request    session    ${SET_NAT_TYPE}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

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
    Write    h4 ping h5 -c 5
    ${result}    Read Until    mininet>
    Log    ${result}
    sleep    5
    write    sh ovs-ofctl dump-flows s1
    ${switchoutput}    Read Until    >
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    Should Contain    ${switchoutput}    ${flowElement}
