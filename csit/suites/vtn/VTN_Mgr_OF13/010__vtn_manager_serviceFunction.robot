*** Settings ***
Documentation     Test suite for VTN Manager using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Test Cases ***
Start Scf Topology
    [Documentation]    Start Scf Topology
    Start Scf Topology

Check if switch1 detected
    [Documentation]    Check if openflow:1 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    12     3    Fetch vtn switch inventory     openflow:1

Check if switch2 detected
    [Documentation]    Check if openflow:2 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:2

Check if switch3 detected
    [Documentation]    Check if openflow:3 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:3

Check if switch4 detected
    [Documentation]    Check if openflow:4 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:4

Configure service nodes
    [Documentation]    Configure service nodes
    Configure service nodes

Start SuiteVtnMaSCFTest
    [Documentation]    Start SuiteVtnMaSCFTest
    Start SuiteVtnMaSCFTest

Start SuiteVtnMaTest
    [Documentation]    Start SuiteVtnMaTest
    Start SuiteVtnMaTest

Start Mininet Session
    [Documentation]    Start Mininet Session
    Start Mininet Session

Add a vtn Tenant2
    [Documentation]    Add a vtn Tenant2
    Add a vtn    Tenant2    {"idleTimeout": "200","hardTimeout": "600","description": "Virtual Tenant2 for Hackfest network"}

Add a vBridge Bridge1
    [Documentation]    Add a vBridge Bridge1 in vtn Tenant2
    Add a vBridge    Tenant2    Bridge1    {"ageInterval": "300","description": "Bridge1 for Tenant2"}

Add a interface IF1
    [Documentation]    Add a interface IF1 into vBrdige Bridge1
    Add a interface    Tenant2    Bridge1    IF1    {"description": "Description about IF-1","enabled": true}

Add a portmap for interface IF1
    [Documentation]    Create a portmap on Interface IF1 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:01
    ${port}    Create Dictionary    type=OF    id=2    name=s1-eth2
    ${portmap_data}    Create Dictionary    vlan=0    node=${node}    port=${port}
    Add a portmap    Tenant2    Bridge1    IF1    ${portmap_data}

Add a interface IF2
    [Documentation]    Add a interface IF2 into vBrdige Bridge1
    Add a interface    Tenant2    Bridge1    IF2    {"description": "Description about IF-2","enabled": true}

Add a portmap for interface IF2
    [Documentation]    Create a portmap on Interface IF2 of Bridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    type=OF    id=2    name=s2-eth2
    ${portmap_data}    Create Dictionary    vlan=0    node=${node}    port=${port}
    Add a portmap    Tenant2    Bridge1    IF2    ${portmap_data}

Ping h12 to h22
    [Documentation]    Ping h12 to h22, verify no packet loss
    Mininet Ping Should Succeed     h12     h22

Add a interface IF3
    [Documentation]    Add a interface IF3 into vBrdige Bridge1
    Add a interface    Tenant2    Bridge1    IF3    {"description": "Description about IF-3","enabled": true}

Add a portmap for interface IF3
    [Documentation]    Create a portmap on Interface IF3 of Bridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    type=OF    id=3    name=s2-eth3
    ${portmap_data}    Create Dictionary    vlan=0    node=${node}    port=${port}
    Add a portmap    Tenant2    Bridge1    IF3    ${portmap_data}

Add a flowcondition cond_1
    [Documentation]    Create a flowcondition cond_1
    ${inet4}=    Create Dictionary    dst=10.0.0.4
    ${inetMatch}=    Create Dictionary    inet4=${inet4}
    ${matchElement}=    Create Dictionary    index=1    inetMatch=${inetMatch}
    @{matchlist}    Create List    ${matchElement}
    ${flowcond_data}=    Create Dictionary    name=cond_1    match=${matchlist}
    Add a flowcondition  cond_1    ${flowcond_data}

Add a flowfilter for drop
    [Documentation]    Create a flowfilter with inet4 for drop action
    Add a flowfilter for drop    Tenant2    Bridge1    IF1    ${flowfilterdropdata}    ${index}
    Mininet Ping Should Not Succeed    h12    h22

Add a vTerminal vt_srvc1_1
    [Documentation]    Add a vTerminal vt_srvc1_1 in vtn Tenant2
    Add a vTerminal    Tenant2    vt_srvc1_1    {"description": "vterminal for service1"}

Add a interface IF for vt_srvc1_1
    [Documentation]    Add a interface IF into vTerminal vt_srvc1_1
    Add a interface to terminal   Tenant2    vt_srvc1_1    IF    {"description": "Description about IF-1","enabled": true}

Add a portmap for interface IF for vt_srvc1_1
    [Documentation]    Create a portmap on Interface IF of vt_srvc1_1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:03
    ${port}    Create Dictionary    type=OF    id=3    name=s3-eth3
    ${portmap_data}    Create Dictionary    vlan=0    node=${node}    port=${port}
    Add a portmap to terminal intf    Tenant2    vt_srvc1_1    IF    ${portmap_data}

Add a vTerminal vt_srvc1_2
    [Documentation]    Add a vTerminal vt_srvc1_1 in vtn Tenant2
    Add a vTerminal    Tenant2    vt_srvc1_2    {"description": "vterminal for service1_2"}

Add a interface IF for vt_srvc1_2
    [Documentation]    Add a interface IF into vTerminal vt_srvc1_2
    Add a interface to terminal   Tenant2    vt_srvc1_2    IF    {"description": "Description about IF-1_2","enabled": true}

Add a portmap for interface IF for vt_srvc1_2
    [Documentation]    Create a portmap on Interface IF of vt_srvc1_2
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:04
    ${port}    Create Dictionary    type=OF    id=3    name=s4-eth3
    ${portmap_data}    Create Dictionary    vlan=0    node=${node}    port=${port}
    Add a portmap to terminal intf    Tenant2    vt_srvc1_2    IF    ${portmap_data}

Add a flowcondition cond_1 for service chain function
    [Documentation]    Create a flowcondition cond_1
    ${inet4}=    Create Dictionary    dst=10.0.0.4
    ${inetMatch}=    Create Dictionary    inet4=${inet4}
    ${matchElement}=    Create Dictionary    index=1    inetMatch=${inetMatch}
    @{matchlist}    Create List    ${matchElement}
    ${flowcond_data}=    Create Dictionary    name=cond_1    match=${matchlist}
    Add a flowcondition for service  service chain function cond_1    ${flowcond_data}

Add a flowcondition cond_Any
    [Documentation]    Create a flowcondition cond_Any
    ${matchElement}=    Create Dictionary    index=1
    @{matchlist}    Create List    ${matchElement}
    ${flowcond_data}=    Create Dictionary    name=cond_Any    match=${matchlist}
    Add a flowcondition  cond_Any    ${flowcond_data}

Add a flowfilter for redirect any
    [Documentation]    Create a flowfilter for redirect
    Add a flowfilter terminal redirect   Tenant2    vt_srvc1_2    IF    ${flowfilterRedirectAnydata}    ${index}

Add a flowfilter for redirect
    [Documentation]    Create a flowfilter for redirect
    Update a flowfilter    Tenant2    Bridge1    IF1    ${flowfilterRedirectdata}    ${index}

Ping h12 to h22 after redirect
    [Documentation]    Ping h12 to h22, verify no packet loss
    Wait_Until_Keyword_Succeeds    12     3    Mininet Ping Should Succeed     h12     h22

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Delete a flowcondition    cond_1

Delete a flowcondition cond_Any
    [Documentation]    Delete a flowcondition
    Delete a flowcondition    cond_Any

Delete a vtn Tenant2
    [Documentation]    Delete a vtn Tenant2
    Delete a vtn    Tenant2
