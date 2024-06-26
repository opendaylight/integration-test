*** Settings ***
Library         SSHLibrary
Library         String
Library         DateTime
Library         Collections
Library         json
Library         RequestsLibrary
Variables       ../variables/Variables.py
Variables       ../variables/vtn/Modules.py
Resource        ./Utils.robot
Resource        ./KarafKeywords.robot
Resource        ./MininetKeywords.robot
Resource        ./TemplatedRequests.robot
Resource        DataModels.robot


*** Variables ***
${vlan_topo}                    --custom vlan_vtn_test.py --topo vlantopo
${VERSION_VTN}                  controller/nb/v2/vtn/version
${VTN_INVENTORY}                restconf/operational/vtn-inventory:vtn-nodes
${ENTITY_OWNERS}                restconf/operational/entity-owners:entity-owners
${DUMPFLOWS_OF10}               dpctl dump-flows -OOpenFlow10
${DUMPFLOWS_OF13}               dpctl dump-flows -OOpenFlow13
${FF_DUMPFLOWS_OF10}            sh ovs-ofctl dump-flows -OOpenFlow10 s3
${FF_DUMPFLOWS_OF13}            sh ovs-ofctl dump-flows -OOpenFlow13 s3
${DROP_DUMPFLOWS_OF10}          sh ovs-ofctl dump-flows -OOpenFlow10 s2
${DROP_DUMPFLOWS_OF13}          sh ovs-ofctl dump-flows -OOpenFlow13 s2
${DROP_OUT_DUMPFLOWS_OF10}      sh ovs-ofctl dump-flows -OOpenFlow10 s3
${DROP_OUT_DUMPFLOWS_OF13}      sh ovs-ofctl dump-flows -OOpenFlow13 s3
${FF_OUT_DUMPFLOWS_OF10}        sh ovs-ofctl dump-flows -OOpenFlow10 s2
${FF_OUT_DUMPFLOWS_OF13}        sh ovs-ofctl dump-flows -OOpenFlow13 s2
${index}                        7
@{inet_actions}                 mod_nw_src:192.0.0.1    mod_nw_dst:192.0.0.2
@{BRIDGE1_DATAFLOW}
...                             "reason":"PORTMAPPED"
...                             "tenant-name":"Tenant1"
...                             "bridge-name":"vBridge1"
...                             "interface-name":"if2"
@{BRIDGE2_DATAFLOW}
...                             "reason":"PORTMAPPED"
...                             "tenant-name":"Tenant1"
...                             "bridge-name":"vBridge2"
...                             "interface-name":"if3"
${vlanmap_bridge1}              200
${vlanmap_bridge2}              300
@{VLANMAP_BRIDGE1_DATAFLOW}     "reason":"VLANMAPPED"    "tenant-name":"Tenant1"    "bridge-name":"vBridge1_vlan"
@{VLANMAP_BRIDGE2_DATAFLOW}     "reason":"VLANMAPPED"    "tenant-name":"Tenant1"    "bridge-name":"vBridge2_vlan"
${out_before_pathpolicy}        output:2
${out_after_pathpolicy}         output:3
${pathpolicy_topo}              --custom topo-3sw-2host_multipath.py --topo pathpolicytopo
@{PATHMAP_ATTR}                 "index":"1"    "condition":"flowcond_path"    "policy":"1"
${policy_id}                    1
${in_port}                      1
${filter_index}                 1
@{inet_action}                  set_field:192.0.0.1->ip_src    set_field:192.0.0.2->ip_dst
${dscp_action}                  set_field:32->ip_dscp
${dscp_be_action}               set_field:32->nw_tos_shifted
${dscp_flow}                    mod_nw_tos:128
@{icmp_action}                  mod_tp_dst:1    mod_tp_src:3
${drop_action}                  actions=drop
${vlanpcp_action}               mod_vlan_pcp:6
${vlanpcp_actions}              set_field:6->vlan_pcp
${dlsrc_action}                 mod_dl_src:00:00:00:00:00:11
${dlsrc_actions}                set_field:00:00:00:00:00:11->eth_src
@{PATHPOLICY_ATTR}              "id":1    "port-desc":"openflow:4,2,s4-eth2"
${custom}                       ${CURDIR}/${CREATE_PATHPOLICY_TOPOLOGY_FILE_PATH}


*** Keywords ***
Start SuiteVtnMa
    [Documentation]    Start VTN Manager Rest Config Api Test Suite, and enabling karaf loglevel as TRACE for VTN.
    #Issue Command On Karaf Console    log:set TRACE org.opendaylight.vtn
    ${vtn_mgr_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${vtn_mgr_id}
    SSHLibrary.Login_With_Public_Key    ${ODL_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Execute Command
    ...    sudo sed -i "$ i log4j.logger.org.opendaylight.vtn = TRACE" ${WORKSPACE}/${BUNDLEFOLDER}/etc/org.ops4j.pax.logging.cfg
    Create Session
    ...    session
    ...    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    headers=${HEADERS_YANG_JSON}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    3    Fetch vtn list
    Start Mininet

Start SuiteVtnMaTest
    [Documentation]    Start VTN Manager Test Suite
    Create Session
    ...    session
    ...    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    headers=${HEADERS_YANG_JSON}

Stop SuiteVtnMa
    [Documentation]    Stop VTN Manager Test Suite
    Delete All Sessions

Stop SuiteVtnMaTest
    [Documentation]    Stop VTN Manager Test Suite
    Delete All Sessions

Fetch vtn list
    [Documentation]    Check if VTN Manager is up.
    ${resp}=    RequestsLibrary.GET On Session    session    restconf/operational/vtn:vtns    expected_status=200

Fetch vtn switch inventory
    [Documentation]    Check if Switch is detected.
    [Arguments]    ${sw_name}
    ${resp}=    RequestsLibrary.GET On Session
    ...    session
    ...    restconf/operational/vtn-inventory:vtn-nodes/vtn-node/${sw_name}    expected_status=200

Collect Debug Info
    [Documentation]    Check if Switch is detected.
    write    ${DUMPFLOWS_OF10}
    ${result}=    Read Until    mininet>
    write    ${DUMPFLOWS_OF13}
    ${result}=    Read Until    mininet>
    Get Model Dump    ${ODL_SYSTEM_IP}    ${vtn_data_models}

Add a Topology wait
    [Documentation]    Add a topology wait to complete all Inter-switch link connection of switches
    [Arguments]    ${topo_wait}
    ${resp}=    RequestsLibrary.Put Request
    ...    session
    ...    restconf/config/vtn-config:vtn-config
    ...    data={"vtn-config": {"topology-wait":${topo_wait}, "host-tracking": "true"}}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Add a Vtn
    [Documentation]    Create a vtn with specified parameters.
    [Arguments]    ${vtn_name}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn:update-vtn
    ...    data={"input": {"tenant-name":${vtn_name}, "update-mode": "CREATE","operation": "SET", "description": "creating vtn", "idle-timeout":300, "hard-timeout":0}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vBridge
    [Documentation]    Create a vBridge in a VTN
    [Arguments]    ${vtn_name}    ${vbr_name}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-vbridge:update-vbridge
    ...    data={"input": {"update-mode": "CREATE","operation":"SET", "tenant-name":${vtn_name}, "bridge-name":${vbr_name}, "description": "vbrdige created"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a interface
    [Documentation]    Create a interface into a vBridge of a VTN
    [Arguments]    ${vtn_name}    ${vbr_name}    ${interface_name}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-vinterface:update-vinterface
    ...    data={"input": {"update-mode":"CREATE","operation":"SET", "tenant-name":${vtn_name}, "bridge-name":${vbr_name}, "description": "vbrdige interfacecreated", "enabled":"true", "interface-name": ${interface_name}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a portmap
    [Documentation]    Create a portmap for a interface of a vbridge
    [Arguments]    ${vtn_name}    ${vbr_name}    ${interface_name}    ${node_id}    ${port_id}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-port-map:set-port-map
    ...    data={"input": { "tenant-name":${vtn_name}, "bridge-name":${vbr_name}, "interface-name": ${interface_name}, "node":"${node_id}", "port-name":"${port_id}"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete a Vtn
    [Documentation]    Delete a vtn with specified parameters.
    [Arguments]    ${vtn_name}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn:remove-vtn
    ...    data={"input": {"tenant-name":${vtn_name}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vlanmap
    [Documentation]    Create a vlanmap
    [Arguments]    ${vtn_name}    ${vbr_name}    ${vlan_id}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-vlan-map:add-vlan-map
    ...    data={"input": {"tenant-name":${vtn_name},"bridge-name":${vbr_name},"vlan-id":${vlan_id}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify Data Flows
    [Documentation]    Verify the reason and physical data flows for the specified vtn and vbridge
    [Arguments]    ${vtn_name}    ${vBridge_name}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow:get-data-flow
    ...    data={"input":{"tenant-name":"${vtn_name}","mode":"UPDATESTATS"}}
    IF    '${vBridge_name}' == 'vBridge1'
        DataFlowsForBridge    ${resp}    @{BRIDGE1_DATAFLOW}
    ELSE IF    '${vBridge_name}' == 'vBridge2'
        DataFlowsForBridge    ${resp}    @{BRIDGE2_DATAFLOW}
    ELSE IF    '${vBridge_name}' == 'vBridge1_vlan'
        DataFlowsForBridge    ${resp}    @{VLANMAP_BRIDGE1_DATAFLOW}
    ELSE
        DataFlowsForBridge    ${resp}    @{VLANMAP_BRIDGE2_DATAFLOW}
    END

Start PathSuiteVtnMaTest
    [Documentation]    Start VTN Manager Test Suite and Mininet
    Start SuiteVtnMaTest
    MininetKeywords.Start Mininet Single Controller
    ...    ${TOOLS_SYSTEM_IP}
    ...    ${ODL_SYSTEM_IP}
    ...    ${pathpolicy_topo}
    ...    ${custom}
    ...    ofversion=13

Start PathSuiteVtnMaTestOF10
    [Documentation]    Start VTN Manager Test Suite and Mininet in Open Flow 10 Specification
    Start SuiteVtnMaTest
    MininetKeywords.Start Mininet Single Controller
    ...    ${TOOLS_SYSTEM_IP}
    ...    ${ODL_SYSTEM_IP}
    ...    ${pathpolicy_topo}
    ...    ${custom}
    ...    ofversion=10

Stop PathSuiteVtnMaTest
    [Documentation]    Cleanup/Shutdown work at the completion of all tests.
    Delete All Sessions
    MininetKeywords.Stop Mininet And Exit

DataFlowsForBridge
    [Documentation]    Verify whether the required attributes exists.
    [Arguments]    ${resp}    @{BRIDGE_DATAFLOW}
    FOR    ${dataflowElement}    IN    @{BRIDGE_DATAFLOW}
        should Contain    ${resp.text}    ${dataflowElement}
    END

Add a pathmap
    [Documentation]    Create a pathmap for a vtn
    [Arguments]    ${pathmap_data}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-path-map:set-path-map
    ...    data=${pathmap_data}
    Should Be Equal As Strings    ${resp.status_code}    200

Get a pathmap
    [Documentation]    Get a pathmap for a vtn.
    ${resp}=    RequestsLibrary.GET On Session    session    restconf/operational/vtn-path-map:global-path-maps
    FOR    ${pathElement}    IN    @{PATHMAP_ATTR}
        should Contain    ${resp.text}    ${pathElement}
    END

Add a pathpolicy
    [Documentation]    Create a pathpolicy for a vtn
    [Arguments]    ${pathpolicy_data}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-path-policy:set-path-policy
    ...    data=${pathpolicy_data}
    Should Be Equal As Strings    ${resp.status_code}    200

Get a pathpolicy
    [Documentation]    Get a pathpolicy for a vtn.
    [Arguments]    ${pathpolicy_id}
    ${resp}=    RequestsLibrary.GET On Session
    ...    session
    ...    restconf/operational/vtn-path-policy:vtn-path-policies/vtn-path-policy/${pathpolicy_id}
    FOR    ${pathpolicyElement}    IN    @{PATHPOLICY_ATTR}
        should Contain    ${resp.text}    ${pathpolicyElement}
    END

Delete a pathmap
    [Documentation]    Remove a pathmap for a vtn
    [Arguments]    ${tenant_path}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-path-map:remove-path-map
    ...    data={"input":{"tenant-name":"${tenant_path}","map-index":["${policy_id}"]}}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete a pathpolicy
    [Documentation]    Delete a pathpolicy for a vtn
    [Arguments]    ${policy_id}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-path-policy:remove-path-policy
    ...    data={"input":{"id":"${policy_id}"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify flowEntryPathPolicy
    [Documentation]    Checking Flows on switch S1 and switch S3 after applying path policy
    [Arguments]    ${of_version}    ${port}    ${output}
    ${DUMPFLOWS}=    Set Variable If    "${of_version}"=="OF10"    ${DUMPFLOWS_OF10}    ${DUMPFLOWS_OF13}
    write    ${DUMPFLOWS}
    ${result}=    Read Until    mininet>
    Should Contain    ${result}    in_port=${port}    actions=${output}

Add a macmap
    [Documentation]    Create a macmap for a vbridge
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${src_add}    ${dst_add}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-mac-map:set-mac-map
    ...    data={"input":{"operation":"SET","allowed-hosts":["${dst_add}@0","${src_add}@0"],"tenant-name":"${vtn_name}","bridge-name":"${vBridge_name}"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Get DynamicMacAddress
    [Documentation]    Get Dynamic mac address of Host
    [Arguments]    ${h}
    write    ${h} ifconfig -a | grep HWaddr
    ${source}=    Read Until    mininet>
    ${HWaddress}=    Split String    ${source}    ${SPACE}
    ${sourceHWaddr}=    Get from List    ${HWaddress}    ${index}
    ${sourceHWaddress}=    Convert To Lowercase    ${sourceHWaddr}
    RETURN    ${sourceHWaddress}    # Also [Return] would work here.

Mininet Ping Should Succeed
    [Documentation]    Ping hosts to check connectivity
    [Arguments]    ${host1}    ${host2}
    Write    ${host1} ping -c 1 ${host2}
    ${result}=    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Mininet Ping Should Not Succeed
    [Documentation]    Ping hosts when there is no connectivity and check hosts is unreachable
    [Arguments]    ${host1}    ${host2}
    Write    ${host1} ping -c 3 ${host2}
    ${result}=    Read Until    mininet>
    Should Not Contain    ${result}    64 bytes

Start vlan_topo
    [Documentation]    Create custom topology for vlan functionality
    [Arguments]    ${OF}
    Install Package On Ubuntu System    vlan
    IF    '${OF}' == 'OF13'
        MininetKeywords.Start Mininet Single Controller
        ...    ${TOOLS_SYSTEM_IP}
        ...    ${ODL_SYSTEM_IP}
        ...    ${vlan_topo}
        ...    ${CURDIR}/${CREATE_VLAN_TOPOLOGY_FILE_PATH}
        ...    ofversion=13
    ELSE IF    '${OF}' == 'OF10'
        MininetKeywords.Start Mininet Single Controller
        ...    ${TOOLS_SYSTEM_IP}
        ...    ${ODL_SYSTEM_IP}
        ...    ${vlan_topo}
        ...    ${CURDIR}/${CREATE_VLAN_TOPOLOGY_FILE_PATH}
        ...    ofversion=10
    END

Get flow
    [Documentation]    Get data flow.
    [Arguments]    ${vtn_name}
    ${resp}=    RequestsLibrary.GET On Session
    ...    session
    ...    restconf/operational/vtn-flow-impl:vtn-flows/vtn-flow-table/${vtn_name}
    ...    expected_status=200

Remove a portmap
    [Documentation]    Remove a portmap for a interface of a vbridge
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-port-map:remove-port-map
    ...    data={"input": {"tenant-name":${vtn_name},"bridge-name":${vBridge_name},"interface-name":${interface_name}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify FlowMacAddress
    [Documentation]    Verify the source and destination mac address.
    [Arguments]    ${host1}    ${host2}    ${OF_VERSION}
    IF    '${OF_VERSION}' == 'OF10'
        Verify Flows On OpenFlow    ${host1}    ${host2}    ${FF_DUMPFLOWS_OF10}
    ELSE
        VerifyFlowsOnOpenFlow    ${host1}    ${host2}    ${FF_DUMPFLOWS_OF13}
    END

Verify Flows On OpenFlow
    [Documentation]    Verify the mac addresses on the specified open flow.
    [Arguments]    ${host1}    ${host2}    ${DUMPFLOWS}
    ${booleanValue}=    Run Keyword And Return Status    Verify macaddress    ${host1}    ${host2}    ${DUMPFLOWS}
    Should Be Equal As Strings    ${booleanValue}    True

Verify RemovedFlowMacAddress
    [Documentation]    Verify the removed source and destination mac address.
    [Arguments]    ${host1}    ${host2}    ${OF_VERSION}
    IF    '${OF_VERSION}' == 'OF10'
        Verify Removed Flows On OpenFlow    ${host1}    ${host2}    ${FF_DUMPFLOWS_OF10}
    ELSE
        Verify Removed Flows On OpenFlow    ${host1}    ${host2}    ${FF_DUMPFLOWS_OF13}
    END

Verify Removed Flows On OpenFlow
    [Documentation]    Verify the removed mac addresses on the specified open flow.
    [Arguments]    ${host1}    ${host2}    ${DUMPFLOWS}
    ${booleanValue}=    Run Keyword And Return Status    Verify macaddress    ${host1}    ${host2}    ${DUMPFLOWS}
    Should Not Be Equal As Strings    ${booleanValue}    True

Verify macaddress
    [Documentation]    Verify the source and destination mac address after ping in the dumpflows
    [Arguments]    ${host1}    ${host2}    ${DUMPFLOWS}
    write    ${host1} ifconfig -a | grep HWaddr
    ${sourcemacaddr}=    Read Until    mininet>
    ${macaddress}=    Split String    ${sourcemacaddr}    ${SPACE}
    ${sourcemacaddr}=    Get from List    ${macaddress}    ${index}
    ${sourcemacaddress}=    Convert To Lowercase    ${sourcemacaddr}
    write    ${host2} ifconfig -a | grep HWaddr
    ${destmacaddr}=    Read Until    mininet>
    ${macaddress}=    Split String    ${destmacaddr}    ${SPACE}
    ${destmacaddr}=    Get from List    ${macaddress}    ${index}
    ${destmacaddress}=    Convert To Lowercase    ${destmacaddr}
    write    ${DUMPFLOWS}
    ${result}=    Read Until    mininet>
    Should Contain    ${result}    ${sourcemacaddress}
    Should Contain    ${result}    ${destmacaddress}

Verify flowactions
    [Documentation]    Verify the flowfilter actions after ping in the dumpflows
    [Arguments]    ${actions}    ${DUMPFLOWS}
    write    ${DUMPFLOWS}
    ${result}=    Read Until    mininet>
    Should Contain    ${result}    ${actions}

Add a vtn flowfilter
    [Documentation]    Create a flowfilter for a vtn
    [Arguments]    ${vtn_name}    ${vtnflowfilter_data}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow-filter:set-flow-filter
    ...    data={"input": {"tenant-name": "${vtn_name}",${vtnflowfilter_data}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Remove a vtn flowfilter
    [Documentation]    Delete a vtn flowfilter
    [Arguments]    ${vtn_name}    ${filter_index}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow-filter:remove-flow-filter
    ...    data={"input": {"indices": ["${filter_index}"], "tenant-name": "${vtn_name}"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vbr flowfilter
    [Documentation]    Create a flowfilter for a vbr
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${vbrflowfilter_data}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow-filter:set-flow-filter
    ...    data={"input": {"tenant-name": "${vtn_name}", "bridge-name": "${vBridge_name}", ${vbrflowfilter_data}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Remove a vbr flowfilter
    [Documentation]    Delete a vbr flowfilter
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${filter_index}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow-filter:remove-flow-filter
    ...    data={"input": {"indices": ["${filter_index}"], "tenant-name": "${vtn_name}","bridge-name": "${vBridge_name}"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vbrif flowfilter
    [Documentation]    Create a flowfilter for a vbrif
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${vbrif_flowfilter_data}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow-filter:set-flow-filter
    ...    data={"input": {"tenant-name": ${vtn_name}, "bridge-name": "${vBridge_name}","interface-name":"${interface_name}",${vbrif_flowfilter_data}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Remove a vbrif flowfilter
    [Documentation]    Delete a vbrif flowfilter
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${filter_index}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow-filter:remove-flow-filter
    ...    data={"input": {"indices": ["${filter_index}"], "tenant-name": "${vtn_name}","bridge-name": "${vBridge_name}","interface-name": "${interface_name}"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vlan portmap
    [Documentation]    Create a portmap for a interface of a vbridge
    [Arguments]    ${vtn_name}    ${vbr_name}    ${interface_name}    ${id}    ${node_id}    ${port_id}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-port-map:set-port-map
    ...    data={"input": { "tenant-name":${vtn_name}, "bridge-name":${vbr_name}, "interface-name": ${interface_name}, "vlan-id": ${id}, "node":"${node_id}", "port-name":"${port_id}"}}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify Flow Entries for Flowfilter
    [Documentation]    Verify switch flow entry using flowfilter for a vtn
    [Arguments]    ${dumpflows}    @{flowfilter_actions}
    ${booleanValue}=    Run Keyword And Return Status
    ...    Verify Actions on Flow Entry
    ...    ${dumpflows}
    ...    @{flowfilter_actions}
    Should Be Equal As Strings    ${booleanValue}    True

Verify Removed Flow Entry for Inet Drop Flowfilter
    [Documentation]    Verify removed switch flow entry using flowfilter drop for a vtn
    [Arguments]    ${dumpflows}    @{flowfilter_actions}
    ${booleanValue}=    Run Keyword And Return Status
    ...    Verify Actions on Flow Entry
    ...    ${dumpflows}
    ...    @{flowfilter_actions}
    Should Be Equal As Strings    ${booleanValue}    True

Verify Actions on Flow Entry
    [Documentation]    check flow action elements by giving dumpflows in mininet
    [Arguments]    ${dumpflows}    @{flowfilter_actions}
    write    ${dumpflows}
    ${result}=    Read Until    mininet>
    FOR    ${flowElement}    IN    @{flowfilter_actions}
        should Contain    ${result}    ${flowElement}
    END

Add a flowcondition
    [Documentation]    Create a flowcondition using Restconfig Api
    [Arguments]    ${flowcond_name}    ${flowconditiondata}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow-condition:set-flow-condition
    ...    data={"input":{"operation":"SET","present":"false","name":"${flowcond_name}",${flowconditiondata}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Get flowconditions
    [Documentation]    Retrieve the list of flowconditions created
    ${resp}=    RequestsLibrary.Get On Session
    ...    session
    ...    restconf/operational/vtn-flow-condition:vtn-flow-conditions
    ...    expected_status=200

Get flowcondition
    [Documentation]    Retrieve the flowcondition by name and to check the removed flowcondition we added "retrieve" argument to differentiate the status code,
    ...    since after removing flowcondition name the status will be different compare to status code when the flowcondition name is present.
    [Arguments]    ${flowcond_name}    ${retrieve}
    ${resp}=    RequestsLibrary.GET On Session
    ...    session
    ...    restconf/operational/vtn-flow-condition:vtn-flow-conditions/vtn-flow-condition/${flowcond_name}
    ...    expected_status=anything
    IF    '${retrieve}' == 'retrieve'
        Should Be Equal As Strings    ${resp.status_code}    200
    ELSE
        Should Not Be Equal As Strings    ${resp.status_code}    200
    END

Remove flowcondition
    [Documentation]    Remove the flowcondition by name
    [Arguments]    ${flowcond_name}
    ${resp}=    RequestsLibrary.Post Request
    ...    session
    ...    restconf/operations/vtn-flow-condition:remove-flow-condition
    ...    data={"input":{"name":"${flowcond_name}"}}
    Should Be Equal As Strings    ${resp.status_code}    200
