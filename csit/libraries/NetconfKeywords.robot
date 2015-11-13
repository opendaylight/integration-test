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
Library           RequestsLibrary
Resource          NetconfViaRestconf.robot
Resource          SSHKeywords.robot

*** Variables ***
${DIRECTORY_WITH_DEVICE_TEMPLATES}    ${CURDIR}/../variables/netconf/device
${FIRST_TESTTOOL_PORT}    17830

*** Keywords ***
Setup_NetconfKeywords
    [Documentation]    Setup the environment for the other keywords of this Resource to work properly.
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${NetconfKeywords__mounted_device_types}    ${tmp}
    NetconfViaRestconf.Setup_Netconf_Via_Restconf

Configure_Device_In_Netconf
    [Arguments]    ${device_name}    ${device_type}=default    ${device_port}=${FIRST_TESTTOOL_PORT}
    [Documentation]    Tell Netconf about the specified device so it can add it into its configuration.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_IP': '${TOOLS_SYSTEM_IP}', 'DEVICE_NAME': '${device_name}', 'DEVICE_PORT': '${device_port}'}
    NetconfViaRestconf.Put_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${device_type}    ${template_as_string}
    Collections.Set_To_Dictionary    ${NetconfKeywords__mounted_device_types}    ${device_name}    ${device_type}

Count_Netconf_Connectors_For_Device
    [Arguments]    ${device_name}
    [Documentation]    Count all Netconf connectors referring to the specified device (usually 0 or 1).
    ${mounts}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf
    Builtin.Log    ${mounts}
    ${actual_count}=    Builtin.Evaluate    len('''${mounts}'''.split('"node-id":"${device_name}"'))-1
    Builtin.Return_From_Keyword    ${actual_count}

Check_Device_Has_No_Netconf_Connector
    [Arguments]    ${device_name}
    [Documentation]    Check that there are no Netconf connectors referring to the specified device.
    ${count}    Count_Netconf_Connectors_For_Device    ${device_name}
    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Device_Completely_Gone
    [Arguments]    ${device_name}
    [Documentation]    Check that the specified device has no Netconf connectors nor associated data.
    Check_Device_Has_No_Netconf_Connector    ${device_name}
    ${uri}=    Builtin.Set_Variable    network-topology:network-topology/topology/topology-netconf/node/${device_name}/yang-ext:mount
    ${response}=    RequestsLibrary.Get Request    nvr_session    ${uri}    ${ACCEPT_XML}
    BuiltIn.Should_Be_Equal_As_Integers    ${response.status_code}    404

Check_Device_Connected
    [Arguments]    ${device_name}
    [Documentation]    Check that the specified device is accessible from Netconf.
    ${device_status}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf/node/${device_name}
    Builtin.Should_Contain    ${device_status}    "netconf-node-topology:connection-status":"connected"

Wait_Device_Connected
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s
    [Documentation]    Wait for the device to become connected.
    ...    It is more readable to use this keyword in a test case than to put the whole WUKS below into it.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Connected    ${device_name}

Remove_Device_From_Netconf
    [Arguments]    ${device_name}
    [Documentation]    Tell Netconf to deconfigure the specified device
    ${device_type}=    Collections.Pop_From_Dictionary    ${NetconfKeywords__mounted_device_types}    ${device_name}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    NetconfViaRestconf.Delete_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${device_type}    ${template_as_string}

Wait_Device_Fully_Removed
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s
    [Documentation]    Wait until all netconf connectors for the device with the given name disappear.
    ...    Call of Remove_Device_From_Netconf returns before netconf gets
    ...    around deleting the device's connector. To ensure the device is
    ...    really gone from netconf, use this keyword to make sure all
    ...    connectors disappear. If a call to Remove_Device_From_Netconf
    ...    is not made before using this keyword, the wait will fail.
    ...    Using this keyword is more readable than putting the WUKS below
    ...    into a test case.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Completely_Gone    ${device_name}

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

Install_And_Start_Testtool
    [Arguments]    ${device-count}=10    ${debug}=true    ${schemas}=none    ${options}=${EMPTY}
    [Documentation]    Install and run testtool. Also arrange to collect its output into a log file.
    ...    When the ${schemas} argument is set to 'none', it signifies that
    ...    there are no additional schemas to be deployed, so the directory
    ...    for the additional schemas is deleted on the remote machine and
    ...    the additional schemas argument is left out.
    # Install test tool on the machine.
    # TODO: The "urlbase" line is very similar to what pcep suites do. Reduce this code duplication.
    ${urlbase}=    BuiltIn.Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot/org/opendaylight/netconf/netconf-testtool
    ${version}=    SSHLibrary.Execute_Command    curl ${urlbase}/maven-metadata.xml | grep '<version>' | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${version}
    ${namepart}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    BuiltIn.Set_Suite_Variable    ${filename}    netconf-testtool-${namepart}-executable.jar
    BuiltIn.Log    ${filename}
    ${response}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/${filename} >${filename}
    BuiltIn.Log    ${response}
    ${schemas_option}=    NetconfKeywords__Deploy_Additional_Schemas    ${schemas}
    # Start the testtool
    ${command}    BuiltIn.Set_Variable    java -Xmx1G -XX:MaxPermSize=256M -jar ${filename} --device-count ${device-count} --debug ${debug} ${schemas_option} ${options}
    BuiltIn.Log    Running testtool: ${command}
    SSHLibrary.Write    ${command} >testtool.log 2>&1
    # Wait for the testtool to boot up.
    ${timeout}=    BuiltIn.Evaluate    (${device-count}/3)+5
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}s    1s    NetconfKeywords__Check_Device_Is_Up    ${FIRST_TESTTOOL_PORT}

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
    SSHLibrary.Get_File    testtool.log
