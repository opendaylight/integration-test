*** Settings ***
Documentation     Test suite for ALTO simple IRD (Information Resource Dictionary)
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/ALTO/AltoParser.py
Variables         ../../../variables/Variables.py
Variables         ../../../variables/alto/Variables.py

*** Variables ***
${THE_FIRST_IRD_RESOURCE_ID}    hello
${THE_SECOND_IRD_RESOURCE_ID}    world
${RESOURCE_IN_FIRST_IRD}    test-model-networkmap
${RESOURCE_IN_SECOND_IRD}    test-model-filtered-costmap
${BASE_URL}       ${EMPTY}
${RANDOM_CONTEXT_ID}    ${EMPTY}

*** Test Cases ***
Check the simple IRD information
    [Documentation]    Get the default IRD information
    Wait Until Keyword Succeeds    5s    1s    Check GET Response Code Equals 200    /${ALTO_SIMPLE_IRD_INFO}
    ${resp}    RequestsLibrary.Get Request    session    /${ALTO_SIMPLE_IRD_INFO}
    ${context_id}    ${BASE_URL}    Get Basic Info    ${resp.content}
    Set Suite Variable    ${BASE_URL}
    Set Suite Variable    ${RANDOM_CONTEXT_ID}    ${context_id}
    Wait Until Keyword Succeeds    5s    1s    Check GET Response Code Equals 200    /${RESOURCE_POOL_BASE}/${context_id}

Create two IRDs
    [Documentation]    Create two IRDs and verify their existence
    Create An IRD    ${DEFAULT_CONTEXT_ID}    ${THE_FIRST_IRD_RESOURCE_ID}
    Wait Until Keyword Succeeds    5s    1s    Check GET Response Code Equals 200    /${ALTO_OPERATIONAL_IRD_INSTANCE}/${THE_FIRST_IRD_RESOURCE_ID}
    Create An IRD    ${DEFAULT_CONTEXT_ID}    ${THE_SECOND_IRD_RESOURCE_ID}
    Wait Until Keyword Succeeds    5s    1s    Check GET Response Code Equals 200    /${ALTO_OPERATIONAL_IRD_INSTANCE}/${THE_SECOND_IRD_RESOURCE_ID}

Add one IRD configuration entry in one IRD instance
    [Documentation]    Add one IRD configuration entry in an IRD whose name is hello. Link IRD entry to one existed resource.
    Wait Until Keyword Succeeds    5s    1s    Add An IRD Configuration Entry    ${THE_FIRST_IRD_RESOURCE_ID}    ${DEFAULT_CONTEXT_ID}    ${RESOURCE_IN_FIRST_IRD}
    ...    ${BASE_URL}
    Wait Until Keyword Succeeds    5s    1s    Add An IRD Configuration Entry    ${THE_SECOND_IRD_RESOURCE_ID}    ${DEFAULT_CONTEXT_ID}    ${RESOURCE_IN_SECOND_IRD}
    ...    ${BASE_URL}

*** Keywords ***
Check GET Response Code Equals 200
    [Arguments]    ${uri_without_ip_port}
    ${resp}    RequestsLibrary.Get Request    session    ${uri_without_ip_port}
    Should Be Equal As Strings    ${resp.status_code}    200

Create An IRD
    [Arguments]    ${context_id}    ${IRD_id}
    ${body}    Set Variable    {"ird-instance-configuration":{"entry-context":"/alto-resourcepool:context[alto-resourcepool:context-id='${context_id}']","instance-id":"${IRD_id}"}}
    ${resp}    RequestsLibrary.Put Request    session    /${ALTO_CONFIG_IRD_INSTANCE_CONFIG}/${IRD_id}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Add An IRD Configuration Entry
    [Arguments]    ${IRD_id}    ${context_id}    ${resource_id}    ${base_url}
    ${body}    Set Variable    {"ird-configuration-entry":{"entry-id":"${resource_id}","instance":"/alto-resourcepool:context[alto-resourcepool:context-id='${context_id}']/alto-resourcepool:resource[alto-resourcepool:resource-id='${resource_id}']","path":"${base_url}/${resource_id}"}}
    ${resp}    RequestsLibrary.Put Request    session    /${ALTO_CONFIG_IRD_INSTANCE_CONFIG}/${IRD_id}/ird-configuration-entry/${resource_id}    data=${body}
    should Be Equal As Strings    ${resp.status_code}    200
