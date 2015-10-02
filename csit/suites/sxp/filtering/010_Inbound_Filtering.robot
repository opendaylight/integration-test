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
    ${peers}         Add Peers      127.0.0.2       127.0.0.4
    Add PeerGroup    GROUP      ${peers}

    ${entry1}       Get Filter Entry    10  permit      ACL=10.10.10.0,0.0.0.255
    ${entry2}       Get Filter Entry    20  permit      ACL=10.0.0.0,0.254.0.0
    ${entries}      Combine Strings     ${entry1}     ${entry2}
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s

    ${resp}    Get Bindings Master Database    127.0.0.5

    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/32    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/32    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/32    sxp

    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Not Contain Binding    ${resp}    20    10.10.20.0/32    sxp
    Should Contain Binding    ${resp}    20    10.20.0.0/32    sxp
    Should Not Contain Binding    ${resp}    20    20.0.0.0/32    sxp

    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/32    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/32    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/32    sxp

    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Not Contain Binding    ${resp}    40    10.10.40.0/32    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/32    sxp
    Should Not Contain Binding    ${resp}    40    40.0.0.0/32    sxp

    ${resp}    Get Bindings Master Database    127.0.0.3

    Should Contain Binding    ${resp}    50    10.10.10.50/32    sxp
    Should Contain Binding    ${resp}    50    10.10.50.0/32    sxp
    Should Contain Binding    ${resp}    50    10.50.0.0/32    sxp
    Should Contain Binding    ${resp}    50    50.0.0.0/32    sxp

    Delete Filter   GROUP    inbound
    ${entries}       Get Filter Entry    10    permit      ACL=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s

    ${resp}    Get Bindings Master Database    127.0.0.5

    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/32    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/32    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/32    sxp

    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding    ${resp}    20    10.10.20.0/32    sxp
    Should Contain Binding    ${resp}    20    10.20.0.0/32    sxp
    Should Not Contain Binding    ${resp}    20    20.0.0.0/32    sxp

    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/32    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/32    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/32    sxp

    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding    ${resp}    40    10.10.40.0/32    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/32    sxp
    Should Not Contain Binding    ${resp}    40    40.0.0.0/32    sxp

    ${resp}    Get Bindings Master Database    127.0.0.3

    Should Contain Binding    ${resp}    50    10.10.10.50/32    sxp
    Should Contain Binding    ${resp}    50    10.10.50.0/32    sxp
    Should Contain Binding    ${resp}    50    10.50.0.0/32    sxp
    Should Contain Binding    ${resp}    50    50.0.0.0/32    sxp

    Delete Filter   GROUP    inbound
    ${entries}       Get Filter Entry    10    deny      ACL=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s

    ${resp}    Get Bindings Master Database    127.0.0.5

    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/32    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/32    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/32    sxp

    Should Not Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Not Contain Binding    ${resp}    20    10.10.20.0/32    sxp
    Should Not Contain Binding    ${resp}    20    10.20.0.0/32    sxp
    Should Not Contain Binding    ${resp}    20    20.0.0.0/32    sxp

    Should Not Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Not Contain Binding    ${resp}    30    10.10.30.0/32    sxp
    Should Not Contain Binding    ${resp}    30    10.30.0.0/32    sxp
    Should Not Contain Binding    ${resp}    30    30.0.0.0/32    sxp

    Should Not Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Not Contain Binding    ${resp}    40    10.10.40.0/32    sxp
    Should Not Contain Binding    ${resp}    40    10.40.0.0/32    sxp
    Should Not Contain Binding    ${resp}    40    40.0.0.0/32    sxp

Access List Sgt Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.3       127.0.0.5
    Add PeerGroup    GROUP      ${peers}

    ${entry1}       Get Filter Entry    10  permit      SGT=30  ACL=10.10.10.0,0.0.0.255
    ${entry2}       Get Filter Entry    20  permit      SGT=50  ACL=10.0.0.0,0.254.0.0
    ${entries}      Combine Strings     ${entry1}     ${entry2}
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s

    ${resp}    Get Bindings Master Database    127.0.0.4

    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/32    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/32    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/32    sxp

    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding    ${resp}    20    10.10.20.0/32    sxp
    Should Contain Binding    ${resp}    20    10.20.0.0/32    sxp
    Should Contain Binding    ${resp}    20    20.0.0.0/32    sxp

    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Not Contain Binding    ${resp}    30    10.10.30.0/32    sxp
    Should Not Contain Binding    ${resp}    30    10.30.0.0/32    sxp
    Should Not Contain Binding    ${resp}    30    30.0.0.0/32    sxp

    Should Not Contain Binding    ${resp}    50    10.10.10.50/32    sxp
    Should Not Contain Binding    ${resp}    50    10.10.50.0/32    sxp
    Should Contain Binding    ${resp}    50    10.50.0.0/32    sxp
    Should Not Contain Binding    ${resp}    50    50.0.0.0/32    sxp

    ${resp}    Get Bindings Master Database    127.0.0.2

    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding    ${resp}    40    10.10.40.0/32    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/32    sxp
    Should Contain Binding    ${resp}    40    40.0.0.0/32    sxp

    Delete Filter   GROUP    inbound
    ${entries}       Get Filter Entry    10    permit      ESGT=20,40   ACL=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound      ${entries}
    Sleep       2s

    ${resp}    Get Bindings Master Database    127.0.0.4

    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/32    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/32    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/32    sxp

    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding    ${resp}    20    10.10.20.0/32    sxp
    Should Contain Binding    ${resp}    20    10.20.0.0/32    sxp
    Should Contain Binding    ${resp}    20    20.0.0.0/32    sxp

    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/32    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/32    sxp
    Should Not Contain Binding    ${resp}    30    30.0.0.0/32    sxp

    Should Not Contain Binding    ${resp}    50    10.10.10.50/32    sxp
    Should Not Contain Binding    ${resp}    50    10.10.50.0/32    sxp
    Should Not Contain Binding    ${resp}    50    10.50.0.0/32    sxp
    Should Not Contain Binding    ${resp}    50    50.0.0.0/32    sxp

    ${resp}    Get Bindings Master Database    127.0.0.2

    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding    ${resp}    40    10.10.40.0/32    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/32    sxp
    Should Contain Binding    ${resp}    40    40.0.0.0/32    sxp


Extended Access List Sgt Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.2       127.0.0.4
    Add PeerGroup    GROUP1      ${peers}

    ${peers}         Add Peers      127.0.0.3       127.0.0.5
    Add PeerGroup    GROUP2      ${peers}

Prefix List Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.2       127.0.0.4
    Add PeerGroup    GROUP      ${peers}

Prefix List Sgt Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.3       127.0.0.5
    Add PeerGroup    GROUP      ${peers}

Extended Prefix List Sgt Filtering
    [Documentation]     TODO
    ${peers}         Add Peers      127.0.0.2       127.0.0.4
    Add PeerGroup    GROUP1      ${peers}

    ${peers}         Add Peers      127.0.0.3       127.0.0.5
    Add PeerGroup    GROUP2      ${peers}

*** Keywords ***
Setup Nodes
    [Arguments]     ${version}=version4     ${PASSWORD}=none
    @{list} =    Create List    2  3  4  5
    : FOR    ${node}    IN    @{list}
    \   Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.${node}    ${PASSWORD}
    \   Add Connection    ${version}    both    127.0.0.${node}    64999    127.0.0.1    ${PASSWORD}
    \   Wait Until Keyword Succeeds    15    4    Verify Connection    ${version}    both    127.0.0.${node}
    \   Add Binding    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
    \   Add Binding    ${node}0    10.10.${node}0.0/24     127.0.0.${node}
    \   Add Binding    ${node}0   10.${node}0.0.0/16      127.0.0.${node}
    \   Add Binding    ${node}0    ${node}0.0.0.0/8        127.0.0.${node}

    Add Binding    10    10.10.10.10/32    127.0.0.1
    Add Binding    10    10.10.10.0/24     127.0.0.1
    Add Binding    10    10.10.0.0/16      127.0.0.1
    Add Binding    10    10.0.0.0/8        127.0.0.1

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
