*** Settings ***
Documentation     Library containing Keywords used for SXP testing
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ./Sxp.py
Resource          KarafKeywords.robot
Variables         ../variables/Variables.py

*** Variables ***
${REST_CONTEXT}    /restconf/operations/sxp-controller

*** Keywords ***
Add Connection
    [Arguments]    ${version}    ${mode}    ${ip}    ${port}    ${node}=127.0.0.1    ${password}=none
    ...    ${session}=session
    [Documentation]    Add connection via RPC to node
    ${DATA}    Add Connection Xml    ${version}    ${mode}    ${ip}    ${port}    ${node}
    ...    ${password}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:add-connection    data=${DATA}    headers=${HEADERS_XML}
    LOG     ${resp}
    Should be Equal As Strings    ${resp.status_code}    200

Get Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Gets all connections via RPC from node
    ${DATA}    Get Connections From Node Xml    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:get-connections    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Delete Connections
    [Arguments]    ${ip}    ${port}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete connection via RPC from node
    ${DATA}    Delete Connections Xml    ${ip}    ${port}    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:delete-connection    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Clean Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete all connections via RPC from node
    ${resp}    Get Connections    ${node}    ${session}
    @{connections}    Parse Connections    ${resp}
    : FOR    ${connection}    IN    @{connections}
    \    delete connections    ${connection['peer-address']}    ${connection['tcp-port']}    ${node}    ${session}

Verify Connection
    [Arguments]    ${version}    ${mode}    ${ip}    ${port}=64999    ${node}=127.0.0.1    ${state}=on
    [Documentation]    Verify that connection is ON
    ${resp}    Get Connections    ${node}
    Should Contain Connection    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}

Add Binding
    [Arguments]    ${sgt}    ${prefix}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Add binding via RPC to Master DB of node
    ${DATA}    Add Entry Xml    ${sgt}    ${prefix}    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:add-entry    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Get Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Gets all binding via RPC from Master DB of node
    ${DATA}    Get Bindings From Node Xml    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:get-node-bindings    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Clean Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete all bindings via RPC from Master DB of node
    ${resp}    Get Bindings Master Database    ${node}    ${session}
    @{prefixes}    Parse Prefix Groups    ${resp}    local
    : FOR    ${prefix}    IN    @{prefixes}
    \    Clean Binding    ${prefix}    ${prefix['binding']}    ${node}    ${session}

Clean Binding
    [Arguments]    ${prefix}    ${bindings}    ${node}    ${session}
    [Documentation]    Used for nester FOR loop
    : FOR    ${binding}    IN    @{bindings}
    \    Delete Binding    ${prefix['sgt']}    ${binding['ip-prefix']}    ${node}    ${session}

Get Bindings Master Database
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Gets content of Master DB from node
    ${resp}    RequestsLibrary.Get    ${session}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/master-database/    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Update Binding
    [Arguments]    ${sgtOld}    ${prefixOld}    ${sgtNew}    ${prefixNew}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Updates value of binding via RPC in Master DB of node
    ${DATA}    Update Binding Xml    ${sgtOld}    ${prefixOld}    ${sgtNew}    ${prefixNew}    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:update-entry    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Binding
    [Arguments]    ${sgt}    ${prefix}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete binding via RPC from Master DB of node
    ${DATA}    Delete Binding Xml    ${sgt}    ${prefix}    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:delete-entry    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Add PeerGroup
    [Documentation]    Adds new PeerGroup via RPC to Node
    [Arguments]     ${name}     ${peers}=    ${node}=127.0.0.1       ${session}=session
    ${DATA}    Add Peer Group Xml        ${name}        ${peers}         ${node}
    LOG     ${DATA}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:add-peer-group    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Peer Group
    [Arguments]    ${name}    ${node}=127.0.0.1       ${session}=session
    [Documentation]    Delete PeerGroup via RPC from Node
    ${DATA}    Delete Peer Group Xml        ${name}    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:delete-peer-group    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Get Peer Groups
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Gets all PeerGroups via RPC from node
    ${DATA}    Get Peer Groups From Node Xml    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:get-peer-groups    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Clean Peer Groups
    [Arguments]    ${node}=127.0.0.1       ${session}=session
    [Documentation]    Delete all PeerGroups vie RPC from node
    ${resp}    Get Peer Groups    ${node}   ${session}
    @{prefixes}    Parse Peer Groups    ${resp}
    : FOR    ${group}    IN    @{prefixes}
    \    Delete Peer Group      ${group['name']}    ${node}     ${session}

Add Filter
    [Arguments]    ${name}    ${type}      ${entries}       ${node}=127.0.0.1       ${session}=session
    [Documentation]    Add Filter via RPC from Node
    ${DATA}    Add Filter Xml        ${name}    ${type}    ${entries}   ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:add-filter    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Filter
    [Arguments]    ${name}    ${type}      ${node}=127.0.0.1       ${session}=session
    [Documentation]    Delete Filter via RPC from Node
    ${DATA}    Delete Filter Xml        ${name}    ${type}    ${node}
    ${resp}    RequestsLibrary.Post    ${session}    ${REST_CONTEXT}:delete-filter    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Should Contain Binding
    [Arguments]    ${resp}    ${sgt}    ${prefix}    ${db_source}=local
    [Documentation]    Tests if data contains specified binding
    ${out}    Find Binding    ${resp}    ${sgt}    ${prefix}    ${db_source}    add
    Should Be True    ${out}    Doesn't have ${sgt} ${prefix}
    ${out}    Find Binding    ${resp}    ${sgt}    ${prefix}    ${db_source}    delete
    Should Not Be True    ${out}    Should't have ${sgt} ${prefix}

Should Not Contain Binding
    [Arguments]    ${resp}    ${sgt}    ${prefix}    ${db_source}=local
    [Documentation]    Tests if data doesn't contains specified binding
    ${out}    Find Binding    ${resp}    ${sgt}    ${prefix}    ${db_source}    add
    Should Not Be True    ${out}    Should't have ${sgt} ${prefix}

Should Contain Binding With Peer Sequence
    [Arguments]    ${resp}    ${sgt}    ${prefix}    ${source}    ${seq}=0    ${db_source}=local
    [Documentation]    Tests if data contains specified binding with peer sequence
    ${out}    Find Binding With Peer Sequence    ${resp}    ${sgt}    ${prefix}    ${db_source}    add
    ...    ${source}    ${seq}
    Should Be True    ${out}    Doesn't have ${sgt} ${prefix} ${source} ${seq} ${db_source}

Should Not Contain Binding With Peer Sequence
    [Arguments]    ${resp}    ${sgt}    ${prefix}    ${source}    ${seq}=0    ${db_source}=local
    [Documentation]    Tests if data doesn't contains specified binding with peer sequence
    ${out}    Find Binding With Peer Sequence    ${resp}    ${sgt}    ${prefix}    ${db_source}    add
    ...    ${source}    ${seq}
    Should Not Be True    ${out}    Should't have ${sgt} ${prefix} ${source} ${seq} ${db_source}

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

Setup SXP Environment
    [Documentation]    Create session to Controller
    Verify Feature Is Installed    odl-sxp-all
    Create Session    session    url=http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    15    3    Get Bindings Master Database

Clean SXP Environment
    [Documentation]    Destroy created sessions
    Delete All Sessions
