*** Settings ***
Documentation     Test suite for VTN Manager Data Flows using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Test Cases ***
Start topology
    [Documentation]    Add a vlan topology
     Start vlan_topo

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
    Add a vtn    Tenant1    {}

Add a vBridge vBridge1_vlan
    [Documentation]    Add a vBridge vBridge1_vlan in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1_vlan    {}

Add a vlanmap for vBridge1_vlan
    [Documentation]    Add a Vlanmap for vBridge1_vlan in vtn Tenant1
    Add a vlanmap    Tenant1    vBridge1_vlan    ${vlanmap_bridge1}

Add a vBridge vBridge2_vlan
    [Documentation]    Add a vBridge vBridge2_vlan in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2_vlan    {}

Add a vlanmap for vBridge2_vlan
    [Documentation]    Add a Vlanmap for vBridge2_vlan in vtn Tenant1
    Add a vlanmap    Tenant1    vBridge2_vlan    ${vlanmap_bridge2}

Get vlanflow h1 h3
    [Documentation]    ping h1 to h3
    Wait Until Keyword Succeeds    10s    2s    Mininet Ping Should Succeed    h1    h3

Get vlanflow h1 h5
    [Documentation]    ping h1 to h5
    Wait Until Keyword Succeeds    10s    2s    Mininet Ping Should Succeed    h1    h5

Verify data flow details for vlanmap vBridge1_vlan
    [Documentation]    Verify the data flows for the specified tenant and vBridge1_vlan
    Verify Data Flows    Tenant1    vBridge1_vlan

Get vlanflow h2 h4
    [Documentation]    ping h2 to h4
    Wait Until Keyword Succeeds    10s    2s    Mininet Ping Should Succeed    h2    h4

Get vlanflow h2 h6
    [Documentation]    ping h2 to h6
    Wait Until Keyword Succeeds    10s    2s    Mininet Ping Should Succeed    h2    h6

Verify data flow details for vlanmap vBridge2_vlan
    [Documentation]    Verify the data flows for the specified tenant and vBridge2_vlan
    Verify Data Flows    Tenant1    vBridge2_vlan

Get vlanflow h2 h5
   [Documentation]    ping h2 to h5
    Mininet Ping Should Not Succeed    h2    h5

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
