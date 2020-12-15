*** Settings ***
Documentation     Test suite for testing MD-SAL netty replication functionality
Suite Setup       Setup_Suite
Test Setup        Setup_Test
Test Teardown     Teardown_Test
Suite Teardown    Teardown _Suite
Default Tags      3node    critical
Library           SSHLibrary
Library           String
Library           XML
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
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
    ${ip_address} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${DEFAULT_SOURCE_NODE_INDEX}
    Setup_Netty_Replication
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-1    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-1    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${1212}    DEVICE_USER=newer    DEVICE_PASSWORD=random
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}

Replicte_Config_Deletion
    [Documentation]    Updating existing configuration on source node is replicated on sink node.
    ${ip_address} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${DEFAULT_SOURCE_NODE_INDEX}
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

Sink_Catch_Up_After_Opening_Connection
    [Documentation]    Sink should catch up to changes made on source node before connecting.
    Open_Source_Connection
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-2    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}    verify_on_source=True    verify_on_sink=False
    Open_Sink_Connection
    Verify_Config_Is_Present    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${sink_odl_session_alias}

Reconnect_After_Lost_Connection
    [Documentation]    Test if sink sucessfuly reconnects after lost connection and if changes made during lost connection are resent on reconnected sink's datastore.
    Setup_Netty_Replication
    ClusterManagement.Isolate_Member_From_List_Or_All    ${DEFAULT_SOURCE_NODE_INDEX}    port=9999
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-3    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping}    verify_on_source=True    verify_on_sink=False
    Verify_Config_Is_Not_Present    ${NETCONF_DEV_FOLDER}    ${mapping}    session=${sink_odl_session_alias}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${DEFAULT_SOURCE_NODE_INDEX}    port=9999
    Verify_Config_Is_Present    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${sink_odl_session_alias}

Change_Replication_Source
    [Documentation]    After changing replication source ODL to another ODL sink should reflect datastore from newer source forgeting changes from the old datastore.
    Setup_Netty_Replication
    &{mapping_older} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-3    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping_older}
    Teardown_Netty_Replication
    Setup_Netty_Replication    source_memeber_index=${ADDITIONAL_SOURCE_NODE_INDEX}    sink_member_index=${DEFAULT_SINK_NODE_INDEX}
    &{mapping_newer} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-4    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=1212    DEVICE_USER=newer_source    DEVICE_PASSWORD=newer_source
    Put_Config_And_Verify    ${NETCONF_DEV_FOLDER}    ${mapping_newer}
    Verify_Config_Is_Not_Present    ${NETCONF_DEV_FOLDER}    ${mapping_older}    ${sink_odl_session_alias}
    TemplatedRequests.Get_From_Uri    restconf/config/network-topology:network-topology/topology/


*** Keywords ***
Setup_suite
    [Documentation]    Open ssh karaf connections to each ODL and setup netty replication connection betwean ODL 1 (source) and ODL 2 (sink).
    #KarafKeywords.Setup_Karaf_Keywords
    BuiltIn.Log_Variables

Teardown_Suite
    [Documentation]    Close all opended connections.
    #RequestsLibrary.Delete_All_Sessions
    #SSHLibrary.Close_All_Connections
    BuiltIn.Log_Variables

Setup_Test
    [Documentation]    Clear all config stored in datastore.
    ClusterManagement.Clean_Journals_Data_And_Snapshots_On_List_Or_All
    KarafKeywords.Setup_Karaf_Keywords
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    #BuiltIn.Log_Variables

Teardown_Test
    [Documentation]    Show linked bugs in case of failure.
    Teardown_Netty_Replication
    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Setup_Netty_Replication
    [Arguments]    ${source_memeber_index}=${DEFAULT_SOURCE_NODE_INDEX}    ${sink_member_index}=${DEFAULT_SINK_NODE_INDEX}
    [Documentation]    Set up connection betwean source and sink for datastore replication.
    Open_Source_Connection    ${source_memeber_index}
    open_sink_connection    ${sink_member_index}

Teardown_Netty_Replication
    [Arguments]    ${source_memeber_index}=${DEFAULT_SOURCE_NODE_INDEX}    ${sink_member_index}=${DEFAULT_SINK_NODE_INDEX}
    [Documentation]    Tear down connection betwean source and sink for datastore replication.
    Close_Source_Connection    ${source_memeber_index}
    Close_sink_connection    ${sink_member_index}

Open_Source_Connection
    [Arguments]    ${cluster_member_index}=${DEFAULT_SINK_NODE_INDEX}
    [Documentation]    Open sink part of netty replicate connection on specific node. Http session to this node is stored in sorce_odl_session_alias suite variable avaible for usage in other keywords.
    BuiltIn.Log_Variables
    ${connections} =    SSHLibrary.Get_Connections
    BuiltIn.Log    ${connections}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.source    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled true    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${cluster_member_index}
    ${source_odl_session_alias} =    Resolve_Http_Session_For_Member    member_index=${cluster_member_index}
    BuiltIn.Set_Suite_Variable    ${source_odl_session_alias}

Close_Source_Connection
    [Arguments]    ${cluster_member_index}=${DEFAULT_SINK_NODE_INDEX}
    [Documentation]    Close sink part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.source    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled false    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${cluster_member_index}
    ${source_odl_session_alias} =    Set Variable    ${EMPTY}

Open_Sink_Connection
    [Arguments]    ${cluster_member_index}=${DEFAULT_SOURCE_NODE_INDEX}
    [Documentation]    Open source part of netty replicate connection on specific node. Http session to this node is stored in sink_odl_session_alias suite variable avaible for usage in other keywords.
    BuiltIn.Log_Variables
    ${connections} =    SSHLibrary.Get_Connections
    BuiltIn.Log    ${connections}
    ${replicate_source_ip}=    ClusterManagement.Resolve_Ip_Address_For_Member    ${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.sink    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled true    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set source-host ${replicate_source_ip}    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${cluster_member_index}
    ${sink_odl_session_alias} =    Resolve_Http_Session_For_Member    member_index=${cluster_member_index}
    BuiltIn.Set_Suite_Variable    ${sink_odl_session_alias}

Close_Sink_Connection
    [Arguments]    ${cluster_member_index}=${DEFAULT_SOURCE_NODE_INDEX}
    [Documentation]    Close source part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.sink    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled false    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${cluster_member_index}
    ${sink_odl_session_alias} =    Set Variable    ${EMPTY}

Put_Config_And_Verify
    [Arguments]    ${template_folder}    ${mapping}    ${verify_on_source}=True    ${verify_on_sink}=True
    [Documentation]    Request put config  on netty replicate source and verify changes has been made on both source and sink.
    BuiltIn.Run_Keyword_If    ${source_odl_session_alias} == ${EMPTY}    BuiltIn.Fail    Could not put config, session to source node is not opened.
    TemplatedRequests.Put_As_Json_Templated    ${template_folder}    mapping=${mapping}    session=${source_odl_session_alias}
    BuiltIn.Run_Keyword_If    ${verify_on_source}    Verify_Config_Is_Present    template_folder=${template_folder}     mapping=${mapping}    session=${source_odl_session_alias}
    BuiltIn.Run_Keyword_If    ${verify_on_sink}    Verify_Config_Is_Present    template_folder=${template_folder}     mapping=${mapping}    session=${sink_odl_session_alias}

Verify_Config_Is_Present
    [Arguments]    ${template_folder}    ${mapping}    ${session}
    [Documentation]    Verifies config is present on target node datastore by using XML get template.
    BuiltIn.Run_Keyword_If    ${session} == ${EMPTY}    BuiltIn.Fail    Could not verify, session to node is not opened
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Json_Templated    ${template_folder}     mapping=${mapping}    verify=True    session=${session}

Delete_Config_And_Verify
    [Arguments]    ${template_folder}    ${mapping}    ${verify_on_source}=True    ${verify_on_sink}=True
    [Documentation]    Request delete config  on netty replicate source and verify changes has been made on both source and sink.
    BuiltIn.Run_Keyword_If    ${source_odl_session_alias} == ${EMPTY}    BuiltIn.Fail    Could not delete config, session to source node is not opened
    TemplatedRequests.Delete_Templated    ${template_folder}    mapping=${mapping}    session=${source_odl_session_alias}
    BuiltIn.Run_Keyword_If    ${verify_on_source}    Verify_Config_Is_Not_Present    template_folder=${template_folder}     mapping=${mapping}    session=${source_odl_session_alias}
    BuiltIn.Run_Keyword_If    ${verify_on_sink}    Verify_Config_Is_Not_Present    template_folder=${template_folder}     mapping=${mapping}    session=${sink_odl_session_alias}

Verify_Config_Is_Not_Present
    [Arguments]    ${template_folder}    ${mapping}    ${session}
    [Documentation]    Verifies config is not present on target node datastore by using XML get template. Should get return code 404 or 409.
    BuiltIn.Run_Keyword_If    ${session} == ${EMPTY}    BuiltIn.Fail    Could not verify, session to node is not opened
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${template_folder}     base_name=location    extension=uri    mapping=${mapping}
    Utils.No_Content_From_URI    ${session}    ${uri}
