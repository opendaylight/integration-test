*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs
...               Test The Logical SFF end to end traffic (using 'dovs' simulated neutron network)
...               Test traffic in two Service Function Chains, each SFs in a different subnet
...               Test traffic after moving one VM to other compute node
...
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/SFC/SfcUtils.py
Variables         ../../../variables/Variables.py
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SFC/DockerSfc.robot

*** Variables ***
${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFP1","name":"RSP1"}}
${CREATE_RSP_FAILURE_INPUT}    {"input":{"parent-service-function-path":"SFC1-empty","name":"RSP1-empty-Path-1"}}

*** Test Cases ***
Test Traffic after VM migration
    [Documentation]    Test Traffic after VM migration
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;./test_case_02_move_vm_different_subnet.sh -o ${ODL_SYSTEM_IP} > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0

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

Switch Ips In Json Files
    [Arguments]    ${json_dir}    ${container_names}
    ${normalized_dir}=    OperatingSystem.Normalize Path    ${json_dir}/*.json
    : FOR    ${cont_name}    IN    @{container_names}
    \    ${cont_ip}=    Get Docker IP    ${cont_name}
    \    OperatingSystem.Run    sudo sed -i 's/${cont_name}/${cont_ip}/g' ${normalized_dir}

Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    timeout=3s
    Utils.Flexible Mininet Login
    ${docker_cidr}=    DockerSfc.Get Docker Bridge Subnet
    ${docker_nw}=    SfcUtils.Get Network From Cidr    ${docker_cidr}
    ${docker_mask}=    SfcUtils.Get Mask From Cidr    ${docker_cidr}
    ${route_to_docker_net}=    Set Variable    sudo route add -net 172.17.0.0 netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Put Directory    ${CURDIR}/sfc-docker    .    mode=0755    recursive=True
    ${route_to_docker_net}=    Set Variable    sudo route add -net 172.18.0.0 netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Put Directory    ${CURDIR}/sfc-docker    .    mode=0755    recursive=True
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;sudo ./setup_ovs.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;sudo ./setup_ovs_docker.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;sudo ./setup_dovs_network.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;sudo ./setup_dovs.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    sudo ip a show docker0 > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    sudo ip a \ > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0

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
