*** Settings ***
Documentation     Test suite measuring binding export and forwarding speed.
Test Setup        Setup SXP Environment
Test Teardown     Clean SXP Environment
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote    http://${ODL_SYSTEM_IP}:8270/ExportTestLibrary    WITH NAME    ExportLibrary

*** Variables ***
# Tested Nodes IPs
${SOURCE_IP}      127.1.0.1
${DESTINATION_IP}    127.2.0.1
# Testing variables
${EXPORT_AMOUNT}    65536
${TEST_SAMPLES}    5
${MINIMAL_SPEED}    2000
# Testing Domains
${DOMAIN_0}       global
${DOMAIN_1}       test-domain

*** Test Cases ***
Binding Export Test
    [Documentation]    Test binding export speed without any filters
    Add Bindings Range    112    84213760    ${EXPORT_AMOUNT}
    ${export_speed}    Simple Export    ${EXPORT_AMOUNT}    ${TEST_SAMPLES}
    Log    Average export speed ${export_speed} bindings/s.
    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

Binding Forwarding Export Test
    [Documentation]    Test binding forwarding speed without any filters
    ${export_speed}    Forwarding Export    ${EXPORT_AMOUNT}    ${TEST_SAMPLES}
    Log    Average export speed ${export_speed} bindings/s.
    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

Binding Outbound Filter Export Test
    [Documentation]    Test binding export speed with Outbound filter and multiple passrates.
    Add Bindings Range    112    84213760    ${EXPORT_AMOUNT}
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate    100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    int(math.ceil( ${EXPORT_AMOUNT}*${passrate}/100 ))    modules=math
    \    ${exported_bindings}    Convert To String    ${exported_bindings}
    \    Setup Filter    ${num}    outbound
    \    ${export_speed}    Simple Export    ${exported_bindings}    ${TEST_SAMPLES}
    \    Log    Outbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

Binding Inbound Filter Forwarding Export Test
    [Documentation]    Test binding forwarding speed with Inbound filter and multiple passrates.
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate    100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    math.ceil( ${EXPORT_AMOUNT}*${passrate}/100 )    modules=math
    \    ${exported_bindings}    Convert To String    ${exported_bindings}
    \    Setup Filter    ${num}    inbound-discarding
    \    ${export_speed}    Forwarding Export    ${exported_bindings}    ${TEST_SAMPLES}
    \    Log    Outbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

Binding Inbound-Discarding Filter Forwarding Export Test
    [Documentation]    Test binding forwarding speed with Inbound-discarding filter and multiple passrates.
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate    100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    math.ceil( ${EXPORT_AMOUNT}*${passrate}/100 )    modules=math
    \    ${exported_bindings}    Convert To String    ${exported_bindings}
    \    Setup Filter    ${num}    inbound-discarding
    \    ${export_speed}    Forwarding Export    ${exported_bindings}    ${TEST_SAMPLES}
    \    Log    Outbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

Binding Domain Filter Export Test
    [Documentation]    Test binding export speed with domain filter and multiple passrates.
    Add Bindings Range    112    84213760    ${EXPORT_AMOUNT}
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate    100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    math.ceil( ${EXPORT_AMOUNT}*${passrate}/100 )    modules=math
    \    ${exported_bindings}    Convert To String    ${exported_bindings}
    \    Run Keyword And Ignore Error    Setup Domain Filter    ${num}    ${DOMAIN_1}
    \    ${export_speed}    Simple Export    ${exported_bindings}    ${TEST_SAMPLES}    ${DOMAIN_1}
    \    Log    Outbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

Binding Domain Filter Forwarding Export Test
    [Documentation]    Test binding forward speed with domain filter and multiple passrates.
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate    100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    math.ceil( ${EXPORT_AMOUNT}*${passrate}/100 )    modules=math
    \    ${exported_bindings}    Convert To String    ${exported_bindings}
    \    Run Keyword And Ignore Error    Setup Domain Filter    ${num}    ${DOMAIN_1}
    \    ${export_speed}    Forwarding Export    ${exported_bindings}    ${TEST_SAMPLES}    ${DOMAIN_1}
    \    Log    Outbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

Binding Combined Filter Export Test
    [Documentation]    Test binding export speed with domain filter, Outbound filter and multiple passrates.
    Add Bindings Range    112    84213760    ${EXPORT_AMOUNT}
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate    100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    math.ceil( ${EXPORT_AMOUNT}*${passrate}/100 )    modules=math
    \    ${exported_bindings}    Convert To String    ${exported_bindings}
    \    Run Keyword And Ignore Error    Setup Domain Filter    ${num}    ${DOMAIN_1}
    \    Setup Filter    ${num}    outbound
    \    ${export_speed}    Simple Export    ${exported_bindings}    ${TEST_SAMPLES}    ${DOMAIN_1}
    \    Log    Outbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

Binding Combined Filter Forwarding Export Test
    [Documentation]    Test binding forward speed with domain filter, Inbound-discarding filter and multiple passrates.
    : FOR    ${num}    IN RANGE    16    20
    \    ${passrate}    Evaluate    100.0/(2**(${num} - 16))
    \    ${exported_bindings}    Evaluate    math.ceil( ${EXPORT_AMOUNT}*${passrate}/100 )    modules=math
    \    ${exported_bindings}    Convert To String    ${exported_bindings}
    \    Run Keyword And Ignore Error    Setup Domain Filter    ${num}    ${DOMAIN_1}
    \    Setup Filter    ${num}    inbound-discarding
    \    ${export_speed}    Forwarding Export    ${exported_bindings}    ${TEST_SAMPLES}    ${DOMAIN_1}
    \    Log    Outbound Export speed ${export_speed} with passrate ${passrate}%.
    \    Should Be True    ${export_speed} > ${MINIMAL_SPEED}

*** Keywords ***
Setup Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}    ${destination_nodes}=3    ${destination_domain}=global
    [Documentation]    Adds connections to local and remote nodes and wait until they are connected
    Setup Simple Binding Export Topology    ${version}    ${PASSWORD}    ${destination_nodes}    1    ${destination_domain}
    : FOR    ${num}    IN RANGE    0    ${destination_nodes}
    \    ${DESTINATION_NODE}    Get Ip From Number And Ip    ${num}    ${DESTINATION_IP}
    \    ExportLibrary.Add Connection    ${version}    listener    127.0.0.1    64999    ${PASSWORD}
    \    ...    ${DESTINATION_NODE}
    \    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker
    \    ...    ${DESTINATION_NODE}    64999    domain=${destination_domain}

Setup Simple Binding Export Topology
    [Arguments]    ${version}=version4    ${PASSWORD}=${EMPTY}    ${destination_nodes}=3    ${source_nodes}=1    ${destination_domain}=global
    [Documentation]    Adds connections to local and remote nodes and wait until they are connected
    : FOR    ${num}    IN RANGE    0    ${source_nodes}
    \    ${SOURCE_NODE}    Get Ip From Number And Ip    ${num}    ${SOURCE_IP}
    \    ExportLibrary.Add Node    ${SOURCE_NODE}    ${version}    64999    ${PASSWORD}
    \    ExportLibrary.Add Connection    ${version}    speaker    127.0.0.1    64999    ${PASSWORD}
    \    ...    ${SOURCE_NODE}
    : FOR    ${num}    IN RANGE    0    ${destination_nodes}
    \    ${DESTINATION_NODE}    Get Ip From Number And Ip    ${num}    ${DESTINATION_IP}
    \    ExportLibrary.Add Destination Node    ${DESTINATION_NODE}    ${version}    64999    ${PASSWORD}
    \    Add Connection    ${version}    speaker    ${DESTINATION_NODE}    64999    password=${PASSWORD}
    \    ...    domain=${destination_domain}
    ExportLibrary.Start Nodes
    : FOR    ${num}    IN RANGE    0    ${source_nodes}
    \    ${SOURCE_NODE}    Get Ip From Number And Ip    ${num}    ${SOURCE_IP}
    \    Add Connection    ${version}    listener    ${SOURCE_NODE}    64999    password=${PASSWORD}
    \    Wait Until Keyword Succeeds    60    2    Verify Connection    ${version}    listener
    \    ...    ${SOURCE_NODE}    64999

Simple Export
    [Arguments]    ${check_amount}    ${samples}=10    ${destination_domain}=global
    [Documentation]    Starts SXP nodes and checks if bindings are already exported, this is repeated N times
    @{ITEMS}    Create List
    : FOR    ${num}    IN RANGE    0    ${samples}
    \    Setup Simple Binding Export Topology    destination_domain=${destination_domain}
    \    ExportLibrary.Set Export Amount    ${check_amount}
    \    ExportLibrary.Initiate Simple Export    127.0.0.1
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Test Clean
    ${export_speed}    Get Average Of Items    ${ITEMS}
    [Return]    ${export_speed}

Forwarding Export
    [Arguments]    ${check_amount}    ${samples}=10    ${destination_domain}=global
    [Documentation]    Starts SXP nodes and checks if bindings are already forwarded, this is repeated N times
    @{ITEMS}    Create List
    : FOR    ${num}    IN RANGE    0    ${samples}
    \    Setup Binding Export Topology    destination_domain=${destination_domain}
    \    ExportLibrary.Set Export Amount    ${check_amount}
    \    ExportLibrary.Initiate Export    5.5.0.0/16    112
    \    ${ELEMENT}    Wait Until Keyword Succeeds    360    1    Check Bindings Exported
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Test Clean
    ${export_speed}    Get Average Of Items    ${ITEMS}
    [Return]    ${export_speed}

Check Bindings Exported
    [Documentation]    Checking if bindings were exported and return export speed
    ${all_exported}    ExportLibrary.All Exported
    ${bindings_exported}    ExportLibrary.Get Bindings Exchange Count
    Log    ${bindings_exported}
    Should Be True    ${all_exported}
    ${export_time}    ExportLibrary.Get Export Time
    ${export_speed}    Evaluate    ${bindings_exported}/${export_time}
    [Return]    ${export_speed}

Setup Filter
    [Arguments]    ${bits}    ${type}
    [Documentation]    Creates peer-group and its filter with specific matching.
    Add PeerGroup    GROUP    ${EMPTY}
    ${entry}    Get Filter Entry    10    permit    pl=5.5.0.0/${bits}
    Add Filter    GROUP    ${type}    ${entry}

Setup Domain Filter
    [Arguments]    ${bits}    ${domain}
    [Documentation]    Creates domain and its filter with specific matching.
    Add Domain    ${domain}
    ${domains}    Add Domains    ${domain}
    ${entry}    Get Filter Entry    10    permit    pl=5.5.0.0/${bits}
    Add Domain Filter    ${DOMAIN_0}    ${domains}    ${entry}

Test Clean
    ExportLibrary.Clean Library
    Clean Connections
    Clean Connections    domain=${DOMAIN_1}
    Clean Peer Groups
