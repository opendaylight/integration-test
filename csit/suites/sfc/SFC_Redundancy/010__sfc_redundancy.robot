*** Settings ***
Documentation     Test suite for SFC Redundancy. Checks that system redundancy is working as expected
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Variables         ../../../variables/Variables.py
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SFC/DockerSfc.robot

*** Variables ***
${ODL_SYSTEM_IP}    ${ODL_SYSTEM_1_IP}

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment
    Create Session In Controller    ${ODL_SYSTEM_1_IP}
    Add SFC Elements

Create and Get Rendered Service Path
    [Documentation]    Create and Get Rendered Service Path Through RESTConf APIs. Check that RSP is configured in every Controller
    ...    belonging to the cluster
    Create Session In Controller    ${ODL_SYSTEM_1_IP}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    RSP1    "parent-service-function-path":"SFP1"    "hop-number":0    "service-index":255
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    Create Session In Controller    ${ODL_SYSTEM_2_IP}
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    Create Session In Controller    ${ODL_SYSTEM_3_IP}
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    ${flowList}=    Get Flows In Docker Containers
    log    ${flowList}
    Should Contain Match    ${flowList}    *cookie=0x14*

*** Keywords ***
Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    log    ${ODL_STREAM}
    log    ${TOOLS_SYSTEM_IP}
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    timeout=10s
    Utils.Flexible Mininet Login
    Run Keyword If    '${ODL_STREAM}' == 'stable-lithium'    Set Suite Variable    ${VERSION_DIR}    lithium
    ...    ELSE    Set Suite Variable    ${VERSION_DIR}    master
    ${JSON_DIR}=    Set Variable    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/redundancy
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${JSON_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${JSON_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${JSON_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${JSON_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${JSON_DIR}/service-function-paths.json
    DockerSfc.Docker Ovs Start    nodes=2    guests=1    tunnel=vxlan-gpe    odl_ip=${ODL_SYSTEM_IP}

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

Check Flows Matching
    [Documentation]    Check that Flow List matches given Expression

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    Create Session In Controller    ${ODL_SYSTEM_1_IP}
    Remove SFC Elements
    DockerSfc.Docker Ovs Clean    log_file=myFile4.log
    Delete All Sessions
    SSHLibrary.Close Connection
