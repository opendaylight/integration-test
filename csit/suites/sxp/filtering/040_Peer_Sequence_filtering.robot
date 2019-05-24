*** Settings ***
Documentation     Test suite to verify PeerSequence filtering functionality
Suite Setup       Setup SXP Environment    5
Suite Teardown    Clean SXP Environment    5
Test Teardown     Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Peer Sequence Filtering
    [Documentation]    Test PeerSequence filter behaviour
    [Tags]    SXP    Filtering
    ${peers} =    Sxp.Add Peers    127.0.0.2
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    ps=le,0
    ${entries} =    Common.Combine Strings    ${entry1}
    SxpLib.Add Filter    GROUP    outbound    ${entries}
    Setup Nodes
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check PeerSequence One
    SxpLib.Delete Filter    GROUP    outbound
    ${entry1} =    Sxp.Get Filter Entry    10    permit    ps=le,1
    ${entries} =    Common.Combine Strings    ${entry1}
    SxpLib.Add Filter    GROUP    outbound    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check PeerSequence Two
    SxpLib.Delete Filter    GROUP    outbound
    ${entry1} =    Sxp.Get Filter Entry    10    permit    ps=le,2
    ${entries} =    Common.Combine Strings    ${entry1}
    SxpLib.Add Filter    GROUP    outbound    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check PeerSequence Three
    SxpLib.Delete Filter    GROUP    outbound
    ${entry1} =    Sxp.Get Filter Entry    10    deny    ps=eq,1
    ${entry2} =    Sxp.Get Filter Entry    20    permit    ps=ge,0
    ${entries} =    Common.Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    outbound    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check PeerSequence Mix
    SxpLib.Delete Filter    GROUP    outbound

Inbound PL Combinations Filtering
    [Documentation]    Test PeerSequence filter combined with PrefixList filter
    [Tags]    SXP    Filtering
    @{scopes} =    BuiltIn.Create List    inbound    inbound-discarding
    FOR    ${scope}    IN    @{scopes}
        SxpLib.Add PeerGroup    GROUP
        ${entry1} =    Sxp.Get Filter Entry    10    permit    ps=le,1
        ${entries} =    Common.Combine Strings    ${entry1}
        SxpLib.Add Filter    GROUP    ${scope}    ${entries}
        Setup Nodes Inbound Test
        ${peers} =    Sxp.Add Peers    127.0.0.2
        SxpLib.Add PeerGroup    GROUP2    ${peers}
        ${entry1} =    Sxp.Get Filter Entry    10    permit    pl=1.1.0.0/16
        ${entries} =    Common.Combine Strings    ${entry1}
        SxpLib.Add Filter    GROUP2    ${scope}    ${entries}
        BuiltIn.Wait Until Keyword Succeeds    4    2    Check Inbound PL Combinations Filtering
        Clean Nodes
    END

Inbound ACL Combinations Filtering
    [Documentation]    Test PeerSequence filter combined with ACL filter
    [Tags]    SXP    Filtering
    @{scopes} =    BuiltIn.Create List    inbound    inbound-discarding
    FOR    ${scope}    IN    @{scopes}
        ${peers} =    Sxp.Add Peers    127.0.0.2
        SxpLib.Add PeerGroup    GROUP2    ${peers}
        ${entry1} =    Sxp.Get Filter Entry    10    permit    ps=le,2
        ${entries}    Common.Combine Strings    ${entry1}
        SxpLib.Add Filter    GROUP2    ${scope}    ${entries}
        Setup Nodes Inbound Test
        ${entry1} =    Sxp.Get Filter Entry    10    permit    acl=1.1.1.0,0.0.0.255
        ${entries} =    Common.Combine Strings    ${entry1}
        SxpLib.Add Filter    GROUP2    ${scope}    ${entries}
        ${peers} =    Sxp.Add Peers    127.0.0.5
        SxpLib.Add PeerGroup    GROUP5    ${peers}
        ${entry1} =    Sxp.Get Filter Entry    10    permit    sgt=40
        ${entries} =    Common.Combine Strings    ${entry1}
        SxpLib.Add Filter    GROUP5    ${scope}    ${entries}
        BuiltIn.Wait Until Keyword Succeeds    4    2    Check Inbound ACL Combinations Filtering
        Clean Nodes
    END

Outbound PL Combinations Filtering
    [Documentation]    Test PeerSequence filter combined with PrefixList filter
    [Tags]    SXP    Filtering
    SxpLib.Add PeerGroup    GROUP
    ${entry1} =    Sxp.Get Filter Entry    10    permit    pl=1.1.1.0/24
    ${entries} =    Common.Combine Strings    ${entry1}
    SxpLib.Add Filter    GROUP    outbound    ${entries}
    Setup Nodes Outbound Test
    ${peers} =    Sxp.Add Peers    127.0.0.2
    SxpLib.Add PeerGroup    GROUP2    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    ps=le,1
    ${entries} =    Common.Combine Strings    ${entry1}
    SxpLib.Add Filter    GROUP2    outbound    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check Outbound PL Combinations Filtering

Outbound ACL Combinations Filtering
    [Documentation]    Test PeerSequence filter combined with ACL filter
    [Tags]    SXP    Filtering
    SxpLib.Add PeerGroup    GROUP
    ${entry1} =    Sxp.Get Filter Entry    10    permit    ps=eq,0
    ${entry2} =    Sxp.Get Filter Entry    20    permit    ps=ge,2
    ${entries} =    Common.Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    outbound    ${entries}
    Setup Nodes Outbound Test
    ${peers} =    Sxp.Add Peers    127.0.0.2
    SxpLib.Add PeerGroup    GROUP2    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    acl=1.1.0.0,0.0.255.255
    ${entries} =    Common.Combine Strings    ${entry1}
    SxpLib.Add Filter    GROUP2    outbound    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check Outbound ACL Combinations Filtering

*** Keywords ***
Setup Nodes
    [Arguments]    ${version}=version4    ${password}=none
    [Documentation]    Setup Topology for PeerSequence tests
    SxpLib.Add Bindings    10    10.10.10.10/32    127.0.0.1
    SxpLib.Add Bindings    10    10.10.10.0/24    127.0.0.1
    SxpLib.Add Bindings    10    10.10.0.0/16    127.0.0.1
    SxpLib.Add Bindings    10    10.0.0.0/8    127.0.0.1
    FOR    ${node}    IN RANGE    2    6
        SxpLib.Add Bindings    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    END
    SxpLib.Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.2    ${password}
    SxpLib.Add Connection    ${version}    speaker    127.0.0.2    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    speaker    127.0.0.2
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    listener    127.0.0.3
    SxpLib.Add Connection    ${version}    speaker    127.0.0.3    64999    127.0.0.4    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.4    64999    127.0.0.3    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    listener    127.0.0.4
    ...    64999    127.0.0.3
    SxpLib.Add Connection    ${version}    speaker    127.0.0.4    64999    127.0.0.5    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.5    64999    127.0.0.4    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    listener    127.0.0.5
    ...    64999    127.0.0.4

Setup Nodes Inbound Test
    [Arguments]    ${version}=version4    ${password}=none
    [Documentation]    Setup Topology for inbound PeerSequence and other filters tests
    FOR    ${node}    IN RANGE    2    6
        SxpLib.Add Bindings    ${node}0    1.1.1.${node}/32    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    1.1.${node}.0/24    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    1.${node}.0.0/16    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    ${node}.0.0.0/8    127.0.0.${node}
    END
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    listener    127.0.0.2
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.5    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.5    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    listener    127.0.0.5
    SxpLib.Add Connection    ${version}    both    127.0.0.3    64999    127.0.0.2    ${password}
    SxpLib.Add Connection    ${version}    both    127.0.0.2    64999    127.0.0.3    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    both    127.0.0.2
    ...    64999    127.0.0.3
    SxpLib.Add Connection    ${version}    both    127.0.0.3    64999    127.0.0.4    ${password}
    SxpLib.Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.3    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    both    127.0.0.4
    ...    64999    127.0.0.3
    SxpLib.Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.5    ${password}
    SxpLib.Add Connection    ${version}    both    127.0.0.5    64999    127.0.0.4    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    both    127.0.0.5
    ...    64999    127.0.0.4

Setup Nodes Outbound Test
    [Arguments]    ${version}=version4    ${password}=none
    [Documentation]    Setup Topology for outbound PeerSequence and other filters tests
    SxpLib.Add Bindings    10    1.1.1.1/32    127.0.0.1
    SxpLib.Add Bindings    10    1.1.1.0/24    127.0.0.1
    SxpLib.Add Bindings    10    1.1.0.0/16    127.0.0.1
    SxpLib.Add Bindings    10    1.0.0.0/8    127.0.0.1
    FOR    ${node}    IN RANGE    3    6
        SxpLib.Add Bindings    ${node}0    1.1.1.${node}/32    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    1.1.${node}.0/24    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    1.${node}.0.0/16    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    ${node}.0.0.0/8    127.0.0.${node}
    END
    SxpLib.Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.2    ${password}
    SxpLib.Add Connection    ${version}    speaker    127.0.0.2    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    speaker    127.0.0.2
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    listener    127.0.0.3
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.4    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.4    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    listener    127.0.0.4
    SxpLib.Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.5    ${password}
    SxpLib.Add Connection    ${version}    both    127.0.0.5    64999    127.0.0.4    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    SxpLib.Verify Connection    ${version}    both    127.0.0.5
    ...    64999    127.0.0.4

Check PeerSequence One
    [Documentation]    Node 127.0.0.2 should contain only bindings with peer sequence lower or equals 1
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    FOR    ${node}    IN RANGE    3    6
        SxpLib.Should Not Contain Binding    ${resp}    ${node}0    10.10.10.${node}0/32
        SxpLib.Should Not Contain Binding    ${resp}    ${node}0    10.10.${node}0.0/24
        SxpLib.Should Not Contain Binding    ${resp}    ${node}0    10.${node}0.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    ${node}0    ${node}0.0.0.0/8
    END

Check PeerSequence Two
    [Documentation]    Node 127.0.0.2 should contain only bindings with peer sequence lower or equals 2
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Contain Binding    ${resp}    30    30.0.0.0/8
    FOR    ${node}    IN RANGE    4    6
        SxpLib.Should Not Contain Binding    ${resp}    ${node}0    10.10.10.${node}0/32
        SxpLib.Should Not Contain Binding    ${resp}    ${node}0    10.10.${node}0.0/24
        SxpLib.Should Not Contain Binding    ${resp}    ${node}0    10.${node}0.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    ${node}0    ${node}0.0.0.0/8
    END

Check PeerSequence Three
    [Documentation]    Node 127.0.0.2 should contain only bindings with peer sequence lower or equals 3
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Contain Binding    ${resp}    30    30.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    40    10.10.10.40/32
    SxpLib.Should Contain Binding    ${resp}    40    10.10.40.0/24
    SxpLib.Should Contain Binding    ${resp}    40    10.40.0.0/16
    SxpLib.Should Contain Binding    ${resp}    40    40.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    50    10.10.10.50/32
    SxpLib.Should Not Contain Binding    ${resp}    50    10.10.50.0/24
    SxpLib.Should Not Contain Binding    ${resp}    50    10.50.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    50    50.0.0.0/8

Check PeerSequence Mix
    [Documentation]    Node 127.0.0.2 should not contain bindings with peer sequence 1
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Not Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Not Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    40    10.10.10.40/32
    SxpLib.Should Contain Binding    ${resp}    40    10.10.40.0/24
    SxpLib.Should Contain Binding    ${resp}    40    10.40.0.0/16
    SxpLib.Should Contain Binding    ${resp}    40    40.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    50    10.10.10.50/32
    SxpLib.Should Contain Binding    ${resp}    50    10.10.50.0/24
    SxpLib.Should Contain Binding    ${resp}    50    10.50.0.0/16
    SxpLib.Should Contain Binding    ${resp}    50    50.0.0.0/8

Check Inbound PL Combinations Filtering
    [Documentation]    Node 127.0.0.1 should containt bindings with peer sequence lower than 1 and pl 1.1.0.0/16
    ${resp} =    SxpLib.Get Bindings    127.0.0.1
    SxpLib.Should Contain Binding    ${resp}    20    1.1.1.2/32
    SxpLib.Should Contain Binding    ${resp}    20    1.1.2.0/24
    SxpLib.Should Not Contain Binding    ${resp}    20    1.2.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    20    2.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    30    1.1.1.3/32
    SxpLib.Should Not Contain Binding    ${resp}    30    1.1.3.0/24
    SxpLib.Should Not Contain Binding    ${resp}    30    1.3.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    30    3.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    40    1.1.1.4/32
    SxpLib.Should Not Contain Binding    ${resp}    40    1.1.4.0/24
    SxpLib.Should Not Contain Binding    ${resp}    40    1.4.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    40    4.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    50    1.1.1.5/32
    SxpLib.Should Contain Binding    ${resp}    50    1.1.5.0/24
    SxpLib.Should Contain Binding    ${resp}    50    1.5.0.0/16
    SxpLib.Should Contain Binding    ${resp}    50    5.0.0.0/8

Check Inbound ACL Combinations Filtering
    [Documentation]    Node 127.0.0.1 should containt bindings with peer sequence lower than 2 and acl 1.1.1.0 0.0.0.255
    ${resp} =    SxpLib.Get Bindings    127.0.0.1
    SxpLib.Should Contain Binding    ${resp}    20    1.1.1.2/32
    SxpLib.Should Not Contain Binding    ${resp}    20    1.1.2.0/24
    SxpLib.Should Not Contain Binding    ${resp}    20    1.2.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    20    2.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    1.1.1.3/32
    SxpLib.Should Not Contain Binding    ${resp}    30    1.1.3.0/24
    SxpLib.Should Not Contain Binding    ${resp}    30    1.3.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    30    3.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    40    1.1.1.4/32
    SxpLib.Should Contain Binding    ${resp}    40    1.1.4.0/24
    SxpLib.Should Contain Binding    ${resp}    40    1.4.0.0/16
    SxpLib.Should Contain Binding    ${resp}    40    4.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    50    1.1.1.5/32
    SxpLib.Should Not Contain Binding    ${resp}    50    1.1.5.0/24
    SxpLib.Should Not Contain Binding    ${resp}    50    1.5.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    50    5.0.0.0/8

Check Outbound PL Combinations Filtering
    [Documentation]    Node 127.0.0.2 should containt bindings with peer sequence lower than 1 and pl 1.1.1.0/24
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    SxpLib.Should Contain Binding    ${resp}    10    1.1.1.1/32
    SxpLib.Should Contain Binding    ${resp}    10    1.1.1.0/24
    SxpLib.Should Not Contain Binding    ${resp}    10    1.1.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    10    1.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    1.1.1.3/32
    SxpLib.Should Not Contain Binding    ${resp}    30    1.1.3.0/24
    SxpLib.Should Not Contain Binding    ${resp}    30    1.3.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    30    3.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    40    1.1.1.4/32
    SxpLib.Should Not Contain Binding    ${resp}    40    1.1.4.0/24
    SxpLib.Should Not Contain Binding    ${resp}    40    1.4.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    40    4.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    50    1.1.1.5/32
    SxpLib.Should Not Contain Binding    ${resp}    50    1.1.5.0/24
    SxpLib.Should Not Contain Binding    ${resp}    50    1.5.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    50    5.0.0.0/8

Check Outbound ACL Combinations Filtering
    [Documentation]    Node 127.0.0.2 should containt bindings with peer sequence equals to 0 or greter than 2 and acl 1.1.0.0 0.0.255.255
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    SxpLib.Should Contain Binding    ${resp}    10    1.1.1.1/32
    SxpLib.Should Contain Binding    ${resp}    10    1.1.1.0/24
    SxpLib.Should Contain Binding    ${resp}    10    1.1.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    10    1.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    30    1.1.1.3/32
    SxpLib.Should Not Contain Binding    ${resp}    30    1.1.3.0/24
    SxpLib.Should Not Contain Binding    ${resp}    30    1.3.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    30    3.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    40    1.1.1.4/32
    SxpLib.Should Not Contain Binding    ${resp}    40    1.1.4.0/24
    SxpLib.Should Not Contain Binding    ${resp}    40    1.4.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    40    4.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    50    1.1.1.5/32
    SxpLib.Should Contain Binding    ${resp}    50    1.1.5.0/24
    SxpLib.Should Not Contain Binding    ${resp}    50    1.5.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    50    5.0.0.0/8

Clean Nodes
    SxpLib.Clean Bindings    127.0.0.1
    SxpLib.Clean Bindings    127.0.0.2
    SxpLib.Clean Bindings    127.0.0.3
    SxpLib.Clean Bindings    127.0.0.4
    SxpLib.Clean Bindings    127.0.0.5
    SxpLib.Clean Peer Groups    127.0.0.1
    SxpLib.Clean Connections    127.0.0.1
    SxpLib.Clean Connections    127.0.0.2
    SxpLib.Clean Connections    127.0.0.3
    SxpLib.Clean Connections    127.0.0.4
    SxpLib.Clean Connections    127.0.0.5
