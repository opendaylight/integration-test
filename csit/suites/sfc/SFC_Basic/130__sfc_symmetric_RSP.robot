*** Settings ***
Documentation     Test suite for symmetric RSP using bidirectional field of SF type.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Variables         ../../../variables/Variables.py
Resource         ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

Test Setup       Basic Environment Setup

*** Test Cases ***

Create symmetric RSP with bidirectional flag set true in one SF type
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    RSP1    RSP1-Reverse
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Create non-symmetric RSP with bidirectional flag set false or not set in all SFs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP2_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Log    ${resp.content}
    Should Contain    ${resp.content}    RSP2
    Should Not Contain    ${resp.content}    RSP2-Reverse

Create non-symmetric RSP overriding bidirectional flag with SFP symmetric flag
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP3_INPUT}
    # Note that SFP3 uses SFC1, which contains a dpi-bidirectional, but it's
    # overriden with symmetric flag in SFP set to false
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Log    ${resp.content}
    Should Contain    ${resp.content}    RSP3
    Should Not Contain    ${resp.content}    RSP3-Reverse

Clean Datastore After Tests
    Clean Datastore

*** Keywords ***

Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SUITE_DIR}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/symmetricRSP
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${SUITE_DIR}/service_nodes.json
    Set Suite Variable    ${SERVICE_FUNCTION_TYPES_FILE}    ${SUITE_DIR}/service_function_types.json
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${SUITE_DIR}/service_functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${SUITE_DIR}/service_function_forwarders.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${SUITE_DIR}/service_function_chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${SUITE_DIR}/service_function_paths.json
    Set Suite Variable    ${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFP1","name":"RSP1"}}
    Set Suite Variable    ${CREATE_RSP2_INPUT}    {"input":{"parent-service-function-path":"SFP2","name":"RSP2"}}
    Set Suite Variable    ${CREATE_RSP3_INPUT}    {"input":{"parent-service-function-path":"SFP3","name":"RSP3"}}

Basic Environment Setup
    [Documentation]    Prepare Basic Test Environment
    Clean Datastore
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_TYPES_URI}    ${SERVICE_FUNCTION_TYPES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}

Clean Datastore
    [Documentation]    Remove All Elements
    Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
    Remove All Elements If Exist    ${SERVICE_NODES_URI}
    Remove All Elements If Exist    ${SERVICE_CHAINS_URI}
    Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
