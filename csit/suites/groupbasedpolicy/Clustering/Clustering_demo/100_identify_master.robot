*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Library           SSHLibrary    120 seconds
Resource          ../GBPClusteringKeywords.robot

*** Variables ***
${GBP_INSTANCE_COUNT}    0

*** Test Cases ***
Identify GBP Master Instance
    [Documentation]    Identify on which ODL node are present active instances of GBP modules
    Log Many    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    ${GBP_INSTANCE_COUNT}=    Wait Until Keyword Succeeds    10x    10 sec    Search For Gbp Master
    Should Be Equal As Integers    ${GBP_INSTANCE_COUNT}    1
    Log    GBP index ${GBP_MASTER_INDEX}
