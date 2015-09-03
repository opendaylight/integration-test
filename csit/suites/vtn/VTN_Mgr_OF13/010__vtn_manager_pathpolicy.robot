*** Settings ***
Documentation     Test suite for VTN Manager using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${pathmapdata}    {"index": 1,"condition":"flowcond_path","policy":1,"idleTimeout": 300,"hardTimeout": 0}
${pathpolicydata}    {"id": 1,"default": 100000,"cost": [{"location": {"node": {"type": "OF","id": "00:00:00:00:00:00:00:01"},"port": {"type": "OF","id": "3","name": "s1-eth3"}},"cost": 1000},{"location": {"node": {"type": "OF","id": "00:00:00:00:00:00:00:04"},"port": {"type": "OF","id": "2","name": "s4-eth2"}},"cost": 1000},{"location": {"node": {"type": "OF", "id": "00:00:00:00:00:00:00:03"},"port": {"type": "OF","id": "3","name": "s3-eth3"}},"cost": 100000}]}

*** Test Cases ***

Mininet Execute Custom Topology
    [Documentation]    Mininet Execute Topology For PathPolicy
    Mininet Execute Custom Topology

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
    [Documentation]    Check if openflow:4 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3     1    Fetch vtn switch inventory     openflow:4

Add a vtn Tenant_path
    [Documentation]    Add a vtn Tenant_path
    Add a vtn    Tenant_path    {"idleTimeout": "200","hardTimeout": "600","description": "Virtual Tenant_path for Hackfest network"}

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant_path
    Add a vBridge    Tenant_path    vBridge1    {"ageInterval": "300","description": "vBridge1 for Tenant_path"}

Add a interface If1_path
    [Documentation]    Add a interface if1_path into vBrdige vBridge1
    Add a interface    Tenant_path    vBridge1    if1_path    {}

Add a portmap for interface if1_path
    [Documentation]    Create a portmap on Interface if1 of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:01
    ${port}    Create Dictionary    name=s1-eth1    type=OF    id=1
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant_path    vBridge1    if1_path    ${portmap_data}

Add a interface If2_path
    [Documentation]    Add a interface if2_path into vBrdige vBridge1
    Add a interface    Tenant_path    vBridge1    if2_path   {}

Add a portmap for interface if2_path
    [Documentation]    Create a portmap on Interface if2_path of vBridge1
    ${node}    Create Dictionary    type=OF    id=00:00:00:00:00:00:00:03
    ${port}    Create Dictionary    name=s3-eth3    type=OF    id=3
    ${portmap_data}    Create Dictionary    node=${node}    port=${port}
    Add a portmap    Tenant_path    vBridge1    if2_path    ${portmap_data}

Ping h1 to h2 before path policy
    [Documentation]    Ping h1 to h2, verify no packet loss
    Mininet Ping Should Succeed    h1    h2

Verify flowEntryBeforePathPolicy
    [Documentation]    Checking Flows on switch s1 and s3
    [Tags]    Switch
    Verify flowEntryBeforePathPolicy

Add a flowcondition flowcond_path
    [Documentation]    Create a flowcondition flowcond_path
    ${inet4}=    Create Dictionary    src=10.0.0.1    dst=10.0.0.2    protocol=1
    ${inetMatch}=    Create Dictionary    inet4=${inet4}
    ${ethernet}=    Create Dictionary    src=ca:9e:58:0c:1e:f0    dst=ba:bd:0f:e3:a8:c8    type=2048
    ${matchElement}=    Create Dictionary    index=1    ethernet=${ethernet}    inetMatch=${inetMatch}
    @{matchlist}    Create List    ${matchElement}
    ${flowcond_data}=    Create Dictionary    name=flowcond_path    match=${matchlist}
    Add a flowcondition  flowcond_path    ${flowcond_data}

Add a pathmap
    [Documentation]    Create a pathmap in the vtn
    Add a pathmap    ${pathmapdata}

Get a pathmap
    [Documentation]    Retrieve a pathmap in the vtn
    Get a pathmap

Add a pathpolicy
    [Documentation]    Create a pathpolicy in the vtn
    Add a pathpolicy    ${pathpolicydata}

Get a pathpolicy
    [Documentation]    Retrieve a pathpolicy in the vtn
    Get a pathpolicy

Ping h1 to h2 after path policy
    [Documentation]    Ping h1 to h2, verify no packet loss
    Mininet Ping Should Succeed    h1    h2

Verify flowEntryAfterPathPolicy
    [Documentation]    Checking Flows on switch s1 and s3
    [Tags]    Switch
    Verify flowEntryAfterPathPolicy

Delete a pathmap
    [Documentation]    Delete a pathmap
    Delete a pathmap

Get a pathmap after delete
    [Documentation]    Retrieve a pathmap in the vtn after delete
    Get a pathmap after delete

Delete a pathpolicy
    [Documentation]    Delete a pathpolicy
    Delete a pathpolicy

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Delete a flowcondition    flowcond_path

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant_path




