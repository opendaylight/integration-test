*** Settings ***
Documentation     Test suite for VTN Manager using OF10
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${flowconditiondata}    "vtn-flow-match":[{"vtn-inet-match":{"source-network":"10.0.0.1/32","destination-network":"10.0.0.5/32"},"index":"1"}]
${flowfiltervlanpcp}    "vtn-flow-filter":[{"condition":"cond_1","vtn-pass-filter":{},"vtn-flow-action":[{"order":"1","vtn-set-vlan-pcp-action":{"vlan-pcp":"6"}}],"index":"1"}]

*** Test Cases ***
Start topology
    [Documentation]    Add a vlan topology
    Start vlan_topo    OF10

Check if switch1 detected
    [Documentation]    Check if openflow:1 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    12    3    Fetch vtn switch inventory    openflow:1

Check if switch2 detected
    [Documentation]    Check if openflow:2 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:2

Check if switch3 detected
    [Documentation]    Check if openflow:3 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:3

Add a Topology Wait
    [Documentation]    Add a topology wait to wait for a completion of inter-switch link
    Add a Topology wait    1000

Add a vtn Tenant1
    [Documentation]    Add a vtn Tenant1
    Add a vtn    Tenant1

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1

Add a interface if1
    [Documentation]    Add a interface if1 into vBridge vBridge1
    Add a interface    Tenant1    vBridge1    if1

Add a interface if2
    [Documentation]    Add a interface if2 into vBridge vBridge1
    Add a interface    Tenant1    vBridge1    if2

Add a portmap with vlan-id for interface if1
    [Documentation]    Create a vlan portmap on Interface if1 of vBridge1
    Add a vlan portmap    Tenant1    vBridge1    if1    200    openflow:2    s2-eth2

Add a portmap with vlan-id for interface if2
    [Documentation]    Create a vlan portmap on Interface if2 of vBridge1
    Add a vlan portmap    Tenant1    vBridge1    if2    200    openflow:3    s3-eth3

Add a flowcondition
    [Documentation]    Create a flowcondition cond_1 using restconfig api
    Add a flowcondition    cond_1    ${flowconditiondata}

Add a vbrif flowfilter with vlanpcp
    [Documentation]    Create a flowfilter with vlanpcp and Verify ping
    [Tags]    exclude
    Add a vbrif flowfilter    Tenant1    vBridge1    if1    ${flowfiltervlanpcp}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h5

Verify vlanpcp of vbrif flowfilter
    [Documentation]    Verify actions in Flow Enties for vlanpcp
    [Tags]    exclude
    Wait_Until_Keyword_Succeeds    20s    1s    Verify Flow Entries for Flowfilter    ${FF_DUMPFLOWS_OF10}    ${vlanpcp_action}

Remove vbrif Flowfilter index
    [Documentation]    Remove a index of vbrif flowfilter
    Remove a vbrif flowfilter    Tenant1    vBridge1    if1    ${filter_index}

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Remove flowcondition    cond_1

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
