*** Settings ***
Documentation     netconf-connector CRUD test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Perform basic operations (Create, Read, Update and Delete or CRUD) on device
...               data mounted onto a netconf connector and see if they work.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    prompt=${MININET_PROMPT}    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${device_name}    netconf-test-device
${netconf_ns}     urn:ietf:params:xml:ns:netconf:base:1.0

*** Test Cases ***
Check_Device_Is_Not_Mounted_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    [Tags]    critical
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${device_name}

Mount_Device_On_Netconf
    [Documentation]    Make request to mount a testtool device on Netconf connector
    [Tags]    critical
    NetconfKeywords.Mount_Device_Onto_Netconf    ${device_name}

Check_ODL_Has_Netconf_Connector_For_Device
    [Documentation]    Get the list of mounts and search for our device there. Fail if not found.
    [Tags]    critical
    ${count}    Count_Netconf_Connectors_For_Device    ${device_name}
    Builtin.Should_Be_Equal_As_Strings    ${count}    1

Wait_For_Device_To_Become_Mounted
    [Documentation]    Wait until the device becomes available through Netconf.
    NetconfKeywords.Wait_Device_Mounted    ${device_name}

Check_Device_Data_Is_Empty
    [Documentation]    Get the device data and make sure it is empty.
    Check_Config_Data    <data xmlns="${netconf_ns}"></data>

Create_Device_Data
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    NetconfViaRestconf.Post_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}dataorig    ${template_as_string}

Check_Device_Data_Is_Created
    [Documentation]    Get the device data and make sure it contains the created content.
    Check_Config_Data    <data xmlns="${netconf_ns}"><cont xmlns="urn:opendaylight:test" xmlns:a="${netconf_ns}" a:operation="replace"><l>Content</l></cont></data>

Modify_Device_Data
    [Documentation]    Send a request to change the sample test data and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    NetconfViaRestconf.Put_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}datamod1    ${template_as_string}

Check_Device_Data_Is_Modified
    [Documentation]    Get the device data and make sure it contains the created content.
    Check_Config_Data    <data xmlns="${netconf_ns}"><cont xmlns="urn:opendaylight:test" xmlns:a="${netconf_ns}" a:operation="replace"><l>Modified Content</l></cont></data>

Delete_Device_Data
    [Documentation]    Send a request to delete the sample test data on the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    NetconfViaRestconf.Delete_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}datamod1    ${template_as_string}

Check_Device_Data_Is_Deleted
    [Documentation]    Get the device data and make sure it is empty again.
    Check_Config_Data    <data xmlns="${netconf_ns}"></data>

Delete_Device_From_Netconf
    [Documentation]    Make request to unmount a testtool device on Netconf connector.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Unmount_Device_From_Netconf    ${device_name}

Check_Device_Going_To_Be_Gone_After_Delete
    [Documentation]    Check that the device is really going to be gone. Fail if found after one minute.
    ...    This is an expected behavior as the unmount request is sent to the config subsystem which
    ...    then triggers asynchronous disconnection of the device which is reflected in the operational
    ...    data once completed. This test makes sure this asynchronous operation does not take
    ...    unreasonable amount of time.
    [Tags]    critical
    NetconfKeywords.Wait_Device_Unmounted    ${device_name}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    # Connect to the Mininet machine
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_Mininet_Login
    SSHKeywords.Install_And_Start_Testtool    device-count=10    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHKeywords.Stop_Testtool

Check_Config_Data
    [Arguments]    ${expected}    ${contains}=False
    ${url}=    Builtin.Set_Variable    network-topology:network-topology/topology/topology-netconf/node/${device_name}/yang-ext:mount
    ${data}=    Utils.Get_Data_From_URI    nvr_session    ${url}    headers=${ACCEPT_XML}
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}
