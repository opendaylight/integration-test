*** Settings ***
Documentation     Test suite to verify Outbound filtering functionality using manual policy
Suite Setup       Setup SXP Environment    6
Suite Teardown    Clean SXP Environment    6
Test Teardown     Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/SXP/FilteringResources.robot

*** Variables ***

*** Test Cases ***
Access List Filtering
    [Documentation]    Test ACL filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers}    Add Peers    127.0.0.4    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    acl=10.10.10.0,0.0.0.255
    ${entry2}    Get Filter Entry    20    deny    acl=10.10.0.0,0.0.255.0
    ${entry3}    Get Filter Entry    30    permit    acl=10.0.0.0,0.255.255.0
    ${entries}    Combine Strings    ${entry1}    ${entry2}    ${entry3}
    Add Filter    GROUP    outbound    ${entries}    policy=manual-update
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check One Group 4-5
    Delete Filter    GROUP    outbound
    Wait Until Keyword Succeeds    4    1    Check One Group 4-5
    Reconnect Peers
    ${entry1}    Get Filter Entry    10    permit    acl=10.20.0.0,0.0.255.255
    ${entry2}    Get Filter Entry    20    permit    acl=10.10.0.0,0.0.255.0
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    outbound    ${entries}    policy=manual-update
    Wait Until Keyword Succeeds    4    1    Check Two Group 4-5

Access List Sgt Filtering
    [Documentation]    Test ACL and SGT filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers}    Add Peers    127.0.0.2    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    deny    acl=10.10.20.0,0.0.0.255
    ${entry2}    Get Filter Entry    20    permit    acl=10.10.0.0,0.0.255.0
    ${entry3}    Get Filter Entry    30    permit    sgt=30    acl=10.10.10.0,0.0.0.255
    ${entries}    Combine Strings    ${entry1}    ${entry2}    ${entry3}
    Add Filter    GROUP    outbound    ${entries}    policy=manual-update
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check One Group 2-5
    Delete Filter    GROUP    outbound
    Wait Until Keyword Succeeds    4    1    Check One Group 2-5
    Reconnect Peers
    ${entries}    Get Filter Entry    10    permit    esgt=20,40    acl=10.10.0.0,0.0.255.255
    Add Filter    GROUP    outbound    ${entries}    policy=manual-update
    Wait Until Keyword Succeeds    4    1    Check Two Group 2-5

Prefix List Filtering
    [Documentation]    Test Prefix List filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers}    Add Peers    127.0.0.4    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    pl=10.10.10.0/24
    ${entry2}    Get Filter Entry    20    deny    epl=10.10.0.0/16,le,24
    ${entry3}    Get Filter Entry    30    permit    epl=10.0.0.0/8,le,24
    ${entries}    Combine Strings    ${entry1}    ${entry2}    ${entry3}
    Add Filter    GROUP    outbound    ${entries}    policy=manual-update
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check One Group 4-5
    Delete Filter    GROUP    outbound
    Wait Until Keyword Succeeds    4    1    Check One Group 4-5
    Reconnect Peers
    ${entry1}    Get Filter Entry    10    permit    pl=10.20.0.0/16
    ${entry2}    Get Filter Entry    20    permit    epl=10.10.0.0/16,le,24
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    outbound    ${entries}    policy=manual-update
    Wait Until Keyword Succeeds    4    1    Check Two Group 4-5

Prefix List Sgt Filtering
    [Documentation]    Test Prefix List and SGT filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers}    Add Peers    127.0.0.2    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    deny    pl=10.10.20.0/24
    ${entry2}    Get Filter Entry    20    permit    epl=10.10.0.0/16,le,24
    ${entry3}    Get Filter Entry    30    permit    sgt=30    pl=10.10.10.0/24
    ${entries}    Combine Strings    ${entry1}    ${entry2}    ${entry3}
    Add Filter    GROUP    outbound    ${entries}    policy=manual-update
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check One Group 2-5
    Delete Filter    GROUP    outbound
    Wait Until Keyword Succeeds    4    1    Check One Group 2-5
    Reconnect Peers
    ${entries}    Get Filter Entry    10    permit    esgt=20,40    pl=10.10.0.0/16
    Add Filter    GROUP    outbound    ${entries}    policy=manual-update
    Wait Until Keyword Succeeds    4    1    Check Two Group 2-5

*** Keywords ***
Reconnect Peers
    [Arguments]    ${version}=version4    ${password}=none
    [Documentation]    Reconnect all peers connected to node containing filters
    Clean Connections    127.0.0.1
    Add Connection    ${version}    both    127.0.0.2    64999    127.0.0.1    ${password}
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${password}
    Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.1    ${password}
    Add Connection    ${version}    speaker    127.0.0.5    64999    127.0.0.1    ${password}
