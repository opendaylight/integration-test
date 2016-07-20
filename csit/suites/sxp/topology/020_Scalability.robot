*** Settings ***
Documentation     Test suite to test scalability of SXP
Suite Setup       Setup SXP Environment    32
Suite Teardown    Clean SXP Environment    32
Test Setup        Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot

*** Variables ***

*** Test Cases ***
Test Mega Topology
    [Documentation]    Stress test that contains of connecting 20 Nodes and exporting their bindings
    [Tags]    SXP    Scalability
    Setup Mega Topology
    Wait Until Keyword Succeeds    10    1    Check Binding Range    2    22

Test Complex Mega Topology
    [Documentation]    Stress test that contains of connecting 30 Nodes and exporting their bindings
    [Tags]    SXP    Scalability
    Setup Complex Mega Topology
    Wait Until Keyword Succeeds    10    1    Check Binding Range    22    32

Text Bindings export
    [Documentation]    Stress test that consist of exporting 500 Bindings under 5s
    [Tags]    SXP    Scalability
    : FOR    ${num}    IN RANGE    2    502
    \    ${ip}    Get Ip From Number    ${num}
    \    Add Binding    ${num}    ${ip}/32    127.0.0.2
    Add Connection    version4    listener    127.0.0.2    64999    127.0.0.1
    Add Connection    version4    speaker    127.0.0.1    64999    127.0.0.2
    Wait Until Keyword Succeeds    15    1    Verify Connection    version4    listener    127.0.0.2
    Wait Until Keyword Succeeds    10    1    Check Binding Range    2    102

*** Keywords ***
Setup Mega Topology
    [Arguments]    ${version}=version4
    : FOR    ${num}    IN RANGE    2    22
    \    ${ip}    Get Ip From Number    ${num}
    \    Add Binding    ${num}    ${ip}/32    ${ip}
    \    Add Connection    ${version}    listener    ${ip}    64999    127.0.0.1
    \    Add Connection    ${version}    speaker    127.0.0.1    64999    ${ip}
    \    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener
    \    ...    ${ip}

Setup Complex Mega Topology
    [Arguments]    ${version}=version4
    Setup Mega Topology    ${version}
    ${second_num}    Convert To Integer    2
    : FOR    ${num}    IN RANGE    22    32
    \    ${ip}    Get Ip From Number    ${num}
    \    ${second_ip}    Get Ip From Number    ${second_num}
    \    Add Binding    ${num}    ${ip}/32    ${ip}
    \    Add Connection    ${version}    listener    ${ip}    64999    ${second_ip}
    \    Add Connection    ${version}    speaker    ${second_ip}    64999    ${ip}
    \    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener
    \    ...    ${ip}    64999    ${second_ip}
    \    ${second_num}    Set Variable    ${second_num + 1}
    \    ${second_ip}    Get Ip From Number    ${second_num}
    \    Add Connection    ${version}    listener    ${ip}    64999    ${second_ip}
    \    Add Connection    ${version}    speaker    ${second_ip}    64999    ${ip}
    \    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener
    \    ...    ${ip}    64999    ${second_ip}

Check Binding Range
    [Arguments]    ${start}    ${end}    ${node}=127.0.0.1
    [Documentation]    Check if binding range is contained by node
    ${resp}    Get Bindings    ${node}
    : FOR    ${num}    IN RANGE    ${start}    ${end}
    \    ${ip}    Get Ip From Number    ${num}
    \    Should Contain Binding    ${resp}    ${num}    ${ip}/32    sxp

Clean Nodes
    : FOR    ${num}    IN RANGE    1    32
    \    ${ip}    Get Ip From Number    ${num}
    \    Clean Bindings    ${ip}
    \    Clean Connections    ${ip}
