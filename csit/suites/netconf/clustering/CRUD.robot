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
${DEVICE_CHECK_TIMEOUT}    60s
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
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${DEVICE_NAME}

Configure_Device_On_Netconf
    [Documentation]    Make request to configure a testtool device on Netconf connector
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Configure_Device_In_Netconf    ${DEVICE_NAME}    device_type=configure-via-topology
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5089

Check_Configurer_Has_Netconf_Connector_For_Device
    [Documentation]    Get the list of mounts and search for our device there. Fail if not found.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Device_Instance_Count    1

Wait_For_Device_To_Become_Visible_For_Configurer
    [Documentation]    Wait until the device becomes visible on configurer node.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}

Wait_For_Device_To_Become_Visible_For_Checker
    [Documentation]    Wait until the device becomes visible on checker node.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CHECKER}
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}

Wait_For_Device_To_Become_Visible_For_Setter
    [Documentation]    Wait until the device becomes visible on setter node.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}

Check_Device_Data_Is_Seen_As_Empty_On_Configurer
    [Documentation]    Get the device data as seen by configurer and make sure it is empty.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${NODE_CONFIGURER}    ${empty_data}

Check_Device_Data_Is_Seen_As_Empty_On_Checker
    [Documentation]    Get the device data as seen by checker and make sure it is empty.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${NODE_CHECKER}    ${empty_data}

Check_Device_Data_Is_Seen_As_Empty_On_Setter
    [Documentation]    Get the device data as seen by setter and make sure it is empty.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${NODE_SETTER}    ${empty_data}

Test_Entity_Ownership_Data_1
    ${data}=    Utils.Get Data From URI    node1    ${CONFIG_API}/restconf/operational/entity-owners:entity-owners
    Log    ${data}

Test_Entity_Ownership_Data_2
    ${data}=    Utils.Get Data From URI    node1    ${OPERATIONAL_API}/restconf/operational/entity-owners:entity-owners
    Log    ${data}

Create_Device_Data
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    NetconfViaRestconf.Post_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}dataorig    ${template_as_string}

Check_New_Device_Data_Is_Visible_On_Setter
    [Documentation]    Get the device data and make sure it contains the created content.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${NODE_SETTER}    ${original_data}

Check_New_Device_Data_Is_Visible_On_Checker
    [Documentation]    Check that the created device data make their way into the checker node.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${NODE_CHECKER}    ${original_data}

Check_New_Device_Data_Is_Visible_On_Configurer
    [Documentation]    Check that the created device data make their way into the configurer node.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEVICE_CHECK_TIMEOUT}    1s    Check_Config_Data    ${NODE_CONFIGURER}    ${original_data}

Modify_Device_Data
    [Documentation]    Send a request to change the sample test data and check that the request went OK.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    NetconfViaRestconf.Put_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}datamod1    ${template_as_string}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Device_Data_Is_Modified
    [Documentation]    Get the device data and make sure it contains the modified content.
    Check_Config_Data    ${NODE_SETTER}    ${modified_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Modified_Device_Data_Is_Visible_On_Checker
    [Documentation]    Check that the modified device data make their way into the checker node.
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    ${NODE_CHECKER}    ${modified_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Modified_Device_Data_Is_Visible_On_Configurer
    [Documentation]    Check that the modified device data make their way into the configurer node.
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    ${NODE_CONFIGURER}    ${modified_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Delete_Device_Data
    [Documentation]    Send a request to delete the sample test data on the device and check that the request went OK.
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    NetconfViaRestconf.Delete_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}datamod1    ${template_as_string}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Device_Data_Is_Deleted
    [Documentation]    Get the device data and make sure it is empty again.
    Check_Config_Data    ${NODE_SETTER}    ${empty_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Device_Data_Deletion_Is_Visible_On_Checker
    [Documentation]    Check that the device data deletion makes its way into the checker node.
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    ${NODE_CHECKER}    ${empty_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Check_Device_Data_Deletion_Is_Visible_On_Configurer
    [Documentation]    Check that the device data deletion makes its way into the checker node.
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Config_Data    ${NODE_CONFIGURER}    ${empty_data}
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4968

Deconfigure_Device_In_Netconf
    [Documentation]    Make request to deconfigure the device on Netconf connector.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME}

Check_Device_Deconfigured_On_Configurer
    [Documentation]    Check that the device is really going to be gone. Fail if still there after one minute.
    ...    This is an expected behavior as the unmount request is sent to the config subsystem which
    ...    then triggers asynchronous disconnection of the device which is reflected in the operational
    ...    data once completed. This test makes sure this asynchronous operation does not take
    ...    unreasonable amount of time.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CONFIGURER}
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME}

Check_Device_Deconfigured_On_Checker
    [Documentation]    Check that the device is going to be gone from the checker node. Fail if still there after one minute.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_CHECKER}
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME}

Check_Device_Deconfigured_On_Setter
    [Documentation]    Check that the device is going to be gone from the setter node. Fail if still there after one minute.
    [Tags]    critical
    NetconfViaRestconf.Activate_NVR_Session    ${NODE_SETTER}
    NetconfKeywords.Wait_Device_Fully_Removed    ${DEVICE_NAME}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    NetconfViaRestconf.Create_NVR_Session    node1    ${ODL_SYSTEM_1_IP}
    NetconfViaRestconf.Create_NVR_Session    node2    ${ODL_SYSTEM_2_IP}
    NetconfViaRestconf.Create_NVR_Session    node3    ${ODL_SYSTEM_3_IP}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Check_Device_Instance_Count
    [Arguments]    ${expected}
    ${count}    NetconfKeywords.Count_Netconf_Connectors_For_Device    ${DEVICE_NAME}
    Builtin.Should_Be_Equal_As_Strings    ${count}    ${expected}

Check_Config_Data
    [Arguments]    ${node}    ${expected}    ${contains}=False
    NetconfViaRestconf.Activate_NVR_Session    ${node}
    ${url}=    Builtin.Set_Variable    network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount
    ${data}=    NetconfViaRestconf.Get_Config_Data_From_URI    ${url}    headers=${ACCEPT_XML}
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}
