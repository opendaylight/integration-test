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
...
...               FIXME: Replace the BuiltIn.Should_[Not_]Contain instances in the test cases
...               that check the car list related data with calls to keywords of a Resource
...               aimed at getting interesting pieces of data from the XML files and checking
...               them against expected data sets. See MDSAL/northbound.robot suite for
...               additional information.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${device_name}    netconf-test-device

*** Test Cases ***
Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Check_Device_Is_Not_Configured_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    [Tags]    critical
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${device_name}

Configure_Device_On_Netconf
    [Documentation]    Make request to configure a testtool device on Netconf connector.
    [Tags]    critical
    NetconfKeywords.Configure_Device_In_Netconf    ${device_name}

Check_ODL_Has_Netconf_Connector_For_Device
    [Documentation]    Get the list of configured devices and search for our device there. Fail if not found.
    [Tags]    critical
    ${count}    NetconfKeywords.Count_Netconf_Connectors_For_Device    ${device_name}
    Builtin.Should_Be_Equal_As_Strings    ${count}    1

Wait_For_Device_To_Become_Connected
    [Documentation]    Wait until the device becomes available through Netconf.
    NetconfKeywords.Wait_Device_Connected    ${device_name}

Check_Device_Data_Is_Empty
    [Documentation]    Get the device data and make sure it is empty.
    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>

Create_Device_Data_Label_Via_Xml
    [Documentation]    Send a sample test data label into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}dataorig    ${template_as_string}

Check_Device_Data_Label_Is_Created
    [Documentation]    Get the device data label and make sure it contains the created content.
    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Content</l></cont></data>

Modify_Device_Data_Label_Via_Xml
    [Documentation]    Send a request to change the sample test data label and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Put_As_Xml_Templated    ${directory_with_template_folders}${/}datamod1    ${template_as_string}

Check_Device_Data_Label_Is_Modified
    [Documentation]    Get the device data label and make sure it contains the modified content.
    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Modified Content</l></cont></data>

Deconfigure_Device_From_Netconf_Temporarily
    [Documentation]    Make request to deconfigure the testtool device on Netconf connector.
    ...    This is the first part of the "configure/deconfigure" cycle of the device
    ...    The purpose of cycling the device like this is to see that the configuration
    ...    data was really stored in the device.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${device_name}

Wait_For_Device_To_Be_Gone
    [Documentation]    Wait for the device to completely disappear.
    NetconfKeywords.Wait_Device_Fully_Removed    ${device_name}

Configure_The_Device_Back
    [Documentation]    Configure the device again.
    ...    This is the second step of the device configuration.
    [Tags]    critical
    NetconfKeywords.Configure_Device_In_Netconf    ${device_name}

Wait_For_Device_To_Reconnect
    [Documentation]    Wait until the device becomes available through Netconf.
    NetconfKeywords.Wait_Device_Connected    ${device_name}

Check_Modified_Device_Data_Is_Still_There
    [Documentation]    Get the device data and make sure it contains the created content.
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Modified Content</l></cont></data>

Modify_Device_Data_Again
    [Documentation]    Send a request to change the sample test data and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Put_As_Xml_Templated    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}datamod2    ${template_as_string}

Check_Device_Data_Is_Modified_Again
    [Documentation]    Get the device data and make sure it contains the created content.
    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Another Modified Content</l></cont></data>

Modify_Device_Data_Label_Via_Json
    [Documentation]    Send a JSON request to change the sample test data label and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Put_As_Json_Templated    ${directory_with_template_folders}${/}datamodjson    ${template_as_string}

Check_Device_Data_Label_Is_Modified_Via_Json
    [Documentation]    Get the device data label as XML and make sure it matches the content posted as JSON in the previous case.
    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Content Modified via JSON</l></cont></data>

Create_Car_List
    [Documentation]    Send a request to create a list of cars in the sample test data label and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}cars    ${template_as_string}

Check_Car_List_Created
    [Documentation]    Get the device data label as XML and make sure it matches the content posted as JSON in the previous case.
    ${data}=    Get_Config_Data
    BuiltIn.Should_Contain    ${data}    <id>KEEP</id>
    BuiltIn.Should_Not_Contain    ${data}    <id>SMALL</id>
    BuiltIn.Should_Not_Contain    ${data}    <model>Isetta</model>
    BuiltIn.Should_Not_Contain    ${data}    <manufacturer>BMW</manufacturer>
    BuiltIn.Should_Not_Contain    ${data}    <year>1953</year>
    BuiltIn.Should_Not_Contain    ${data}    <category>microcar</category>
    BuiltIn.Should_Not_Contain    ${data}    <id>TOYOTA</id>
    BuiltIn.Should_Not_Contain    ${data}    <model>Camry</model>
    BuiltIn.Should_Not_Contain    ${data}    <manufacturer>Toyota</manufacturer>
    BuiltIn.Should_Not_Contain    ${data}    <year>1982</year>
    BuiltIn.Should_Not_Contain    ${data}    <category>sedan</category>

Add_Device_Data_Item_1_Via_XML_Post
    [Documentation]    Send a request to create a data item in the test list and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}item1    ${template_as_string}

Check_Item1_Is_Created
    [Documentation]    Get the device data as XML and make sure it matches the content posted as JSON in the previous case.
    ${data}=    Get_Config_Data
    BuiltIn.Should_Contain    ${data}    <id>SMALL</id>
    BuiltIn.Should_Contain    ${data}    <model>Isetta</model>
    BuiltIn.Should_Contain    ${data}    <manufacturer>BMW</manufacturer>
    BuiltIn.Should_Contain    ${data}    <year>1953</year>
    BuiltIn.Should_Contain    ${data}    <category>microcar</category>
    BuiltIn.Should_Not_Contain    ${data}    <id>TOYOTA</id>
    BuiltIn.Should_Not_Contain    ${data}    <model>Camry</model>
    BuiltIn.Should_Not_Contain    ${data}    <manufacturer>Toyota</manufacturer>
    BuiltIn.Should_Not_Contain    ${data}    <year>1982</year>
    BuiltIn.Should_Not_Contain    ${data}    <category>sedan</category>

Add_Device_Data_Item_2_Via_JSON_Post
    [Documentation]    Send a JSON request to change the sample test data and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Post_As_Json_Templated    ${directory_with_template_folders}${/}item2    ${template_as_string}

Check_Item2_Is_Created
    [Documentation]    Get the device data as XML and make sure it matches the content posted as JSON in the previous case.
    ${data}=    Get_Config_Data
    BuiltIn.Should_Contain    ${data}    <id>SMALL</id>
    BuiltIn.Should_Contain    ${data}    <model>Isetta</model>
    BuiltIn.Should_Contain    ${data}    <manufacturer>BMW</manufacturer>
    BuiltIn.Should_Contain    ${data}    <year>1953</year>
    BuiltIn.Should_Contain    ${data}    <category>microcar</category>
    BuiltIn.Should_Contain    ${data}    <id>TOYOTA</id>
    BuiltIn.Should_Contain    ${data}    <model>Camry</model>
    BuiltIn.Should_Contain    ${data}    <manufacturer>Toyota</manufacturer>
    BuiltIn.Should_Contain    ${data}    <year>1982</year>
    BuiltIn.Should_Contain    ${data}    <category>sedan</category>

Delete_Device_Data
    [Documentation]    Send a request to delete the sample test data on the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Delete_Templated    ${directory_with_template_folders}${/}datamod1    ${template_as_string}
    TemplatedRequests.Delete_Templated    ${directory_with_template_folders}${/}item1    ${template_as_string}

Check_Device_Data_Is_Deleted
    [Documentation]    Get the device data and make sure it is empty again.
    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>

Deconfigure_Device_From_Netconf
    [Documentation]    Make request to deconfigure the testtool device on Netconf connector.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${device_name}

Check_Device_Going_To_Be_Gone_After_Deconfiguring
    [Documentation]    Check that the device is really going to be gone. Fail
    ...    if found after one minute. This is an expected behavior as the
    ...    delete request is sent to the config subsystem which then triggers
    ...    asynchronous destruction of the netconf connector referring to the
    ...    device and the device's data. This test makes sure this
    ...    asynchronous operation does not take unreasonable amount of time
    ...    by making sure that both the netconf connector and the device's
    ...    data is gone before reporting success.
    [Tags]    critical
    NetconfKeywords.Wait_Device_Fully_Removed    ${device_name}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool

Get_Config_Data
    [Documentation]    Get and return the config data from the device.
    ${url}=    Builtin.Set_Variable    ${CONFIG_API}/network-topology:network-topology/topology/topology-netconf/node/${device_name}/yang-ext:mount
    ${data}=    TemplatedRequests.Get_As_Xml_From_Uri    ${url}
    [Return]    ${data}

Check_Config_Data
    [Arguments]    ${expected}    ${contains}=False
    ${data}=    Get_Config_Data
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}
