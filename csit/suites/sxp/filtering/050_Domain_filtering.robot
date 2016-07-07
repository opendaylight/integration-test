*** Settings ***
Documentation     Test suite to verify Domain data separation
Test Setup        Setup Nodes
Test Teardown     Clean SXP Environment    10
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/Variables.py

*** Variables ***
${DOMAIN_1}       guest
${DOMAIN_2}       trusted
${DOMAIN_3}       semitrusted
${DOMAIN_4}       secure

*** Test Cases ***
Non Transitivity Test
    [Documentation]    Test if Node 7 contains only bindings from global domain
    [Tags]    SXP    Domains    Filtering
    Wait Until Keyword Succeeds    15    1    Check Initialized
    Add Filters
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing


Adaptation To Filter Test
    [Documentation]    Test if Nodes 8,9 contains only bindings from guest domain
    [Tags]    SXP    Domains    Filtering
    Wait Until Keyword Succeeds    15    1    Check Initialized
    Add Filters
    Add Domain    ${DOMAIN_4}
    ${domain_1_xml}    Add Domain    ${DOMAIN_4}
    ${domains}    Combine Strings    ${domain_1_xml}
    ${entry1}    Get Filter Entry    10    permit    pl=20.0.0.0/8
    ${entries}    Combine Strings    ${entry1}
    Add Domain Filter    ${DOMAIN_1}    ${domains}    ${entries}
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing Updated

Cleanup Of Filter Test
    [Documentation]    Test if Node 10 contains only bindings from trusted domain
    [Tags]    SXP    Domains    Filtering
    Wait Until Keyword Succeeds    15    1    Check Initialized
    Add Filters

*** Keywords ***
Setup Nodes
    [Arguments]    ${version}=version4
    [Documentation]    Setups Multi domain topology consisting of 3 specific domains and 1 default, data will be shared by filter.
    Setup SXP Environment    10
    : FOR    ${node}    IN RANGE    2    5
    \    Add Binding    ${node}0    ${node}0.${node}0.${node}0.${node}0/32    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.${node}0.${node}0.0/24    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.${node}0.0.0/16    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    \    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.${node}
    : FOR    ${node}    IN RANGE    5    9
    \    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.${node}
    Add Domain    ${DOMAIN_1}
    Add Domain    ${DOMAIN_2}
    Add Domain    ${DOMAIN_3}
    # NO DOMAIN
    Add Connection    ${version}    speaker    127.0.0.8    64999
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.8
    # DOMAIN 1
    Add Connection    ${version}    listener    127.0.0.2    64999    domain=${DOMAIN_1}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    ...    domain=${DOMAIN_1}
    Add Connection    ${version}    speaker    127.0.0.5    64999    domain=${DOMAIN_1}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.5
    ...    domain=${DOMAIN_1}
    # DOMAIN 2
    Add Connection    ${version}    listener    127.0.0.3    64999    domain=${DOMAIN_2}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    ...    domain=${DOMAIN_2}
    Add Connection    ${version}    speaker    127.0.0.6    64999    domain=${DOMAIN_2}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.6
    ...    domain=${DOMAIN_2}
    # DOMAIN 3
    Add Connection    ${version}    listener    127.0.0.4    64999    domain=${DOMAIN_2}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.4
    ...    domain=${DOMAIN_2}
    Add Connection    ${version}    speaker    127.0.0.7    64999    domain=${DOMAIN_2}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.7
    ...    domain=${DOMAIN_2}

Add Filters
    [Arguments]
    [Documentation]    TODO
    ${domain_1_xml}    Add Domain    ${DOMAIN_3}
    ${domain_2_xml}    Add Domain    ${DOMAIN_4}
    ${domains}    Combine Strings    ${domain_1_xml}     ${domain_2_xml}
    ${entry1}    Get Filter Entry    10    permit    pl=20.0.0.0/8
    ${entries}    Combine Strings    ${entry1}
    Add Domain Filter    ${DOMAIN_1}    ${domains}    ${entries}

    ${domain_1_xml}    Add Domain    ${DOMAIN_1}
    ${domains}    Combine Strings    ${domain_1_xml}
    ${entry1}    Get Filter Entry    10    permit    pl=30.30.0.0/16
    ${entries}    Combine Strings    ${entry1}
    Add Domain Filter    ${DOMAIN_2}    ${domains}    ${entries}

    ${domain_1_xml}    Add Domain    global
    ${domains}    Combine Strings    ${domain_1_xml}
    ${entry1}    Get Filter Entry    10    permit    pl=30.30.30.0/24
    ${entries}    Combine Strings    ${entry1}
    Add Domain Filter    ${DOMAIN_2}    ${domains}    ${entries}


Check Initialized
    [Documentation]    TODo
    ${resp}    Get Bindings    127.0.0.5
    Should Contain Binding    ${resp}    20    20.20.20.20/32
    Should Contain Binding    ${resp}    20    20.20.20.0/24
    Should Contain Binding    ${resp}    20    20.20.0.0/16
    Should Contain Binding    ${resp}    20    20.0.0.0/8
    Should Not Contain Binding    ${resp}    30    30.30.30.30/32
    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.6
    Should Not Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    Should Contain Binding    ${resp}    30    30.30.30.30/32
    Should Contain Binding    ${resp}    30    30.30.30.0/24
    Should Contain Binding    ${resp}    30    30.30.0.0/16
    Should Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.7
    Should Not Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    Should Not Contain Binding    ${resp}    30    30.30.30.30/32
    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Contain Binding    ${resp}    40    40.40.40.40/32
    Should Contain Binding    ${resp}    40    40.40.40.0/24
    Should Contain Binding    ${resp}    40    40.40.0.0/16
    Should Contain Binding    ${resp}    40    40.0.0.0/8
    : FOR    ${node}    IN RANGE    8    10
    \    ${resp}    Get Bindings    127.0.0.${node}
    \    Should Not Contain Binding    ${resp}    20    20.20.20.20/32
    \    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
    \    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    \    Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    \    Should Not Contain Binding    ${resp}    30    30.30.30.30/32
    \    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    \    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    \    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    \    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    \    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    \    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    \    Should Not Contain Binding    ${resp}    40    40.0.0.0/8

Check Domain Sharing
    [Documentation]    TODo
    ${resp}    Get Bindings    127.0.0.5
    Should Contain Binding    ${resp}    20    20.20.20.20/32
    Should Contain Binding    ${resp}    20    20.20.20.0/24
    Should Contain Binding    ${resp}    20    20.20.0.0/16
    Should Contain Binding    ${resp}    20    20.0.0.0/8
    Should Contain Binding    ${resp}    30    30.30.30.30/32
    Should Contain Binding    ${resp}    30    30.30.30.0/24
    Should Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.6
    Should Not Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    Should Contain Binding    ${resp}    30    30.30.30.30/32
    Should Contain Binding    ${resp}    30    30.30.30.0/24
    Should Contain Binding    ${resp}    30    30.30.0.0/16
    Should Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.7
    Should Contain Binding    ${resp}    20    20.20.20.20/32
    Should Contain Binding    ${resp}    20    20.20.20.0/24
    Should Contain Binding    ${resp}    20    20.20.0.0/16
    Should Contain Binding    ${resp}    20    20.0.0.0/8
    Should Not Contain Binding    ${resp}    30    30.30.30.30/32
    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Contain Binding    ${resp}    40    40.40.40.40/32
    Should Contain Binding    ${resp}    40    40.40.40.0/24
    Should Contain Binding    ${resp}    40    40.40.0.0/16
    Should Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.8
    Should Contain Binding    ${resp}    20    20.20.20.20/32
    Should Contain Binding    ${resp}    20    20.20.20.0/24
    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    Should Not Contain Binding    ${resp}    30    30.30.30.30/32
    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8

Check Domain Sharing Updated
    [Documentation]    TODo
    ${resp}    Get Bindings    127.0.0.9
    Should Contain Binding    ${resp}    20    20.20.20.20/32
    Should Contain Binding    ${resp}    20    20.20.20.0/24
    Should Contain Binding    ${resp}    20    20.20.0.0/16
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    Should Not Contain Binding    ${resp}    30    30.30.30.30/32
    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8
