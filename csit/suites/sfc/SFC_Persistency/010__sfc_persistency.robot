*** Settings ***
Documentation     Test suite for SFC Persistency. Checks that system persistency is working as expected
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Library           ../../../libraries/SFC/SfcUtils.py
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SFC/DockerSfc.robot

*** Test Cases ***
Add SFC Elements and restart controller
    [Documentation]    Add SFC Elements and restart the first controller, upon restart the config must be present
    Add SFC Elements
    ClusterManagement.Kill_Single_Member    1
    ClusterManagement.Start_Single_Member    1    wait_for_sync=False
    ${session} =    Resolve_Http_Session_For_Member    member_index=1
    Wait until Keyword succeeds    2min    5 sec    TemplatedRequests.Get_As_Json_Templated    session=${session}    folder=${RESTCONF_MODULES_DIR}    verify=False
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_NODES_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAINS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove SFC Elements

Post RSP and restart controller
    [Documentation]    Starting with SFC elements, upon controller restart, the RSP is lost.
    Add SFC Elements
    ${session} =    Resolve_Http_Session_For_Member    member_index=1
    Wait until Keyword succeeds    1min    1 sec    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ClusterManagement.Kill_Single_Member    1
    ClusterManagement.Start_Single_Member    1    wait_for_sync=False
    Wait until Keyword succeeds    2min    5 sec    TemplatedRequests.Get_As_Json_Templated    session=${session}    folder=${RESTCONF_MODULES_DIR}    verify=False
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404
    Remove SFC Elements

*** Keywords ***
Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    ${JSON_DIR}=    Set Variable    ${CURDIR}/../../../variables/sfc/master
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${JSON_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${JSON_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${JSON_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${JSON_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${JSON_DIR}/service-function-paths.json
    Set Suite Variable    ${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-1"}}
    ClusterManagement Setup
    Create Session In Controller    ${ODL_SYSTEM_1_IP}
    Utils.Run_Command_On_Controller    ${ODL_SYSTEM_1_IP}    "feature:uninstall odl-akka-clustering"

Post Elements To URI As JSON
    [Arguments]    ${uri}    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${data}    headers=${headers}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Add SFC Elements
    [Documentation]    Add Elements to the Controller via API REST
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}

Remove SFC Elements
    [Documentation]    Remove Elements from the Controller via API REST
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}

Create Session In Controller
    [Arguments]    ${CONTROLLER}=${ODL_SYSTEM_IP}
    [Documentation]    Removes previously created Sessions and creates a session in specified controller
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    Create Session In Controller    ${ODL_SYSTEM_1_IP}
    Delete All Sessions
