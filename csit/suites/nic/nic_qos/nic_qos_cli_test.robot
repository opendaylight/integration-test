*** Settings ***
Documentation     Basic Tests for OF Renderer using NIC CLI.
...
...               Copyright (c) 2015 NEC. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Setup NIC Console Environment
Suite Teardown    Stop NIC OF Rest Test Suite
Library           SSHLibrary
Library           Collections
Variables         ../../../variables/Variables.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/NicKeywords.robot

*** Variables ***
${switches}       2

@{qos_intent1}    HIGH    46
@{qos_intent2}    DOWN    4
@{invalid_dscp}    DOWN    800
@{all_valid_qos}    ${qos_intent1}    ${qos_intent2}

@{valid_intent1}    00:00:00:00:00:01    00:00:00:00:00:02    ALLOW    QOS    HIGH
@{valid_intent2}    00:00:00:00:00:02    00:00:00:00:00:01    ALLOW    QOS    HIGH
@{all_valid_intent}    ${valid_intent1}    ${valid_intent2}

@{all_intents_ids}

@{valid_intent3}    00:00:00:00:00:01    00:00:00:00:00:02    ALLOW
@{valid_intent4}    00:00:00:00:00:02    00:00:00:00:00:01    ALLOW
@{all_valid_intent_allow}    ${valid_intent3}    ${valid_intent4}

*** Test Cases ***
Verify OF Renderer Install
    [Documentation]    Verify if OF renderer bundles are installed.
    Wait Until Keyword Succeeds    200s    10s    Verify OFBundle

Verify OF Renderer QOS Configuration CLI
    [Documentation]    Verification of NIC Console command for QOS Configuration.
    [Tags]    NIC
    ${id}=    Add Qos Configuration    HIGH    46
    ${idd}=    Add Qos From Karaf Console    00:00:00:00:00:01    00:00:00:00:00:02    ALLOW    QOS    HIGH
    ${iddd}=    Add Qos From Karaf Console    00:00:00:00:00:02    00:00:00:00:00:01    ALLOW    QOS    HIGH
    Switch Connection    ${mininet_conn_id}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h2
    Wait_Until_Keyword_Succeeds    20s    1s    Verify TOS Actions     ${dscp_flow}    ${DUMPFLOWS_OF10}
