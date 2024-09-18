*** Settings ***
Documentation       Suite for High Availability testing config topology shard leader under stress.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 This is close analogue of topology_owner_ha.robot, see Documentation there.
...                 The difference is that here the requests are sent towards entity-ownership shard leader,
...                 and the topology shard leader node is rebooted.
...
...                 No real clustering Bugs are expected to be discovered by this suite,
...                 except maybe some Restconf ones.
...                 But as this suite was easy to create, it may as well be run.

Library             OperatingSystem
Library             SSHLibrary    timeout=10s
Library             String    # for Get_Regexp_Matches
Resource            ${CURDIR}/../../../libraries/ClusterAdmin.robot
Resource            ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource            ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource            ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource            ${CURDIR}/../../../libraries/RemoteBash.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource            ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource            ${CURDIR}/../../../libraries/Utils.robot
Variables           ${CURDIR}/../../../variables/Variables.py

Suite Setup         Setup_Everything
Suite Teardown      Teardown_Everything
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown       ${DEFAULT_TEARDOWN_KEYWORD}

Default Tags        @{tags_critical}


*** Variables ***
${CONFIGURED_DEVICES_LIMIT}     20
${CONNECTION_SLEEP}             1.2
${DEFAULT_TEARDOWN_KEYWORD}     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
${DEVICE_BASE_NAME}             netconf-test-device
${DEVICE_SET_SIZE}              30
@{TAGS_CRITICAL}                critical    @{TAGS_NONCRITICAL}
@{TAGS_NONCRITICAL}             clustering    netconf


*** Test Cases ***
Locate_Managers
    [Documentation]    Detect location of topology(config) and entity-ownership(operational) leaders and store related data into suite variables.
    ...    This cannot be part of Suite Setup, as Utils.Get_Index_From_List_Of_Dictionaries calls BuiltIn.Set_Test_Variable.
    ...    WUKS are used, as location failures are probably due to booting process, not bugs.
    ${topology_config_leader_index}    ${candidates} =    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    2s
    ...    ClusterManagement.Get_Leader_And_Followers_For_Shard
    ...    shard_name=topology
    ...    shard_type=config
    BuiltIn.Set_Suite_Variable    \${topology_config_leader_index}
    ${topology_config_leader_ip} =    ClusterManagement.Resolve_Ip_Address_For_Member
    ...    ${topology_config_leader_index}
    BuiltIn.Set_Suite_Variable    \${topology_config_leader_ip}
    ${topology_config_leader_http_session} =    Resolve_Http_Session_For_Member    ${topology_config_leader_index}
    BuiltIn.Set_Suite_Variable    \${topology_config_leader_http_session}
    ${entity_ownership_leader_index} =    Change_Entity_Ownership_Leader_If_Needed    ${topology_config_leader_index}
    BuiltIn.Set_Suite_Variable    \${entity_ownership_leader_index}
    ${entity_ownership_leader_ip} =    ClusterManagement.Resolve_Ip_Address_For_Member
    ...    ${entity_ownership_leader_index}
    BuiltIn.Set_Suite_Variable    \${entity_ownership_leader_ip}
    ${entity_ownership_leader_http_session} =    Resolve_Http_Session_For_Member    ${entity_ownership_leader_index}
    BuiltIn.Set_Suite_Variable    \${entity_ownership_leader_http_session}

Start_Testtool
    [Documentation]    Deploy and start test tool on its separate SSH session.
    SSHLibrary.Switch_Connection    ${testtool_connection_index}
    NetconfKeywords.Install_And_Start_Testtool
    ...    device-count=${DEVICE_SET_SIZE}
    ...    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas
    # TODO: Introduce NetconfKeywords.Safe_Install_And_Start_Testtool to avoid teardown maniputation.
    [Teardown]    BuiltIn.Run_Keywords    SSHLibrary.Switch_Connection    ${configurer_connection_index}
    ...    AND    ${DEFAULT_TEARDOWN_KEYWORD}

Start_Configurer
    [Documentation]    Launch Python utility (while copying output to log file) and verify it does not stop by itself.
    ${log_filename} =    Utils.Get_Log_File_Name    configurer
    BuiltIn.Set_Suite_Variable    \${log_filename}
    ${use_node_encapsulation} =    CompareStream.Set_Variable_If_At_Least_Scandium    True    False
    # TODO: Should things like restconf port/user/password be set from Variables?
    ${command} =    BuiltIn.Set_Variable
    ...    python configurer.py --odladdress ${entity_ownership_leader_ip} --deviceaddress ${TOOLS_SYSTEM_IP} --devices ${DEVICE_SET_SIZE} --disconndelay ${CONFIGURED_DEVICES_LIMIT} --basename ${DEVICE_BASE_NAME} --connsleep ${CONNECTION_SLEEP} --encapsulation ${use_node_encapsulation}  &> "${log_filename}"
    SSHLibrary.Write    ${command}
    ${status}    ${text} =    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}
    IF    "${status}" != "FAIL"    BuiltIn.Fail    Prompt happened, see Log.
    # Session is kept active.

Wait_For_Config_Items
    [Documentation]    Make sure configurer is in phase when old devices are being deconfigured; or fail on timeout.
    ${timeout} =    Get_Typical_Time
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    1s    Check_Config_Items_Lower_Bound

Reboot_Topology_Leader
    [Documentation]    Kill and restart member where topology shard leader was, including removal of persisted data.
    ...    After cluster sync, sleep additional time to ensure manager processes requests with the rebooted member fully rejoined.
    [Tags]    @{tags_noncritical}    # To avoid long WUKS list expanded in log.html
    ClusterManagement.Kill_Single_Member    ${topology_config_leader_index}
    ${owner_list} =    BuiltIn.Create_List    ${topology_config_leader_index}
    ClusterManagement.Start_Single_Member    ${topology_config_leader_index}
    BuiltIn.Comment    FIXME: Replace sleep with WUKS when it becomes clear what to wait for.
    ${sleep_time} =    Get_Typical_Time    coefficient=3.0
    BuiltIn.Sleep    ${sleep_time}

Stop_Configurer
    [Documentation]    Write ctrl+c, download the log, read its contents and match expected patterns.
    RemoteBash.Write_Bare_Ctrl_C
    ${output} =    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    SSHLibrary.Get_File    ${log_filename}
    ${output} =    OperatingSystem.Get_File    ${log_filename}
    ${list_any_matches} =    String.Get_Regexp_Matches    ${output}    delete|put
    ${number_any_matches} =    BuiltIn.Get_Length    ${list_any_matches}
    BuiltIn.Should_Be_Equal    ${2}    ${number_any_matches}    Unexpected status seen: ${output}
    ${list_strict_matches} =    String.Get_Regexp_Matches    ${output}    delete:200|put:201
    ${number_strict_matches} =    BuiltIn.Get_Length    ${list_strict_matches}
    BuiltIn.Should_Be_Equal    ${2}    ${number_strict_matches}    Expected status not seen: ${output}

Check_For_Connector_Leak
    [Documentation]    Check that number of items in operational netconf topology is not higher than expected.
    # FIXME: Are separate keywords necessary?
    Check_Operational_Items_Upper_Bound


*** Keywords ***
Setup_Everything
    [Documentation]    Initialize libraries and set suite variables..
    ClusterManagement.ClusterManagement_Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords    create_session_for_templated_requests=False
    ${testtool_connection_index} =    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    \${testtool_connection_index}
    ${configurer_connection_index} =    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    \${configurer_connection_index}
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Counter
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/netconf_tools/configurer.py
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/AuthStandalone.py

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    SSHLibrary.Switch_Connection    ${testtool_connection_index}
    NetconfKeywords.Stop_Testtool
    RequestsLibrary.Delete_All_Sessions

Count_Substring_Occurence
    [Documentation]    Apply the length_of_split method for counting how many times ${substring} occures within ${main_string}.
    ...    The method is reliable only if triple-double quotes are not present in either argument.
    [Arguments]    ${substring}    ${main_string}
    BuiltIn.Comment    TODO: Migrate this keyword into an appropriate Resource.
    BuiltIn.Run_Keyword_And_Return    Builtin.Evaluate    len("""${main_string}""".split("""${substring}""")) - 1

Get_Config_Device_Count
    [Documentation]    Count number of items in config netconf topology matching ${DEVICE_BASE_NAME}
    ${item_data} =    TemplatedRequests.Get_As_Json_From_Uri
    ...    ${REST_API}/network-topology:network-topology/topology=topology-netconf
    ...    session=${entity_ownership_leader_http_session}
    BuiltIn.Run_Keyword_And_Return
    ...    Count_Substring_Occurence
    ...    substring=${DEVICE_BASE_NAME}
    ...    main_string=${item_data}

Get_Operational_Device_Count
    [Documentation]    Count number of items in operational netconf topology matching ${DEVICE_BASE_NAME}
    ${item_data} =    TemplatedRequests.Get_As_Json_From_Uri
    ...    ${REST_API}/network-topology:network-topology/topology=topology-netconf?content=nonconfig
    ...    session=${entity_ownership_leader_http_session}
    BuiltIn.Run_Keyword_And_Return
    ...    Count_Substring_Occurence
    ...    substring=${DEVICE_BASE_NAME}
    ...    main_string=${item_data}

Check_Config_Items_Lower_Bound
    [Documentation]    Count items matching ${DEVICE_BASE_NAME}, fail if less than ${CONFIGURED_DEVICES_LIMIT}
    ${device_count} =    Get_Config_Device_Count
    IF    ${device_count} < ${CONFIGURED_DEVICES_LIMIT}
        BuiltIn.Fail    Found ${device_count} config items, should be at least ${CONFIGURED_DEVICES_LIMIT}
    END

Check_Operational_Items_Upper_Bound
    [Documentation]    Count items matching ${DEVICE_BASE_NAME}, fail if more than 1 + ${CONFIGURED_DEVICES_LIMIT}
    ${device_count} =    Get_Operational_Device_Count
    IF    ${device_count} > 1 + ${CONFIGURED_DEVICES_LIMIT}
        BuiltIn.Fail    Found ${device_count} config items, should be at most 1 + ${CONFIGURED_DEVICES_LIMIT}
    END

Get_Typical_Time
    [Documentation]    Return number of seconds typical for given scale variables.
    [Arguments]    ${coefficient}=1.0
    BuiltIn.Run_Keyword_And_Return
    ...    BuiltIn.Evaluate
    ...    ${coefficient} * ${CONNECTION_SLEEP} * ${CONFIGURED_DEVICES_LIMIT}

Change_Entity_Ownership_Leader_If_Needed
    [Documentation]    Move entity-ownership (operational) shard leader if it is on the same node as topology (config) shard leader.
    [Arguments]    ${topology_config_leader_idx}
    ${entity_ownership_leader_index_old}    ${candidates} =    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    2s
    ...    ClusterManagement.Get_Leader_And_Followers_For_Shard
    ...    shard_name=entity-ownership
    ...    shard_type=operational
    IF    ${topology_config_leader_idx} != ${entity_ownership_leader_index_old}
        RETURN    ${entity_ownership_leader_index_old}
    END
    ${idx} =    Collections.Get_From_List    ${candidates}    0
    ClusterAdmin.Make_Leader_Local    ${idx}    entity-ownership    operational
    ${entity_ownership_leader_index}    ${candidates} =    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    60s
    ...    3s
    ...    ClusterManagement.Verify_Shard_Leader_Elected
    ...    entity-ownership
    ...    operational
    ...    ${True}
    ...    ${entity_ownership_leader_index_old}
    ...    verify_restconf=False
    RETURN    ${entity_ownership_leader_index}
