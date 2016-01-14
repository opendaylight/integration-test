*** Settings ***
Documentation     Test suite for ALTO simple IRD (Information Resource Dictionary)
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    #headers=${ACCEPT_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ./AltoParser.py
Variables         ../../../variables/Variables.py

*** Variables ***
${ALTO_SIMPLE_IRD_INFO}  /restconf/operational/alto-simple-ird:information
${ALTO_CONFIG_IRD_INSTANCE_CONFIG}   /restconf/config/alto-simple-ird:ird-instance-configuration
${ALTO_OPERATIONAL_IRD_INSTANCE}    /restconf/operational/alto-simple-ird:ird-instance
${THE_FIRST_IRD_RESOURCE_ID}    hello
${THE_SECOND_IRD_RESOURCE_ID}    world
${RESOURCE_IN_FIRST_IRD}    test-model-networkmap
${RESOURCE_IN_SECOND_IRD}    test-model-filtered-costmap
${RESOURCE_POOL_BASE}    /restconf/operational/alto-resourcepool:context
${DEFAULT_CONTEXT_ID}    00000000-0000-0000-0000-000000000000
${BASE_URL}
${RANDOM_CONTEXT_ID}

*** Test Cases ***
Check the simple IRD information
    [Documentation]    Get the default IRD information
    Wait Until Keyword Succeeds    30s    2s    Check GET Response Code Equals 200    ${ALTO_SIMPLE_IRD_INFO}
    ${resp}    RequestsLibrary.Get    session    ${ALTO_SIMPLE_IRD_INFO}
    ${context_id}    ${BASE_URL}    Get Context Id And Base URL In IRD Information    ${resp.content}
    Set Suite Variable    ${BASE_URL}    ${BASE_URL}
    Set Suite Variable    ${RANDOM_CONTEXT_ID}    ${context_id}
    Wait Until Keyword Succeeds    30s    2s    Check GET Response Code Equals 200    ${RESOURCE_POOL_BASE}/${context_id}

Create two IRDs
    [Documentation]    Create two IRDs and verify their existence
    Create An IRD    ${DEFAULT_CONTEXT_ID}    ${THE_FIRST_IRD_RESOURCE_ID}
    Wait Until Keyword Succeeds    30s    2s    Check GET Response Code Equals 200    ${ALTO_OPERATIONAL_IRD_INSTANCE}/${THE_FIRST_IRD_RESOURCE_ID}
    Create An IRD    ${DEFAULT_CONTEXT_ID}    ${THE_SECOND_IRD_RESOURCE_ID}
    Wait Until Keyword Succeeds    30s    2s    Check GET Response Code Equals 200    ${ALTO_OPERATIONAL_IRD_INSTANCE}/${THE_SECOND_IRD_RESOURCE_ID}

Add one IRD configuration entry in one IRD instance
    [Documentation]    Add one IRD configuration entry in an IRD whose name is hello. Link IRD entry to one existed resource.
    Wait Until Keyword Succeeds    30s    2s    Add An IRD Configuration Entry    ${THE_FIRST_IRD_RESOURCE_ID}    ${DEFAULT_CONTEXT_ID}    ${RESOURCE_IN_FIRST_IRD}    ${BASE_URL}
    Wait Until Keyword Succeeds    30s    2s    Add An IRD Configuration Entry    ${THE_SECOND_IRD_RESOURCE_ID}    ${DEFAULT_CONTEXT_ID}    ${RESOURCE_IN_SECOND_IRD}    ${BASE_URL}

Check IRD configuration instances has been added in resource pool
    ${resp}    RequestsLibrary.Get    session    ${RESOURCE_POOL_BASE}/${RANDOM_CONTEXT_ID}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}     ${RESOURCE_IN_FIRST_IRD}
    Should Contain    ${resp.content}     ${RESOURCE_IN_SECOND_IRD}
    ${flag}    Check Ird Configuration Entry    ${resp.content}    ${THE_FIRST_IRD_RESOURCE_ID}    ${DEFAULT_CONTEXT_ID}    ${RESOURCE_IN_FIRST_IRD}
    Should Be True    ${flag}
    ${flag}    Check Ird Configuration Entry    ${resp.content}    ${THE_SECOND_IRD_RESOURCE_ID}    ${DEFAULT_CONTEXT_ID}    ${RESOURCE_IN_SECOND_IRD}
    Should Be True    ${flag}

Check operational IRD instances have been added
    ${resp}    RequestsLibrary.Get    session    ${BASE_URL}/${THE_FIRST_IRD_RESOURCE_ID}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${RESOURCE_IN_FIRST_IRD}
    ${flag}    Verify Ird     ${resp}
    Should Be True    ${flag}
    ${resp}    RequestsLibrary.Get    session    ${BASE_URL}/${THE_SECOND_IRD_RESOURCE_ID}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}     ${RESOURCE_IN_SECOND_IRD}
    ${flag}    Verify Ird     ${resp}
    Should Be True    ${flag}

*** Keywords ***
Check GET Response Code Equals 200
    [Arguments]    ${uri_without_ip_port}
    ${resp}    RequestsLibrary.Get    session    ${uri_without_ip_port}
    Should Be Equal As Strings    ${resp.status_code}    200

Create An IRD
    [Arguments]    ${context_id}    ${IRD_id}
    ${HEADERS}=   Create Dictionary    Content-Type=application/json
    ${body}    Set Variable    {"ird-instance-configuration":{"entry-context":"/alto-resourcepool:context[alto-resourcepool:context-id='${context_id}']","instance-id":"${IRD_id}"}}
    ${resp}    RequestsLibrary.Put    session    ${ALTO_CONFIG_IRD_INSTANCE_CONFIG}/${IRD_id}    data=${body}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Add An IRD Configuration Entry
    [Arguments]    ${IRD_id}    ${context_id}    ${resource_id}    ${base_url}
    ${HEADERS}=   Create Dictionary    Content-Type=application/json
    ${body}    Set Variable    {"ird-configuration-entry":{"entry-id":"${resource_id}","instance":"/alto-resourcepool:context[alto-resourcepool:context-id='${context_id}']/alto-resourcepool:resource[alto-resourcepool:resource-id='${resource_id}']","path":"${base_url}/${resource_id}"}}
    ${resp}    RequestsLibrary.Put     session    ${ALTO_CONFIG_IRD_INSTANCE_CONFIG}/${IRD_id}/ird-configuration-entry/${resource_id}    data=${body}    headers=${HEADERS}
    should Be Equal As Strings    ${resp.status_code}    200