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
${vlan_topo}=   sudo mn --controller=remote,ip=${CONTROLLER} --custom vlan_vtn_test.py --topo vlantopo
${REST_CONTEXT_VTNS}    controller/nb/v2/vtn/default/vtns
${REST_CONTEXT}    controller/nb/v2/vtn/default
${VERSION_VTN}          controller/nb/v2/vtn/version
${VTN_INVENTORY}        restconf/operational/vtn-inventory:vtn-nodes
${DUMPFLOWS}    dpctl dump-flows -O OpenFlow13
${index}    7
@{FLOWELMENTS}    nw_src=10.0.0.1    nw_dst=10.0.0.3    actions=drop
${vlanmap_bridge1}    {"vlan": "200"}
${vlanmap_bridge2}    {"vlan": "300"}
${pathpolicy_topo}    sudo mn --controller=remote,ip=${CONTROLLER} --custom topo-3sw-2host_multipath.py --topo pathpolicytopo --switch ovsk,protocols=OpenFlow13
@{PATHMAP_ATTR}    "index":"1"    "condition":"flowcond_path"    "policy":"1"
${policy_id}    1
@{PATHPOLICY_ATTR}    "id":"1"    "type":"OF"    "name":"s4-eth2"
${OVSDB_CONFIG_DIR}    ${CURDIR}/${CREATE_PATHPOLICY_TOPOLOGY_FILE_PATH}

*** Keywords ***
Start SuiteVtnMa
    [Documentation]  Start VTN Manager Init Test Suite
    Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    3     Fetch vtn list
    Start Suite

Stop SuiteVtnMa
    [Documentation]  Stop VTN Manager Test Suite
    Delete All Sessions
    Stop Suite

Start SuiteVtnMaTest
    [Documentation]  Start VTN Manager Test Suite
    Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}

Stop SuiteVtnMaTest
    [Documentation]  Stop VTN Manager Test Suite
    Delete All Sessions

Fetch vtn list
    [Documentation]    Check if VTN Manager is up.
    ${resp}=    RequestsLibrary.Get    session    ${REST_CONTEXT_VTNS}
    Should Be Equal As Strings    ${resp.status_code}    200

Fetch vtn switch inventory
    [Arguments]    ${sw_name}
    [Documentation]    Check if Switch is detected.
    ${resp}=    RequestsLibrary.Get    session    ${VTN_INVENTORY}/vtn-inventory:vtn-node/${sw_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vtn
    [Arguments]    ${vtn_name}    ${vtn_data}
    [Documentation]    Create a vtn with specified parameters.
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}    data=${vtn_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Delete a vtn
    [Arguments]    ${vtn_name}
    [Documentation]    Create a vtn with specified parameters.
    ${resp}=    RequestsLibrary.Delete    session    ${REST_CONTEXT_VTNS}/${vtn_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vBridge
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${vBridge_data}
    [Documentation]    Create a vBridge in a VTN
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}    data=${vBridge_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a interface
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${interface_data}
    [Documentation]    Create a interface into a vBridge of a VTN
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}    data=${interface_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a portmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${portmap_data}
    [Documentation]    Create a portmap for a interface of a vbridge
    ${json_data}=   json.dumps    ${portmap_data}
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/portmap    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a pathmap
    [Arguments]    ${pathmap_data}
    [Documentation]    Create a pathmap for a vtn
    ${json_data}=   json.dumps    ${pathmap_data}
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT}/pathmaps/${policy_id}    data=${pathmap_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get a pathmap
    [Documentation]    Get a pathmap for a vtn.
    ${resp}=    RequestsLibrary.Get   session    ${REST_CONTEXT}/pathmaps
    : FOR    ${pathElement}    IN    @{PATHMAP_ATTR}
    \    should Contain    ${resp.content}    ${pathElement}

Add a pathpolicy
    [Arguments]    ${pathpolicy_data}
    [Documentation]    Create a pathpolicy for a vtn
    ${json_data}=   json.dumps    ${pathpolicy_data}
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT}/pathpolicies/${policy_id}    data=${pathpolicy_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get a pathpolicy
    [Documentation]    Get a pathpolicy for a vtn.
    ${resp}=    RequestsLibrary.Get   session    ${REST_CONTEXT}/pathpolicies/${policy_id}
    : FOR    ${pathpolicyElement}    IN    @{PATHPOLICY_ATTR}
    \    should Contain    ${resp.content}    ${pathpolicyElement}

Verify flowEntryBeforePathPolicy
    [Documentation]    Checking Flows on switch S1 and switch S3 before applying path policy
    write    ${DUMPFLOWS}
    ${result}    Read Until    mininet>
    @{list_to_verify}    Create List    in_port=1    actions=output:2    actions=output:3
    : FOR    ${flowverifyElement}    IN    @{list_to_verify}
    \    should Contain    ${result}    ${flowverifyElement}

Verify flowEntryAfterPathPolicy
    [Documentation]    Checking Flows on switch S1 and switch S3 after applying path policy
    write    ${DUMPFLOWS}
    ${result}    Read Until    mininet>
    @{list_to_verify}    Create List    in_port=1    actions=output:3    in_port=2
    : FOR    ${flowverifyElement}    IN    @{list_to_verify}
    \    should Contain    ${result}    ${flowverifyElement}

Mininet Execute Custom Topology
    [Documentation]    This will start mininet with custom topology.
    Start Mininet    ${MININET}    ${pathpolicy_topo}    ${OVSDB_CONFIG_DIR}

Delete a pathmap
    [Documentation]    Delete a pathmap for a vtn
    ${resp}=    RequestsLibrary.Delete    session    ${REST_CONTEXT}/pathmaps/1
    Should Be Equal As Strings    ${resp.status_code}    200

Get a pathmap after delete
    [Documentation]    Get a pathmap for a vtn.
    ${resp}=    RequestsLibrary.Get   session    ${REST_CONTEXT}/pathmaps
    : FOR    ${pathElement}    IN    @{PATHMAP_ATTR}
    \    should Not Contain    ${resp.content}    ${pathElement}

Delete a pathpolicy
    [Documentation]    Delete a pathpolicy for a vtn
    ${resp}=    RequestsLibrary.Delete    session    ${REST_CONTEXT}/pathpolicies/1
    Should Be Equal As Strings    ${resp.status_code}    200

Get a pathpolicy after delete
    [Documentation]    Get a pathpolicy for a vtn after delete.
    ${resp}=    RequestsLibrary.Get   session    ${REST_CONTEXT}/pathpolicies/${policy_id}
    : FOR    ${pathpolicyElement}    IN    @{PATHPOLICY_ATTR}
    \    should Not Contain    ${resp.content}    ${pathpolicyElement}

Add a macmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${macmap_data}
    [Documentation]    Create a macmap for a vbridge
    ${json_data}=   json.dumps    ${macmap_data}
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/macmap/allow    data=${macmap_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Mininet Ping Should Succeed
    [Arguments]     ${host1}     ${host2}
    Write    ${host1} ping -c 10 ${host2}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Mininet Ping Should Not Succeed
    [Arguments]    ${host1}    ${host2}
    Write    ${host1} ping -c 10 ${host2}
    ${result}    Read Until    mininet>
    Should Not Contain    ${result}    64 bytes

Delete a interface
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}
    [Documentation]    Delete a interface with specified parameters.
    ${resp}=    RequestsLibrary.Delete    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Start vlan_topo
    Clean Mininet System
    ${mininet_conn_id1}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${mininet_conn_id1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Put File    ${CURDIR}/${CREATE_VLAN_TOPOLOGY_FILE_PATH}
    Write    ${vlan_topo}
    ${result}    Read Until    mininet>

Add a vlanmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${vlanmap_data}
    [Documentation]    Create a vlanmap
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/vlanmaps/    data=${vlanmap_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get flow
    [Arguments]    ${vtn_name}
    [Documentation]    Get data flow.
    ${resp}=    RequestsLibrary.Get   session    ${REST_CONTEXT_VTNS}/${vtn_name}/flows/detail
    Should Be Equal As Strings    ${resp.status_code}    200

Remove a portmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${portmap_data}
    [Documentation]    Remove a portmap for a interface of a vbridge
    ${json_data}=   json.dumps    ${portmap_data}
    ${resp}=    RequestsLibrary.Delete    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/portmap    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify FlowMacAddress
    [Arguments]    ${host1}    ${host2}
    ${booleanValue}=    Run Keyword And Return Status    Verify macaddress    ${host1}    ${host2}
    Should Be Equal As Strings    ${booleanValue}    True

Verify RemovedFlowMacAddress
    [Arguments]    ${host1}    ${host2}
    ${booleanValue}=    Run Keyword And Return Status    Verify macaddress    ${host1}    ${host2}
    Should Not Be Equal As Strings    ${booleanValue}    True

Verify macaddress
    [Arguments]    ${host1}    ${host2}
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
    ${json_data}=   json.dumps    ${flowcond_data}
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT}/flowconditions/${cond_name}    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Delete a flowcondition
    [Arguments]    ${cond_name}
    [Documentation]    Delete a flowcondition for a interface of a vbridge
    ${resp}=    RequestsLibrary.Delete    session    ${REST_CONTEXT}/flowconditions/${cond_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a flowfilter
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a flowfilter_vtn
    [Arguments]    ${vtn_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/flowfilters/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a flowfilter_vbr
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vbr
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Update a flowfilter
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a flowfilter for drop
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
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
    write    ${DUMPFLOWS}
    ${result}    Read Until    mininet>
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    should Contain    ${result}    ${flowElement}
