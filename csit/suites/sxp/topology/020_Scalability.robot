*** Settings ***
Documentation     Test suite to test scalability of SXP
Suite Setup       Setup SXP Environment    31
Suite Teardown    Clean SXP Environment    31
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
    BuiltIn.Wait Until Keyword Succeeds    10    1    Check Binding Range    2    22

Test Complex Mega Topology
    [Documentation]    Stress test that contains of connecting 30 Nodes and exporting their bindings
    [Tags]    SXP    Scalability
    Setup Complex Mega Topology
    BuiltIn.Wait Until Keyword Succeeds    10    1    Check Binding Range    22    32

Text Bindings export
    [Documentation]    Stress test that consist of exporting 500 Bindings under 5s
    [Tags]    SXP    Scalability
    FOR    ${num}    IN RANGE    2    502
        ${ip} =    Sxp.Get Ip From Number    ${num}
        SxpLib.Add Bindings    ${num}    ${ip}/32    127.0.0.2
    END
    SxpLib.Add Connection    version4    listener    127.0.0.2    64999    127.0.0.1
    SxpLib.Add Connection    version4    speaker    127.0.0.1    64999    127.0.0.2
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    version4    listener    127.0.0.2
    BuiltIn.Wait Until Keyword Succeeds    10    1    Check Binding Range    2    102

*** Keywords ***
Setup Mega Topology
    [Arguments]    ${version}=version4
    FOR    ${num}    IN RANGE    2    22
        ${ip} =    Sxp.Get Ip From Number    ${num}
        SxpLib.Add Bindings    ${num}    ${ip}/32    ${ip}
        SxpLib.Add Connection    ${version}    listener    ${ip}    64999    127.0.0.1
        SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    ${ip}
        BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener
        ...    ${ip}
    END

Setup Complex Mega Topology
    [Arguments]    ${version}=version4
    Setup Mega Topology    ${version}
    ${second_num}    Convert To Integer    2
    FOR    ${num}    IN RANGE    22    32
        ${ip} =    Sxp.Get Ip From Number    ${num}
        ${second_ip} =    Sxp.Get Ip From Number    ${second_num}
        SxpLib.Add Bindings    ${num}    ${ip}/32    ${ip}
        SxpLib.Add Connection    ${version}    listener    ${ip}    64999    ${second_ip}
        SxpLib.Add Connection    ${version}    speaker    ${second_ip}    64999    ${ip}
        BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener
        ...    ${ip}    64999    ${second_ip}
        ${second_num} =    Set Variable    ${second_num + 1}
        ${second_ip} =    Sxp.Get Ip From Number    ${second_num}
        SxpLib.Add Connection    ${version}    listener    ${ip}    64999    ${second_ip}
        SxpLib.Add Connection    ${version}    speaker    ${second_ip}    64999    ${ip}
        BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener
        ...    ${ip}    64999    ${second_ip}
    END

Check Binding Range
    [Arguments]    ${start}    ${end}    ${node}=127.0.0.1
    [Documentation]    Check if binding range is contained by node
    ${resp} =    SxpLib.Get Bindings    ${node}
    FOR    ${num}    IN RANGE    ${start}    ${end}
        ${ip} =    Sxp.Get Ip From Number    ${num}
        Should Contain Binding    ${resp}    ${num}    ${ip}/32
    END

Clean Nodes
    FOR    ${num}    IN RANGE    1    32
        ${ip} =    Sxp.Get Ip From Number    ${num}
        SxpLib.Clean Bindings    ${ip}
        SxpLib.Clean Connections    ${ip}
    END
