*** Settings ***
Documentation     Test suite for SFC Rendered Service Paths and Classifiers.
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
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/sfc/Modules.py

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment. Full Deploy
    Utils.Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Utils.Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Utils.Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    SfcKeywords.Check Service Function Types Added    ${SF_NAMES}
    Utils.Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Utils.Add Elements To URI From File    ${SERVICE_METADATA_URI}    ${SERVICE_METADATA_FILE}
    SfcKeywords.Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}    ${CREATED_SFPS}
    BuiltIn.Set Suite Variable    ${RSP_NAME}    SfcKeywords.Get Rendered Service Path Name    ${SFP_NAME}
    BuiltIn.Set Suite Variable    ${RSP_REV_NAME}    SfcKeywords.Get Rendered Service Path Name    ${SFP_NAME}    True
    ${mapping} =    BuiltIn.Create Dictionary    RSP1=${RSP_NAME}    RSP1_Reverse=${RSP_REV_NAME}
    ${sf_acl_text} =    TemplatedRequests.Resolve_Text_From_Template_File    folder=${CONFIG_DIR}    file_name=${SERVICE_FUNCTION_ACLS_FILE}    mapping=${mapping}
    Utils.Add Elements To URI And Verify    ${SERVICE_FUNCTION_ACLS_URI}    ${sf_acl_text}

Get Rendered Service Path By Name
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs. Full Deploy
    # The RSP should be symetric, so 2 should be created for the SFP
    Utils.Get URI And Verify    ${OPERATIONAL_RSP_URI}${RSP_NAME}
    Utils.Get URI And Verify    ${OPERATIONAL_RSP_URI}${RSP_REV_NAME}
    ${elements}=    BuiltIn.Create List    ${rsp_name}    "parent-service-function-path":"${SFP_NAME}"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254
    Utils.Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Create and Get Classifiers
    [Documentation]    Apply json file descriptions of ACLs and Classifiers. Full Deploy
    Utils.Add Elements To URI From File    ${SERVICE_CLASSIFIERS_URI}    ${SERVICE_CLASSIFIERS_FILE}
    ${classifiers}=    BuiltIn.Create List    "service-function-classifiers"    "service-function-classifier"    "type":"ietf-access-control-list:ipv4-acl"    "scl-service-function-forwarder"
    Append To List    ${classifiers}    "name":"Classifier2"    "name":"ACL2"
    Append To List    ${classifiers}    "name":"Classifier1"    "name":"ACL1"
    Utils.Check For Elements At URI    ${SERVICE_CLASSIFIERS_URI}    ${classifiers}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    SfcKeywords.Check Classifier Flows

*** Keywords ***
Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    timeout=3s
    SSHKeywords.Flexible Mininet Login
    ${docker_cidr} =    DockerSfc.Get Docker Bridge Subnet
    ${docker_nw} =    SfcUtils.Get Network From Cidr    ${docker_cidr}
    ${docker_mask} =    SfcUtils.Get Mask From Cidr    ${docker_cidr}
    ${route_to_docker_net} =    BuiltIn.Set Variable    sudo route add -net ${docker_nw} netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Put File    ${CURDIR}/docker-ovs.sh    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/Dockerfile    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/setup-docker-image.sh    .    mode=0755
    ${result} =    SSHLibrary.Execute Command    ./setup-docker-image.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    BuiltIn.log    ${result}
    BuiltIn.Should be equal as integers    ${result[2]}    0
    BuiltIn.Set Suite Variable    @{INTERFACE_NAMES}    v-ovsnsn6g1    v-ovsnsn1g1
    DockerSfc.Docker Ovs Start    nodes=6    guests=1    tunnel=vxlan-gpe    odl_ip=${ODL_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    Utils.Check For Elements At URI    ${OVSDB_TOPOLOGY_URI}    ${INTERFACE_NAMES}
    ${docker_name_list} =    DockerSfc.Get Docker Names As List
    BuiltIn.Set Suite Variable    ${DOCKER_NAMES_LIST}    ${docker_name_list}
    BuiltIn.log    ${ODL_STREAM}
    BuiltIn.Set Suite Variable    ${SFP_NAME}    SFP1
    BuiltIn.Set Suite Variable    @{CREATED_SFPS}    ${SFP_NAME}
    BuiltIn.Set Suite Variable    ${CONFIG_DIR}    ${CURDIR}/../../../variables/sfc/master/full-deploy
    BuiltIn.Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CONFIG_DIR}/service-functions.json
    BuiltIn.Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CONFIG_DIR}/service-function-forwarders.json
    BuiltIn.Set Suite Variable    ${SERVICE_NODES_FILE}    ${CONFIG_DIR}/service-nodes.json
    BuiltIn.Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CONFIG_DIR}/service-function-chains.json
    BuiltIn.Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CONFIG_DIR}/service-function-paths.json
    BuiltIn.Set Suite Variable    ${SERVICE_METADATA_FILE}    ${CONFIG_DIR}/service-function-metadata.json
    BuiltIn.Set Suite Variable    ${SERVICE_FUNCTION_ACLS_FILE}    service-function-acls.json
    BuiltIn.Set Suite Variable    ${SERVICE_CLASSIFIERS_FILE}    ${CONFIG_DIR}/service-function-classifiers.json
    BuiltIn.Set Suite Variable    @{SF_NAMES}    "firewall-1"    "dpi-1"
    SfcKeywords.Switch Ips In Json Files    ${CONFIG_DIR}    ${DOCKER_NAMES_LIST}

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${sfc_data_models}
    Utils.Remove All Elements At URI    ${SERVICE_CLASSIFIERS_URI}
    Utils.Remove All Elements At URI    ${SERVICE_FUNCTION_ACLS_URI}
    SfcKeywords.Delete Sfp And Wait For Rsps Deletion    ${SFP_NAME}
    Utils.Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    SfcKeywords.Check Service Function Types Removed    ${SF_NAMES}
    Utils.Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Utils.Remove All Elements At URI    ${SERVICE_NODES_URI}
    Utils.Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Utils.Remove All Elements At URI    ${SERVICE_METADATA_URI}
    DockerSfc.Docker Ovs Clean    log_file=myFile4.log
    RequestsLibrary.Delete All Sessions
    SSHLibrary.Close Connection
