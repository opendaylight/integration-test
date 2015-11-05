*** Settings ***
Documentation     Basic Tests for DIDM in Beryllium.
...
...               Copyright (c) 2015 Hewlett-Packard Development Company, L.P. and others. All rights reserved.
...               This program and the accompanying materials are made available under the terms of the Eclipse
...               Public License v1.0 which accompanies this distribution, and is available at
...               http://www.eclipse.org/legal/ep1-v10.html
Suite Setup       Setup DIDM Environment
Suite Teardown    DIDM Suite Teardown
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
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
    ${device_ip_addr}=    Find Unknown Device    ${unknown_device_ip}
    Should Not match    ${device_ip_addr}    ${DEVICE_IP}

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
