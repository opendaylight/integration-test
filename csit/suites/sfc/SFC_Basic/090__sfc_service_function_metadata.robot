*** Settings ***
Documentation     Test suite for SFC Service Function Metadata from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTION_METADATA_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata.json
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/context-metadata
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata-context-metadata.json
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/variable-metadata
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata-variable-metadata.json
    # Set Suite Variable    ${SERVICE_FUNCTION_METADATA400_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/service-function-metadata/SFC1-400
    # Set Suite Variable    ${SERVICE_FUNCTION_METADATA400_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sfp_sfc1_metadata400.json

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
    Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/SFM3    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_FILE}
    ${elements}=    Create List    "name":"SFM3"
    Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/SFM3    ${elements}
Get existing Fixed Context Metadata Header
     [Documentation]    Get one existing Fixed Context Metadata Header (context-metadata)
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${elements}=    Create List    "name":"SFM1"
     Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/SFM1    ${elements}
Get Non-existing Fixed Context Metadata Header
     [Documentation]    Get one non-existing Fixed Context Metadata Header (context-metadata)
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/non-existing-sfcmh
     Should Be Equal As Strings    ${resp.status_code}    404
Delete A Fixed Context Metadata Header
     [Documentation]    Delete A Fixed Context Metadata Header
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/SFM1
     Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
     Remove All Elements At URI    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/SFM1
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/SFM1
     Should Be Equal As Strings    ${resp.status_code}    404
Delete A Non-existing Fixed Context Metadata Header
     [Documentation]    Delete A Non-existing Fixed Context Metadata Header
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}/non-existing-sfcmh
     Should Be Equal As Strings    ${resp.status_code}    404
Add Variable Metadata To An Existing SFM
     [Documentation]    Add Variable Metadata To An Existing SFM from JSON file
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_FILE}
     ${elements}=    Create List    "name":"SFM1"
     Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1    ${elements}
Get existing Variable Metadata
     [Documentation]    Get one existing Variable Metadata
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${elements}=    Create List    "name":"SFM1"
     Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1    ${elements}
Get Non-existing Variable Metadata
     [Documentation]    Get one non-existing Fixed Context Metadata Header (context-metadata)
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/non-existing-sfvm
     Should Be Equal As Strings    ${resp.status_code}    404
Delete A Variable Metadata
     [Documentation]    Delete A Variable Metadata
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1
     Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
     Remove All Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1
     Should Be Equal As Strings    ${resp.status_code}    404
Delete A Non-existing Variable Metadata
     [Documentation]    Delete A Non-existing Fixed Context Metadata Header
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/non-existing-sfvm
     Should Be Equal As Strings    ${resp.status_code}    404
Add Name, Class & Type To An Existing Variable Metadata
     [Documentation]    Add Name, Class & Type To An Existing Variable Metadata from JSON File

     ${name} =     BuiltIn.Set Variable    SFM1
     ${class} =     BuiltIn.Set Variable    1
     ${type} =     BuiltIn.Set Variable    1

     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_FILE}
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1
     ${elements}=    Create List    "name":"SFM1"
     Check For Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/SFM1    ${elements}
Get Existing Variable Metadata By Name, Class & Type
     [Documentation]    Get one existing Variable Metadata By Name, Class & Type

     ${name} =     BuiltIn.Set Variable    SFM1
     ${class} =     BuiltIn.Set Variable    0
     ${type} =     BuiltIn.Set Variable    0

     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${name}/tlv-metadata/${class}/${type}
     Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
Get Non-Existing Variable Metadata By Incorrect Name, Class & Type
     [Documentation]    Get non-existing Variable Metadata By Name, Class & Type

     ${name} =     BuiltIn.Set Variable    SFM1
     ${class} =     BuiltIn.Set Variable    1
     ${type} =     BuiltIn.Set Variable    0

     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${name}/tlv-metadata/${class}/${type}
     Should Be Equal As Strings    ${resp.status_code}    404
Delete Existing Variable Metadata By Name, Class & Type
     [Documentation]    Delete existing Variable Metadata By Name, Class & Type

     ${name} =     BuiltIn.Set Variable    SFM1
     ${class} =     BuiltIn.Set Variable    0
     ${type} =     BuiltIn.Set Variable    0

     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     Utils.Remove All Elements At URI    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${name}/tlv-metadata/${class}/${type}
     ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${name}/tlv-metadata/${class}/${type}
     Should Be Equal As Strings    ${resp.status_code}    404     
Delete Non-Existing Variable Metadata By Name, Class & Type
     [Documentation]    Delete non-existing Variable Metadata By Name, Class & Type

     ${name} =     BuiltIn.Set Variable    SFM1
     ${class} =     BuiltIn.Set Variable    1
     ${type} =     BuiltIn.Set Variable    0

     Add Elements To URI From File    ${SERVICE_FUNCTION_METADATA_URI}    ${SERVICE_FUNCTION_METADATA_FILE}
     ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}/${name}/tlv-metadata/${class}/${type}
     Should Be Equal As Strings    ${resp.status_code}    404
