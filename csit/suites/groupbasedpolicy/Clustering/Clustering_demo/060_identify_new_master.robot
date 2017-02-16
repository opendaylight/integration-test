*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Library           SSHLibrary    120 seconds
Resource          ../GBPClusteringKeywords.robot

*** Variables ***
${GBP_INSTANCE_COUNT}    0
${OLD_MASTER}     0

*** Test Cases ***
Identify New GBP Master Instance
    [Documentation]    Identify on which ODL node are running GBP instances but skip previous master node
    Log Many    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    Set Suite Variable    ${OLD_MASTER}    ${GBP_MASTER_INDEX}
    ${GBP_INSTANCE_COUNT}=    Wait Until Keyword Succeeds    10x    10 sec    Search For Gbp Master    ${GBP_MASTER_INDEX}
    Should Be Equal As Integers    ${GBP_INSTANCE_COUNT}    1
    Should Not Be Equal    ${OLD_MASTER}    ${GBP_MASTER_INDEX}
    Log    GBP master index ${GBP_MASTER_INDEX}

