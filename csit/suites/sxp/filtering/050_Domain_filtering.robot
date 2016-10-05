*** Settings ***
Documentation     Test suite to verify Domain data filtering
Test Setup        Setup Nodes Local
Test Teardown     Clean SXP Environment    10
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/SxpLib.robot

*** Variables ***
${DOMAIN_1}       guest
${DOMAIN_2}       trusted
${DOMAIN_3}       semitrusted
${DOMAIN_4}       secure
${version}        version4

*** Test Cases ***
Non Transitivity Test
    [Documentation]    Test if Bindings are shared according to associated filters
    [Tags]    SXP    Domains    Filtering
    Wait Until Keyword Succeeds    15    1    Check Initialized
    Add Filters
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing
    Remove Filters
    Wait Until Keyword Succeeds    15    1    Check Initialized

Update Messages Test
    [Documentation]    Test if Bindings are shared according to associated filters while bindings are removed/added
    [Tags]    SXP    Domains    Filtering
    Wait Until Keyword Succeeds    15    1    Check Initialized
    Add Filters
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing
    : FOR    ${node}    IN RANGE    2    5
    \    Delete Binding    ${node}0    ${node}0.${node}0.${node}0.0/24    127.0.0.${node}
    \    Delete Binding    ${node}0    ${node}0.${node}0.0.0/16    127.0.0.${node}
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing After Update
    : FOR    ${node}    IN RANGE    2    5
    \    Add Binding    ${node}0    ${node}0.${node}0.${node}0.0/24    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.${node}0.0.0/16    127.0.0.${node}
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing

Local Binding Non Transitivity Test
    [Documentation]    Test if Local Bindings are shared according to associated filters,
    ...    and does not colide with other Bindings
    [Tags]    SXP    Domains    Filtering
    Wait Until Keyword Succeeds    15    1    Check Initialized Local
    Add Filters
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing Local
    Remove Filters
    Wait Until Keyword Succeeds    15    1    Check Initialized Local

Local Binding Update Test
    [Documentation]    Test if Local Bindings are shared according to associated filters while bindings are removed/added
    [Tags]    SXP    Domains    Filtering
    Wait Until Keyword Succeeds    15    1    Check Initialized Local
    Add Filters
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing Local
    Delete Binding    20    20.20.20.5/32    127.0.0.1    ${DOMAIN_1}
    Delete Binding    30    30.30.30.5/32    127.0.0.1    ${DOMAIN_2}
    Delete Binding    40    40.40.40.5/32    127.0.0.1    ${DOMAIN_3}
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing After Update Local
    Add Binding    20    20.20.20.5/32    127.0.0.1    ${DOMAIN_1}
    Add Binding    30    30.30.30.5/32    127.0.0.1    ${DOMAIN_2}
    Add Binding    40    40.40.40.5/32    127.0.0.1    ${DOMAIN_3}
    Wait Until Keyword Succeeds    15    1    Check Domain Sharing Local

Binding Replacement Test
    [Documentation]    Test situation where Local binding is replaced by other shared local binding,
    ...    after shared binding is removed the original binding must be propagated to Peers
    [Tags]    SXP    Domains    Filtering
    Wait Until Keyword Succeeds    15    1    Check Initialized After Update
    Add Binding    400    35.35.35.35/32    127.0.0.4
    Add Binding    450    35.35.35.35/32    127.0.0.1    ${DOMAIN_3}
    Wait Until Keyword Succeeds    15    1    Check After Update Part One
    Add Filters After Update
    Wait Until Keyword Succeeds    15    1    Check After Update Part Two
    Delete Binding    450    35.35.35.35/32    127.0.0.1    ${DOMAIN_3}
    Wait Until Keyword Succeeds    15    1    Check After Update Part Three

*** Keywords ***
Setup Nodes Local
    [Documentation]    Setups Multi domain topology consisting of 3 specific domains and 1 default, data will be shared by filter.
    Setup SXP Environment    10
    : FOR    ${node}    IN RANGE    2    5
    \    Add Binding    ${node}0    ${node}0.${node}0.${node}0.${node}0/32    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.${node}0.${node}0.0/24    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.${node}0.0.0/16    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    \    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.${node}
    : FOR    ${node}    IN RANGE    5    10
    \    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.${node}
    Add Domain    ${DOMAIN_1}
    Add Domain    ${DOMAIN_2}
    Add Domain    ${DOMAIN_3}
    Add Binding    20    20.20.20.5/32    127.0.0.1    ${DOMAIN_1}
    Add Binding    20    20.20.5.5/32    127.0.0.1    ${DOMAIN_1}
    Add Binding    30    30.30.30.5/32    127.0.0.1    ${DOMAIN_2}
    Add Binding    30    30.30.5.5/32    127.0.0.1    ${DOMAIN_2}
    Add Binding    40    40.40.40.5/32    127.0.0.1    ${DOMAIN_3}
    Add Binding    40    40.40.5.5/32    127.0.0.1    ${DOMAIN_3}
    Add Binding    300    25.25.25.25/32    127.0.0.4
    Add Binding    500    35.35.35.35/32
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
    Add Connection    ${version}    listener    127.0.0.4    64999    domain=${DOMAIN_3}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.4
    ...    domain=${DOMAIN_3}
    Add Connection    ${version}    speaker    127.0.0.7    64999    domain=${DOMAIN_3}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.7
    ...    domain=${DOMAIN_3}

Add Filters
    [Documentation]    Add 4 Domain filters that shares portion of Bindings
    ${domain_1_xml}    Add Domains    ${DOMAIN_3}
    ${domain_2_xml}    Add Domains    ${DOMAIN_4}
    ${domains}    Combine Strings    ${domain_1_xml}    ${domain_2_xml}
    ${entry1}    Get Filter Entry    10    permit    pl=20.0.0.0/8
    ${entries}    Combine Strings    ${entry1}
    Add Domain Filter    ${DOMAIN_1}    ${domains}    ${entries}
    ${domain_1_xml}    Add Domains    ${DOMAIN_1}
    ${domains}    Combine Strings    ${domain_1_xml}
    ${entry1}    Get Filter Entry    10    permit    pl=30.30.0.0/16
    ${entries}    Combine Strings    ${entry1}
    Add Domain Filter    ${DOMAIN_2}    ${domains}    ${entries}
    ${domain_1_xml}    Add Domains    global
    ${domains}    Combine Strings    ${domain_1_xml}
    ${entry1}    Get Filter Entry    10    permit    pl=30.30.30.0/24
    ${entries}    Combine Strings    ${entry1}
    Add Domain Filter    ${DOMAIN_2}    ${domains}    ${entries}    127.0.0.1    extended-domain-filter

Add Filters After Update
    [Documentation]    Add Domain filter that shares portion of Local Bindings
    ${domain_1_xml}    Add Domains    global
    ${domains}    Combine Strings    ${domain_1_xml}
    ${entry1}    Get Filter Entry    10    permit    esgt=300,600
    ${entries}    Combine Strings    ${entry1}
    Add Domain Filter    ${DOMAIN_3}    ${domains}    ${entries}

Remove Filters
    [Documentation]    Remove 4 Domain filters that shared portion of Bindings
    Delete Domain Filter    ${DOMAIN_1}
    Delete Domain Filter    ${DOMAIN_2}
    Delete Domain Filter    ${DOMAIN_2}    127.0.0.1    extended-domain-filter

Check Initialized
    [Documentation]    Checks that Bindings are not shared between domains
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

Check Initialized Local
    [Documentation]    Checks that Local Bindings are not shared between domains
    ${resp}    Get Bindings    127.0.0.5
    Should Contain Binding    ${resp}    20    20.20.20.5/32
    Should Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.6
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    Should Contain Binding    ${resp}    30    30.30.30.5/32
    Should Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.7
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    Should Contain Binding    ${resp}    40    40.40.40.5/32
    Should Contain Binding    ${resp}    40    40.40.5.5/32
    : FOR    ${node}    IN RANGE    8    10
    \    ${resp}    Get Bindings    127.0.0.${node}
    \    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    \    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    \    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    \    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    \    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    \    Should Not Contain Binding    ${resp}    40    40.40.5.5/32

Check Initialized After Update
    [Documentation]    Checks that Local Bindings are not shared between domains
    ${resp}    Get Bindings    127.0.0.7
    Should Contain Binding    ${resp}    300    25.25.25.25/32
    Should Not Contain Binding    ${resp}    400    35.35.35.35/32
    Should Not Contain Binding    ${resp}    450    35.35.35.35/32
    ${resp}    Get Bindings    127.0.0.8
    Should Not Contain Binding    ${resp}    300    25.25.25.25/32
    Should Contain Binding    ${resp}    500    35.35.35.35/32

Check Domain Sharing
    [Documentation]    Checks that Bindings are shared between domains
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
    Should Not Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    Should Contain Binding    ${resp}    30    30.30.30.30/32
    Should Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.9
    Should Not Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
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

Check Domain Sharing Local
    [Documentation]    Checks that Local Bindings are shared between domains
    ${resp}    Get Bindings    127.0.0.5
    Should Contain Binding    ${resp}    20    20.20.20.5/32
    Should Contain Binding    ${resp}    20    20.20.5.5/32
    Should Contain Binding    ${resp}    30    30.30.30.5/32
    Should Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.6
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    Should Contain Binding    ${resp}    30    30.30.30.5/32
    Should Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.7
    Should Contain Binding    ${resp}    20    20.20.20.5/32
    Should Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    Should Contain Binding    ${resp}    40    40.40.40.5/32
    Should Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.8
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    Should Contain Binding    ${resp}    30    30.30.30.5/32
    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.9
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32

Check Domain Sharing After Update
    [Documentation]    Checks that removed Bindings are shared between domains
    ${resp}    Get Bindings    127.0.0.5
    Should Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    Should Contain Binding    ${resp}    20    20.0.0.0/8
    Should Contain Binding    ${resp}    30    30.30.30.30/32
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
    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.7
    Should Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    Should Contain Binding    ${resp}    20    20.0.0.0/8
    Should Not Contain Binding    ${resp}    30    30.30.30.30/32
    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.8
    Should Not Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
    Should Not Contain Binding    ${resp}    20    20.20.0.0/16
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    Should Contain Binding    ${resp}    30    30.30.30.30/32
    Should Not Contain Binding    ${resp}    30    30.30.30.0/24
    Should Not Contain Binding    ${resp}    30    30.30.0.0/16
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    Should Not Contain Binding    ${resp}    40    40.40.40.40/32
    Should Not Contain Binding    ${resp}    40    40.40.40.0/24
    Should Not Contain Binding    ${resp}    40    40.40.0.0/16
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp}    Get Bindings    127.0.0.9
    Should Not Contain Binding    ${resp}    20    20.20.20.20/32
    Should Not Contain Binding    ${resp}    20    20.20.20.0/24
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

Check Domain Sharing After Update Local
    [Documentation]    Checks that removed Local Bindings are shared between domains
    ${resp}    Get Bindings    127.0.0.5
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.6
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.7
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.8
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32
    ${resp}    Get Bindings    127.0.0.9
    Should Not Contain Binding    ${resp}    20    20.20.20.5/32
    Should Not Contain Binding    ${resp}    20    20.20.5.5/32
    Should Not Contain Binding    ${resp}    30    30.30.30.5/32
    Should Not Contain Binding    ${resp}    30    30.30.5.5/32
    Should Not Contain Binding    ${resp}    40    40.40.40.5/32
    Should Not Contain Binding    ${resp}    40    40.40.5.5/32

Check After Update Part One
    [Documentation]    Checks that Local Binding is not replaced by Local shared Binding
    ${resp}    Get Bindings    127.0.0.7
    Should Contain Binding    ${resp}    300    25.25.25.25/32
    Should Contain Binding    ${resp}    450    35.35.35.35/32
    ${resp}    Get Bindings    127.0.0.8
    Should Contain Binding    ${resp}    500    35.35.35.35/32

Check After Update Part Two
    [Documentation]    Checks that Local Binding was replaced by Local shared Binding
    ${resp}    Get Bindings    127.0.0.8
    Should Contain Binding    ${resp}    300    25.25.25.25/32
    Should Contain Binding    ${resp}    450    35.35.35.35/32

Check After Update Part Three
    [Documentation]    Checks that Local Binding restored
    ${resp}    Get Bindings    127.0.0.7
    Should Contain Binding    ${resp}    300    25.25.25.25/32
    Should Contain Binding    ${resp}    400    35.35.35.35/32
    ${resp}    Get Bindings    127.0.0.8
    Should Contain Binding    ${resp}    300    25.25.25.25/32
    Should Contain Binding    ${resp}    500    35.35.35.35/32
