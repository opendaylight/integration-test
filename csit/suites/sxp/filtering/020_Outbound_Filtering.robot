*** Settings ***
Documentation     Test suite to verify Bahaviour in different topologies
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Setup        Setup Nodes
Test Teardown     Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Access List Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.3       127.0.0.5
    Add PeerGroup    GROUP      ${peers}

    ${entry1}       Get Filter Entry    10  permit      ACL=10.10.10.0,0.0.0.255
    ${entry2}       Get Filter Entry    20  deny        ACL=10.10.0.0,0.0.255.0
    ${entry3}       Get Filter Entry    30  permit      ACL=10.0.0.0,0.255.255.0
    ${entries}      Combine Strings     ${entry1}     ${entry2}     ${entry3}
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s
    Check One Group 4-5
    Delete Filter   GROUP    inbound
    ${entry1}       Get Filter Entry    10  permit      ACL=10.20.0.0,0.0.255.255
    ${entry2}       Get Filter Entry    20  deny        ACL=10.10.0.0,0.0.255.0
    ${entries}      Combine Strings     ${entry1}     ${entry2}
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s
    Check Two Group 4-5

Access List Sgt Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.4       127.0.0.5
    Add PeerGroup    GROUP      ${peers}

    ${entry1}       Get Filter Entry    10  deny        ACL=10.10.20.0,0.0.0.255
    ${entry2}       Get Filter Entry    20  permit      ACL=10.10.0.0,0.0.255.0
    ${entry3}       Get Filter Entry    30  permit      SGT=30      ACL=10.10.10.0,0.0.0.255
    ${entries}      Combine Strings     ${entry1}     ${entry2}     ${entry3}
    Add Filter    GROUP    inbound      ${entries}
    Sleep       5s
    Check One Group 4-5
    Delete Filter   GROUP    inbound
    ${entries}       Get Filter Entry    10    permit   ESGT=20,40   ACL=10.10.0.0,0.0.255.255
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s
    Check Two Group 4-5

Prefix List Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.3       127.0.0.5
    Add PeerGroup    GROUP      ${peers}

    ${entry1}       Get Filter Entry    10  permit      PL=10.10.10.0/24
    ${entry2}       Get Filter Entry    20  deny        EPL=10.10.0.0/16,le,24
    ${entry3}       Get Filter Entry    30  permit      EPL=10.0.0.0/8,le,24
    ${entries}      Combine Strings     ${entry1}     ${entry2}     ${entry3}
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s
    Check One Group 4-5
    Delete Filter   GROUP    inbound
    ${entry1}       Get Filter Entry    10  permit      PL=10.20.0.0/16
    ${entry2}       Get Filter Entry    20  deny        EPL=10.10.0.0/16,le,24
    ${entries}      Combine Strings     ${entry1}     ${entry2}
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s
    Check Two Group 4-5

Prefix List Sgt Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.4       127.0.0.5
    Add PeerGroup    GROUP      ${peers}

    ${entry1}       Get Filter Entry    10  deny        PL=10.10.20.0/24
    ${entry2}       Get Filter Entry    20  permit      EPL=10.10.0.0/16,le,24
    ${entry3}       Get Filter Entry    30  permit      SGT=30      PL=10.10.10.0/24
    ${entries}      Combine Strings     ${entry1}     ${entry2}     ${entry3}
    Add Filter    GROUP    inbound      ${entries}
    Sleep       5s
    Check One Group 4-5
    Delete Filter   GROUP    inbound
    ${entries}       Get Filter Entry    10    permit   ESGT=20,40   PL=10.10.0.0/16
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s
    Check Two Group 4-5

*** Keywords ***
Setup Nodes
    [Arguments]     ${version}=version4     ${PASSWORD}=none
    : FOR    ${node}    IN RANGE    2    5
    \   Add Binding    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
    \   Add Binding    ${node}0    10.10.${node}0.0/24     127.0.0.${node}
    \   Add Binding    ${node}0   10.${node}0.0.0/16      127.0.0.${node}
    \   Add Binding    ${node}0    ${node}0.0.0.0/8        127.0.0.${node}

    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.2    ${PASSWORD}
    Add Connection    ${version}    both    127.0.0.2    64999    127.0.0.1    ${PASSWORD}
    Wait Until Keyword Succeeds    15    4    Verify Connection    ${version}    both    127.0.0.1

    Add Connection    ${version}    speaker     127.0.0.1    64999    127.0.0.3    ${PASSWORD}
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${PASSWORD}
    Wait Until Keyword Succeeds    15    4    Verify Connection    ${version}    listener    127.0.0.1

    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.4    ${PASSWORD}
    Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.1    ${PASSWORD}
    Wait Until Keyword Succeeds    15    4    Verify Connection    ${version}    both    127.0.0.1

    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.5    ${PASSWORD}
    Add Connection    ${version}    speaker    127.0.0.5    64999    127.0.0.1    ${PASSWORD}
    Wait Until Keyword Succeeds    15    4    Verify Connection    ${version}    speaker    127.0.0.1

Check One Group 4-5
    ${resp}    Get Bindings Master Database    127.0.0.5
    Should Contain Binding      ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding      ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding      ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding      ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding      ${resp}    20    10.10.10.20/32    sxp
    Should Not Contain Binding  ${resp}    20    10.10.20.0/24    sxp
    Should Contain Binding      ${resp}    20    10.20.0.0/16    sxp
    Should Not Contain Binding  ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding      ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding      ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding      ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding      ${resp}    30    30.0.0.0/8    sxp
    Should Contain Binding      ${resp}    40    10.10.10.40/32    sxp
    Should Not Contain Binding  ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding      ${resp}    40    10.40.0.0/16    sxp
    Should Not Contain Binding  ${resp}    40    40.0.0.0/8    sxp

    ${resp}    Get Bindings Master Database    127.0.0.3
    Should Contain Binding      ${resp}    50    10.10.10.50/32    sxp
    Should Contain Binding      ${resp}    50    10.10.50.0/24    sxp
    Should Contain Binding      ${resp}    50    10.50.0.0/16    sxp
    Should Contain Binding      ${resp}    50    50.0.0.0/8    sxp

Check Two Group 4-5
    ${resp}    Get Bindings Master Database    127.0.0.5
    Should Contain Binding      ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding      ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding      ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding      ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding      ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding      ${resp}    20    10.10.20.0/24    sxp
    Should Contain Binding      ${resp}    20    10.20.0.0/16    sxp
    Should Not Contain Binding  ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding      ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding      ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding      ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding      ${resp}    30    30.0.0.0/8    sxp
    Should Contain Binding      ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding      ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding      ${resp}    40    10.40.0.0/16    sxp
    Should Not Contain Binding  ${resp}    40    40.0.0.0/8    sxp

    ${resp}    Get Bindings Master Database    127.0.0.3
    Should Contain Binding      ${resp}    50    10.10.10.50/32    sxp
    Should Contain Binding      ${resp}    50    10.10.50.0/24    sxp
    Should Contain Binding      ${resp}    50    10.50.0.0/16    sxp
    Should Contain Binding      ${resp}    50    50.0.0.0/8    sxp

Check Three Group 4-2
    ${resp}    Get Bindings Master Database    127.0.0.5
    Should Contain Binding      ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding      ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding      ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding      ${resp}    10    10.0.0.0/8    sxp
    Should Not Contain Binding  ${resp}    20    10.10.10.20/32    sxp
    Should Not Contain Binding  ${resp}    20    10.10.20.0/24    sxp
    Should Not Contain Binding  ${resp}    20    10.20.0.0/16    sxp
    Should Not Contain Binding  ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding      ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding      ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding      ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding      ${resp}    30    30.0.0.0/8    sxp
    Should Not Contain Binding  ${resp}    40    10.10.10.40/32    sxp
    Should Not Contain Binding  ${resp}    40    10.10.40.0/24    sxp
    Should Not Contain Binding  ${resp}    40    10.40.0.0/16    sxp
    Should Not Contain Binding  ${resp}    40    40.0.0.0/8    sxp

Check One Group 4-5
    ${resp}    Get Bindings Master Database    127.0.0.4
    Should Contain Binding      ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding      ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding      ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding      ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding      ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding      ${resp}    20    10.10.20.0/24    sxp
    Should Contain Binding      ${resp}    20    10.20.0.0/16    sxp
    Should Contain Binding      ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding      ${resp}    30    10.10.10.30/32    sxp
    Should Not Contain Binding  ${resp}    30    10.10.30.0/24    sxp
    Should Not Contain Binding  ${resp}    30    10.30.0.0/16    sxp
    Should Not Contain Binding  ${resp}    30    30.0.0.0/8    sxp
    Should Not Contain Binding  ${resp}    50    10.10.10.50/32    sxp
    Should Not Contain Binding  ${resp}    50    10.10.50.0/24    sxp
    Should Contain Binding      ${resp}    50    10.50.0.0/16    sxp
    Should Not Contain Binding  ${resp}    50    50.0.0.0/8    sxp

    ${resp}    Get Bindings Master Database    127.0.0.2
    Should Contain Binding      ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding      ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding      ${resp}    40    10.40.0.0/16    sxp
    Should Contain Binding      ${resp}    40    40.0.0.0/8    sxp


Check Two Group 4-5
    ${resp}    Get Bindings Master Database    127.0.0.4
    Should Contain Binding      ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding      ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding      ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding      ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding      ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding      ${resp}    20    10.10.20.0/24    sxp
    Should Contain Binding      ${resp}    20    10.20.0.0/16    sxp
    Should Contain Binding      ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding      ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding      ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding      ${resp}    30    10.30.0.0/16    sxp
    Should Not Contain Binding  ${resp}    30    30.0.0.0/8    sxp
    Should Not Contain Binding  ${resp}    50    10.10.10.50/32    sxp
    Should Not Contain Binding  ${resp}    50    10.10.50.0/24    sxp
    Should Not Contain Binding  ${resp}    50    10.50.0.0/16    sxp
    Should Not Contain Binding  ${resp}    50    50.0.0.0/8    sxp

    ${resp}    Get Bindings Master Database    127.0.0.2
    Should Contain Binding      ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding      ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding      ${resp}    40    10.40.0.0/16    sxp
    Should Contain Binding      ${resp}    40    40.0.0.0/8    sxp

Clean Nodes
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Clean Connections    127.0.0.3
    Clean Connections    127.0.0.4
    Clean Connections    127.0.0.5
    Clean Peer Groups    127.0.0.1
    Sleep   5s
    Clean Bindings       127.0.0.1
    Clean Bindings       127.0.0.2
    Clean Bindings       127.0.0.3
    Clean Bindings       127.0.0.4
    Clean Bindings       127.0.0.5
