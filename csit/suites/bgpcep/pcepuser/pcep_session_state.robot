*** Settings ***
Documentation     DEBUG test for odl-bgpcep-pcep-all feature.
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
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/PcepOperations.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/RemoteBash.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../variables/Variables.robot
Variables         ../../../variables/pcepuser/variables.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${CONFIG_SESSION}    session
${PATH_SESSION_URI}    node/pcc:%2F%2F${TOOLS_SYSTEM_IP}/path-computation-client
${DIR_WITH_TEMPLATES}    ${CURDIR}/../../../variables/tcpmd5user/
${TEST_LOG_LEVEL}    TRACE
@{TEST_LOG_COMPONENTS}    org.opendaylight.bgpcep.pcep    org.opendaylight.protocol.pcep

*** Test Cases ***
Topology_Precondition
    [Documentation]    Compare current pcep-topology to off_json variable.
    ...    Timeout is long enough to ODL boot, to see that pcep is ready, with no PCC is connected.
    [Tags]    critical
    Wait_Until_Keyword_Succeeds    300s    1s    Compare_Topology    ${off_json}

Start_Pcc_Mock
    [Documentation]    Execute pcc-mock on Mininet, fail is Open is not sent, keep it running for next tests.
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --reconnect 1 --local-address ${TOOLS_SYSTEM_IP} --remote-address ${ODL_SYSTEM_IP} --log-level TRACE 2>&1 | tee pccmock.log
    SSHLibrary.Set_Client_Configuration    timeout=30s
    Log    ${command}
    Write    ${command}
    Read_Until    started

Topology_Default
    [Documentation]    Compare pcep-topology to default_on_state, which includes a path-computation and session-state
    ...    Timeout is lower than in Precondition, as state from pcc-mock should be updated quickly.
    [Tags]    critical
    ${state}    ${output}    Run Keyword And Ignore Error    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    pcep:node-state -topology-id pcep-topology -node-id pcc://${TOOLS_SYSTEM_IP}
    Run Keyword And Ignore Error    BuiltIn.Log    ${output}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    CODE=${pcc_name_code}    NAME=${pcc_name}    IP_ODL=${ODL_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    50s    5s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}default_on_state    ${mapping}
    ...    ${CONFIG_SESSION}    verify=True

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
    KarafKeywords.Setup_Karaf_Keywords
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set TRACE org.opendaylight.bgpcep.pcep
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set TRACE org.opendaylight.protocol.pcep
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    #Setting Pcc Name and its code for mapping for templates
    BuiltIn.Set_Suite_Variable    ${pcc_name}    pcc_${TOOLS_SYSTEM_IP}_tunnel_1
    ${code}=    Evaluate    binascii.b2a_base64('${pcc_name}')[:-1]    modules=binascii
    BuiltIn.Set_Suite_Variable    ${pcc_name_code}    ${code}
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
    ${response}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${OPERATIONAL_TOPO_API}/topology/pcep-topology/${uri}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200
    TemplatedRequests.Normalize_Jsons_And_Compare    ${exp}    ${response.text}
