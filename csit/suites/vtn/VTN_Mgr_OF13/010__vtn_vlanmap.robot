*** Settings ***
Documentation     Test suite for VTN Manager using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${flowconditiondata}    "vtn-flow-match":[{"vtn-inet-match":{"source-network":"10.0.0.1/32","destination-network":"10.0.0.5/32"},"index":"1"}]
${flowfiltervlanpcp}    "vtn-flow-filter":[{"condition":"cond_1","vtn-pass-filter":{},"vtn-flow-action":[{"order":"1","vtn-set-vlan-pcp-action":{"vlan-pcp":"6"}}],"index":"1"}]

*** Test Cases ***
Start topology
    [Documentation]    Add a vlan topology
    Start vlan_topo    OF13

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

Add a vlanmap for bridge1
    [Documentation]    Add a Vlanmap for bridge1 in vtn Tenant1
    Add a vlanmap    Tenant1    vBridge1    ${vlanmap_bridge1}

Add a vBridge vBridge2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2

Add a vlanmap for bridge2
    [Documentation]    Add a Vlanmap for bridge1 in vtn Tenant1
    Add a vlanmap    Tenant1    vBridge2    ${vlanmap_bridge2}

Get vlanflow h1 h5
    [Documentation]    ping h1 to h5
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h5

Get vlanflow h3 h5
    [Documentation]    ping h3 to h5
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping Should Succeed    h3    h5

Get vlanflow h2 h4
    [Documentation]    ping h2 to h4
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping Should Succeed    h2    h4

Get vlanflow h2 h6
    [Documentation]    ping h2 to h6
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping Should Succeed    h2    h6

Get vlanflow h1 h4
    [Documentation]    ping h1 to h4
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping Should Not Succeed    h1    h4

Add a flowcondition
    [Documentation]    Create a flowcondition cond_1 using restconfig api
    Add a flowcondition    cond_1    ${flowconditiondata}

Add a vtn flowfilter with vlanpcp
    [Documentation]    Create a flowfilter with vlanpcp and Verify ping
    Add a vtn flowfilter    Tenant1    ${flowfiltervlanpcp}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h5

Verify vlanpcp of vtn flowfilter
    [Documentation]    Verify vtn flowfilter actions in Flow Enties for vlanpcp
    Wait_Until_Keyword_Succeeds    20s    1s    Verify Flow Entries for Flowfilter    ${FF_DUMPFLOWS_OF13}    ${vlanpcp_actions}

Remove vtn Flowfilter index
    [Documentation]    Remove a index of vtn flowfilter
    Remove a vtn flowfilter    Tenant1    ${filter_index}

Add a vbr flowfilter with vlanpcp
    [Documentation]    Create a flowfilter with vlanpcp and Verify ping
    Add a vbr flowfilter    Tenant1    vBridge1    ${flowfiltervlanpcp}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h5

Verify vlanpcp of vbr flowfilter
    [Documentation]    Verify actions in Flow Enties for vlanpcp
    Wait_Until_Keyword_Succeeds    20s    1s    Verify Flow Entries for Flowfilter    ${FF_DUMPFLOWS_OF13}    ${vlanpcp_actions}

Remove vbr Flowfilter index
    [Documentation]    Remove a index of vbr flowfilter
    Remove a vbr flowfilter    Tenant1    vBridge1    ${filter_index}

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
