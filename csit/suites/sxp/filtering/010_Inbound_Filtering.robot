*** Settings ***
Documentation     Test suite to verify Inbound filtering functionality
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
    ${peers}    Add Peers    127.0.0.2    127.0.0.4
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    acl=10.10.10.0,0.0.0.255
    ${entry2}    Get Filter Entry    20    permit    acl=10.0.0.0,0.254.0.0
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    inbound    ${entries}
    Setup Topology Complex
    Wait Until Keyword Succeeds    4    1    Check One Group 4-2
    Delete Filter    GROUP    inbound
    ${entries}    Get Filter Entry    10    permit    acl=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Two Group 4-2
    Delete Filter    GROUP    inbound
    ${entries}    Get Filter Entry    10    deny    acl=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Three Group 4-2

Access List Sgt Filtering
    [Documentation]    Test ACL and SGT filter behaviour during filter update
    ${peers}    Add Peers    127.0.0.3    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    sgt=30    acl=10.10.10.0,0.0.0.255
    ${entry2}    Get Filter Entry    20    permit    sgt=50    acl=10.0.0.0,0.254.0.0
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    inbound    ${entries}
    Setup Topology Complex
    Wait Until Keyword Succeeds    4    1    Check One Group 5-3
    Delete Filter    GROUP    inbound
    ${entries}    Get Filter Entry    10    permit    esgt=20,40    acl=10.0.0.0,0.255.255.255
    Add Filter    GROUP    inbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Two Group 5-3

Prefix List Filtering
    [Documentation]    Test Prefix List filter behaviour during filter update
    ${peers}    Add Peers    127.0.0.2    127.0.0.4
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    pl=10.10.10.0/24
    ${entry2}    Get Filter Entry    20    permit    epl=10.0.0.0/8,le,16
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    inbound    ${entries}
    Setup Topology Complex
    Wait Until Keyword Succeeds    4    1    Check One Group 4-2
    Delete Filter    GROUP    inbound
    ${entries}    Get Filter Entry    10    permit    pl=10.0.0.0/8
    Add Filter    GROUP    inbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Two Group 4-2
    Delete Filter    GROUP    inbound
    ${entries}    Get Filter Entry    10    deny    pl=10.0.0.0/8
    Add Filter    GROUP    inbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Three Group 4-2

Prefix List Sgt Filtering
    [Documentation]    Test Prefix List and SGT filter behaviour during filter update
    ${peers}    Add Peers    127.0.0.3    127.0.0.5
    Add PeerGroup    GROUP    ${peers}
    ${entry1}    Get Filter Entry    10    permit    sgt=30    pl=10.10.10.0/24
    ${entry2}    Get Filter Entry    20    permit    pl=10.50.0.0/16
    ${entries}    Combine Strings    ${entry1}    ${entry2}
    Add Filter    GROUP    inbound    ${entries}
    Setup Topology Complex
    Wait Until Keyword Succeeds    4    1    Check One Group 5-3
    Delete Filter    GROUP    inbound
    ${entries}    Get Filter Entry    10    permit    esgt=20,40    pl=10.0.0.0/8
    Add Filter    GROUP    inbound    ${entries}
    Wait Until Keyword Succeeds    4    1    Check Two Group 5-3

*** Keywords ***
Check One Group 4-2
    [Documentation]    Check if only bindings matching filter from node 4 and 2 are propagated to SXP-DB other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.10.10.0 0.0.0.255
    ...    permit ACL 10.0.0.0 0.254.0.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp}    Get Bindings    127.0.0.5
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Not Contain Binding    ${resp}    20    10.10.20.0/24    sxp
    Should Contain Binding    ${resp}    20    10.20.0.0/16    sxp
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Not Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8    sxp
    ${resp}    Get Bindings    127.0.0.3
    Should Contain Binding    ${resp}    50    10.10.10.50/32    sxp
    Should Contain Binding    ${resp}    50    10.10.50.0/24    sxp
    Should Contain Binding    ${resp}    50    10.50.0.0/16    sxp
    Should Contain Binding    ${resp}    50    50.0.0.0/8    sxp

Check Two Group 4-2
    [Documentation]    Check if only bindings matching filter from node 4 and 2 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.0.0.0 0.255.255.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp}    Get Bindings    127.0.0.5
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    Should Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Contain Binding    ${resp}    20    10.10.20.0/24    sxp
    Should Contain Binding    ${resp}    20    10.20.0.0/16    sxp
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8    sxp
    ${resp}    Get Bindings    127.0.0.3
    Should Contain Binding    ${resp}    50    10.10.10.50/32    sxp
    Should Contain Binding    ${resp}    50    10.10.50.0/24    sxp
    Should Contain Binding    ${resp}    50    10.50.0.0/16    sxp
    Should Contain Binding    ${resp}    50    50.0.0.0/8    sxp

Check Three Group 4-2
    [Documentation]    Check if only bindings matching filter from node 4 and 2 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    deny ACL 10.0.0.0 0.255.255.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp}    Get Bindings    127.0.0.5
    Should Contain Binding    ${resp}    10    10.10.10.10/32    sxp
    Should Contain Binding    ${resp}    10    10.10.10.0/24    sxp
    Should Contain Binding    ${resp}    10    10.10.0.0/16    sxp
    Should Contain Binding    ${resp}    10    10.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    20    10.10.10.20/32    sxp
    Should Not Contain Binding    ${resp}    20    10.10.20.0/24    sxp
    Should Not Contain Binding    ${resp}    20    10.20.0.0/16    sxp
    Should Not Contain Binding    ${resp}    20    20.0.0.0/8    sxp
    Should Contain Binding    ${resp}    30    10.10.10.30/32    sxp
    Should Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Not Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    Should Not Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    Should Not Contain Binding    ${resp}    40    40.0.0.0/8    sxp

Check One Group 5-3
    [Documentation]    Check if only bindings matching filter from node 5 and 3 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit SGT 30 ACL 10.10.10.0 0.0.0.255
    ...    permit SGT 50 ACL 10.0.0.0 0.254.0.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
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
    Should Not Contain Binding    ${resp}    30    10.10.30.0/24    sxp
    Should Not Contain Binding    ${resp}    30    10.30.0.0/16    sxp
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    50    10.10.10.50/32    sxp
    Should Not Contain Binding    ${resp}    50    10.10.50.0/24    sxp
    Should Contain Binding    ${resp}    50    10.50.0.0/16    sxp
    Should Not Contain Binding    ${resp}    50    50.0.0.0/8    sxp
    ${resp}    Get Bindings    127.0.0.2
    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    Should Contain Binding    ${resp}    40    40.0.0.0/8    sxp

Check Two Group 5-3
    [Documentation]    Check if only bindings matching filter from node 5 and 3 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ESGT 20,40 ACL 10.0.0.0 0.255.255.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
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
    Should Not Contain Binding    ${resp}    30    30.0.0.0/8    sxp
    Should Not Contain Binding    ${resp}    50    10.10.10.50/32    sxp
    Should Not Contain Binding    ${resp}    50    10.10.50.0/24    sxp
    Should Not Contain Binding    ${resp}    50    10.50.0.0/16    sxp
    Should Not Contain Binding    ${resp}    50    50.0.0.0/8    sxp
    ${resp}    Get Bindings    127.0.0.2
    Should Contain Binding    ${resp}    40    10.10.10.40/32    sxp
    Should Contain Binding    ${resp}    40    10.10.40.0/24    sxp
    Should Contain Binding    ${resp}    40    10.40.0.0/16    sxp
    Should Contain Binding    ${resp}    40    40.0.0.0/8    sxp

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
