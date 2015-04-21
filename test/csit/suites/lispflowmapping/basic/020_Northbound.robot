*** Settings ***
Documentation     Test suite to verify AD-SAL based Northbound is OK
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Variables         ../../../variables/lispflowmapping/Variables.py
Resource          ../../../libraries/Utils.txt

*** Variables ***
${NB_KEY}         /lispflowmapping/nb/v2/default/key
${NB_MAPPING}     /lispflowmapping/nb/v2/default/mapping
${EID_V4}         192.0.2.1

*** Test Cases ***
Add Key
    [Documentation]    Add key for mapping registration
    ${resp}    RequestsLibrary.Put    session    ${NB_KEY}    ${add_key}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Mapping
    [Documentation]    Add mapping to database
    ${resp}    RequestsLibrary.Put    session    ${NB_MAPPING}    ${add_mapping}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Mapping
    [Documentation]    Get a mapping from the database
    ${resp}    RequestsLibrary.Get    session    ${NB_MAPPING}/0/1/${EID_V4}/32
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Dictionaries Should Be Equal    ${resp.json()}    ${get_mapping}
