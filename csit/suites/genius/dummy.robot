*** Settings ***
Documentation     TDD Test Suite for WiP Genius features
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Teardown     Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../variables/Variables.py
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Utils.robot

*** Variables ***

*** Test Cases ***
Dummy Test Case
    [Documentation]    This testcase doesn't do anything
    Log    >>>> Genius TDD WiP Dummy Test Case <<<<<

*** Keywords ***
