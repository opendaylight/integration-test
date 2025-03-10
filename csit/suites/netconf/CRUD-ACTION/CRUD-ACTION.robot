*** Settings ***
Documentation       netconf-connector CRUD-Action test suite.
...
...                 Copyright (c) 2019 Ericsson Software Technology AB. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 Perform basic operations (Create, Read, Update and Delete or CRUD) on device
...                 data mounted onto a netconf connector using RPC for node supporting Yang 1.1
...                 addition and see if invoking Action Operation work.

Library             Collections
Library             RequestsLibrary
Library             OperatingSystem
Library             String
Library             SSHLibrary    timeout=10s
Resource            ${CURDIR}/../../../libraries/CompareStream.robot
Resource            ${CURDIR}/../../../libraries/FailFast.robot
Resource            ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource            ${CURDIR}/../../../variables/Variables.robot

Suite Setup         Setup_Everything
Suite Teardown      Teardown_Everything
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing


*** Variables ***
${DIRECTORY_WITH_TEMPLATE_FOLDERS}      ${CURDIR}/../../../variables/netconf/CRUD
${DEVICE_NAME}                          netconf-test-device
${DEVICE_TYPE_RPC}                      rpc-device
${DEVICE_TYPE_RPC_CREATE}               rpc-create-device
${DEVICE_TYPE_RPC_DELETE}               rpc-delete-device
${USE_NETCONF_CONNECTOR}                ${False}
${DELETE_LOCATION}                      delete_location
${RPC_FILE}                             ${CURDIR}/../../../variables/netconf/CRUD/customaction/customaction.xml


*** Test Cases ***
Check_Device_Is_Not_Configured_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    [Tags]    critical
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME}

Configure_Device_On_Netconf
    [Documentation]    Make request to configure a testtool device on Netconf connector.
    [Tags]    critical
    NetconfKeywords.Configure_Device_In_Netconf
    ...    ${DEVICE_NAME}
    ...    device_type=${DEVICE_TYPE_RPC_CREATE}
    ...    http_timeout=2
    ...    http_method=post

Check_ODL_Has_Netconf_Connector_For_Device
    [Documentation]    Get the list of configured devices and search for our device there. Fail if not found.
    [Tags]    critical
    ${count} =    NetconfKeywords.Count_Netconf_Connectors_For_Device    ${DEVICE_NAME}
    Builtin.Should_Be_Equal_As_Strings    ${count}    1

Wait_For_Device_To_Become_Connected
    [Documentation]    Wait until the device becomes available through Netconf.
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}

Check_Device_Data_Is_Empty
    [Documentation]    Get the device data and make sure it is empty.
    ${escaped} =    BuiltIn.Regexp_Escape    ${ODL_NETCONF_NAMESPACE}
    Check_Config_Data    <data xmlns\="${escaped}"(\/>|><\/data>)    ${True}

Invoke_Yang1.1_Action_Via_Xml_Post
    [Documentation]    Send a sample test data label into the device and check that the request went OK.
    ${mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=${device_name}    RESTCONF_ROOT=${RESTCONF_ROOT}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}dataorigaction
    ...    ${mapping}

Invoke_Yang1.1_Action_Via_Json_Post
    [Documentation]    Send a sample test data label into the device and check that the request went OK.
    ${mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=${device_name}    RESTCONF_ROOT=${RESTCONF_ROOT}
    TemplatedRequests.Post_As_Json_RFC8040_Templated
    ...    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}dataorigaction
    ...    ${mapping}

Invoke_Yang1.1_Augmentation_Via_Xml_Post
    [Documentation]    Send a sample test data label into the device and check that the request went OK.
    ${mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=${device_name}    RESTCONF_ROOT=${RESTCONF_ROOT}
    TemplatedRequests.Post_As_Xml_Templated    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}augment    ${mapping}

Invoke_Yang1.1_Augmentation_Via_Json_Post
    [Documentation]    Send a sample test data label into the device and check that the request went OK.
    ${mapping} =    BuiltIn.Create_Dictionary    DEVICE_NAME=${device_name}    RESTCONF_ROOT=${RESTCONF_ROOT}
    TemplatedRequests.Post_As_Json_RFC8040_Templated
    ...    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}augment
    ...    ${mapping}

Deconfigure_Device_From_Netconf
    [Documentation]    Make request to deconfigure the testtool device on Netconf connector.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Configure_Device_In_Netconf
    ...    ${DEVICE_NAME}
    ...    device_type=${DEVICE_TYPE_RPC_DELETE}
    ...    http_timeout=2
    ...    http_method=post

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
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME}


*** Keywords ***
Setup_Everything
    [Documentation]    Initialize SetupUtils. Setup everything needed for the test cases.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${REST_API}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords
    ${DEVICE_TYPE_RPC} =    BuiltIn.Set_Variable_If
    ...    """${USE_NETCONF_CONNECTOR}""" == """True"""
    ...    default
    ...    ${DEVICE_TYPE_RPC}
    OperatingSystem.File Should Exist    ${RPC_FILE}
    NetconfKeywords.Install_And_Start_Testtool
    ...    device-count=1
    ...    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas
    ...    rpc_config=${RPC_FILE}
    ...    mdsal=true

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool

Get_Config_Data
    [Documentation]    Get and return the config data from the device.
    ${url} =    Builtin.Set_Variable
    ...    ${REST_API}/network-topology:network-topology/topology=topology-netconf/node=${DEVICE_NAME}/yang-ext:mount?content=config
    ${data} =    TemplatedRequests.Get_As_Xml_From_Uri    ${url}
    RETURN    ${data}

Check_Config_Data
    [Arguments]    ${expected}    ${regex}=False    ${contains}=False
    ${data} =    Get_Config_Data
    IF    ${regex}
        BuiltIn.Should Match Regexp    ${data}    ${expected}
    ELSE IF    ${contains}
        BuiltIn.Should_Contain    ${data}    ${expected}
    ELSE
        BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    END
