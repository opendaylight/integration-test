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
    Log    Setup suite in gbp-multitenant
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    GBP_3node.Setup Node    ${GBPSFC}    ${CURDIR}    timeout=${timeout}
