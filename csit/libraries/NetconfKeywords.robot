*** Settings ***
Documentation       Perform complex operations on netconf.
...
...                 Copyright (c) 2015,2017 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 This library encapsulates a bunch of somewhat complex and commonly used
...                 netconf operations into reusable keywords to make writing netconf
...                 test suites easier.
...
...                 TODO: RemoteBash.robot contains logic which could be reused here.

Library             Collections
Library             DateTime
Library             RequestsLibrary
Library             SSHLibrary
Resource            NexusKeywords.robot
Resource            Restconf.robot
Resource            SSHKeywords.robot
Resource            TemplatedRequests.robot
Resource            Utils.robot
Resource            RemoteBash.robot
Resource            ${CURDIR}/CompareStream.robot


*** Variables ***
${MAX_HEAP}                             1G
${TESTTOOL_DEFAULT_JAVA_OPTIONS}        -Xmx${MAX_HEAP} -Djava.security.egd=file:/dev/./urandom
${DIRECTORY_WITH_DEVICE_TEMPLATES}      ${CURDIR}/../variables/netconf/device
${FIRST_TESTTOOL_PORT}                  17830
${BASE_NETCONF_DEVICE_PORT}             17830
${DEVICE_NAME_BASE}                     netconf-scaling-device
${TESTTOOL_BOOT_TIMEOUT}                60s
${ENABLE_NETCONF_TEST_TIMEOUT}          ${ENABLE_GLOBAL_TEST_DEADLINES}
${SSE_CFG_FILE}                         ${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.restconf.nb.rfc8040.cfg
${RESTCONF_PREFIX}                      ${{ "restconf" if $RESTCONFPORT == "8182" else "rests" }}


*** Keywords ***
Setup_NetconfKeywords
    [Documentation]    Setup the environment for the other keywords of this Resource to work properly.
    [Arguments]    ${create_session_for_templated_requests}=True
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${NetconfKeywords__mounted_device_types}    ${tmp}
    IF    ${create_session_for_templated_requests}
        TemplatedRequests.Create_Default_Session    timeout=2
    END
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage

Configure_Device_In_Netconf
    [Documentation]    Tell Netconf about the specified device so it can add it into its configuration.
    [Arguments]    ${device_name}    ${device_type}=default    ${device_port}=${FIRST_TESTTOOL_PORT}    ${device_address}=${TOOLS_SYSTEM_IP}    ${device_user}=admin    ${device_password}=topsecret
    ...    ${device_key}=device-key    ${session}=default    ${schema_directory}=/tmp/schema    ${http_timeout}=${EMPTY}    ${http_method}=put
    ${version}=    CompareStream.Set_Variable_If_At_Least_Scandium    scandium    calcium
    ${mapping}=    BuiltIn.Create_dictionary
    ...    DEVICE_IP=${device_address}
    ...    DEVICE_NAME=${device_name}
    ...    DEVICE_PORT=${device_port}
    ...    DEVICE_USER=${device_user}
    ...    DEVICE_PASSWORD=${device_password}
    ...    DEVICE_KEY=${device_key}
    ...    SCHEMA_DIRECTORY=${schema_directory}
    ...    RESTCONF_PREFIX=${RESTCONF_PREFIX}
    # TODO: Is it possible to use &{kwargs} as a mapping directly?
    IF    '${http_method}'=='post'
        TemplatedRequests.Post_As_Xml_Templated
        ...    folder=${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${version}${/}${device_type}
        ...    mapping=${mapping}
        ...    session=${session}
        ...    http_timeout=${http_timeout}
    ELSE
        TemplatedRequests.Put_As_Xml_Templated
        ...    folder=${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${version}${/}${device_type}
        ...    mapping=${mapping}
        ...    session=${session}
        ...    http_timeout=${http_timeout}
    END
    Collections.Set_To_Dictionary    ${NetconfKeywords__mounted_device_types}    ${device_name}    ${device_type}

Configure_Device
    [Documentation]    Operation for configuring the device.
    [Arguments]    ${current_name}    ${log_response}=True
    KarafKeywords.Log_Message_To_Controller_Karaf    Configuring device ${current_name} to Netconf
    Configure_Device_In_Netconf    ${current_name}    device_type=${device_type}    device_port=${current_port}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} configured

Configure_Device_And_Verify
    [Documentation]    Operation for configuring the device in the Netconf subsystem and connecting to it.
    [Arguments]    ${current_name}    ${log_response}=True
    Configure_Device    ${current_name}    ${log_response}
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to connect
    Wait_Device_Connected    ${current_name}    period=0.5s    log_response=${log_response}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} connected

Count_Netconf_Connectors_For_Device
    [Documentation]    Count all instances of the specified device in the Netconf topology (usually 0 or 1).
    [Arguments]    ${device_name}    ${session}=default
    # FIXME: This no longer counts netconf connectors, it counts "device instances in Netconf topology".
    # This keyword should be renamed but without an automatic keyword naming standards checker this is
    # potentially destabilizing change so right now it is as FIXME. Proposed new name:
    # Count_Device_Instances_In_Netconf_Topology
    ${uri}=    Restconf.Generate URI    network-topology:network-topology    operational
    ${mounts}=    TemplatedRequests.Get_As_Json_From_Uri    ${uri}    session=${session}
    Builtin.Log    ${mounts}
    ${actual_count}=    Builtin.Evaluate    len('''${mounts}'''.split('"node-id": "${device_name}"'))-1
    RETURN    ${actual_count}

Wait_Connected
    [Documentation]    Operation for waiting until the device is connected.
    [Arguments]    ${current_name}    ${log_response}=True
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to connect
    Wait_Device_Connected    ${current_name}    period=0.5s    timeout=300s    log_response=${log_response}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} connected

Check_Device_Has_No_Netconf_Connector
    [Documentation]    Check that there are no instances of the specified device in the Netconf topology.
    [Arguments]    ${device_name}    ${session}=default
    # FIXME: Similarlt to "Count_Netconf_Connectors_For_Device", this does not check whether the device has
    # no netconf connector but whether the device is present in the netconf topology or not. Rename, proposed
    # new name: Check_Device_Not_Present_In_Netconf_Topology
    ${count}=    Count_Netconf_Connectors_For_Device    ${device_name}    session=${session}
    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Device_Completely_Gone
    [Documentation]    Check that the specified device has no Netconf connectors nor associated data.
    [Arguments]    ${device_name}    ${session}=default    ${log_response}=True
    Check_Device_Has_No_Netconf_Connector    ${device_name}    session=${session}
    ${uri}=    Restconf.Generate URI
    ...    network-topology:network-topology
    ...    config
    ...    topology=topology-netconf
    ...    node=${device_name}
    Utils.No Content From URI    ${session}    ${uri}

Check_Device_Connected
    [Documentation]    Check that the specified device is accessible from Netconf.
    [Arguments]    ${device_name}    ${session}=default    ${log_response}=True
    ${uri}=    Restconf.Generate URI
    ...    network-topology:network-topology
    ...    operational
    ...    topology=topology-netconf
    ...    node=${device_name}
    ${device_status}=    TemplatedRequests.Get_As_Json_From_Uri
    ...    ${uri}
    ...    session=${session}
    ...    log_response=${log_response}
    Builtin.Should_Contain    ${device_status}    connection-status": "connected"

Wait_Device_Connected
    [Documentation]    Wait for the device to become connected.
    ...    It is more readable to use this keyword in a test case than to put the whole WUKS below into it.
    [Arguments]    ${device_name}    ${timeout}=20s    ${period}=1s    ${session}=default    ${log_response}=True
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    ${timeout}
    ...    ${period}
    ...    Check_Device_Connected
    ...    ${device_name}
    ...    session=${session}
    ...    log_response=${log_response}

Remove_Device_From_Netconf
    [Documentation]    Tell Netconf to deconfigure the specified device
    [Arguments]    ${device_name}    ${session}=default    ${location}=location
    ${device_type}=    Collections.Pop_From_Dictionary    ${NetconfKeywords__mounted_device_types}    ${device_name}
    ${mapping}=    BuiltIn.Create_Dictionary    DEVICE_NAME=${device_name}    RESTCONF_PREFIX=${RESTCONF_PREFIX}
    ${version}=    CompareStream.Set_Variable_If_At_Least_Scandium    scandium    calcium
    TemplatedRequests.Delete_Templated
    ...    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${version}${/}${device_type}
    ...    ${mapping}
    ...    session=${session}
    ...    location=${location}

Deconfigure_Device
    [Documentation]    Operation for deconfiguring the device.
    [Arguments]    ${current_name}    ${log_response}=True
    KarafKeywords.Log_Message_To_Controller_Karaf    Deconfiguring device ${current_name}
    Remove_Device_From_Netconf    ${current_name}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} deconfigured

Deconfigure_Device_And_Verify
    [Documentation]    Operation for deconfiguring the device from Netconf.
    [Arguments]    ${current_name}    ${log_response}=True
    Deconfigure_Device    ${current_name}    ${log_response}
    Check_Device_Deconfigured    ${current_name}

Check_Device_Deconfigured
    [Documentation]    Operation for making sure the device is really deconfigured.
    [Arguments]    ${current_name}    ${log_response}=True
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to disappear
    Wait_Device_Fully_Removed    ${current_name}    period=0.5s    timeout=120s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} removed

Wait_Device_Fully_Removed
    [Documentation]    Wait until all netconf connectors for the device with the given name disappear.
    ...    Call of Remove_Device_From_Netconf returns before netconf gets
    ...    around deleting the device's connector. To ensure the device is
    ...    really gone from netconf, use this keyword to make sure all
    ...    connectors disappear. If a call to Remove_Device_From_Netconf
    ...    is not made before using this keyword, the wait will fail.
    ...    Using this keyword is more readable than putting the WUKS below
    ...    into a test case.
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s    ${session}=default    ${log_response}=True
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    ${timeout}
    ...    ${period}
    ...    Check_Device_Completely_Gone
    ...    ${device_name}
    ...    session=${session}
    ...    log_response=${log_response}

NetconfKeywords__Deploy_Additional_Schemas
    [Documentation]    Internal keyword for Install_And_Start_TestTool
    ...    This deploys the additional schemas if any and returns a
    ...    command line argument to be added to the testtool commandline
    ...    to tell it to load them. While this code could be integrated
    ...    into its only user, I considered the resulting code to be too
    ...    unreadable as the actions are quite different in the two
    ...    possibilities (additional schemas present versus no additional
    ...    schemas present), therefore a separate keyword is used.
    [Arguments]    ${schemas}
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
    IF    '${schemas}' == 'none'    RETURN    ${EMPTY}
    # Deploy the additional schemas into a standard directory on the remote
    # machine and construct a command line argument pointing to that
    # directory from the point of view of the process running on that
    # machine.
    SSHLibrary.Put_Directory    ${schemas}    destination=./schemas
    SSHLibrary.List_Directory    ./schemas
    RETURN    --schemas-dir ./schemas

NetconfKeywords__Deploy_Custom_RPC
    [Documentation]    Internal keyword for Install_And_Start_TestTool
    ...    This deploys the optional custom rpc file.
    ...    Drop out of the keyword, returning no command line argument when there
    ...    is no rpc file to deploy.
    [Arguments]    ${rpc_config}
    IF    '${rpc_config}' == 'none'    RETURN    ${EMPTY}
    SSHKeywords.Copy_File_To_Tools_System    ${TOOLS_SYSTEM_1_IP}    ${rpc_config}    /tmp
    RETURN    --rpc-config /tmp/customaction.xml

NetconfKeywords__Check_Device_Is_Up
    [Arguments]    ${last-port}
    ${count}=    SSHKeywords.Count_Port_Occurences    ${last-port}    LISTEN    java
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    1

NetconfKeywords__Wait_Device_Is_Up_And_Running
    [Arguments]    ${device_name}    ${log_response}=True
    ${number}=    BuiltIn.Evaluate    '${device_name}'.split('-').pop()
    BuiltIn.Wait_Until_Keyword_Succeeds    ${TESTTOOL_BOOT_TIMEOUT}    1s    Check_Device_Up_And_Running    ${number}

Install_And_Start_Testtool
    [Documentation]    Install and run testtool.
    [Arguments]    ${device-count}=10    ${debug}=true    ${schemas}=none    ${rpc_config}=none    ${tool_options}=${EMPTY}    ${java_options}=${TESTTOOL_DEFAULT_JAVA_OPTIONS}
    ...    ${mdsal}=true    ${log_response}=True
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool
    Start_Testtool    ${filename}    ${device-count}    ${debug}    ${schemas}    ${rpc_config}    ${tool_options}
    ...    ${java_options}    ${mdsal}    log_response=${log_response}

Start_Testtool
    [Documentation]    Arrange to collect tool's output into a log file.
    ...    Will use specific ${schemas} unless argument resolves to 'none',
    ...    which signifies that there are no additional schemas to be deployed.
    ...    If so the directory for the additional schemas is deleted on the
    ...    remote machine and the additional schemas argument is left out.
    [Arguments]    ${filename}    ${device-count}=10    ${debug}=true    ${schemas}=none    ${rpc_config}=none    ${tool_options}=${EMPTY}
    ...    ${java_options}=${TESTTOOL_DEFAULT_JAVA_OPTIONS}    ${mdsal}=true    ${log_response}=True
    ${schemas_option}=    NetconfKeywords__Deploy_Additional_Schemas    ${schemas}
    ${rpc_config_option}=    NetconfKeywords__Deploy_Custom_RPC    ${rpc_config}
    ${command}=    NexusKeywords.Compose_Full_Java_Command
    ...    ${java_options} -jar ${filename} ${tool_options} --device-count ${device-count} --debug ${debug} ${schemas_option} ${rpc_config_option} --md-sal ${mdsal}
    BuiltIn.Log    Running testtool: ${command}
    ${logfile}=    Utils.Get_Log_File_Name    testtool
    BuiltIn.Set_Suite_Variable    ${testtool_log}    ${logfile}
    SSHLibrary.Write    ${command} >${logfile} 2>&1
    # Store information needed by other keywords.
    BuiltIn.Set_Suite_Variable    ${NetconfKeywords__testtool_device_count}    ${device-count}
    # Wait for the testtool to boot up.
    Perform_Operation_On_Each_Device    NetconfKeywords__Wait_Device_Is_Up_And_Running    log_response=${log_response}

Check_Device_Up_And_Running
    [Documentation]    Query netstat on remote machine whether testtool device with the specified number has its port open and fail if not.
    [Arguments]    ${device-number}
    ${device-port}=    BuiltIn.Evaluate    ${FIRST_TESTTOOL_PORT}+${device-number}-1
    NetconfKeywords__Check_Device_Is_Up    ${device-port}

Stop_Testtool
    [Documentation]    Stop testtool and download its log.
    RemoteBash.Write_Bare_Ctrl_C
    SSHLibrary.Read_Until_Prompt
    # TODO: Unify with play.py and pcc-mock handling.
    # TODO: Maybe this keyword's content shall be moved into SSHUtils and named somewhat like
    # "Interrupt_Program_And_Download_Its_Log" which will get an argument stating the name of
    # the log file to get.
    SSHLibrary.Get_File    ${testtool_log}

NetconfKeywords__Check_Netconf_Test_Timeout_Not_Expired
    [Arguments]    ${deadline_Date}
    IF    not ${ENABLE_NETCONF_TEST_TIMEOUT}    RETURN
    ${current_Date}=    DateTime.Get_Current_Date
    ${ellapsed_seconds}=    DateTime.Subtract_Date_From_Date    ${deadline_Date}    ${current_Date}
    IF    ${ellapsed_seconds}<0    Fail    The global time out period expired

NetconfKeywords__Perform_Operation_With_Checking_On_Next_Device
    [Arguments]    ${operation}    ${deadline_Date}    ${log_response}=True
    NetconfKeywords__Check_Netconf_Test_Timeout_Not_Expired    ${deadline_Date}
    ${number}=    BuiltIn.Evaluate    ${current_port}-${BASE_NETCONF_DEVICE_PORT}+1
    BuiltIn.Run_Keyword    ${operation}    ${DEVICE_NAME_BASE}-${number}    log_response=${log_response}
    ${next}=    BuiltIn.Evaluate    ${current_port}+1
    BuiltIn.Set_Suite_Variable    ${current_port}    ${next}

Perform_Operation_On_Each_Device
    [Arguments]    ${operation}    ${count}=${NetconfKeywords__testtool_device_count}    ${timeout}=45m    ${log_response}=True
    ${current_Date}=    DateTime.Get_Current_Date
    ${deadline_Date}=    DateTime.Add_Time_To_Date    ${current_Date}    ${timeout}
    BuiltIn.Set_Suite_Variable    ${current_port}    ${BASE_NETCONF_DEVICE_PORT}
    BuiltIn.Repeat_Keyword
    ...    ${count} times
    ...    NetconfKeywords__Perform_Operation_With_Checking_On_Next_Device
    ...    ${operation}
    ...    ${deadline_Date}
    ...    log_response=${log_response}

Disable SSE On Controller
    [Documentation]    Sets the config for using SSE (Server Side Events) to false. Note that
    ...    this keyword only changes the config. A controller restart is needed for the config to
    ...    to take effect.
    [Arguments]    ${controller_ip}
    SSHLibrary.Open Connection    ${controller_ip}
    Login With Public Key    ${ODL_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    ${cmd}=    Set Variable    echo "use-sse=false" > ${SSE_CFG_FILE}
    SSHLibrary.Execute Command    ${cmd}
    SSHLibrary.Close Connection

Enable SSE On Controller
    [Documentation]    Sets the config for using SSE (Server Side Events) to true. Note that
    ...    this keyword only changes the config. A controller restart is needed for the config to
    ...    to take effect.
    [Arguments]    ${controller_ip}
    SSHLibrary.Open Connection    ${controller_ip}
    Login With Public Key    ${ODL_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    ${cmd}=    Set Variable    echo "use-sse=true" > ${SSE_CFG_FILE}
    SSHLibrary.Execute Command    ${cmd}
    SSHLibrary.Close Connection
