*** Settings ***
Documentation     Test suite to verify inbound-discarding filtering functionality
Suite Setup       Setup SXP Environment    5
Suite Teardown    Clean SXP Environment    5
Test Teardown     Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/SxpLib.robot

*** Variables ***

*** Test Cases ***
Access List Filtering
    [Documentation]    Test ACL filter behaviour during filter update
    [Tags]    SXP    Filtering
    Setup Nodes
    ${peers} =    Sxp.Add Peers    127.0.0.2    127.0.0.4
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    acl=10.10.10.0,0.0.0.255
    ${entry2} =    Sxp.Get Filter Entry    20    permit    acl=10.0.0.0,0.254.0.0
    ${entries} =    Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    inbound-discarding    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 4-2
    SxpLib.Delete Filter    GROUP    inbound-discarding
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 4-2

Access List Sgt Filtering
    [Documentation]    Test ACL and SGT filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers} =    Sxp.Add Peers    127.0.0.3    127.0.0.5
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    sgt=30    acl=10.10.10.0,0.0.0.255
    ${entry2} =    Sxp.Get Filter Entry    20    permit    sgt=50    acl=10.0.0.0,0.254.0.0
    ${entries} =    Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    inbound-discarding    ${entries}
    Setup Nodes
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 5-3
    SxpLib.Delete Filter    GROUP    inbound-discarding
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 5-3

Prefix List Filtering
    [Documentation]    Test Prefix List filter behaviour during filter update
    [Tags]    SXP    Filtering
    Setup Nodes
    ${peers} =    Sxp.Add Peers    127.0.0.2    127.0.0.4
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    pl=10.10.10.0/24
    ${entry2} =    Sxp.Get Filter Entry    20    permit    epl=10.0.0.0/8,le,16
    ${entries} =    Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    inbound-discarding    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 4-2
    SxpLib.Delete Filter    GROUP    inbound-discarding
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 4-2

Prefix List Sgt Filtering
    [Documentation]    Test Prefix List and SGT filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers} =    Sxp.Add Peers    127.0.0.3    127.0.0.5
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    sgt=30    pl=10.10.10.0/24
    ${entry2} =    Sxp.Get Filter Entry    20    permit    pl=10.50.0.0/16
    ${entries} =    Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    inbound-discarding    ${entries}
    Setup Nodes
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 5-3
    SxpLib.Delete Filter    GROUP    inbound-discarding
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 5-3

Access List Filtering Legacy
    [Documentation]    Test ACL filter behaviour during filter update
    [Tags]    SXP    Filtering
    Setup Nodes Legacy Par Two
    ${peers} =    Sxp.Add Peers    127.0.0.2    127.0.0.4
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    acl=10.10.10.0,0.0.0.255
    ${entry2} =    Sxp.Get Filter Entry    20    permit    acl=10.0.0.0,0.254.0.0
    ${entries} =    Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    inbound-discarding    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 4-2
    SxpLib.Delete Filter    GROUP    inbound-discarding
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 4-2

Access List Sgt Filtering Legacy
    [Documentation]    Test ACL and SGT filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers} =    Sxp.Add Peers    127.0.0.3    127.0.0.5
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    sgt=30    acl=10.10.10.0,0.0.0.255
    ${entry2} =    Sxp.Get Filter Entry    20    permit    sgt=50    acl=10.0.0.0,0.254.0.0
    ${entries} =    Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    inbound-discarding    ${entries}
    Setup Nodes Legacy Par One
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 5-3
    SxpLib.Delete Filter    GROUP    inbound-discarding
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 5-3

Prefix List Filtering Legacy
    [Documentation]    Test Prefix List filter behaviour during filter update
    [Tags]    SXP    Filtering
    Setup Nodes Legacy Par Two
    ${peers} =    Sxp.Add Peers    127.0.0.2    127.0.0.4
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    pl=10.10.10.0/24
    ${entry2} =    Sxp.Get Filter Entry    20    permit    epl=10.0.0.0/8,le,16
    ${entries} =    Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    inbound-discarding    ${entries}
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 4-2
    SxpLib.Delete Filter    GROUP    inbound-discarding
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 4-2

Prefix List Sgt Filtering Legacy
    [Documentation]    Test Prefix List and SGT filter behaviour during filter update
    [Tags]    SXP    Filtering
    ${peers} =    Sxp.Add Peers    127.0.0.3    127.0.0.5
    SxpLib.Add PeerGroup    GROUP    ${peers}
    ${entry1} =    Sxp.Get Filter Entry    10    permit    sgt=30    pl=10.10.10.0/24
    ${entry2} =    Sxp.Get Filter Entry    20    permit    pl=10.50.0.0/16
    ${entries} =    Combine Strings    ${entry1}    ${entry2}
    SxpLib.Add Filter    GROUP    inbound-discarding    ${entries}
    Setup Nodes Legacy Par One
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 5-3
    SxpLib.Delete Filter    GROUP    inbound-discarding
    BuiltIn.Wait Until Keyword Succeeds    4    2    Check One Group 5-3

*** Keywords ***
Setup Nodes
    [Arguments]    ${version}=version4    ${password}=none
    FOR    ${node}    IN RANGE    2    5
        SxpLib.Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.${node}
        ...    ${password}
        SxpLib.Add Connection    ${version}    both    127.0.0.${node}    64999    127.0.0.1
        ...    ${password}
        BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both
        ...    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    END
    SxpLib.Add Connection    ${version}    both    127.0.0.5    64999    127.0.0.3    ${password}
    SxpLib.Add Connection    ${version}    both    127.0.0.3    64999    127.0.0.5    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.5
    ...    64999    127.0.0.3
    SxpLib.Add Bindings    50    10.10.10.50/32    127.0.0.5
    SxpLib.Add Bindings    50    10.10.50.0/24    127.0.0.5
    SxpLib.Add Bindings    50    10.50.0.0/16    127.0.0.5
    SxpLib.Add Bindings    50    50.0.0.0/8    127.0.0.5
    SxpLib.Add Bindings    10    10.10.10.10/32    127.0.0.1
    SxpLib.Add Bindings    10    10.10.10.0/24    127.0.0.1
    SxpLib.Add Bindings    10    10.10.0.0/16    127.0.0.1
    SxpLib.Add Bindings    10    10.0.0.0/8    127.0.0.1

Setup Nodes Legacy Par One
    [Arguments]    ${version}=version3    ${password}=none
    FOR    ${node}    IN RANGE    1    6
        SxpLib.Add Bindings    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    END
    SxpLib.Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.2    ${password}
    SxpLib.Add Connection    ${version}    speaker    127.0.0.2    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.2
    SxpLib.Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.4    ${password}
    SxpLib.Add Connection    ${version}    speaker    127.0.0.4    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.4
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    SxpLib.Add Connection    ${version}    listener    127.0.0.5    64999    127.0.0.3    ${password}
    SxpLib.Add Connection    ${version}    speaker    127.0.0.3    64999    127.0.0.5    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.5
    ...    64999    127.0.0.3

Setup Nodes Legacy Par Two
    [Arguments]    ${version}=version3    ${password}=none
    FOR    ${node}    IN RANGE    1    6
        SxpLib.Add Bindings    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    END
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.4    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.4    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.4
    SxpLib.Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.3    ${password}
    SxpLib.Add Connection    ${version}    speaker    127.0.0.3    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.3
    SxpLib.Add Connection    ${version}    speaker    127.0.0.5    64999    127.0.0.3    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.5    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.5
    ...    64999    127.0.0.3

Check One Group 4-2
    [Documentation]    Check if only bindings matching filter from node 4 and 2 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.10.10.0 0.0.0.255
    ...    permit ACL 10.0.0.0 0.254.0.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp} =    SxpLib.Get Bindings    127.0.0.5
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    20    10.10.10.20/32
    SxpLib.Should Not Contain Binding    ${resp}    20    10.10.20.0/24
    SxpLib.Should Contain Binding    ${resp}    20    10.20.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Contain Binding    ${resp}    30    30.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    40    10.10.10.40/32
    SxpLib.Should Not Contain Binding    ${resp}    40    10.10.40.0/24
    SxpLib.Should Contain Binding    ${resp}    40    10.40.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    40    40.0.0.0/8

Check One Group 5-3
    [Documentation]    Check if only bindings matching filter from node 5 and 3 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit SGT 30 ACL 10.10.10.0 0.0.0.255
    ...    permit SGT 50 ACL 10.0.0.0 0.254.0.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp} =    SxpLib.Get Bindings    127.0.0.4
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Not Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Not Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    50    10.10.10.50/32
    SxpLib.Should Not Contain Binding    ${resp}    50    10.10.50.0/24
    SxpLib.Should Contain Binding    ${resp}    50    10.50.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    50    50.0.0.0/8

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
