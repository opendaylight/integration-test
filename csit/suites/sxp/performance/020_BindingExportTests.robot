*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Teardown     Test Clean
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote    http://127.0.0.1:8270/ExportTestLibrary    WITH NAME    ExportLibrary

*** Variables ***
${TESTED_NODE}    127.0.0.1
${SOURCE_NODE}    127.1.0.1
${DESTINATION_NODE}    127.1.0.2

*** Test Cases ***
Remote Library Test
    [Documentation]    TODO
    ${resp}    ExportLibrary.Library Echo
    Should Not Be Equal    ${resp}    ${EMPTY}
    Log To Console    \n${resp}

Binding Forwarding Export Test
    [Documentation]    TODO
    @{ITEMS}    Create List
    Log To Console    \n\tBinding Export statistics.
    : FOR    ${num}    IN RANGE    0    10
    \    Setup Binding Export Topology
    \    ExportLibrary.Initiate Export    5.5.0.0/16    112
    \    ${ELEMENT}    Wait Until Keyword Succeeds    45    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Log To Console    \tExport speed of measurement ${num + 1}: ${ELEMENT} bindings/s.
    \    Test Clean
    ${export_speed}    Get Average Of Items    ${ITEMS}
    Log To Console    \n\tAverage export speed ${export_speed} bindings/s.\n
    Should Be True    ${export_speed} > 2000

*** Keywords ***
Setup Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}
    [Documentation]    TODO
    ExportLibrary.Setup Nodes    version4    64999   ${PASSWORD}    ${SOURCE_NODE}    ${DESTINATION_NODE}
    ExportLibrary.Add Connection    ${version}    speaker    ${TESTED_NODE}    64999    ${PASSWORD}    ${SOURCE_NODE}
    ExportLibrary.Add Connection    ${version}    listener    ${TESTED_NODE}    64999    ${PASSWORD}    ${DESTINATION_NODE}

    ExportLibrary.Start Nodes
    Add Connection    ${version}    listener    ${SOURCE_NODE}    64999    ${TESTED_NODE}    ${PASSWORD}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    ${SOURCE_NODE}    64999    ${TESTED_NODE}
    Add Connection    ${version}    speaker    ${DESTINATION_NODE}    64999    ${TESTED_NODE}    ${PASSWORD}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    ${DESTINATION_NODE}    64999    ${TESTED_NODE}

Check Bindings Exported
    [Arguments]
    [Documentation]    TODO
    ${bindings_exported}    ExportLibrary.Get Bindings Exchange Count
    ${total_export_time}    ExportLibrary.Get Export Time Total
    ${current_export_time}    ExportLibrary.Get Export Time Current
    #Log To Console    \tExported Bindings: ${bindings_exported} after ${current_export_time} seconds.
    Should Not Be Equal    ${total_export_time}    0
    Should Be Equal    ${total_export_time}    ${current_export_time}
    ${export_speed}    div    ${bindings_exported}    ${total_export_time}
    [return]    ${export_speed}

Test Clean
    [Arguments]
    [Documentation]    TODO
    ExportLibrary.Clean Library
    Clean Connections    ${TESTED_NODE}

