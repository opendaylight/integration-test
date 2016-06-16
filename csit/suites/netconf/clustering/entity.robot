*** Settings ***
Documentation     Test suite for netconf device entity ownership handling during outages.
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
...               The suite recognizes 3 nodes, "CONFIGURER" (the node that configures the
...               device at the beginning and then deconfigures it at the end), "SETTER" (the
...               node that manipulates the data on the device) and "CHECKER" (the node that
...               checks the data on the device). The configured device and the results of each
...               data operation on it is expected to be visible on all nodes so after each
...               operation three test cases make sure they can see the result on their
...               respective nodes.
...
...               The 3 nodes are configured by placing "node1", "node2" or "node3" into the
...               ${NODE_CONFIGURER}, ${NODE_SETTER} and ${NODE_CHECKER} to make the node
...               a "CONFIGURER", "SETTER" and "CHECKER" respectively. The "nodeX" name refers
...               to the node with its IP address configured with the ${ODL_SYSTEM_X_IP}
...               variable where the "X" is 1, 2 or 3.
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
Resource          ${CURDIR}/../../../libraries/ClusterKeywords.robot
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
${CLUSTER_RECOVERY_TIMEOUT}    120s
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
    [Documentation]    Use node 1 to configure a testtool device on Netconf connector.
    NetconfKeywords.Configure_Device_In_Netconf    ${DEVICE_NAME}    device_type=configure-via-topology    session=node1
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5089

Wait_For_Device_To_Become_Visible_For_All_Nodes
    [Documentation]    Wait for the whole cluster to see the device.
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node1
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node2
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}    session=node3

Check_Config_Data_Before_Data_Creation
    [Documentation]    Check if there really is no data present on none of the nodes
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${empty_data}

Create_Device_Data
    [Documentation]    Create some data on the device and propagate it throughout the cluster.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_template_folders}${/}dataorig    ${template_as_string}    session=node2

Check_Config_Data_After_Data_Creation
    [Documentation]    Check if the data we just added into the cluster is really there
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${original_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${original_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${original_data}

Find_And_Shutdown_Device_Entity_Owner
    [Documentation]    Simulate a failure of the owner of the entity that represents the device.
    ${owner}    ${followers}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    node1    netconf    ${DEVICE NAME}
    Log    ${followers}
    Length Should Be    ${followers}    2    Wrong count of followers returned
    BuiltIn.Set_Suite_Variable    ${original_device_owner}    ${owner}
    BuiltIn.Set_Suite_Variable    ${follower1}    @{followers}[0]
    BuiltIn.Set_Suite_Variable    ${follower2}    @{followers}[1]
    ClusterManagement.Kill_Single_Member    ${owner}

Wait_For_New_Owner_To_Appear
    [Documentation]    Wait for the cluster to recover from the failure and choose a new owner for the entity.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    ${CLUSTER_RECOVERY_TIMEOUT}    1s    Check_Owner_Reconfigured

Check_Config_Data_Before_Modification_With_Original_Owner_Down
    [Documentation]    Check if data is present and retrievable from follower nodes
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node${follower1}    ${original_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node${follower2}    ${original_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    6067

Modify_Device_Data_When_Original_Owner_Is_Down
    [Documentation]    Attempt to modify the data on the device after recovery and see if it still works.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Put_As_Xml_Templated    ${directory_with_template_folders}${/}datamod1    ${template_as_string}    session=node${follower1}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Config_Data_After_Modification_With_Original_Owner_Down
    [Documentation]    Check if data is written correctly when original owner is shut down
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node${follower1}    ${modified_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node${follower2}    ${modified_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    6067

Restart_Original_Entity_Owner
    [Documentation]    Restart the original entity owner and see if it can still see the device and the new data on it.
    ClusterManagement.Start_Single_Member    ${original_device_owner}

Check_Config_Data_After_Original_Owner_Restart
    [Documentation]    Sanity check if we still can retrieve our data from the original device owner (node${original_device_owner}).
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node${original_device_owner}    ${modified_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5761

Modify_Device_Data_With_Original_Owner
    [Documentation]    Check that the original owner of the entity is still able to modify the data on the device
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Put_As_Xml_Templated    ${directory_with_template_folders}${/}datamod2    ${template_as_string}    session=node${original_device_owner}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5761

Check_Config_Data_After_Modification_With_Original_Owner_Up
    [Documentation]    Check if data has really been written as we expect. Fails if Modify_Device_Data_With_Original_Owner fails.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node1    ${modified_data_2}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node2    ${modified_data_2}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    node3    ${modified_data_2}

Deconfigure_Device_In_Netconf
    [Documentation]    Make request to deconfigure the device on Netconf connector and see if it works.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME}    session=node1
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
    ClusterKeywords.Create_Controller_Sessions
    # TODO: Refactor the suite to use ClusterManagement.Resolve_Http_Session_For_Member instead of these 3 "hardcoded" sessions.
    RequestsLibrary.Create_Session    node1    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node3    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    # Constants that are not meant to be overriden by the users
    BuiltIn.Set_Suite_Variable    ${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
    BuiltIn.Set_Suite_Variable    ${empty_data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>
    ${cont}=    BuiltIn.Set_Variable    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>
    ${contend}=    BuiltIn.Set_Variable    </l></cont></data>
    BuiltIn.Set_Suite_Variable    ${original_data}    ${cont}Content${contend}
    BuiltIn.Set_Suite_Variable    ${modified_data}    ${cont}Modified Content${contend}
    BuiltIn.Set_Suite_Variable    ${modified_data_2}    ${cont}Another Modified Content${contend}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Check_Config_Data
    [Arguments]    ${node}    ${expected}    ${contains}=False
    [Documentation]    Check that the data on the device matches the specified expectations.
    ...    TODO: Needs to be extracted into a suitable Resource as there is
    ...    the same code in at least two other suites (CRUD and clustered
    ...    CRUD).
    ${url}=    Builtin.Set_Variable    ${CONFIG_API}/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount
    ${data}=    TemplatedRequests.Get_As_Xml_From_Uri    ${url}    session=${node}
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}

Check_Owner_Reconfigured
    [Documentation]    Check whether the entity owner changed. Fail if not or no owner found.
    Log    Original Owner Index: ${original_device_owner}
    Log    Follower 1: node${follower1}
    Log    Follower 2: node${follower2}
    ${owner}    ${candidates}=    ClusterKeywords.Get_Device_Entity_Owner_And_Candidates_Indexes    node${follower1}    netconf    ${DEVICE_NAME}
    BuiltIn.Should_Not_Be_Equal_As_Integers    ${owner}    ${original_device_owner}
