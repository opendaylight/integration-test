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
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/DIDMKeywords.robot

*** Test Cases ***
Identifying Unknown Device
    [Documentation]    Verify other device types are identified as unknown
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify unknown device is not identified
    [Tags]    DIDM
    ${unknown_device_ip}=    Set Variable    1.1.1.1
    ${node_data}=    Find Device Data
    Log    unknwn_dev: ${node_data}
    Should Not Contain    ${node_data}    ${unknown_device_ip}

Identifying Device Type
    [Documentation]    Verify device type
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's type
    [Tags]    DIDM
    ${device_type}=    Find Device Type
    Log    ${device_type}
    Should Match    ${DEVICE_TYPE}    ${device_type}

Identifying Hardware Information
    [Documentation]    Verify device hardware information
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's hardware information
    [Tags]    DIDM
    ${device_hw}=    Find Device Hardware
    Log    ${device_hw}
    Should Match    ${DEVICE_HW_INFO}    ${device_hw}

Identifying Manufacturer
    [Documentation]    Verify device manufacturer
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's manufacturer
    [Tags]    DIDM
    ${manufacture}=    Find Device Manufacturer
    Log    ${manufacture}
    Should Match    ${DEVICE_MANUFACTURE}    ${manufacture}

Identifying Serial Number
    [Documentation]    Verify device serial number
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's serial number
    [Tags]    DIDM
    ${serial_number}=    Find Serial Number
    Log    ${serial_number}
    Should Match    ${DEVICE_SERIAL_NUMBER}    ${serial_number}

Identifying Software Information
    [Documentation]    Verify device software information
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's software information
    [Tags]    DIDM
    ${device_sw}=    Find Device Software
    Log    ${device_sw}
    Should Match    ${DEVICE_SW_INFO}    ${device_sw}

Identifying Description
    [Documentation]    Verify device description
    ...    This test case performs the following:
    ...    1. Send a RestConf request to fetch for the operational nodes inventory
    ...    2. Verify the device's description
    [Tags]    DIDM
    ${device_description}=    Find Device Description
    Log    ${device_description}
    Should Match    ${DEVICE_DESCRIPTION}    ${device_description}

*** Keywords ***
DIDM Suite Teardown
    [Documentation]    Cleanup and exit device
    Stop Mininet And Exit    ${mininet_conn_id}

Setup DIDM Environment
    [Documentation]    Install DIDM Karaf features, drivers and OpenflowPlugin Lithium services.
    ...    Wait for DIDM Listener is registered. Create REST session to the controller.
    Install a Feature    odl-didm-all
    Verify Feature Is Installed    odl-didm-all
    Verify Feature Is Installed    odl-didm-identification
    Verify Feature Is Installed    odl-didm-drivers
    Verify Feature Is Installed    odl-didm-hp-all
    Verify Feature Is Installed    odl-didm-hp-impl
    Verify Feature Is Installed    odl-didm-ovs-all
    Verify Feature Is Installed    odl-didm-ovs-impl
    Verify Feature Is Installed    odl-openflowplugin-all-li
    ${message}=    Set Variable    org.opendaylight.didm.ovs - 0.2.0.SNAPSHOT | Device-type Listener registered
    Wait For Karaf Log    ${message}
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Log    Start device
    ${mininet_topo_opt}=    Set Variable    --topo linear,1 --switch ovsk,protocols=OpenFlow13
    ${mininet_conn_id}=    Start Mininet Single Controller    ${DEVICE_IP}    ${CONTROLLER}    ${mininet_topo_opt}
    Wait Until Keyword Succeeds    11s    1s    Check DIDM Registered With Device
    Set Suite Variable    ${mininet_conn_id}
