*** Settings ***
Documentation     netconf clustered CRUD test suite.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Perform basic operations (Create, Read, Update and Delete or CRUD) on device
...               data mounted onto a netconf connector and see if they work.
...
...               The suite checks the integrity of the presence of the device and the data
...               seen on the device only for nodes that have at least one of the roles
...               ("CONFIGURER", "SETTER" and "CHECKER") assigned. A better design would have
...               a "checker list" of sorts and have only one checking test case that runs
...               through the check list and performs the test on each node listed. However
...               this currently has fairly low priority due to Beryllium delivery date so
...               it was left out.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_CHECK_TIMEOUT}    60s
${DEVICE_BOOT_TIMEOUT}    300s
${DEVICE_NAME}    netconf-test-device
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${empty_data}     <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>
${original_data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Content</l></cont></data>
${modified_data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Modified Content</l></cont></data>

*** Test Cases ***
Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Check_Device_Is_Not_Mounted_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    [Tags]    critical
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME}    session=node1
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME}    session=node2
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME}    session=node3

Configure_Device_On_Netconf
    [Documentation]    Make request to configure a testtool device on Netconf connector
    [Tags]    critical
    NetconfKeywords.Configure_Device_In_Netconf    ${DEVICE_NAME}    device_type=configure-via-topology    session=node1
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5089

Check_Configurer_Has_Netconf_Connector_For_Device
    [Documentation]    Get the list of mounts and search for our device there. Fail if not found.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Device_Instance_Count    1    session=node1

Wait_For_Device_To_Become_Visible_For_all_nodes
    [Documentation]    Wait until the device becomes visible on all nodes.
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node1
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node2
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node3

Check_Device_Data_Is_Seen_As_Empty_On_all_nodes
    [Documentation]    Ensure the device data is seen by all nodes as empty.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${empty_data}
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node1
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${empty_data}
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node2
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${empty_data}
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node3

Kill_node1_Before_Create
    ClusterManagement.Kill_Single_Member    1

Create_Device_Data_With_node1_Down
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}dataorig    ${template_as_string}    session=node2

Check_New_Device_Data_Is_Visible_On_Nodes_Without_node1
    [Documentation]    Get the device data and make sure it contains the created content.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${original_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${original_data}

Restart_node1_After_Create
    ClusterManagement.Start_Single_Member    1
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node1

Check_New_Device_Data_Is_Visible_On_node1
    [Documentation]    Check that the created device data make their way into node 1.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node1    ${original_data}

Kill_node1_Before_Delete
    ClusterManagement.Kill_Single_Member    1

Delete_Device_Data_With_node1_Down
    [Documentation]    Send a request to delete the sample test data on the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Delete_Templated    ${directory_with_template_folders}${/}datamod1    ${template_as_string}    session=node2
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Device_Data__Deletion_Is_Visible_On_Nodes_Without_node1
    [Documentation]    Get the device data and make sure it is empty again.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${empty_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Restart_node1_After_Delete
    ClusterManagement.Start_Single_Member    1
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node1

Check_Device_Data__Deletion_Is_Visible_On_node1
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node1    ${empty_data}

Kill_node2_Before_Create
    ClusterManagement.Kill_Single_Member    2

Create_Device_Data_With_node2_Down
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}dataorig    ${template_as_string}    session=node3

Check_New_Device_Data_Is_Visible_On_Nodes_Without_node2
    [Documentation]    Get the device data and make sure it contains the created content.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${original_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${original_data}

Restart_node2_After_Create
    ClusterManagement.Start_Single_Member    2
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node2

Check_New_Device_Data_Is_Visible_On_node2
    [Documentation]    Check that the created device data make their way into node 2.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node2    ${original_data}

Kill_node2_Before_Delete
    ClusterManagement.Kill_Single_Member    2

Delete_Device_Data_With_node2_Down
    [Documentation]    Send a request to delete the sample test data on the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Delete_Templated    ${directory_with_template_folders}${/}datamod1    ${template_as_string}    session=node3
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Device_Data__Deletion_Is_Visible_On_Nodes_Without_node2
    [Documentation]    Get the device data and make sure it is empty again.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${empty_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Restart_node2_After_Delete
    ClusterManagement.Start_Single_Member    2
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node2

Check_Device_Data__Deletion_Is_Visible_On_node2
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node2    ${empty_data}

Kill_node3_Before_Create
    ClusterManagement.Kill_Single_Member    3

Create_Device_Data_With_node3_Down
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}dataorig    ${template_as_string}    session=node1

Check_New_Device_Data_Is_Visible_On_Nodes_Without_node3
    [Documentation]    Get the device data and make sure it contains the created content.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${original_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${original_data}

Restart_node3_After_Create
    ClusterManagement.Start_Single_Member    3
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node3

Check_New_Device_Data_Is_Visible_On_node3
    [Documentation]    Check that the created device data make their way into node 3.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node3    ${original_data}

Kill_node3_Before_Delete
    ClusterManagement.Kill_Single_Member    3

Delete_Device_Data_With_node3_Down
    [Documentation]    Send a request to delete the sample test data on the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Delete_Templated    ${directory_with_template_folders}${/}datamod1    ${template_as_string}    session=node1
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Device_Data__Deletion_Is_Visible_On_Nodes_Without_node3
    [Documentation]    Get the device data and make sure it is empty again.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${empty_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Restart_node3_After_Delete
    ClusterManagement.Start_Single_Member    3
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node3

Check_Device_Data__Deletion_Is_Visible_On_node3
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node3    ${empty_data}

Deconfigure_Device_In_Netconf
    [Documentation]    Make request to deconfigure the device on Netconf connector.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME}    session=node1

Check_Device_Deconfigured
    [Tags]    critical
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME}    session=node1
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME}    session=node2
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME}    session=node3

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    NetconfKeywords.Setup_Netconf_Keywords    create_session_for_templated_requests=False
    RequestsLibrary.Create_Session    node1    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node3    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}

Get_Topology
    [Arguments]    ${session}
    ${url}=    /network-topology:network-topology/topology/topology-netconf
    ${config_topology}=    TemplatedRequests.Get_As_Json_From_Uri    ${CONFIG_API}${url}    session=${session}
    BuiltIn.Log    ${config_topology}
    ${operational_topology}=    TemplatedRequests.Get_As_Json_From_Uri    ${OPERATIONAL_API}${url}    session=${session}
    BuiltIn.Log    ${operational_topology}
    [Return]    ${config_topology}    ${operational_topology}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Check_Device_Instance_Count
    [Arguments]    ${expected}    ${session}
    ${count}    NetconfKeywords.Count_Netconf_Connectors_For_Device    ${DEVICE_NAME}    session=${session}
    Builtin.Should_Be_Equal_As_Strings    ${count}    ${expected}

Check_Config_Data
    [Arguments]    ${node}    ${expected}    ${contains}=False
    ${url}=    Builtin.Set_Variable    ${CONFIG_API}/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount
    ${data}=    TemplatedRequests.Get_As_Xml_From_Uri    ${url}    session=${node}
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}
