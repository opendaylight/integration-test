*** Settings ***
Documentation     Test suite to verify Inbound filtering functionality using manual policy
Suite Setup       Setup SXP Environment    5
Suite Teardown    Clean SXP Environment    5
Test Teardown     Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../libraries/SXP/FilteringResources.robot

*** Variables ***

*** Test Cases ***
Access List Filtering
    [Documentation]    Test ACL filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers}    Add Peers    127.0.0.2    127.0.0.4
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    acl=10.10.10.0,0.0.0.255
    ${entry2}    Get Filter Entry    20    permit    acl=10.0.0.0,0.254.0.0
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Setup Topology Complex
    Wait Until Keyword Succeeds    4    2    Check One Group 4-2
    Delete Filter    GROUP    inbound
    Verify Keyword Does Not Fail Within Timeout    4    1    Check One Group 4-2
    Reconnect Peers
    ${entries}    Get Filter Entry    10    permit    acl=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Reconnect Peers
    Wait Until Keyword Succeeds    4    2    Check Two Group 4-2
    Delete Filter    GROUP    inbound
    Verify Keyword Does Not Fail Within Timeout    4    1    Check Two Group 4-2
    Reconnect Peers
    ${entries}    Get Filter Entry    10    deny    acl=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Reconnect Peers
    Wait Until Keyword Succeeds    4    2    Check Three Group 4-2

Access List Sgt Filtering
    [Documentation]    Test ACL and SGT filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers}    Add Peers    127.0.0.3    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    sgt=30    acl=10.10.10.0,0.0.0.255
    ${entry2}    Get Filter Entry    20    permit    sgt=50    acl=10.0.0.0,0.254.0.0
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Setup Topology Complex
    Wait Until Keyword Succeeds    4    2    Check One Group 5-3
    Delete Filter    GROUP    inbound
    Verify Keyword Does Not Fail Within Timeout    4    1    Check One Group 5-3
    Reconnect Peers
    ${entries}    Get Filter Entry    10    permit    esgt=20,40    acl=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Reconnect Peers
    Wait Until Keyword Succeeds    4    2    Check Two Group 5-3

Prefix List Filtering
    [Documentation]    Test Prefix List filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers}    Add Peers    127.0.0.2    127.0.0.4
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    pl=10.10.10.0/24
    ${entry2}    Get Filter Entry    20    permit    epl=10.0.0.0/8,le,16
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Setup Topology Complex
    Wait Until Keyword Succeeds    4    2    Check One Group 4-2
    Delete Filter    GROUP    inbound
    Verify Keyword Does Not Fail Within Timeout    4    1    Check One Group 4-2
    Reconnect Peers
    ${entries}    Get Filter Entry    10    permit    pl=10.0.0.0/8
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Reconnect Peers
    Wait Until Keyword Succeeds    4    2    Check Two Group 4-2
    Delete Filter    GROUP    inbound
    Verify Keyword Does Not Fail Within Timeout    4    1    Check Two Group 4-2
    Reconnect Peers
    ${entries}    Get Filter Entry    10    deny    pl=10.0.0.0/8
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Reconnect Peers
    Wait Until Keyword Succeeds    4    2    Check Three Group 4-2

Prefix List Sgt Filtering
    [Documentation]    Test Prefix List and SGT filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers}    Add Peers    127.0.0.3    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    sgt=30    pl=10.10.10.0/24
    ${entry2}    Get Filter Entry    20    permit    pl=10.50.0.0/16
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Setup Topology Complex
    Wait Until Keyword Succeeds    4    2    Check One Group 5-3
    Delete Filter    GROUP    inbound
    Verify Keyword Does Not Fail Within Timeout    4    1    Check One Group 5-3
    Reconnect Peers
    ${entries}    Get Filter Entry    10    permit    esgt=20,40    pl=10.0.0.0/8
    Add Filter    GROUP    inbound    ${entries}    policy=manual-update
    Reconnect Peers
    Wait Until Keyword Succeeds    4    2    Check Two Group 5-3

*** Keywords ***
Reconnect Peers
    [Arguments]    ${version}=version4    ${PASSWORD}=none
    [Documentation]    Reconnect all peers connected to node containing filters
    Clean Connections    127.0.0.1
    FOR    ${node}    IN RANGE    2    6
        Add Connection    ${version}    both    127.0.0.${node}    64999    127.0.0.1
        ...    ${PASSWORD}
    END
