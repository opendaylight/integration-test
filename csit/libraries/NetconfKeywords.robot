*** Settings ***
Documentation     Perform complex operations on netconf.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This library encapsulates a bunch of somewhat complex and commonly used
...               netconf operations into reusable keywords to make writing netconf
...               test suites easier.
Library           Collections
Library           DateTime
Library           RequestsLibrary
Library           SSHLibrary
Resource          NexusKeywords.robot
Resource          SSHKeywords.robot
Resource          TemplatedRequests.robot
Resource          Utils.robot

*** Variables ***
${TESTTOOL_DEFAULT_JAVA_OPTIONS}    -Xmx1G -XX:MaxPermSize=256M -Dorg.apache.sshd.registerBouncyCastle=false
${DIRECTORY_WITH_DEVICE_TEMPLATES}    ${CURDIR}/../variables/netconf/device
${FIRST_TESTTOOL_PORT}    17830
${BASE_NETCONF_DEVICE_PORT}    17830
${DEVICE_NAME_BASE}    netconf-scaling-device
${TESTTOOL_BOOT_TIMEOUT}    60s
${ENABLE_NETCONF_TEST_TIMEOUT}    ${ENABLE_GLOBAL_TEST_DEADLINES}

*** Keywords ***
Setup_NetconfKeywords
    [Arguments]    ${create_session_for_templated_requests}=True
    [Documentation]    Setup the environment for the other keywords of this Resource to work properly.
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${NetconfKeywords__mounted_device_types}    ${tmp}
    BuiltIn.Run_Keyword_If    ${create_session_for_templated_requests}    TemplatedRequests.Create_Default_Session
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage

Configure_Device_In_Netconf
    [Arguments]    ${device_name}    ${device_type}=default    ${device_port}=${FIRST_TESTTOOL_PORT}    ${device_address}=${TOOLS_SYSTEM_IP}    ${device_user}=admin    ${device_password}=topsecret
    ...    ${session}=default
    [Documentation]    Tell Netconf about the specified device so it can add it into its configuration.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_IP': '${device_address}', 'DEVICE_NAME': '${device_name}', 'DEVICE_PORT': '${device_port}', 'DEVICE_USER': '${device_user}', 'DEVICE_PASSWORD': '${device_password}'}
    TemplatedRequests.Put_As_Xml_Templated    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${device_type}    ${template_as_string}    session=${session}
    Collections.Set_To_Dictionary    ${NetconfKeywords__mounted_device_types}    ${device_name}    ${device_type}

Count_Netconf_Connectors_For_Device
    [Arguments]    ${device_name}    ${session}=default
    [Documentation]    Count all instances of the specified device in the Netconf topology (usually 0 or 1).
    # FIXME: This no longer counts netconf connectors, it counts "device instances in Netconf topology".
    # This keyword should be renamed but without an automatic keyword naming standards checker this is
    # potentially destabilizing change so right now it is as FIXME. Proposed new name:
    # Count_Device_Instances_In_Netconf_Topology
    ${mounts}=    TemplatedRequests.Get_As_Json_From_Uri    ${OPERATIONAL_API}/network-topology:network-topology/topology/topology-netconf    session=${session}
    Builtin.Log    ${mounts}
    ${actual_count}=    Builtin.Evaluate    len('''${mounts}'''.split('"node-id": "${device_name}"'))-1
    Builtin.Return_From_Keyword    ${actual_count}

Check_Device_Has_No_Netconf_Connector
    [Arguments]    ${device_name}    ${session}=default
    [Documentation]    Check that there are no instances of the specified device in the Netconf topology.
    # FIXME: Similarlt to "Count_Netconf_Connectors_For_Device", this does not check whether the device has
    # no netconf connector but whether the device is present in the netconf topology or not. Rename, proposed
    # new name: Check_Device_Not_Present_In_Netconf_Topology
    ${count}    Count_Netconf_Connectors_For_Device    ${device_name}    session=${session}
    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Device_Completely_Gone
    [Arguments]    ${device_name}    ${session}=default
    [Documentation]    Check that the specified device has no Netconf connectors nor associated data.
    Check_Device_Has_No_Netconf_Connector    ${device_name}    session=${session}
    ${uri}=    Builtin.Set_Variable    ${CONFIG_API}/network-topology:network-topology/topology/topology-netconf/node/${device_name}
    ${status}    ${response}=    BuiltIn.Run_Keyword_And_Ignore_Error    TemplatedRequests.Get_As_Xml_From_Uri    ${uri}    session=${session}
    BuiltIn.Should_Be_Equal_As_Strings    ${status}    FAIL
    BuiltIn.Should_Contain    ${response}    404

Check_Device_Connected
    [Arguments]    ${device_name}    ${session}=default
    [Documentation]    Check that the specified device is accessible from Netconf.
    ${device_status}=    TemplatedRequests.Get_As_Json_From_Uri    ${OPERATIONAL_API}/network-topology:network-topology/topology/topology-netconf/node/${device_name}    session=${session}
    Builtin.Should_Contain    ${device_status}    "netconf-node-topology:connection-status": "connected"

Wait_Device_Connected
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s    ${session}=default
    [Documentation]    Wait for the device to become connected.
    ...    It is more readable to use this keyword in a test case than to put the whole WUKS below into it.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Connected    ${device_name}    session=${session}

Remove_Device_From_Netconf
    [Arguments]    ${device_name}    ${session}=default
    [Documentation]    Tell Netconf to deconfigure the specified device
    ${device_type}=    Collections.Pop_From_Dictionary    ${NetconfKeywords__mounted_device_types}    ${device_name}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Delete_Templated    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${device_type}    ${template_as_string}    session=${session}

Wait_Device_Fully_Removed
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s    ${session}=default
    [Documentation]    Wait until all netconf connectors for the device with the given name disappear.
    ...    Call of Remove_Device_From_Netconf returns before netconf gets
    ...    around deleting the device's connector. To ensure the device is
    ...    really gone from netconf, use this keyword to make sure all
    ...    connectors disappear. If a call to Remove_Device_From_Netconf
    ...    is not made before using this keyword, the wait will fail.
    ...    Using this keyword is more readable than putting the WUKS below
    ...    into a test case.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Completely_Gone    ${device_name}    session=${session}

NetconfKeywords__Deploy_Additional_Schemas
    [Arguments]    ${schemas}
    [Documentation]    Internal keyword for Install_And_Start_TestTool
    ...    This deploys the additional schemas if any and returns a
    ...    command line argument to be added to the testtool commandline
    ...    to tell it to load them. While this code could be integrated
    ...    into its only user, I considered the resulting code to be too
    ...    unreadable as the actions are quite different in the two
    ...    possibilities (additional schemas present versus no additional
    ...    schemas present), therefore a separate keyword is used.
    # Make sure there is no schemas directory on the remote machine. A
    # previous test suite might have left some debris there and that might
    # lead to spurious failures, so it is better to make sure we start with a
    # clean slate. Additionally when the caller did not specify any
    # additional schemas for testtool, we want to make extra sure none are
    # used.
    ${response}=    SSHLibrary.Execute_Command    rm -rf schemas 2>&1
    BuiltIn.Log    ${response}
    # Drop out of the keyword, returning no command line argument when there
    # are no additional schemas to deploy.
    BuiltIn.Return_From_Keyword_If    '${schemas}' == 'none'    ${EMPTY}
    # Deploy the additional schemas into a standard directory on the remote
    # machine and construct a command line argument pointing to that
    # directory from the point of view of the process running on that
    # machine.
    SSHLibrary.Put_Directory    ${schemas}    destination=./schemas
    [Return]    --schemas-dir ./schemas

NetconfKeywords__Check_Device_Is_Up
    [Arguments]    ${last-port}
    ${count}=    SSHKeywords.Count_Port_Occurences    ${last-port}    LISTEN    java
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    1

NetconfKeywords__Wait_Device_Is_Up_And_Running
    [Arguments]    ${device_name}
    ${number}=    BuiltIn.Evaluate    '${device_name}'.split('-').pop()
    BuiltIn.Wait_Until_Keyword_Succeeds    ${TESTTOOL_BOOT_TIMEOUT}    1s    Check_Device_Up_And_Running    ${number}

Install_And_Start_Testtool
    [Arguments]    ${device-count}=10    ${debug}=true    ${schemas}=none    ${tool_options}=${EMPTY}    ${java_options}=${TESTTOOL_DEFAULT_JAVA_OPTIONS}    ${mdsal}=true
    [Documentation]    Install and run testtool. Also arrange to collect its output into a log file.
    ...    When the ${schemas} argument is set to 'none', it signifies that
    ...    there are no additional schemas to be deployed, so the directory
    ...    for the additional schemas is deleted on the remote machine and
    ...    the additional schemas argument is left out.
    # Install test tool on the machine.
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool
    ${schemas_option}=    NetconfKeywords__Deploy_Additional_Schemas    ${schemas}
    # Start the testtool
    ${command}=    NexusKeywords.Compose_Full_Java_Command    ${java_options} -jar ${filename} ${tool_options} --device-count ${device-count} --debug ${debug} ${schemas_option} --md-sal ${mdsal}
    BuiltIn.Log    Running testtool: ${command}
    ${logfile}=    Utils.Get_Log_File_Name    testtool
    BuiltIn.Set_Suite_Variable    ${testtool_log}    ${logfile}
    SSHLibrary.Write    ${command} >${logfile} 2>&1
    # Store information needed by other keywords.
    BuiltIn.Set_Suite_Variable    ${NetconfKeywords__testtool_device_count}    ${device-count}
    # Wait for the testtool to boot up.
    Perform_Operation_On_Each_Device    NetconfKeywords__Wait_Device_Is_Up_And_Running

Check_Device_Up_And_Running
    [Arguments]    ${device-number}
    [Documentation]    Query netstat on remote machine whether testtool device with the specified number has its port open and fail if not.
    ${device-port}=    BuiltIn.Evaluate    ${FIRST_TESTTOOL_PORT}+${device-number}-1
    NetconfKeywords__Check_Device_Is_Up    ${device-port}

Stop_Testtool
    [Documentation]    Stop testtool and download its log.
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Read_Until_Prompt
    # TODO: Unify with play.py and pcc-mock handling.
    # TODO: Maybe this keyword's content shall be moved into SSHUtils and named somewhat like
    # "Interrupt_Program_And_Download_Its_Log" which will get an argument stating the name of
    # the log file to get.
    SSHLibrary.Get_File    ${testtool_log}

NetconfKeywords__Check_Netconf_Test_Timeout_Not_Expired
    [Arguments]    ${deadline_Date}
    BuiltIn.Return_From_Keyword_If    not ${ENABLE_NETCONF_TEST_TIMEOUT}
    ${current_Date}=    DateTime.Get_Current_Date
    ${ellapsed_seconds}=    DateTime.Subtract_Date_From_Date    ${deadline_Date}    ${current_Date}
    BuiltIn.Run_Keyword_If    ${ellapsed_seconds}<0    Fail    The global time out period expired

NetconfKeywords__Perform_Operation_With_Checking_On_Next_Device
    [Arguments]    ${operation}    ${deadline_Date}
    NetconfKeywords__Check_Netconf_Test_Timeout_Not_Expired    ${deadline_Date}
    ${number}=    BuiltIn.Evaluate    ${current_port}-${BASE_NETCONF_DEVICE_PORT}+1
    BuiltIn.Run_Keyword    ${operation}    ${DEVICE_NAME_BASE}-${number}
    ${next}=    BuiltIn.Evaluate    ${current_port}+1
    BuiltIn.Set_Suite_Variable    ${current_port}    ${next}

Perform_Operation_On_Each_Device
    [Arguments]    ${operation}    ${count}=${NetconfKeywords__testtool_device_count}    ${timeout}=30m
    ${current_Date}=    DateTime.Get_Current_Date
    ${deadline_Date}=    DateTime.Add_Time_To_Date    ${current_Date}    ${timeout}
    BuiltIn.Set_Suite_Variable    ${current_port}    ${BASE_NETCONF_DEVICE_PORT}
    BuiltIn.Repeat_Keyword    ${count} times    NetconfKeywords__Perform_Operation_With_Checking_On_Next_Device    ${operation}    ${deadline_Date}
