*** Settings ***
Default Tags      single-tenant    setup    single-tenant-setup
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../GBP_3node.robot

*** Variables ***
${timeout}        10s

*** Test Cases ***
Setup Suite
    Log    Setup suite in gbp1
    GBP_3node.Setup Node    ${GBP1}    ${CURDIR}    0    timeout=${timeout}
    GBP_3node.Setup Node    ${GBP2}    ${CURDIR}    1    timeout=${timeout}
    GBP_3node.Setup Node    ${GBP3}    ${CURDIR}    2    timeout=${timeout}
