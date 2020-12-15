*** Settings ***
Documentation    Netty replication library. This library can be used to setup and teardown netty replication connections.
Resource         KarafKeywords.robot
Resource         ClusterManagement.robot

*** Variables ***
${DEFAULT_NETTY_SOURCE_NODE_INDEX}    ${1}
@{DEFAULT_NETTY_SINK_NODE_INDEXES}    ${2}

*** Keywords ***
Setup_Netty_Replication
    [Arguments]    ${source_memeber_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}    ${sink_members_indexes}=${DEFAULT_NETTY_SINK_NODE_INDEXES}
    [Documentation]    Set up netty replication connections betwean source and sinks.
    Open_Source_Connection    ${source_memeber_index}
    FOR    ${sink_member_index}    IN   @{sink_members_indexes}
        Open_Sink_Connection    ${sink_member_index}    source_memeber_index=${source_memeber_index}
    END

Teardown_Netty_Replication
    [Arguments]    ${source_memeber_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}   ${sink_members_indexes}=${DEFAULT_NETTY_SINK_NODE_INDEXES}
    [Documentation]    Tear down netty replication connections betwean source and sinks.
    Close_Source_Connection    ${source_memeber_index}
    FOR    ${sink_member_index}    IN   @{sink_members_indexes}
        Close_Sink_Connection    ${sink_member_index}
    END

Open_Source_Connection
    [Arguments]    ${source_memeber_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}
    [Documentation]    Open source part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.source    member_index=${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled true    member_index=${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${source_memeber_index}

Close_Source_Connection
    [Arguments]    ${source_memeber_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}
    [Documentation]    Close source part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.source    member_index=${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled false    member_index=${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${source_memeber_index}

Open_Sink_Connection
    [Arguments]    ${sink_member_index}=@{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]    ${source_memeber_index}=${DEFAULT_NETTY_SOURCE_NODE_INDEX}
    [Documentation]    Open sink part of netty replicate connection on specific node.
    ${replicate_source_ip}=    ClusterManagement.Resolve_Ip_Address_For_Member    ${source_memeber_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.sink    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled true    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set source-host ${replicate_source_ip}    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${sink_member_index}

Close_Sink_Connection
    [Arguments]    ${sink_member_index}=@{DEFAULT_NETTY_SINK_NODE_INDEXES}[0]
    [Documentation]    Close sink part of netty replicate connection on specific node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:edit org.opendaylight.mdsal.replicate.netty.sink    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:property-set enabled false    member_index=${sink_member_index}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    config:update    member_index=${sink_member_index}
