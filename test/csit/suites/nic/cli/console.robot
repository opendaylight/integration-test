*** Settings ***
Documentation     Basic Tests for NIC Console Commands.
...
...               Copyright (c) 2015 Hewlett-Packard Development Company, L.P. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Setup NIC Console Environment
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.txt
Resource          ../../../libraries/Utils.txt
Variables         ../../../variables/Variables.py

*** Variables ***
@{intent1}        10.0.0.5    10.0.0.2,10.0.0.3    ALLOW
@{intent2}        10.0.0.5    10.0.0.2,10.0.0.10    BLOCK
@{intent3}        10.0.0.1,10.0.0.4    10.0.0.2    ALLOW
@{all_intents}    ${intent1}    ${intent2}    ${intent3}
@{all_intents_ids}
${intent_validation1}    from [10.0.0.1, 10.0.0.4] to [10.0.0.2] apply ALLOW
${intent_validation2}    from [10.0.0.5] to [10.0.0.2] apply BLOCK
${intent_validation3}    from [10.0.0.5] to [10.0.0.3] apply ALLOW
${intent_validation4}    from [10.0.0.5] to [10.0.0.10] apply BLOCK
@{all_intent_validations}    ${intent_validation1}    ${intent_validation2}    ${intent_validation3}    ${intent_validation4}

*** Test Cases ***
Verify NIC Command Add and Remove
    [Documentation]    Verification of NIC Console command add and remove. It first creates the intents
    ...    and stores the intent ids, then verifies that the intents were added. Finally, it compiles the intents
    ...    to verify that intents were properly merged and also validates intents were removed at the end per the cleanup procedure.
    [Tags]    NIC
    : FOR    ${intent}    IN    @{all_intents}
    \    ${id}=    Add Intent    @{intent}
    \    Append To List    ${all_intents_ids}    ${id}
    ${size}=    Get Length    ${all_intents}
    : FOR    ${index}    IN RANGE    ${size}
    \    ${intent}=    Get From List    ${all_intents}    ${index}
    \    ${intent_id}=    Get From List    ${all_intents_ids}    ${index}
    \    Verify Intent Added    ${intent_id}    ${intent}
    ${output}=    Issue Command On Karaf Console    intent:compile
    : FOR    ${valid_intent}    IN    @{all_intent_validations}
    \    Should Contain    ${output}    ${valid_intent}
    : FOR    ${intent_id}    IN    @{all_intents_ids}
    \    Remove Intent    ${intent_id}
    ${output}=    Issue Command On Karaf Console    intent:list -c
    : FOR    ${intent_id}    IN    @{all_intents_ids}
    \    Should Not Contain    ${output}    ${id}

*** Keywords ***
Setup NIC Console Environment
    [Documentation]    Installing NIC Console related features (odl-nic-core, odl-nic-console)
    Install a Feature    odl-nic-core
    Install a Feature    odl-nic-console
    Start Suite
    Verify Feature Is Installed    odl-nic-core
    Verify Feature Is Installed    odl-nic-console

Add Intent
    [Arguments]    ${intent_from}    ${intent_to}    ${intent_permission}
    [Documentation]    Adds an intent to the controller, and returns the id of the intent created.
    ${output}=    Issue Command On Karaf Console    intent:add -f ${intent_from} -t ${intent_to} -a ${intent_permission}
    Should Contain    ${output}    Intent created
    ${output}=    Fetch From Left    ${output}    )
    ${output_split}=    Split String    ${output}    ${SPACE}
    ${id}=    Get From List    ${output_split}    3
    [Return]    ${id}

Verify Intent Added
    [Arguments]    ${id}    ${intent}
    [Documentation]    This will check if the id exists via intent:list -c, then compares intent details with arguments passed in with Add Intent
    ${output}=    Issue Command On Karaf Console    intent:list -c
    Should Contain    ${output}    ${id}
    ${output}=    Issue Command On Karaf Console    intent:show ${id}
    ${out}=    Get Lines Containing String    ${output}    Value:
    ${out_intent_from}=    Get Line    ${out}    0
    ${out_intent_to}=    Get Line    ${out}    1
    ${out_intent_permission}=    Get Line    ${out}    2
    ${intent_from}=    Get From List    ${intent}    0
    ${intent_to}=    Get From List    ${intent}    1
    ${intent_permission}=    Get From List    ${intent}    2
    Should Contain    ${out_intent_from}    ${intent_from}
    Should Contain    ${out_intent_to}    ${intent_to}
    Should Contain    ${out_intent_permission}    ${intent_permission}

Remove Intent
    [Arguments]    ${id}
    [Documentation]    Removes an intent from the controller via the provided intent id.
    ${output}=    Issue Command On Karaf Console    intent:remove ${id}
    Should Contain    ${output}    Intent successfully removed
