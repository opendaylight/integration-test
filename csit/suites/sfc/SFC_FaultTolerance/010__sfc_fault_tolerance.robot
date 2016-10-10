*** Settings ***
Documentation     Test suite for Cluster Fault Tolerance
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           HttpLibrary.HTTP
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/sfc/Variables.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{SHARD_OPER_LIST}    inventory    topology    default    entity-ownership
@{SHARD_CONF_LIST}    inventory    topology    default

*** Test Cases ***
Check Shards Status
    [Documentation]    Check Shard Status.
    Verify Shards Status

Kill Leader Karaf Instance
    [Documentation]    Kill Leader Karaf instance
    ClusterManagement.Kill Single Member    ${leader}
    Set Suite Variable    ${old_leader}    ${leader}
    BuiltIn.Sleep    30s

Get the new Leader and its Follower
    [Documentation]    Get the new Leader and Follower.
    @{follower_list} =    Create List    ${follower_node_1}    ${follower_node_2}
    ${new_leaders}    ${new_followers}    ClusterManagement.Get_State_Info_For_Shard    member_index_list=${follower_list}
    ${new_leader}=    Get From List    ${new_leaders}    0
    ${new_follower}=    Get From List    ${new_followers}    0
    Set Suite Variable    ${new_leader}
    Set Suite Variable    ${new_follower}

Create and Get Service Function
    [Documentation]    Create and get Service Function in the new Leader. Check if the config is replicated in the running Follower
    Create Session    session    http://${ODL_SYSTEM_${new_leader}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session_follower    http://${ODL_SYSTEM_${new_follower}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}    ${HEADERS_YANG_JSON}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}
    ${resp}    RequestsLibrary.Get Request    session_follower    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Restart Karaf in the Previous Leader
    [Documentation]    Restart Karaf in the Previous Leader
    ClusterManagement.Start Single Member    ${old_leader}
    BuiltIn.Sleep    30s

Check Service Function in the Restarted Member
    [Documentation]    Check if the config is replicated in the restarted node.
    Create Session    session_old_leader    http://${ODL_SYSTEM_${old_leader}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${SERVICE_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.Get Request    session_old_leader    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Get New Leader and Followers
    [Documentation]    Get New Leader and Followers
    Get Leader and Followers

*** Keywords ***
Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    ClusterManagement Setup
    Get Leader and Followers
    log    ${ODL_STREAM}
    log    ${TOOLS_SYSTEM_IP}
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    timeout=10s
    Utils.Flexible Mininet Login
    ${docker_cidr}=    DockerSfc.Get Docker Bridge Subnet
    ${docker_nw}=    SfcUtils.Get Network From Cidr    ${docker_cidr}
    ${docker_mask}=    SfcUtils.Get Mask From Cidr    ${docker_cidr}
    ${route_to_docker_net}=    Set Variable    sudo route add -net ${docker_nw} netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    # Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHLibrary.Put File    ${CURDIR}/../utils/docker-ovs.sh    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/../utils/Dockerfile    .    mode=0755
    SSHLibrary.Put File    ${CURDIR}/../utils/setup-docker-image.sh    .    mode=0755
    ${result}    SSHLibrary.Execute Command    ./setup-docker-image.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    Run Keyword If    '${ODL_STREAM}' == 'stable-lithium'    Set Suite Variable    ${VERSION_DIR}    lithium
    ...    ELSE    Set Suite Variable    ${VERSION_DIR}    master
    ${JSON_DIR}=    Set Variable    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/faulttolerance
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${JSON_DIR}/service-functions.json
    DockerSfc.Docker Ovs Start    nodes=2    guests=1    tunnel=vxlan-gpe    odl_ip=${ODL_SYSTEM_IP}

Get Leader and Followers
    [Documentation]    Find leader and followers in the shard
    ${leader}    ${followers}    Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${followers}    0
    ${follower_node_2}=    Get From List    ${followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${leader}

Verify Shards Status
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Verify shards status.
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_OPER_LIST}    shard_type=operational    member_index_list=${controller_index_list}
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_CONF_LIST}    shard_type=config    member_index_list=${controller_index_list}

Get InventoryConfig Shard Status
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Check Status for Inventory Config shard in OpenFlow application.
    ${inv_conf_leader}    ${inv_conf_followers_list}    Wait Until Keyword Succeeds    10s    1s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=inventory
    ...    shard_type=config    member_index_list=${controller_index_list}
    Log    config inventory Leader is ${inv_conf_leader} and followers are ${inv_conf_followers_list}
    [Return]    ${inv_conf_leader}    ${inv_conf_followers_list}

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    DockerSfc.Docker Ovs Clean    log_file=myFile4.log
    Delete All Sessions
    SSHLibrary.Close Connection
