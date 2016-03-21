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
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-connection    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp}
    Should be Equal As Strings    ${resp.status_code}    200

Get Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Gets all connections via RPC from node
    ${DATA}    Get Connections From Node Xml    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:get-connections    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Delete Connections
    [Arguments]    ${ip}    ${port}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete connection via RPC from node
    ${DATA}    Delete Connections Xml    ${ip}    ${port}    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-connection    data=${DATA}    headers=${HEADERS_XML}
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
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-entry    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Get Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Gets all binding via RPC from Master DB of node
    ${DATA}    Get Bindings From Node Xml    ${node}    all
    ${resp}    Run Keyword If    '${ODL_STREAM}' == 'boron'    Post Request    ${session}    ${REST_CONTEXT}:get-node-bindings    data=${DATA}
    ...    headers=${HEADERS_XML}
    ...    ELSE    Get Request    ${session}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/master-database/    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Clean Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete all bindings via RPC from Master DB of node
    ${resp}    Get Bindings    ${node}    ${session}
    @{bindings}    Run Keyword If    '${ODL_STREAM}' == 'boron'    Parse Bindings    ${resp}
    ...    ELSE    Parse Prefix Groups    ${resp}    local
    : FOR    ${binding}    IN    @{bindings}
    \    Run Keyword If    '${ODL_STREAM}' == 'boron'    Clean Binding    ${binding['sgt']}    ${binding['ip-prefix']}    ${node}
    \    ...    ${session}
    \    ...    ELSE    Clean Binding    ${binding}    ${binding['binding']}    ${node}
    \    ...    ${session}

Clean Binding
    [Arguments]    ${sgt}    ${prefixes}    ${node}    ${session}
    [Documentation]    Used for nester FOR loop
    : FOR    ${prefix}    IN    @{prefixes}
    \    Run Keyword If    '${ODL_STREAM}' == 'boron'    Delete Binding    ${sgt}    ${prefix}    ${node}
    \    ...    ${session}
    \    ...    ELSE    Delete Binding    ${sgt['sgt']}    ${prefix['ip-prefix']}    ${node}
    \    ...    ${session}

Update Binding
    [Arguments]    ${sgtOld}    ${prefixOld}    ${sgtNew}    ${prefixNew}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Updates value of binding via RPC in Master DB of node
    ${DATA}    Update Binding Xml    ${sgtOld}    ${prefixOld}    ${sgtNew}    ${prefixNew}    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:update-entry    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Binding
    [Arguments]    ${sgt}    ${prefix}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete binding via RPC from Master DB of node
    ${DATA}    Delete Binding Xml    ${sgt}    ${prefix}    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-entry    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Add PeerGroup
    [Arguments]    ${name}    ${peers}=    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Adds new PeerGroup via RPC to Node
    ${DATA}    Add Peer Group Xml    ${name}    ${peers}    ${node}
    LOG    ${DATA}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-peer-group    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Peer Group
    [Arguments]    ${name}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete PeerGroup via RPC from Node
    ${DATA}    Delete Peer Group Xml    ${name}    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-peer-group    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

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
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-filter    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Filter
    [Arguments]    ${name}    ${type}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete Filter via RPC from Node
    ${DATA}    Delete Filter Xml    ${name}    ${type}    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-filter    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Should Contain Binding
    [Arguments]    ${resp}    ${sgt}    ${prefix}    ${db_source}=any
    [Documentation]    Tests if data contains specified binding
    ${out}    Run Keyword If    '${ODL_STREAM}' == 'boron'    Find Binding    ${resp}    ${sgt}    ${prefix}
    ...    ELSE    Find Binding Legacy    ${resp}    ${sgt}    ${prefix}    ${db_source}
    ...    add
    Should Be True    ${out}    Doesn't have ${sgt} ${prefix}

Should Not Contain Binding
    [Arguments]    ${resp}    ${sgt}    ${prefix}    ${db_source}=any
    [Documentation]    Tests if data doesn't contains specified binding
    ${out}    Run Keyword If    '${ODL_STREAM}' == 'boron'    Find Binding    ${resp}    ${sgt}    ${prefix}
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

Setup SXP Environment
    [Documentation]    Create session to Controller
    Verify Feature Is Installed    odl-sxp-all
    Create Session    session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    15    1    Get Bindings

Clean SXP Environment
    [Documentation]    Destroy created sessions
    Delete All Sessions
