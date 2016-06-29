*** Settings ***
Documentation     Test suite to verify Domain data separation
Suite Setup       Setup Nodes Local
Suite Teardown    Clean SXP Environment    15
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
    [Documentation]    Test if Node 7 contains only bindings from global domain
    [Tags]    SXP    Domains
    Check Binding Range    20    2000    2300    127.0.0.7
    Check Binding Range Negative    30    3000    3300    127.0.0.7
    Check Binding Range Negative    40    4000    4300    127.0.0.7
    Check Binding Range Negative    50    5000    5300    127.0.0.7
    Check Binding Range Negative    60    6000    6300    127.0.0.7
    Check Binding Range Negative    110    11000    11300    127.0.0.7
    Check Binding Range Negative    120    12000    12300    127.0.0.7
    Check Binding Range Negative    130    13000    13300    127.0.0.7
    Check Binding Range Negative    140    14000    14300    127.0.0.7

Export Separation Node 8-9 Test
    [Documentation]    Test if Nodes 8,9 contains only bindings from guest domain
    [Tags]    SXP    Domains
    : FOR    ${node}    IN RANGE    8    10
    \    Check Binding Range Negative    20    2000    2300    127.0.0.${node}
    \    Check Binding Range    30    3000    3300    127.0.0.${node}
    \    Check Binding Range    40    4000    3300    127.0.0.${node}
    \    Check Binding Range Negative    50    5000    5300    127.0.0.${node}
    \    Check Binding Range Negative    60    6000    6300    127.0.0.${node}
    \    Check Binding Range Negative    110    11000    11300    127.0.0.${node}
    \    Check Binding Range Negative    120    12000    12300    127.0.0.${node}
    \    Check Binding Range Negative    130    13000    13300    127.0.0.${node}
    \    Check Binding Range Negative    140    14000    14300    127.0.0.${node}

Export Separation Node 10 Test
    [Documentation]    Test if Node 10 contains only bindings from trusted domain
    [Tags]    SXP    Domains
    Check Binding Range Negative    20    2000    2300    127.0.0.10
    Check Binding Range Negative    30    3000    3300    127.0.0.10
    Check Binding Range Negative    40    4000    4300    127.0.0.10
    Check Binding Range    50    5000    5300    127.0.0.10
    Check Binding Range    60    6000    6300    127.0.0.10
    Check Binding Range Negative    110    11000    11300    127.0.0.10
    Check Binding Range Negative    120    12000    12300    127.0.0.10
    Check Binding Range Negative    130    13000    13300    127.0.0.10
    Check Binding Range Negative    140    14000    14300    127.0.0.10

Export Separation Node 11-14 Test
    [Documentation]    Test if Nodes 11-14 contains only bindings from secure domain
    [Tags]    SXP    Domains
    : FOR    ${node}    IN RANGE    11    15
    \    Check Binding Range Negative    20    2000    2300    127.0.0.${node}
    \    Check Binding Range Negative    30    3000    3300    127.0.0.${node}
    \    Check Binding Range Negative    40    4000    4300    127.0.0.${node}
    \    Check Binding Range Negative    50    5000    5300    127.0.0.${node}
    \    Check Binding Range Negative    60    6000    6300    127.0.0.${node}
    \    Check Binding Range    110    11000    11300    127.0.0.${node}
    \    Check Binding Range    120    12000    12300    127.0.0.${node}
    \    Check Binding Range    130    13000    13300    127.0.0.${node}
    \    Check Binding Range    140    14000    14300    127.0.0.${node}

*** Keywords ***
Setup Nodes Local
    [Arguments]    ${version}=version4
    [Documentation]    Setups Multi domain topology consisting of 3 specific domains and 1 default, data between domains must remain separated.
    Setup SXP Environment    15
    : FOR    ${node}    IN RANGE    2    7
    \    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.${node}
    \    Add Bindings Range    ${node}0    ${node}000    300    127.0.0.${node}
    : FOR    ${node}    IN RANGE    7    11
    \    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.${node}
    : FOR    ${node}    IN RANGE    11    15
    \    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.${node}
    \    Add Bindings Range    ${node}0    ${node}000    300    127.0.0.${node}
    Add Domain    ${DOMAIN_1}
    Add Domain    ${DOMAIN_2}
    Add Domain    ${DOMAIN_3}
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
