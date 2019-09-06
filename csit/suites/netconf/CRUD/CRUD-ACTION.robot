*** Settings ***
Documentation     netconf-connector CRUD-Action test suite.
...
...               Copyright (c) 2019  Ericsson Software Technology AB. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Perform basic operations (Create, Read, Update and Delete or CRUD) on device
...               data mounted onto a netconf connector using RPC for node supporting Yang 1.1
...               addition and see if invoking Action Operation work.

Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../variables/Variables.robot

*** Variables ***
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${device_name}    netconf-test-device
${device_type_rpc}    rpc-device
${device_type_rpc_create}    rpc-create-device
${device_type_rpc_delete}    rpc-delete-device
${USE_NETCONF_CONNECTOR}    ${False}
${delete_location}    delete_location
${stdout}
${rpc_folder}    ${CURDIR}/../../../variables/netconf/CRUD/customaction/
${rpc_file}    ${CURDIR}/../../../variables/netconf/CRUD/customaction/customaction.xml



*** Test Cases ***
Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    # OperatingSystem.Run and Return RC and Output    @{stdout}=    ls -l ${CURDIR}/../../../variables/netconf/CRUD/customaction/customaction.xml
    ${stdout}=    SSHLibrary.Execute Command    ls ${directory_with_template_folders}
    # @{files}=    SSHLibrary.List Files In Directory    ${rpc_folder}
    # BuiltIn.Log To Console    @{files}
    # @{files1}=    SSHLibrary.List Directories In Directory    ${directory_with_template_folders}
    BuiltIn.Log To Console    ${stdout}
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas    rpc_config=${rpc_file}

Check_Device_Is_Not_Configured_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    [Tags]    critical
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${device_name}

Configure_Device_On_Netconf
    [Documentation]    Make request to configure a testtool device on Netconf connector.
    [Tags]    critical
    NetconfKeywords.Configure_Device_In_Netconf    ${device_name}    device_type=${device_type}    http_timeout=2    http_method=post

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
    Run_Keyword_If_Less_Than_Neon    Check_Config_Data    <data xmlns\="${ODL_NETCONF_NAMESPACE}"></data>
    Run_Keyword_If_At_Least_Neon    Check_Config_Data    <data xmlns\="${ODL_NETCONF_NAMESPACE}"/>

Invoke_Yang1.1_Action_Via_Xml_Post
    [Documentation]    Send a sample test data label into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}dataorigaction    ${template_as_string}

Invoke_Yang1.1_Action_Via_Json_Post
    [Documentation]    Send a sample test data label into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    TemplatedRequests.Post_As_Json_RFC8040_Templated    ${directory_with_template_folders}${/}dataorigaction    ${template_as_string}

*** Keywords ***
Setup_Everything
    [Documentation]    Initialize SetupUtils. Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords
    ${device_type_rpc}=    BuiltIn.Set_Variable_If    """${USE_NETCONF_CONNECTOR}""" == """True"""    default    ${device_type_rpc}
    ${device_type}    CompareStream.Set_Variable_If_At_Most_Nitrogen    ${device_type_rpc}    ${device_type_rpc_create}
    BuiltIn.Set_Suite_Variable    ${device_type}

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
