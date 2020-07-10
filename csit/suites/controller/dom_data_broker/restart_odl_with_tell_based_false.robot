*** Settings ***
Documentation     Unset tell-based protocol usage
...           
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...           
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...           
...               Suite stops all odl nodes, outcomment usage of tell-based protocol in
...               config file (means make it false by default) and starts all nodes again.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
Suite Teardown    SSHLibrary.Close_All_Connections
Default Tags      critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/ShardStability.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot

*** Variables ***
${DATASTORE_CFG}    /${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.controller.cluster.datastore.cfg

*** Test Cases ***
Stop_All_Members
    [Documentation]    Stop every odl node.
    ClusterManagement.Stop_Members_From_List_Or_All

Unset_Tell_Based_Protocol_Usage
    [Documentation]    Comment out the flag usage in config file. Also clean most data except data/log/.
    DdbCommons.Change_Use_Tell_Based_Protocol    False    ${DATASTORE_CFG}
    ClusterManagement.Check_Bash_Command_On_List_Or_All    cat ${DATASTORE_CFG}
    ClusterManagement.Clean_Directories_On_List_Or_All    tmp_dir=/tmp

Start_All_And_Sync
    [Documentation]    Start each member and wait for sync.
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    10s    ClusterManagement.Run_Bash_Command_On_List_Or_All    netstat -punta
    ${index_list} =    List_Indices_Or_All
    FOR    ${index}    IN    @{index_list}
        ${output} =    ClusterManagement.Check_Bash_Command_On_Member    command=sudo netstat -punta | grep 2550 | grep LISTEN    member_index=${index}
        ${listening} =    Get Match    ${output}    LISTEN
        BuiltIn.Run Keyword If    '${listening}' == 'None'    ClusterManagement.Check_Bash_Command_On_Member    command=pid=$(grep org.apache.karaf.main.Main | grep -v grep | tr -s ' ' | cut -f2 -d' '); sudo /usr/lib/jvm/java-1.8.0/bin/jstack -l ${pid}    member_index=${index}
    END
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}    verify_restconf=True

*** Keywords ***
Get Match
    [Arguments]    ${text}    ${regexp}    ${index}=0
    [Documentation]    Wrapper around String.Get Regexp Matches to return None if not found or the first match if found.
    @{matches} =    String.Get Regexp Matches    ${text}    ${regexp}
    ${matches_length} =    BuiltIn.Get Length    ${matches}
    BuiltIn.Set Suite Variable    ${OS_MATCH}    None
    BuiltIn.Run Keyword If    ${matches_length} > ${index}    BuiltIn.Set Suite Variable    ${OS_MATCH}    ${matches}[${index}]
    [Return]    ${OS_MATCH}
