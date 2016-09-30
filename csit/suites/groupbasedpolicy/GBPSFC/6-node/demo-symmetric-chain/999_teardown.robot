*** Settings ***
Library           SSHLibrary
Resource          ${CURDIR}/../../../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../../../libraries/GBP/ConnUtils.robot
Resource          ${CURDIR}/../Variables.robot
Resource          ${CURDIR}/../GBPSFC_6node.robot

*** Variables ***
${timeout}        10s

*** Test Cases ***
Teardown Suite
    Log    Teardown suite in symetric-chain
    : FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    GBPSFC_6node.Teardown Node    ${GBPSFC}    ${CURDIR}    timeout=${timeout}
