*** Settings ***
Documentation       Netty replication library. This library can be used to setup and teardown netty replication connections.

Resource            KarafKeywords.robot
Resource            ClusterManagement.robot


*** Variables ***
${DEFAULT_NETTY_SOURCE_NODE_INDEX}      ${1}
@{DEFAULT_NETTY_SINK_NODE_INDEXES}      ${2}


*** Keywords ***
Setup_Netty_Replication
    [Documentation]    Set up netty replication connections betwean source and sinks.
    [Arguments]    ${source_member_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}    ${sink_members_indexes}=${DEFAULT_NETTY_SINK_NODE_INDEXES}
    Open_Source_Connection    ${source_member_index}
    FOR    ${sink_member_index}    IN    @{sink_members_indexes}
        Open_Sink_Connection    ${sink_member_index}    source_member_index=${source_member_index}
    END

Teardown_Netty_Replication
    [Documentation]    Tear down netty replication connections betwean source and sinks.
    [Arguments]    ${source_member_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}    ${sink_members_indexes}=${DEFAULT_NETTY_SINK_NODE_INDEXES}
    Close_Source_Connection    ${source_member_index}
    FOR    ${sink_member_index}    IN    @{sink_members_indexes}
        Close_Sink_Connection    ${sink_member_index}
    END

Open_Source_Connection
    [Documentation]    Open source part of netty replicate connection on specific node.
    [Arguments]    ${source_member_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:edit org.opendaylight.mdsal.replicate.netty.source
    ...    member_index=${source_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:property-set enabled true
    ...    member_index=${source_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:update
    ...    member_index=${source_member_index}

Close_Source_Connection
    [Documentation]    Close source part of netty replicate connection on specific node.
    [Arguments]    ${source_member_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:edit org.opendaylight.mdsal.replicate.netty.source
    ...    member_index=${source_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:property-set enabled false
    ...    member_index=${source_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:update
    ...    member_index=${source_member_index}

Open_Sink_Connection
    [Documentation]    Open sink part of netty replicate connection on specific node.
    [Arguments]    ${sink_member_index}=@{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]    ${source_member_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}
    ${replicate_source_ip}=    ClusterManagement.Resolve_Ip_Address_For_Member    ${source_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:edit org.opendaylight.mdsal.replicate.netty.sink
    ...    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:property-set enabled true
    ...    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:property-set source-host ${replicate_source_ip}
    ...    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${sink_member_index}

Close_Sink_Connection
    [Documentation]    Close sink part of netty replicate connection on specific node.
    [Arguments]    ${sink_member_index}=@{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:edit org.opendaylight.mdsal.replicate.netty.sink
    ...    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background
    ...    config:property-set enabled false
    ...    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${sink_member_index}
