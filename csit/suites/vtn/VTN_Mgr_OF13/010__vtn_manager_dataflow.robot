*** Settings ***
Documentation     Test suite for VTN Manager Data Flow using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Test Cases ***
Check if switch1 detected
    [Documentation]    Check if openflow:1 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    12     3    Fetch vtn switch inventory     openflow:1

Check if switch2 detected
    [Documentation]    Check if openflow:2 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:2

Check if switch3 detected
    [Documentation]    Check if openflow:3 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:3

Add a vtn Tenant1
    [Documentation]    Add a vtn Tenant1
    Add a vtn    Tenant1    {"idleTimeout": "200","hardTimeout": "600","description": "Virtual Tenant1 for Hackfest network"}

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1    {"ageInterval": "300","description": "vBridge1 for Tenant1"}

Add a interface If1
    [Documentation]    Add a interface if1 into vBridge vBridge1
    Add a interface    Tenant1    vBridge1    if1    {"enabled": "true","description": "Interface1 for vBridge1 for Tenant1"}

Add a interface if2
    [Documentation]    Add a interface if2 into vBridge vBridge1
    Add a interface    Tenant1    vBridge1    if2    {"enabled": "true","description": "Interface2 for vBridge1 for Tenant1"}

Add a portmap for interface if1
    [Documentation]    Create a portmap on Interface if1 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    name=s2-eth1
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if1    ${portmap_data}

Add a portmap for interface if2
    [Documentation]    Create a portmap on Interface if2 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:03
    ${port}    Create Dictionary    name=s3-eth1
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if2    ${portmap_data}

Ping h1 to h3
    [Documentation]    Ping h1 to h3, verify no packet loss
    Mininet Ping Should Succeed     h1     h3

Verify data flow details For vBridge1
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Verify Data Flows For Bridge1    Tenant1

Add a vBridge vBridge2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2    {}

Add a interface If3
    [Documentation]    Add a interface if3 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge2    if3    {}

Add a interface if4
    [Documentation]    Add a interface if4 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge2    if4    {}

Add a portmap for interface if3
    [Documentation]    Create a portmap on Interface if3 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    name=s2-eth2
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge2    if3    ${portmap_data}

Add a portmap for interface if4
    [Documentation]    Create a portmap on Interface if4 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:03
    ${port}    Create Dictionary    name=s3-eth2
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge2    if4    ${portmap_data}

Ping h2 to h4
    [Documentation]    Ping h2 to h4, verify no packet loss
    Mininet Ping Should Succeed     h2     h4

Verify data flow details for vBridge2
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Verify Data Flows For Bridge2   Tenant1

Verify FlowMacAddress
    [Documentation]    Checking Flows on switch
    [Tags]    Switch
    Verify FlowMacAddress    h2    h4

Remove Portmap for If1
    [Documentation]    Remove portmap for the interface If1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    name=s2-eth1
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Remove a portmap    Tenant1    vBridge1    if1    ${portmap_data}

Verify RemovedFlowMacAddress
    [Documentation]    flows will be deleted after the port map is removed
    Verify RemovedFlowMacAddress    h1    h3

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1

Start topology
    [Documentation]    Add a vlan topology
     Start vlan_topo

Check if switch1 detected for vlan topology
    [Documentation]    Check if openflow:1 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    12     3    Fetch vtn switch inventory     openflow:1

Check if switch2 detected for vlan topology
    [Documentation]    Check if openflow:2 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:2

Check if switch3 detected for vlan topology
    [Documentation]    Check if openflow:3 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:3

Add a vtn Tenant2
    [Documentation]    Add a vtn Tenant2
    Add a vtn    Tenant2    {}

Add a vBridge vBridge1 for Tenant2
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant2
    Add a vBridge    Tenant2    vBridge1    {}

Add a vlanmap for bridge1
    [Documentation]    Add a Vlanmap for bridge1 in vtn Tenant2
    Add a vlanmap    Tenant2    vBridge1    ${vlanmap_bridge1}

Add a vBridge vBridge2 for Tenant2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant2
    Add a vBridge    Tenant2    vBridge2    {}

Add a vlanmap for bridge2
    [Documentation]    Add a Vlanmap for bridge2 in vtn Tenant2
    Add a vlanmap    Tenant2    vBridge2    ${vlanmap_bridge2}

Get vlanflow h1 h3
    [Documentation]    ping h1 to h3
    Wait Until Keyword Succeeds    10s    2s    Mininet Ping Should Succeed    h1    h3

Verify data flow details for vlanmap
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Verify Data Flows For Vlanmap    Tenant2

Get vlanflow h1 h5
    [Documentation]    ping h1 to h5
    Wait Until Keyword Succeeds    10s    2s    Mininet Ping Should Succeed    h1    h5

Verify data flow details for vlanmap
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Verify Data Flows For Vlanmap    Tenant2

Get vlanflow h2 h4
    [Documentation]    ping h2 to h4
    Wait Until Keyword Succeeds    10s    2s    Mininet Ping Should Succeed    h2    h4

Verify data flow details for vlanmap
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Verify Data Flows For Vlanmap    Tenant2

Get vlanflow h2 h6
    [Documentation]    ping h2 to h6
    Wait Until Keyword Succeeds    10s    2s    Mininet Ping Should Succeed    h2    h6

Verify data flow details for vlanmap
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Verify Data Flows For Vlanmap    Tenant2

Get vlanflow h2 h5
   [Documentation]    ping h2 to h5
    Mininet Ping Should Not Succeed    h2    h5

Verify data flow details for vlanmap
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Verify Data Flows For Vlanmap    Tenant2

Delete a vtn Tenant2
    [Documentation]    Delete a vtn Tenant2
    Delete a vtn    Tenant2
