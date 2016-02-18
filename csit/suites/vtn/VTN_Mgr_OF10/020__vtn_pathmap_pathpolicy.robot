*** Settings ***
Documentation     Test suite for VTN Manager PathPolicy using OF10
Suite Setup       Start PathSuiteVtnMaTestOF10
Suite Teardown    Stop PathSuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${flowconditiondata}    "vtn-flow-match":[{"vtn-ether-match":{"destination-address":"ba:bd:0f:e3:a8:c8","ether-type":"2048","source-address":"ca:9e:58:0c:1e:f0","vlan-id": "1"},"vtn-inet-match":{"source-network":"10.0.0.1/32","protocol":1,"destination-network":"10.0.0.2/32"},"index":"1"}]
${pathmapdata}    {"input":{"tenant-name":"Tenant_path","path-map-list":[{"condition":"flowcond_path","policy":"1","index": "1","idle-timeout":"300","hard-timeout":"0"}]}}
${pathpolicydata}    {"input":{"operation":"SET","id": "1","default-cost": "10000","vtn-path-cost": [{"port-desc":"openflow:1,3,s1-eth3","cost":"1000"},{"port-desc":"openflow:4,2,s4-eth2","cost":"1000"},{"port-desc":"openflow:3,3,s3-eth3","cost":"100000"}]}}

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

Check if switch4 detected
    [Documentation]    Check if openflow:4 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:4

Add a vtn Tenant_path
    [Documentation]    Add a vtn Tenant_path
    Add a vtn    Tenant_path

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant_path
    Add a vBridge    Tenant_path    vBridge1

Add a interface If1_path
    [Documentation]    Add a interface if1_path into vBrdige vBridge1
    Add a interface    Tenant_path    vBridge1    if1_path

Add a portmap for interface if1_path
    [Documentation]    Create a portmap on Interface if1 of vBridge1
    Add a portmap    Tenant_path    vBridge1    if1_path    openflow:1    s1-eth1

Add a interface If2_path
    [Documentation]    Add a interface if2_path into vBrdige vBridge1
    Add a interface    Tenant_path    vBridge1    if2_path

Add a portmap for interface if2_path
    [Documentation]    Create a portmap on Interface if2_path of vBridge1
    Add a portmap    Tenant_path    vBridge1    if2_path    openflow:3    s3-eth3

Ping h1 to h2 before path policy
    [Documentation]    Ping h1 to h2, verify no packet loss
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h2

Verify flowEntryBeforePathPolicy
    [Documentation]    Checking Flows on switch s1 and s3
    [Tags]    exclude
    Verify flowEntryPathPolicy    OF10    ${in_port}    ${out_before_pathpolicy}

Add a flowcondition flowcond_path
    [Documentation]    Create a flowcondition flowcond_path
    Add a flowcondition    flowcond_path    ${flowconditiondata}

Add a pathmap
    [Documentation]    Create a pathmap in the vtn
    Add a pathmap    ${pathmapdata}

Add a pathpolicy
    [Documentation]    Create a pathpolicy in the vtn
    Add a pathpolicy    ${pathpolicydata}

Get a pathpolicy
    [Documentation]    Retrieve a pathpolicy in the vtn
    Get a pathpolicy    ${policy_id}

Ping h1 to h2 after path policy
    [Documentation]    Ping h1 to h2, verify no packet loss
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h2

Verify flowEntryAfterPathPolicy
    [Documentation]    Checking Flows on switch s1 and s3
    [Tags]    exclude
    Verify flowEntryPathPolicy    OF10    ${in_port}    ${out_after_pathpolicy}

Delete a pathmap
    [Documentation]    Delete a pathmap
    Delete a pathmap    Tenant_path

Delete a pathpolicy
    [Documentation]    Delete a pathpolicy
    Delete a pathpolicy    ${policy_id}

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Remove flowcondition    flowcond_path

Delete a vtn Tenant_path
    [Documentation]    Delete a vtn Tenant_path
    Delete a vtn    Tenant_path
