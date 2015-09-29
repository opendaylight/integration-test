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
Setup Suite
    Log    Setup suite in gbp1
    ${sw_index}    Set Variable    0
    :FOR    ${GBP}    IN    @{GBPs}
    \    GBP_3node.Setup Node    ${GBP}    ${sw_index}    ${CURDIR}    timeout=${timeout}
    \    ${sw_index}    Evaluate    ${sw_index} + 1
