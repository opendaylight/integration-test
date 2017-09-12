*** Settings ***
Documentation     Switch connections and cluster are restarted.
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           RequestsLibrary
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../variables/Variables.robot

*** Test Cases ***
Start Mininet Multiple Connections
    [Documentation]    Start mininet linear with connection to all cluster instances.
    ${cluster_index_list}=    ClusterManagement.List All Indices
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Multiple Controllers    ${TOOLS_SYSTEM_IP}    ${cluster_index_list}
    BuiltIn.Set Suite Variable    ${cluster_index_list}
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OVSDB.Check OVS OpenFlow Connections    ${TOOLS_SYSTEM_IP}    3

Check Entity Owner Status And Find Owner and Successor
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${original_owner}    ${original_successor_list}    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    1
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${new_cluster_list}    ${original_successor_list}
    [Teardown]    Report_Failure_Due_To_Bug    9145

Stop Mininet
    [Documentation]    Stop Mininet.
    MininetKeywords.Stop Mininet And Exit

*** Keywords ***
Initialization Phase
    [Documentation]    Create controller session and set variables.
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ClusterManagement.ClusterManagement_Setup

Final Phase
    [Documentation]    Delete all sessions.
    RequestsLibrary.Delete All Sessions
