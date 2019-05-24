*** Settings ***
Documentation     Library containing Keywords used for SXP filtering test checks
Resource          ../SxpLib.robot

*** Keywords ***
Setup Nodes
    [Arguments]    ${version}=version4    ${password}=none
    FOR    ${node}    IN RANGE    1    5
        SxpLib.Add Bindings    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
        SxpLib.Add Bindings    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    END
    SxpLib.Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.2    ${password}
    SxpLib.Add Connection    ${version}    both    127.0.0.2    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.2
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    ${password}
    SxpLib.Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    SxpLib.Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.4    ${password}
    SxpLib.Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.4
    SxpLib.Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.5    ${password}
    SxpLib.Add Connection    ${version}    speaker    127.0.0.5    64999    127.0.0.1    ${password}
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.5

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

Check One Group 4-5
    [Documentation]    Check if only bindings matching filter nodes 4 and 5
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.10.10.0 0.0.0.255
    ...    deny ACL 10.10.0.0 0.0.255.0
    ...    permit ACL 10.0.0.0 0.255.255.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    FOR    ${node}    IN RANGE    4    6
        ${resp} =    SxpLib.Get Bindings    127.0.0.${node}
        BuiltIn.Log    ${resp}
        SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
        SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
        SxpLib.Should Not Contain Binding    ${resp}    10    10.10.0.0/16
        SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
        SxpLib.Should Contain Binding    ${resp}    20    10.10.10.20/32
        SxpLib.Should Not Contain Binding    ${resp}    20    10.10.20.0/24
        SxpLib.Should Contain Binding    ${resp}    20    10.20.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    20    20.0.0.0/8
        SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
        SxpLib.Should Not Contain Binding    ${resp}    30    10.10.30.0/24
        SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    END
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    BuiltIn.Log    ${resp}
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

Check Two Group 4-5
    [Documentation]    Check if only bindings matching filter nodes 4 and 5
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.20.0.0 0.0.255.255
    ...    permit ACL 10.10.0.0 0.0.255.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    FOR    ${node}    IN RANGE    4    6
        ${resp} =    SxpLib.Get Bindings    127.0.0.${node}
        BuiltIn.Log    ${resp}
        SxpLib.Should Not Contain Binding    ${resp}    10    10.10.10.10/32
        SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
        SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    10    10.0.0.0/8
        SxpLib.Should Not Contain Binding    ${resp}    20    10.10.10.20/32
        SxpLib.Should Contain Binding    ${resp}    20    10.10.20.0/24
        SxpLib.Should Contain Binding    ${resp}    20    10.20.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    20    20.0.0.0/8
        SxpLib.Should Not Contain Binding    ${resp}    30    10.10.10.30/32
        SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
        SxpLib.Should Not Contain Binding    ${resp}    30    10.30.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    END
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    BuiltIn.Log    ${resp}
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

Check One Group 2-5
    [Documentation]    Check if only bindings matching filter nodes 2 and 5
    ...    Database should contains only Bindings regarding to these matches:
    ...    deny ACL 10.10.20.0 0.0.0.255
    ...    permit ACL 10.10.0.0 0.0.255.0
    ...    permit SGT 30 ACL 10.10.10.0 0.0.0.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    @{list}    Create List    127.0.0.2    127.0.0.5
    FOR    ${node}    IN    @{list}
        ${resp} =    SxpLib.Get Bindings    ${node}
        BuiltIn.Log    ${resp}
        SxpLib.Should Not Contain Binding    ${resp}    10    10.10.10.10/32
        SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
        SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    10    10.0.0.0/8
        SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
        SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
        SxpLib.Should Not Contain Binding    ${resp}    30    10.30.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    30    30.0.0.0/8
        SxpLib.Should Not Contain Binding    ${resp}    40    10.10.10.40/32
        SxpLib.Should Contain Binding    ${resp}    40    10.10.40.0/24
        SxpLib.Should Not Contain Binding    ${resp}    40    10.40.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    END
    ${resp} =    SxpLib.Get Bindings    127.0.0.4
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    20    10.10.10.20/32
    SxpLib.Should Contain Binding    ${resp}    20    10.10.20.0/24
    SxpLib.Should Contain Binding    ${resp}    20    10.20.0.0/16
    SxpLib.Should Contain Binding    ${resp}    20    20.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Contain Binding    ${resp}    30    30.0.0.0/8

Check Two Group 2-5
    [Documentation]    Check if only bindings matching filter nodes 2 and 5
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit SGT 20,40 ACL 10.10.0.0 0.0.255.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    @{list} =    Create List    127.0.0.2    127.0.0.5
    FOR    ${node}    IN    @{list}
        ${resp} =    SxpLib.Get Bindings    ${node}
        BuiltIn.Log    ${resp}
        SxpLib.Should Not Contain Binding    ${resp}    10    10.10.10.10/32
        SxpLib.Should Not Contain Binding    ${resp}    10    10.10.10.0/24
        SxpLib.Should Not Contain Binding    ${resp}    10    10.10.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    10    10.0.0.0/8
        SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
        SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
        SxpLib.Should Not Contain Binding    ${resp}    30    10.30.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    30    30.0.0.0/8
        SxpLib.Should Contain Binding    ${resp}    40    10.10.10.40/32
        SxpLib.Should Contain Binding    ${resp}    40    10.10.40.0/24
        SxpLib.Should Not Contain Binding    ${resp}    40    10.40.0.0/16
        SxpLib.Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    END
    ${resp} =    SxpLib.Get Bindings    127.0.0.4
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    20    10.10.10.20/32
    SxpLib.Should Contain Binding    ${resp}    20    10.10.20.0/24
    SxpLib.Should Contain Binding    ${resp}    20    10.20.0.0/16
    SxpLib.Should Contain Binding    ${resp}    20    20.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Contain Binding    ${resp}    30    30.0.0.0/8

Check One Group 4-2
    [Documentation]    Check if only bindings matching filter from node 4 and 2 are propagated to SXP-DB other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.10.10.0 0.0.0.255
    ...    permit ACL 10.0.0.0 0.254.0.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp} =    SxpLib.Get Bindings    127.0.0.5
    BuiltIn.Log    ${resp}
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
    ${resp} =    SxpLib.Get Bindings    127.0.0.3
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    50    10.10.10.50/32
    SxpLib.Should Contain Binding    ${resp}    50    10.10.50.0/24
    SxpLib.Should Contain Binding    ${resp}    50    10.50.0.0/16
    SxpLib.Should Contain Binding    ${resp}    50    50.0.0.0/8

Check Two Group 4-2
    [Documentation]    Check if only bindings matching filter from node 4 and 2 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ACL 10.0.0.0 0.255.255.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp} =    SxpLib.Get Bindings    127.0.0.5
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    20    10.10.10.20/32
    SxpLib.Should Contain Binding    ${resp}    20    10.10.20.0/24
    SxpLib.Should Contain Binding    ${resp}    20    10.20.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Contain Binding    ${resp}    30    30.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    40    10.10.10.40/32
    SxpLib.Should Contain Binding    ${resp}    40    10.10.40.0/24
    SxpLib.Should Contain Binding    ${resp}    40    10.40.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    40    40.0.0.0/8
    ${resp} =    SxpLib.Get Bindings    127.0.0.3
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    50    10.10.10.50/32
    SxpLib.Should Contain Binding    ${resp}    50    10.10.50.0/24
    SxpLib.Should Contain Binding    ${resp}    50    10.50.0.0/16
    SxpLib.Should Contain Binding    ${resp}    50    50.0.0.0/8

Check Three Group 4-2
    [Documentation]    Check if only bindings matching filter from node 4 and 2 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    deny ACL 10.0.0.0 0.255.255.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp} =    SxpLib.Get Bindings    127.0.0.5
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    20    10.10.10.20/32
    SxpLib.Should Not Contain Binding    ${resp}    20    10.10.20.0/24
    SxpLib.Should Not Contain Binding    ${resp}    20    10.20.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    20    20.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Contain Binding    ${resp}    30    30.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    40    10.10.10.40/32
    SxpLib.Should Not Contain Binding    ${resp}    40    10.10.40.0/24
    SxpLib.Should Not Contain Binding    ${resp}    40    10.40.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    40    40.0.0.0/8

Check One Group 5-3
    [Documentation]    Check if only bindings matching filter from node 5 and 3 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit SGT 30 ACL 10.10.10.0 0.0.0.255
    ...    permit SGT 50 ACL 10.0.0.0 0.254.0.0
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp} =    SxpLib.Get Bindings    127.0.0.4
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    20    10.10.10.20/32
    SxpLib.Should Contain Binding    ${resp}    20    10.10.20.0/24
    SxpLib.Should Contain Binding    ${resp}    20    10.20.0.0/16
    SxpLib.Should Contain Binding    ${resp}    20    20.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Not Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Not Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    50    10.10.10.50/32
    SxpLib.Should Not Contain Binding    ${resp}    50    10.10.50.0/24
    SxpLib.Should Contain Binding    ${resp}    50    10.50.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    50    50.0.0.0/8
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    40    10.10.10.40/32
    SxpLib.Should Contain Binding    ${resp}    40    10.10.40.0/24
    SxpLib.Should Contain Binding    ${resp}    40    10.40.0.0/16
    SxpLib.Should Contain Binding    ${resp}    40    40.0.0.0/8

Check Two Group 5-3
    [Documentation]    Check if only bindings matching filter from node 5 and 3 are propagated to SXP-DB of other nodes
    ...    Database should contains only Bindings regarding to these matches:
    ...    permit ESGT 20,40 ACL 10.0.0.0 0.255.255.255
    ...    Info regarding filtering https://wiki.opendaylight.org/view/SXP:Beryllium:Developer_Guide
    ${resp} =    SxpLib.Get Bindings    127.0.0.4
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.10/32
    SxpLib.Should Contain Binding    ${resp}    10    10.10.10.0/24
    SxpLib.Should Contain Binding    ${resp}    10    10.10.0.0/16
    SxpLib.Should Contain Binding    ${resp}    10    10.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    20    10.10.10.20/32
    SxpLib.Should Contain Binding    ${resp}    20    10.10.20.0/24
    SxpLib.Should Contain Binding    ${resp}    20    10.20.0.0/16
    SxpLib.Should Contain Binding    ${resp}    20    20.0.0.0/8
    SxpLib.Should Contain Binding    ${resp}    30    10.10.10.30/32
    SxpLib.Should Contain Binding    ${resp}    30    10.10.30.0/24
    SxpLib.Should Contain Binding    ${resp}    30    10.30.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    30    30.0.0.0/8
    SxpLib.Should Not Contain Binding    ${resp}    50    10.10.10.50/32
    SxpLib.Should Not Contain Binding    ${resp}    50    10.10.50.0/24
    SxpLib.Should Not Contain Binding    ${resp}    50    10.50.0.0/16
    SxpLib.Should Not Contain Binding    ${resp}    50    50.0.0.0/8
    ${resp} =    SxpLib.Get Bindings    127.0.0.2
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    40    10.10.10.40/32
    SxpLib.Should Contain Binding    ${resp}    40    10.10.40.0/24
    SxpLib.Should Contain Binding    ${resp}    40    10.40.0.0/16
    SxpLib.Should Contain Binding    ${resp}    40    40.0.0.0/8
