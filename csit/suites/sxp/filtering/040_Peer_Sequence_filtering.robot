*** Settings ***
Documentation     Test suite to verify Outbound filtering functionality
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
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
Peer Sequence Filtering
    [Documentation]    Test PeerSequence filter behaviour
    ${peers}    Add Peers    127.0.0.2
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    ps=le,0
    ${entries}    Combine Strings    ${entry1}
    Add Filter    GROUP    outbound    ${entries}
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check PeerSequence One
    Delete Filter    GROUP    outbound
    ${peers}    Add Peers    127.0.0.2
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    ps=le,1
    ${entries}    Combine Strings    ${entry1}
    Add Filter    GROUP    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check PeerSequence Two
    Delete Filter    GROUP    outbound
    ${peers}    Add Peers    127.0.0.2
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    ps=le,2
    ${entries}    Combine Strings    ${entry1}
    Add Filter    GROUP    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check PeerSequence Three
    Delete Filter    GROUP    outbound
    ${peers}    Add Peers    127.0.0.2
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    deny    ps=eq,1
    ${entry2}    Get Filter Entry    20    permit    ps=ge,0
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check PeerSequence Mix
    Delete Filter    GROUP    outbound

Inbound PL Combinations Filtering
    [Documentation]    Test PeerSequence filter combined with PrefixList filter
    @{scopes}    Create List    inbound    inbound-discarding
    : FOR    ${scope}    IN    @{scopes}
    \    Add PeerGroup    GROUP
    \    ${entry1}    Get Filter Entry    10    permit    ps=le,1
    \    ${entries}    Combine Strings    ${entry1}
    \    Add Filter    GROUP    ${scope}    ${entries}
    \    Setup Nodes Inbound Test
    \    ${peers}    Add Peers    127.0.0.2
    \    Add PeerGroup    GROUP2    ${peers}
    \    ${entry1}    Get Filter Entry    10    permit    pl=1.1.0.0/16
    \    ${entries}    Combine Strings    ${entry1}
    \    Add Filter    GROUP2    ${scope}    ${entries}
    \    Wait Until Keyword Succeeds    4    1    Check Inbound PL Combinations Filtering
    \    Clean Nodes

Inbound ACL Combinations Filtering
    [Documentation]    Test PeerSequence filter combined with ACL filter
    @{scopes}    Create List    inbound    inbound-discarding
    : FOR    ${scope}    IN    @{scopes}
    \    ${peers}    Add Peers    127.0.0.2
    \    Add PeerGroup    GROUP2    ${peers}
    \    ${entry1}    Get Filter Entry    10    permit    ps=le,2
    \    ${entries}    Combine Strings    ${entry1}
    \    Add Filter    GROUP2    ${scope}    ${entries}
    \    Setup Nodes Inbound Test
    \    ${entry1}    Get Filter Entry    10    permit    acl=1.1.1.0,0.0.0.255
    \    ${entries}    Combine Strings    ${entry1}
    \    Add Filter    GROUP2    ${scope}    ${entries}
    \    ${peers}    Add Peers    127.0.0.5
    \    Add PeerGroup    GROUP5    ${peers}
    \    ${entry1}    Get Filter Entry    10    permit    sgt=40
    \    ${entries}    Combine Strings    ${entry1}
    \    Add Filter    GROUP5    ${scope}    ${entries}
    \    Wait Until Keyword Succeeds    4    1    Check Inbound ACL Combinations Filtering
    \    Clean Nodes

Outbound PL Combinations Filtering
    [Documentation]    Test PeerSequence filter combined with PrefixList filter
    Add PeerGroup    GROUP
    ${entry1}    Get Filter Entry    10    permit    pl=1.1.1.0/24
    ${entries}    Combine Strings    ${entry1}
    Add Filter    GROUP    outbound    ${entries}
    Setup Nodes Outbound Test
    ${peers}    Add Peers    127.0.0.2
    Add PeerGroup    GROUP2    ${peers}
    ${entry1}    Get Filter Entry    10    permit    ps=le,1
    ${entries}    Combine Strings    ${entry1}
    Add Filter    GROUP2    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Outbound PL Combinations Filtering

Outbound ACL Combinations Filtering
    [Documentation]    Test PeerSequence filter combined with ACL filter
    Add PeerGroup    GROUP
    ${entry1}    Get Filter Entry    10    permit    ps=eq,0
    ${entry2}    Get Filter Entry    20    permit    ps=ge,2
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    outbound    ${entries}
    Setup Nodes Outbound Test
    ${peers}    Add Peers    127.0.0.2
    Add PeerGroup    GROUP2    ${peers}
    ${entry1}    Get Filter Entry    10    permit    acl=1.1.0.0,0.0.255.255
    ${entries}    Combine Strings    ${entry1}
    Add Filter    GROUP2    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Outbound ACL Combinations Filtering

*** Keywords ***
Setup Nodes
    [Arguments]    ${version}=version4    ${password}=none
    [Documentation]    Setup Topology for PeerSequence tests
    Add Binding    10    10.10.10.10/32    127.0.0.1
    Add Binding    10    10.10.10.0/24    127.0.0.1
    Add Binding    10    10.10.0.0/16    127.0.0.1
    Add Binding    10    10.0.0.0/8    127.0.0.1
    : FOR    ${node}    IN RANGE    2    6
    \    Add Binding    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
    \    Add Binding    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
    \    Add Binding    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.2    ${password}
    Add Connection    ${version}    speaker    127.0.0.2    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.2
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    ${password}
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    Add Connection    ${version}    speaker    127.0.0.3    64999    127.0.0.4    ${password}
    Add Connection    ${version}    listener    127.0.0.4    64999    127.0.0.3    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.4
    ...    64999    127.0.0.3
    Add Connection    ${version}    speaker    127.0.0.4    64999    127.0.0.5    ${password}
    Add Connection    ${version}    listener    127.0.0.5    64999    127.0.0.4    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.5
    ...    64999    127.0.0.4

Setup Nodes Inbound Test
    [Arguments]    ${version}=version4    ${password}=none
    [Documentation]    Setup Topology for inbound PeerSequence and other filters tests
    : FOR    ${node}    IN RANGE    2    6
    \    Add Binding    ${node}0    1.1.1.${node}/32    127.0.0.${node}
    \    Add Binding    ${node}0    1.1.${node}.0/24    127.0.0.${node}
    \    Add Binding    ${node}0    1.${node}.0.0/16    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}.0.0.0/8    127.0.0.${node}
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2    ${password}
    Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.5    ${password}
    Add Connection    ${version}    listener    127.0.0.5    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.5
    Add Connection    ${version}    both    127.0.0.3    64999    127.0.0.2    ${password}
    Add Connection    ${version}    both    127.0.0.2    64999    127.0.0.3    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.2
    ...    64999    127.0.0.3
    Add Connection    ${version}    both    127.0.0.3    64999    127.0.0.4    ${password}
    Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.3    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.4
    ...    64999    127.0.0.3
    Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.5    ${password}
    Add Connection    ${version}    both    127.0.0.5    64999    127.0.0.4    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.5
    ...    64999    127.0.0.4

Setup Nodes Outbound Test
    [Arguments]    ${version}=version4    ${password}=none
    [Documentation]    Setup Topology for outbound PeerSequence and other filters tests
    Add Binding    10    1.1.1.1/32    127.0.0.1
    Add Binding    10    1.1.1.0/24    127.0.0.1
    Add Binding    10    1.1.0.0/16    127.0.0.1
    Add Binding    10    1.0.0.0/8    127.0.0.1
    : FOR    ${node}    IN RANGE    3    6
    \    Add Binding    ${node}0    1.1.1.${node}/32    127.0.0.${node}
    \    Add Binding    ${node}0    1.1.${node}.0/24    127.0.0.${node}
    \    Add Binding    ${node}0    1.${node}.0.0/16    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}.0.0.0/8    127.0.0.${node}
    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.2    ${password}
    Add Connection    ${version}    speaker    127.0.0.2    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.2
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    ${password}
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.4    ${password}
    Add Connection    ${version}    listener    127.0.0.4    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.4
    Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.5    ${password}
    Add Connection    ${version}    both    127.0.0.5    64999    127.0.0.4    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.5
    ...    64999    127.0.0.4

Check PeerSequence One
    [Documentation]    Node 127.0.0.2 should contain only bindings with peer sequence lower or equals 1
    ${resp}    Get Bindings    127.0.0.2
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    : FOR    ${node}    IN RANGE    3    6
    \    Should Not Contain Binding    ${resp}    ${node}0    10.10.10.${node}0/32
    \    Should Not Contain Binding    ${resp}    ${node}0    10.10.${node}0.0/24
    \    Should Not Contain Binding    ${resp}    ${node}0    10.${node}0.0.0/16
    \    Should Not Contain Binding    ${resp}    ${node}0    ${node}0.0.0.0/8

Check PeerSequence Two
    [Documentation]    Node 127.0.0.2 should contain only bindings with peer sequence lower or equals 2
    ${resp}    Get Bindings    127.0.0.2
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    : FOR    ${node}    IN RANGE    4    6
    \    Should Not Contain Binding    ${resp}    ${node}0    10.10.10.${node}0/32
    \    Should Not Contain Binding    ${resp}    ${node}0    10.10.${node}0.0/24
    \    Should Not Contain Binding    ${resp}    ${node}0    10.${node}0.0.0/16
    \    Should Not Contain Binding    ${resp}    ${node}0    ${node}0.0.0.0/8

Check PeerSequence Three
    [Documentation]    Node 127.0.0.2 should contain only bindings with peer sequence lower or equals 3
    ${resp}    Get Bindings    127.0.0.2
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    Should Contain Binding    ${resp}    40    40.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    50    10.10.10.50/32
    Should Not Contain Binding    ${resp}    50    10.10.50.0/24
    Should Not Contain Binding    ${resp}    50    10.50.0.0/16
    Should Not Contain Binding    ${resp}    50    50.0.0.0/8

Check PeerSequence Mix
    [Documentation]    Node 127.0.0.2 should not contain bindings with peer sequence 1
    ${resp}    Get Bindings    127.0.0.2
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Not Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Not Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    Should Contain Binding    ${resp}    40    40.0.0.0/8    sxp
    Should Contain Binding    ${resp}    50    10.10.10.50/32
    Should Contain Binding    ${resp}    50    10.10.50.0/24
    Should Contain Binding    ${resp}    50    10.50.0.0/16
    Should Contain Binding    ${resp}    50    50.0.0.0/8

Check Inbound PL Combinations Filtering
    [Documentation]    Node 127.0.0.1 should containt bindings with peer sequence lower than 1 and pl 1.1.0.0/16
    ${resp}    Get Bindings    127.0.0.1
    Should Contain Binding    ${resp}    20    1.1.1.2/32    sxp
    Should Contain Binding    ${resp}    20    1.1.2.0/24    sxp
    Should Not Contain Binding    ${resp}    20    1.2.0.0/16    sxp
    Should Not Contain Binding    ${resp}    20    2.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    30    1.1.1.3/32    sxp
    Should Not Contain Binding    ${resp}    30    1.1.3.0/24    sxp
    Should Not Contain Binding    ${resp}    30    1.3.0.0/16    sxp
    Should Not Contain Binding    ${resp}    30    3.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    40    1.1.1.4/32    sxp
    Should Not Contain Binding    ${resp}    40    1.1.4.0/24    sxp
    Should Not Contain Binding    ${resp}    40    1.4.0.0/16    sxp
    Should Not Contain Binding    ${resp}    40    4.0.0.0/8    sxp
    Should Contain Binding    ${resp}    50    1.1.1.5/32    sxp
    Should Contain Binding    ${resp}    50    1.1.5.0/24    sxp
    Should Contain Binding    ${resp}    50    1.5.0.0/16    sxp
    Should Contain Binding    ${resp}    50    5.0.0.0/8    sxp

Check Inbound ACL Combinations Filtering
    [Documentation]    Node 127.0.0.1 should containt bindings with peer sequence lower than 2 and acl 1.1.1.0 0.0.0.255
    ${resp}    Get Bindings    127.0.0.1
    Should Contain Binding    ${resp}    20    1.1.1.2/32    sxp
    Should Not Contain Binding    ${resp}    20    1.1.2.0/24    sxp
    Should Not Contain Binding    ${resp}    20    1.2.0.0/16    sxp
    Should Not Contain Binding    ${resp}    20    2.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    1.1.1.3/32    sxp
    Should Not Contain Binding    ${resp}    30    1.1.3.0/24    sxp
    Should Not Contain Binding    ${resp}    30    1.3.0.0/16    sxp
    Should Not Contain Binding    ${resp}    30    3.0.0.0/8    sxp
    Should Contain Binding    ${resp}    40    1.1.1.4/32    sxp
    Should Contain Binding    ${resp}    40    1.1.4.0/24    sxp
    Should Contain Binding    ${resp}    40    1.4.0.0/16    sxp
    Should Contain Binding    ${resp}    40    4.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    50    1.1.1.5/32    sxp
    Should Not Contain Binding    ${resp}    50    1.1.5.0/24    sxp
    Should Not Contain Binding    ${resp}    50    1.5.0.0/16    sxp
    Should Not Contain Binding    ${resp}    50    5.0.0.0/8    sxp

Check Outbound PL Combinations Filtering
    [Documentation]    Node 127.0.0.2 should containt bindings with peer sequence lower than 1 and pl 1.1.1.0/24
    ${resp}    Get Bindings    127.0.0.2
    Should Contain Binding    ${resp}    10    1.1.1.1/32    sxp
    Should Contain Binding    ${resp}    10    1.1.1.0/24    sxp
    Should Not Contain Binding    ${resp}    10    1.1.0.0/16    sxp
    Should Not Contain Binding    ${resp}    10    1.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    1.1.1.3/32    sxp
    Should Not Contain Binding    ${resp}    30    1.1.3.0/24    sxp
    Should Not Contain Binding    ${resp}    30    1.3.0.0/16    sxp
    Should Not Contain Binding    ${resp}    30    3.0.0.0/8    sxp
    Should Contain Binding    ${resp}    40    1.1.1.4/32    sxp
    Should Not Contain Binding    ${resp}    40    1.1.4.0/24    sxp
    Should Not Contain Binding    ${resp}    40    1.4.0.0/16    sxp
    Should Not Contain Binding    ${resp}    40    4.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    50    1.1.1.5/32    sxp
    Should Not Contain Binding    ${resp}    50    1.1.5.0/24    sxp
    Should Not Contain Binding    ${resp}    50    1.5.0.0/16    sxp
    Should Not Contain Binding    ${resp}    50    5.0.0.0/8    sxp

Check Outbound ACL Combinations Filtering
    [Documentation]    Node 127.0.0.2 should containt bindings with peer sequence equals to 0 or greter than 2 and acl 1.1.0.0 0.0.255.255
    ${resp}    Get Bindings    127.0.0.2
    Should Contain Binding    ${resp}    10    1.1.1.1/32    sxp
    Should Contain Binding    ${resp}    10    1.1.1.0/24    sxp
    Should Contain Binding    ${resp}    10    1.1.0.0/16    sxp
    Should Not Contain Binding    ${resp}    10    1.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    30    1.1.1.3/32    sxp
    Should Not Contain Binding    ${resp}    30    1.1.3.0/24    sxp
    Should Not Contain Binding    ${resp}    30    1.3.0.0/16    sxp
    Should Not Contain Binding    ${resp}    30    3.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    40    1.1.1.4/32    sxp
    Should Not Contain Binding    ${resp}    40    1.1.4.0/24    sxp
    Should Not Contain Binding    ${resp}    40    1.4.0.0/16    sxp
    Should Not Contain Binding    ${resp}    40    4.0.0.0/8    sxp
    Should Contain Binding    ${resp}    50    1.1.1.5/32    sxp
    Should Contain Binding    ${resp}    50    1.1.5.0/24    sxp
    Should Not Contain Binding    ${resp}    50    1.5.0.0/16    sxp
    Should Not Contain Binding    ${resp}    50    5.0.0.0/8    sxp

Clean Nodes
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Clean Connections    127.0.0.3
    Clean Connections    127.0.0.4
    Clean Connections    127.0.0.5
    Clean Peer Groups    127.0.0.1
    Clean Bindings    127.0.0.1
    Clean Bindings    127.0.0.2
    Clean Bindings    127.0.0.3
    Clean Bindings    127.0.0.4
    Clean Bindings    127.0.0.5
