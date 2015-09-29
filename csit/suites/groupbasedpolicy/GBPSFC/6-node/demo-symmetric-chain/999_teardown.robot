*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../GBPSFC_6node_resources.robot


*** Variables ***
${timeout} =     10s


*** Test Cases ***
Teardown Suite
    Log    Teardown suite in symmetric-chain
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    GBPSFC_6node_resources.Teardown_GBPSFC_6node    ${GBPSFC}    timeout=${timeout}
