*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Test Setup        Setup SXP Environment
Test Teardown     Test Clean
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote    http://127.0.0.1:8270/ExportTestLibrary    WITH NAME    ExportLibrary
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Common.py

*** Variables ***
${TESTED_NODE}    127.0.0.1
${DESTINATION_IP}    2130837505
${SOURCE_IP}    2130771969
${EXPORT_AMOUNT}       65536

*** Test Cases ***
Remote Library Test
    [Documentation]    TODO
    ${resp}    ExportLibrary.Library Echo
    Should Not Be Equal    ${resp}    ${EMPTY}
    Log To Console    \n${resp}

Binding Export Test
    [Documentation]    TODO
    pass execution    SKIP
    @{ITEMS}    Create List
    Log To Console    \n\tBinding Export statistics.
    Add Bindings Range    112    84213760    ${EXPORT_AMOUNT}    ${TESTED_NODE}
    ${export_speed}    Simple Export    ${EXPORT_AMOUNT}
    Log To Console    \n\tAverage export speed ${export_speed} bindings/s.\n
    Should Be True    ${export_speed} > 2000

Binding Forwarding Export Test
    [Documentation]    TODO
    #pass execution    SKIP
    @{ITEMS}    Create List
    Log To Console    \n\tBinding Export statistics.
    ${export_speed}    Forwarding Export    ${EXPORT_AMOUNT}
    Log To Console    \n\tAverage export speed ${export_speed} bindings/s.\n
    Should Be True    ${export_speed} > 2000

Binding Outbound Filter Export Test
    [Documentation]    Outbount
    pass execution    SKIP
    Add Bindings Range    112    84213760    ${EXPORT_AMOUNT}    ${TESTED_NODE}
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate	100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    int(__import__('math').ceil( ${EXPORT_AMOUNT}*${passrate}/100 ))
    \    ${tmp}    Convert To String    ${exported_bindings}
    \    Setup Filter    ${num}    outbound
    \    ${export_speed}    Simple Export    ${tmp}    10
    \    Log To Console    \tOutbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Clean Peer Groups

Binding Inbound Filter Forwarding Export Test
    [Documentation]    Outbount
    pass execution    SKIP
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate	100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    int(__import__('math').ceil( ${EXPORT_AMOUNT}*${passrate}/100 ))
    \    ${tmp}    Convert To String    ${exported_bindings}
    \    Setup Filter    ${num}    inbound-discarding
    \    ${export_speed}    Forwarding Export    ${tmp}    10
    \    Log To Console    \tOutbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Clean Peer Groups


Binding Inbound-Discarding Filter Forwarding Export Test
    [Documentation]    Outbount
    pass execution    SKIP
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate	100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    int(__import__('math').ceil( ${EXPORT_AMOUNT}*${passrate}/100 ))
    \    ${tmp}    Convert To String    ${exported_bindings}
    \    Setup Filter    ${num}    inbound-discarding
    \    ${export_speed}    Forwarding Export    ${tmp}    10
    \    Log To Console    \tOutbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Clean Peer Groups

Binding Domain Filter Export Test
    [Documentation]    Outbount
    pass execution    SKIP
    Add Bindings Range    112    84213760    ${EXPORT_AMOUNT}    ${TESTED_NODE}
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate	100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    int(__import__('math').ceil( ${EXPORT_AMOUNT}*${passrate}/100 ))
    \    ${tmp}    Convert To String    ${exported_bindings}
    \    Setup Domain Filter    ${num}    test-domain
    \    ${export_speed}    Simple Export    ${tmp}    10    test-domain
    \    Log To Console    \tOutbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Delete Domain Filter    global

Binding Domain Filter Forwarding Export Test
    [Documentation]    Outbount
    pass execution    SKIP
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate	100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    int(__import__('math').ceil( ${EXPORT_AMOUNT}*${passrate}/100 ))
    \    ${tmp}    Convert To String    ${exported_bindings}
    \    Setup Domain Filter    ${num}    test-domain
    \    ${export_speed}    Forwarding Export    ${tmp}    10    test-domain
    \    Log To Console    \tOutbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Delete Domain Filter    global

Binding Combined Filter Export Test
    [Documentation]    Outbount
    pass execution    SKIP
    Add Bindings Range    112    84213760    ${EXPORT_AMOUNT}    ${TESTED_NODE}
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate	100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    int(__import__('math').ceil( ${EXPORT_AMOUNT}*${passrate}/100 ))
    \    ${tmp}    Convert To String    ${exported_bindings}
    \    Setup Domain Filter    ${num}    test-domain
    \    Setup Filter    ${num}    outbound
    \    ${export_speed}    Simple Export    ${tmp}    10    test-domain
    \    Log To Console    \tOutbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Delete Domain Filter    global
    \    Clean Peer Groups

Binding Combined Filter Forwarding Export Test
    [Documentation]    Outbount
    pass execution    SKIP
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate	100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    int(__import__('math').ceil( ${EXPORT_AMOUNT}*${passrate}/100 ))
    \    ${tmp}    Convert To String    ${exported_bindings}
    \    Setup Domain Filter    ${num}    test-domain
    \    Setup Filter    ${num}    inbound-discarding
    \    ${export_speed}    Forwarding Export    ${tmp}    10    test-domain
    \    Log To Console    \tOutbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Delete Domain Filter    global
    \    Clean Peer Groups

*** Keywords ***
Setup Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}    ${destination_nodes}=3        ${destination_domain}=global
    [Documentation]    TODO
    Setup Simple Binding Export Topology    ${version}    ${PASSWORD}     ${destination_nodes}    1    ${destination_domain}
    : FOR    ${num}    IN RANGE    0    ${destination_nodes}
    \    ${DESTINATION_NODE}    Get Ip From Number    ${num}    ${DESTINATION_IP}
    \    ExportLibrary.Add Connection    ${version}    listener    ${TESTED_NODE}    64999    ${PASSWORD}    ${DESTINATION_NODE}
    \    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    ${DESTINATION_NODE}    64999    ${TESTED_NODE}        domain=${destination_domain}

Setup Simple Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}    ${destination_nodes}=3    ${source_nodes}=1    ${destination_domain}=global
    [Documentation]    TODO
    : FOR    ${num}    IN RANGE    0    ${source_nodes}
    \    ${SOURCE_NODE}    Get Ip From Number    ${num}    ${SOURCE_IP}
    \    ExportLibrary.Add Node    ${SOURCE_NODE}    ${version}    64999    ${PASSWORD}
    \    ExportLibrary.Add Connection    ${version}    speaker    ${TESTED_NODE}    64999    ${PASSWORD}    ${SOURCE_NODE}
    : FOR    ${num}    IN RANGE    0    ${destination_nodes}
    \    ${DESTINATION_NODE}    Get Ip From Number    ${num}    ${DESTINATION_IP}
    \    ExportLibrary.Add Destination Node    ${DESTINATION_NODE}    ${version}    64999    ${PASSWORD}
    \    Add Connection    ${version}    speaker    ${DESTINATION_NODE}    64999    ${TESTED_NODE}    ${PASSWORD}    domain=${destination_domain}
    ExportLibrary.Start Nodes
    : FOR    ${num}    IN RANGE    0    ${source_nodes}
    \    ${SOURCE_NODE}    Get Ip From Number    ${num}    ${SOURCE_IP}
    \    Add Connection    ${version}    listener    ${SOURCE_NODE}    64999    ${TESTED_NODE}    ${PASSWORD}
    \    Wait Until Keyword Succeeds    60    2    Verify Connection    ${version}    listener    ${SOURCE_NODE}    64999    ${TESTED_NODE}

Simple Export
    [Arguments]    ${check_amount}    ${samples}=10     ${destination_domain}=global
    [Documentation]    TODO
    @{ITEMS}    Create List
    : FOR    ${num}    IN RANGE    0    ${samples}
    \    Setup Simple Binding Export Topology        destination_domain=${destination_domain}
    \    ExportLibrary.Set Export Amount    ${check_amount}
    \    ExportLibrary.Initiate Simple Export    ${TESTED_NODE}
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    #\    Log To Console    \tExport speed of measurement ${num + 1}: ${ELEMENT} bindings/s\n.
    \    ExportLibrary.Clean Library
    \    Clean Connections    ${TESTED_NODE}
    ${export_speed}    Get Average Of Items    ${ITEMS}
    [return]    ${export_speed}

Forwarding Export
    [Arguments]    ${check_amount}    ${samples}=10     ${destination_domain}=global
    [Documentation]    TODO
    @{ITEMS}    Create List
    : FOR    ${num}    IN RANGE    0    ${samples}
    \    Setup Binding Export Topology     destination_domain=${destination_domain}
    \    ExportLibrary.Set Export Amount    ${check_amount}
    \    ExportLibrary.Initiate Export    5.5.0.0/16    112
    \    ${ELEMENT}    Wait Until Keyword Succeeds    360    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Log To Console    \tExport speed of measurement ${num + 1}: ${ELEMENT} bindings/s\n.
    \    ExportLibrary.Clean Library
    \    Clean Connections    ${TESTED_NODE}
    ${export_speed}    Get Average Of Items    ${ITEMS}
    [return]    ${export_speed}

Check Bindings Exported
    [Documentation]    TODO
    ${bindings_exported}    ExportLibrary.Get Bindings Exchange Count
    ${total_export_time}    ExportLibrary.Get Export Time Total
    ${current_export_time}    ExportLibrary.Get Export Time Current
    Log To Console    \tBindings exported ${bindings_exported} per ${current_export_time} seconds.
    Should Not Be Equal    ${total_export_time}    0
    Should Be Equal    ${total_export_time}    ${current_export_time}
    ${export_speed}    Evaluate    ${bindings_exported}/${total_export_time}
    [Return]    ${export_speed}

Setup Filter
    [Arguments]    ${bits}    ${type}
    Add PeerGroup    GROUP    ${EMPTY}
    ${entry}    Get Filter Entry    10    permit    pl=5.5.0.0/${bits}
    Add Filter    GROUP    ${type}    ${entry}    ${TESTED_NODE}

Setup Domain Filter
    [Arguments]    ${bits}    ${domain}
    Add Domain    ${domain}    ${TESTED_NODE}
    ${domains}    Add Domains    ${domain}
    ${entry}    Get Filter Entry    10    permit    pl=5.5.0.0/${bits}
    Add Domain Filter    global    ${domains}    ${entry}    ${TESTED_NODE}

Test Clean
    [Documentation]    TODO
    ExportLibrary.Clean Library
    Clean Connections    ${TESTED_NODE}
    Clean Peer Groups    ${TESTED_NODE}
    Clean SXP Environment
