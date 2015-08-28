*** Settings ***
Documentation     Test suite for VTN Manager
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
    Add a vtn    Tenant1    {"description": "Virtual Tenant 1 for Hackfest network"}

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1    {}

Add a interface If1
    [Documentation]    Add a interface if1 into vBridge vBrdige1
    Add a interface    Tenant1    vBridge1    if1    {}

Add a interface if2
    [Documentation]    Add a interface if2 into vBridge vBrdige1
    Add a interface    Tenant1    vBridge1    if2    {}

Add a portmap for interface if1
    [Documentation]    Create a portmap on Interface if1 of vBridge1
    ${node}=    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}=    Create Dictionary    name=s2-eth1
    ${portmap_data}=    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if1    ${portmap_data}

Add a portmap for interface if2
    [Documentation]    Create a portmap on Interface if2 of vBridge1
    ${node}=    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:03
    ${port}=    Create Dictionary    name=s3-eth1
    ${portmap_data}=    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if2    ${portmap_data}

Add a vBridge vBridge2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2    {}

Add a interface If3
    [Documentation]    Add a interface if3 into vBridge vBrdige2
    Add a interface    Tenant1    vBridge2    if3    {}

Add a interface if4
    [Documentation]    Add a interface if4 into vBridge vBrdige2
    Add a interface    Tenant1    vBridge2    if4    {}

Add a portmap for interface if3
    [Documentation]    Create a portmap on Interface if3 of vBridge2
    ${node}=    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}=    Create Dictionary    name=s2-eth2
    ${portmap_data}=    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge2    if3    ${portmap_data}

Add a portmap for interface if4
    [Documentation]    Create a portmap on Interface if4 of vBridge2
    ${node}=    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:03
    ${port}=    Create Dictionary    name=s3-eth2
    ${portmap_data}=    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge2    if4    ${portmap_data}

Ping h1 to h3
    [Documentation]    Ping h1 to h3, verify no packet loss
    Mininet Ping Should Succeed     h1    h3

Ping h2 to h4
    [Documentation]    Ping h2 to h4, verify no packet loss
    Mininet Ping Should Succeed     h2    h4

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
