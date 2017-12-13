*** Settings ***
Documentation     Basic tests for odl-bgpcep-pcep-all feature.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Set_It_Up
Suite Teardown    Tear_It_Down
Library           OperatingSystem
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../libraries/norm_json.py
Resource          ../../../libraries/NexusKeywords.robot
Resource          ../../../libraries/PcepOperations.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/RemoteBash.robot
Resource          ../../../libraries/TemplatedRequests.robot
Variables         ../../../variables/Variables.py
Variables         ../../../variables/pcepuser/variables.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${DIRECTORY_FOR_ACTUAL_RESPONSES}    ${TEMPDIR}${/}actual
${DIRECTORY_FOR_EXPECTED_RESPONSES}    ${TEMPDIR}${/}expected
${NODE_SESSION_STATE_FOLDER}    ${CURDIR}/../../../variables/pcepuser/node_session_state/
${CONFIG_SESSION}    session

*** Test Cases ***
Topology_Precondition
    [Documentation]    Compare current pcep-topology to off_json variable.
    ...    Timeout is long enough to ODL boot, to see that pcep is ready, with no PCC is connected.
    [Tags]    critical
    ${off_json_normalized}=    Normalize_And_Save_Json    ${off_json}    010_Topology_Precondition.json    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    Wait_Until_Keyword_Succeeds    300s    1s    Compare_Topology    ${off_json_normalized}    010_Topology_Precondition.json

Start_Pcc_Mock
    [Documentation]    Execute pcc-mock on Mininet, fail is Open is not sent, keep it running for next tests.
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --local-address ${TOOLS_SYSTEM_IP} --remote-address ${ODL_SYSTEM_IP} 2>&1 | tee pccmock.log
    Log    ${command}
    Write    ${command}
    Read_Until    started, sent proposal Open

Topology_Default
    [Documentation]    Compare pcep-topology to default_json, which includes a tunnel from pcc-mock.
    ...    Timeout is lower than in Precondition, as state from pcc-mock should be updated quickly.
    [Tags]    critical
    ${default_json_normalized}=    Normalize_And_Save_Json    ${default_json}    020_Topology_Default.json    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${default_json_normalized}    020_Topology_Default.json

Update_Delegated
    [Documentation]    Perform update-lsp on the mocked tunnel, check response is success.
    [Tags]    critical
    ${text}=    Update_Xml_Lsp_Return_Json    ${update_delegated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel.
    [Tags]    critical
    ${updated_json_normalized}=    Normalize_And_Save_Json    ${updated_json}    030_Topology_Updated.json    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_json_normalized}    030_Topology_Updated.json

Refuse_Remove_Delegated
    [Documentation]    Perform remove-lsp on the mocked tunnel, check that mock-pcc has refused to remove it.
    [Tags]    critical
    ${text}=    Remove_Xml_Lsp_Return_Json    ${remove_delegated_xml}
    Pcep_Json_Is_Refused    ${text}

Topology_Still_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel, to verify that refusal did not break topology.
    [Tags]    critical
    ${updated_json_normalized}=    Normalize_And_Save_Json    ${updated_json}    040_Topology_Still_Updated.json    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_json_normalized}    040_Topology_Still_Updated.json

Add_Instantiated
    [Documentation]    Perform add-lsp to create new tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Add_Xml_Lsp_Return_Json    ${add_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Second_Default
    [Documentation]    Compare pcep-topology to default_json, which includes the updated delegated and default instantiated tunnel.
    [Tags]    critical
    ${updated_default_json_normalized}=    Normalize_And_Save_Json    ${updated_default_json}    050_Topology_Second_Default.json    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_default_json_normalized}    050_Topology_Second_Default.json

Update_Instantiated
    [Documentation]    Perform update-lsp on the newly instantiated tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Update_Xml_Lsp_Return_Json    ${update_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Second_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated delegated and updated instantiated tunnel.
    [Tags]    critical
    ${updated_updated_json_normalized}=    Normalize_And_Save_Json    ${updated_updated_json}    060_Topology_Second_Updated.json    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_updated_json_normalized}    060_Topology_Second_Updated.json

Remove_Instantiated
    [Documentation]    Perform remove-lsp on the instantiated tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Remove_Xml_Lsp_Return_Json    ${remove_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Again_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel, to verify that instantiated tunnel was removed.
    [Tags]    critical
    ${updated_json_normalized}=    Normalize_And_Save_Json    ${updated_json}    070_Topology_Again_Updated.json    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_json_normalized}    070_Topology_Again_Updated.json

Stop_Pcc_Mock
    [Documentation]    Send ctrl+c to pcc-mock, fails if no prompt is seen
    ...    after 3 seconds (the default for SSHLibrary)
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

Topology_Postcondition
    [Documentation]    Compare curent pcep-topology to "off_json" again.
    [Tags]    critical
    ${off_json_normalized}=    Normalize_And_Save_Json    ${off_json}    080_Topology_Postcondition.json    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    Wait_Until_Keyword_Succeeds    10s    1s    Compare_Topology    ${off_json_normalized}    080_Topology_Postcondition

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to Mininet machine, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to Mininet.
    ...    Also, delete and create directories for json diff handling.
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    OperatingSystem.Remove_Directory    ${DIRECTORY_FOR_EXPECTED_RESPONSES}    recursive=True
    OperatingSystem.Remove_Directory    ${DIRECTORY_FOR_ACTUAL_RESPONSES}    recursive=True
    OperatingSystem.Create_Directory    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    OperatingSystem.Create_Directory    ${DIRECTORY_FOR_ACTUAL_RESPONSES}
    PcepOperations.Setup_Pcep_Operations

Tear_It_Down
    [Documentation]    Download pccmock.log and Log its contents.
    ...    Compute and Log the diff between expected and actual normalized responses.
    ...    Close both HTTP client session and SSH connection to Mininet.
    SSHLibrary.Get_File    pccmock.log
    ${pccmocklog}=    OperatingSystem.Run    cat pccmock.log
    BuiltIn.Log    ${pccmocklog}
    ${diff}=    OperatingSystem.Run    diff -dur ${DIRECTORY_FOR_EXPECTED_RESPONSES} ${DIRECTORY_FOR_ACTUAL_RESPONSES}
    BuiltIn.Log    ${diff}
    PcepOperations.Teardown_Pcep_Operations
    Delete_All_Sessions
    Close_All_Connections

Compare_Topology
    [Arguments]    ${normexp}    ${name}
    [Documentation]    Get current pcep-topology as json, normalize both expected and actual json.
    ...    Save normalized jsons to files for later processing.
    ...    Error codes and normalized jsons should match exactly.
    ${resp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${OPERATIONAL_TOPO_API}/topology/pcep-topology
    BuiltIn.Log    ${resp}
    BuiltIn.Log    ${resp.text}
    ${normresp}=    Normalize_And_Save_Json    ${resp.text}    ${name}    ${DIRECTORY_FOR_EXPECTED_RESPONSES}
    BuiltIn.Log    ${normresp}
    # Ignoring errors so I can test new node session state
    Run Keyword And Ignore Error    BuiltIn.Should_Be_Equal_As_Strings    ${resp.status_code}    200
    Run Keyword And Ignore Error    BuiltIn.Should_Be_Equal    ${normresp}    ${normexp}
    # New Node Session State Log to see whether the two results match
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}
    ${resp}=    TemplatedRequests.Get_As_Json_Templated    ${NODE_SESSION_STATE_FOLDER}    ${mapping}    ${CONFIG_SESSION}
    BuiltIn.Log    ${resp}

Normalize_And_Save_Json
    [Arguments]    ${json_text}    ${name}    ${directory}
    [Documentation]    Normalize given json using norm_json library. Log and save the result to given filename under given directory.
    ${json_normalized}=    norm_json.normalize_json_text    ${json_text}
    BuiltIn.Log    ${json_normalized}
    OperatingSystem.Create_File    ${directory}${/}${name}    ${json_normalized}
    [Return]    ${json_normalized}
