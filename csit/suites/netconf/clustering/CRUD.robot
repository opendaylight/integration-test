*** Settings ***
Documentation     netconf-connector clustered CRUD test suite.
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
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${NODE_CONFIGURER}    node1
${NODE_SETTER}    node2
${NODE_CHECKER}    node3
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${device_name}    netconf-test-device

*** Test Cases ***
Check_Device_Is_Not_Mounted_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CHECKER}
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${device_name}

Configure_Device_On_Netconf
    [Documentation]    Make request to configure a testtool device on Netconf connector
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Configure_Device_In_Netconf    ${device_name}

Check_Configurer_Has_Netconf_Connector_For_Device
    [Documentation]    Get the list of mounts and search for our device there. Fail if not found.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CHECKER}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Netconf_Connector_Count    1

Wait_For_Device_To_Become_Visible_For_Configurer
    [Documentation]    Wait until the device becomes visible on checker node.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Wait_Device_Connected    ${device_name}

Wait_For_Device_To_Become_Visible_For_Checker
    [Documentation]    Wait until the device becomes visible on checker node.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CHECKER}
    NetconfKeywords.Wait_Device_Connected    ${device_name}

Wait_For_Device_To_Become_Visible_For_Setter
    [Documentation]    Wait until the device becomes visible on setter node.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    NetconfKeywords.Wait_Device_Connected    ${device_name}

Check_Device_Data_Is_Seen_As_Empty_On_Checker
    [Documentation]    Get the device data and make sure it is empty.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CHECKER}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4635

Check_Device_Data_Is_Seen_As_Empty_On_Setter
    [Documentation]    Get the device data and make sure it is empty.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4635

Check_Device_Data_Is_Seen_As_Empty_On_Configurer
    [Documentation]    Get the device data and make sure it is empty.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4635

Create_Device_Data
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    NetconfViaRestconf.Post_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}dataorig    ${template_as_string}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4635

Check_New_Device_Data_Is_Visible_On_Checker
    [Documentation]    Check that the created device data make their way into the checker node.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CHECKER}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud" xmlns:a="${ODL_NETCONF_NAMESPACE}" a:operation="replace"><l>Content</l></cont></data>
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4635

Check_New_Device_Data_Is_Visible_On_Setter
    [Documentation]    Get the device data and make sure it contains the created content.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud" xmlns:a="${ODL_NETCONF_NAMESPACE}" a:operation="replace"><l>Content</l></cont></data>
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4635

Check_New_Device_Data_Is_Visible_On_Configurer
    [Documentation]    Check that the created device data make their way into the configurer node.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud" xmlns:a="${ODL_NETCONF_NAMESPACE}" a:operation="replace"><l>Content</l></cont></data>
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4635

Deconfigure_Device_In_Netconf
    [Documentation]    Make request to deconfigure the device on Netconf connector.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Remove_Device_From_Netconf    ${device_name}

Check_Device_Going_To_Be_Deconfigured_On_Configurer
    [Documentation]    Check that the device is really going to be gone. Fail if still there after one minute.
    ...    This is an expected behavior as the unmount request is sent to the config subsystem which
    ...    then triggers asynchronous disconnection of the device which is reflected in the operational
    ...    data once completed. This test makes sure this asynchronous operation does not take
    ...    unreasonable amount of time.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Wait_Device_Fully_Removed    ${device_name}

Check_Device_Going_To_Be_Deconfigured_On_Checker
    [Documentation]    Check that the device is going to be gone from the checker node. Fail if still there after one minute.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CHECKER}
    NetconfKeywords.Wait_Device_Fully_Removed    ${device_name}

Check_Device_Going_To_Be_Deconfigured_On_Setter
    [Documentation]    Check that the device is going to be gone from the setter node. Fail if still there after one minute.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    NetconfKeywords.Wait_Device_Fully_Removed    ${device_name}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    NetconfViaRestconf.Create_NVR_Session    node1    ${ODL_SYSTEM_1_IP}
    NetconfViaRestconf.Create_NVR_Session    node2    ${ODL_SYSTEM_2_IP}
    NetconfViaRestconf.Create_NVR_Session    node3    ${ODL_SYSTEM_3_IP}
    # Connect to the Mininet machine
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    Utils.Flexible_Mininet_Login
    NetconfKeywords.Install_And_Start_Testtool    device-count=10    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Check_Netconf_Connector_Count
    [Arguments]    ${expected}
    ${count}    NetconfKeywords.Count_Netconf_Connectors_For_Device    ${device_name}
    Builtin.Should_Be_Equal_As_Strings    ${count}    ${expected}

Check_Config_Data
    [Arguments]    ${expected}    ${contains}=False
    ${url}=    Builtin.Set_Variable    network-topology:network-topology/topology/topology-netconf/node/${device_name}/yang-ext:mount
    ${data}=    Utils.Get_Data_From_URI    ${NODE_CHECKER}    ${url}    headers=${ACCEPT_XML}
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}
