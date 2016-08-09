*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote     http://127.0.0.1:8270    WITH NAME    RemoteLib

*** Variables ***

*** Test Cases ***
Remote Library Test
    ${resp}    RemoteLib.Library Echo
    Should Be Equal    ${resp}    OK

Connectivity Test
    : FOR    ${num}    IN RANGE    0    2000
    \    Add Connection To Nodes
    ${time_elapsed}    RemoteLib.Open Connections
    Log To Console    ${time_elapsed}
    RemoteLib.Shutdown Nodes

*** Keywords ***
Add Connection To Nodes
    [Arguments]    ${mode_local}=listener    ${mode_remote}=speaker    ${version}=version4    ${PASSWORD}=${EMPTY}
    [Documentation]
    ${address}    RemoteLib.Add Connection    ${version}    ${mode_remote}    127.0.0.1    64999    ${PASSWORD}
    LOG    ${address}
    Add Connection    ${version}    ${mode_local}    ${address}    64999    127.0.0.1    ${PASSWORD}

