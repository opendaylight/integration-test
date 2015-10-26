*** Settings ***
Documentation     Basic Tests for DIDM in Beryllium.
...
...               Copyright (c) 2015 Hewlett-Packard Development Company, L.P. and others. All rights reserved.
Suite Setup       Setup DIDM Environment
Suite Teardown    Cleanup DIDM Test Suite
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/UtilLibrary.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CONTEXT}    restconf/operational/opendaylight-inventory:nodes/
${hp3800_ip}      172.17.8.38
${hp3800_device_type}    hp-3800:hp-3800-device-type
${hp3800_hardware}    3800-48G-4SFP+ Switch
${hp3800_manufacturer}    HP
${hp3800_software}    KA.15.18.0007C
${hp3800_serial_number}    SG29G0W2Z4
${hp3800_description}    v2

*** Test Cases ***
Identifying Unknown Device Type
    [Documentation]    Verify other device types are identified as unknown
    ...    This test case performs the following:
    ...    1. Send a restconf curl command to fetch for the operational nodes inventory
    ...    2. Verify the device type is unknown for non HP3800 switch and mininet
    [Tags]    DIDM
    ${unknown_device_ip}=    Set Variable    172.17.8.191
    ${device_info}=    Find Device Identification Information    ${unknown_device_ip}
    ${unknown_device}=    Set Variable    didm-identification:unknown-device-type
    Log    ${device_info}
    ${length}=    Get Length    ${device_info}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${index}
    \    Log    ${line}
    \    Run Keyword If    '${unknown_device}' in '${line}'    Exit For Loop
    Should Contain    ${line}    ${unknown_device}

Identifying HP3800 Device Type
    [Documentation]    Verify HP3800 device type
    ...    This test case performs the following:
    ...    1. Send a restconf curl command to fetch for the operational nodes inventory
    ...    2. Verify the device type for HP3800 switch
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information    ${hp3800_ip}
    ${length}=    Get Length    ${device_info}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${index}
    \    Run Keyword If    '${hp3800_device_type}' in '${line}'    Exit For Loop
    Should Contain    ${line}    ${hp3800_device_type}

Identifying HP3800 Hardware Information
    [Documentation]    Verify HP3800 hardware information
    ...    This test case performs the following:
    ...    1. Send a restconf curl command to fetch for the operational nodes inventory
    ...    2. Verify the HP3800 hardware information
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information    ${hp3800_ip}
    ${length}=    Get Length    ${device_info}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${index}
    \    Run Keyword If    '${hp3800_hardware}' in '${line}'    Exit For Loop
    Should Contain    ${line}    ${hp3800_hardware}

Identifying HP3800 Manufacturer
    [Documentation]    Verify HP3800 manufacturer
    ...    This test case performs the following:
    ...    1. Send a restconf curl command to fetch for the operational nodes inventory
    ...    2. Verify the HP3800 device manufacturer
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information    ${hp3800_ip}
    ${length}=    Get Length    ${device_info}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${INDEX}
    \    Run Keyword If    '${hp3800_manufacturer}' in '${line}'    Exit For Loop
    Should Contain    ${line}    ${hp3800_manufacturer}

Identifying HP3800 Serial Number
    [Documentation]    Verify HP3800 serial number
    ...    This test case performs the following:
    ...    1. Send a restconf curl command to fetch for the operational nodes inventory
    ...    2. Verify the HP3800 device's serial number
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information    ${hp3800_ip}
    ${length}=    Get Length    ${device_info}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${INDEX}
    \    Run Keyword If    '${hp3800_serial_number}' in '${line}'    Exit For Loop
    Should Contain    ${line}    ${hp3800_serial_number}

Identifying HP3800 Software Information
    [Documentation]    Verify HP3800 software information
    ...    This test case performs the following:
    ...    1. Send a restconf curl command to fetch for the operational nodes inventory
    ...    2. Verify the HP3800 device's software information
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information    ${hp3800_ip}
    ${length}=    Get Length    ${device_info}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${INDEX}
    \    Run Keyword If    '${hp3800_software}' in '${line}'    Exit For Loop
    Should Contain    ${line}    ${hp3800_software}

Identifying HP3800 Description
    [Documentation]    Verify HP3800 description
    ...    This test case performs the following:
    ...    1. Send a restconf curl command to fetch for the operational nodes inventory
    ...    2. Verify the HP3800 device's description
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information    ${hp3800_ip}
    ${length}=    Get Length    ${device_info}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${INDEX}
    \    Run Keyword If    '${hp3800_description}' in '${line}'    Exit For Loop
    Should Contain    ${line}    ${hp3800_description}

*** Keywords ***
Find Device Identification Information
    [Arguments]    ${device_ip}
    [Documentation]    Extract DIDM identification information
    ...    This keyword performs the following:
    ...    1. Send a restconf curl command to fetch for the operational nodes inventory of the device
    ...    2. Find the device_ip from the restconf response and return the response with the device's info
    ${resp}=    RequestsLibrary.Get    session    ${REST_CONTEXT}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    ${flow_node_inventory_ip}=    Set Variable    flow-node-inventory:ip-address":"
    ${flow_node_inventory_device_ip}=    Catenate    SEPARATOR=    ${flow_node_inventory_ip}    ${device_ip}
    Should Contain    ${resp.content}    ${flow_node_inventory_device_ip}
    ${response}=    Split String    ${resp.content}    ","
    ${hardware}=    Set Variable    flow-node-inventory:hardware":
    ${device_type}=    Set Variable    didm-identification:device-type":
    ${manufacturer}=    Set Variable    flow-node-inventory:manufacturer":
    ${serial_number}=    Set Variable    flow-node-inventory:serial-number":
    ${software}=    Set Variable    flow-node-inventory:software":
    ${description}=    Set Variable    flow-node-inventory:description":
    ${length}=    Get Length    ${response}
    @{device_list}=    Create List
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${response}    ${index}
    \    Run Keyword If    '${manufacturer}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${serial_number}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${hardware}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${software}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${description}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${device_type}' in '${line}'    Append To List    ${device_list}    ${line}
    Log    ${device_list}
    [Return]    ${device_list}

DIDM Suite Teardown
    [Documentation]    Uninstall DIDM bundle, driver and Openflow Plugin
    Uninstall a Feature    odl-didm-identification-api
    Uninstall a Feature    odl-didm-identification
    Uninstall a Feature    odl-didm-drivers-api
    Uninstall a Feature    odl-didm-hp3800
    Uninstall a Feature    odl-openflowplugin-all-li
    Verify Feature Is Not Installed    odl-didm-identification-api
    Verify Feature Is Not Installed    odl-didm-identification
    Verify Feature Is Not Installed    odl-didm-drivers-api
    Verify Feature Is Not Installed    odl-didm-hp3800
    Verify Feature Is Not Installed    odl-openflowplugin-all-li

Setup DIDM Environment
    [Documentation]    Install DIDM Karaf features, hp3800 driver and OpenflowPlugin Lithium services.
    ...    Create REST session to the controller
    Install a Feature    odl-didm-identification-api
    Verify Feature Is Installed    odl-didm-identification-api
    Install a Feature    odl-didm-identification
    Verify Feature Is Installed    odl-didm-identification
    Install a Feature    odl-didm-drivers-api
    Verify Feature Is Installed    odl-didm-drivers-api
    Install a Feature    odl-didm-hp3800
    Verify Feature Is Installed    odl-didm-hp3800
    Install a Feature    odl-openflowplugin-all-li
    Verify Feature Is Installed    odl-openflowplugin-all-li
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
