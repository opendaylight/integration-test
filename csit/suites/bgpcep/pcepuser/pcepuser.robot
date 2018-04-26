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
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../variables/Variables.robot
Variables         ../../../variables/pcepuser/variables.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${CONFIG_SESSION}    session
${PATH_SESSION_URI}    node/pcc:%2F%2F${TOOLS_SYSTEM_IP}/path-computation-client
${PCEP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/pcepuser/

*** Test Cases ***
Topology_Precondition
    [Documentation]    Compare current pcep-topology to off_json variable.
    ...    Timeout is long enough to ODL boot, to see that pcep is ready, with no PCC is connected.
    [Tags]    critical
    Wait_Until_Keyword_Succeeds    300s    1s    Compare_Topology    ${off_json}

Start_Pcc_Mock
    [Documentation]    Execute pcc-mock on Mininet, fail is Open is not sent, keep it running for next tests.
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --reconnect 1 --local-address ${TOOLS_SYSTEM_IP} --remote-address ${ODL_SYSTEM_IP} 2>&1 | tee pccmock.log
    Log    ${command}
    Write    ${command}
    Read_Until    started, sent proposal Open

Configure_Speaker_Entity_Identifier
    [Documentation]    Additional PCEP Speaker configuration for at least oxygen streams.
    ...    Allows PCEP speaker to determine if state synchronization can be skipped when a PCEP session is restarted.
    CompareStream.Run_Keyword_If_Less_Than_Oxygen    BuiltIn.Pass_Execution    Test case valid only for versions oxygen and above.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${PCEP_VARIABLES_FOLDER}${/}node_speaker_entity_identifier    mapping=${mapping}    session=${CONFIG_SESSION}

Topology_Default
    [Documentation]    Compare pcep-topology to default_json, which includes a tunnel from pcc-mock.
    ...    Timeout is lower than in Precondition, as state from pcc-mock should be updated quickly.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${default_json}    ${PATH_SESSION_URI}

Update_Delegated
    [Documentation]    Perform update-lsp on the mocked tunnel, check response is success.
    [Tags]    critical
    ${text}=    Update_Xml_Lsp_Return_Json    ${update_delegated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_json}    ${PATH_SESSION_URI}

Refuse_Remove_Delegated
    [Documentation]    Perform remove-lsp on the mocked tunnel, check that mock-pcc has refused to remove it.
    [Tags]    critical
    ${text}=    Remove_Xml_Lsp_Return_Json    ${remove_delegated_xml}
    Pcep_Json_Is_Refused    ${text}

Topology_Still_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel, to verify that refusal did not break topology.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_json}    ${PATH_SESSION_URI}

Add_Instantiated
    [Documentation]    Perform add-lsp to create new tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Add_Xml_Lsp_Return_Json    ${add_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Second_Default
    [Documentation]    Compare pcep-topology to default_json, which includes the updated delegated and default instantiated tunnel.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_default_json}    ${PATH_SESSION_URI}

Update_Instantiated
    [Documentation]    Perform update-lsp on the newly instantiated tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Update_Xml_Lsp_Return_Json    ${update_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Second_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated delegated and updated instantiated tunnel.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_updated_json}    ${PATH_SESSION_URI}

Remove_Instantiated
    [Documentation]    Perform remove-lsp on the instantiated tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Remove_Xml_Lsp_Return_Json    ${remove_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Again_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel, to verify that instantiated tunnel was removed.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    10s    1s    Compare_Topology    ${updated_json}    ${PATH_SESSION_URI}

Stop_Pcc_Mock
    [Documentation]    Send ctrl+c to pcc-mock, fails if no prompt is seen
    ...    after 3 seconds (the default for SSHLibrary)
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

Topology_Postcondition
    [Documentation]    Compare curent pcep-topology to "off_json" again.
    [Tags]    critical
    Wait_Until_Keyword_Succeeds    10s    1s    Compare_Topology    ${off_json}

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to Mininet machine, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to Mininet.
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    PcepOperations.Setup_Pcep_Operations

Tear_It_Down
    [Documentation]    Download pccmock.log and Log its contents.
    ...    Compute and Log the diff between expected and actual normalized responses.
    ...    Close both HTTP client session and SSH connection to Mininet.
    SSHLibrary.Get_File    pccmock.log
    ${pccmocklog}=    OperatingSystem.Run    cat pccmock.log
    BuiltIn.Log    ${pccmocklog}
    PcepOperations.Teardown_Pcep_Operations
    Delete_All_Sessions
    Close_All_Connections

Compare_Topology
    [Arguments]    ${exp}    ${uri}=${EMPTY}
    [Documentation]    Get current pcep-topology as json, compare both expected and actual json.
    ...    Error codes and normalized jsons should match exactly.
    # TODO: Add Node Session State Check For Oxygen, see tcpmd5user
    # TODO: Possibly remake all tests with TemplatedRequests
    ${response}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${OPERATIONAL_TOPO_API}/topology/pcep-topology/${uri}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200
    TemplatedRequests.Normalize_Jsons_And_Compare    ${exp}    ${response.text}
