*** Settings ***
Documentation     netconf cluster node outage test suite (CRUD operations).
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Perform one of the basic operations (Create, Read, Update and Delete or CRUD)
...               on device data mounted onto a netconf connector while one of the nodes is
...               down and see if they work. Then bring the dead node up and check that it sees
...               the operations that were made while it was down are visible on it as well.
...
...               The node is brought down before each of the "Create", "Update" and "Delete"
...               operations and brought and back up after these operations. Before the dead
...               node is brought up, a test case makes sure the operation is properly
...               propagated within the cluster.
...
...               Currently each of the 3 operations is done once. "Create" is done while
...               node 1 is down, "Update" while node 2 is down and "Delete" while node 3
...               is down.
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
${DEVICE_BOOT_TIMEOUT}    100s
${DEVICE_NAME}    netconf-test-device

*** Test Cases ***
Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Check_Device_Is_Not_Mounted_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME}    session=node1
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME}    session=node2
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME}    session=node3

Configure_Device_On_Netconf
    [Documentation]    Use node 1 to configure a testtool device on Netconf connector
    NetconfKeywords.Configure_Device_In_Netconf    ${DEVICE_NAME}    device_type=configure-via-topology    session=node1
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5089

Wait_For_Device_To_Become_Visible_For_All_Nodes
    [Documentation]    Check that the cluster communication about a new Netconf device configuration works
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node1
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node2
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node3

Check_Device_Data_Is_Seen_As_Empty_On_All_Nodes
    [Documentation]    Sanity check against possible data left-overs from previous suites. Also causes the suite to wait until the entire cluster sees the device and its data mount.
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node1
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node2
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node3
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${empty_data}

Kill_node1_Before_Create
    [Documentation]    Simulate node 1 crashes just before device data is created, fail if node 1 survives.
    ClusterManagement.Kill_Single_Member    1

Create_Device_Data_With_node1_Down
    [Documentation]    Check that the create requests work when node 1 is down.
    [Tags]    critical
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}dataorig    {'DEVICE_NAME': '${DEVICE_NAME}'}    session=node2

Check_New_Device_Data_Is_Visible_On_Nodes_Without_node1
    [Documentation]    Check that the new device data is propagated in the cluster even when node 1 is down.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${original_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${original_data}

Restart_node1_After_Create_And_Dump_Its_Topology_Data
    [Documentation]    Simulate node 1 restarted by admin just after device data is created and the change propagated in the cluster, fail if node 1 fails to boot.
    ClusterManagement.Start_Single_Member    1
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node1

Check_New_Device_Data_Is_Visible_On_node1
    [Documentation]    Check that the created device data is propagated to node 1 as well.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node1    ${original_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5761

Kill_node2_Before_Modify
    [Documentation]    Simulate node 2 crashes just before device data is modified, fail if node 2 survives.
    ClusterManagement.Kill_Single_Member    2

Modify_Device_Data_With_node2_Down
    [Documentation]    Check that the modification requests work when node 2 is down.
    [Tags]    critical
    TemplatedRequests.Put_As_Xml_Templated    ${directory_with_template_folders}${/}datamod1    {'DEVICE_NAME': '${DEVICE_NAME}'}    session=node3
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5762

Check_Modified_Device_Data_Is_Visible_On_Nodes_Without_node2
    [Documentation]    Check that the device data modification is propagated in the cluster even when node 2 is down.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${modified_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${modified_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5762

Restart_node2_After_Modify_And_Dump_Its_Topology_Data
    [Documentation]    Simulate node 2 restarted by admin just after device data is modified and the change propagated in the cluster, fail if node 2 fails to boot.
    ClusterManagement.Start_Single_Member    2
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node2

Check_Modified_Device_Data_Is_Visible_On_node2
    [Documentation]    Check that the device data modification is propagated to node 2 as well.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node2    ${modified_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5761

Kill_node3_Before_Delete
    [Documentation]    Simulate node 3 crashes just before device data is deleted, fail if node 3 survives.
    ClusterManagement.Kill_Single_Member    3

Delete_Device_Data_With_node3_Down
    [Documentation]    Check that the data removal requests work when node 3 is down.
    [Tags]    critical
    TemplatedRequests.Delete_Templated    ${directory_with_template_folders}${/}datamod1    {'DEVICE_NAME': '${DEVICE_NAME}'}    session=node1
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5762

Check_Device_Data_Removal_Is_Visible_On_Nodes_Without_node3
    [Documentation]    Check that the device data removal is propagated in the cluster even when node 3 is down.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${empty_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5762

Restart_node3_After_Delete_And_Dump_Its_Topology_Data
    [Documentation]    Simulate node 3 restarted by admin just after device data is deleted and the change propagated in the cluster, fail if node 3 fails to boot.
    ClusterManagement.Start_Single_Member    3
    ${config_topology}    ${operational_topology}=    Get_Topology    session=node3

Check_Device_Data_Removal_Is_Visible_On_node3
    [Documentation]    Check that the device data removal is propagated to node 3 as well.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Check_Config_Data    node3    ${empty_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5761

Deconfigure_Device_In_Netconf
    [Documentation]    Make request to deconfigure the device on Netconf connector to clean things up and also check that it still works after all the node outages.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME}    session=node1

Check_Device_Deconfigured
    [Documentation]    Check that the device deconfiguration is propagated throughout the cluster correctly.
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
    # TODO: Refactor the suite to use ClusterManagement.Resolve_Http_Session_For_Member instead of these 3 "hardcoded" sessions.
    RequestsLibrary.Create_Session    node1    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node3    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    BuiltIn.Set_Suite_Variable    ${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
    BuiltIn.Set_Suite_Variable    ${empty_data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>
    BuiltIn.Set_Suite_Variable    ${original_data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Content</l></cont></data>
    BuiltIn.Set_Suite_Variable    ${modified_data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Modified Content</l></cont></data>
    ${url}=    Builtin.Set_Variable    /network-topology:network-topology/topology/topology-netconf
    BuiltIn.Set_Suite_Variable    ${config_topology_url}    ${CONFIG_API}${url}
    BuiltIn.Set_Suite_Variable    ${operational_topology_url}    ${OPERATIONAL_API}${url}

Get_Topology_Core
    [Arguments]    ${session}
    [Documentation]    Get both versions of topology (config and operational), log them and return them for further processing.
    ${config_topology}=    TemplatedRequests.Get_As_Json_From_Uri    ${config_topology_url}    session=${session}
    BuiltIn.Log    ${config_topology}
    ${operational_topology}=    TemplatedRequests.Get_As_Json_From_Uri    ${operational_topology_url}    session=${session}
    BuiltIn.Log    ${operational_topology}
    [Return]    ${config_topology}    ${operational_topology}

Get_Topology
    [Arguments]    ${session}
    [Documentation]    Repeatedly try to get the topologies using Get_Topology_Core until either the request succeeds or boot timeout period expires.
    ${result}=    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_BOOT_TIMEOUT}    1s    Get_Topology_Core    ${session}
    [Return]    ${result}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Check_Device_Instance_Count
    [Arguments]    ${expected}    ${session}
    [Documentation]    Check that the specified session sees the specified count of instances of the test tool device.
    ${count}    NetconfKeywords.Count_Netconf_Connectors_For_Device    ${DEVICE_NAME}    session=${session}
    Builtin.Should_Be_Equal_As_Strings    ${count}    ${expected}

Check_Config_Data
    [Arguments]    ${node}    ${expected}    ${contains}=False
    [Documentation]    Check that the specified session sees the specified data in the test tool device.
    ${url}=    Builtin.Set_Variable    ${CONFIG_API}/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount
    ${data}=    TemplatedRequests.Get_As_Xml_From_Uri    ${url}    session=${node}
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}
