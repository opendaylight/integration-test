*** Settings ***
Documentation     Test suite for RESTCONF Topology
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
@{node_list}      openflow:1    openflow:2    openflow:3

*** Test Cases ***
Get RESTCONF Topology
    [Documentation]    Get RESTCONF Topology and validate the result.
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list}
    ${resp}    RequestsLibrary.GET On Session    session    ${OPERATIONAL_TOPO_API}
    Log    ${resp.text}

List all the links
    [Documentation]    List all the links in the topology.
    ${body1}    Create Dictionary    dest-node=openflow:1    dest-tp=openflow:1:2
    ${body2}    Create Dictionary    source-node=openflow:3    source-tp=openflow:3:3
    ${link2}    Create Dictionary    link-id=openflow:3:3    destination=${body1}    source=${body2}
    Set Suite Variable    ${link2}
    ${body1}    Create Dictionary    dest-node=openflow:1    dest-tp=openflow:1:1
    ${body2}    Create Dictionary    source-node=openflow:2    source-tp=openflow:2:3
    ${link1}    Create Dictionary    link-id=openflow:2:3    destination=${body1}    source=${body2}
    Set Suite Variable    ${link1}
    ${body1}    Create Dictionary    dest-node=openflow:3    dest-tp=openflow:3:3
    ${body2}    Create Dictionary    source-node=openflow:1    source-tp=openflow:1:2
    ${link4}    Create Dictionary    link-id=openflow:1:2    destination=${body1}    source=${body2}
    Set Suite Variable    ${link4}
    ${body1}    Create Dictionary    dest-node=openflow:2    dest-tp=openflow:2:3
    ${body2}    Create Dictionary    source-node=openflow:1    source-tp=openflow:1:1
    ${link3}    Create Dictionary    link-id=openflow:1:1    destination=${body1}    source=${body2}
    Set Suite Variable    ${link3}
    ${links}    Create List    ${link1}    ${link2}    ${link3}    ${link4}
    Wait Until Keyword Succeeds    10s    2s    Verify Links    ${links}

Link Down
    [Documentation]    Take link s1-s2 down
    Write    link s1 s2 down
    Read Until    mininet>
    ${links}    Create List    ${link2}    ${link4}
    # increasing the WUKS timeout to 60s to see if the CI environment might just be taking
    # longer for this test with the lithium redesign plugin
    Wait Until Keyword Succeeds    60s    2s    Verify Links    ${links}
    # shot in the dark.    maybe the "link s1 s2 down" really didn't take the link(s) down?
    # hopefully this output below will show that.
    Write    sh ovs-vsctl find Interface name="s1-eth1"
    ${output}=    Read Until    mininet>
    Log    ${output}
    Write    sh ovs-vsctl find Interface name="s1-eth2"
    ${output}=    Read Until    mininet>
    Log    ${output}

Link Up
    [Documentation]    Take link s1-s2 up
    Write    link s1 s2 up
    Read Until    mininet>
    ${links}    Create List    ${link1}    ${link2}    ${link3}    ${link4}
    Wait Until Keyword Succeeds    10s    2s    Verify Links    ${links}

Remove Port
    [Documentation]    Remove port s2-eth2
    [Tags]    exclude
    Write    sh ovs-vsctl del-port s2 s2-eth2
    Read Until    mininet>
    @{list}    Create List    openflow:2:2
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Add Port
    [Documentation]    Add port s2-eth2, new id 5
    [Tags]    exclude
    Write    sh ovs-vsctl add-port s2 s2-eth2
    Read Until    mininet>
    @{list}    Create List    openflow:2:5
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

*** Keywords ***
Verify Links
    [Arguments]    ${expected_links}
    ${resp}    RequestsLibrary.GET On Session    session    ${OPERATIONAL_TOPO_API}/topology/flow:1
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.text}
    Log    ${result}
    ${content}    Get From Dictionary    ${result}    topology
    ${topology}    Get From List    ${content}    0
    ${links}    Get From Dictionary    ${topology}    link
    FOR    ${expected_link}    IN    @{expected_links}
        Should Contain    ${links}    ${expected_link}
    END
