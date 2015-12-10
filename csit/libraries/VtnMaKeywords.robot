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
${vlan_topo_10}    sudo mn --controller=remote,ip=${CONTROLLER} --custom vlan_vtn_test.py --topo vlantopo
${vlan_topo_13}    sudo mn --controller=remote,ip=${CONTROLLER} --custom vlan_vtn_test.py --topo vlantopo --switch ovsk,protocols=OpenFlow13
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
${in_port}        1
${out_before_pathpolicy}    output:2
${out_after_pathpolicy}    output:3
${flowcond_restconfigdata}    {"input":{"operation":"SET","present":"false","name":"cond_1","vtn-flow-match":[{"vtn-ether-match":{"destination-address":"ba:bd:0f:e3:a8:c8","ether-type":"2048","source-address":"ca:9e:58:0c:1e:f0","vlan-id": "1"},"vtn-inet-match":{"source-network":"10.0.0.1/32","protocol":1,"destination-network":"10.0.0.2/32"},"index":"1"}]}}

*** Keywords ***

Start SuiteVtnMa
    [Documentation]    Start VTN Manager Rest Config Api Test Suite
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    3    Fetch vtn list
    Start Suite

Start SuiteVtnMaTest
    [Documentation]    Start VTN Manager Test Suite
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Stop SuiteVtnMa
    [Documentation]    Stop VTN Manager Test Suite
    Delete All Sessions
    Stop Suite

Stop SuiteVtnMaTest
    [Documentation]    Stop VTN Manager Test Suite
    Delete All Sessions

Fetch vtn list
    [Documentation]    Check if VTN Manager is up.
    ${resp}=    RequestsLibrary.Get    session    restconf/operational/vtn:vtns
    Should Be Equal As Strings    ${resp.status_code}    200

Fetch vtn switch inventory
    [Arguments]    ${sw_name}
    [Documentation]    Check if Switch is detected.
    ${resp}=    RequestsLibrary.Get    session    restconf/operational/vtn-inventory:vtn-nodes/vtn-node/${sw_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a Vtn
    [Arguments]    ${vtn_name}
    [Documentation]    Create a vtn with specified parameters.
    ${resp}=    RequestsLibrary.Post    session    restconf/operations/vtn:update-vtn   data={"input": {"tenant-name":${vtn_name}, "update-mode": "CREATE","operation": "SET", "description": "creating vtn", "idle-timeout":300, "hard-timeout":0}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vBridge
    [Arguments]    ${vtn_name}    ${vbr_name}
    [Documentation]    Create a vBridge in a VTN
    ${resp}=    RequestsLibrary.Post    session    restconf/operations/vtn-vbridge:update-vbridge    data={"input": {"update-mode": "CREATE","operation":"SET", "tenant-name":${vtn_name}, "bridge-name":${vbr_name}, "description": "vbrdige created"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a interface
    [Arguments]    ${vtn_name}    ${vbr_name}    ${interface_name}
    [Documentation]    Create a interface into a vBridge of a VTN
    ${resp}=    RequestsLibrary.Post    session       restconf/operations/vtn-vinterface:update-vinterface    data={"input": {"update-mode":"CREATE","operation":"SET", "tenant-name":${vtn_name}, "bridge-name":${vbr_name}, "description": "vbrdige interfacecreated", "enabled":"true", "interface-name": ${interface_name}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a portmap
    [Arguments]    ${vtn_name}    ${vbr_name}    ${interface_name}   ${node_id}   ${port_id}
    [Documentation]    Create a portmap for a interface of a vbridge
    ${resp}=    RequestsLibrary.POST    session    restconf/operations/vtn-port-map:set-port-map     data={"input": { "tenant-name":${vtn_name}, "bridge-name":${vbr_name}, "interface-name": ${interface_name}, "node":"${node_id}", "port-name":"${port_id}"}}    
    Should Be Equal As Strings    ${resp.status_code}    200

Delete a Vtn
    [Arguments]    ${vtn_name}
    [Documentation]    Delete a vtn with specified parameters.
    ${resp}=    RequestsLibrary.POST    session    restconf/operations/vtn:remove-vtn    data={"input": {"tenant-name":${vtn_name}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vlanmap
    [Arguments]    ${vtn_name}    ${vbr_name}    ${vlan_id}
    [Documentation]    Create a vlanmap
    ${resp}=    RequestsLibrary.Post    session    restconf/operations/vtn-vlan-map:add-vlan-map     data={"input": {"tenant-name":${vtn_name},"bridge-name":${vbr_name},"vlan-id":${vlan_id}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify Data Flows
    [Arguments]    ${vtn_name}    ${vBridge_name}
    [Documentation]    Verify the reason and physical data flows for the specified vtn and vbridge
    ${resp}=    RequestsLibrary.Get    session    ${REST_CONTEXT_VTNS}/${vtn_name}/flows/detail
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
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT}/pathmaps/${policy_id}    data=${pathmap_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get a pathmap
    [Documentation]    Get a pathmap for a vtn.
    ${resp}=    RequestsLibrary.Get    session    ${REST_CONTEXT}/pathmaps
    : FOR    ${pathElement}    IN    @{PATHMAP_ATTR}
    \    should Contain    ${resp.content}    ${pathElement}

Add a pathpolicy
    [Arguments]    ${pathpolicy_data}
    [Documentation]    Create a pathpolicy for a vtn
    ${json_data}=    json.dumps    ${pathpolicy_data}
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT}/pathpolicies/${policy_id}    data=${pathpolicy_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get a pathpolicy
    [Documentation]    Get a pathpolicy for a vtn.
    ${resp}=    RequestsLibrary.Get    session    ${REST_CONTEXT}/pathpolicies/${policy_id}
    : FOR    ${pathpolicyElement}    IN    @{PATHPOLICY_ATTR}
    \    should Contain    ${resp.content}    ${pathpolicyElement}

Verify flowEntryPathPolicy
    [Arguments]    ${of_version}    ${port}    ${output}
    [Documentation]    Checking Flows on switch S1 and switch S3 after applying path policy
    ${DUMPFLOWS}=    Set Variable If    "${of_version}"=="OF10"    ${DUMPFLOWS_OF10}    ${DUMPFLOWS_OF13}
    write    ${DUMPFLOWS}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    in_port=${port}    actions=${output}

Add a macmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${macmap_data}
    [Documentation]    Create a macmap for a vbridge
    ${json_data}=    json.dumps    ${macmap_data}
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/macmap/allow    data=${macmap_data}    headers=${HEADERS}
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
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${tenant_name}/vbridges/${Bridge_name}/macmap/allow    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Mininet Ping Should Succeed
    [Arguments]    ${host1}    ${host2}
    Write    ${host1} ping -c 1 ${host2}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Mininet Ping Should Not Succeed
    [Arguments]    ${host1}    ${host2}
    Write    ${host1} ping -c 3 ${host2}
    ${result}    Read Until    mininet>
    Should Not Contain    ${result}    64 bytes

Start vlan_topo
    [Arguments]    ${OF}
    Clean Mininet System
    ${mininet_conn_id1}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${mininet_conn_id1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Put File    ${CURDIR}/${CREATE_VLAN_TOPOLOGY_FILE_PATH}
    Run Keyword If    '${OF}' == 'OF13'    Write    ${vlan_topo_13}
    ...    ELSE IF    '${OF}' == 'OF10'    Write    ${vlan_topo_10}
    ${result}    Read Until    mininet>

Get flow
    [Arguments]    ${vtn_name}
    [Documentation]    Get data flow.
    ${resp}=    RequestsLibrary.Get    session    ${REST_CONTEXT_VTNS}/${vtn_name}/flows/detail
    Should Be Equal As Strings    ${resp.status_code}    200

Remove a portmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}
    [Documentation]    Remove a portmap for a interface of a vbridge
    ${resp}=    RequestsLibrary.POST    session    restconf/operations/vtn-port-map:remove-port-map    data={"input": { "tenant-name":"${vtn_name}","bridge-name":"${vBridge_name}", "interface-name": "${interface_name}"}}
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

Add a vtn flowfilter
    [Arguments]    ${vtn_name}    ${vtnflowfilter_data}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.POST    session    restconf/operations/vtn-flow-filter:set-flow-filter   data=${vtnflowfilter_data}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vbr flowfilter
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${vbrflowfilter_data}
    [Documentation]    Create a flowfilter for a vbr
    ${resp}=    RequestsLibrary.POST    session    restconf/operations/vtn-flow-filter:set-flow-filter    data=${vbrflowfilter_data}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vbrif flowfilter
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${vbrif_flowfilter_data}
    [Documentation]    Create a flowfilter for a vbrif
    ${resp}=    RequestsLibrary.POST    session     restconf/operations/vtn-flow-filter:set-flow-filter    data=${vbrif_flowfilter_data}
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

Add a flowcondition
    [Arguments]    ${flowcond_name}
    [Documentation]    Create a flowcondition using Restconfig Api
    ${resp}=    RequestsLibrary.Post    session    restconf/operations/vtn-flow-condition:set-flow-condition    data={"input":{"operation":"SET","present":"false","name":"${flowcond_name}", "vtn-flow-match":[{"vtn-ether-match":{"destination-address":"ba:bd:0f:e3:a8:c8","ether-type":"2048","source-address":"ca:9e:58:0c:1e:f0","vlan-id": "1"},"vtn-inet-match":{"source-network":"10.0.0.1/32","protocol":1,"destination-network":"10.0.0.2/32"},"index":"1"}]}}
    Should Be Equal As Strings    ${resp.status_code}    200

Get flowconditions
    [Documentation]    Retrieve the list of flowconditions created
    ${resp}=    RequestsLibrary.Get    session    restconf/operational/vtn-flow-condition:vtn-flow-conditions
    Should Be Equal As Strings    ${resp.status_code}    200

Get flowcondition
    [Arguments]    ${flowcond_name}    ${retrieve}
    [Documentation]    Retrieve the flowcondition by name
    ${resp}=    RequestsLibrary.Get    session    restconf/operational/vtn-flow-condition:vtn-flow-conditions/vtn-flow-condition/${flowcond_name}
    Run Keyword If    '${retrieve}' == 'retrieve'    Should Be Equal As Strings    ${resp.status_code}    200
    ...    ELSE    Should Not Be Equal As Strings    ${resp.status_code}    200

Remove flowcondition
    [Arguments]    ${flowcond_name}
    [Documentation]    Remove the flowcondition by name
    ${resp}=    RequestsLibrary.Post    session    restconf/operations/vtn-flow-condition:remove-flow-condition    {"input": {"name": "${flowcond_name}"}}
    Should Be Equal As Strings    ${resp.status_code}    200
