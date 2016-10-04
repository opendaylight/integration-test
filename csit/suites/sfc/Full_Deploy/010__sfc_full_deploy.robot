*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/SFC/SfcUtils.py
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SFC/DockerSfc.robot

*** Variables ***
${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFP1","name":"RSP1"}}
${CREATE_RSP_FAILURE_INPUT}    {"input":{"parent-service-function-path":"SFC1-empty","name":"RSP1-empty-Path-1"}}

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_METADATA_URI}    ${SERVICE_METADATA_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACLS_URI}    ${SERVICE_FUNCTION_ACLS_FILE}

Create and Get Rendered Service Path
    [Documentation]    Create and Get Rendered Service Path Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    RSP1    "parent-service-function-path":"SFP1"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Create and Get Classifiers
    [Documentation]    Apply json file descriptions of ACLs and Classifiers
    Add Elements To URI From File    ${SERVICE_CLASSIFIERS_URI}    ${SERVICE_CLASSIFIERS_FILE}
    ${classifiers}=    Create List    "service-function-classifiers"    "service-function-classifier"    "type":"ietf-access-control-list:ipv4-acl"    "scl-service-function-forwarder"
    Append To List    ${classifiers}    "name":"Classifier2"    "name":"ACL2"
    Append To List    ${classifiers}    "name":"Classifier1"    "name":"ACL1"
    Check For Elements At URI    ${SERVICE_CLASSIFIERS_URI}    ${classifiers}
    Wait Until Keyword Succeeds    60s    2s    Check Classifier Flows

*** Keywords ***
Post Elements To URI As JSON
    [Arguments]    ${uri}    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${data}    headers=${headers}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get JSON Elements From URI
    [Arguments]    ${uri}
    ${resp}    RequestsLibrary.Get Request    session    ${uri}
    ${value}    To Json    ${resp.content}
    [Return]    ${value}

Check Classifier Flows
    ${flowList}=    DockerSfc.Get Flows In Docker Containers
    log    ${flowList}
    Should Contain Match    ${flowList}    *actions=pop_nsh*
    Should Contain Match    ${flowList}    *actions=push_nsh*

Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    timeout=3s
    Utils.Flexible Mininet Login
    ${docker_cidr}=    DockerSfc.Get Docker Bridge Subnet
    ${docker_nw}=    SfcUtils.Get Network From Cidr    ${docker_cidr}
    ${docker_mask}=    SfcUtils.Get Mask From Cidr    ${docker_cidr}
    ${route_to_docker_net}=    Set Variable    sudo route add -net ${docker_nw} netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Put File    ${CURDIR}/../utils/docker-ovs.sh    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/../utils/Dockerfile    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/../utils/setup-docker-image.sh    .    mode=0755
    ${result}    SSHLibrary.Execute Command    ./setup-docker-image.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    DockerSfc.Docker Ovs Start    nodes=6    guests=1    tunnel=vxlan-gpe    odl_ip=${ODL_SYSTEM_IP}
    ${docker_name_list}=    DockerSfc.Get Docker Names As List
    Set Suite Variable    ${DOCKER_NAMES_LIST}    ${docker_name_list}
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${CONFIG_DIR}    ${CURDIR}/../../../variables/sfc/master/full-deploy
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CONFIG_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CONFIG_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${CONFIG_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CONFIG_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CONFIG_DIR}/service-function-paths.json
    Set Suite Variable    ${SERVICE_METADATA_FILE}    ${CONFIG_DIR}/service-function-metadata.json
    Set Suite Variable    ${SERVICE_FUNCTION_ACLS_FILE}    ${CONFIG_DIR}/service-function-acls.json
    Set Suite Variable    ${SERVICE_CLASSIFIERS_FILE}    ${CONFIG_DIR}/service-function-classifiers.json
    DockerSfc.Switch Ips In Json Files    ${CONFIG_DIR}    ${DOCKER_NAMES_LIST}

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    Remove All Elements At URI    ${SERVICE_CLASSIFIERS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACLS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    Remove All Elements At URI    ${SERVICE_METADATA_URI}
    DockerSfc.Docker Ovs Clean    log_file=myFile4.log
    Delete All Sessions
    SSHLibrary.Close Connection
