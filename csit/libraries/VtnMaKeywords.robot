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
${VTN_CONFIG}        restconf/config/vtn-static-topology:vtn-static-topology/static-edge-ports
${DUMPFLOWS}    dpctl dump-flows -O OpenFlow13
${index}    7
@{FLOWELMENTS}    nw_src=10.0.0.1    nw_dst=10.0.0.3    actions=drop
${vlanmap_bridge1}    {"vlan": "200"}
${vlanmap_bridge2}    {"vlan": "300"}


${scf_topo}    sudo mn --controller=remote,ip=${CONTROLLER} --custom topo_handson.py --topo scftopo --switch ovsk,protocols=OpenFlow13
${flowfilterdropdata}    {"index":1,"condition":"cond_1","filterType":{"drop":{}}}
${flowfilterRedirectAnydata}    {"index":2,"condition":"cond_Any","filterType":{"redirect":{"destination": {"bridge": "vBridge1","interface": "if2"},"output": true}}}
${flowfilterRedirectdata}    {"index":3,"condition":"cond_1","filterType":{"redirect":{"destination": {"terminal": "vTerminal1","interface": "if4"},"output": true}}}
${static_edge_ports}    {"static-edge-ports": {"static-edge-port": [ {"port": "openflow:3:3"}, {"port": "openflow:3:4"}, {"port": "openflow:4:3"}, {"port": "openflow:4:4"}]}}


*** Keywords ***
Start SuiteVtnMa
    [Documentation]  Start VTN Manager Init Test Suite
    Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    3     Fetch vtn list
    Start Suite

Start SuiteVtnMaSCF
    [Documentation]  Start VTN Manager Service Chain Function Test Suite
    Create Session    session    url=http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    3     Fetch vtn list

Stop SuiteVtnMa
    [Documentation]  Stop VTN Manager Test Suite
    Delete All Sessions
    Stop Suite

Stop SuiteVtnMaSCF
    [Documentation]  Stop VTN Manager Test Suite
    Delete All Sessions
    Stop Suite

Start SuiteVtnMaTest
    [Documentation]  Start VTN Manager Test Suite
    Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}

Start SuiteVtnMaSCFTest
    [Documentation]  Start VTN Manager Service Chain Function Test Suite
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Put    session    ${VTN_CONFIG}    data=${static_edge_ports}
    Should Be Equal As Strings    ${resp.status_code}    200

Stop SuiteVtnMaTest
    [Documentation]  Stop VTN Manager Test Suite
    Delete All Sessions

Stop SuiteVtnMaSCFTest
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

Add a macmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${macmap_data}
    [Documentation]    Create a macmap for a vbridge
    ${json_data}=   json.dumps    ${macmap_data}
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/macmap/allow    data=${macmap_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a vTerminal
    [Arguments]    ${vtn_name}    ${vTerminal_name}    ${vTerminal_data}
    [Documentation]    Create a vTerminal in a VTN
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vterminals/${vTerminal_name}    data=${vTerminal_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a interface to terminal
    [Arguments]    ${vtn_name}    ${vTerminal_name}    ${interface_name}    ${interface_data}
    [Documentation]    Create a interface into a vTerminal of a VTN
    ${resp}=    RequestsLibrary.Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vterminals/${vTerminal_name}/interfaces/${interface_name}    data=${interface_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a portmap to terminal intf
    [Arguments]    ${vtn_name}    ${vTerminal_name}    ${interface_name}    ${portmap_data}
    [Documentation]    Create a portmap for a interface of a vterminal
    ${json_data}=   json.dumps    ${portmap_data}
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vterminals/${vTerminal_name}/interfaces/${interface_name}/portmap    data=${json_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Configure service nodes
    Write    srvc1 ip addr del 10.0.0.6/8 dev srvc1-eth0
    Write    srvc1 brctl addbr br0
    Write    srvc1 brctl addif br0 srvc1-eth0
    Write    srvc1 brctl addif br0 srvc1-eth1
    Write    srvc1 ifconfig br0 up
    Write    srvc1 tc qdisc add dev srvc1-eth1 root netem delay 200ms
    Write    srvc2 ip addr del 10.0.0.7/8 dev srvc2-eth0
    Write    srvc2 brctl addbr br0
    Write    srvc2 brctl addif br0 srvc2-eth0
    Write    srvc2 brctl addif br0 srvc2-eth1
    Write    srvc2 ifconfig br0 up
    Write    srvc2 tc qdisc add dev srvc2-eth1 root netem delay 300ms
    ${result}    Read Until    mininet>

Add a flowfilter terminal redirect
    [Arguments]    ${vtn_name}    ${vTerminal_name}    ${interface_name}    ${flowfilter_data}    ${ff_index}
    [Documentation]    Create a flowfilter for a vtn
    ${resp}=    RequestsLibrary.Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vterminals/${vTerminal_name}/interfaces/${interface_name}/flowfilters/IN/${ff_index}    data=${flowfilter_data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Start Scf Topology
    [Documentation]    Starts Service Chain Functioning custom topology.
    Start Mininet    ${MININET}    ${scf_topo}    ${CURDIR}/${CREATE_SCF_TOPOLOGY_FILE_PATH}

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

Install Flow Entries
    ${mininet_conn_id4}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${mininet_conn_id4}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo ovs-ofctl add-flow s1 priority=0,actions=output:CONTROLLER
    Execute Command    sudo ovs-ofctl add-flow s2 priority=0,actions=output:CONTROLLER
    Execute Command    sudo ovs-ofctl add-flow s3 priority=0,actions=output:CONTROLLER
    Execute Command    sudo ovs-ofctl add-flow s4 priority=0,actions=output:CONTROLLER

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
    Should Be Equal As Strings    ${resp.status_code}    201

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
