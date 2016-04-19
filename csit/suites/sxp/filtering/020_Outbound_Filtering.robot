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
Access List Filtering
    [Documentation]    Test ACL filter behaviour during filter update
    ${peers}    Add Peers    127.0.0.4    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    acl=10.10.10.0,0.0.0.255
    ${entry2}    Get Filter Entry    20    deny    acl=10.10.0.0,0.0.255.0
    ${entry3}    Get Filter Entry    30    permit    acl=10.0.0.0,0.255.255.0
    ${entries}    Combine Strings    ${entry1}    ${entry2}    ${entry3}
    Add Filter    GROUP    outbound    ${entries}
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check One Group 4-5
    Delete Filter    GROUP    outbound
    ${entry1}    Get Filter Entry    10    permit    acl=10.20.0.0,0.0.255.255
    ${entry2}    Get Filter Entry    20    permit    acl=10.10.0.0,0.0.255.0
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Two Group 4-5

Access List Sgt Filtering
    [Documentation]    Test ACL and SGT filter behaviour during filter update
    ${peers}    Add Peers    127.0.0.2    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    deny    acl=10.10.20.0,0.0.0.255
    ${entry2}    Get Filter Entry    20    permit    acl=10.10.0.0,0.0.255.0
    ${entry3}    Get Filter Entry    30    permit    sgt=30    acl=10.10.10.0,0.0.0.255
    ${entries}    Combine Strings    ${entry1}    ${entry2}    ${entry3}
    Add Filter    GROUP    outbound    ${entries}
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check One Group 2-5
    Delete Filter    GROUP    outbound
    ${entries}    Get Filter Entry    10    permit    esgt=20,40    acl=10.10.0.0,0.0.255.255
    Add Filter    GROUP    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Two Group 2-5

Prefix List Filtering
    [Documentation]    Test Prefix List filter behaviour during filter update
    ${peers}    Add Peers    127.0.0.4    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    pl=10.10.10.0/24
    ${entry2}    Get Filter Entry    20    deny    epl=10.10.0.0/16,le,24
    ${entry3}    Get Filter Entry    30    permit    epl=10.0.0.0/8,le,24
    ${entries}    Combine Strings    ${entry1}    ${entry2}    ${entry3}
    Add Filter    GROUP    outbound    ${entries}
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check One Group 4-5
    Delete Filter    GROUP    outbound
    ${entry1}    Get Filter Entry    10    permit    pl=10.20.0.0/16
    ${entry2}    Get Filter Entry    20    permit    epl=10.10.0.0/16,le,24
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Two Group 4-5

Prefix List Sgt Filtering
    [Documentation]    Test Prefix List and SGT filter behaviour during filter update
    ${peers}    Add Peers    127.0.0.2    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    deny    pl=10.10.20.0/24
    ${entry2}    Get Filter Entry    20    permit    epl=10.10.0.0/16,le,24
    ${entry3}    Get Filter Entry    30    permit    sgt=30    pl=10.10.10.0/24
    ${entries}    Combine Strings    ${entry1}    ${entry2}    ${entry3}
    Add Filter    GROUP    outbound    ${entries}
    Setup Nodes
    Wait Until Keyword Succeeds    4    1    Check One Group 2-5
    Delete Filter    GROUP    outbound
    ${entries}    Get Filter Entry    10    permit    esgt=20,40    pl=10.10.0.0/16
    Add Filter    GROUP    outbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Two Group 2-5

*** Keywords ***
Setup Nodes
    [Arguments]    ${version}=version4    ${password}=none
    : FOR    ${node}    IN RANGE    1    5
    \    Add Binding    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
    \    Add Binding    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
    \    Add Binding    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.2    ${password}
    Add Connection    ${version}    both    127.0.0.2    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.2
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    ${password}
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.4    ${password}
    Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.4
    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.5    ${password}
    Add Connection    ${version}    speaker    127.0.0.5    64999    127.0.0.1    ${password}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.5

Check One Group 4-5
    [Documentation]    Check if only bindings matching filter nodes 4 and 5
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.10.10.0 0.0.0.255
    ...    deny ACL 10.10.0.0 0.0.255.0
    ...    permit ACL 10.0.0.0 0.255.255.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    : FOR    ${node}    IN RANGE    4    6
    \    ${resp}    Get Bindings    127.0.0.${node}
    \    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    \    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    \    Should Not Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    \    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    \    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    \    Should Not Contain Binding    ${resp}    20    10.10.20.0/24    sxp
    \    Should Contain Binding    ${resp}    20    10.20.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    20    20.0.0.0/8    sxp
    \    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    \    Should Not Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    \    Should Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    30    30.0.0.0/8    sxp
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

Check Two Group 4-5
    [Documentation]    Check if only bindings matching filter nodes 4 and 5
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.20.0.0 0.0.255.255
    ...    permit ACL 10.10.0.0 0.0.255.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    : FOR    ${node}    IN RANGE    4    6
    \    ${resp}    Get Bindings    127.0.0.${node}
    \    Should Not Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    \    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    \    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    \    Should Not Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    \    Should Contain Binding    ${resp}    20    10.10.20.0/24    sxp
    \    Should Contain Binding    ${resp}    20    10.20.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    20    20.0.0.0/8    sxp
    \    Should Not Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    \    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    \    Should Not Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    30    30.0.0.0/8    sxp
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

Check One Group 2-5
    [Documentation]    Check if only bindings matching filter nodes 2 and 5
    ...    Database should contains only Bindings regarding to these matches:
    ...    deny ACL 10.10.20.0 0.0.0.255
    ...    permit ACL 10.10.0.0 0.0.255.0
    ...    permit SGT 30 ACL 10.10.10.0 0.0.0.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    @{list}    Create List    127.0.0.2    127.0.0.5
    : FOR    ${node}    IN    @{list}
    \    ${resp}    Get Bindings    ${node}
    \    Should Not Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    \    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    \    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    \    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    \    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    \    Should Not Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    \    Should Not Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    \    Should Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    \    Should Not Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    40    40.0.0.0/8    sxp
    ${resp}    Get Bindings    127.0.0.4
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding    ${resp}    20    10.10.20.0/24    sxp
    Should Contain Binding    ${resp}    20    10.20.0.0/16    sxp
    Should Contain Binding    ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/8    sxp

Check Two Group 2-5
    [Documentation]    Check if only bindings matching filter nodes 2 and 5
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit SGT 20,40 ACL 10.10.0.0 0.0.255.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    @{list}    Create List    127.0.0.2    127.0.0.5
    : FOR    ${node}    IN    @{list}
    \    ${resp}    Get Bindings    ${node}
    \    Should Not Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    \    Should Not Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    \    Should Not Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    \    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    \    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    \    Should Not Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    \    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    \    Should Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    \    Should Not Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    \    Should Not Contain Binding    ${resp}    40    40.0.0.0/8    sxp
    ${resp}    Get Bindings    127.0.0.4
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding    ${resp}    20    10.10.20.0/24    sxp
    Should Contain Binding    ${resp}    20    10.20.0.0/16    sxp
    Should Contain Binding    ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/8    sxp

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
