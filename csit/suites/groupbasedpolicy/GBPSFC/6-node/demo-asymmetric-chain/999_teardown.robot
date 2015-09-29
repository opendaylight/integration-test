*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../GBP_3node.robot


*** Variables ***
${timeout} =     10s


*** Test Cases ***
Teardown Suite
    Log    Teardown suite in asymetric-chain
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    GBPSFC_6node.Teardown Node    ${GBPSFC}    ${CURDIR}    timeout=${timeout}
