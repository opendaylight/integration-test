*** Settings ***
Documentation     Test suite for SFC Service Function Metadata from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTION_METADATA_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Variables ***
${SFM_NAME}    SFM1
${SFM_TYPE}    0
${VERSION_DIR}    master
${SERVICE_FUNCTION_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/
${SERVICE_FUNCTION_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata.json
${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/context-metadata
${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata-context-metadata.json
${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/variable-metadata
${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata-variable-metadata.json

*** Test Cases ***
Add Service Function Metadata
    [Documentation]    Add Service Function Metadata from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_METADATA_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-metadata
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${path}    Get From Dictionary    ${result}    service-function-metadata
    Lists Should be Equal    ${path}    ${paths}

Delete All Service Function Metadata
    [Documentation]    Delete all Service Function Metadata
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTION_METADATA_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Add Fixed Context Metadata Header
    [Documentation]    Add Fixed Context Metadata Header from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/${SFM_NAME}    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_FILE}
    ${elements}=    Create List    "name":"${SFM_NAME}"
    Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/${SFM_NAME}    ${elements}

Get existing Fixed Context Metadata Header
    [Documentation]    Get one existing Fixed Context Metadata Header (context-metadata)
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${elements}=    Create List    "name":"${SFM_NAME}"
    Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/${SFM_NAME}    ${elements}

Get Non-existing Fixed Context Metadata Header
    [Documentation]    Get one non-existing Fixed Context Metadata Header (context-metadata)
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/non-existing-sfcmh
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Fixed Context Metadata Header
    [Documentation]    Delete A Fixed Context Metadata Header
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/${SFM_NAME}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/${SFM_NAME}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/${SFM_NAME}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Non-existing Fixed Context Metadata Header
    [Documentation]    Delete A Non-existing Fixed Context Metadata Header
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/non-existing-sfcmh
    Should Be Equal As Strings    ${resp.status_code}    404

Add Variable Metadata To An Existing SFM
    [Documentation]    Add Variable Metadata To An Existing SFM from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_FILE}
    ${elements}=    Create List    "name":"${SFM_NAME}"
    Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}    ${elements}

Get existing Variable Metadata
    [Documentation]    Get one existing Variable Metadata
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${elements}=    Create List    "name":"${SFM_NAME}"
    Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}    ${elements}

Get Non-existing Variable Metadata
    [Documentation]    Get one non-existing Fixed Context Metadata Header (context-metadata)
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/non-existing-sfvm
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Variable Metadata
    [Documentation]    Delete A Variable Metadata
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Non-existing Variable Metadata
    [Documentation]    Delete A Non-existing Fixed Context Metadata Header
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/non-existing-sfvm
    Should Be Equal As Strings    ${resp.status_code}    404

Add Name Class and Type To An Existing Variable Metadata
    [Documentation]    Add Name, Class & Type To An Existing Variable Metadata from JSON File
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}
    ${elements}=    Create List    "name":"${SFM_NAME}"
    Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}    ${elements}

Get Existing Variable Metadata By Name Class and Type
    [Documentation]    Get one existing Variable Metadata By Name, Class & Type
    ${class} =    BuiltIn.Set Variable    0
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}/tlv-metadata/${class}/${SFM_TYPE}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get Non-Existing Variable Metadata By Incorrect Name Class and Type
    [Documentation]    Get non-existing Variable Metadata By Name, Class & Type
    ${class} =    BuiltIn.Set Variable    1
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}/tlv-metadata/${class}/${SFM_TYPE}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete Existing Variable Metadata By Name Class and Type
    [Documentation]    Delete existing Variable Metadata By Name, Class & Type
    ${class} =    BuiltIn.Set Variable    0
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    Utils.Remove All Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}/tlv-metadata/${class}/${SFM_TYPE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}/tlv-metadata/${class}/${SFM_TYPE}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete Non-Existing Variable Metadata By Name Class and Type
    [Documentation]    Delete non-existing Variable Metadata By Name, Class & Type
    ${class} =    BuiltIn.Set Variable    1
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
    ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${SFM_NAME}/tlv-metadata/${class}/${SFM_TYPE}
    Should Be Equal As Strings    ${resp.status_code}    404

*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
