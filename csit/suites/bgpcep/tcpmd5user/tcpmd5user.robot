*** Settings ***
Documentation     TCPMD5 user-facing feature system tests, using PCEP.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic pcep md5 password authorization test cases:
...               (Run entire basic PCEP suite without passwords.)
...               Start pcc-mock (reconnecting mode): 1 pcc, 1 lsp, password set, check pcep-topology stays empty.
...               Use restconf to change PCEP configuration to use a wrong password, check pcep-topology stays empty.
...               Change ODL PCEP configuration to use the correct password, check pcep-topology shows the lsp.
...               Stop pcc-mock, check pcep-topology stays empty.
...               Start pcc-mock with new password, check pcep-topology stays empty.
...               Change ODL PCEP configuration to use the correct password, check pcep-topology shows the lsp.
...               Update the lsp, check a change in pcep-topology.
...               Change ODL PCEP configuration to not use password, pcep-topology empties, kill pcep-pcc-mock.
...
...               Stable/carbon and stable/nitrogen are using netconf-connector-ssh to send restconf requests.
...               Oxygen test cases no longer need netconf-connector-ssh, and they include comparison of
...               pcep-session-state, which is exclusive to oxygen.
Suite Setup       Set_It_Up
Suite Teardown    Tear_It_Down
Test Setup        FailFast.Fail_This_Fast_On_Previous_Error
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary    prompt=]>
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/NexusKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../libraries/RemoteBash.robot
Resource          ../../../libraries/CompareStream.robot

*** Variables ***
${DIR_WITH_TEMPLATES}    ${CURDIR}/../../../variables/tcpmd5user/
${CONFIG_SESSION}    session
${CONNECTOR_FEATURE}    odl-netconf-connector-all
${PCEP_FEATURE}    odl-bgpcep-pcep
${RESTCONF_FEATURE}    odl-restconf-all

*** Test Cases ***
Topology_Precondition
    [Documentation]    Compare current pcep-topology to empty one.
    ...    Timeout is long enough to see that pcep is ready, with no PCC connected.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    300s    1s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_off    session=${CONFIG_SESSION}    verify=True

Start_Secure_Pcc_Mock
    [Documentation]    Execute pcc-mock on Mininet with password set, fail if pcc-mock promptly exits. Keep pcc-mock running for next test cases.
    Start_Pcc_Mock_Tool_With_Password    password=topsecret

Topology_Unauthorized_1
    [Documentation]    Try to catch a glimpse of pcc-mock in pcep-topology. Pass if no change from Precondition is detected over 10 seconds.
    [Tags]    critical
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Test_Unauthorized

Set_Wrong_Password
    [Documentation]    Configure password in pcep dispatcher for client with Mininet IP address.
    ...    This password does not match what pcc-mock uses.
    CompareStream.Run_Keyword_If_At_Least_Oxygen    Replace_Password_On_Pcep_Node    password=changeme
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    Set_Password_Less_Than_Oxygen    password=changeme

Topology_Unauthorized_2
    [Documentation]    The same logic as Topology_Unauthorized_1 as incorrect password was provided to ODL.
    [Tags]    critical
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Test_Unauthorized

Set_Correct_Password
    [Documentation]    Configure password in pcep dispatcher for client with Mininet IP address.
    ...    This password finally matches what pcc-mock uses.
    CompareStream.Run_Keyword_If_At_Least_Oxygen    Replace_Password_On_Pcep_Node    password=topsecret
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    Set_Password_Less_Than_Oxygen    password=topsecret

Topology_Intercondition
    [Documentation]    Compare pcep-topology/path-computation-client to filled one, which includes a tunnel from pcc-mock.
    ...    For oxygen compares full pcep-topology including pcep-session-state
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    CODE=${pcc_name_code}    NAME=${pcc_name}    IP_ODL=${ODL_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_on    ${mapping}    ${CONFIG_SESSION}
    ...    verify=True
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    BuiltIn.Pass_Execution    Rest of the test case valid only for versions oxygen and above.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    1s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_on_state    ${mapping}
    ...    ${CONFIG_SESSION}    verify=True

Stop_Pcc_Mock_1
    [Documentation]    Stops First instance of pcc-mock.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    Stop_Pcc_Mock_Tool
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Topology_Unauthorized_3
    [Documentation]    The same logic as Topology_Unauthorized_1, with no pcc-mock running.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    Test_Unauthorized

Start_Secure_Pcc_Mock_2
    [Documentation]    Execute pcc-mock on Mininet with new password set, fail if pcc-mock promptly exits. Keep pcc-mock running for next test cases.
    Start_Pcc_Mock_Tool_With_Password    password=newtopsecret

Topology_Unauthorized_4
    [Documentation]    The same logic as Topology_Unauthorized_1, but ODL password became incorrect with new pcc-mock running.
    [Tags]    critical
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Test_Unauthorized

Set_Correct_Password_2
    [Documentation]    Configure password in pcep dispatcher for client with Mininet IP address.
    ...    This password again matches what second pcc-mock instance uses.
    CompareStream.Run_Keyword_If_At_Least_Oxygen    Replace_Password_On_Pcep_Node    password=newtopsecret
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    Set_Password_Less_Than_Oxygen    password=newtopsecret

Topology_Intercondition_2
    [Documentation]    Compare pcep-topology/path-computation-client to filled one, which includes a tunnel from pcc-mock.
    ...    For oxygen compares full pcep-topology including pcep-session-state
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    CODE=${pcc_name_code}    NAME=${pcc_name}    IP_ODL=${ODL_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_on    ${mapping}    ${CONFIG_SESSION}
    ...    verify=True
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    BuiltIn.Pass_Execution    Rest of the test case valid only for versions oxygen and above.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    1s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_on_state    ${mapping}
    ...    ${CONFIG_SESSION}    verify=True

Update_Delegated
    [Documentation]    Perform update-lsp on the mocked tunnel, check response is success.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    NAME=${pcc_name}
    ${response}=    TemplatedRequests.Post_As_Xml_Templated    ${DIR_WITH_TEMPLATES}${/}update_delegated    ${mapping}    ${CONFIG_SESSION}    verify=True
    Log    ${response}

Topology_Updated
    [Documentation]    Compare pcep-topology/path-computation-client to default_on_updated, which includes the updated tunnel.
    ...    For oxygen compares full pcep-topology including pcep-session-state
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    CODE=${pcc_name_code}    NAME=${pcc_name}    IP_ODL=${ODL_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_on_updated    ${mapping}    ${CONFIG_SESSION}
    ...    verify=True
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    BuiltIn.Pass_Execution    Rest of the test case valid only for versions oxygen and above.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    1s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_on_updated_state    ${mapping}
    ...    ${CONFIG_SESSION}    verify=True

Unset_Password
    [Documentation]    De-configure password for pcep dispatcher for client with Mininet IP address.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    CompareStream.Run_Keyword_If_At_Least_Oxygen    Unset_Password_On_Pcep_Node
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    Replace_Password_Xml_Element_In_Pcep_Client_Module_Less_Than_Oxygen
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Topology_Unauthorized_5
    [Documentation]    Wait for pcep-topology to become empty again.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    Test_Unauthorized

Stop_Pcc_Mock_2
    [Documentation]    Stops second instance of pcc-mock
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    Stop_Pcc_Mock_Tool
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Topology_Postcondition
    [Documentation]    Verify that pcep-topology stays empty.
    [Tags]    critical
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Test_Unauthorized

Delete_Pcep_Client_Module
    [Documentation]    Delete Pcep client module.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}
    CompareStream.Run_Keyword_If_At_Least_Oxygen    TemplatedRequests.Delete_Templated    ${DIR_WITH_TEMPLATES}${/}pcep_topology_node    ${mapping}
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    TemplatedRequests.Delete_Templated    ${DIR_WITH_TEMPLATES}${/}pcep_topology_client_module    ${mapping}

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to Mininet machine, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to Mininet.
    ...    Also, delete and create directories for json diff handling.
    ...    Sets up netconf-connector on odl-streams less than oxygen.
    KarafKeywords.Setup_Karaf_Keywords
    TemplatedRequests.Create_Default_Session
    BuiltIn.Run_Keyword_If    """${USE_NETCONF_CONNECTOR}""" == """False"""    CompareStream.Run_Keyword_If_Less_Than_Oxygen    Install_Netconf_Connector
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    ${current_connection}=    SSHLibrary.Get_Connection
    ${current_prompt}=    BuiltIn.Set_Variable    ${current_connection.prompt}
    BuiltIn.Log    ${current_prompt}
    BuiltIn.Set_Suite_Variable    ${prompt}    ${current_prompt}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    #Setting Pcc Name and its code for mapping for templates
    BuiltIn.Set_Suite_Variable    ${pcc_name}    pcc_${TOOLS_SYSTEM_IP}_tunnel_1
    ${code}=    Evaluate    binascii.b2a_base64('${pcc_name}')[:-1]    modules=binascii
    BuiltIn.Set_Suite_Variable    ${pcc_name_code}    ${code}
    FailFast.Do_Not_Fail_Fast_From_Now_On

Tear_It_Down
    [Documentation]    Download pccmock.log and Log its contents.
    ...    Compute and Log the diff between expected and actual normalized responses.
    ...    Close both HTTP client session and SSH connection to Mininet.
    SSHLibrary.Get_File    pccmock.log
    ${pccmocklog}=    OperatingSystem.Run    cat pccmock.log
    BuiltIn.Log    ${pccmocklog}
    BuiltIn.Run_Keyword_If    """${USE_NETCONF_CONNECTOR}""" == """False"""    CompareStream.Run_Keyword_If_Less_Than_Oxygen    Uninstall_Netconf_Connector
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
    BuiltIn.Wait_Until_Keyword_Succeeds    240s    3s    Check_Netconf_Up_And_Running

Check_Netconf_Up_And_Running
    [Documentation]    Make a request to netconf connector's mounted pcep module and expect it is mounted.
    TemplatedRequests.Get_From_Uri    restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-pcep-topology-provider-cfg:pcep-topology-provider/pcep-topology

Uninstall_Netconf_Connector
    [Documentation]    Uninstalls ${CONNECTOR_FEATURE} feature.
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Uninstall_A_Feature    ${CONNECTOR_FEATURE}
    BuiltIn.Log    ${results}

Test_Unauthorized
    [Documentation]    Try to access pcep topology with wrong password, should get empty topology
    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_off    session=${CONFIG_SESSION}    verify=True

Set_Password_Less_Than_Oxygen
    [Arguments]    ${password}=${EMPTY}
    ${password_line}=    Construct_Password_Element_Line_Using_Password    password=${password}
    Replace_Password_Xml_Element_In_Pcep_Client_Module_Less_Than_Oxygen    ${password_line}

Read_Text_Before_Prompt
    [Documentation]    Log text gathered by SSHLibrary.Read_Until_Prompt.
    ...    This needs to be a separate keyword just because how Read_And_Fail_If_Prompt_Is_Seen is implemented.
    ${text}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}

Replace_Password_On_Pcep_Node
    [Arguments]    ${password}
    [Documentation]    Send restconf PUT to replace the config module specifying PCEP password element.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    PASSWD=${password}
    TemplatedRequests.Put_As_Xml_Templated    ${DIR_WITH_TEMPLATES}${/}pcep_topology_node    mapping=${mapping}

Unset_Password_On_Pcep_Node
    [Documentation]    Send restconf PUT to unset the config module.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${DIR_WITH_TEMPLATES}${/}pcep_topology_node_empty    mapping=${mapping}

Construct_Password_Element_Line_Using_Password
    [Arguments]    ${password}
    [Documentation]    Return line with password XML element containing given password, whitespace is there so that data to send looks neat.
    ${element}=    String.Replace_String    ${SPACE}${SPACE}<password>$PASSWORD</password>${\n}    $PASSWORD    ${password}
    BuiltIn.Log    ${element}
    [Return]    ${element}

Replace_Password_Xml_Element_In_Pcep_Client_Module_Less_Than_Oxygen
    [Arguments]    ${password_element}=${EMPTY}
    [Documentation]    Send restconf PUT to replace the config module specifying PCEP password element (may be empty=missing).
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    PASSWD=${password_element}
    TemplatedRequests.Put_As_Xml_Templated    ${DIR_WITH_TEMPLATES}${/}pcep_topology_client_module    mapping=${mapping}

Stop_Pcc_Mock_Tool
    [Documentation]    Send ctrl+c to pcc-mock, fails if no prompt is seen
    ...    after 3 seconds (the default for SSHLibrary)
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

Start_Pcc_Mock_Tool_With_Password
    [Arguments]    ${password}
    [Documentation]    Starts pcc-mock with password argument.
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --password ${password} --reconnect 1 --local-address ${TOOLS_SYSTEM_IP} --remote-address ${ODL_SYSTEM_IP} 2>&1 | tee pccmock.log
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}
