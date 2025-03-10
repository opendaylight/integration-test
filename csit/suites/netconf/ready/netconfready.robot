*** Settings ***
Documentation       netconf-connector readiness test suite.
...
...                 Copyright (c) 2015,2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 Try to detect whether Netconf is up and running and wait for
...                 it for a configurable time if it is not yet up and running.
...
...                 This is achieved by the test Check_Whether_Netconf_Topology_Is_Ready. This test case
...                 does not use controller-config device. This test case is skipped (Pass Execution) if
...                 the usage of controller-config device is indicated.
...                 Testing itself is done by creating a netconf test device configured
...                 to all odl nodes one by one and check if GET works from mounted
...                 device. GET is done from all the odl nodes and it works for both, 1 or 3 nodes
...                 setup.
...
...                 The next test cases are basically dedicated to test readiness of the netconf using
...                 controller-config device. This device is created when odl-netconf-connector-ssh|all
...                 feature is installed. Robot variable USE_NETCONF_CONNECTOR should be set to True.
...                 Connector test cases change behavior depending on ${USE_NETCONF_CONNECTOR}. If True,
...                 they check data mounted behind controller-config is readable, if False they only check
...                 topology-netconf is readable.
...
...                 Some testsuites expect netconf-connector to be ready as soon as possible and will
...                 fail if it is not. We want to see a failure if this is the cause of the failure.
...
...
...                 The usage of netconf-connector happens in other suites than netconf,
...                 especially bgpcep to configure odl's bgp peers. Testing the readiness
...                 of the netconf-connector must be invoked by the Robot invocation
...                 argument USE_NETCONF_CONNECTOR. By default it is set to False and
...                 test jobs should be responsible to set it to True if needed. In the
...                 default configuration the affected test cases waits for the netconf
...                 topology to appear only.
...
...                 If the netconf-connector is not ready upon startup and it's usage is set
...                 to True (as seen by the second test case failing), the next case starts
...                 to repeat the query for a minute to see whether it is going "to fix itself"
...                 within the minute. If yes, then the testcase will pass, which
...                 indicates that the "ODL cooldown" of 1 minute is not long enough
...                 to allow for netconf-connector to initialize properly.
...                 If this fails, one more check with even longer timeout is run.
...                 If the Check_Whether_Netconf_Is_Up_And_Running pass, then the next test
...                 case does nothing.
...
...                 The other test case then checks whether Netconf can pretty print
...                 data. This sometimes makes problems, most likely due to too
...                 new Robot Requests library with an interface incompatible with
...                 this test suite.

Resource            ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource            ${CURDIR}/../../../libraries/CompareStream.robot
Resource            ${CURDIR}/../../../libraries/KarafKeywords.robot
Library             RequestsLibrary
Resource            ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/SSHKeywords.robot
Variables           ${CURDIR}/../../../variables/Variables.py

Suite Setup         Setup_Everything
Suite Teardown      Teardown_Everything
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown       SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed


*** Variables ***
${netconf_is_ready}                 False
${NETCONFREADY_WAIT}                60s
${NETCONFREADY_FALLBACK_WAIT}       1200s
${USE_NETCONF_CONNECTOR}            False
${DEBUG_LOGGING_FOR_EVERYTHING}     False
${NETCONFREADY_WAIT_MDSAL}          60s
${DEVICE_NAME}                      test-device
${DEVICE_PORT}                      2830
${NETCONF_FOLDER}                   ${CURDIR}/../../../variables/netconf/device


*** Test Cases ***
Check_Whether_Netconf_Topology_Is_Ready
    [Documentation]    Checks netconf readiness.
    BuiltIn.Pass_Execution_If
    ...    ${USE_NETCONF_CONNECTOR}==${True}
    ...    Netconf connector is used. Next testcases do their job in this case.
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    1s    Check_Netconf_Topology_Ready

Check_Whether_Netconf_Connector_Is_Up_And_Running
    [Documentation]    Make one request to Netconf topology to see whether Netconf is up and running.
    [Tags]    exclude
    Check_Netconf_Up_And_Running
    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True

Wait_For_Netconf_Connector
    [Documentation]    Wait for the Netconf to go up for configurable time.
    [Tags]    critical
    IF    not ${netconf_is_ready}
        BuiltIn.Wait_Until_Keyword_Succeeds    ${NETCONFREADY_WAIT}    1s    Check_Netconf_Up_And_Running
    END
    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True

Wait_Even_Longer
    [Documentation]    Bugs such as 7175 may require to wait longer till netconf-connector works.
    [Tags]    critical
    BuiltIn.Pass_Execution_If
    ...    ${netconf_is_ready}
    ...    Netconf was detected to be up and running so bug 5014 did not show up.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${NETCONFREADY_FALLBACK_WAIT}    10s    Check_Netconf_Up_And_Running
    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True

Check_For_Bug_5014
    [Documentation]    If Netconf appears to be down, it may be due to bug 5014. Check if it is so and fail if yes.
    ...    Bug 5014 is about Netconf playing dead on boot until a device
    ...    configuration request is sent to it. To uncover this attempt to
    ...    configure and then deconfigure a device and then check if Netconf
    ...    is now up and running. If that turns out to be true, fail the case
    ...    as this signifies the bug 5014 to be present. Skip this testcase
    ...    if Netconf is detected to be up and running.
    [Tags]    critical
    BuiltIn.Pass_Execution_If
    ...    ${netconf_is_ready}
    ...    Netconf was detected to be up and running so bug 5014 did not show up.
    ${status}    ${error}=    BuiltIn.Run_Keyword_And_Ignore_Error    Check_Netconf_Usable
    IF    '${status}'=='PASS'
        BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True
    END
    BuiltIn.Should_Be_Equal    '${status}'    'FAIL'

Check_Whether_Netconf_Can_Pretty_Print
    [Documentation]    Make one request to netconf-connector and see if it works.
    [Tags]    critical
    IF    not ${netconf_is_ready}
        Fail    Netconf is not ready so it can't pretty-print now.
    END
    CompareStream.Run_Keyword_If_At_Least_Phosphorus
    ...    Check_Netconf_Up_And_Running    pretty_print=odl-pretty-print=true

Wait_For_MDSAL
    [Documentation]    Wait for the MDSAL feature to become online
    ${status}    ${message}=    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    KarafKeywords.Verify_Feature_Is_Installed
    ...    odl-netconf-mdsal
    IF    '${status}' == 'FAIL'
        BuiltIn.Pass_Execution    The 'odl-netconf-mdsal' feature is not installed so no need to wait for it.
    END
    SSHKeywords.Open_Connection_To_ODL_System
    BuiltIn.Wait_Until_Keyword_Succeeds    ${NETCONFREADY_WAIT_MDSAL}    1s    Check_Netconf_MDSAL_Up_And_Running
    SSHLibrary.Close_Connection


*** Keywords ***
Setup_Everything
    [Documentation]    Initialize SetupUtils. Setup requests library and log into karaf.log that the netconf readiness wait starts.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${connector}=    Set_Netconf_Connector
    BuiltIn.Set_Suite_Variable    ${netconf_connector}    ${connector}
    ${restconf_prefix}=    Set_Variable_If    "${RESTCONFPORT}" == "8182"    restconf    rests
    BuiltIn.Set_Suite_Variable    ${restconf_prefix}
    BuiltIn.Comment
    ...    A workaround for EOF error follows. TODO: Create a test case for the EOF bug, possibly tagged "exclude".
    BuiltIn.Wait_Until_Keyword_Succeeds    2x    1s    KarafKeywords.Open_Controller_Karaf_Console_On_Background
    KarafKeywords.Log_Message_To_Controller_Karaf    Starting Netconf readiness test suite
    IF    ${DEBUG_LOGGING_FOR_EVERYTHING}
        KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG
    END
    RequestsLibrary.Create_Session    ses    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords

Teardown_Everything
    [Documentation]    Destroy all sessions in the requests library and log into karaf.log that the netconf readiness wait is over.
    KarafKeywords.Log_Message_To_Controller_Karaf    Ending Netconf readiness test suite
    RequestsLibrary.Delete_All_Sessions

Set_Netconf_Connector
    [Documentation]    Sets netconf connector verify url according to the ${ODL_STREAM} and ${USE_NETCONF_CONNECTOR} combination
    ${streamconnector}=    Set Variable
    ...    /node/controller-config/yang-ext:mount/config:modules/module/sal-restconf-service:json-restconf-service-impl/json-restconf-service-impl
    ${connector}=    BuiltIn.Set_Variable_If    ${USE_NETCONF_CONNECTOR}    ${streamconnector}    ${EMPTY}
    RETURN    ${connector}

Check_Netconf_Topology_Ready
    [Documentation]    Verifies the netconf readiness for every odl node.
    FOR    ${idx}    IN    @{ClusterManagement__member_index_list}
        Verify_Netconf_Topology_Ready_For_Node    ${idx}
    END

Verify_Netconf_Topology_Ready_For_Node
    [Documentation]    Netconf readines for a node is done by creating a netconf device connected to that node
    ...    and performing GET operation got from the device's mount point.
    [Arguments]    ${node_index}
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${node_index}
    Configure_Netconf_Device    ${DEVICE_NAME}    ${session}    ${ODL_SYSTEM_${node_index}_IP}
    &{mapping}=    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    RESTCONF_PREFIX=${restconf_prefix}
    Wait_Netconf_Device_Mounted    ${DEVICE_NAME}    ${session}    ${mapping}
    ${version}=    CompareStream.Set_Variable_If_At_Least_Scandium    scandium    calcium
    FOR    ${idx}    IN    @{ClusterManagement__member_index_list}
        ${mod_session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${idx}
        BuiltIn.Wait_Until_Keyword_Succeeds
        ...    5x
        ...    3s
        ...    TemplatedRequests.Get_As_Xml_Templated
        ...    ${NETCONF_FOLDER}${/}${version}${/}netconf-state
        ...    mapping=${mapping}
        ...    session=${mod_session}
    END
    [Teardown]    Remove_Netconf_Device    ${DEVICE_NAME}    ${session}

Configure_Netconf_Device
    [Documentation]    Configures the device via REST api.
    [Arguments]    ${device_name}    ${session}    ${device_ip}
    ${device_type}=   Set_Variable_If    "${RESTCONFPORT}" == "8182"    netty-full-uri-device    full-uri-device
    NetconfKeywords.Configure_Device_In_Netconf
    ...    ${device_name}
    ...    device_type=${device_type}
    ...    device_port=${DEVICE_PORT}
    ...    device_address=${device_ip}
    ...    device_user=admin
    ...    device_password=admin
    ...    session=${session}

Remove_Netconf_Device
    [Documentation]    Removes configured device
    [Arguments]    ${device_name}    ${session}
    NetconfKeywords.Remove_Device_From_Netconf    ${device_name}    session=${session}

Wait_Netconf_Device_Mounted
    [Documentation]    Checks weather the device was mounted.
    [Arguments]    ${device_name}    ${session}    ${mapping}    ${timeout}=30s
    ${version}=    CompareStream.Set_Variable_If_At_Least_Scandium    scandium    calcium
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    ${timeout}
    ...    3s
    ...    TemplatedRequests.Get_As_Xml_Templated
    ...    ${NETCONF_FOLDER}${/}${version}${/}full-uri-mount
    ...    mapping=${mapping}
    ...    session=${session}

Check_Netconf_Up_And_Running
    [Documentation]    Make a request to netconf connector's list of mounted devices and check that the request was successful.
    [Arguments]    ${pretty_print}=${EMPTY}
    ${response}=    RequestsLibrary.Get_On_Session
    ...    ses
    ...    url=${restconf_prefix}/data/network-topology:network-topology/topology=topology-netconf${netconf_connector}
    ...    params=${pretty_print}
    BuiltIn.Log    ${response.text}
    ${status}=    BuiltIn.Run_Keyword_And_Return_Status
    ...    BuiltIn.Should_Contain
    ...    ${response.text}
    ...    data model content does not exist
    IF    ${status}
        BuiltIn.Set_Suite_Variable    ${netconf_not_ready_cause}    5832
    END
    IF    ${status}    SetupUtils.Set_Known_Bug_Id    5832
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200

Check_Netconf_Usable
    NetconfKeywords.Configure_Device_In_Netconf    test-device    device_type=configure-via-topology
    NetconfKeywords.Remove_Device_From_Netconf    test-device
    Check_Netconf_Up_And_Running

Check_Netconf_MDSAL_Up_And_Running
    ${count}=    SSHKeywords.Count_Port_Occurences    ${ODL_NETCONF_MDSAL_PORT}    LISTEN    java
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    1
