*** Settings ***
Default Tags      single-tenant    teardown    single-tenant-teardown
Library           SSHLibrary
Resource          ${CURDIR}/../../../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../../../libraries/GBP/ConnUtils.robot
Resource          ${CURDIR}/../Variables.robot
Resource          ${CURDIR}/../GBP_3node.robot

*** Variables ***
${timeout}        10s

*** Test Cases ***
Teardown Suite
    Log    Teardown suite in gbp1
    : FOR    ${GBP}    IN    @{GBPs}
    \    GBP_3node.Teardown Node    ${GBP}    ${CURDIR}    timeout=${timeout}
