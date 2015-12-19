*** Settings ***
Documentation     Test suite for VTN Manager Data Flow using OF10
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Test Cases ***
Check if switch1 detected
    [Documentation]    Check if openflow:1 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    12    3    Fetch vtn switch inventory    openflow:1

Check if switch2 detected
    [Documentation]    Check if openflow:2 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:2

Check if switch3 detected
    [Documentation]    Check if openflow:3 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:3

Add a vtn Tenant1
    [Documentation]    Add a vtn Tenant1
    Add a vtn    Tenant1

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1

Add a interface If1
    [Documentation]    Add a interface if1 into vBridge vBridge1
    Add a interface    Tenant1    vBridge1    if1

Add a interface if2
    [Documentation]    Add a interface if2 into vBridge vBridge1
    Add a interface    Tenant1    vBridge1    if2

Add a portmap for interface if1
    [Documentation]    Create a portmap on Interface if1 of vBridge1
    Add a portmap    Tenant1    vBridge1    if1    openflow:2    s2-eth1

Add a portmap for interface if2
    [Documentation]    Create a portmap on Interface if2 of vBridge1
    Add a portmap    Tenant1    vBridge1    if2    openflow:3    s3-eth1

Ping h1 to h3
    [Documentation]    Ping h1 to h3, verify no packet loss
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Verify data flow details For vBridge1
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Wait Until Keyword Succeeds    20s    1s    Verify Data Flows    Tenant1    vBridge1

Add a vBridge vBridge2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2

Add a interface If3
    [Documentation]    Add a interface if3 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge2    if3

Add a interface if4
    [Documentation]    Add a interface if4 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge2    if4

Add a portmap for interface if3
    [Documentation]    Create a portmap on Interface if3 of vBridge1
    Add a portmap    Tenant1    vBridge2    if3    openflow:2    s2-eth2

Add a portmap for interface if4
    [Documentation]    Create a portmap on Interface if4 of vBridge1
    Add a portmap    Tenant1    vBridge2    if4    openflow:3    s3-eth2

Ping h2 to h4
    [Documentation]    Ping h2 to h4, verify no packet loss
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping Should Succeed    h2    h4

Verify data flow details for vBridge2
    [Documentation]    Verify the data flows for the specified tenant and bridge
    Verify Data Flows    Tenant1    vBridge2

Verify FlowMacAddress
    [Documentation]    Checking Flows on switch
    Wait Until Keyword Succeeds    20s    1s    Verify FlowMacAddress    h2    h4    OF10

Remove Portmap for If1
    [Documentation]    Remove portmap for the interface If1
    Remove a portmap    Tenant1    vBridge1    if1

Verify RemovedFlowMacAddress
    [Documentation]    flows will be deleted after the port map is removed
    Verify RemovedFlowMacAddress    h1    h3    OF10

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
