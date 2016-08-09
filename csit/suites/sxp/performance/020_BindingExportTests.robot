*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Test Setup        Setup SXP Environment
Test Teardown     Test Clean
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote    http://127.0.0.1:8270/ExportTestLibrary    WITH NAME    ExportLibrary

*** Variables ***
${TESTED_NODE}    127.0.0.1
${DESTINATION_IP}    2130837505
${SOURCE_IP}    2130771969
${EXPORT_AMOUNT}       100000
${FORWARD_AMOUNT}       100000

*** Test Cases ***
Remote Library Test
    [Documentation]    TODO
    ${resp}    ExportLibrary.Library Echo
    Should Not Be Equal    ${resp}    ${EMPTY}
    Log To Console    \n${resp}

Binding Export Test
    [Documentation]    TODO
    @{ITEMS}    Create List
    Log To Console    \n\tBinding Export statistics.
    Add Bindings Range    112    0    ${EXPORT_AMOUNT}    ${TESTED_NODE}
    : FOR    ${num}    IN RANGE    0    10
    \    Setup Simple Binding Export Topology
    \    ExportLibrary.Initiate Simple Export    ${TESTED_NODE}    ${EXPORT_AMOUNT}
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Log To Console    \tExport speed of measurement ${num + 1}: ${ELEMENT} bindings/s.
    \    ExportLibrary.Clean Library
    \    Clean Connections    ${TESTED_NODE}
    ${export_speed}    Get Average Of Items    ${ITEMS}
    Log To Console    \n\tAverage export speed ${export_speed} bindings/s.\n
    Should Be True    ${export_speed} > 2000

Binding Forwarding Export Test
    [Documentation]    TODO
    @{ITEMS}    Create List
    Log To Console    \n\tBinding Export statistics.
    : FOR    ${num}    IN RANGE    0    10
    \    Setup Binding Export Topology
    \    ExportLibrary.Initiate Export    5.5.0.0/16    112
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Log To Console    \tExport speed of measurement ${num + 1}: ${ELEMENT} bindings/s.
    \    ExportLibrary.Clean Library
    \    Clean Connections    ${TESTED_NODE}
    ${export_speed}    Get Average Of Items    ${ITEMS}
    Log To Console    \n\tAverage export speed ${export_speed} bindings/s.\n
    Should Be True    ${export_speed} > 2000

*** Keywords ***
Setup Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}    ${destination_nodes}=3
    [Documentation]    TODO
    Setup Simple Binding Export Topology    ${version}    ${PASSWORD}
    : FOR    ${num}    IN RANGE    0    ${destination_nodes}
    \    ${DESTINATION_NODE}    Get Ip From Number    ${num}    ${DESTINATION_IP}
    \    ExportLibrary.Add Connection    ${version}    listener    ${TESTED_NODE}    64999    ${PASSWORD}    ${DESTINATION_NODE}
    \    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    ${DESTINATION_NODE}    64999    ${TESTED_NODE}

Setup Simple Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}    ${destination_nodes}=3    ${source_nodes}=1
    [Documentation]    TODO
    : FOR    ${num}    IN RANGE    0    ${source_nodes}
    \    ${SOURCE_NODE}    Get Ip From Number    ${num}    ${SOURCE_IP}
    \    ExportLibrary.Add Node    ${SOURCE_NODE}    ${version}    64999    ${PASSWORD}
    \    ExportLibrary.Add Connection    ${version}    speaker    ${TESTED_NODE}    64999    ${PASSWORD}    ${SOURCE_NODE}
    : FOR    ${num}    IN RANGE    0    ${destination_nodes}
    \    ${DESTINATION_NODE}    Get Ip From Number    ${num}    ${DESTINATION_IP}
    \    ExportLibrary.Add Destination Node    ${DESTINATION_NODE}    ${version}    64999    ${PASSWORD}
    \    Add Connection    ${version}    speaker    ${DESTINATION_NODE}    64999    ${TESTED_NODE}    ${PASSWORD}
    ExportLibrary.Start Nodes
    : FOR    ${num}    IN RANGE    0    ${source_nodes}
    \    ${SOURCE_NODE}    Get Ip From Number    ${num}    ${SOURCE_IP}
    \    Add Connection    ${version}    listener    ${SOURCE_NODE}    64999    ${TESTED_NODE}    ${PASSWORD}
    \    Wait Until Keyword Succeeds    60    2    Verify Connection    ${version}    listener    ${SOURCE_NODE}    64999    ${TESTED_NODE}

Check Bindings Exported
    [Documentation]    TODO
    ${bindings_exported}    ExportLibrary.Get Bindings Exchange Count
    ${total_export_time}    ExportLibrary.Get Export Time Total
    ${current_export_time}    ExportLibrary.Get Export Time Current
    Log To Console    \tBindings exported ${bindings_exported} per ${current_export_time} seconds.\n
    Should Not Be Equal    ${total_export_time}    0
    Should Be Equal    ${total_export_time}    ${current_export_time}
    ${export_speed}    div    ${bindings_exported}    ${total_export_time}
    [Return]    ${export_speed}

Test Clean
    [Documentation]    TODO
    ExportLibrary.Clean Library
    Clean Connections    ${TESTED_NODE}
    Clean SXP Environment
