*** Settings ***
Documentation     Access Netconf via Restconf.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           Collections
Resource          NetconfViaRestconf.robot
Resource          SSHKeywords.robot

*** Variables ***
${DIRECTORY_WITH_DEVICE_TEMPLATES}    ${CURDIR}/../variables/netconf/device
${DIRECTORY_FOR_SCHEMAS}    schemas
${FIRST_TESTTOOL_PORT}    17830

*** Keywords ***
Setup_Netconf_Keywords
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${mounted_device_types}    ${tmp}
    NetconfViaRestconf.Setup_Netconf_Via_Restconf
    # Setup a requests session for operational data (used by Netconf mount checks)
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}

Mount_Device_Onto_Netconf
    [Arguments]    ${device_name}    ${device_type}=default    ${device_port}=${FIRST_TESTTOOL_PORT}
    [Documentation]    Tell Netconf to make the specified device accessible.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_IP': '${MININET}', 'DEVICE_NAME': '${device_name}', 'DEVICE_PORT': '${device_port}'}
    NetconfViaRestconf.Put_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${device_type}    ${template_as_string}
    Collections.Set_To_Dictionary    ${mounted_device_types}    ${device_name}    ${device_type}

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
    [Documentation]    Check thatthe specified device is accessible from Netconf.
    ${device_status}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf/node/${device_name}
    Builtin.Should_Contain    ${device_status}    "netconf-node-topology:connection-status":"connected"

Wait_Device_Mounted
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Mounted    ${device_name}

Unmount_Device_From_Netconf
    [Arguments]    ${device_name}
    [Documentation]    Tell Netconf to drop accessibility point for the specified device
    ${device_type}=    Collections.Pop_From_Dictionary    ${mounted_device_types}    ${device_name}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    NetconfViaRestconf.Delete_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_DEVICE_TEMPLATES}${/}${device_type}    ${template_as_string}

Wait_Device_Unmounted
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s
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
    ${response}=    SSHLibrary.Execute_Command    rm -rf ${DIRECTORY_FOR_SCHEMAS}
    BuiltIn.Log    ${response}
    # Drop out of the keyword, returning no command line argument when there
    # are no additional schemas to deploy.
    BuiltIn.Return_From_Keyword_If    '${schemas}' == 'none'    ${EMPTY}
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
    [Arguments]    ${device-count}=10    ${debug}=true    ${schemas}=none
    [Documentation]    Install and run testtool.
    # Install test tool on the machine.
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
    ${timeout}=    BuiltIn.Evaluate    ${device-count}/3
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}s    1s    NetconfKeywords__Check_Device_Is_Up    ${FIRST_TESTTOOL_PORT}

Check_Device_Up_And_Running
    [Arguments]    ${device-number}
    [Documentation]
    ${device-port}=    BuiltIn.Evaluate    ${FIRST_TESTTOOL_PORT}+${device-number}-1
    NetconfKeywords__Check_Device_Is_Up    ${device-port}

Stop_Testtool
    [Documentation]    Stop testtool and download its log.
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Read_Until_Prompt
    SSHLibrary.Get_File    testtool.log
