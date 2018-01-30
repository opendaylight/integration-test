*** Settings ***
Documentation     Test suite for symmetric RSP using bidirectional field of SF type.
Suite Setup       Init Suite
Suite Teardown    End Suite
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Resource          ../../../libraries/SFC/SfcKeywords.robot
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Variables ***
${VERSION_DIR}    master
${SUITE_DIR}      ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/symmetricRSP
${SERVICE_NODES_FILE}    ${SUITE_DIR}/service_nodes.json
${SERVICE_FUNCTION_TYPES_FILE}    ${SUITE_DIR}/service_function_types.json
${SERVICE_FUNCTIONS_FILE}    ${SUITE_DIR}/service_functions.json
${SERVICE_FORWARDERS_FILE}    ${SUITE_DIR}/service_function_forwarders.json
${SERVICE_CHAINS_FILE}    ${SUITE_DIR}/service_function_chains.json
${SERVICE_FUNCTION_PATHS_FILE}    ${SUITE_DIR}/service_function_paths.json
${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFP1","name":"RSP1"}}
${CREATE_RSP2_INPUT}    {"input":{"parent-service-function-path":"SFP2","name":"RSP2"}}
${CREATE_RSP3_INPUT}    {"input":{"parent-service-function-path":"SFP3","name":"RSP3"}}
${DELETE_RSP1_INPUT}    {"input":{"name":"RSP1"}}
${DELETE_RSP2_INPUT}    {"input":{"name":"RSP2"}}
${DELETE_RSP3_INPUT}    {"input":{"name":"RSP3"}}
@{SF_NAMES}       "name":"firewall-1"    "name":"dpi-1"    "name":"dpi-2"

*** Test Cases ***
Create symmetric RSP with bidirectional flag set true in one SF type
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}=    Create List    RSP1    RSP1-Reverse
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    [Teardown]    Post Elements To URI    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}

Create non-symmetric RSP with bidirectional flag set false or not set in all SFs
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP2_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    RSP2
    Should Not Contain    ${resp.content}    RSP2-Reverse
    [Teardown]    Post Elements To URI    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP2_INPUT}

Create non-symmetric RSP overriding bidirectional flag with SFP symmetric flag
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP3_INPUT}
    # Note that SFP3 uses SFC1, which contains a dpi-bidirectional, but it's
    # overriden with symmetric flag in SFP set to false
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    RSP3
    Should Not Contain    ${resp.content}    RSP3-Reverse
    [Teardown]    Post Elements To URI    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP3_INPUT}

*** Keywords ***
Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Basic Environment Setup

Basic Environment Setup
    [Documentation]    Provision all elements except RSPs
    Clean Datastore
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_TYPES_URI}    ${SERVICE_FUNCTION_TYPES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Added    ${SF_NAMES}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}

End Suite
    Clean Datastore
    Delete All Sessions

Clean Datastore
    [Documentation]    Remove All Elements
    Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Removed    ${SF_NAMES}
    Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
    Remove All Elements If Exist    ${SERVICE_NODES_URI}
    Remove All Elements If Exist    ${SERVICE_CHAINS_URI}
    Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
