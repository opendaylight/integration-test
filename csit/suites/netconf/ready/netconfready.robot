*** Settings ***
Documentation     netconf-connector readiness test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Query netconf-connector and see if it works. Some testsuites
...               expect netconf-connector to be ready as soon as possible and
...               will fail if it is not. We want to see a failure if this is
...               the cause of the failure.
...
...               If the netconf-connector is not ready upon startup (as seen by
...               the first test case failing), the second case starts to repeat
...               the query for a minute to see whether it is going "to fix itself"
...               within the minute. If yes, then the testcase will pass, which
...               indicates that the "ODL cooldown" of 1 minute is not long enough
...               to allow for netconf-connector to initialize properly.
...
...               If the first test case passed, then the second test case does
...               nothing.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Library           RequestsLibrary
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${netconf_is_ready}    False
${NETCONFREADY_WAIT}    60s
${DEBUG_LOGGING_FOR_EVERYTHING}    False

*** Test Cases ***
Check_Whether_Netconf_Connector_Works
    [Documentation]    Make one request to netconf-connector and see if it works.
    [Tags]    exclude
    Check_Netconf_Connector
    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4708

Wait_For_Netconf_Connector
    [Documentation]    Attempt to wait for the netconf-connector for configurable time.
    [Tags]    critical
    BuiltIn.Run_Keyword_Unless    ${netconf_is_ready}    BuiltIn.Wait_Until_Keyword_Succeeds    ${NETCONFREADY_WAIT}    1s    Check_Netconf_Connector
    BuiltIn.Set_Suite_Variable    ${netconf_is_ready}    True
    [Teardown]    Utils.Report_Failure_Due_To_Bug    4583

Check_Whether_Netconf_Connector_Can_Pretty_Print
    [Documentation]    Make one request to netconf-connector and see if it works.
    [Tags]    critical
    Check_Netconf_Connector    ?prettyPrint=true

*** Keywords ***
Setup_Everything
    [Documentation]    Setup requests library and log into karaf.log that the netconf readiness wait starts.
    KarafKeywords.Open_Controller_Karaf_Console_On_Background
    KarafKeywords.Log_Message_To_Controller_Karaf    Starting Netconf readiness test suite
    BuiltIn.Run_Keyword_If    ${DEBUG_LOGGING_FOR_EVERYTHING}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG
    RequestsLibrary.Create_Session    ses    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.

Teardown_Everything
    [Documentation]    Destroy all sessions in the requests library and log into karaf.log that the netconf readiness wait is over.
    KarafKeywords.Log_Message_To_Controller_Karaf    Ending Netconf readiness test suite
    RequestsLibrary.Delete_All_Sessions

Check_Netconf_Connector
    [Arguments]    ${pretty_print}=${EMPTY}
    [Documentation]    Make a request to netconf connector's list of mounted devices and check that the request was successful.
    ${response}=    RequestsLibrary.Get    ses    restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-sal-netconf-connector-cfg:sal-netconf-connector/controller-config${pretty_print}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200
