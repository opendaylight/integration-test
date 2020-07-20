*** Settings ***
Documentation    This suite mount testtool onto ODL via jsonrpc and then performs CRUD operations on mountpoint.
...
...              IETF Topology model was chosen because it's well know to most of people working with ODL and
...              it is available out-of-box in most installations.

Suite Setup           Initialize
Suite Teardown        Destroy
Resource          ../../libraries/JsonrpcKeywords.robot

*** Variables ***
${mp_name}            test
${topology_name}      topology-1

*** Test Cases ***
Put Get Delete
    [Documentation]    Create network topology in config datastore and verify its existence under mount point using RESTConf.
    ...    Link nodes in topology and ensure that correct links exists. Then remove links and nodes and
    ...    verify that data are not present.Use restconf PUT/GET/DELETE operations (no merge will occur on databroker level).
    ...
    ...    Note that delete operation can't be validated on mountpoint currently. JSONRPC will report empty
    ...    JSON container even for objects that don't exists, which in turn prevent restconf to report HTTP409.
    [Setup]    Create Topology    mount_point=${mp_name}
    [Teardown]    Delete Topology    mount_point=${mp_name}
    Create Node    node1    mount_point=${mp_name}
    Create Node    node2    2    mount_point=${mp_name}
    Create Node    node3    3    mount_point=${mp_name}
    Link Nodes    node1    node2    mount_point=${mp_name}
    Link Nodes    node2    node3    mount_point=${mp_name}
    Link Nodes    node3    node1    mount_point=${mp_name}
    ${topo}=    Read Topology    mount_point=${mp_name}
    ${nodes}=    Get Length    ${topo['node']}
    ${links}=    Get Length    ${topo['link']}
    Builtin.Should Be Equal As Integers    3    ${nodes}
    Builtin.Should Be Equal As Integers    3    ${links}
    Unlink Nodes    node1    node2    mount_point=${mp_name}
    Unlink Nodes    node2    node3    mount_point=${mp_name}
    Unlink Nodes    node3    node1    mount_point=${mp_name}
    Delete Node    node1    mount_point=${mp_name}
    Delete Node    node2    mount_point=${mp_name}
    Delete Node    node3    mount_point=${mp_name}

Factorial via RPC
    [Documentation]     Call RPC method 'factorial' on mountpoint and evaluate result.
    ...     Test tool implements simple factorial calculation via RPC.
    ${uri}=     Builtin.Catenate    SEPARATOR=/    restconf/operations/jsonrpc:config/configured-endpoints
    ...     ${mp_name}    yang-ext:mount/test-model:factorial
    &{inner}=     Builtin.Create Dictionary     in-number=5
    &{outer}=     Builtin.Create Dictionary   input=${inner}
    ${data}=      Json.Dumps    ${outer}
    ${result}=    TemplatedRequests.Post_As_Json_To_Uri    ${uri}     ${data}
    ${data}=    Json.Loads    ${result}
    ${val}=    Builtin.Get Variable Value    ${data['output']['out-number']}
    # Factorial of 5 is 120
    Should Be Equal As Integers   ${val}    120

*** Keywords ***
Get Config Path
    [Documentation]    Construct path within config datastore according to given arguments.
    [Arguments]    ${path}=${EMPTY_STR}    ${mount_point}=${EMPTY}
    ${prefix}=    Run Keyword Unless    "${mount_point}"=="${EMPTY}"    Builtin.Catenate    SEPARATOR=/
    ...    jsonrpc:config    configured-endpoints    ${mount_point}    yang-ext:mount
    ${prefix}=    Set Variable If    "${mount_point}"=="${EMPTY}"    ${EMPTY}    ${prefix}
    ${result}=    Builtin.Catenate    SEPARATOR=/    restconf/config    ${prefix}    ${path}
    [Return]    ${result}

Create Topology
    [Documentation]    Create instance of network-topology with given name
    [Arguments]    ${topo_name}=${topology_name}        ${mount_point}=${EMPTY}
    ${path}=    Builtin.Catenate    SEPARATOR=/    network-topology:network-topology
    ${uri}=    Get Config Path    ${path}    ${mount_point}
    &{topo}=    Builtin.Create Dictionary    topology-id=${topo_name}
    @{topo_list}=    Builtin.Create List    ${topo}
    &{nt}=    Builtin.Create Dictionary    topology=${topo_list}
    &{outer}=    Builtin.Create Dictionary    network-topology    ${nt}
    ${data}=    Json.Dumps    ${outer}
    TemplatedRequests.Put_As_Json_To_Uri    ${uri}      ${data}

Delete Topology
    [Documentation]    Remove given network topology
    [Arguments]    ${topo_name}=${topology_name}        ${mount_point}=${EMPTY}
    ${path}=    Builtin.Catenate    SEPARATOR=/    network-topology:network-topology    topology    ${topo_name}
    ${uri}=    Get Config Path    ${path}    ${mount_point}
    TemplatedRequests.Delete_From_Uri   uri=${uri}    additional_allowed_status_codes=${DELETED_STATUS_CODES}

Read Topology
    [Documentation]    Read entire topology
    [Arguments]    ${topo_name}=${topology_name}        ${mount_point}=${EMPTY}
    ${path}=    Builtin.Catenate    SEPARATOR=/    network-topology:network-topology    topology    ${topo_name}
    ${uri}=    Get Config Path    ${path}    ${mount_point}
    ${resp}=    TemplatedRequests.Get_As_Json_From_Uri    ${uri}
    ${data}=    Json.Loads    ${resp}
    [Return]    ${data['topology'][0]}

Create Node Object
    [Documentation]    Create node object that can be used by other KWs
    [Arguments]    ${node_name}    ${tp_count}=1
    @{tp_list}=    Builtin.Create List
    FOR    ${tp_index}    IN RANGE    0    ${tp_count}
        &{tp}=    Builtin.Create Dictionary    network-topology:tp-id=eth${tp_index}
        Collections.Append To List    ${tp_list}    ${tp}
    END
    &{node}=    Builtin.Create Dictionary    network-topology:node-id=${node_name}    network-topology:termination-point=${tp_list}
    [Return]    ${node}

Post Node
    [Documentation]    Create node using POST
    [Arguments]    ${node_name}    ${tp_count}=1    ${mount_point}=${EMPTY}    ${topo_name}=${topology_name}
    ${uri}=    Get Topology Object Path    node    ${node_name}    topo_name=${topo_name}    mount_point=${mount_point}
    &{node}=    Create Node Object    node_name=${node_name}    tp_count=${tp_count}
    Collections.Remove From Dictionary    ${node}    network-topology:node-id
    ${data}=    Json.Dumps    ${node}
    ControllerSimpleRest.Do Controller Post Expect Success    ${uri}    ${data}
    Ensure Node Exists    ${node_name}    mount_point=${mount_point}    topo_name=${topology_name}    should_exists=${True}

Create Node
    [Documentation]    Create node in topology with specified number of termination points
    [Arguments]    ${node_name}    ${tp_count}=1    ${mount_point}=${EMPTY}    ${topo_name}=${topology_name}
    ${uri}=    Get Topology Object Path    node    ${node_name}    topo_name=${topo_name}    mount_point=${mount_point}
    &{node}=    Create Node Object    node_name=${node_name}    tp_count=${tp_count}
    @{node_list}=    Builtin.Create List    ${node}
    &{outer}=    Builtin.Create Dictionary    network-topology:node=${node_list}
    ${data}=    Json.Dumps    ${outer}
    TemplatedRequests.Put_As_Json_To_Uri    ${uri}      ${data}
    Ensure Node Exists    ${node_name}    mount_point=${mount_point}    topo_name=${topology_name}    should_exists=${True}

Delete Node
    [Documentation]    Delete node from topology and verify it is gone
    [Arguments]    ${node_name}    ${mount_point}=${EMPTY}    ${topo_name}=${topology_name}
    ${uri}=    Get Topology Object Path    node    ${node_name}    topo_name=${topo_name}    mount_point=${mount_point}
    TemplatedRequests.Delete_From_Uri   uri=${uri}    additional_allowed_status_codes=${DELETED_STATUS_CODES}
    Ensure Node Exists    ${node_name}    mount_point=${mount_point}    topo_name=${topology_name}    should_exists=${False}

Link Nodes
    [Documentation]    Link termination points of two nodes in topology.
    [Arguments]    ${node1}    ${node2}    ${tp1}=eth0    ${tp2}=eth0    ${mount_point}=${EMPTY}    ${topo_name}=${topology_name}
    ${link_id}=    Builtin.Catenate    SEPARATOR=_    ${node1}    ${tp1}    to    ${node2}    ${tp2}
    ${uri}=    Get Topology Object Path    link    ${link_id}    topo_name=${topo_name}    mount_point=${mount_point}
    &{outer}=    Builtin.Create Dictionary
    @{link_list}=    Builtin.Create List
    Collections.Set To Dictionary    ${outer}    network-topology:link    ${link_list}
    &{link}=    Builtin.Create Dictionary
    Collections.Append To List    ${link_list}    ${link}
    Collections.Set To Dictionary    ${link}    network-topology:link-id    ${link_id}
    &{source_node}=    Builtin.Create Dictionary
    &{dest_node}=    Builtin.Create Dictionary
    Collections.Set To Dictionary    ${source_node}    network-topology:source-node    ${node1}
    Collections.Set To Dictionary    ${source_node}    network-topology:source-tp    ${tp1}
    Collections.Set To Dictionary    ${dest_node}    network-topology:dest-node    ${node2}
    Collections.Set To Dictionary    ${dest_node}    network-topology:dest-tp    ${tp2}
    Collections.Set To Dictionary    ${link}    network-topology:source    ${source_node}
    Collections.Set To Dictionary    ${link}    network-topology:destination    ${dest_node}
    ${data}=    Json.Dumps    ${outer}
    TemplatedRequests.Put_As_Json_To_Uri    ${uri}      ${data}

Unlink Nodes
    [Documentation]    Remove link between 2 termination points in topology and verify that link is removed afterwards.
    [Arguments]    ${node1}    ${node2}    ${tp1}=eth0    ${tp2}=eth0    ${mount_point}=${EMPTY}    ${topo_name}=${topology_name}
    ${link_id}=    Builtin.Catenate    SEPARATOR=_    ${node1}    ${tp1}    to    ${node2}    ${tp2}
    ${uri}=    Get Topology Object Path    link    ${link_id}    topo_name=${topo_name}    mount_point=${mount_point}
    TemplatedRequests.Delete_From_Uri   uri=${uri}    additional_allowed_status_codes=${DELETED_STATUS_CODES}
    Ensure Link Exists    ${node1}    ${node2}    ${tp1}    ${tp2}    mount_point=${mount_point}
    ...    topo_name=${topology_name}    should_exists=${False}

Ensure Link Exists
    [Documentation]    Verify that link between 2 termination points in topology exists or not.
    [Arguments]    ${node1}    ${node2}    ${tp1}=eth0    ${tp2}=eth0    ${mount_point}=${EMPTY}
    ...    ${topo_name}=${topology_name}    ${should_exists}=${True}
    ${link_id}=    Builtin.Catenate    SEPARATOR=_    ${node1}    ${tp1}    to    ${node2}    ${tp2}
    ${uri}=    Get Topology Object Path    link    ${link_id}    topo_name=${topo_name}    mount_point=${mount_point}
    ${status_code}=    Set Variable If    "${should_exists}"=="${True}"    200    409
    ${response}=    RequestsLibrary.Get Request    default    ${uri}
    #TODO : This should be changed in jsonrpc. It returns '{}' even for non-existing data
    #Builtin.Should Be Equal As Integers    ${response.status_code}    ${status_code}

Ensure Node Exists
    [Documentation]    Verify that given node is present in topology (or not)
    [Arguments]    ${node_name}   ${mount_point}=${EMPTY}    ${topo_name}=${topology_name}    ${should_exists}=${True}
    ${uri}=    Get Topology Object Path    node    ${node_name}    topo_name=${topo_name}    mount_point=${mount_point}
    ${status_code}=    Set Variable If    "${should_exists}"=="${True}"    200    409
    ${response}=    RequestsLibrary.Get Request    default    ${uri}
    #TODO : This should be changed in jsonrpc. It returns '{}' even for non-existing data
    #Builtin.Should Be Equal As Integers    ${response.status_code}    ${status_code}

Get Topology Object Path
    [Documentation]    Get URI path for given topology object (node or link)
    [Arguments]    ${obj_type}    ${name}    ${topo_name}=${topology_name}    ${mount_point}=${EMPTY}
    ${path}=    Builtin.Catenate    SEPARATOR=/    network-topology:network-topology    topology
    ...    ${topo_name}    ${obj_type}    ${name}
    ${uri}=    Get Config Path    ${path}    ${mount_point}
    [Return]    ${uri}

Initialize
    [Documentation]    Prepare controller for this suite
    ClusterManagement.ClusterManagement_Setup
    ${testtool}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${testtool}    ${testtool}
    SSHLibrary.Switch_Connection    ${testtool}
    RequestsLibrary.Create_Session    default    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    JsonrpcKeywords.Install_And_Start_Testtool
    JsonrpcKeywords.Unconfigure JSONRPC
    ${gov}=     JsonrpcKeywords.Replace Endpoint Address    ${TESTTOOL_GOV_ENDPOINT}    ${TOOLS_SYSTEM_IP}
    ${rpc}=     JsonrpcKeywords.Replace Endpoint Address    ${TESTTOOL_RPC_ENDPOINT}    ${TOOLS_SYSTEM_IP}
    ${data}=    JsonrpcKeywords.Replace Endpoint Address    ${TESTTOOL_DATA_ENDPOINT}    ${TOOLS_SYSTEM_IP}
    JsonrpcKeywords.Initialize JSONRPC     governance=${gov}
    JsonrpcKeywords.Mount Peer    ${mp_name}    test-model,network-topology    config_endpoints=\{\}=${data}
    ...     op_endpoints=\{\}=${data}    rpc_endpoints=\{\}=${rpc}

Destroy
    [Documentation]    Cleanup controller
    JsonrpcKeywords.Unmount Peer    ${mp_name}
    JsonrpcKeywords.Unconfigure JSONRPC
    Delete All Sessions
