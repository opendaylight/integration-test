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
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/PcepOperations.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/pcepuser/variables.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${OUTPUT_TIMEOUT}    10
# FIXME: Unify parameter naming and case.
${ExpDir}         ${CURDIR}/expected
${ActDir}         ${CURDIR}/actual

*** Test Cases ***
Topology_Precondition
    [Documentation]    Compare current pcep-topology to off_json variable.
    ...    Timeout is long enough to ODL boot, to see that pcep is ready, with no PCC is connected.
    [Tags]    critical
    Wait_Until_Keyword_Succeeds    300    1    Compare_Topology    ${off_json}    010_Topology_Precondition

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
    Wait_Until_Keyword_succeeds    5    1    Compare_Topology    ${default_json}    020_Topology_Default

Update_Delegated
    [Documentation]    Perform update-lsp on the mocked tunnel, check response is success.
    [Tags]    critical
    ${text}=    Update_Xml_Lsp_Return_Json    ${update_delegated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    5    1    Compare_Topology    ${updated_json}    030_Topology_Updated

Refuse_Remove_Delegated
    [Documentation]    Perform remove-lsp on the mocked tunnel, check that mock-pcc has refused to remove it.
    [Tags]    critical
    ${text}=    Remove_Xml_Lsp_Return_Json    ${remove_delegated_xml}
    Pcep_Json_Is_Refused    ${text}

Topology_Still_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel, to verify that refusal did not break topology.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    5    1    Compare_Topology    ${updated_json}    040_Topology_Still_Updated

Add_Instantiated
    [Documentation]    Perform add-lsp to create new tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Add_Xml_Lsp_Return_Json    ${add_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Second_Default
    [Documentation]    Compare pcep-topology to default_json, which includes the updated delegated and default instantiated tunnel.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    5    1    Compare_Topology    ${updated_default_json}    050_Topology_Second_Default

Update_Instantiated
    [Documentation]    Perform update-lsp on the newly instantiated tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Update_Xml_Lsp_Return_Json    ${update_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Second_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated delegated and updated instantiated tunnel.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    5    1    Compare_Topology    ${updated_updated_json}    060_Topology_Second_Updated

Remove_Instantiated
    [Documentation]    Perform remove-lsp on the instantiated tunnel, check that response is success.
    [Tags]    critical
    ${text}=    Remove_Xml_Lsp_Return_Json    ${remove_instantiated_xml}
    Pcep_Json_Is_Success    ${text}

Topology_Again_Updated
    [Documentation]    Compare pcep-topology to default_json, which includes the updated tunnel, to verify that instantiated tunnel was removed.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    5    1    Compare_Topology    ${updated_json}    070_Topology_Again_Updated

Stop_Pcc_Mock
    [Documentation]    Send ctrl+c to pcc-mock, fails if no prompt is seen
    ...    after 3 seconds (the default for SSHLibrary)
    ${command}=    Evaluate    chr(int(3))
    Log    ${command}
    Write    ${command}
    Read_Until_Prompt

Topology_Postcondition
    [Documentation]    Compare curent pcep-topology to "off_json" again.
    [Tags]    critical
    Wait_Until_Keyword_Succeeds    5    1    Compare_Topology    ${off_json}    080_Topology_Postcondition

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to Mininet machine, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to Mininet.
    ...    Also, delete and create directories for json diff handling.
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    # FIXME: Unify Module prefix usage across whole file.
    Create_Session    ses    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/restconf/operational/network-topology:network-topology    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    Remove_Directory    ${ExpDir}
    Remove_Directory    ${ActDir}
    Create_Directory    ${ExpDir}
    Create_Directory    ${ActDir}
    Setup_Pcep_Operations

Compare_Topology
    [Arguments]    ${expected}    ${name}
    [Documentation]    Get current pcep-topology as json, normalize both expected and actual json.
    ...    Save normalized jsons to files for later processing.
    ...    Error codes and normalized jsons should match exactly.
    ${normexp}=    Hsf_Json    ${expected}
    Log    ${normexp}
    Create_File    ${ExpDir}${/}${name}    ${normexp}
    ${resp}=    RequestsLibrary.Get Request    ses    topology/pcep-topology
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
    Delete_All_Sessions
    Close_All_Connections
