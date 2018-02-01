*** Settings ***
Documentation     Test suite for SFC Persistency. Checks that system persistency is working as expected
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
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

*** Variables ***
${JSON_DIR}       ${CURDIR}/../../../variables/sfc/master
${SERVICE_FUNCTIONS_FILE}    ${JSON_DIR}/service-functions.json
${SERVICE_FORWARDERS_FILE}    ${JSON_DIR}/service-function-forwarders.json
${SERVICE_NODES_FILE}    ${JSON_DIR}/service-nodes.json
${SERVICE_CHAINS_FILE}    ${JSON_DIR}/service-function-chains.json
${SERVICE_FUNCTION_PATHS_FILE}    ${JSON_DIR}/service-function-paths.json
${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-1"}}
@{SF_NAMES}    napt44-103-2   napt44-103-1    dpi-102-2    firewall-101-2    napt44-104    dpi-102-1    firewall-104    dpi-102-3    firewall-101-1

*** Test Cases ***
Add SFC Elements and restart cluster
    [Documentation]    Add SFC Elements and restart the cluster. Next, it is queried the RSP wich returns a 404 error code.
    Add SFC Elements
    ${session} =    Resolve Http Session for Controller
    Kill_Members_From_List_Or_All
    Start_Members_From_List_Or_All    wait_for_sync=True
    Wait until Keyword succeeds    2min    5 sec    Get Data From URI    session    ${SERVICE_FORWARDERS_URI}
    Wait until Keyword succeeds    2min    5 sec    Get Data From URI    session    ${SERVICE_NODES_URI}
    Wait until Keyword succeeds    2min    5 sec    Get Data From URI    session    ${SERVICE_FUNCTIONS_URI}
    Wait Until Keyword Succeeds    2min    5 sec    Check Service Function Types Added    ${SF_NAMES}
    Wait until Keyword succeeds    2min    5 sec    Get Data From URI    session    ${SERVICE_CHAINS_URI}
    Wait until Keyword succeeds    2min    5 sec    Get Data From URI    session    ${SERVICE_FUNCTION_PATHS_URI}
    Wait until Keyword succeeds    2min    5 sec    TemplatedRequests.Get_As_Json_Templated    session=${session}    folder=${RESTCONF_MODULES_DIR}    verify=False
    Wait until Keyword succeeds    2min    5 sec    Get Data From URI    session    ${OPERATIONAL_RSPS_URI}
    [Teardown]    Remove SFC Elements

*** Keywords ***
Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    ClusterManagement Setup
    Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Add SFC Elements
    [Documentation]    Add Elements to the Controller via API REST
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Added    ${SF_NAMES}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    Wait until Keyword succeeds    60s    2s    Get Data From URI    session    ${OPERATIONAL_RSPS_URI}

Remove SFC Elements
    [Documentation]    Remove Elements from the Controller via API REST
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}

Resolve Http Session for Controller
    ${session} =    Resolve_Http_Session_For_Member    member_index=1
    [Return]    ${session}
