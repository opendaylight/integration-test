*** Settings ***
Documentation     Perform complex netconf operations via restconf.
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
Resource          NetconfViaRestconf.robot
Resource          RequestKeywords.robot
Resource          SSHKeywords.robot

*** Variables ***
${DIRECTORY_WITH_DEVICE_TEMPLATES}    ${CURDIR}/../variables/netconf/device
${DIRECTORY_FOR_SCHEMAS}    schemas
${FIRST_TESTTOOL_PORT}    17830

*** Keywords ***
Setup_Netconf_Keywords
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${NetconfKeywords__mounted_device_types}    ${tmp}
    RequestKeywords.Create_Operational_Requests_Session
    NetconfViaRestconf.Setup_Netconf_Via_Restconf

Mount_Device_Onto_Netconf
    [Arguments]    ${device_name}    ${device_type}=default    ${device_port}=${FIRST_TESTTOOL_PORT}
    [Documentation]    Tell Netconf to make the specified device accessible.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_IP': '${TOOLS_SYSTEM_IP}', 'DEVICE_NAME': '${device_name}', 'DEVICE_PORT': '${device_port}'}
    NetconfViaRestconf.Put_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${device_type}    ${template_as_string}
    Collections.Set_To_Dictionary    ${NetconfKeywords__mounted_device_types}    ${device_name}    ${device_type}

Count_Netconf_Connectors_For_Device
    [Arguments]    ${device_name}
    [Documentation]    Count all Netconf connectors referring to the specified device.
    ${mounts}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf
    Builtin.Log    ${mounts}
    ${actual_count}=    Builtin.Evaluate    len('''${mounts}'''.split('"node-id":"${device_name}"'))-1
    Builtin.Return_From_Keyword    ${actual_count}

Check_Device_Has_No_Netconf_Connector
    [Arguments]    ${device_name}
    [Documentation]    Check that there are no Netconf connectors referring to the specified device.
    ${count}    Count_Netconf_Connectors_For_Device    ${device_name}
    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Device_Mounted
    [Arguments]    ${device_name}
    [Documentation]    Check that the specified device is accessible from Netconf.
    ${device_status}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf/node/${device_name}
    Builtin.Should_Contain    ${device_status}    "netconf-node-topology:connection-status":"connected"

Wait_Device_Mounted
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Mounted    ${device_name}

Unmount_Device_From_Netconf
    [Arguments]    ${device_name}
    [Documentation]    Tell Netconf to drop accessibility point for the specified device
    ${device_type}=    Collections.Pop_From_Dictionary    ${NetconfKeywords__mounted_device_types}    ${device_name}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    NetconfViaRestconf.Delete_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${device_type}    ${template_as_string}

Wait_Device_Unmounted
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s
    [Documentation]    Wait until all netconf connectors for the device with the given name disappear.
    ...    Call of Unmount_Device_From_Netconf returns before netconf gets
    ...    around deleting the device's connector. To ensure the device is
    ...    really gone from netconf, use this keyword to make sure all
    ...    connectors disappear. This must be preceeded by a call to
    ...    Wait_Device_Unmounted otherwise the wait will fail.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Has_No_Netconf_Connector    ${device_name}

NetconfKeywords__Deploy_Additional_Schemas
    [Arguments]    ${schemas}
    [Documentation]    Internal keyword for Install_And_Start_TestTool
    ...    Needed to have this in a separate keyword because Robot does not
    ...    support conditional assignments to a local variable. This deploys
    ...    the additional schemas if any and returns a command line argument
    ...    to be added to the testtool commandline to tell it to load them.
    # Make sure there is no schemas directory on the remote machine. A
    # previous test suite might have left some debris there and that might
    # lead to spurious failures, so it is better to make sure we start with a
    # clean slate. Additionally when the caller did not specify any
    # additional schemas for testtool, we want to make extra sure none are
    # used.
    ${response}=    SSHLibrary.Execute_Command    rm -rf ${DIRECTORY_FOR_SCHEMAS} 2>&1
    BuiltIn.Log    ${response}
    # Drop out of the keyword, returning no command line argument when there
    # are no additional schemas to deploy.
    BuiltIn.Return_From_Keyword_If    '${schemas}' is None    ${EMPTY}
    # Deploy the additional schemas into a standard directory on the remote
    # machine and construct a command line argument pointing to that
    # directory from the point of view of the process running on that
    # machine.
    SSHLibrary.Put_Directory    ${schemas}    destination=./${DIRECTORY_FOR_SCHEMAS}
    [Return]    --schemas-dir \$HOME/${DIRECTORY_FOR_SCHEMAS}

NetconfKeywords__Check_Device_Is_Up
    [Arguments]    ${last-port}
    ${count}=    SSHKeywords.Count_Port_Occurences    ${last-port}    LISTEN    java
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    1

Install_And_Start_Testtool
    [Arguments]    ${device-count}=10    ${debug}=true    ${schemas}=${None}
    [Documentation]    Install and run testtool. Also arrange to collect its output into a log file.
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
    SSHLibrary.Write    java -Xmx1G -XX:MaxPermSize=256M -jar ${filename} --device-count ${device-count} --debug ${debug} ${schemas_option} >testtool.log 2>&1
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
