*** Settings ***
Documentation     Test suite to test scalability of SXP
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Setup        Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Test Mega Topology
    [Documentation]     Stress test that contains of connecting 20 Nodes and exporting their bindings
    Setup Mega Topology
    Sleep    5s
    ${resp}    Get Bindings Master Database    127.0.0.1
    :FOR    ${num}    IN RANGE    2    22
    \    ${ip}    Get Ip From Number    ${num}
    \    Should Contain Binding    ${resp}    ${num}    ${ip}/32    sxp

Test Complex Mega Topology
    [Documentation]     Stress test that contains of connecting 30 Nodes and exporting their bindings
    Setup Complex Mega Topology
    Sleep    5s
    ${resp}    Get Bindings Master Database    127.0.0.1
    :FOR    ${num}    IN RANGE    22    32
    \    ${ip}    Get Ip From Number    ${num}
    \    Should Contain Binding    ${resp}    ${num}    ${ip}/32    sxp

Text Bindings export
    [Documentation]     Stress test that consist of exporting 500 Bindings under 5s
    :FOR    ${num}    IN RANGE    2    502
    \    ${ip}    Get Ip From Number    ${num}
    \    Add Binding    ${num}    ${ip}/32    127.0.0.2
    Add Connection    version4    listener    127.0.0.2    64999    127.0.0.1
    Add Connection    version4    speaker    127.0.0.1    64999    127.0.0.2
    Sleep   5s
    ${resp}    Get Bindings Master Database    127.0.0.1
    :FOR    ${num}    IN RANGE    2    102
    \    ${ip}    Get Ip From Number    ${num}
    \    Should Contain Binding    ${resp}    ${num}    ${ip}/32    sxp

*** Keywords ***
Setup Mega Topology
    [Arguments]    ${version}=version4
    :FOR    ${num}    IN RANGE    2    22
    \    ${ip}    Get Ip From Number    ${num}
    \    Add Binding    ${num}    ${ip}/32    ${ip}
    \    Add Connection    ${version}    listener    ${ip}    64999    127.0.0.1
    \    Add Connection    ${version}    speaker    127.0.0.1    64999    ${ip}

Setup Complex Mega Topology
    [Arguments]    ${version}=version4
    Setup Mega Topology    ${version}
    ${second_num}    Convert To Integer    2
    :FOR    ${num}    IN RANGE    22    32
    \    ${ip}    Get Ip From Number    ${num}
    \    ${second_ip}    Get Ip From Number    ${second_num}
    \    Add Binding    ${num}    ${ip}/32    ${ip}
    \    Add Connection    ${version}    listener    ${ip}    64999    ${second_ip}
    \    Add Connection    ${version}    speaker    ${second_ip}    64999    ${ip}
    \    ${second_num}    Set Variable      ${second_num + 1}
    \    ${second_ip}    Get Ip From Number    ${second_num}
    \    Add Connection    ${version}    listener    ${ip}    64999    ${second_ip}
    \    Add Connection    ${version}    speaker    ${second_ip}    64999    ${ip}


Clean Nodes
    :FOR    ${num}    IN RANGE    1    32
    \    ${ip}    Get Ip From Number    ${num}
    \    Clean Connections    ${ip}
    \    Clean Bindings    ${ip}
