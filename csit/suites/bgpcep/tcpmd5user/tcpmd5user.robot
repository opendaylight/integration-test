*** Settings ***
Documentation     TCPMD5 user-facing feature system tests, using PCEP.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               The original brief description of this suite is at
...               https://wiki.opendaylight.org/view/TCPMD5:Lithium_Feature_Tests#How_to_test
Suite Setup       Set_It_Up
Suite Teardown    Tear_It_Down
Test Setup        FailFast.Fail_This_Fast_On_Previous_Error
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary    prompt=]>
Library           String
Library           ../../../libraries/norm_json.py
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/NexusKeywords.robot
Resource          ../../../libraries/PcepOperations.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/WaitForFailure.robot
Variables         ../../../variables/Variables.py
Variables         ../../../variables/pcepuser/variables.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${directory_for_actual_responses}    ${TEMPDIR}${/}actual
${directory_for_expected_responses}    ${TEMPDIR}${/}expected
${directory_with_template_folders}    ${CURDIR}/../../../variables/tcpmd5user/
${CONNECTOR_FEATURE}    odl-netconf-connector-all
${PCEP_FEATURE}    odl-bgpcep-pcep
${RESTCONF_FEATURE}    odl-restconf-all
${CONFIG_SESSION}    session
${CONFIG_SESSION_XML}    session_xml

*** Test Cases ***
Topology_Precondition
    [Documentation]    Compare current pcep-topology to empty one.
    ...    Timeout is long enough to see that pcep is ready, with no PCC is connected.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    300    1    Compare_Topology    ${off_json}    010_Precondition.json

Start_Secure_Pcc_Mock
    [Documentation]    Execute pcc-mock on Mininet with password set, fail if pcc-mock promptly exits. Keep pcc-mock running for next test cases.
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --password topsecret --reconnect 1 --local-address ${TOOLS_SYSTEM_IP} --remote-address ${ODL_SYSTEM_IP} 2>&1 | tee pccmock.log
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}
    ${status}    ${resp}=   Run Keyword And Ignore Error    Read_And_Fail_If_Prompt_Is_Seen

Topology_Unauthorized_1
    [Documentation]    Try to catch a glimpse of pcc-mock in pcep-topology. Pass if no change from Precondition is detected over 1 minute.
    [Tags]    critical
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Compare_Topology    ${off_json}    020_Unauthorized_1.json

Set_Wrong_Password
    [Documentation]    Configure password in pcep dispatcher for client with Mininet IP address.
    ...    This password does not match what pcc-mock uses.
    Replace_Password_Xml_Element_In_Pcep_Client_Module    password=changeme

Topology_Unauthorized_2
    [Documentation]    The same logic as Topology_Unauthorized_1 as incorrect password was provided to ODL.
    [Tags]    critical
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Compare_Topology    ${off_json}    040_Unauthorized_3.json

Set_Correct_Password
    [Documentation]    Configure password in pcep dispatcher for client with Mininet IP address.
    ...    This password finally matches what pcc-mock uses.
    Replace_Password_Xml_Element_In_Pcep_Client_Module    topsecret

Topology_Intercondition
    [Documentation]    Compare pcep-topology to filled one, which includes a tunnel from pcc-mock.
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    Compare_Topology    ${default_json}    050_Intercondition.json

Update_Delegated
    [Documentation]    Perform update-lsp on the mocked tunnel, check response is success.
    ${response}=    RequestsLibrary.Post Request    ${CONFIG_SESSION_XML}    /restconf/operations/network-topology-pcep:update-lsp    ${update_delegated_xml}
    Log    ${response.text}

Topology_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_succeeds    5s    1s    Compare_Topology    ${updated_json}    060_Topology_Updated.json

Unset_Password
    [Documentation]    De-configure password for pcep dispatcher for client with Mininet IP address.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    Replace_Password_Xml_Element_In_Pcep_Client_Module    ${EMPTY}
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Topology_Unauthorized_3
    [Documentation]    Wait for pcep-topology to become empty again.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    Compare_Topology    ${offjson}    070_Unauthorized_4.json

Stop_Pcc_Mock
    [Documentation]    Send ctrl+c to pcc-mock, fails if no prompt is seen
    ...    after 3 seconds (the default for SSHLibrary)
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    RemoteBash.Write_Bare_Ctrl_C
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Topology_Postcondition
    [Documentation]    Verify that pcep-topology stays empty.
    [Tags]    critical
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    10    1    Compare_Topology    ${offjson}    080_Postcondition.json
    # FIXME: We should delete config changes to not affect next suite.

Delete_Pcep_Client_Module
    [Documentation]    Delete Pcep client module.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Delete_Templated    ${directory_with_template_folders}${/}pcep_topology_client_module    mapping=${mapping}

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to Mininet machine, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to Mininet.
    ...    Also, delete and create directories for json diff handling.
    KarafKeywords.Setup_Karaf_Keywords
    TemplatedRequests.Create_Default_Session
    #BuiltIn.Run_Keyword_If    """${USE_NETCONF_CONNECTOR}""" == """False"""    Install_Netconf_Connector
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    ${current_connection}=    SSHLibrary.Get_Connection
    ${current_prompt}=    BuiltIn.Set_Variable    ${current_connection.prompt}
    BuiltIn.Log    ${current_prompt}
    BuiltIn.Set_Suite_Variable    ${prompt}    ${current_prompt}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION_XML}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    headers=${HEADERS_XML}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    OperatingSystem.Remove_Directory    ${directory_for_expected_responses}    recursive=True
    OperatingSystem.Remove_Directory    ${directory_for_actual_responses}    recursive=True
    # The previous suite may have been using the same directories.
    OperatingSystem.Create_Directory    ${directory_for_expected_responses}
    OperatingSystem.Create_Directory    ${directory_for_actual_responses}
    #PcepOperations.Setup_Pcep_Operations
    FailFast.Do_Not_Fail_Fast_From_Now_On

Tear_It_Down
    [Documentation]    Download pccmock.log and Log its contents.
    ...    Compute and Log the diff between expected and actual normalized responses.
    ...    Close both HTTP client session and SSH connection to Mininet.
    #SSHLibrary.Get_File    pccmock.log
    #${pccmocklog}=    OperatingSystem.Run    cat pccmock.log
    #BuiltIn.Log    ${pccmocklog}
    #${diff}=    OperatingSystem.Run    diff -dur ${directory_for_expected_responses} ${directory_for_actual_responses}
    #BuiltIn.Log    ${diff}
    #PcepOperations.Teardown_Pcep_Operations
    #BuiltIn.Run_Keyword_If    """${USE_NETCONF_CONNECTOR}""" == """False"""    Uninstall_Netconf_Connector
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Install_Netconf_Connector
    [Documentation]    Installs ${CONNECTOR_FEATURE} feature.
    # During the netconf connector installation the karaf's ssh is restarted and connection to karaf console is droped. This is causing an error
    # which is ignored, because the feature should be installed anyway.
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Install_A_Feature    ${CONNECTOR_FEATURE}
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Install_A_Feature    ${PCEP_FEATURE}
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Install_A_Feature    ${RESTCONF_FEATURE}
    BuiltIn.Log    ${results}
    BuiltIn.Wait_Until_Keyword_Succeeds    240    3    Check_Netconf_Up_And_Running

Check_Netconf_Up_And_Running
    [Documentation]    Make a request to netconf connector's mounted pcep module and expect it is mounted.
    TemplatedRequests.Get_From_Uri    restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-pcep-topology-provider-cfg:pcep-topology-provider/pcep-topology

Uninstall_Netconf_Connector
    [Documentation]    Uninstalls ${CONNECTOR_FEATURE} feature.
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Uninstall_A_Feature    ${CONNECTOR_FEATURE}
    BuiltIn.Log    ${results}

Read_And_Fail_If_Prompt_Is_Seen
    [Documentation]    Try to read SSH to see prompt, but expect to see no prompt within SSHLibrary's timeout.
    BuiltIn.Run_Keyword_And_Expect_Error    No match found for '${prompt}' in *.    Read_Text_Before_Prompt

Read_Text_Before_Prompt
    [Documentation]    Log text gathered by SSHLibrary.Read_Until_Prompt.
    ...    This needs to be a separate keyword just because how Read_And_Fail_If_Prompt_Is_Seen is implemented.
    ${text}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}

Compare_Topology
    [Arguments]    ${expected}    ${name}
    [Documentation]    Get current pcep-topology as json, normalize both expected and actual json.
    ...    Save normalized jsons to files for later processing.
    ...    Error codes and normalized jsons should match exactly.
    # FIXME: See bgpuser to move handling of expected outside WUKS loop, as in bgpuser suite.
    ${normexp}=    norm_json.normalize_json_text    ${expected}
    BuiltIn.Log    ${normexp}
    OperatingSystem.Create_File    ${directory_for_expected_responses}${/}${name}    ${normexp}
    ${resp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    /restconf/operational/network-topology:network-topology/topology/pcep-topology
    BuiltIn.Log    ${resp}
    BuiltIn.Log    ${resp.text}
    ${normresp}=    norm_json.normalize_json_text    ${resp.text}
    BuiltIn.Log    ${normresp}
    OperatingSystem.Create_File    ${directory_for_actual_responses}${/}${name}    ${normresp}
    Run Keyword And Ignore Error    BuiltIn.Should_Be_Equal_As_Strings    ${resp.status_code}    200
    Run Keyword And Ignore Error    BuiltIn.Should_Be_Equal    ${normresp}    ${normexp}

Replace_Password_Xml_Element_In_Pcep_Client_Module
    [Arguments]    ${password}
    [Documentation]    Send restconf PUT to replace the config module specifying PCEP password element (may me empty=missing).
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    PASSWD=${password}
    TemplatedRequests.Put_As_Xml_Templated    ${directory_with_template_folders}${/}pcep_topology_client_module    mapping=${mapping}    session=${CONFIG_SESSION}
