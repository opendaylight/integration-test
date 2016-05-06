*** Settings ***
Library           SSHLibrary
Library           String
Library           DateTime
Library           Collections
Library           json
Library           RequestsLibrary
Variables         ../variables/Variables.py
Resource          ./Utils.robot

*** Variables ***
${vlan_topo_10}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --custom vlan_vtn_test.py --topo vlantopo
${vlan_topo_13}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --custom vlan_vtn_test.py --topo vlantopo --switch ovsk,protocols=OpenFlow13
${REST_CONTEXT_VTNS}    controller/nb/v2/vtn/default/vtns
${REST_CONTEXT}    controller/nb/v2/vtn/default
${VERSION_VTN}    controller/nb/v2/vtn/version
${VTN_INVENTORY}    restconf/operational/vtn-inventory:vtn-nodes
${DUMPFLOWS_OF10}    dpctl dump-flows -O OpenFlow10
${DUMPFLOWS_OF13}    dpctl dump-flows -O OpenFlow13
${index}          7
@{FLOWELMENTS}    nw_src=10.0.0.1    nw_dst=10.0.0.3    actions=drop
@{BRIDGE1_DATAFLOW}    "reason":"PORTMAPPED"    "path":{"tenant":"Tenant1","bridge":"vBridge1","interface":"if2"}
@{BRIDGE2_DATAFLOW}    "reason":"PORTMAPPED"    "path":{"tenant":"Tenant1","bridge":"vBridge2","interface":"if3"}
${vlanmap_bridge1}    {"vlan": "200"}
${vlanmap_bridge2}    {"vlan": "300"}
@{VLANMAP_BRIDGE1_DATAFLOW}    "reason":"VLANMAPPED"    "path":{"tenant":"Tenant1","bridge":"vBridge1_vlan"}
@{VLANMAP_BRIDGE2_DATAFLOW}    "reason":"VLANMAPPED"    "path":{"tenant":"Tenant1","bridge":"vBridge2_vlan"}
${pathpolicy_topo_13}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --custom topo-3sw-2host_multipath.py --topo pathpolicytopo --switch ovsk,protocols=OpenFlow13
${pathpolicy_topo_10}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --custom topo-3sw-2host_multipath.py --topo pathpolicytopo --switch ovsk,protocols=OpenFlow10
@{PATHMAP_ATTR}    "index":"1"    "condition":"flowcond_path"    "policy":"1"
${policy_id}      1
@{PATHPOLICY_ATTR}    "id":"1"    "type":"OF"    "name":"s4-eth2"
${custom}         ${CURDIR}/${CREATE_PATHPOLICY_TOPOLOGY_FILE_PATH}
${in_port}        1
${out_before_pathpolicy}    output:2
${out_after_pathpolicy}    output:3

*** Keywords ***
Start SuiteVtnMa
    [Arguments]    ${version_flag}=none
    [Documentation]    Start VTN Manager Init Test Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    3    Fetch vtn list
    Start Suite
    Run Keyword If    '${version_flag}' == 'OF13'    Set Global Variable    ${OPENFLOW_VERSION}    OF13
    ...    ELSE    Set Global Variable    ${OPENFLOW_VERSION}    OF10

Stop SuiteVtnMa
    [Documentation]    Stop VTN Manager Test Suite
    Delete All Sessions

Start SuiteVtnMaTest
    [Documentation]    Start VTN Manager Test Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}

Stop SuiteVtnMaTest
    [Documentation]    Stop VTN Manager Test Suite
    Delete All Sessions

Add Table Miss Flows
    [Documentation]    Add Flow entried to handle table miss situation
    Write    dpctl add-flow priority=0,actions=output:CONTROLLER -OOpenFlow13
    Read Until    mininet>

Fetch vtn list
    [Documentation]    Check if VTN Manager is up.
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CONTEXT_VTNS}
    Should Be Equal As Strings    ${resp.status_code}    200

Fetch vtn switch inventory
    [Arguments]    ${sw_name}
    [Documentation]    Check if Switch is detected.
    ${resp}=    RequestsLibrary.Get Request    session    ${VTN_INVENTORY}/vtn-inventory:vtn-node/${sw_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vtn
    [Arguments]    ${vtn_name}    ${vtn_data}
    [Documentation]    Create a vtn with specified parameters.
    ${resp}=    RequestsLibrary.Post Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}    data=${vtn_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Delete a vtn
    [Arguments]    ${vtn_name}
    [Documentation]    Create a vtn with specified parameters.
    ${resp}=    RequestsLibrary.Delete Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vBridge
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${vBridge_data}
    [Documentation]    Create a vBridge in a VTN
    ${resp}=    RequestsLibrary.Post Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}    data=${vBridge_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a interface
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${interface_data}
    [Documentation]    Create a interface into a vBridge of a VTN
    ${resp}=    RequestsLibrary.Post Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}    data=${interface_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a portmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${portmap_data}
    [Documentation]    Create a portmap for a interface of a vbridge
    ${json_data}=    json.dumps    ${portmap_data}
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/portmap    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify Data Flows
    [Arguments]    ${vtn_name}    ${vBridge_name}
    [Documentation]    Verify the reason and physical data flows for the specified vtn and vbridge
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/flows/detail
    Run Keyword If    '${vBridge_name}' == 'vBridge1'    DataFlowsForBridge    ${resp}    @{BRIDGE1_DATAFLOW}
    ...    ELSE IF    '${vBridge_name}' == 'vBridge2'    DataFlowsForBridge    ${resp}    @{BRIDGE2_DATAFLOW}
    ...    ELSE IF    '${vBridge_name}' == 'vBridge1_vlan'    DataFlowsForBridge    ${resp}    @{VLANMAP_BRIDGE1_DATAFLOW}
    ...    ELSE    DataFlowsForBridge    ${resp}    @{VLANMAP_BRIDGE2_DATAFLOW}

DataFlowsForBridge
    [Arguments]    ${resp}    @{BRIDGE_DATAFLOW}
    [Documentation]    Verify whether the required attributes exists.
    : FOR    ${dataflowElement}    IN    @{BRIDGE_DATAFLOW}
    \    should Contain    ${resp.content}    ${dataflowElement}

Add a pathmap
    [Arguments]    ${pathmap_data}
    [Documentation]    Create a pathmap for a vtn
    ${json_data}=    json.dumps    ${pathmap_data}
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT}/pathmaps/${policy_id}    data=${pathmap_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get a pathmap
    [Documentation]    Get a pathmap for a vtn.
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CONTEXT}/pathmaps
    : FOR    ${pathElement}    IN    @{PATHMAP_ATTR}
    \    should Contain    ${resp.content}    ${pathElement}

Add a pathpolicy
    [Arguments]    ${pathpolicy_data}
    [Documentation]    Create a pathpolicy for a vtn
    ${json_data}=    json.dumps    ${pathpolicy_data}
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT}/pathpolicies/${policy_id}    data=${pathpolicy_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get a pathpolicy
    [Documentation]    Get a pathpolicy for a vtn.
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CONTEXT}/pathpolicies/${policy_id}
    : FOR    ${pathpolicyElement}    IN    @{PATHPOLICY_ATTR}
    \    should Contain    ${resp.content}    ${pathpolicyElement}

Verify flowEntryPathPolicy
    [Arguments]    ${of_version}    ${port}    ${output}
    [Documentation]    Checking Flows on switch S1 and switch S3 after applying path policy
    ${DUMPFLOWS}=    Set Variable If    "${of_version}"=="OF10"    ${DUMPFLOWS_OF10}    ${DUMPFLOWS_OF13}
    write    ${DUMPFLOWS}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    in_port=${port}    actions=${output}

Start PathSuiteVtnMaTest
    [Documentation]    Start VTN Manager Test Suite and Mininet
    Start SuiteVtnMaTest
    Start Mininet    ${TOOLS_SYSTEM_IP}    ${pathpolicy_topo_13}    ${custom}

Start PathSuiteVtnMaTestOF10
    [Documentation]    Start VTN Manager Test Suite and Mininet in Open Flow 10 Specification
    Start SuiteVtnMaTest
    Start Mininet    ${TOOLS_SYSTEM_IP}    ${pathpolicy_topo_10}    ${custom}

Stop PathSuiteVtnMaTest
    [Documentation]    Cleanup/Shutdown work at the completion of all tests.
    Delete All Sessions
    Stop Mininet    ${mininet_conn_id}

Delete a pathmap
    [Documentation]    Delete a pathmap for a vtn
    ${resp}=    RequestsLibrary.Delete Request    session    ${REST_CONTEXT}/pathmaps/1
    Should Be Equal As Strings    ${resp.status_code}    200

Get a pathmap after delete
    [Documentation]    Get a pathmap for a vtn.
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CONTEXT}/pathmaps
    : FOR    ${pathElement}    IN    @{PATHMAP_ATTR}
    \    should Not Contain    ${resp.content}    ${pathElement}

Delete a pathpolicy
    [Documentation]    Delete a pathpolicy for a vtn
    ${resp}=    RequestsLibrary.Delete Request    session    ${REST_CONTEXT}/pathpolicies/1
    Should Be Equal As Strings    ${resp.status_code}    200

Get a pathpolicy after delete
    [Documentation]    Get a pathpolicy for a vtn after delete.
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CONTEXT}/pathpolicies/${policy_id}
    : FOR    ${pathpolicyElement}    IN    @{PATHPOLICY_ATTR}
    \    should Not Contain    ${resp.content}    ${pathpolicyElement}

Add a macmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${macmap_data}
    [Documentation]    Create a macmap for a vbridge
    ${json_data}=    json.dumps    ${macmap_data}
    ${resp}=    RequestsLibrary.Post Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/macmap/allow    data=${macmap_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get DynamicMacAddress
    [Arguments]    ${h}
    [Documentation]    Get Dynamic mac address of Host
    write    ${h} ifconfig -a | grep HWaddr
    ${source}    Read Until    mininet>
    ${HWaddress}=    Split String    ${source}    ${SPACE}
    ${sourceHWaddr}=    Get from List    ${HWaddress}    ${index}
    ${sourceHWaddress}=    Convert To Lowercase    ${sourceHWaddr}
    Return From Keyword    ${sourceHWaddress}    # Also [Return] would work here.

Add a vBridgeMacMapping
    [Arguments]    ${tenant_name}    ${Bridge_name}    ${bridge_macmap_data}
    [Documentation]    Create a vbridge macmap for a bridge
    ${json_data}=    json.dumps    ${bridge_macmap_data}
    ${resp}=    RequestsLibrary.Post Request    session    ${REST_CONTEXT_VTNS}/${tenant_name}/vbridges/${Bridge_name}/macmap/allow    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Mininet Ping Should Succeed
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Ping hosts to check connectivity
    Write    ${host1} ping -c 1 ${host2}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Mininet Ping Should Not Succeed
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Ping hosts when there is no connectivity and check hosts is unreachable
    Write    ${host1} ping -c 3 ${host2}
    ${result}    Read Until    mininet>
    Should Not Contain    ${result}    64 bytes

Delete a interface
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}
    [Documentation]    Delete a interface with specified parameters.
    ${resp}=    RequestsLibrary.Delete Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Start vlan_topo
    [Arguments]    ${OF}
    [Documentation]    Create custom topology for vlan functionality
    Install Package On Ubuntu System     vlan
    Run Keyword If    '${OF}' == 'OF13'    Start Mininet    ${TOOLS_SYSTEM_IP}    ${vlan_topo_13}    ${CURDIR}/${CREATE_VLAN_TOPOLOGY_FILE_PATH}
    ...    ELSE IF    '${OF}' == 'OF10'    Start Mininet    ${TOOLS_SYSTEM_IP}    ${vlan_topo_10}    ${CURDIR}/${CREATE_VLAN_TOPOLOGY_FILE_PATH}

Add a vlanmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${vlanmap_data}
    [Documentation]    Create a vlanmap
    ${resp}=    RequestsLibrary.Post Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/vlanmaps/    data=${vlanmap_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get flow
    [Arguments]    ${vtn_name}
    [Documentation]    Get data flow.
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/flows/detail
    Should Be Equal As Strings    ${resp.status_code}    200

Remove a portmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${portmap_data}
    [Documentation]    Remove a portmap for a interface of a vbridge
    ${json_data}=    json.dumps    ${portmap_data}
    ${resp}=    RequestsLibrary.Delete Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/portmap    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify FlowMacAddress
    [Arguments]    ${host1}    ${host2}    ${OF_VERSION}
    [Documentation]    Verify the source and destination mac address.
    Run Keyword If    '${OF_VERSION}' == 'OF10'    Verify Flows On OpenFlow    ${host1}    ${host2}    ${DUMPFLOWS_OF10}
    ...    ELSE    VerifyFlowsOnOpenFlow    ${host1}    ${host2}    ${DUMPFLOWS_OF13}

Verify Flows On OpenFlow
    [Arguments]    ${host1}    ${host2}    ${DUMPFLOWS}
    [Documentation]    Verify the mac addresses on the specified open flow.
    ${booleanValue}=    Run Keyword And Return Status    Verify macaddress    ${host1}    ${host2}    ${DUMPFLOWS}
    Should Be Equal As Strings    ${booleanValue}    True

Verify RemovedFlowMacAddress
    [Arguments]    ${host1}    ${host2}    ${OF_VERSION}
    [Documentation]    Verify the removed source and destination mac address.
    Run Keyword If    '${OF_VERSION}' == 'OF10'    Verify Removed Flows On OpenFlow    ${host1}    ${host2}    ${DUMPFLOWS_OF10}
    ...    ELSE    VerifyRemovedFlowsOnOpenFlow    ${host1}    ${host2}    ${DUMPFLOWS_OF13}

Verify Removed Flows On OpenFlow
    [Arguments]    ${host1}    ${host2}    ${DUMPFLOWS}
    [Documentation]    Verify the removed mac addresses on the specified open flow.
    ${booleanValue}=    Run Keyword And Return Status    Verify macaddress    ${host1}    ${host2}    ${DUMPFLOWS}
    Should Not Be Equal As Strings    ${booleanValue}    True

Verify macaddress
    [Arguments]    ${host1}    ${host2}    ${DUMPFLOWS}
    [Documentation]    Verify the source and destination mac address after ping in the dumpflows
    write    ${host1} ifconfig -a | grep HWaddr
    ${sourcemacaddr}    Read Until    mininet>
    ${macaddress}=    Split String    ${sourcemacaddr}    ${SPACE}
    ${sourcemacaddr}=    Get from List    ${macaddress}    ${index}
    ${sourcemacaddress}=    Convert To Lowercase    ${sourcemacaddr}
    write    ${host2} ifconfig -a | grep HWaddr
    ${destmacaddr}    Read Until    mininet>
    ${macaddress}=    Split String    ${destmacaddr}    ${SPACE}
    ${destmacaddr}=    Get from List    ${macaddress}    ${index}
    ${destmacaddress}=    Convert To Lowercase    ${destmacaddr}
    write    ${DUMPFLOWS}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    ${sourcemacaddress}
    Should Contain    ${result}    ${destmacaddress}

Add a flowcondition
    [Arguments]    ${cond_name}    ${flowcond_data}
    [Documentation]    Create a flowcondition for a interface of a vbridge
    ${json_data}=    json.dumps    ${flowcond_data}
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT}/flowconditions/${cond_name}    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Delete a flowcondition
    [Arguments]    ${cond_name}
    [Documentation]    Delete a flowcondition for a interface of a vbridge
    ${resp}=    RequestsLibrary.Delete Request    session    ${REST_CONTEXT}/flowconditions/${cond_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a flowfilter
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a flowfilter_vtn
    [Arguments]    ${vtn_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/flowfilters/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a flowfilter_vbr
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vbr
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Update a flowfilter
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a flowfilter for drop
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put Request    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify Flow Entry for Inet Flowfilter
    [Documentation]    Verify switch flow entry using flowfilter for a vtn
    ${booleanValue}=    Run Keyword And Return Status    Verify Actions on Flow Entry
    Should Not Be Equal As Strings    ${booleanValue}    True

Verify Removed Flow Entry for Inet Drop Flowfilter
    [Documentation]    Verify removed switch flow entry using flowfilter drop for a vtn
    ${booleanValue}=    Run Keyword And Return Status    Verify Actions on Flow Entry
    Should Be Equal As Strings    ${booleanValue}    True

Verify Actions on Flow Entry
    write    ${DUMPFLOWS_OF13}
    ${result}    Read Until    mininet>
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    should Contain    ${result}    ${flowElement}
