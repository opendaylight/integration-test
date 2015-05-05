*** Settings ***
Documentation     TCPMD5 user-facing feature system tests, using PCEP.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Set_It_Up
Suite Teardown    Tear_It_Down
Library           OperatingSystem
Library           SSHLibrary    prompt=]>
Library           ${CURDIR}/../../../libraries/RequestsLibrary.py
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/PcepOperations.robot
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/tcpmd5user/variables.py    ${MININET}
Variables         ${CURDIR}/../../../variables/pcepuser/variables.py    ${MININET}

*** Variables ***
${ExpDir}         ${CURDIR}/expected
${ActDir}         ${CURDIR}/actual

*** Test Cases ***
Topology_Precondition
    [Documentation]    Compare current pcep-topology to "offjson" variable.
    ...    Timeout is long enough to see that pcep is ready, with no PCC is connected.
    [Tags]    critical
    Wait_Until_Keyword_Succeeds    300    1    Compare_Topology    ${offjson}    Pre

Start_Secure_Pcc_Mock
    [Documentation]    Execute pcc-mock on Mininet with password set, fail if pcc-mock returns. Keep pcc-mock running for next test cases.
    [Tags]    critical
    ${command}=    Set_Variable    java -jar ${filename} --password topsecret --reconnect 1 --local-address ${MININET} --remote-address ${CONTROLLER} 2>&1 | tee pccmock.log
    Log    ${command}
    Write    ${command}
    Run_Keyword_And_Expect_Error    No match found for '${prompt}' in *.    Read_Until_Prompt

Topology_Unauthorized_1
    [Documentation]    Try to catch a glimpse of pcc-mock in pcep-topology. Pass if no change from Precondition is detected over 1 minute.
    [Tags]    critical
    Run_Keyword_And_Expect_Error    *    Wait_Until_Keyword_Succeeds    10    1    Run_Keyword_And_Expect_Error    *
    ...    Compare_Topology    ${offjson}    Una1
    # RKAEE WUKS RKAEE equals poor man's Wait_For_Keyword_To_Fail (and pass iff it does not fail)
    # Maybe explicit contruction with :FOR and time-based exit will be more readable?

Enable_Tcpmd5_No_Password_Yet
    [Documentation]    Send series of restconf posts according to https://wiki.opendaylight.org/view/BGP_LS_PCEP:TCP_MD5_Guide#RESTCONF_Configuration
    ...    Every post should return empty text with 204 status code.
    [Tags]    critical
    Post_Xml_Config_Module_Via_Restconf    ${key_access_module}
    Post_Xml_Config_Service_Via_Restconf    ${key_access_service}
    Post_Xml_Config_Module_Via_Restconf    ${client_channel_module}
    Post_Xml_Config_Service_Via_Restconf    ${client_channel_service}
    Post_Xml_Config_Module_Via_Restconf    ${server_channel_module}
    Post_Xml_Config_Service_Via_Restconf    ${server_channel_service}
    Post_Xml_Config_Module_Via_Restconf    ${pcep_dispatcher_module}

Topology_Unauthorized_2
    [Documentation]    The same logic as Topology_Unauthorized_1 as password was not provided to ODL.
    [Tags]    critical
    Run_Keyword_And_Expect_Error    *    Wait_Until_Keyword_Succeeds    10    1    Run_Keyword_And_Expect_Error    *
    ...    Compare_Topology    ${offjson}    Una2

Set_Wrong_Password
    [Documentation]    Send restconf post to configure password for pcep dispatcher for client with Mininet IP address.
    ...    This password does not match what pcc-mock uses.
    [Tags]    critical
    Post_Xml_Config_Module_Via_Restconf    ${passwd_changeme_module}

Topology_Unauthorized_3
    [Documentation]    The same logic as Topology_Unauthorized_1 as incorrect password was provided to ODL.
    [Tags]    critical
    Run_Keyword_And_Expect_Error    *    Wait_Until_Keyword_Succeeds    10    1    Run_Keyword_And_Expect_Error    *
    ...    Compare_Topology    ${offjson}    Una3

Set_Correct_Password
    [Documentation]    Send restconf post to configure password for pcep dispatcher for client with Mininet IP address.
    ...    This password finally matches what pcc-mock uses.
    [Tags]    critical
    Post_Xml_Config_Module_Via_Restconf    ${passwd_topsecret_module}

Topology_Intercondition
    [Documentation]    Compare pcep-topology to "onjson", which includes a tunnel from pcc-mock.
    [Tags]    xfail
    Wait_Until_Keyword_Succeeds    10    1    Compare_Topology    ${onjson}    Inter

Update_Delegated
    [Documentation]    Perform update-lsp on the mocked tunnel, check response is success.
    [Tags]    critical
    ${text}=    Update_Xml_Lsp_Return_Json    ${update_delegated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    5    1    Compare_Topology    ${updated_json}    010_Topology_Updated

Unset_Password
    [Documentation]    Send restconf post to de-configure password for pcep dispatcher for client with Mininet IP address.
    [Tags]    critical
    Post_Xml_Config_Module_Via_Restconf    ${no_passwd_module}

Topology_Unauthorized_4
    [Documentation]    The same logic as Topology_Unauthorized_1 as the correct password is no longer configured on ODL.
    [Tags]    critical
    Run_Keyword_And_Expect_Error    *    Wait_Until_Keyword_Succeeds    10    1    Run_Keyword_And_Expect_Error    *
    ...    Compare_Topology    ${offjson}    Una4

Stop_Pcc_Mock
    [Documentation]    Send ctrl+c to pcc-mock, fails if no prompt is seen
    ...    after 3 seconds (the default for SSHLibrary)
    ${command}=    Evaluate    chr(int(3))
    Log    ${command}
    Write    ${command}
    Read_Until_Prompt

Topology_Postcondition
    [Documentation]    Compare curent pcep-topology to "offjson" again.
    ...    Timeout is lower than in Precondition,
    ...    but data from pcc-mock should be gone quickly.
    [Tags]    critical
    Wait_Until_Keyword_Succeeds    10    1    Compare_Topology    ${offjson}    Post

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to Mininet machine, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to Mininet.
    ...    Also, delete and create directories for json diff handling.
    Open_Connection    ${MININET}
    Login_With_Public_Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    ${current_connection}=    Get_Connection
    ${current_prompt}=    Set_Variable    ${current_connection.prompt}
    Log    ${current_prompt}
    Set_Suite_Variable    ${prompt}    ${current_prompt}
    Create_Session    ses    http://${CONTROLLER}:${RESTCONFPORT}/restconf/operational/network-topology:network-topology    auth=${AUTH}
    # TODO: Figure out a way how to share pcc-mock instance with pcepuser suite.
    ${urlbase}=    Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot/org/opendaylight/bgpcep/pcep-pcc-mock
    ${version}=    Execute_Command    curl ${urlbase}/maven-metadata.xml | grep latest | cut -d '>' -f 2 | cut -d '<' -f 1
    Log    ${version}
    ${namepart}=    Execute_Command    curl ${urlbase}/${version}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    Log    ${namepart}
    Set_Suite_Variable    ${filename}    pcep-pcc-mock-${namepart}-executable.jar
    Log    ${filename}
    ${response}=    Execute_Command    wget -q -N ${urlbase}/${version}/${filename} 2>&1
    Log    ${response}
    Remove_Directory    ${ExpDir}
    Remove_Directory    ${ActDir}
    Create_Directory    ${ExpDir}
    Create_Directory    ${ActDir}
    Setup_Config_Via_Restconf
    Setup_Pcep_Operations

Compare_Topology
    [Arguments]    ${expected}    ${name}
    [Documentation]    Get current pcep-topology as json, normalize both expected and actual json.
    ...    Save normalized jsons to files for later processing.
    ...    Error codes and normalized jsons should match exactly.
    ${normexp}=    Hsf_Json    ${expected}
    Log    ${normexp}
    Create_File    ${ExpDir}${/}${name}    ${normexp}
    ${resp}=    RequestsLibrary.Get    ses    topology/pcep-topology
    Log    ${resp}
    Log    ${resp.text}
    ${normresp}=    Hsf_Json    ${resp.text}
    Log    ${normresp}
    Create_File    ${ActDir}${/}${name}    ${normresp}
    Should_Be_Equal_As_Strings    ${resp.status_code}    200
    Should_Be_Equal    ${normresp}    ${normexp}

Tear_It_Down
    [Documentation]    Download pccmock.log and Log its contents.
    ...    Compute and Log the diff between expected and actual normalized responses.
    ...    Close both HTTP client session and SSH connection to Mininet.
    SSHLibrary.Get_File    pccmock.log
    ${pccmocklog}=    Run    cat pccmock.log
    Log    ${pccmocklog}
    ${diff}=    Run    diff -dur ${ExpDir} ${ActDir}
    Log    ${diff}
    Teardown_Pcep_Operations
    Teardown_Config_Via_Restconf
    Delete_All_Sessions
    Close_All_Connections
