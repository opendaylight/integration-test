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
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/ShardStability.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../variables/Variables.robot

*** Variables ***
${DATASTORE_CFG}    /${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.controller.cluster.datastore.cfg

*** Test Cases ***
Stop_All_Members
    [Documentation]    Stop every odl node. If fail then generate thread dump.
    ${index_list} =    List_Indices_Or_All
    FOR    ${index}    IN    @{index_list}
        Run Keyword If Test Failed    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    dev:dump-create    ${index}
    END
    ClusterManagement.Stop_Members_From_List_Or_All    timeout=60s
    [Teardown]    Run Keyword If Test Failed    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    dev:dump-create

Unset_Tell_Based_Protocol_Usage
    [Documentation]    Comment out the flag usage in config file. Also clean most data except data/log/.
    DdbCommons.Change_Use_Tell_Based_Protocol    False    ${DATASTORE_CFG}
    ClusterManagement.Check_Bash_Command_On_List_Or_All    cat ${DATASTORE_CFG}
    ClusterManagement.Clean_Directories_On_List_Or_All    tmp_dir=/tmp

Start_All_And_Sync
    [Documentation]    Start each member and wait for sync.
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    5s    ClusterManagement.Run_Bash_Command_On_List_Or_All    netstat -punta
    ${index_list} =    List_Indices_Or_All
    FOR    ${index}    IN    @{index_list}
        ${output} =    ClusterManagement.Check_Bash_Command_On_Member    command=sudo netstat -punta | grep 2550 | grep LISTEN    member_index=${index}
        ${listening} =    Get Match    ${output}    LISTEN
        BuiltIn.Run Keyword If    '${listening}' != 'None'    ClusterManagement.Check_Bash_Command_On_Member    command=sudo /usr/lib/jvm/java-1.8.0/bin/jstack -l grep org.apache.karaf.main.Main    member_index=${index}
    END
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    5s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}    verify_restconf=True

*** Keywords ***
Get Match
    [Arguments]    ${text}    ${regexp}    ${index}=0
    [Documentation]    Wrapper around String.Get Regexp Matches to return None if not found or the first match if found.
    @{matches} =    String.Get Regexp Matches    ${text}    ${regexp}
    ${matches_length} =    BuiltIn.Get Length    ${matches}
    BuiltIn.Set Suite Variable    ${OS_MATCH}    None
    BuiltIn.Run Keyword If    ${matches_length} > ${index}    BuiltIn.Set Suite Variable    ${OS_MATCH}    ${matches}[${index}]
    [Return]    ${OS_MATCH}

Generate Thread Dump
    [Arguments]    ${system}    ${regex_string_to_match_on}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Find out process ID based on regex and generate its thread dump.
    ${pid} =    Utils.Get Process ID Based On Regex On Remote System    ${system}    ${regex_string_to_match_on}    ${user}    ${password}    ${prompt}    ${prompt_timeout}
    ${output} =    Utils.Run Command On Remote System    ${system}    cat /etc/passwd    user=${user}    password=${password}    prompt=${prompt}    prompt_timeout=${prompt_timeout}
    Log    ${output}
    ${output} =    Utils.Run Command On Remote System And Log    ${system}    whoami    user=${user}    password=${password}    prompt=${prompt}    prompt_timeout=${prompt_timeout}
    ${output} =    Utils.Run Command On Remote System    ${system}    ps -o user= -p ${pid}    user=${user}    password=${password}    prompt=${prompt}    prompt_timeout=${prompt_timeout}
    Log    Owner of process is "${output}"
    Utils.Run Command On Remote System And Log    ${system}    sudo -u jenkins /usr/lib/jvm/java-11-openjdk/bin/jstack -l ${pid}    user=${user}    password=${password}    prompt=${prompt}    prompt_timeout=${prompt_timeout}
