*** Settings ***
Documentation     Suite for High Availability testing netconf topology owner under stress.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Suite topology_leader_ha.robot is derived from this suite.
...               Please, keep the logic in the suites as similar as possible.
...
...               This suite uses a Python utility to continuously configure/deconfigure
...               device connections against devices simulated by testtool.
...               The utility sends requests to the member which is Leader for topology config shard.
...
...               To avoid excessive consumption, the utility deconfigures old devices.
...               In stable state, number of config items oscillates between
...               ${CONFIGURED_DEVICES_LIMIT} and 1 + ${CONFIGURED_DEVICES_LIMIT}.
...
...               The only tested HA event so far is reboot of the member
...               which is Owner of netconf topology-manager entity.
...               The results can be different when 
...               This suite assumes the Owner and the Leader are not co-located.
...
...               Number of devices is configurable, wait times are computed from that,
...               as it takes some time to initialize connections.
...               Ideally, the utility should go through half of devices during Owner downtime.
...
...               If there is a period when netconf manager ignores deletions in config datastore,
...               the deviced created previously could "leak", meaning the number of
...               netconf topology items could be higher than 1 + ${CONFIGURED_DEVICES_LIMIT}.
...
...               One check for correctness is the final number of devices in operational netconf topology.
...               TODO: After stopping utility, wait to see mount has succeeded on the devices.
...               Another check is performed on utility output.
...               Performance can be estimated by the total number of requests processed,
...               but this suite does not perform such a computation.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      clustering    netconf    critical
Library           SSHLibrary    timeout=10s
Library           String
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CONFIGURED_DEVICES_LIMIT}    10
${CONFIG_WRITE_TIME_SECONDS}    1
${DEVICE_BASE_NAME}    netconf-test-device
${DEVICE_SET_SIZE}    20
${DEVICE_CHECK_TIMEOUT}    60s
${DEVICE_BOOT_TIMEOUT}    100s
${CLUSTER_RECOVERY_TIMEOUT}    120s

*** Test Cases ***
Locate_Managers
    [Documentation]    Detect location of Leader and Owner and store related data into suite variables.
    ...    This cannot be part of Suite Setup, as Utils.Get_Index_From_List_Of_Dictionaries calls BuiltIn.Set_Test_Variable.
    ${topology_config_leader_index}    ${candidates} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=topology    shard_type=config
    BuiltIn.Set_Suite_Variable    \${topology_config_leader_index}
    ${topology_config_leader_ip} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${topology_config_leader_index}
    BuiltIn.Set_Suite_Variable    \${topology_config_leader_ip}
    ${topology_config_leader_http_session} =    Resolve_Http_Session_For_Member    ${topology_config_leader_index}
    BuiltIn.Set_Suite_Variable    \${topology_config_leader_http_session}
    ${netconf_manager_owner_index}    ${candidates} =    ClusterManagement.Get_Owner_And_Candidates_For_Type_And_Id    type=topology-netconf    id=/general-entity:entity[general-entity:name='topology-manager']    member_index=1
    BuiltIn.Set_Suite_Variable    \${netconf_manager_owner_index}
    ${netconf_manager_owner_ip} =    ClusterManagement.Resolve_Ip_Address_For_Member    ${netconf_manager_owner_index}
    BuiltIn.Set_Suite_Variable    \${netconf_manager_owner_ip}
    ${netconf_manager_owner_http_session} =    Resolve_Http_Session_For_Member    ${netconf_manager_owner_index}
    BuiltIn.Set_Suite_Variable    \${netconf_manager_owner_http_session}

Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    NetconfKeywords.Install_And_Start_Testtool    device-count=${DEVICE_SET_SIZE}    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Start_Configurer
    [Documentation]    Launch Python utility and wait for devices to be present.
    # TODO: Should things like restconf port/user/password be set from Variables?
    ${command} =    python configurer.py --odladdress ${topology_config_leader_ip} --deviceaddress ${TOOLS_SYSTEM_IP} --devices ${DEVICE_SET_SIZE} --disconndelay ${CONFIGURED_DEVICES_LIMIT} --basename ${DEVICE_BASE_NAME}
    SSHLibrary.Write    ${command}
    # Session is kept active.

Wait_For_Config_Items
    [Documentation]    Make sure configurer is in phase when old devices are being deconfigured; or fail on timeout.
    ${timeout} =    Get_Typical_Time
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    1s    Check_Config_Items

Reboot_Manager_Owner
    [Documentation]    Kill and restart member where netconf topology manager was, including removal of persisted data.
    ...    After cluster sync, wait additional time to ensure manager processes requests with the rebooted member fully rejoined.
    ClusterManagement.Kill_Single_Member    ${netconf_manager_owner_index}
    # TODO: Introduce ClusterManagement.Clean_Journals_And_Snapshots_On_Single_Member
    ${owner_list} =    BuiltIn.Create_List    ${netconf_manager_owner_index}
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All    ${owner_list}
    ClusterManagement.Start_Single_Member    ${netconf_manager_owner_index}
    # FIXME: Replace sleep with WUKS when it becomes clear what to wait for.
    ${sleep_time} =    Get_Typical_Time    coefficient=3.0
    BuiltIn.Sleep    ${sleep_time}

Stop_Configurer
    [Documentation]    Write ctrl+c, read the output and match the output.
    Utils.Write_Bare_Ctrl_C
    ${output} =    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    ${list_any_matches} =    String.Get_Regexp_Matches    ${output}    delete|put
    ${number_any_matches} =    BuiltIn.Get_Length    ${list_any_matches}
    BuiltIn.Should_Be_Equal    ${2}    ${number_any_matches}    Unexpected status seen: ${output}
    ${list_strict_matches} =    String.Get_Regexp_Matches    ${output}    delete 200|put 201
    ${number_strict_matches} =    BuiltIn.Get_Length    ${list_strict_matches}
    BuiltIn.Should_Be_Equal    ${2}    ${number_strict_matches}    Expected status not seen: ${output}

Check_For_Connector_Leak
    [Documentation]    Check that number of items in operational netconf topology is not higher than expected.
    # FIXME: Are separate keywords necessary?
    Check_Operational_Items_Upper_Bound

*** Keywords ***
Setup_Everything
    [Documentation]    Initialize libraries and set suite variables..
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    NetconfKeywords.Setup_Netconf_Keywords    create_session_for_templated_requests=False
    SSHKeywords.Open_Connection_To_Tools_System
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Counter
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/netconf_tools/configurer.py
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/AuthStandalone.py

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    NetconfKeywords.Stop_Testtool
    RequestsLibrary.Delete_All_Sessions

Count_Substring_Occurence
    [Arguments]    ${substring}    ${main_string}
    [Documentation]    Apply the length_of_split method for counting how many times ${substring} occures within ${main_string}.
    ...    The method is reliable only if triple-double quotes are not present in either argument.
    ...    TODO: Move this into appropriate Resource.
    BuiltIn.Run_Keyword_And_Return    Builtin.Evaluate    len("""${main_string}""".split("""${substring}""")) - 1

Get_Config_Device_Count
    [Documentation]    Count number of items in config netconf topology matching ${DEVICE_BASE_NAME}
    ${item_data} =    TemplatedRequests.Get_As_Json_From_Uri    ${CONFIG_API}/network-topology:network-topology/topology/topology-netconf    session=${topology_config_leader_http_session}
    BuiltIn.Run_Keyword_And_Return    Count_Substring_Occurence    substring=${DEVICE_BASE_NAME}    main_string=${item_data}

Get_Operational_Device_Count
    [Documentation]    Count number of items in operational netconf topology matching ${DEVICE_BASE_NAME}
    ${item_data} =    TemplatedRequests.Get_As_Json_From_Uri    ${OPERATIONAL_API}/network-topology:network-topology/topology/topology-netconf    session=${topology_config_leader_http_session}
    BuiltIn.Run_Keyword_And_Return    Count_Substring_Occurence    substring=${DEVICE_BASE_NAME}    main_string=${item_data}

Check_Config_Items_Lower_Bound
    [Documentation]    Count items matching ${DEVICE_BASE_NAME}, fail if less than ${CONFIGURED_DEVICES_LIMIT}
    ${device_count} =    Get_Config_Device_Count
    BuiltIn.Run_Keyword_If    ${device_count} < ${CONFIGURED_DEVICES_LIMIT}    BuiltIn.Fail    Found ${device_count} config items, should be at least ${CONFIGURED_DEVICES_LIMIT}

Check_Oprational_Items_Upper_Bound
    [Documentation]    Count items matching ${DEVICE_BASE_NAME}, fail if more than 1 + ${CONFIGURED_DEVICES_LIMIT}
    ${device_count} =    Get_Operational_Device_Count
    BuiltIn.Run_Keyword_If    ${device_count} > 1 + ${CONFIGURED_DEVICES_LIMIT}    BuiltIn.Fail    Found ${device_count} config items, should be at most 1 + ${CONFIGURED_DEVICES_LIMIT}

Get_Typical_Time
    [Arguments]    ${coefficient}=1.0
    [Documentation]    Return number of seconds typical for given scale variables.
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Evaluate    ${coefficient} * ${CONFIG_WRITE_TIME_SECONDS} * ${CONFIGURED_DEVICES_LIMIT}
