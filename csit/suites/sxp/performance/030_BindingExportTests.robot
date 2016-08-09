*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Test Setup        Setup SXP Environment
Test Teardown     Test Clean
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote    http://127.0.0.1:8270/ExportTestLibrary    WITH NAME    ExportLibrary

*** Variables ***
${TESTED_NODE}    127.0.0.1
${SOURCE_NODE}    127.1.0.1
${DESTINATION_NODE}    127.1.0.2
${bindings}       10000
${forwarding_amount}    131072

*** Test Cases ***
Remote Library Test
    [Documentation]    TODO
    ${resp}    ExportLibrary.Library Echo
    Should Not Be Equal    ${resp}    ${EMPTY}
    Log To Console    \n${resp}

Binding Export Test
    [Documentation]    Outbount
    Add Bindings Range    112    84148224    ${bindings}    ${TESTED_NODE}
    : FOR    ${num}    IN RANGE    15    20
    \    ${passrate}    exp    2    ${num - 15}
    \    ${passrate}    div    100    ${passrate}
    \    Log To Console    \tOutbound Export speed with passrate ${passrate} %.
    \    ${passrate}    div    ${passrate}    100
    \    Setup Filter    ${num}    outbound
    \    ${exported_bindings}    mul    ${bindings}    ${passrate}
    \    Binding Export Test    ${exported_bindings}

Binding Forwarding Export Test
    [Documentation]    Inbound
    : FOR    ${num}    IN RANGE    15    20
    \    ${passrate}    exp    2    ${num - 15}
    \    ${passrate}    div    100    ${passrate}
    \    Log To Console    \tInbound Export speed with passrate ${passrate} %.
    \    ${passrate}    div    ${passrate}    100
    \    Setup Filter    ${num}    inbound
    \    ${exported_bindings}    mul    ${forwarding_amount}    ${passrate}
    \    Binding Forwarding Export Test    ${exported_bindings}

Binding Forwarding Export Test
    [Documentation]    Inbound-discarding
    : FOR    ${num}    IN RANGE    15    20
    \    ${passrate}    exp    2    ${num - 15}
    \    ${passrate}    div    100    ${passrate}
    \    Log To Console    \tInbound-Discarding Export speed with passrate ${passrate} %.
    \    ${passrate}    div    ${passrate}    100
    \    Setup Filter    ${num}    inbound-discarding
    \    ${exported_bindings}    mul    ${forwarding_amount}    ${passrate}
    \    Binding Forwarding Export Test    ${exported_bindings}

*** Keywords ***
Setup Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}
    [Documentation]    TODO
    Setup Simple Binding Export Topology    ${version}    ${PASSWORD}
    ExportLibrary.Add Connection    ${version}    listener    ${TESTED_NODE}    64999    ${PASSWORD}    ${DESTINATION_NODE}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    ${DESTINATION_NODE}
    ...    64999    ${TESTED_NODE}
    ExportLibrary.Add Connection    ${version}    listener    ${TESTED_NODE}    64999    ${PASSWORD}    127.1.0.3
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.1.0.3
    ...    64999    ${TESTED_NODE}
    ExportLibrary.Add Connection    ${version}    listener    ${TESTED_NODE}    64999    ${PASSWORD}    127.1.0.4
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.1.0.4
    ...    64999    ${TESTED_NODE}

Setup Simple Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}
    [Documentation]    TODO
    ExportLibrary.Add Node    ${SOURCE_NODE}    ${version}    64999    ${PASSWORD}
    ExportLibrary.Add Destination Node    ${DESTINATION_NODE}    ${version}    64999    ${PASSWORD}
    ExportLibrary.Add Destination Node    127.1.0.3    ${version}    64999    ${PASSWORD}
    ExportLibrary.Add Destination Node    127.1.0.4    ${version}    64999    ${PASSWORD}
    ExportLibrary.Add Connection    ${version}    speaker    ${TESTED_NODE}    64999    ${PASSWORD}    ${SOURCE_NODE}
    ExportLibrary.Start Nodes
    Add Connection    ${version}    listener    ${SOURCE_NODE}    64999    ${TESTED_NODE}    ${PASSWORD}
    Wait Until Keyword Succeeds    60    2    Verify Connection    ${version}    listener    ${SOURCE_NODE}
    ...    64999    ${TESTED_NODE}
    Add Connection    ${version}    speaker    ${DESTINATION_NODE}    64999    ${TESTED_NODE}    ${PASSWORD}
    Add Connection    ${version}    speaker    127.1.0.3    64999    ${TESTED_NODE}    ${PASSWORD}
    Add Connection    ${version}    speaker    127.1.0.4    64999    ${TESTED_NODE}    ${PASSWORD}

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

Binding Export Test
    [Arguments]    ${bindings_amount}
    [Documentation]    TODO
    @{ITEMS}    Create List
    : FOR    ${num}    IN RANGE    0    10
    \    Setup Simple Binding Export Topology
    \    ExportLibrary.Initiate Simple Export    ${TESTED_NODE}    ${bindings_amount}
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Log To Console    \tExport speed of measurement ${num + 1}: ${ELEMENT} bindings/s.
    \    ExportLibrary.Clean Library
    \    Clean Connections    ${TESTED_NODE}
    \    Clean Peer Groups    ${TESTED_NODE}
    ${export_speed}    Get Average Of Items    ${ITEMS}
    Log To Console    \n\tAverage export speed ${export_speed} bindings/s.\n
    Should Be True    ${export_speed} > 2000

Binding Forwarding Export Test
    [Arguments]    ${bindings_amount}
    [Documentation]    TODO
    @{ITEMS}    Create List
    Log To Console    \n\tBinding Export statistics.
    : FOR    ${num}    IN RANGE    0    10
    \    Setup Binding Export Topology
    \    ExportLibrary.Initiate Export    5.4.0.0/15    112
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Log To Console    \tExport speed of measurement ${num + 1}: ${ELEMENT} bindings/s.
    \    ExportLibrary.Clean Library
    \    Clean Connections    ${TESTED_NODE}
    \    Clean Peer Groups    ${TESTED_NODE}
    ${export_speed}    Get Average Of Items    ${ITEMS}
    Log To Console    \n\tAverage export speed ${export_speed} bindings/s.\n
    Should Be True    ${export_speed} > 2000


Setup Filter
    [Arguments]    ${bits}    ${type}
    ${peers}    Add Peers    ${DESTINATION_NODE}
    Add PeerGroup    GROUP    ${peers}
    ${entry}    Get Filter Entry    10    permit    pl=5.4.0.0/${bits}
    Add Filter    GROUP    ${type}    ${entry}

Test Clean
    [Documentation]    TODO
    ExportLibrary.Clean Library
    Clean Connections    ${TESTED_NODE}
    Clean SXP Environment