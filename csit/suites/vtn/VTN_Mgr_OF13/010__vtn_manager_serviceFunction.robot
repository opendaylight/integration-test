*** Settings ***
Documentation     Test suite for VTN Manager using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${static_edge_ports}    {"static-edge-ports": {"static-edge-port": [ {"port": "openflow:3:3"}, {"port": "openflow:3:4"}, {"port": "openflow:4:3"}, {"port": "openflow:4:4"}]}}

*** Test Cases ***
Start SuiteVtnMaSCFTest
    [Documentation]    Start SuiteVtnMaSCFTest
    Start SuiteVtnMaSCFTest

Mininet Execute Scf Topology
    [Documentation]    Mininet Execute Scf Topology
    Mininet Execute Scf Topology

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
    [Documentation]    Check if openflow:3 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:4

Configure service nodes
    [Documentation]    Configure service nodes for the created topology
    Configure service nodes

Add a Static Edge Ports
    [Documentation]    Create a Static edge ports for openflow 3:3, 3:4, 4:3, 4:4.
    Add a StaticEdgePort    ${static_edge_ports}

Add a vtn Tenant1
    [Documentation]    Add a vtn Tenant1
    Add a vtn    Tenant1    {"idleTimeout": "200","hardTimeout": "600","description": "Virtual Tenant1 for Hackfest network"}

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1    {"ageInterval": "300","description": "vBridge1 for Tenant1"}

Add a interface If1
    [Documentation]    Add a interface if1 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge1    if1    {}

Add a portmap for interface if1
    [Documentation]    Create a portmap on Interface if1 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:01
    ${port}    Create Dictionary    name=s1-eth2
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if1    ${portmap_data}

Add a interface If2
    [Documentation]    Add a interface if2 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge1    if2    {}

Add a portmap for interface if2
    [Documentation]    Create a portmap on Interface if2 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    name=s2-eth2
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if2    ${portmap_data}

Add a interface If3
    [Documentation]    Add a interface if3 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge1    if3    {}

Add a portmap for interface if3
    [Documentation]    Create a portmap on Interface if3 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    name=s2-eth3
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if3    ${portmap_data}

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
    Add a flowfilter for drop    Tenant1    vBridge1    if1    ${flowfilterdropdata}    ${index}
    Mininet Ping Should Not Succeed    h12    h22

Add a vTerminal vTerminal1
    [Documentation]    Add a vTerminal vTerminal1 in vtn Tenant1
    Add a vTerminal    Tenant1    vTerminal1    {"description": "vTerminal1 for Tenant1"}

Add a interface If4
    [Documentation]    Add a interface if4 into vTerminal vTerminal1
    Add a interface to terminal   Tenant1    vTerminal1    if4    {"enabled": "true","description": "Interface4 for vTerminal1 for Tenant1"}

Add a portmap for interface if4
    [Documentation]    Create a portmap on Interface if4 of vTerminal1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:03
    ${port}    Create Dictionary    name=s3-eth3
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap to terminal intf    Tenant1    vTerminal1    if4    ${portmap_data}

Add a vTerminal vTerminal2
    [Documentation]    Add a vTerminal vTerminal2 in vtn Tenant1
    Add a vTerminal    Tenant1    vTerminal2    {"description": "vTerminal2 for Tenant1"}

Add a interface If5
    [Documentation]    Add a interface if5 into vTerminal vTerminal2
    Add a interface to terminal   Tenant1    vTerminal2    if5    {"enabled": "true","description": "Interface5 for vTerminal2 for Tenant1"}

Add a portmap for interface if5
    [Documentation]    Create a portmap on Interface if5 of vTerminal2
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:04
    ${port}    Create Dictionary    name=s4-eth3
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap to terminal intf    Tenant1    vTerminal2    if5    ${portmap_data}

Add a flowcondition cond_Any
    [Documentation]    Create a flowcondition cond_Any
    ${matchElement}=    Create Dictionary    index=1
    @{matchlist}    Create List    ${matchElement}
    ${flowcond_data}=    Create Dictionary    name=cond_Any    match=${matchlist}
    Add a flowcondition  cond_Any    ${flowcond_data}

Add a flowfilter for redirect any
    [Documentation]    Create a flowfilter for redirect
    Add a flowfilter terminal redirect   Tenant1    vTerminal2    if5    ${flowfilterRedirectAnydata}    ${index}

Add a flowfilter for redirect
    [Documentation]    Create a flowfilter for redirect
    Update a flowfilter    Tenant1    vBridge1    if1    ${flowfilterRedirectdata}    ${index}

Ping h12 to h22
    [Documentation]    Ping h12 to h22, verify no packet loss
    Mininet Ping Should Succeed     h12     h22

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Delete a flowcondition    cond_1

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Delete a flowcondition    cond_Any

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
