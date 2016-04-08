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
...               data mounted onto a netconf connector and see if they work. The difference
...               is that one of the cluster nodes is down at the time when the operation is
...               attempted (this includes configuring and then deconfiguring the device).
...               The suite then brings the dead node up and makes sure that all 3 node see
...               the operation (including the failing node).
...
...               The suite recognizes 3 node roles, "CONFIGURER" (the node that configures the
...               device at the beginning and then deconfigures it at the end), "SETTER" (the
...               node that manipulates the data on the device) and "CHECKER" (the node that
...               checks the data on the device; this one is also the one that is brought down
...               before the operation and brought back up after it completes). The configured
...               devices and the results of each data operation on them are expected to be
...               visible on all nodes so after each operation three checks make sure the three
...               node can see these results.
...
...               This test suite uses 3 devices. Each one has the "CONFIGURER", "SETTER" and
...               "CHECKER" node set to different node (first device has CONFIGURER=1, SETTER=2
...               and CHECKER=3, second has CONFIGURER=2, SETTER=3 and CHECKER=1 and third has
...               CONFIGURER=3, SETTER=1 and CHECKER=2). These node numbers are hardcoded like
...               this because for this suite it makes little sense to make them configurable.
...               Additionally, the 3 nodes must run on 3 different physical machines,
...               othwerwise the suite will break down. Also the testtool (which is used to
...               simulate the devices) must run on a machine different from the 3 machines
...               where ODL is running.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_CHECK_TIMEOUT}    60s
${DEVICE_NAME_PREFIX}    netconf-test-device
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${empty_data}     <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>
${original_data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Content</l></cont></data>
${modified_data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"><cont xmlns="urn:opendaylight:test:netconf:crud"><l>Modified Content</l></cont></data>

*** Test Cases ***
Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    NetconfKeywords.Install_And_Start_Testtool    device-count=3    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Check_Devices_Are_Not_Configured_At_Beginning
    [Documentation]    Sanity check making sure our devices are not on any node. Fail if any found anywhere.
    [Tags]    critical
    Check_Device_Not_Visible    1
    Check_Device_Not_Visible    2
    Check_Device_Not_Visible    3

Configure_Devices
    ClusterManagement.Kill_Member    3
    Configure_Device    1
    ClusterManagement.Start_Member    3
    ClusterManagement.Kill_Member    1
    Configure_Device    2
    ClusterManagement.Start_Member    1
    ClusterManagement.Kill_Member    2
    Configure_Device    3
    ClusterManagement.Start_Member    2

Check_Devices_Configured_And_Connected
    Check_Device_Ready    1
    Check_Device_Ready    2
    Check_Device_Ready    3

Deconfigure_Devices
    ClusterManagement.Kill_Member    3
    Deconfigure_Device    1
    ClusterManagement.Start_Member    3
    ClusterManagement.Kill_Member    1
    Deconfigure_Device    2
    ClusterManagement.Start_Member    1
    ClusterManagement.Kill_Member    2
    Deconfigure_Device    3
    ClusterManagement.Start_Member    2

Check_Devices_Deconfigured
    Check_Device_Gone    1
    Check_Device_Gone    2
    Check_Device_Gone    3

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords    create_session_for_templated_requests=False
    RequestsLibrary.Create_Session    node1    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    RequestsLibrary.Create_Session    node3    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Check_Device_Not_Visible
    [Arguments]    ${number}
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME_PREFIX}-${number}    session=node1
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME_PREFIX}-${number}    session=node2
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME_PREFIX}-${number}    session=node3

Configure_Device
    [Arguments]    ${number}
    NetconfKeywords.Configure_Device_In_Netconf    ${DEVICE_NAME_PREFIX}-${number}    device_type=configure-via-topology    session=node${number}
    ${count}=    NetconfKeywords.Count_Netconf_Connectors_For_Device    ${DEVICE_NAME_PREFIX}-${number}    session=node${number}
    Builtin.Should_Be_Equal_As_Integers    ${count}    1
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME_PREFIX}-${number}    session=node${number}

Check_Device_Ready
    [Arguments]    ${number}
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME_PREFIX}-${number}    session=node1
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME_PREFIX}-${number}    session=node2
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME_PREFIX}-${number}    session=node3

Check_Config_Data
    [Arguments]    ${number}    ${node}    ${expected}    ${contains}=False
    ${url}=    Builtin.Set_Variable    ${CONFIG_API}/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME_PREFIX}-${number}/yang-ext:mount
    ${data}=    TemplatedRequests.Get_As_Xml_From_Uri    ${url}    session=${node}
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}

Wait_For_Device_Data_To_Become_Visible
    [Arguments]    ${number}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${number}    node1    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${number}    node2    ${empty_data}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${number}    node3    ${empty_data}

Deconfigure_Device
    [Arguments]    ${number}
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME_PREFIX}-${number}    session=node${number}
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME_PREFIX}-${number}    session=node${number}

Check_Device_Gone
    [Arguments]    ${number}
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME_PREFIX}-${number}    session=node1
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME_PREFIX}-${number}    session=node2
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME_PREFIX}-${number}    session=node3
