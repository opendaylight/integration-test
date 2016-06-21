*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource         ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
*** Variables ***
${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFP-1","name":"SFP-1-Path-1"}}
${CREATE_RSP_FAILURE_INPUT}    {"input":{"parent-service-function-path":"SFC1-empty","name":"SFC1-empty-Path-1"}}
*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}

Create and Get Rendered Service Path
    [Documentation]    Create and Get Rendered Service Path Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}=    Create List    SFP-1-Path-1    "parent-service-function-path":"SFP-1"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
*** comments  ***
Clean Datastore After Tests
    [Documentation]    Clean All Items In Datastore After Tests
    Sleep    1
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}

*** Keywords ***
Post Elements To URI As JSON
    [Arguments]    ${uri}    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${data}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

Get JSON Elements From URI
    [Arguments]    ${uri}
    ${resp}    RequestsLibrary.Get Request    session    ${uri}
    ${value}    To Json    ${resp.content}
    [Return]    ${value}

Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    timeout=3s
    Utils.Flexible Mininet Login
    SSHLibrary.Put File    ${CURDIR}/docker-ovs.sh    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/Dockerfile    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/setup-docker-image.sh    .    mode=0755
#    ${result}    SSHLibrary.Execute Command    ./setup-docker-image.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
#    log    ${result}
#    Should be equal as integers    ${result[2]}    0
#    ${result}    SSHLibrary.Execute Command    ./docker-ovs.sh spawn --nodes=6 --guests=1 --tun=vxlan-gpe --odl=${ODL_SYSTEM_IP} > >(tee myFile2.log) 2> >(tee myFile2.log)    return_stderr=True    return_stdout=True    return_rc=True
#    log    ${result}
#    Should be equal as integers    ${result[2]}    0
    SSHLibrary.Close Connection
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Run Keyword If    '${ODL_STREAM}' == 'stable-lithium'    Set Suite Variable    ${VERSION_DIR}    lithium
    ...    ELSE    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/full-deploy/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/full-deploy/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/full-deploy/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/full-deploy/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/full-deploy/service-function-paths.json
    Set Suite Variable    ${SERVICE_RANDOM_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/full-deploy/service-random-schedule-type.json
    Set Suite Variable    ${SERVICE_ROUNDROBIN_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/full-deploy/service-roundrobin-schedule-type.json

