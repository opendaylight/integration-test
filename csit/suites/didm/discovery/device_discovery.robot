*** Settings ***
Documentation       Basic Tests for DIDM in Beryllium.
...
...                 Copyright (c) 2015 Hewlett Packard Enterprise Development LP and others. All rights reserved.
...                 This program and the accompanying materials are made available under the terms of the Eclipse
...                 Public License v1.0 which accompanies this distribution, and is available at
...                 http://www.eclipse.org/legal/ep1-v10.html

Library             SSHLibrary
Library             Collections
Library             RequestsLibrary
Resource            ../../../variables/DIDM/Variables.robot
Variables           ../../../variables/Variables.py
Resource            ../../../libraries/Utils.robot
Resource            ../../../libraries/MininetKeywords.robot
Resource            ../../../libraries/DIDMKeywords.robot
Resource            ../../../libraries/KarafKeywords.robot
Resource            ../../../libraries/SetupUtils.robot

Suite Setup         Setup DIDM Environment
Suite Teardown      DIDM Suite Teardown
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing


*** Test Cases ***
Identifying Unknown Device
    [Documentation]    Verify other devices are identified as unknown
    [Tags]    didm
    ${unknown_device_ip}=    Set Variable    1.1.1.1
    ${device_ip}=    Check Device IP
    Should Not Match    ${device_ip}    ${unknown_device_ip}

Identifying Device Type
    [Documentation]    Verify device type
    [Tags]    didm
    ${device_type}=    Find Device Type
    Log    ${device_type}
    Should Match    ${DEVICE_TYPE}    ${device_type}

Identifying Hardware Information
    [Documentation]    Verify device hardware information
    [Tags]    didm
    ${device_hw}=    Find Device Hardware
    Log    ${device_hw}
    Should Match    ${DEVICE_HW_INFO}    ${device_hw}

Identifying Manufacturer
    [Documentation]    Verify device manufacturer
    [Tags]    didm
    ${manufacture}=    Find Device Manufacturer
    Log    ${manufacture}
    Should Match    ${DEVICE_MANUFACTURE}    ${manufacture}

Identifying Serial Number
    [Documentation]    Verify device serial number
    [Tags]    didm
    ${serial_number}=    Find Serial Number
    Log    ${serial_number}
    Should Match    ${DEVICE_SERIAL_NUMBER}    ${serial_number}

Identifying Software Information
    [Documentation]    Verify device software information
    [Tags]    didm
    ${device_sw}=    Find Device Software
    Log    ${device_sw}
    Should Match    ${DEVICE_SW_INFO}    ${device_sw}

Identifying Description
    [Documentation]    Verify device description
    [Tags]    didm
    ${device_description}=    Find Device Description
    Log    ${device_description}
    Should Match    ${DEVICE_DESCRIPTION}    ${device_description}


*** Keywords ***
DIDM Suite Teardown
    [Documentation]    Cleanup and exit device
    Stop Mininet And Exit    ${mininet_conn_id}

Setup DIDM Environment
    [Documentation]    Install DIDM Karaf feature. Wait for DIDM Listener to register.
    ...    Wait for DIDM Listener is registered. Create REST session to the controller.
    ...    Start the device.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Install a Feature    odl-didm-all
    Verify Feature Is Installed    odl-didm-all
    Verify Feature Is Installed    odl-didm-identification
    Verify Feature Is Installed    odl-didm-drivers
    Verify Feature Is Installed    odl-didm-hp-all
    Verify Feature Is Installed    odl-didm-hp-impl
    Verify Feature Is Installed    odl-didm-ovs-all
    Verify Feature Is Installed    odl-didm-ovs-impl
    Verify Feature Is Installed    odl-openflowplugin-flow-services
    ${message}=    Set Variable    org.opendaylight.didm.ovs - 0.2.0.SNAPSHOT | Device-type Listener registered
    Wait For Karaf Log    ${message}
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Log    Start device
    ${mininet_topo_opt}=    Set Variable    --topo linear,1
    ${mininet_conn_id}=    Start Mininet Single Controller
    ...    ${TOOLS_SYSTEM_IP}
    ...    ${ODL_SYSTEM_IP}
    ...    ${mininet_topo_opt}
    Wait Until Keyword Succeeds    11s    1s    Check DIDM Registered With Device
    Set Suite Variable    ${mininet_conn_id}
