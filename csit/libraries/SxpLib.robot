*** Settings ***
Documentation     Library containing Keywords used for SXP testing
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           SSHLibrary
Library           String
Library           ./Sxp.py
Resource          KarafKeywords.robot
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
${REST_CONTEXT}    /restconf/operations/sxp-controller

*** Keywords ***
Post To Controller
    [Arguments]    ${session}    ${path}    ${DATA}
    [Documentation]    Post request to Controller and checks response
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:${path}    data=${DATA}    headers=${HEADERS_XML}
    Log    ${resp.content}
    Log    ${session}
    Log    ${path}
    Log    ${DATA}
    Should be Equal As Strings    ${resp.status_code}    200
    ${content}    Evaluate    json.loads('''${resp.content}''')    json
    ${content}    Get From Dictionary    ${content}    output
    ${content}    Get From Dictionary    ${content}    result
    Should Be True    ${content}    Post to ${path} failed as invalid data manipulation

Add Node
    [Arguments]    ${node}    ${password}=${EMPTY}    ${version}=version4    ${port}=64999    ${session}=session    ${ip}=${EMPTY}
    [Documentation]    Add node via RPC to ODL
    ${DATA}    Add Node Xml    ${node}    ${port}    ${password}    ${version}    ${ip}
    Post To Controller    ${session}    add-node    ${DATA}

Delete Node
    [Arguments]    ${node}    ${session}=session
    [Documentation]    Delete connection via RPC from node
    ${DATA}    Delete Node Xml    ${node}
    Post To Controller    ${session}    delete-node    ${DATA}

Add Connection
    [Arguments]    ${version}    ${mode}    ${ip}    ${port}    ${node}=127.0.0.1    ${password}=${EMPTY}
    ...    ${session}=session    ${domain}=global
    [Documentation]    Add connection via RPC to node
    ${DATA}    Add Connection Xml    ${version}    ${mode}    ${ip}    ${port}    ${node}
    ...    ${password}    ${domain}
    Post To Controller    ${session}    add-connection    ${DATA}

Get Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Gets all connections via RPC from node
    ${DATA}    Get Connections From Node Xml    ${node}    ${domain}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:get-connections    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Delete Connections
    [Arguments]    ${ip}    ${port}    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete connection via RPC from node
    ${DATA}    Delete Connections Xml    ${ip}    ${port}    ${node}    ${domain}
    Post To Controller    ${session}    delete-connection    ${DATA}

Clean Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete all connections via RPC from node
    ${resp}    Get Connections    ${node}    ${session}    ${domain}
    @{connections}    Parse Connections    ${resp}
    : FOR    ${connection}    IN    @{connections}
    \    Delete Connections    ${connection['peer-address']}    ${connection['tcp-port']}    ${node}    ${session}

Verify Connection
    [Arguments]    ${version}    ${mode}    ${ip}    ${port}=64999    ${node}=127.0.0.1    ${state}=on
    ...    ${session}=session    ${domain}=global
    [Documentation]    Verify that connection is ON
    ${resp}    Get Connections    ${node}    ${session}    ${domain}
    Should Contain Connection    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}

Add Binding
    [Arguments]    ${sgt}    ${prefix}    ${node}=127.0.0.1    ${domain}=global    ${session}=session
    [Documentation]    Add binding via RPC to Master DB of node
    ${DATA}    Add Entry Xml    ${sgt}    ${prefix}    ${node}    ${domain}
    Post To Controller    ${session}    add-entry    ${DATA}

Get Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global    ${scope}=all
    [Documentation]    Gets all binding via RPC from Master DB of node
    ${DATA}    Get Bindings From Node Xml    ${node}    ${scope}    ${domain}
    ${resp}    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Post Request    ${session}    ${REST_CONTEXT}:get-node-bindings    data=${DATA}
    ...    headers=${HEADERS_XML}
    ...    ELSE    Get Request    ${session}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/master-database/    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Clean Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete all bindings via RPC from Master DB of node
    ${resp}    Get Bindings    ${node}    ${session}    ${domain}    local
    @{bindings}    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Parse Bindings    ${resp}
    ...    ELSE    Parse Prefix Groups    ${resp}    local
    : FOR    ${binding}    IN    @{bindings}
    \    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Clean Binding    ${binding['sgt']}    ${binding['ip-prefix']}    ${node}
    \    ...    ${session}    ${domain}
    \    ...    ELSE    Clean Binding    ${binding}    ${binding['binding']}    ${node}
    \    ...    ${session}    ${domain}

Clean Binding
    [Arguments]    ${sgt}    ${prefixes}    ${node}    ${session}    ${domain}=global
    [Documentation]    Used for nester FOR loop
    : FOR    ${prefix}    IN    @{prefixes}
    \    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Delete Binding    ${sgt}    ${prefix}    ${node}
    \    ...    ${domain}    ${session}
    \    ...    ELSE    Delete Binding    ${sgt['sgt']}    ${prefix['ip-prefix']}    ${node}
    \    ...    ${domain}    ${session}

Update Binding
    [Arguments]    ${sgtOld}    ${prefixOld}    ${sgtNew}    ${prefixNew}    ${node}=127.0.0.1    ${session}=session
    ...    ${domain}=global
    [Documentation]    Updates value of binding via RPC in Master DB of node
    ${DATA}    Update Binding Xml    ${sgtOld}    ${prefixOld}    ${sgtNew}    ${prefixNew}    ${node}
    ...    ${domain}
    Post To Controller    ${session}    update-entry    ${DATA}

Delete Binding
    [Arguments]    ${sgt}    ${prefix}    ${node}=127.0.0.1    ${domain}=global    ${session}=session
    [Documentation]    Delete binding via RPC from Master DB of node
    ${DATA}    Delete Binding Xml    ${sgt}    ${prefix}    ${node}    ${domain}
    Post To Controller    ${session}    delete-entry    ${DATA}

Add PeerGroup
    [Arguments]    ${name}    ${peers}=    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Adds new PeerGroup via RPC to Node
    ${DATA}    Add Peer Group Xml    ${name}    ${peers}    ${node}
    Post To Controller    ${session}    add-peer-group    ${DATA}

Delete Peer Group
    [Arguments]    ${name}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete PeerGroup via RPC from Node
    ${DATA}    Delete Peer Group Xml    ${name}    ${node}
    Post To Controller    ${session}    delete-peer-group    ${DATA}

Get Peer Groups
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Gets all PeerGroups via RPC from node
    ${DATA}    Get Peer Groups From Node Xml    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:get-peer-groups    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Clean Peer Groups
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete all PeerGroups via RPC from node
    ${resp}    Get Peer Groups    ${node}    ${session}
    @{prefixes}    Parse Peer Groups    ${resp}
    : FOR    ${group}    IN    @{prefixes}
    \    Delete Peer Group    ${group['name']}    ${node}    ${session}

Add Filter
    [Arguments]    ${name}    ${type}    ${entries}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Add Filter via RPC from Node
    ${DATA}    Add Filter Xml    ${name}    ${type}    ${entries}    ${node}
    Post To Controller    ${session}    add-filter    ${DATA}

Add Domain Filter
    [Arguments]    ${name}    ${domains}    ${entries}    ${node}=127.0.0.1    ${filter_name}=base-domain-filter    ${session}=session
    [Documentation]    Add Domain Filter via RPC from Node
    ${DATA}    Add Domain Filter Xml    ${name}    ${domains}    ${entries}    ${node}    ${filter_name}
    Post To Controller    ${session}    add-domain-filter    ${DATA}

Delete Filter
    [Arguments]    ${name}    ${type}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete Filter via RPC from Node
    ${DATA}    Delete Filter Xml    ${name}    ${type}    ${node}
    Post To Controller    ${session}    delete-filter    ${DATA}

Delete Domain Filter
    [Arguments]    ${name}    ${node}=127.0.0.1    ${filter_name}=base-domain-filter    ${session}=session
    [Documentation]    Delete Filter via RPC from Node
    ${DATA}    Delete Domain Filter Xml    ${name}    ${node}    ${filter_name}
    Post To Controller    ${session}    delete-domain-filter    ${DATA}

Should Contain Binding
    [Arguments]    ${resp}    ${sgt}    ${prefix}    ${db_source}=any
    [Documentation]    Tests if data contains specified binding
    ${out}    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Find Binding    ${resp}    ${sgt}    ${prefix}
    ...    ELSE    Find Binding Legacy    ${resp}    ${sgt}    ${prefix}    ${db_source}
    ...    add
    Should Be True    ${out}    Doesn't have ${sgt} ${prefix}

Should Not Contain Binding
    [Arguments]    ${resp}    ${sgt}    ${prefix}    ${db_source}=any
    [Documentation]    Tests if data doesn't contains specified binding
    ${out}    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Find Binding    ${resp}    ${sgt}    ${prefix}
    ...    ELSE    Find Binding Legacy    ${resp}    ${sgt}    ${prefix}    ${db_source}
    ...    add
    Should Not Be True    ${out}    Should't have ${sgt} ${prefix}

Should Contain Connection
    [Arguments]    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}=none
    [Documentation]    Test if data contains specified connection
    ${out}    Find Connection    ${resp}    ${version}    ${mode}    ${ip}    ${port}
    ...    ${state}
    Should Be True    ${out}    Doesn't have ${ip}:${port} ${mode} ${version}

Should Not Contain Connection
    [Arguments]    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}=none
    [Documentation]    Test if data doesn't contains specified connection
    ${out}    Find Connection    ${resp}    ${version}    ${mode}    ${ip}    ${port}
    ...    ${state}
    Should Not Be True    ${out}    Shouldn't have ${ip}:${port} ${mode} ${version}

Setup Topology Complex
    [Arguments]    ${version}=version4    ${PASSWORD}=none
    : FOR    ${node}    IN RANGE    2    6
    \    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.${node}
    \    ...    ${PASSWORD}
    \    Add Connection    ${version}    both    127.0.0.${node}    64999    127.0.0.1
    \    ...    ${PASSWORD}
    \    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both
    \    ...    127.0.0.${node}
    \    Add Binding    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
    \    Add Binding    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
    \    Add Binding    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
    \    Add Binding    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    Add Binding    10    10.10.10.10/32    127.0.0.1
    Add Binding    10    10.10.10.0/24    127.0.0.1
    Add Binding    10    10.10.0.0/16    127.0.0.1
    Add Binding    10    10.0.0.0/8    127.0.0.1

Verify Snapshot Was Pushed
    [Arguments]    ${snapshot_string}=22-sxp-controller-one-node.xml
    [Documentation]    Will succeed if the ${snapshot_string} is found in the karaf logs
    ${output}    Run Command On Controller    ${ODL_SYSTEM_IP}    cat ${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log* | grep -c 'Successfully pushed configuration snapshot.*${snapshot_string}'
    Should Not Be Equal As Strings    ${output}    0

Setup SXP Session
    [Arguments]    ${session}=session    ${controller}=${ODL_SYSTEM_IP}
    [Documentation]    Create session to Controller
    Install a Feature    odl-sxp-controller    ${controller}
    Verify Feature Is Installed    odl-sxp-controller    ${controller}
    Create Session    ${session}    url=http://${controller}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${resp}    RequestsLibrary.Get Request    ${session}    ${MODULES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf

Clean SXP Session
    [Documentation]    Destroy created sessions
    Delete All Sessions

Add Domain
    [Arguments]    ${domain_name}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Add Domain via RPC
    ${DATA}    Add Domain Xml    ${node}    ${domain_name}
    Post To Controller    ${session}    add-domain    ${DATA}

Delete Domain
    [Arguments]    ${domain_name}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete Domain via RPC
    ${DATA}    Delete Domain Xml    ${node}    ${domain_name}
    Post To Controller    ${session}    delete-domain    ${DATA}

Add Bindings
    [Arguments]    ${sgt}    ${prefixes}    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Add bindings via RPC to Master DB of node
    ${DATA}    Add Bindings Xml    ${node}    ${domain}    ${sgt}    ${prefixes}
    Post To Controller    ${session}    add-bindings    ${DATA}

Delete Bindings
    [Arguments]    ${sgt}    ${prefixes}    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete bindings via RPC from Master DB of node
    ${DATA}    Delete Bindings Xml    ${node}    ${domain}    ${sgt}    ${prefixes}
    Post To Controller    ${session}    delete-bindings    ${DATA}

Add Bindings Range
    [Arguments]    ${sgt}    ${start}    ${size}    ${node}
    [Documentation]    Add Bindings to Node specified by range
    ${prefixes}    Prefix Range    ${start}    ${size}
    Add Bindings    ${sgt}    ${prefixes}    ${node}

Delete Bindings Range
    [Arguments]    ${sgt}    ${start}    ${size}    ${node}
    [Documentation]    Delete Bindings to Node specified by range
    ${prefixes}    Prefix Range    ${start}    ${size}
    Delete Bindings    ${sgt}    ${prefixes}    ${node}

Check Binding Range
    [Arguments]    ${sgt}    ${start}    ${end}    ${node}
    [Documentation]    Check if Node contains Bindings specified by range
    ${resp}    Get Bindings    ${node}
    : FOR    ${num}    IN RANGE    ${start}    ${end}
    \    ${ip}    Get Ip From Number    ${num}
    \    Should Contain Binding    ${resp}    ${sgt}    ${ip}/32

Check Binding Range Negative
    [Arguments]    ${sgt}    ${start}    ${end}    ${node}
    [Documentation]    Check if Node does not contains Bindings specified by range
    ${resp}    Get Bindings    ${node}
    : FOR    ${num}    IN RANGE    ${start}    ${end}
    \    ${ip}    Get Ip From Number    ${num}
    \    Should Not Contain Binding    ${resp}    ${sgt}    ${ip}/32

Setup SXP Environment
    [Arguments]    ${node_range}=2
    [Documentation]    Create session to Controller, node_range parameter specifies number of nodes to be created plus one
    Setup SXP Session
    : FOR    ${num}    IN RANGE    1    ${node_range}
    \    ${ip}    Get Ip From Number    ${num}
    \    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Add Node    ${ip}
    \    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Wait Until Keyword Succeeds    20    1    Check Node Started
    \    ...    ${ip}

Check Node Started
    [Arguments]    ${node}    ${port}=64999    ${system}=${ODL_SYSTEM_IP}    ${session}=session    ${ip}=${node}
    [Documentation]    Verify that SxpNode has data writed to Operational datastore
    ${resp}    RequestsLibrary.Get Request    ${session}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${rc}    Run Command On Remote System    ${system}    netstat -tln | grep -q ${ip}:${port} && echo 0 || echo 1    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}    prompt=${ODL_SYSTEM_PROMPT}
    Should Be Equal As Strings    ${rc}    0

Check Node Stopped
    [Arguments]    ${node}    ${port}=64999    ${system}=${ODL_SYSTEM_IP}    ${session}=session    ${ip}=${node}
    [Documentation]    Verify that SxpNode has data writed to Operational datastore
    ${resp}    RequestsLibrary.Get Request    ${session}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    Should Not Be Equal As Strings    ${resp.status_code}    200
    ${rc}    Run Command On Remote System    ${system}    netstat -tln | grep -q ${ip}:${port} && echo 1 || echo 0    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}    prompt=${ODL_SYSTEM_PROMPT}
    Should Be Equal As Strings    ${rc}    0

Clean SXP Environment
    [Arguments]    ${node_range}=2
    [Documentation]    Destroy created sessions
    : FOR    ${num}    IN RANGE    1    ${node_range}
    \    ${ip}    Get Ip From Number    ${num}
    \    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Delete Node    ${ip}
    \    Run Keyword If    '${ODL_STREAM}' not in ['beryllium', 'stable-lithium']    Wait Until Keyword Succeeds    20    1    Check Node Stopped
    \    ...    ${ip}
    Clean SXP Session

Run Keyword With Optional Error
    [Arguments]    ${MAY_FAIL}    ${keyword}    @{args}
    [Documentation]    Runs keyword and ignore Error if ${MAY_FAIL} is set to True
    Run Keyword If    ${MAY_FAIL}    Run Keyword And Ignore Error    ${keyword}    @{args}
    ...    ELSE    ${keyword}    @{args}
