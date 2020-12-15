*** Settings ***
Documentation     Test suite for testing MD-SAL netty replication functionality
Suite Setup       Setup_Suite
Test Setup        Setup_Test
Test Teardown     Teardown_Test
Suite Teardown    Teardown _Suite
Default Tags      3node    critical    netty-replicate
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/NettyReplication.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot

*** Variables ***
#@{REQUIRED_FEATURES}    features-controller    odl-mdsal-exp-replicate-netty    odl-restconf-nb-bierman02    odl-netconf-clustered-topology    odl-clustering-test-app
${NETCONF_DEV_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-device
${CARPEOPLE_DEV_FOLDER}    ${CURDIR}/../../../variables/carpeople/crud
${DEVICE_IP}      120.20.10.1
${DEVICE_PORT}    8842
${DEVICE_USER}    admin
${DEVICE_PASSWORD}    admin
${ADDITIONAL_SOURCE_NODE_INDEX}    ${3}
@{MULTIPLE_SINK_NODES_INDEXES}    ${2}    ${3}

*** Test Cases ***
Replicate_Config_Addition
    [Documentation]    Adding new configuration on source node is replicated on sink node.
    NettyReplication.Setup_Netty_Replication
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    iterations=${5}

Replicate_config_Update
    [Documentation]    Updating existing configuration on source node is replicated on sink node.
    NettyReplication.Setup_Netty_Replication
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    iterations=${5}    iter_j_offset=${0}
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    iterations=${5}    iter_j_offset=${5}

Replicte_Config_Deletion
    [Documentation]    Updating existing configuration on source node is replicated on sink node.
    NettyReplication.Setup_Netty_Replication
    &{mapping} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    iterations=${5}
    Delete_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people

Replicate_Multiple_Changes_to_Config
    [Documentation]    CRUD configuration changes done on source node are replicated on sink node.
    NettyReplication.Setup_Netty_Replication
    &{mapping_1} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    iterations=${5}    iter_j_offset=${0}
    &{mapping_2} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    iterations=${7}    iter_j_offset=${0}
    &{mapping_2_updated} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    iterations=${7}    iter_j_offset=${2}
    Delete_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people

Replicate_Multiple_Changes_to_Multiple_Sinks
    [Documentation]    CRUD configuration changes done on source node are replicated on both sink node.
    NettyReplication.Setup_Netty_Replication    source_memeber_index=${DEFAULT_NETTY_SOURCE_NODE_INDEX}    sink_members_indexes=@{MULTIPLE_SINK_NODES_INDEXES}
    &{mapping_1} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    sink_node_indexes=@{MULTIPLE_SINK_NODES_INDEXES}    iterations=${5}    iter_j_offset=${0}
    &{mapping_2} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    sink_node_indexes=@{MULTIPLE_SINK_NODES_INDEXES}    iterations=${7}    iter_j_offset=${0}
    &{mapping_2_updated} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    sink_node_indexes=@{MULTIPLE_SINK_NODES_INDEXES}    iterations=${8}    iter_j_offset=${2}
    Delete_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people

Sink_Catch_Up_After_Opening_Connection
    [Documentation]    Sink should catch up to changes made on source node before connecting.
    NettyReplication.Open_Source_Connection
    &{mapping} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    sink_node_indexes=@{EMPTY}    iterations=${5}
    ${netty_sink_session_alias} =    Resolve_Http_Session_For_Member    member_index=@{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]
    Verify_Config_Is_Not_Present    ${CARPEOPLE_DEV_FOLDER}/people   session=${netty_sink_session_alias}    wait_time=5s
    NettyReplication.Open_Sink_Connection
    Verify_Config_Is_Present    ${CARPEOPLE_DEV_FOLDER}/people    session=${netty_sink_session_alias}    iterations=${5}

Reconnect_After_Lost_Connection
    [Documentation]    Test if sink sucessfuly reconnects after lost connection and if changes made during lost connection are resent on reconnected sink's datastore.
    NettyReplication.Setup_Netty_Replication
    ClusterManagement.Isolate_Member_From_List_Or_All    @{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]
    &{mapping} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    sink_node_indexes=@{EMPTY}    iterations=${5}
    ${netty_sink_session_alias} =    Resolve_Http_Session_For_Member    member_index=@{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]
    Verify_Config_Is_Not_Present    ${CARPEOPLE_DEV_FOLDER}/people    session=${netty_sink_session_alias}    wait_time=5s
    ClusterManagement.Rejoin_Member_From_List_Or_All    @{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]
    Verify_Config_Is_Present    ${CARPEOPLE_DEV_FOLDER}/people    session=${netty_sink_session_alias}    iterations=${5}
    [Teardown]    Teardown_Isolation_Test

Change_Replication_Source
    [Documentation]    After changing replication source ODL to another ODL sink should reflect datastore from newer source forgeting changes from the old datastore.
    NettyReplication.Setup_Netty_Replication
    &{mapping_older} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/people    iterations=${5}
    NettyReplication.Teardown_Netty_Replication
    # switch source node 1 -> 3
    NettyReplication.Setup_Netty_Replication    source_memeber_index=${ADDITIONAL_SOURCE_NODE_INDEX}    sink_members_indexes=${DEFAULT_NETTY_SINK_NODE_INDEXES}
    &{mapping_newer} =    BuiltIn.Create_Dictionary
    Put_Config_And_Verify    ${CARPEOPLE_DEV_FOLDER}/cars    source_node_index=${ADDITIONAL_SOURCE_NODE_INDEX}    iterations=${8}
    # check if data from old source was forgotten (removed)
    ${netty_sink_session_alias} =    Resolve_Http_Session_For_Member    member_index=@{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]
    Verify_Config_Is_Not_Present    ${CARPEOPLE_DEV_FOLDER}/people    session=${netty_sink_session_alias}    removal=True

*** Keywords ***
Setup_suite
    [Documentation]    Open karaf connections to each ODL and deconfigure cluster to prevent interferance of shard replication with netty replication.
    KarafKeywords.Setup_Karaf_Keywords
    BuiltIn.Log_Variables
    # deconfigure cluster
    ${members_index_list} =    List_Indices_Or_All
    FOR    ${cluster_member_index}    IN    @{members_index_list}
        ${member_ip_address} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${cluster_member_index}
        # backup old configuration files
        Run_Bash_Command_On_Member    command=pushd ${karaf_home} && tar -cvf config_backup.tar ./configuration/initial/ && popd    member_index=${cluster_member_index}
        Run_Bash_Command_On_Member    command=rm -f custom_shard_config.txt    member_index=${cluster_member_index}
        Run_Bash_Command_On_Member    command=pushd ${karaf_home} && ./bin/configure_cluster.sh 1 ${member_ip_address} && popd    member_index=${cluster_member_index}
    END

Teardown_Suite
    [Documentation]    Close all opended connections.
    ${members_index_list} =    List_Indices_Or_All
    FOR    ${cluster_member_index}    IN    @{members_index_list}
        ${member_ip_address} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${cluster_member_index}
        Run_Bash_Command_On_Member    command=pushd ${karaf_home} && rm -rf ./configuration/initial/ && popd    member_index=${cluster_member_index}
        # restore old config files
        Run_Bash_Command_On_Member    command=pushd ${karaf_home} && tar -xvf config_backup.tar && popd    member_index=${cluster_member_index}
    END
    #RequestsLibrary.Delete_All_Sessions
    #SSHLibrary.Close_All_Connections
    BuiltIn.Log_Variables

Setup_Test
    [Documentation]    Clear all datastores.
    Restart_Cluster_Members_And_Clear_Data
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing

Teardown_Test
    [Documentation]    Close all netty replication connections and show linked bugs in case of failure.
    FOR    ${sink_member_index}    IN    @{ClusterManagement__member_index_list}
        NettyReplication.Close_Source_Connection    ${sink_member_index}
        NettyReplication.Close_Sink_Connection    ${sink_member_index}
    END
    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Teardown_Isolation_Test
    [Documentation]    Tears down test where isolation is used. Additionally to traditional teardown resets iptables rules set during isolation.
    FOR    ${member_index}    IN    @{ClusterManagement__member_index_list}
        ClusterManagement.Rejoin_Member_From_List_Or_All    ${member_index}
    END
    Teardown_Test

Restart_Cluster_Members_And_Clear_Data
    [Documentation]    Clears data after stoping all members, then restarts all members and recreate connections.
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Clean_Journals_Data_And_Snapshots_On_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    #KarafKeywords.Setup_Karaf_Keywords
    #${features_string} =    Catenate    SEPARATOR=${SPACE}    @{REQUIRED_FEATURES}
    #KarafKeywords.Log_Message_To_Controller_Karaf    Before instalation:
    BuiltIn.Run_Keyword_And_Continue_On_Failure    ClusterManagement.Run_Karaf_Command_On_Member     feature:list    member_index=${1}    timeout=60s
    #ClusterManagement.Install_Feature_On_List_Or_All    ${features_string}
    #ClusterManagement.Run_Karaf_Command_On_Member     feature:list    member_index=${1}
    #BuiltIn.Run_Keyword_And_Continue_On_Failure    ClusterManagement.Run_Karaf_Command_On_Member     feature:install features-controller odl-mdsal-exp-replicate-netty odl-restconf-nb-bierman02 odl-netconf-clustered-topology    member_index=${1}
    #BuiltIn.Run_Keyword_And_Continue_On_Failure    ClusterManagement.Run_Karaf_Command_On_Member     odl-clustering-test-app    member_index=${1}
    #BuiltIn.Run_Keyword_And_Continue_On_Failure    ClusterManagement.Run_Karaf_Command_On_Member     feature:list    member_index=${1}
    #ClusterManagement.Install_Feature_On_List_Or_All    odl-clustering-test-app \n feature:list \n
    #KarafKeywords.Log_Message_To_Controller_Karaf    After instalation:

Put_Config_And_Verify
    [Arguments]    ${template_folder}    ${mapping}={}    ${source_node_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}    @{sink_node_indexes}=${DEFAULT_NETTY_SINK_NODE_INDEXES}
    ...    ${iterations}=${1}    ${iter_j_offset}=${0}
    [Documentation]    Request put config on netty replicate source and verify changes has been made on both source and sinks.
    ${netty_source_session_alias} =    Resolve_Http_Session_For_Member    member_index=${source_node_index}
    TemplatedRequests.Put_As_Json_Templated    ${template_folder}    session=${netty_source_session_alias}    iterations=${iterations}    iter_j_offset=${iter_j_offset}
    Verify_Config_Is_Present    template_folder=${template_folder}    mapping=${mapping}    session=${netty_source_session_alias}    iterations=${iterations}    iter_j_offset=${iter_j_offset}
    FOR    ${sink_node_index}    IN    @{sink_node_indexes}
        ${netty_sink_session_alias} =    Resolve_Http_Session_For_Member    member_index=${sink_node_index}
        Verify_Config_Is_Present    template_folder=${template_folder}    mapping=${mapping}    session=${netty_sink_session_alias}    iterations=${iterations}    iter_j_offset=${iter_j_offset}
    END

Verify_Config_Is_Present
    [Arguments]    ${template_folder}    ${session}    ${mapping}={}    ${iterations}=${1}    ${iter_j_offset}=${0}
    [Documentation]    Verifies config is present on target node datastore by using XML get template.
    BuiltIn.Should_Not_Be_Empty    ${session}    Could not verify, session to node is not opened
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Json_Templated    ${template_folder}
    ...    verify=True    session=${session}    iterations=${iterations}    iter_j_offset=${iter_j_offset}

Delete_Config_And_Verify
    [Arguments]    ${template_folder}    ${mapping}={}    ${source_node_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}    @{sink_node_indexes}=${DEFAULT_NETTY_SINK_NODE_INDEXES}
    ...    ${iterations}=${1}
    [Documentation]    Request delete config on netty replicate source and verify changes has been made on both source and sink.
    ${netty_source_session_alias} =    Resolve_Http_Session_For_Member    member_index=${source_node_index}
    TemplatedRequests.Delete_Templated    ${template_folder}    session=${netty_source_session_alias}
    Verify_Config_Is_Not_Present    template_folder=${template_folder}    mapping=${mapping}    session=${netty_source_session_alias}    removal=True
    FOR    ${sink_node_index}    IN    @{sink_node_indexes}
        ${netty_sink_session_alias} =    Resolve_Http_Session_For_Member    member_index=${sink_node_index}
        Verify_Config_Is_Not_Present    template_folder=${template_folder}    mapping=${mapping}    session=${netty_sink_session_alias}    removal=True
    END

Verify_Config_Is_Not_Present
    [Arguments]    ${template_folder}    ${session}    ${mapping}={}    ${removal}=False    ${wait_time}=0s
    [Documentation]    Verifies config is not present on target node datastore by using XML get template. Should get return code 404 or 409.
    ...    removal - Retries until config is not present (in case of cofig deletion when config migh be present at begining, but disapears later)
    ...    wait_time - Retries for specific time if config is not present during the whole wait time (in case of config addition when config might appear after some time)
    BuiltIn.Should_Not_Be_Empty    ${session}    Could not verify, session to node is not opened
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${template_folder}    base_name=location    extension=uri    mapping=${mapping}
    BuiltIn.Run_Keyword_If    ${removal}    Until_Confg_Is_Removed    ${session}    ${uri}
    ...    ELSE IF    "${wait_time}" != "0s"    Config_Does_Not_Appear_During_Time    ${session}    ${uri}    ${wait_time}
    ...    ELSE    Utils.No_Content_From_URI    ${session}    ${uri}

Until_Confg_Is_Removed
    [Arguments]    ${session}    ${uri}
    [Documentation]    Retries until config is not avaibale
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    Utils.No_Content_From_URI    ${session}    ${uri}

Config_Does_Not_Appear_During_Time
    [Arguments]    ${session}    ${uri}    ${wait_time}
    [Documentation]    Retries if config does not appear during the wait time
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${wait_time}    1s    Utils.No_Content_From_URI    ${session}    ${uri}
