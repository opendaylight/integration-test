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
${switches}       4

@{qos_intent1}    HIGH    46
@{qos_intent2}    DOWN    4
@{invalid_dscp}    DOWN    90
@{all_valid_qos}    ${qos_intent1}    ${qos_intent2}

@{all_intents_ids}

*** Test Cases ***
Verify OF Renderer Install
    [Documentation]    Verify if OF renderer bundles are installed.
    Wait Until Keyword Succeeds    200s    10s    Verify OFBundle

Verify OF Renderer QOS Configuration CLI
    [Documentation]    Verification of NIC Console command for QOS Configuration.
    [Tags]    NIC
    : FOR    ${intent}    IN    @{all_valid_qos}
    \    ${id}=    Add Qos Configuration    @{intent}
    \    Append To List    ${all_intents_ids}    ${id}

Invalid QOS Configuration CLI
    [Documentation]    Verification of NIC Console command for invalid QOS Configuration.
    [Tags]    NIC
    ${id}=    Invalid Qos Configuration    @{qos_intent1}

Invalid DSCP Value
    [Documentation]    Verification of NIC Console command for DSCP value in QOS Configuration.
    [Tags]    NIC
    ${id}=    Invalid Dscp    @{invalid_dscp}

Verify OF Renderer QoS Constraint CLI
    [Documentation]    Verification of NIC Console command for QOS Configuration.
    [Tags]    NIC
    Start Mininet Linear Topology    ${switches}
    ${source_macaddress}=    Get DynamicMacAddress    h1
    ${destination_macaddress}=    Get DynamicMacAddress    h3
    ${qos_Configuration}=    Wait_Until_Keyword_Succeeds    10s    1s    Add Qos Configuration    HIGH    46
    ${qos_constraint_flow_one}=    Wait_Until_Keyword_Succeeds    10s    1s    Add Qos From Karaf Console    ${source_macaddress}    ${destination_macaddress}    ALLOW    QOS    HIGH
    ${qos_constraint_flow_two}=    Wait_Until_Keyword_Succeeds    10s    1s    Add Qos From Karaf Console    ${destination_macaddress}    ${source_macaddress}    ALLOW    QOS    HIGH
    Switch Connection    ${mininet_conn_id}
    Wait_Until_Keyword_Succeeds    20s    1s    Verify TOS Actions    ${normal_flow}    ${DUMPFLOWS_OF10}
    Get Intent List
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3
    Wait_Until_Keyword_Succeeds    20s    1s    Verify TOS Actions    ${dscp_flow}    ${DUMPFLOWS_OF10}
