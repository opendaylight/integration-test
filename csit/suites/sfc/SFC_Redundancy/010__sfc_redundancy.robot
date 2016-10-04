*** Settings ***
Documentation     Test suite for SFC Redundancy. Checks that system redundancy is working as expected
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
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SFC/DockerSfc.robot

*** Variables ***
@{SHARD_OPER_LIST}    inventory    topology    default    entity-ownership
@{SHARD_CONF_LIST}    inventory    topology    default
@{FEATURE_LIST}    odl-sfc-model    odl-sfc-provider    odl-sfc-provider-rest    odl-sfc-netconf    odl-sfc-ovs    odl-sfc-scf-openflow    odl-sfc-sb-rest
...               odl-sfc-ui

*** Test Cases ***
Check Shards Status
    [Documentation]    Check Shard Status.
    Verify Shards Status

Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment
    Create Session In Controller    ${leader}
    Add SFC Elements

Create and Get Service Functions
    [Documentation]    Create and Get Add Service Functions Through RESTConf APIs. Check if the config is replicated in every constroller
    Create Session In Controller    ${leader}
    Create Session    session_follower1    http://${ODL_SYSTEM_${follower_node_1}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session_follower2    http://${ODL_SYSTEM_${follower_node_2}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}    ${HEADERS_YANG_JSON}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}
    ${resp}    RequestsLibrary.Get Request    session_follower1    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}
    ${resp}    RequestsLibrary.Get Request    session_follower2    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Create and Get Rendered Service Path
    [Documentation]    Create and Get Rendered Service Path Through RESTConf APIs. Check that RSP is configured in every Controller
    ...    belonging to the cluster
    Create Session In Controller    ${leader}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    RSP1    "parent-service-function-path":"SFP1"    "hop-number":0    "service-index":255
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    Create Session In Controller    ${follower_node_1}
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    Create Session In Controller    ${follower_node_2}
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    ${flowList}=    Get Flows In Docker Containers
    log    ${flowList}
    Should Contain Match    ${flowList}    *cookie=0x14*

Delete Rendered Service Path By Name
    [Documentation]    Delete Rendered Service Path By Name Through RESTConf APIs From Leader and check that it's deleted from Followers as well
    Create Session In Controller    ${leader}
    Create Session    session_follower1    http://${ODL_SYSTEM_${follower_node_1}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session_follower2    http://${ODL_SYSTEM_${follower_node_2}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    RSP1
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}    RequestsLibrary.Get Request    session_follower1    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session_follower1    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}    RequestsLibrary.Get Request    session_follower2    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session_follower2    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create Service Function Forwarder in Leader and modify the config by adding a SFF DPL
    [Documentation]    Create one Service Function Forwarder in Leader and modify the config by adding a SFF DPL then check if the changes are reflected in all the Followers
    Create Session In Controller    ${leader}
    Create Session    session_follower1    http://${ODL_SYSTEM_${follower_node_1}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session_follower2    http://${ODL_SYSTEM_${follower_node_2}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Add Elements To URI From File    ${SFF_SFC100_URI}    ${SFF_SFC100_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SFF_SFC100_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    sfc-100    SF7
    Check For Elements At URI    ${SFF_SFC100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}    ${elements}
    ${resp}    RequestsLibrary.Get Request    session_follower1    ${SFF_SFC100_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Check For Elements At URI    ${SFF_SFC100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}    ${elements}
    ${resp}    RequestsLibrary.Get Request    session_follower2    ${SFF_SFC100_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Check For Elements At URI    ${SFF_SFC100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}    ${elements}
    Add Elements To URI From File    ${SFF_SFC100_URI}sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    ${elements1}=    Create List    dpl-101    6101
    Check For Elements At URI    ${SFF_SFC100_URI}sff-data-plane-locator/dpl-101    ${elements1}
    Check For Elements At URI    ${SFF_SFC100_URI}    ${elements1}
    ${resp}    RequestsLibrary.Get Request    session_follower1    ${SFF_SFC100_URI}sff-data-plane-locator/dpl-101
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    dpl-101
    ${resp}    RequestsLibrary.Get Request    session_follower2    ${SFF_SFC100_URI}sff-data-plane-locator/dpl-101
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    dpl-101

Verify if the SFC features are installed on each node
    [Documentation]    Executes command "feature list -i | grep <feature_name>" in karaf console and checks if output \ contain \ the specific features.
    : FOR    ${index}    IN RANGE    1    ${NUM_ODL_SYSTEM}+1
    \    ${member_ip} =    BuiltIn.Set_Variable    ${ODL_SYSTEM_${index}_IP}
    \    Verify if the SFC features in node    ${member_ip}

Kill leader and check followers status
    [Documentation]    Kill leader and check followers status
    ${leader_list}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    default    operational
    ${leader_list}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    default    config
    ClusterManagement.Kill_Single_Member    ${leader_list}
    Wait until Keyword succeeds    2min    5 sec    ClusterOpenFlow.Check OpenFlow Shards Status    ${follower_list}
    ClusterManagement.Start_Single_Member    ${leader_list}
    Wait until Keyword succeeds    2min    5 sec    ClusterOpenFlow.Check OpenFlow Shards Status

Complete configuration after failover
    [Documentation]    Add SFC cofiguration in leader without creating the RSP. Kill the leader. Add the RSP in the new leader. Check correction.
    ${leader_list}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    default    operational
    ${leader_ip} =    Set_Variable    ${ODL_SYSTEM_${leader_list}_IP}
    ${first_follower} =    Get From List    ${follower_list}    0
    Create Session In Controller    ${leader_ip}
    Add SFC Elements
    ClusterManagement.Kill_Single_Member    ${leader_list}
    Create Session In Controller    ${ODL_SYSTEM_${first_follower}_IP}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${session} =    Resolve_Http_Session_For_Member    ${first_follower}
    ${uri} =    BuiltIn.Set_Variable    /restconf/operational/rendered-service-path:rendered-service-paths/
    ${data_text} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${uri}    session=${session}
    ClusterManagement.Start_Single_Member    ${leader_list}
    Wait until Keyword succeeds    2min    5 sec    ClusterOpenFlow.Check OpenFlow Shards Status
    Remove SFC Elements

Check follower failure and restart
    [Documentation]    Stop karaf in follower and start again and check everything is ok
    ClusterOpenFlow.Check OpenFlow Shards Status
    ${leader_list}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    default    operational
    ${first_follower} =    Get From List    ${follower_list}    0
    ClusterManagement.Kill_Single_Member    ${first_follower}
    ClusterManagement.Start_Single_Member    ${first_follower}
    Wait until Keyword succeeds    2min    5 sec    ClusterOpenFlow.Check OpenFlow Shards Status
    ClusterOpenFlow.Check OpenFlow Shards Status

*** Keywords ***
Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    ClusterManagement Setup
    Get Leader and Followers
    Create Session In Controller    ${leader}    False
    Create Session    session_follower1    http://${ODL_SYSTEM_${follower_node_1}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session_follower2    http://${ODL_SYSTEM_${follower_node_2}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
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
    ${JSON_DIR}=    Set Variable    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/redundancy
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${JSON_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${JSON_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${JSON_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${JSON_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${JSON_DIR}/service-function-paths.json
    Set Suite Variable    ${SFF_SFC100_FILE}    ${JSON_DIR}/sff_sfc_100.json
    Set Suite Variable    ${SFF_DPL101_FILE}    ${JSON_DIR}/sff_dpl_101.json
    DockerSfc.Docker Ovs Start    nodes=2    guests=1    tunnel=vxlan-gpe    odl_ip=${ODL_SYSTEM_IP}
    ClusterManagement Setup

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
    [Arguments]    ${member}=${leader}    ${delete_all_sessions}=True
    [Documentation]    Removes previously created Sessions and creates a session in specified controller
    Run Keyword If    ${delete_all_sessions}    Delete All Sessions
    Create Session    session    http://${ODL_SYSTEM_${member}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    Create Session In Controller    ${leader}
    Remove SFC Elements
    DockerSfc.Docker Ovs Clean    log_file=myFile4.log
    Delete All Sessions
    SSHLibrary.Close Connection

Verify if the SFC features in node
    [Arguments]    ${member_ip}
    : FOR    ${feature}    IN    @{FEATURE_LIST}
    \    Verify Feature Is Installed    ${feature}    ${member_ip}
