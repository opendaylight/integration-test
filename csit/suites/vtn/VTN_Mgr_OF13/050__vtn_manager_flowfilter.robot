*** Settings ***
Documentation     Test suite for VTN Manager using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${vtnFlowfilterData}    {"input": {"output": "false", "tenant-name": "Tenant1", "vtn-flow-filter":[{"condition": "cond_1", "index": 11, "vtn-pass-filter": {}, "vtn-flow-action":[{"order": "1","vtn-set-inet-dscp-action":{"dscp":"15"}}]}]}}
${vbrFlowfilterData}     {"input": {"output": "false", "tenant-name": "Tenant1", "bridge-name": "vBridge1", "vtn-flow-filter":[{"condition": "cond_1", "index": 22, "vtn-pass-filter": {}, "vtn-flow-action":[{"order": "1","vtn-set-inet-dscp-action":{"dscp":"16"}}]}]}}
${vbrIfFlowfilterData}   {"input": {"output": "false", "tenant-name": "Tenant1", "bridge-name": "vBridge1", "interface-name": "if1", "vtn-flow-filter":[{"condition": "cond_1", "index": 33, "vtn-pass-filter": {}, "vtn-flow-action":[{"order": "1","vtn-set-inet-dscp-action":{"dscp":"17"}}]}]}}
${macmap_data}    {"machost": [{"address": "0e:d5:e3:40:a3:f0", "vlan": "0"},{"address": "9a:dd:b0:8a:de:2f", "vlan": "0"}]}
${flowfiltervlanpcp}    {"index":7,"condition":"cond1","filterType":{"pass":{}},"actions":[{"inet4src":{"address":"10.0.0.1"}},{"inet4dst":{"address":"10.0.0.3"}},{"icmpcode":{"code":1}},{"vlanpcp":{"priority":3}}]}

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
   # ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if1    openflow:2    s2-eth1

Add a portmap for interface if2
    [Documentation]    Create a portmap on Interface if2 of vBridge1
    Add a portmap    Tenant1    vBridge1    if2    openflow:3    s3-eth1

Ping h1 to h3
    [Documentation]    Ping h1 to h3, verify no packet loss
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Add a vBridge vBridge2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2

Add a interface If3
    [Documentation]    Add a interface if3 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge1    if3

Add a interface if4
    [Documentation]    Add a interface if4 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge1    if4

Add a portmap for interface if3
    [Documentation]    Create a portmap on Interface if3 of vBridge1
    Add a portmap    Tenant1    vBridge1    if3    openflow:2    s2-eth2

Add a portmap for interface if4
    [Documentation]    Create a portmap on Interface if4 of vBridge1
    Add a portmap    Tenant1    vBridge1    if4    openflow:3    s3-eth2

Ping h2 to h4
    [Documentation]    Ping h2 to h4, verify no packet loss
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h2    h4

Add a flowcondition
    [Documentation]    Create a flowcondition cond_1 using restconfig api
    Add a flowcondition    cond_1

Get a flowcondition
    [Documentation]    Create a flowcondition cond_1 using restconfig api
    Get flowconditions

Add vtn flowfilter
    [Documentation]    Create a vtn flowfilter and verify ping
    Add a vtn flowfilter    Tenant1    ${vtnFlowfilterData}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Add a vbrif flowfilter
    [Documentation]    Create a vbrif flowfilter and Verify ping
    Add a vbrif flowfilter    Tenant1    vBridge1    if1    ${vbrIfFlowfilterData}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Add a vbr flowfilter
    [Documentation]    Create a vbr flowfilter and Verify ping
    Add a vbr flowfilter    Tenant1    vBridge1    ${vbrFlowfilterData}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Remove flowcondition    cond_1

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
