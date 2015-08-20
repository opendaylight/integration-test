*** Settings ***
Documentation     Test suite for VTN Manager using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${flowfilterInetdata}    {"index":1,"condition":"cond1","filterType":{"pass":{}},"actions":[{"inet4src":{"address":"10.0.0.1"}},{"inet4dst":{"address":"10.0.0.3"}}]}
${flowfilterInetdropdata}    {"index":1,"condition":"cond1","filterType":{"drop":{}},"actions":[{"inet4src":{"address":"10.0.0.1"}},{"inet4dst":{"address":"10.0.0.3"}}]}
${flowfilterIcmpCodedata}    {"index":2,"condition":"cond1","filterType":{"pass":{}},"actions":[{"icmpcode":{"code":9}}]}
${flowfilterTpsrcTpdstdata}    {"index":3,"condition":"cond1","filterType":{"pass":{}},"actions":[{"tpsrc":{"port":"5"}},{"tpdst":{"port":"10"}}]}
${flowfilterDscpdata}    {"index":6,"condition":"cond1","filterType":{"pass":{}},"actions":[{"dscp": {"dscp": 10}}]}
${macmap_data}    {"machost": [{"address": "0e:d5:e3:40:a3:f0", "vlan": "0"},{"address": "9a:dd:b0:8a:de:2f", "vlan": "0"}]}
${flowfiltervlanpcp}    {"index":7,"condition":"cond1","filterType":{"pass":{}},"actions":[{"inet4src":{"address":"10.0.0.1"}},{"inet4dst":{"address":"10.0.0.3"}},{"icmpcode":{"code":1}},{"vlanpcp":{"priority":3}}]}
${vtn_flowfilterInetdata}    {"index":8,"condition":"cond1","filterType":{"pass":{}},"actions":[{"inet4src":{"address":"10.0.0.1"}},{"inet4dst":{"address":"10.0.0.3"}}]}
${vbr_flowfilterInetdata}    {"index":9,"condition":"cond1","filterType":{"pass":{}},"actions":[{"inet4src":{"address":"10.0.0.1"}},{"inet4dst":{"address":"10.0.0.3"}}]}

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

Add a vBridge vBridge2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2    {}

Add a interface If3
    [Documentation]    Add a interface if3 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge1    if3    {}

Add a interface if4
    [Documentation]    Add a interface if4 into vBrdige vBridge1
    Add a interface    Tenant1    vBridge1    if4    {}

Add a portmap for interface if3
    [Documentation]    Create a portmap on Interface if3 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    name=s2-eth2
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if3    ${portmap_data}

Add a portmap for interface if4
    [Documentation]    Create a portmap on Interface if4 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:03
    ${port}    Create Dictionary    name=s3-eth2
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant1    vBridge1    if4    ${portmap_data}

Ping h2 to h4
    [Documentation]    Ping h2 to h4, verify no packet loss
    Mininet Ping Should Succeed     h2     h4

Add a macmap
    [Documentation]    Create a macmap on vBridge vBridge1
    Add a macmap     Tenant1    vBridge1    ${macmap_data}

Get flow
    [Documentation]    Get flow of a vtn Tenant1
    Get flow    Tenant1

Add a flowcondition cond1
    [Documentation]    Create a flowcondition cond1
    ${inet4}=    Create Dictionary    src=10.0.0.1    dst=10.0.0.3
    ${inetMatch}=    Create Dictionary    inet4=${inet4}
    ${matchElement}=    Create Dictionary    index=1    inetMatch=${inetMatch}
    @{matchlist}    Create List    ${matchElement}
    ${flowcond_data}=    Create Dictionary    name=cond1    match=${matchlist}
    Add a flowcondition  cond1    ${flowcond_data}

Add a flowfilter with inet4src and inet4dst
    [Documentation]    Create a flowfilter with inet4 and Verify ping
    Add a flowfilter    Tenant1    vBridge1    if1    ${flowfilterInetdata}    ${index}
    Mininet Ping Should Succeed    h1    h3

Add a flowfilter with Icmp code
    [Documentation]    Create a flowfilter with icmp code and Verify ping
    Update a flowfilter    Tenant1    vBridge1    if1    ${flowfilterIcmpCodedata}    ${index}
    Mininet Ping Should Succeed    h1    h3

Add a flowfilter with tpsrc and tpdst
    [Documentation]    Create a flowfilter with tpsrc and tpdst and Verify ping
    Update a flowfilter    Tenant1    vBridge1    if1    ${flowfilterTpsrcTpdstdata}    ${index}
    Mininet Ping Should Succeed    h1    h3

Add a flowfilter with dscp
    [Documentation]    Create a flowfilter with dscp and Verify ping
    Update a flowfilter    Tenant1    vBridge1    if1    ${flowfilterDscpdata}    ${index}
    Mininet Ping Should Succeed    h1    h3

Verify Flow Entry for Inet Flowfilter
    [Documentation]    Verify Flow Entry for Inet Flowfilter
    Verify Flow Entry for Inet Flowfilter

Add a flowfilter with vlanpcp
    [Documentation]    Create a flowfilter with vlanpcp and Verify ping
    Update a flowfilter    Tenant1    vBridge1    if1    ${flowfiltervlanpcp}    ${index}
    Mininet Ping Should Succeed    h1    h3

Add a flowfilter_vtn with inet4src and inet4dst
    [Documentation]    Create a vtn_flowfilter with inet4 and Verify ping
    Add a flowfilter_vtn    Tenant1    ${vtn_flowfilterInetdata}    ${index}
    Mininet Ping Should Succeed    h1    h3

Add a flowfilter_vbr with inet4src and inet4dst
    [Documentation]    Create a vbr_flowfilter with inet4 and Verify ping
    Add a flowfilter_vbr    Tenant1    vBridge1    ${vbr_flowfilterInetdata}    ${index}
    Mininet Ping Should Succeed    h1    h3

Add a flowfilter with inet4 for drop
    [Documentation]    Create a flowfilter with inet4 for drop action and Verify no pinging
    Add a flowfilter for drop    Tenant1    vBridge1    if1    ${flowfilterInetdropdata}    ${index}
    Mininet Ping Should Not Succeed    h1    h3

Verify Removed Flow Entry For Inet After Drop Action
    [Documentation]    Verify no flows between the hosts after drop
    Verify Removed Flow Entry for Inet Drop Flowfilter

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Delete a flowcondition    cond1

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
