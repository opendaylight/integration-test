*** Settings ***
Documentation     Basic Tests for DIDM in Beryllium.
...
...               Copyright (c) 2015 Hewlett Packard Enterprise Development LP and others. All rights reserved.
...               This program and the accompanying materials are made available under the terms of the Eclipse
...               Public License v1.0 which accompanies this distribution, and is available at
...               http://www.eclipse.org/legal/ep1-v10.html
Suite Setup       Setup DIDM Environment
Suite Teardown    DIDM Suite Teardown
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/DIDMKeywords.robot

*** Test Cases ***
Identifying Unknown Device
    [Documentation]    Verify other device types are identified as unknown
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify unknown device is not identified
    [Tags]    DIDM
    ${unknown_device_ip}=    Set Variable    1.1.1.1
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Not match    ${OPERATIONAL_NODES_API}    ${DEVICE_IP}

Identifying Device Type
    [Documentation]    Verify device type
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's type
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information
    ${length}=    Get Length    ${device_info}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${index}
    \    Run Keyword If    '${DEVICE_TYPE}' in '${line}'    Pass Execution    Device type identified:${DEVICE_TYPE}
    Fail    Did not find device type:${DEVICE_TYPE}

Identifying Hardware Information
    [Documentation]    Verify device hardware information
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's hardware information
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information
    ${length}=    Get Length    ${device_info}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${index}
    \    Run Keyword If    '${DEVICE_HW_INFO}' in '${line}'    Pass Execution    Device type identified:${DEVICE_HW_INFO}
    Fail    Did not find HW information:${DEVICE_HW_INFO}

Identifying Manufacturer
    [Documentation]    Verify device manufacturer
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's manufacturer
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information
    ${length}=    Get Length    ${device_info}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${INDEX}
    \    Run Keyword If    '${DEVICE_MANUFACTURE}' in '${line}'    Pass Execution    Device type identified:${DEVICE_MANUFACTURE}
    Fail    Did not find Manufacturer:${DEVICE_MANUFACTURE}

Identifying Serial Number
    [Documentation]    Verify device serial number
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's serial number
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information
    ${length}=    Get Length    ${device_info}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${INDEX}
    \    Run Keyword If    '${DEVICE_SERIAL_NUMBER}' in '${line}'    Pass Execution    Device type identified:${DEVICE_SERIAL_NUMBER}
    Fail    Did not find serial number:${DEVICE_SERIAL_NUMBER}

Identifying Software Information
    [Documentation]    Verify device software information
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's software information
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information
    ${length}=    Get Length    ${device_info}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${INDEX}
    \    Run Keyword If    '${DEVICE_SW_INFO}' in '${line}'    Pass Execution    Device type identified:${DEVICE_SW_INFO}
    Fail    Did not find SW information:${DEVICE_SW_INFO}

Identifying Description
    [Documentation]    Verify device description
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's description
    [Tags]    DIDM
    ${device_info}=    Find Device Identification Information
    ${length}=    Get Length    ${device_info}
    : FOR    ${INDEX}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_info}    ${INDEX}
    \    Run Keyword If    '${DEVICE_DESCRIPTION}' in '${line}'    Pass Execution    Device type identified:${DEVICE_DESCRIPTION}
    Fail    Did not find device desccription:${DEVICE_DESCRIPTION}

*** Keywords ***
DIDM Suite Teardown
    [Documentation]    Uninstall DIDM bundle, driver and Openflow Plugin
    Uninstall a Feature    odl-didm-all
    Uninstall a Feature    odl-didm-identification
    Uninstall a Feature    odl-didm-drivers
    Uninstall a Feature    odl-didm-hp-all
    Uninstall a Feature    odl-didm-hp-impl
    Verify Feature Is Not Installed    odl-didm-all
    Verify Feature Is Not Installed    odl-didm-identification
    Verify Feature Is Not Installed    odl-didm-drivers
    Verify Feature Is Not Installed    odl-didm-hp-all
    Verify Feature Is Not Installed    odl-didm-hp-impl
    Stop Mininet    ${mininet_conn_id}

Setup DIDM Environment
    [Documentation]    Install DIDM Karaf features, hp3800 driver and OpenflowPlugin Lithium services.
    ...    Create REST session to the controller
    Install a Feature    odl-didm-all
    Verify Feature Is Installed    odl-didm-all
    Install a Feature    odl-didm-identification
    Verify Feature Is Installed    odl-didm-identification
    Install a Feature    odl-didm-drivers
    Verify Feature Is Installed    odl-didm-drivers
    Install a Feature    odl-didm-hp-all
    Verify Feature Is Installed    odl-didm-hp-all
    Install a Feature    odl-didm-hp-impl
    Verify Feature Is Installed    odl-didm-hp-impl
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Log To Console    Connect to mininet
    ${mininet_start_cmd}=    Set Variable    sudo mn --controller=remote,ip=${CONTROLLER} --topo linear,1,2 --switch ovsk,protocols=OpenFlow13
    ${mininet_conn_id}=    Start Mininet    ${DEVICE_IP}    ${mininet_start_cmd}    ${EMPTY}    ${DEVICE_USER}    ${DEVICE_PASSWORD}
    Set Global Variable    ${mininet_conn_id}
