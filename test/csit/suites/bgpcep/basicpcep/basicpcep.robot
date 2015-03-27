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
Library           SSHLibrary    prompt=]>
Library           ${CURDIR}/../../../libraries/RequestsLibrary.py
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/basicpcep/variables.py    ${MININET}

*** Variables ***
${ExpDir}         ${CURDIR}/expected
${ActDir}         ${CURDIR}/actual

*** Test Cases ***
Topology_Precondition
    [Documentation]    Compare current pcep-topology to "offjson" variable.
    ...    Timeout is long enough to see that pcep is ready, with no PCC is connected.
    [Tags]    critical
    Wait_Until_Keyword_Succeeds    900    1    Compare_Topology    ${offjson}    Pre

Start_Pcc_Mock
    [Documentation]    Execute pcc-mock on Mininet, fail is Open is not sent, keep it running for next tests.
    ${command}=    Set_Variable    java -jar ${filename} --local-address ${MININET} --remote-address ${CONTROLLER} 2>&1 | tee pccmock.log
    Log    ${command}
    Write    ${command}
    Read_Until    started, sent proposal Open

Topology_Intercondition
    [Documentation]    Compare pcep-topology to "onjson", which includes a tunnel from pcc-mock.
    [Tags]    critical
    Wait_Until_Keyword_succeeds    30    1    Compare_Topology    ${onjson}    Inter

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
    Wait_Until_Keyword_Succeeds    30    1    Compare_Topology    ${offjson}    Post

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to Mininet machine, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to Mininet.
    ...    Also, delete and create directories for json diff handling.
    Open_Connection    ${MININET}
    Login_With_Public_Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Create_Session    ses    http://${CONTROLLER}:8181/restconf/operational/network-topology:network-topology    auth=${AUTH}
    ${urlbase}=    Set_Variable    https://nexus.opendaylight.org/content/repositories/opendaylight.snapshot/org/opendaylight/bgpcep/pcep-pcc-mock
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
    Delete_All_Sessions
    Close_All_Connections
