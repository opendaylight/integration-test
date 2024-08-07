*** Settings ***
Documentation       Basic Tests for Device Identification and Driver Management.
...
...                 Copyright (c) 2015 Hewlett-Packard Development Company, L.P. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html

Library             SSHLibrary
Library             Collections
Library             OperatingSystem
Library             RequestsLibrary
Library             ../../../libraries/Common.py
Resource            ../../../libraries/KarafKeywords.robot
Resource            ../../../libraries/Utils.robot
Resource            ../../../variables/DIDM/Variables.robot
Variables           ../../../variables/Variables.py

Suite Setup         Setup Didm Environment
Suite Teardown      Delete All Sessions


*** Variables ***
${DIDM_ID}          "didm-identification:device-type"
${DEVICE_TYPE}      "mininet-didm:mininet-device-type"


*** Test Cases ***
Verify Device Identification
    [Documentation]    Verification of Device type identification feature with device driver installed.
    [Tags]    didm
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${DIDM_ID}
    Should Contain    ${resp.content}    ${DEVICE_TYPE}


*** Keywords ***
Setup Didm Environment
    [Documentation]    Installing DIDM related features, mininet driver, hp3800 driver
    ...    creating session to retrieve operational opendaylight inventory nodes
    Install a Feature    odl-didm-identification-api
    Install a Feature    odl-didm-identification
    Install a Feature    odl-didm-drivers-api
    Install a Feature    odl-didm-mininet
    Install a Feature    odl-hp3800
    Start Mininet
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
