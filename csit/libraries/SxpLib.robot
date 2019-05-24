*** Settings ***
Documentation     Library containing Keywords used for SXP testing
Library           Collections
Library           RequestsLibrary
Library           ./Sxp.py
Resource          CompareStream.robot
Resource          KarafKeywords.robot
Resource          TemplatedRequests.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot

*** Variables ***
${REST_CONTEXT}    /restconf/operations/sxp-controller

*** Keywords ***
Post To Controller
    [Arguments]    ${session}    ${path}    ${data}    ${rest_context}=${REST_CONTEXT}
    [Documentation]    Post request to Controller and checks response
    ${resp} =    RequestsLibrary.Post Request    ${session}    ${rest_context}:${path}    data=${data}    headers=${HEADERS_XML}
    Log    ${resp.content}
    Log    ${session}
    Log    ${path}
    Log    ${data}
    BuiltIn.Should be Equal As Strings    ${resp.status_code}    200
    ${content} =    BuiltIn.Evaluate    json.loads('''${resp.content}''')    json
    ${output} =    collections.Get From Dictionary    ${content}    output
    ${result} =    collections.Get From Dictionary    ${output}    result
    BuiltIn.Should Be True    ${result}    RPC result is False

Add Node
    [Arguments]    ${node}    ${password}=${EMPTY}    ${version}=version4    ${port}=64999    ${session}=session    ${ip}=${node}
    ...    ${ssl_stores}=${EMPTY}    ${retry_open_timer}=1
    [Documentation]    Add node via RPC to ODL
    ${data} =    Sxp.Add Node Xml    ${node}    ${port}    ${password}    ${version}    ${ip}
    ...    keystores=${ssl_stores}    retry_open_timer=${retry_open_timer}
    Post To Controller    ${session}    add-node    ${data}

Delete Node
    [Arguments]    ${node}    ${session}=session
    [Documentation]    Delete connection via RPC from node
    ${data} =    Sxp.Delete Node Xml    ${node}
    Post To Controller    ${session}    delete-node    ${data}

Add Connection
    [Arguments]    ${version}    ${mode}    ${ip}    ${port}    ${node}=127.0.0.1    ${password}=${EMPTY}
    ...    ${session}=session    ${domain}=global    ${security_mode}=${EMPTY}
    [Documentation]    Add connection via RPC to node
    ${data} =    Sxp.Add Connection Xml    ${version}    ${mode}    ${ip}    ${port}    ${node}
    ...    ${password}    ${domain}    security_mode=${security_mode}
    Post To Controller    ${session}    add-connection    ${data}

Get Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Gets all connections via RPC from node
    ${data} =    Sxp.Get Connections From Node Xml    ${node}    ${domain}
    ${resp} =    RequestsLibrary.Post Request    ${session}    ${REST_CONTEXT}:get-connections    data=${data}    headers=${HEADERS_XML}
    BuiltIn.Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Delete Connections
    [Arguments]    ${ip}    ${port}    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete connection via RPC from node
    ${data} =    Sxp.Delete Connections Xml    ${ip}    ${port}    ${node}    ${domain}
    Post To Controller    ${session}    delete-connection    ${data}

Clean Connections
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global
    [Documentation]    Delete all connections via RPC from node
    ${resp} =    Get Connections    ${node}    ${session}    ${domain}
    @{connections} =    Sxp.Parse Connections    ${resp}
    FOR    ${connection}    IN    @{connections}
        Delete Connections    ${connection['peer-address']}    ${connection['tcp-port']}    ${node}    ${session}    ${domain}
    END

Verify Connection
    [Arguments]    ${version}    ${mode}    ${ip}    ${port}=64999    ${node}=127.0.0.1    ${state}=on
    ...    ${session}=session    ${domain}=global
    [Documentation]    Verify that connection is ON
    ${resp} =    Get Connections    ${node}    ${session}    ${domain}
    Should Contain Connection    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}

Add Bindings
    [Arguments]    ${sgt}    ${prefixes}    ${node}=127.0.0.1    ${session}=session    ${domain}=global    ${origin}=LOCAL
    [Documentation]    Based on ODL version decide if bindings will be added with or without origin type (introduced in Fluorine)
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Add Bindings Fluorine    ${sgt}    ${prefixes}    ${node}    ${session}    ${domain}
    ...    ${origin}
    CompareStream.Run_Keyword_If_At_Most_Oxygen    Add Bindings Oxygen    ${sgt}    ${prefixes}    ${node}    ${session}    ${domain}

Add Bindings Fluorine
    [Arguments]    ${sgt}    ${prefixes}    ${node}    ${session}    ${domain}    ${origin}
    [Documentation]    Add/Update one or more bindings with origin type via RPC to Master DB of the node
    ${data} =    Sxp.Add Bindings Xml Fluorine    ${node}    ${domain}    ${sgt}    ${prefixes}    ${origin}
    Post To Controller    ${session}    add-bindings    ${data}

Add Bindings Oxygen
    [Arguments]    ${sgt}    ${prefixes}    ${node}    ${session}    ${domain}
    [Documentation]    Add/Update one or more bindings without origin type via RPC to Master DB of the node
    ${data} =    Sxp.Add Bindings Xml Oxygen    ${node}    ${domain}    ${sgt}    ${prefixes}
    Post To Controller    ${session}    add-bindings    ${data}

Get Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global    ${scope}=all
    [Documentation]    Gets all binding via RPC from Master DB of node
    ${data} =    Sxp.Get Bindings From Node Xml    ${node}    ${scope}    ${domain}
    ${resp} =    TemplatedRequests.Post_To_Uri    ${REST_CONTEXT}:get-node-bindings    data=${data}    accept=${ACCEPT_JSON}    content_type=${HEADERS_XML}    session=${session}
    [Return]    ${resp}

Clean Bindings
    [Arguments]    ${node}=127.0.0.1    ${session}=session    ${domain}=global    ${scope}=local
    [Documentation]    Delete all bindings via RPC from Master DB of node
    ${resp} =    Get Bindings    ${node}    ${session}    ${domain}    ${scope}
    @{bindings} =    Sxp.Parse Bindings    ${resp}
    FOR    ${binding}    IN    @{bindings}
        @{prefixes_list} =    collections.Get From Dictionary    ${binding}    ip-prefix
        ${prefixes} =    BuiltIn.Catenate    SEPARATOR=,    @{prefixes_list}
        Delete Bindings    ${binding['sgt']}    ${prefixes}    ${node}    ${domain}    ${session}
    END

Delete Bindings
    [Arguments]    ${sgt}    ${prefixes}    ${node}=127.0.0.1    ${domain}=global    ${session}=session
    [Documentation]    Delete one or more bindings via RPC from Master DB of node
    ${data} =    Sxp.Delete Bindings Xml    ${node}    ${domain}    ${sgt}    ${prefixes}
    Post To Controller    ${session}    delete-bindings    ${data}

Add PeerGroup
    [Arguments]    ${name}    ${peers}=    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Adds new PeerGroup via RPC to Node
    ${data} =    Sxp.Add Peer Group Xml    ${name}    ${peers}    ${node}
    Post To Controller    ${session}    add-peer-group    ${data}

Delete Peer Group
    [Arguments]    ${name}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete PeerGroup via RPC from Node
    ${data} =    Sxp.Delete Peer Group Xml    ${name}    ${node}
    Post To Controller    ${session}    delete-peer-group    ${data}

Get Peer Groups
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Gets all PeerGroups via RPC from node
    ${data} =    Sxp.Get Peer Groups From Node Xml    ${node}
    ${resp} =    RequestsLibrary.Post Request    ${session}    ${REST_CONTEXT}:get-peer-groups    data=${data}    headers=${HEADERS_XML}
    BuiltIn.Should be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Clean Peer Groups
    [Arguments]    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete all PeerGroups via RPC from node
    ${resp} =    Get Peer Groups    ${node}    ${session}
    @{prefixes} =    Sxp.Parse Peer Groups    ${resp}
    FOR    ${group}    IN    @{prefixes}
        Delete Peer Group    ${group['name']}    ${node}    ${session}
    END

Add Filter
    [Arguments]    ${name}    ${type}    ${entries}    ${node}=127.0.0.1    ${session}=session    ${policy}=auto-update
    [Documentation]    Add Filter via RPC from Node
    ${data} =    Prepare Add/Update Filter Data    ${name}    ${type}    ${entries}    ${node}    ${policy}
    Post To Controller    ${session}    add-filter    ${data}

Update Filter
    [Arguments]    ${name}    ${type}    ${entries}    ${node}=127.0.0.1    ${session}=session    ${policy}=auto-update
    [Documentation]    Update Filter via RPC
    ${data} =    Prepare Add/Update Filter Data    ${name}    ${type}    ${entries}    ${node}    ${policy}
    Post To Controller    ${session}    update-filter    ${data}

Prepare Add/Update Filter Data
    [Arguments]    ${name}    ${type}    ${entries}    ${node}=127.0.0.1    ${policy}=auto-update
    [Documentation]    Prepare XML payload for add-filter and update-filter RPCs. Payloads for both RPCs are the same.
    ${data} =    CompareStream.Run_Keyword_If_At_Least_Else    carbon    Add Filter Xml    ${name}    ${type}    ${entries}
    ...    ${node}    ${policy}
    ...    ELSE    Add Filter Xml    ${name}    ${type}    ${entries}    ${node}
    [Return]    ${data}

Add Domain Filter
    [Arguments]    ${name}    ${domains}    ${entries}    ${node}=127.0.0.1    ${filter_name}=base-domain-filter    ${session}=session
    [Documentation]    Add Domain Filter via RPC from Node
    ${data} =    Sxp.Add Domain Filter Xml    ${name}    ${domains}    ${entries}    ${node}    ${filter_name}
    Post To Controller    ${session}    add-domain-filter    ${data}

Delete Filter
    [Arguments]    ${name}    ${type}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete Filter via RPC from Node
    ${data} =    Sxp.Delete Filter Xml    ${name}    ${type}    ${node}
    Post To Controller    ${session}    delete-filter    ${data}

Delete Domain Filter
    [Arguments]    ${name}    ${node}=127.0.0.1    ${filter_name}=base-domain-filter    ${session}=session
    [Documentation]    Delete Filter via RPC from Node
    ${data} =    Sxp.Delete Domain Filter Xml    ${name}    ${node}    ${filter_name}
    Post To Controller    ${session}    delete-domain-filter    ${data}

Should Contain Binding
    [Arguments]    ${resp}    ${sgt}    ${prefix}
    [Documentation]    Tests if data contains specified binding
    ${out} =    Sxp.Find Binding    ${resp}    ${sgt}    ${prefix}
    BuiltIn.Should Be True    ${out}    Doesn't have ${sgt} ${prefix}

Should Not Contain Binding
    [Arguments]    ${resp}    ${sgt}    ${prefix}
    [Documentation]    Tests if data doesn't contains specified binding
    ${out} =    Sxp.Find Binding    ${resp}    ${sgt}    ${prefix}
    BuiltIn.Should Not Be True    ${out}    Should't have ${sgt} ${prefix}

Should Contain Connection
    [Arguments]    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}=none
    [Documentation]    Test if data contains specified connection
    ${out} =    Sxp.Find Connection    ${resp}    ${version}    ${mode}    ${ip}    ${port}
    ...    ${state}
    BuiltIn.Should Be True    ${out}    Doesn't have ${ip}:${port} ${mode} ${version} in state ${state}

Should Not Contain Connection
    [Arguments]    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}=none
    [Documentation]    Test if data doesn't contains specified connection
    ${out} =    Sxp.Find Connection    ${resp}    ${version}    ${mode}    ${ip}    ${port}
    ...    ${state}
    BuiltIn.Should Not Be True    ${out}    Shouldn't have ${ip}:${port} ${mode} ${version}

Bindings Should Contain
    [Arguments]    ${sgt}    ${prefix}    ${domain}=global    ${scope}=all
    [Documentation]    Retrieves bindings and verifies they contain given binding
    ${resp} =    Get Bindings    domain=${domain}    scope=${scope}
    Should Contain Binding    ${resp}    ${sgt}    ${prefix}

Bindings Should Not Contain
    [Arguments]    ${sgt}    ${prefix}    ${domain}=global    ${scope}=all
    [Documentation]    Retrieves bindings and verifies they do not contain given binding
    ${resp} =    Get Bindings    domain=${domain}    scope=${scope}
    Should Not Contain Binding    ${resp}    ${sgt}    ${prefix}

Connections Should Contain
    [Arguments]    ${ip}    ${port}    ${mode}    ${version}    ${state}=none
    [Documentation]    Retrieves connections and verifies they contain given connection
    ${resp} =    Get Connections
    Should Contain Connection    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}

Connections Should Not Contain
    [Arguments]    ${ip}    ${port}    ${mode}    ${version}    ${state}=none
    [Documentation]    Retrieves connections and verifies they do not contain given connection
    ${resp} =    Get Connections
    Should Not Contain Connection    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}

Setup Topology Complex
    [Arguments]    ${version}=version4    ${password}=none
    FOR    ${node}    IN RANGE    2    6
        Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.${node}
        ...    ${password}
        Add Connection    ${version}    both    127.0.0.${node}    64999    127.0.0.1
        ...    ${password}
        BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both
        ...    127.0.0.${node}
        Add Bindings    ${node}0    10.10.10.${node}0/32    127.0.0.${node}
        Add Bindings    ${node}0    10.10.${node}0.0/24    127.0.0.${node}
        Add Bindings    ${node}0    10.${node}0.0.0/16    127.0.0.${node}
        Add Bindings    ${node}0    ${node}0.0.0.0/8    127.0.0.${node}
    END
    Add Bindings    10    10.10.10.10/32    127.0.0.1
    Add Bindings    10    10.10.10.0/24    127.0.0.1
    Add Bindings    10    10.10.0.0/16    127.0.0.1
    Add Bindings    10    10.0.0.0/8    127.0.0.1

Verify Snapshot Was Pushed
    [Arguments]    ${snapshot_string}=22-sxp-controller-one-node.xml
    [Documentation]    Will succeed if the ${snapshot_string} is found in the karaf logs
    ${output} =    Utils.Run Command On Controller    ${ODL_SYSTEM_IP}    cat ${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log* | grep -c 'Successfully pushed configuration snapshot.*${snapshot_string}'
    BuiltIn.Should Not Be Equal As Strings    ${output}    0

Add Domain
    [Arguments]    ${domain_name}    ${sgt}=None    ${prefixes}=None    ${origin}=LOCAL    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Based on ODL version decide if domain's bindings will be added with or without origin type (introduced in Fluorine)
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Add Domain Fluorine    ${domain_name}    ${sgt}    ${prefixes}    ${origin}    ${node}
    ...    ${session}
    CompareStream.Run_Keyword_If_At_Most_Oxygen    Add Domain Oxygen    ${domain_name}    ${sgt}    ${prefixes}    ${node}    ${session}

Add Domain Fluorine
    [Arguments]    ${domain_name}    ${sgt}    ${prefixes}    ${origin}    ${node}    ${session}
    [Documentation]    Add Domain with bindings (with origin) via RPC
    ${data} =    Sxp.Add Domain Xml Fluorine    ${node}    ${domain_name}    ${sgt}    ${prefixes}    ${origin}
    Post To Controller    ${session}    add-domain    ${data}

Add Domain Oxygen
    [Arguments]    ${domain_name}    ${sgt}    ${prefixes}    ${node}    ${session}
    [Documentation]    Add Domain with bindings (without origin) via RPC
    ${data} =    Sxp.Add Domain Xml Oxygen    ${node}    ${domain_name}    ${sgt}    ${prefixes}
    Post To Controller    ${session}    add-domain    ${data}

Delete Domain
    [Arguments]    ${domain_name}    ${node}=127.0.0.1    ${session}=session
    [Documentation]    Delete Domain via RPC
    ${data} =    Sxp.Delete Domain Xml    ${node}    ${domain_name}
    Post To Controller    ${session}    delete-domain    ${data}

Add Bindings Range
    [Arguments]    ${sgt}    ${start}    ${size}    ${node}=127.0.0.1
    [Documentation]    Add Bindings to Node specified by range
    ${prefixes} =    Sxp.Prefix Range    ${start}    ${size}
    Add Bindings    ${sgt}    ${prefixes}    ${node}

Delete Bindings Range
    [Arguments]    ${sgt}    ${start}    ${size}    ${node}=127.0.0.1
    [Documentation]    Delete Bindings to Node specified by range
    ${prefixes} =    Sxp.Prefix Range    ${start}    ${size}
    Delete Bindings    ${sgt}    ${prefixes}    ${node}

Check Binding Range
    [Arguments]    ${sgt}    ${start}    ${end}    ${node}=127.0.0.1
    [Documentation]    Check if Node contains Bindings specified by range
    ${resp} =    Get Bindings    ${node}
    FOR    ${num}    IN RANGE    ${start}    ${end}
        ${ip} =    Sxp.Get Ip From Number    ${num}
        Should Contain Binding    ${resp}    ${sgt}    ${ip}/32
    END

Check Binding Range Negative
    [Arguments]    ${sgt}    ${start}    ${end}    ${node}=127.0.0.1
    [Documentation]    Check if Node does not contains Bindings specified by range
    ${resp} =    Get Bindings    ${node}
    FOR    ${num}    IN RANGE    ${start}    ${end}
        ${ip} =    Sxp.Get Ip From Number    ${num}
        Should Not Contain Binding    ${resp}    ${sgt}    ${ip}/32
    END

Setup SXP Environment
    [Arguments]    ${node_range}=1
    [Documentation]    Create session to Controller, ${node_range} parameter specifies number of localhost nodes to be created on ${ODL_SYSTEM_IP}.
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    timeout=${DEFAULT_TIMEOUT_HTTP}    max_retries=0
    FOR    ${num}    IN RANGE    1    ${node_range}+1
        ${node} =    Sxp.Get Ip From Number    ${num}
        Add Node    ${node}    retry_open_timer=${num}
        BuiltIn.Wait Until Keyword Succeeds    20    1    Check Node Started    ${node}    system=${ODL_SYSTEM_IP}
    END

Check Node Started
    [Arguments]    ${node}    ${port}=64999    ${system}=${node}    ${session}=session    ${ip}=${node}
    [Documentation]    Verify that SxpNode has data writen to Operational datastore and is running
    ${resp} =    RequestsLibrary.Get Request    ${session}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    ${rc} =    Get Node Running Status    ${node}    ${port}    ${system}    ${session}    ${ip}
    BuiltIn.Should Be Equal As Strings    ${rc}    0

Check Node Stopped
    [Arguments]    ${node}    ${port}=64999    ${system}=${node}    ${session}=session    ${ip}=${node}
    [Documentation]    Verify that SxpNode has data removed from Operational datastore and is not running
    ${resp} =    RequestsLibrary.Get Request    ${session}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    404
    ${rc} =    Get Node Running Status    ${node}    ${port}    ${system}    ${session}    ${ip}
    BuiltIn.Should Be Equal As Strings    ${rc}    1

Get Node Running Status
    [Arguments]    ${node}    ${port}    ${system}    ${session}    ${ip}
    [Documentation]    Get status if node is running by checking that netty server is running
    ${rc} =    Utils.Run Command On Remote System    ${system}    netstat -tln | grep -q ${ip}:${port} && echo 0 || echo 1    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}    prompt=${ODL_SYSTEM_PROMPT}
    [Return]    ${rc}

Clean SXP Environment
    [Arguments]    ${node_range}=1
    [Documentation]    Destroy created sessions
    FOR    ${num}    IN RANGE    1    ${node_range}+1
        ${ip} =    Sxp.Get Ip From Number    ${num}
        Delete Node    ${ip}
        BuiltIn.Wait Until Keyword Succeeds    12x    10s    Check Node Stopped    ${ip}    system=${ODL_SYSTEM_IP}
    END
    RequestsLibrary.Delete All Sessions

Get Routing Configuration From Controller
    [Arguments]    ${session}
    [Documentation]    Get Routing configuration from config DS
    ${resp} =    RequestsLibrary.Get Request    ${session}    /restconf/config/sxp-cluster-route:sxp-cluster-route/    headers=${ACCEPT_XML}
    ${data} =    BuiltIn.Set Variable If    "${resp.status_code}" == "200"    ${resp.content}    ${EMPTY}
    [Return]    ${data}

Put Routing Configuration To Controller
    [Arguments]    ${data}    ${session}
    [Documentation]    Put Routing configuration to Config DS
    ${resp} =    RequestsLibrary.Put Request    ${session}    /restconf/config/sxp-cluster-route:sxp-cluster-route/    data=${data}    headers=${HEADERS_XML}
    BuiltIn.Log    ${resp}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"

Clean Routing Configuration To Controller
    [Arguments]    ${session}
    [Documentation]    Delete Routing configuration from Config DS
    ${resp} =    RequestsLibrary.Get Request    ${session}    /restconf/config/sxp-cluster-route:sxp-cluster-route/    headers=${ACCEPT_XML}
    BuiltIn.Run Keyword If    "${resp.status_code}" == "200"    RequestsLibrary.Delete Request    ${session}    /restconf/config/sxp-cluster-route:sxp-cluster-route/
