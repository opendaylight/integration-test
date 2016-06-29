*** Settings ***
Documentation     Test suite to verify Domain data consistency durin data change
Test Setup        Setup Nodes Local
Test Teardown     Clean SXP Environment    15
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot

*** Variables ***
${DOMAIN_1}       guest
${DOMAIN_2}       trusted
${DOMAIN_3}       secure

*** Test Cases ***
Export Separation Node 7 Test
    [Documentation]    Test if Node 7 contains only bindings from global domain and is not affected by changes from other nodes
    [Tags]    SXP    Domains
    Check Binding Range    20    0    300    127.0.0.7
    Check Binding Range Negative    40    0    300    127.0.0.7
    Check Binding Range Negative    60    0    300    127.0.0.7
    Check Binding Range Negative    120    0    300    127.0.0.7
    Delete Bindings Range    40    0    300    127.0.0.4
    Wait Until Keyword Succeeds    15    1    Check Binding Range    20    0    300
    ...    127.0.0.7
    Delete Bindings Range    20    0    300    127.0.0.2
    Wait Until Keyword Succeeds    15    1    Check Binding Range Negative    20    0    300
    ...    127.0.0.7

Export Separation Node 8-9 Test
    [Documentation]    Test if Nodes 8,9 contains consistent data during its update
    [Tags]    SXP    Domains
    : FOR    ${node}    IN RANGE    8    10
    \    Check Binding Range Negative    20    0    300    127.0.0.${node}
    \    Check Binding Range    40    0    300    127.0.0.${node}
    \    Check Binding Range Negative    60    0    300    127.0.0.${node}
    \    Check Binding Range Negative    120    0    300    127.0.0.${node}
    Delete Bindings Range    60    0    300    127.0.0.6
    : FOR    ${node}    IN RANGE    8    10
    \    Wait Until Keyword Succeeds    15    1    Check Binding Range    40    0
    \    ...    300    127.0.0.${node}
    Delete Bindings Range    40    0    300    127.0.0.4
    : FOR    ${node}    IN RANGE    8    10
    \    Wait Until Keyword Succeeds    15    1    Check Binding Range Negative    40    0
    \    ...    300    127.0.0.${node}

Export Separation Node 10 Test
    [Documentation]    Test if Node 10 contains consistent data during its update
    [Tags]    SXP    Domains
    Check Binding Range Negative    20    0    300    127.0.0.10
    Check Binding Range Negative    40    0    300    127.0.0.10
    Check Binding Range    60    0    300    127.0.0.10
    Check Binding Range Negative    120    0    300    127.0.0.10
    Delete Bindings Range    20    0    300    127.0.0.2
    Wait Until Keyword Succeeds    15    1    Check Binding Range    60    0    300
    ...    127.0.0.10
    Delete Bindings Range    60    0    300    127.0.0.6
    Wait Until Keyword Succeeds    15    1    Check Binding Range Negative    60    0    300
    ...    127.0.0.10

Export Separation Node 11-14 Test
    [Documentation]    Test if Nodes 11-14 contains consistent data during its update
    [Tags]    SXP    Domains
    : FOR    ${node}    IN RANGE    11    15
    \    Check Binding Range Negative    20    0    300    127.0.0.${node}
    \    Check Binding Range Negative    40    0    300    127.0.0.${node}
    \    Check Binding Range Negative    60    0    300    127.0.0.${node}
    \    Check Binding Range    120    0    300    127.0.0.${node}
    Delete Bindings Range    60    0    300    127.0.0.6
    : FOR    ${node}    IN RANGE    11    15
    \    Wait Until Keyword Succeeds    15    1    Check Binding Range    120    0
    \    ...    300    127.0.0.${node}
    Delete Bindings Range    120    0    300    127.0.0.12
    : FOR    ${node}    IN RANGE    11    15
    \    Wait Until Keyword Succeeds    15    1    Check Binding Range Negative    120    0
    \    ...    300    127.0.0.${node}

*** Keywords ***
Setup Nodes Local
    [Arguments]    ${version}=version4
    [Documentation]    Setups Multi domain topology consisting of 3 specific domains and 1 default, data between domains must remain separated.
    Setup SXP Environment    15
    : FOR    ${node}    IN RANGE    2    7
    \    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.${node}
    : FOR    ${node}    IN RANGE    7    11
    \    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.${node}
    : FOR    ${node}    IN RANGE    11    15
    \    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.${node}
    Add Domain    ${DOMAIN_1}
    Add Domain    ${DOMAIN_2}
    Add Domain    ${DOMAIN_3}
    Add Bindings Range    20    0    300    127.0.0.2
    Add Bindings Range    40    0    300    127.0.0.4
    Add Bindings Range    60    0    300    127.0.0.6
    Add Bindings Range    120    0    300    127.0.0.12
    # NO DOMAIN
    Add Connection    ${version}    listener    127.0.0.2    64999
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    Add Connection    ${version}    speaker    127.0.0.7    64999
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.7
    # DOMAIN 1
    Add Connection    ${version}    listener    127.0.0.3    64999    domain=${DOMAIN_1}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    ...    domain=${DOMAIN_1}
    Add Connection    ${version}    listener    127.0.0.4    64999    domain=${DOMAIN_1}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.4
    ...    domain=${DOMAIN_1}
    Add Connection    ${version}    speaker    127.0.0.8    64999    domain=${DOMAIN_1}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.8
    ...    domain=${DOMAIN_1}
    Add Connection    ${version}    speaker    127.0.0.9    64999    domain=${DOMAIN_1}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.9
    ...    domain=${DOMAIN_1}
    # DOMAIN 2
    Add Connection    ${version}    listener    127.0.0.5    64999    domain=${DOMAIN_2}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.5
    ...    domain=${DOMAIN_2}
    Add Connection    ${version}    listener    127.0.0.6    64999    domain=${DOMAIN_2}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.6
    ...    domain=${DOMAIN_2}
    Add Connection    ${version}    speaker    127.0.0.10    64999    domain=${DOMAIN_2}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.10
    ...    domain=${DOMAIN_2}
    # DOMAIN 3
    : FOR    ${node}    IN RANGE    11    15
    \    Add Connection    ${version}    both    127.0.0.${node}    64999    domain=${DOMAIN_3}
    \    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both
    \    ...    127.0.0.${node}    domain=${DOMAIN_3}
