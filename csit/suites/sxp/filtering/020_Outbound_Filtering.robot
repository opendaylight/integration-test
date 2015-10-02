*** Settings ***
Documentation     Test suite to verify Bahaviour in different topologies
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Setup        Clean Nodes
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
    ${peers}         Get Peers      127.0.0.1       127.0.0.2
    Add PeerGroup    GROUP

    ${entry1}       Get Filter Entry    10  permit      SGT=10,20       ACL=127.0.0.1,255.255.255.0
    ${entry2}       Get Filter Entry    20  permit      SGT=10,20       ACL=127.0.0.1,255.255.255.0
    ${entries}      Combine Strings     ${entry1}     ${entry2}

    Add Filter    GROUP    inbound      ${entries}

    Delete PeerGroup    GROUP

Access List Sgt Filtering
    [Documentation]     TODO
    Add PeerGroup    GROUP

Extended Access List Sgt Filtering
    [Documentation]     TODO
    Add PeerGroup    GROUP

Prefix List Filtering
    [Documentation]     TODO
    Add PeerGroup    GROUP

Prefix List Sgt Filtering
    [Documentation]     TODO
    Add PeerGroup    GROUP

Extended Prefix List Sgt Filtering
    [Documentation]     TODO
    Add PeerGroup    GROUP

*** Keywords ***
Clean Nodes
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Clean Connections    127.0.0.3