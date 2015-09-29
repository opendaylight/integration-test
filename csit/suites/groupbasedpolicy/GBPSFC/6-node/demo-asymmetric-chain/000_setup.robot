*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../GBPSFC_6node.robot


*** Variables ***
${timeout} =     10s


*** Test Cases ***
Setup Suite
    Log    Setup suite in asymetric-chain
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    GBPSFC_6node.Setup Node    ${GBPSFC}    timeout=${timeout}
