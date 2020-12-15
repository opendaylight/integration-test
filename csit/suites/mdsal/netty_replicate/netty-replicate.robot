*** Settings ***
Documentation     Test suite for testing MD-SAL netty replication functionality
Suite Setup       Setup_Suite
Test Setup        Setup_Test
Test Teardown     Teardown_Test
Suite Teardown    Teardown _Suite
Default Tags      3node    critical    netty-replicate
Library           SSHLibrary
Library           String
Library           XML
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
@{REQUIRED_FEATURES}    features-controller    odl-mdsal-exp-replicate-netty    odl-restconf-nb-bierman02    odl-netconf-clustered-topology    odl-clustering-test-app
${DEFAULT_SOURCE_NODE_INDEX}    ${1}
${DEFAULT_SINK_NODE_INDEX}    ${2}
${ADDITIONAL_SOURCE_NODE_INDEX}    ${3}
${NETCONF_DEV_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-device
${DEVICE_IP}      120.20.10.1
${DEVICE_PORT}    8842
${DEVICE_USER}    admin
${DEVICE_PASSWORD}    admin

*** Test Cases ***
Replicate_Config_Addition
    [Documentation]    Adding new configuration on source node is replicated on sink node.
    Setup_Netty_Replication
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-1    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}

Replicate_config_Update
    [Documentation]    Updating existing configuration on source node is replicated on sink node.
    #${ip_address} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${DEFAULT_SOURCE_NODE_INDEX}
    Setup_Netty_Replication
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-1    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    #Verify_Config_Is_Not_Present    template_folder=${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${netty_source_session_alias}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-1    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${1212}    DEVICE_USER=newer    DEVICE_PASSWORD=random
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}

Replicte_Config_Deletion
    [Documentation]    Updating existing configuration on source node is replicated on sink node.
    #${ip_address} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${DEFAULT_SOURCE_NODE_INDEX}
    Setup_Netty_Replication
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-1    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}
    Delete_Config_And_Verify    ${NETCONF_DEV_FOLDER}    mapping=${mapping}

Replicate_Multiple_Changes_to_Config
    [Documentation]    All configuration changes done on source node are replicated on sink node. Consist of adding, updating and deleting existing configuration.
    Setup_Netty_Replication
    &{mapping_1} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-1    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping_1}
    &{mapping_2} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-2    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=44444    DEVICE_USER=newer    DEVICE_PASSWORD=newer
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping_2}
    &{mapping_2_updated} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-2    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=55555    DEVICE_USER=updated    DEVICE_PASSWORD=updated
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping_2_updated}
    Delete_Config_And_Verify    ${NETCONF_DEV_FOLDER}    mapping=${mapping_1}
    #TemplatedRequests.Get_From_Uri    restconf/config/network-topology:network-topology/
    # test counts

Sink_Catch_Up_After_Opening_Connection
    [Documentation]    Sink should catch up to changes made on source node before connecting.
    Open_Source_Connection
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-2    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}    verify_on_source=True    verify_on_sink=False
    Verify_Config_Is_Not_Present    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${netty_sink_session_alias}    wait_time=5s
    Open_Sink_Connection
    Verify_Config_Is_Present    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${netty_sink_session_alias}

Reconnect_After_Lost_Connection
    [Documentation]    Test if sink sucessfuly reconnects after lost connection and if changes made during lost connection are resent on reconnected sink's datastore.
    Setup_Netty_Replication
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-2    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Verify_Config_Is_Not_Present    ${NETCONF_DEV_FOLDER}    ${mapping}    session=${netty_sink_session_alias}    wait_time=5s
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-3    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Verify_Config_Is_Not_Present    ${NETCONF_DEV_FOLDER}    ${mapping}    session=${netty_sink_session_alias}    wait_time=5s
    ClusterManagement.Isolate_Member_From_List_Or_All    ${DEFAULT_SINK_NODE_INDEX}
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-3    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}    verify_on_source=True    verify_on_sink=False
    #Verify_Config_Is_Not_Present    ${NETCONF_DEV_FOLDER}    ${mapping}    session=${netty_sink_session_alias}
    close_sink_connection
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${DEFAULT_SINK_NODE_INDEX}
    #Verify_Config_Is_Not_Present    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${netty_sink_session_alias}    wait_time=5s
    Verify_Config_Is_Present    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${netty_sink_session_alias}

Change_Replication_Source
    [Documentation]    After changing replication source ODL to another ODL sink should reflect datastore from newer source forgeting changes from the old datastore.
    Setup_Netty_Replication
    &{mapping_older} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-3    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping_older}
    Teardown_Netty_Replication
    Setup_Netty_Replication    source_memeber_index=${ADDITIONAL_SOURCE_NODE_INDEX}    sink_member_index=${DEFAULT_SINK_NODE_INDEX}
    &{mapping_newer} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-4    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=1212    DEVICE_USER=newer_source    DEVICE_PASSWORD=newer_source
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping_newer}
    Verify_Config_Is_Not_Present    ${NETCONF_DEV_FOLDER}    ${mapping_older}    ${netty_sink_session_alias}
    #TemplatedRequests.Get_From_Uri    restconf/config/network-topology:network-topology/
    # check if is only one element

*** Keywords ***
Setup_suite
    [Documentation]    Open ssh karaf connections to each ODL and setup netty replication connection betwean ODL 1 (source) and ODL 2 (sink).
    KarafKeywords.Setup_Karaf_Keywords
    BuiltIn.Log_Variables

    # deconfigure cluster shard replication
    ${members_index_list} =    List_Indices_Or_All
    FOR    ${cluster_member_index}    IN    @{members_index_list}
        ${member_ip_address} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${cluster_member_index}
        Run_Bash_Command_On_Member    command=pushd ${karaf_home} && ./bin/configure_cluster.sh 1 ${member_ip_address} && popd    member_index=${cluster_member_index}
    END


Teardown_Suite
    [Documentation]    Close all opended connections.
    #RequestsLibrary.Delete_All_Sessions
    #SSHLibrary.Close_All_Connections
    BuiltIn.Log_Variables

Setup_Test
    [Documentation]    Clear all config stored in datastore.
    Restart_Cluster_Members_And_Clear_Data
    #BuiltIn.Sleep    10s
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    #BuiltIn.Log_Variables

Teardown_Test
    [Documentation]    Show linked bugs in case of failure.
    Teardown_Netty_Replication
    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Restart_Cluster_Members_And_Clear_Data
    [Documentation]    Clears data after stoping all members, then restarts all members and recreate connections.
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Clean_Journals_Data_And_Snapshots_On_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    KarafKeywords.Setup_Karaf_Keywords
    ${features_string} =    Catenate    SEPARATOR=${SPACE}    @{REQUIRED_FEATURES}
    ClusterManagement.Install_Feature_On_List_Or_All    ${features_string}

Setup_Netty_Replication
    [Arguments]    ${source_memeber_index}=${DEFAULT_SOURCE_NODE_INDEX}    ${sink_member_index}=${DEFAULT_SINK_NODE_INDEX}
    [Documentation]    Set up connection betwean source and sink for datastore replication.
    Open_Source_Connection    ${source_memeber_index}
    Open_Sink_Connection    ${sink_member_index}
    #BuiltIn.Sleep    5s
    #KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:display    member_index=${DEFAULT_SOURCE_NODE_INDEX}
    #KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:display    member_index=${DEFAULT_SINK_NODE_INDEX}

Teardown_Netty_Replication
    [Arguments]    ${source_memeber_index}=${netty_source_cluster_index}    ${sink_member_index}=${netty_sink_cluster_index}
    [Documentation]    Tear down connection betwean source and sink for datastore replication.
    Close_Source_Connection    ${source_memeber_index}
    Close_Sink_Connection    ${sink_member_index}

Open_Source_Connection
    [Arguments]    ${source_memeber_index}=${DEFAULT_SOURCE_NODE_INDEX}
    [Documentation]    Open source part of netty replicate connection on specific node. Http session to this node is stored in sorce_odl_session_alias suite variable avaible for usage in other keywords.
    BuiltIn.Log_Variables
    ${connections} =    SSHLibrary.Get_Connections
    BuiltIn.Log    ${connections}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.source    member_index=${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled true    member_index=${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${source_memeber_index}
    ${netty_source_session_alias} =    Resolve_Http_Session_For_Member    member_index=${source_memeber_index}
    BuiltIn.Set_Suite_Variable    ${netty_source_session_alias}
    BuiltIn.Set_Suite_Variable    ${netty_source_cluster_index}    ${source_memeber_index}

Close_Source_Connection
    [Arguments]    ${source_memeber_index}=${netty_source_cluster_index}
    [Documentation]    Close sink part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.source    member_index=${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled false    member_index=${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${source_memeber_index}
    ${netty_source_cluster_index} =    Set Variable    ${EMPTY}

Open_Sink_Connection
    [Arguments]    ${sink_member_index}=${DEFAULT_SINK_NODE_INDEX}    ${source_memeber_index}=${netty_source_cluster_index}
    [Documentation]    Open sink part of netty replicate connection on specific node. Http session to this node is stored in sink_odl_session_alias suite variable avaible for usage in other keywords.
    BuiltIn.Log_Variables
    ${connections} =    SSHLibrary.Get_Connections
    BuiltIn.Log    ${connections}
    ${replicate_source_ip}=    ClusterManagement.Resolve_Ip_Address_For_Member    ${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.sink    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled true    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set source-host ${replicate_source_ip}    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${sink_member_index}
    ${netty_sink_session_alias} =    Resolve_Http_Session_For_Member    member_index=${sink_member_index}
    BuiltIn.Set_Suite_Variable    ${netty_sink_session_alias}
    BuiltIn.Set_Suite_Variable    ${netty_sink_cluster_index}    ${sink_member_index}

Close_Sink_Connection
    [Arguments]    ${sink_member_index}=${netty_sink_cluster_index}
    [Documentation]    Close source part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.sink    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled false    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${sink_member_index}
    ${netty_sink_cluster_index} =    Set Variable    ${EMPTY}

Put_Config_And_Verify
    [Arguments]    ${template_folder}    ${mapping}    ${verify_on_source}=True    ${verify_on_sink}=True
    [Documentation]    Request put config on netty replicate source and verify changes has been made on both source and sink.
    BuiltIn.Should_Not_Be_Empty    ${netty_source_session_alias}    Could not put config, session to source node is not opened.
    TemplatedRequests.Put_As_Json_Templated    ${template_folder}    mapping=${mapping}    session=${netty_source_session_alias}
    BuiltIn.Run_Keyword_If    ${verify_on_source}    Verify_Config_Is_Present    template_folder=${template_folder}    mapping=${mapping}    session=${netty_source_session_alias}
    BuiltIn.Run_Keyword_If    ${verify_on_sink}    Verify_Config_Is_Present    template_folder=${template_folder}    mapping=${mapping}    session=${netty_sink_session_alias}

Verify_Config_Is_Present
    [Arguments]    ${template_folder}    ${mapping}    ${session}
    [Documentation]    Verifies config is present on target node datastore by using XML get template.
    BuiltIn.Should_Not_Be_Empty    ${session}    Could not verify, session to node is not opened
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Json_Templated    ${template_folder}    mapping=${mapping}    verify=True    session=${session}

Delete_Config_And_Verify
    [Arguments]    ${template_folder}    ${mapping}    ${verify_on_source}=True    ${verify_on_sink}=True
    [Documentation]    Request delete config on netty replicate source and verify changes has been made on both source and sink.
    BuiltIn.Should_Not_Be_Empty    ${netty_source_session_alias}    Could not delete config, session to source node is not opened
    TemplatedRequests.Delete_Templated    ${template_folder}    mapping=${mapping}    session=${netty_source_session_alias}
    BuiltIn.Run_Keyword_If    ${verify_on_source}    Verify_Config_Is_Not_Present    template_folder=${template_folder}    mapping=${mapping}    session=${netty_source_session_alias}    until_removal=True
    BuiltIn.Run_Keyword_If    ${verify_on_sink}    Verify_Config_Is_Not_Present    template_folder=${template_folder}    mapping=${mapping}    session=${netty_sink_session_alias}    until_removal=True

Verify_Config_Is_Not_Present
    [Arguments]    ${template_folder}    ${mapping}    ${session}    ${until_removal}=False    ${wait_time}=0s
    [Documentation]    Verifies config is not present on target node datastore by using XML get template. Should get return code 404 or 409.
    ...    until_removal - Retries until config is not present (in case of cofig deletion when config migh be present at begining, but disapears later)
    ...    wait_time - Retries for specific time if config is not present during the whole wait time (in case of config addition when config might appear after some time)
    BuiltIn.Should_Not_Be_Empty    ${session}    Could not verify, session to node is not opened
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${template_folder}    base_name=location    extension=uri    mapping=${mapping}
    BuiltIn.Run_Keyword_If    ${until_removal}    Until_Confg_Is_Deleted    ${session}    ${uri}
    ...    ELSE IF    "${wait_time}" != "0s"    Config_Does_Not_Appear_During_Time   ${session}    ${uri}    ${wait_time}
    ...    ELSE    Utils.No_Content_From_URI    ${session}    ${uri}

Until_Confg_Is_Deleted
    [Arguments]    ${session}    ${uri}
    [Documentation]  Retries until config is not avaibale
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    Utils.No_Content_From_URI    ${session}    ${uri}

Config_Does_Not_Appear_During_Time
    [Arguments]    ${session}    ${uri}    ${wait_time}
    [Documentation]  Retries if config does not appear during the wait time
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${wait_time}    1s    Utils.No_Content_From_URI    ${session}    ${uri}
