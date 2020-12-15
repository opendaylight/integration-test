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

*** Variables ***
${DEFAULT_SOURCE_INDEX}    ${1}
${DEFAULT_SINK_INDEX}    ${2}
${NETCONF_DEV_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-device
${DEVICE_IP}      120.20.10.1
${DEVICE_PORT}    8842
${DEVICE_USER}    admin
${DEVICE_PASSWORD}    admin

*** Test Cases ***
Single_Config_Change_Replication
    [Documentation]    Test if single configuration change on source node is replicated on sink node.
    ${ip_address} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${DEFAULT_SOURCE_INDEX}
    Setup_Netty_Replication
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-1    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    BuiltIn.Log_Variables
    ${connections} =    SSHLibrary.Get_Connections
    BuiltIn.Log    ${connections}
    TemplatedRequests.Put_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${source_odl_session_alias}
    ${result} =    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    verify=True    session=${source_odl_session_alias}
    ${result} =    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    verify=True    session=${sink_odl_session_alias}

Sink_Catch_Up_After_Opening_Connection
    [Documentation]    Sink should catch up to changes made on source node before connecting,
    Open_Source_Connection
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-2    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    BuiltIn.Log_Variables
    ${connections} =    SSHLibrary.Get_Connections
    BuiltIn.Log    ${connections}
    TemplatedRequests.Put_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${source_odl_session_alias}
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    verify=True    session=${source_odl_session_alias}
    Open_Sink_Connection
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    verify=True    session=${sink_odl_session_alias}

Reconnect_After_Lost_Connection
    [Documentation]    Test if sink sucessfuly reconnects after lost connection and if changes made during lost connection are resent to reconnected sink.
    Setup_Netty_Replication
    ClusterManagement.Isolate_Member_From_List_Or_All    ${DEFAULT_SOURCE_INDEX}    port=9999
    &{mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=new-netconf-device-3    DEVICE_IP=${DEVICE_IP}    DEVICE_PORT=${DEVICE_PORT}    DEVICE_USER=${DEVICE_USER}    DEVICE_PASSWORD=${DEVICE_PASSWORD}
    BuiltIn.Log_Variables
    ${connections} =    SSHLibrary.Get_Connections
    BuiltIn.Log    ${connections}
    TemplatedRequests.Put_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${source_odl_session_alias}
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    verify=True    session=${source_odl_session_alias}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${DEFAULT_SOURCE_INDEX}    port=9999
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    verify=True    session=${sink_odl_session_alias}

*** Keywords ***
Setup_suite
    [Documentation]    Open ssh karaf connections to each ODL and setup netty replication connection betwean ODL 1 (source) and ODL 2 (sink).
    KarafKeywords.Setup_Karaf_Keywords
    BuiltIn.Log_Variables

Teardown_Suite
    [Documentation]    Close all opended connections.
    #RequestsLibrary.Delete_All_Sessions
    #SSHLibrary.Close_All_Connections
    BuiltIn.Log_Variables

Setup_Test
    [Documentation]    Clear all config stored in datastore.
    #ClusterManagement.Clean_Journals_Data_And_Snapshots_On_List_Or_All
    #SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Log_Variables

Teardown_Test
    [Documentation]    Show linked bugs in case of failure.
    Teardown_Netty_Replication
    #SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Setup_Netty_Replication
    [Arguments]    ${source_memeber_index}=${DEFAULT_SOURCE_INDEX}    ${sink_member_index}=${DEFAULT_SINK_INDEX}
    [Documentation]    Set up connection betwean source and sink for datastore replication.
    Open_Source_Connection    ${source_memeber_index}
    open_sink_connection    ${sink_member_index}

Teardown_Netty_Replication
    [Arguments]    ${source_memeber_index}=${DEFAULT_SOURCE_INDEX}    ${sink_member_index}=${DEFAULT_SINK_INDEX}
    [Documentation]    Tear down connection betwean source and sink for datastore replication.
    Close_Source_Connection    ${source_memeber_index}
    Close_sink_connection    ${sink_member_index}

Open_Source_Connection
    [Arguments]    ${cluster_member_index}=${DEFAULT_SINK_INDEX}
    [Documentation]    Open sink part of netty replicate connection on specific node. Http session to this node is stored in sorce_odl_session_alias suite variable.
    BuiltIn.Log_Variables
    ${connections} =    SSHLibrary.Get_Connections
    BuiltIn.Log    ${connections}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.source    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled true    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${cluster_member_index}
    ${source_odl_session_alias} =    Resolve_Http_Session_For_Member    member_index=${cluster_member_index}
    BuiltIn.Set_Suite_Variable    ${source_odl_session_alias}

Close_Source_Connection
    [Arguments]    ${cluster_member_index}=${DEFAULT_SINK_INDEX}
    [Documentation]    Close sink part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.source    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled false    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${cluster_member_index}
    ${source_odl_session_alias} =    Set Variable    ${EMPTY}

Open_Sink_Connection
    [Arguments]    ${cluster_member_index}=${DEFAULT_SOURCE_INDEX}
    [Documentation]    Open source part of netty replicate connection on specific node. Http session to this node is stored in sink_odl_session_alias suite variable.
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
    [Arguments]    ${cluster_member_index}=${DEFAULT_SOURCE_INDEX}
    [Documentation]    Close source part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.sink    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled false    member_index=${cluster_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${cluster_member_index}
    ${sink_odl_session_alias} =    Set Variable    ${EMPTY}
