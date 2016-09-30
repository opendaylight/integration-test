*** Settings ***
Default Tags      multi-tenant    setup    multi-tenant-setup
Library           SSHLibrary
Resource          ${CURDIR}/../../../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../../../libraries/GBP/ConnUtils.robot
Resource          ${CURDIR}/../Variables.robot
Resource          ${CURDIR}/../GBP_3node.robot

*** Variables ***
${timeout}        10s

*** Test Cases ***
Setup Suite
    Log    Setup suite in gbp2-multitenant
    GBP_3node.Setup Node    ${GBP1}    ${CURDIR}    0    timeout=${timeout}
    GBP_3node.Setup Node    ${GBP2}    ${CURDIR}    1    timeout=${timeout}
    GBP_3node.Setup Node    ${GBP3}    ${CURDIR}    2    timeout=${timeout}
