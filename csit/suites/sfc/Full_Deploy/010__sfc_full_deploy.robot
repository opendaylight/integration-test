*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/SFC/SfcUtils.py
Resource          ../../../libraries/SFC/SfcKeywords.robot
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/SFC/DockerSfc.robot
Variables         ../../../variables/sfc/Modules.py

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment. Full Deploy
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Added    ${SF_NAMES}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_METADATA_URI}    ${SERVICE_METADATA_FILE}
    Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}    ${CREATED_SFPS}
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACLS_URI}    ${SERVICE_FUNCTION_ACLS_FILE}

Get Rendered Service Path By Name
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs. Full Deploy
    # The RSP should be symetric, so 2 should be created for the SFP
    ${rsp_name} =    Get Rendered Service Path Name    ${SFP_NAME}
    Get URI And Verify    ${OPERATIONAL_RSP_URI}${rsp_name}
    ${rsp_name_rev} =    Get Rendered Service Path Name    ${SFP_NAME}    True
    Get URI And Verify    ${OPERATIONAL_RSP_URI}${rsp_name_rev}
    ${elements}=    Create List    ${rsp_name}    "parent-service-function-path":"${SFP_NAME}"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Create and Get Classifiers
    [Documentation]    Apply json file descriptions of ACLs and Classifiers. Full Deploy
    Add Elements To URI From File    ${SERVICE_CLASSIFIERS_URI}    ${SERVICE_CLASSIFIERS_FILE}
    ${classifiers}=    Create List    "service-function-classifiers"    "service-function-classifier"    "type":"ietf-access-control-list:ipv4-acl"    "scl-service-function-forwarder"
    Append To List    ${classifiers}    "name":"Classifier2"    "name":"ACL2"
    Append To List    ${classifiers}    "name":"Classifier1"    "name":"ACL1"
    Check For Elements At URI    ${SERVICE_CLASSIFIERS_URI}    ${classifiers}
    Wait Until Keyword Succeeds    60s    2s    Check Classifier Flows

*** Keywords ***
Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    timeout=3s
    SSHKeywords.Flexible Mininet Login
    ${docker_cidr} =    DockerSfc.Get Docker Bridge Subnet
    ${docker_nw} =    SfcUtils.Get Network From Cidr    ${docker_cidr}
    ${docker_mask} =    SfcUtils.Get Mask From Cidr    ${docker_cidr}
    ${route_to_docker_net} =    Set Variable    sudo route add -net ${docker_nw} netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Put File    ${CURDIR}/docker-ovs.sh    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/Dockerfile    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/setup-docker-image.sh    .    mode=0755
    ${result} =    SSHLibrary.Execute Command    ./setup-docker-image.sh ${ODL_STREAM} > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    Set Suite Variable    @{INTERFACE_NAMES}    v-ovsnsn6g1    v-ovsnsn1g1
    DockerSfc.Docker Ovs Start    nodes=6    guests=1    tunnel=vxlan-gpe    odl_ip=${ODL_SYSTEM_IP}
    Wait Until Keyword Succeeds    60s    2s    Check For Elements At URI    ${OVSDB_TOPOLOGY_URI}    ${INTERFACE_NAMES}
    ${docker_name_list} =    DockerSfc.Get Docker Names As List
    Set Suite Variable    ${DOCKER_NAMES_LIST}    ${docker_name_list}
    log    ${ODL_STREAM}
    Set Suite Variable    ${SFP_NAME}    SFP1
    Set Suite Variable    @{CREATED_SFPS}    ${SFP_NAME}
    Set Suite Variable    ${CONFIG_DIR}    ${CURDIR}/../../../variables/sfc/master/full-deploy
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CONFIG_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CONFIG_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${CONFIG_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CONFIG_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CONFIG_DIR}/service-function-paths.json
    Set Suite Variable    ${SERVICE_METADATA_FILE}    ${CONFIG_DIR}/service-function-metadata.json
    Set Suite Variable    ${SERVICE_FUNCTION_ACLS_FILE}    ${CONFIG_DIR}/service-function-acls.json
    Set Suite Variable    ${SERVICE_CLASSIFIERS_FILE}    ${CONFIG_DIR}/service-function-classifiers.json
    Set Suite Variable    @{SF_NAMES}    "firewall-1"    "dpi-1"
    Switch Ips In Json Files    ${CONFIG_DIR}    ${DOCKER_NAMES_LIST}

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    Get Model Dump    ${ODL_SYSTEM_IP}    ${sfc_data_models}
    Remove All Elements At URI    ${SERVICE_CLASSIFIERS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACLS_URI}
    Delete Sfp And Wait For Rsps Deletion    ${SFP_NAME}
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Removed    ${SF_NAMES}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_METADATA_URI}
    DockerSfc.Docker Ovs Clean    log_file=myFile4.log
    Delete All Sessions
    SSHLibrary.Close Connection
