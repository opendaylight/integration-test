*** Settings ***
Default Tags      single-tenant    teardown    single-tenant-teardown
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../GBP_3node.robot

*** Variables ***
${timeout}        10s

*** Test Cases ***
Teardown Suite
    Log    Teardown suite in gbp1
    : FOR    ${GBP}    IN    @{GBPs}
    \    GBP_3node.Teardown Node    ${GBP}    ${CURDIR}    timeout=${timeout}
