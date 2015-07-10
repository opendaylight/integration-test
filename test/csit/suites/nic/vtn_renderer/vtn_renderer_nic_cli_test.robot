*** Settings ***
Documentation     Basic Tests for VTN Renderer using NIC CLI.
...
...               Copyright (c) 2015 NEC. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Setup NIC Console Environment
Suite Teardown    Stop NIC Vtn Rest Test Suite
Library           SSHLibrary
Library           Collections
Library           ../../../libraries/Common.py
Resource          ../../../libraries/NicKeywords.robot
Resource          ../../../libraries/Scalability.robot

*** Variables ***
${switches}       8
@{valid_intent1}    10.0.0.1    10.0.0.2    ALLOW
@{valid_intent2}    10.0.0.2    10.0.0.4    BLOCK
@{valid_intent3}    10.0.0.3    10.0.0.5    ALLOW
@{invalid_Intent1}    10.0.3.4.5    10.0.0.3    ALLOW
@{invalid_Intent2}    10.0.3.5    10.0.0.3    ALLOW
@{all_invalid_Intent}    ${invalid_Intent1}    ${invalid_Intent2}
@{all_valid_intent}    ${valid_intent1}    ${valid_intent2}    ${valid_intent3}
@{all_intents_ids}

*** Test Cases ***
Verify VTN Install
    [Documentation]    Verify if VTN manager bundles are installed.
    Wait Until Keyword Succeeds    1000s    10s    Verify VTNBundle

Verify VTN Renderer Command Add and Remove in CLI
    [Documentation]    Verification of NIC Console command add and remove. It first creates the intents
    ...    and stores the intent ids, then verifies that the intents were added. Finally, it compiles the intents
    ...    to verify that intents were properly merged and also validates intents were removed at the end per the cleanup procedure.
    [Tags]    NIC
    : FOR    ${intent}    IN    @{all_valid_intent}
    \    ${id}=    Add Intent From Karaf Console    @{intent}
    \    Append To List    ${all_intents_ids}    ${id}
    Switch Connection    ${mininet_conn_id}
    Mininet Ping Should Succeed    h1    h2
    Mininet Ping Should Succeed    h3    h5
    Mininet Ping Should Not Succeed    h2    h4
    : FOR    ${intent_id}    IN    @{all_intents_ids}
    \    Remove Intent From Karaf Console    ${intent_id}

Verify Invalid VTN Renderer Command Add and Remove in CLI
    [Documentation]    Invalid IP address for intent creation It first creates the intents
    ...    and stores the intent ids, but flow condition and flowfilter was not created.
    [Tags]    NIC
    : FOR    ${intent}    IN    @{all_invalid_Intent}
    \    ${id}=    Add Intent From Karaf Console    @{intent}
    \    ${output}=    Issue Command On Karaf Console    log:display |grep "Invalid Address"
    \    Should Contain    ${output}    Invalid Address

*** Keywords ***
Verify VTNBundle
    ${output}=    Issue Command On Karaf Console    bundle:list |grep vtn-renderer
    Should Contain    ${output}    Active

Setup NIC Console Environment
    [Documentation]    Installing NIC Console related features (odl-nic-core, odl-nic-console)
    Verify Feature Is Installed    odl-nic-core
    Verify Feature Is Installed    odl-nic-console
    Verify Feature Is Installed    odl-nic-renderer-vtn
    Clean Mininet System
    Start Mininet Linear    ${switches}
