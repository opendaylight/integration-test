*** Settings ***
Documentation     Library containing Keywords used for SXP testing
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ./Sxp.py
Resource          KarafKeywords.robot
Variables         ../variables/Variables.py

*** Variables ***
${REST_CONTEXT}    /restconf/operations/sxp-controller

*** Keywords ***
Add Node
    [Arguments]    ${node}    ${password}=password    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Add node via RPC to ODL
    ${DATA}    Add Node Xml    ${node}    ${port}    ${password}    ${version}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-node    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Node
    [Arguments]    ${node}    ${session}=session
    [Documentation]    Delete connection via RPC from node
    ${DATA}    Delete Node Xml    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-node    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Add Connection
    [Arguments]    ${version}    ${mode}    ${ip}    ${port}    ${node}=127.0.0.1    ${password}=none
    ...    ${session}=session    ${domain}=global
    [Documentation]    Add connection via RPC to node
    ${DATA}    Add Connection Xml    ${version}    ${mode}    ${ip}    ${port}    ${node}
    ...    ${password}    ${domain}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-connection    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp}
    Should be Equal As Strings    ${resp.status_code}    200

Get Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Gets all connections via RPC from node
    ${DATA}    Get Connections From Node Xml    ${node}    ${domain}
    LOG    ${DATA}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:get-connections    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Delete Connections
    [Arguments]    ${ip}    ${port}    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete connection via RPC from node
    ${DATA}    Delete Connections Xml    ${ip}    ${port}    ${node}    ${domain}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-connection    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Clean Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete all connections via RPC from node
    ${resp}    Get Connections    ${node}    ${session}    ${domain}
    @{connections}    Parse Connections    ${resp}
    : FOR    ${connection}    IN    @{connections}
    \    delete connections    ${connection['peer-address']}    ${connection['tcp-port']}    ${node}    ${session}

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
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-entry    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Get Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Gets all binding via RPC from Master DB of node
    ${DATA}    Get Bindings From Node Xml    ${node}    all    ${domain}
    ${resp}    Run Keyword If    '${ODL_STREAM}' == 'boron'    Post Request    ${session}    ${REST_CONTEXT}:get-node-bindings    data=${DATA}
    ...    headers=${HEADERS_XML}
    ...    ELSE    Get Request    ${session}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/master-database/    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Clean Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete all bindings via RPC from Master DB of node
    ${resp}    Get Bindings    ${node}    ${session}    ${domain}
    @{bindings}    Run Keyword If    '${ODL_STREAM}' == 'boron'    Parse Bindings    ${resp}
    ...    ELSE    Parse Prefix Groups    ${resp}    local
    : FOR    ${binding}    IN    @{bindings}
    \    Run Keyword If    '${ODL_STREAM}' == 'boron'    Clean Binding    ${binding['sgt']}    ${binding['ip-prefix']}    ${node}
    \    ...    ${session}    ${domain}
    \    ...    ELSE    Clean Binding    ${binding}    ${binding['binding']}    ${node}
    \    ...    ${session}    ${domain}

Clean Binding
    [Arguments]    ${sgt}    ${prefixes}    ${node}    ${session}    ${domain}=global
    [Documentation]    Used for nester FOR loop
    : FOR    ${prefix}    IN    @{prefixes}
    \    Run Keyword If    '${ODL_STREAM}' == 'boron'    Delete Binding    ${sgt}    ${prefix}    ${node}
    \    ...    ${session}    ${domain}
    \    ...    ELSE    Delete Binding    ${sgt['sgt']}    ${prefix['ip-prefix']}    ${node}
    \    ...    ${session}    ${domain}

Update Binding
    [Arguments]    ${sgtOld}    ${prefixOld}    ${sgtNew}    ${prefixNew}    ${node}=127.0.0.1    ${session}=session
    ...    ${domain}=global
    [Documentation]    Updates value of binding via RPC in Master DB of node
    ${DATA}    Update Binding Xml    ${sgtOld}    ${prefixOld}    ${sgtNew}    ${prefixNew}    ${node}
    ...    ${domain}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:update-entry    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Binding
    [Arguments]    ${sgt}    ${prefix}    ${node}=127.0.0.1    ${domain}=global    ${session}=session
    [Documentation]    Delete binding via RPC from Master DB of node
    ${DATA}    Delete Binding Xml    ${sgt}    ${prefix}    ${node}    ${domain}
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

Add Domain Filter
    [Arguments]    ${name}    ${domains}    ${entries}    ${node}=127.0.0.1    ${filter_name}=base-domain-filter    ${session}=session
    [Documentation]    Add Domain Filter via RPC from Node
    ${DATA}    Add Domain Filter Xml    ${name}    ${domains}    ${entries}    ${node}    ${filter_name}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-domain-filter    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Filter
    [Arguments]    ${name}    ${type}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete Filter via RPC from Node
    ${DATA}    Delete Filter Xml    ${name}    ${type}    ${node}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-filter    data=${DATA}    headers=${HEADERS_XML}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Domain Filter
    [Arguments]    ${name}    ${node}=127.0.0.1    ${filter_name}=base-domain-filter    ${session}=session
    [Documentation]    Delete Filter via RPC from Node
    ${DATA}    Delete Domain Filter Xml    ${name}    ${node}    ${filter_name}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-domain-filter    data=${DATA}    headers=${HEADERS_XML}
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

Setup SXP Sesion
    [Documentation]    Create session to Controller
    Verify Feature Is Installed    odl-sxp-controller
    Wait Until Keyword Succeeds    20    10    Check Karaf Log Has Messages    Successfully pushed configuration snapshot 22-sxp-controller-one-node.xml
    Create Session    session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${resp}    RequestsLibrary.Get Request    session    ${MODULES_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf

Clean SXP Sesion
    [Documentation]    Destroy created sessions
    Delete All Sessions

Add Domain
    [Arguments]    ${domain_name}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Add Domain via RPC
    ${DATA}    Add Domain Xml    ${node}    ${domain_name}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-domain    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Domain
    [Arguments]    ${domain_name}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete Domain via RPC
    ${DATA}    Delete Domain Xml    ${node}    ${domain_name}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-domain    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Add Bindings
    [Arguments]    ${sgt}    ${prefixes}    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Add bindings via RPC to Master DB of node
    ${DATA}    Add Bindings Xml    ${node}    ${domain}    ${sgt}    ${prefixes}
    LOG    ${DATA}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:add-bindings    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Delete Bindings
    [Arguments]    ${sgt}    ${prefixes}    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete bindings via RPC from Master DB of node
    ${DATA}    Delete Bindings Xml    ${node}    ${domain}    ${sgt}    ${prefixes}
    ${resp}    Post Request    ${session}    ${REST_CONTEXT}:delete-bindings    data=${DATA}    headers=${HEADERS_XML}
    LOG    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

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
    LOG    ${resp}
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
    [Documentation]    Create session to Controller
    Setup SXP Sesion
    : FOR    ${num}    IN RANGE    1    ${node_range}
    \    ${ip}    Get Ip From Number    ${num}
    \    Run Keyword If    '${ODL_STREAM}' == 'boron'    Add Node    ${ip}
    \    Run Keyword If    '${ODL_STREAM}' == 'boron'    Wait Until Keyword Succeeds    20    1    Check Node Started
    \    ...    ${ip}

Check Node Started
    [Arguments]    ${node}    ${port}=64999    ${system}=${ODL_SYSTEM_IP}
    [Documentation]    Verify that SxpNode has data writed to Operational datastore
    ${resp}    RequestsLibrary.Get Request    session    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${rc}    Run and Return RC    netstat -tln | grep -q ${node}:${port}
    should be equal as integers    ${rc}    0

Clean SXP Environment
    [Arguments]    ${node_range}=2
    [Documentation]    Destroy created sessions
    : FOR    ${num}    IN RANGE    1    ${node_range}
    \    ${ip}    Get Ip From Number    ${num}
    \    Run Keyword If    '${ODL_STREAM}' == 'boron'    Delete Node    ${ip}
    Clean SXP Sesion
