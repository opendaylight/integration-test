*** Settings ***
Documentation     Basic tests for BIER information configuration and verification.
...
...               Copyright (c) 2016-2017 Zte, Inc. and others. All rights reserved.
...
...               Test suite performs basic BIER information configuration and verification test cases for
...               topology domain, subdomain, node and channel as follows:
...
...               Test Case 1: Query the topology and check its existence
...               Expected result: Exist a topology which topologyId is flow:1
...
...               Test Case 2: Configure domain with add and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...
...               Test Case 3: Configure subdomain with add and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...
...               Test Case 4: Configure node with add, modify and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...
...               Test Case 5: Configure channel with add, modify, deploy and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
Suite Teardown    Delete_All
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Library           XML
Resource          ../../../libraries/BierResource.robot
Resource          ../../../variables/Variables.robot
Resource          ../../libraries/TemplatedRequests.robot

*** Variables ***
${TOPOLOGY_ID}    flow:1
@{DOMAIN_ID}      1
@{SUBDOMAIN_ID_LIST}    1    2    3    4
@{NOID_ID_LIST}    1    2    3    4
@{BSL_OF_IPV4_AND_IPV6}    64    128    256
@{IGP_TYPE_LIST}    ISIS    OSPF
@{MT_ID_LIST}     0    1    2    3    4    5
@{BITSTRINGLENGTH_LIST}    64-bit    128-bit    256-bit
${ENCAPSULATION_TYPE}    ietf-bier:bier-encapsulation-mpls
${IPV4_BFR_PREFIX}    10.41.41.41/22
${IPV6_BFR_PREFIX}    fe80::7009:fe25:8170:36af/64
${BIER_QUERYALLTOPOLOGYID_URI}    /restconf/operations/bier-topology-api
${BIER_VAR_FOLDER}    ${CURDIR}/../../variables/bier

*** Test Cases ***
TC1_Query All Topology ID
    [Documentation]    Query all bier topology ID
    ${resp}    Send_Request_To_Query_Topology_Id    bier-topology-api    load-topology
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    ${root}    To Json    ${resp.content}
    ${out_put}    Get From Dictionary    ${root}    output
    ${topology_list}    Get From Dictionary    ${out_put}    topology
    ${topology}    Get From List    ${topology_list}    0
    ${topology_id}    Get From Dictionary    ${topology}    topology-id
    BuiltIn.Should_Be_Equal    ${topology_id}    flow:1

TC1_Query Single Topology
    [Documentation]    Query the topology which assigned by RestAPI
    ${uri}    Get File    ${BIER_VAR_FOLDER}/query_single_topology_request/location.uri
    ${body}    Get File    ${BIER_VAR_FOLDER}/query_single_topology_request/data.json
    ${resp}    TemplatedRequests.Post_As_Json_To_Uri    ${uri}    ${body}    session
    BuiltIn.Log    ${resp}
    ${expected_resp}    Get File    ${BIER_VAR_FOLDER}/all_response/query_single_topology_response.json
    Normalize_Jsons_And_Compare    ${expected_resp}    ${resp}

TC2_Configure Domain
    [Documentation]    Configure a bier domain in the topology
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain    ${DOMAIN_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-domain    ${input}
    Verify_Configuration_Success_Or_Not    ${resp}

TC2_Query Domain
    [Documentation]    Query a bier domain in the topology
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-domain    ${input}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    ${root}    To Json    ${resp.content}
    ${out_put}    Get From Dictionary    ${root}    output
    ${domain_list}    Get From Dictionary    ${out_put}    domain
    ${domain_id}    Get From List    ${domain_list}    0
    ${value}    Get From Dictionary    ${domain_id}    domain-id
    BuiltIn.Should_Be_Equal    ${value}    ${1}

TC2_Delete Domain
    [Documentation]    Delete a bier domain in the topology
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-domain    ${input}
    Verify_Configuration_Success_Or_Not    ${resp}

TC3_Configure Subdomain
    [Documentation]    Configure a bier subdomain in the domain
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain    ${DOMAIN_ID}
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-domain    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}    sub-domain
    ...    ${SUBDOMAIN_ID_LIST}
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-subdomain    ${input2}
    Verify_Configuration_Success_Or_Not    ${resp2}

TC3_Query Subdomain
    [Documentation]    Query all bier subdomains in one domain
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-subdomain    ${input}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    ${root}    To Json    ${resp.content}
    ${out_put}    Get From Dictionary    ${root}    output
    ${subdomain_list}    Get From Dictionary    ${out_put}    subdomain
    ${subdomain_num}    Get Length    ${subdomain_list}
    ${fixed_value}    Set Variable    ${4}
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain_id}    Get From List    ${subdomain_list}    ${i}
    \    ${value}    Get From Dictionary    ${subdomain_id}    sub-domain-id
    \    ${subdomain}    Convert To String    ${value}
    \    Should Contain    ${SUBDOMAIN_ID_LIST}    ${subdomain}

TC3_Delete Subdomain
    [Documentation]    Delete a bier subdomain in one domain
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    4
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-subdomain    ${input}
    Verify_Configuration_Success_Or_Not    ${resp}

TC4_Configure Four Node
    [Documentation]    Configure the bier information to the four nodes in the subdomain
    ${af}    Construct_Af    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    5    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${i+1}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${bier_global}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[0]}    ${i+1}    ${IPV4_BFR_PREFIX}
    \    ...    ${IPV6_BFR_PREFIX}    ${subdomain_list}
    \    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bier_global}
    \    ${domain_list}    Create List    ${domain}
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domain_list}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-node    ${node}
    \    Verify_Configuration_Success_Or_Not    ${resp1}
    \    ${node_list}    Create List    ${i+1}
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node    ${node_list}
    \    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-node    ${input}
    \    Extract_NodeConfig_Output_And_Verify_Value    ${resp2}    0    0    ${i+1}    ${1}
    \    ...    10.41.41.41/22    fe80::7009:fe25:8170:36af/64    64-bit    ${i+1}    ${1}
    \    ...    OSPF    64-bit    ${i+1}    ${0}    ${256}
    \    ...    ${1}    ${4}    ${64}    ${5}    ${4}

TC4_Add Subdomain For Single Node
    [Documentation]    Configure each node in the subdomain
    ${af}    Construct_Af    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    5    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${i+1}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${i+1}    ${subdomain_list}
    \    ${bier_global}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[0]}    ${i+1}    ${IPV4_BFR_PREFIX}
    \    ...    ${IPV6_BFR_PREFIX}    ${new_subdomain_list}
    \    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bier_global}
    \    ${domain_list}    Create List    ${domain}
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domain_list}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-node    ${node}
    \    Verify_Configuration_Success_Or_Not    ${resp1}
    \    ${node_list}    Create List    ${i+1}
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node    ${node_list}
    \    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-node    ${input}
    \    Extract_NodeConfig_Output_And_Verify_Value    ${resp2}    1    0    ${i+1}    ${1}
    \    ...    10.41.41.41/22    fe80::7009:fe25:8170:36af/64    64-bit    ${i+1}    ${2}
    \    ...    OSPF    64-bit    ${i+1}    ${0}    ${256}
    \    ...    ${9}    ${4}    ${64}    ${13}    ${4}

TC4_Add Ipv4 Of Subdomain
    [Documentation]    Add one Ipv4 element to Ipv4list in container Af of the subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    17    5
    ...    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${i+1}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${i+1}    ${subdomain_list}
    \    ${bier_global}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[0]}    ${i+1}    ${IPV4_BFR_PREFIX}
    \    ...    ${IPV6_BFR_PREFIX}    ${new_subdomain_list}
    \    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bier_global}
    \    ${domain_list}    Create List    ${domain}
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domain_list}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-node    ${node}
    \    Verify_Configuration_Success_Or_Not    ${resp1}
    \    ${node_list}    Create List    ${i+1}
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node    ${node_list}
    \    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-node    ${input}
    \    Extract_NodeConfig_Output_And_Verify_Value    ${resp2}    0    1    ${i+1}    ${1}
    \    ...    10.41.41.41/22    fe80::7009:fe25:8170:36af/64    64-bit    ${i+1}    ${1}
    \    ...    OSPF    64-bit    ${i+1}    ${0}    ${64}
    \    ...    ${17}    ${4}    ${64}    ${5}    ${4}

TC4_Modify Leaf Of Domain
    [Documentation]    Modify {bitstringlength} and {bfr_id} value for a domain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    17    5
    ...    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${i+1}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${i+1}    ${subdomain_list}
    \    ${bier_global}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[1]}    ${10}    ${IPV4_BFR_PREFIX}
    \    ...    ${IPV6_BFR_PREFIX}    ${new_subdomain_list}
    \    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bier_global}
    \    ${domain_list}    Create List    ${domain}
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domain_list}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-node    ${node}
    \    Verify_Configuration_Success_Or_Not    ${resp1}
    \    ${node_list}    Create List    ${i+1}
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node    ${node_list}
    \    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-node    ${input}
    \    ${root}    To Json    ${resp2.content}
    \    ${out_put}    Get From Dictionary    ${root}    output
    \    ${node_list}    Get From Dictionary    ${out_put}    node
    \    ${node}    Get From List    ${node_list}    0
    \    ${node_id}    Get From Dictionary    ${node}    node-id
    \    ${bier_node_params}    Get From Dictionary    ${node}    bier-node-params
    \    ${domain_list}    Get From Dictionary    ${bier_node_params}    domain
    \    ${domain}    Get From List    ${domain_list}    0
    \    ${domain_id}    Get From Dictionary    ${domain}    domain-id
    \    ${bier_global}    Get From Dictionary    ${domain}    bier-global
    \    ${bit_string_length}    Get From Dictionary    ${bier_global}    bitstringlength
    \    ${bfr_id}    Get From Dictionary    ${bier_global}    bfr-id
    \    BuiltIn.Should_Be_Equal    ${bit_string_length}    ${BITSTRINGLENGTH_LIST[1]}
    \    BuiltIn.Should_Be_Equal    ${bfr_id}    ${10}

TC4_Modify Leaf Of Subdomain
    [Documentation]    Modify {igp_type}, {mt_id} and {bfr_id} value for every subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    17    5
    ...    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[0]}    ${MT_ID_LIST[1]}    ${i+5}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${i+1}    ${subdomain_list}
    \    ${bier_global}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[1]}    ${10}    ${IPV4_BFR_PREFIX}
    \    ...    ${IPV6_BFR_PREFIX}    ${new_subdomain_list}
    \    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bier_global}
    \    ${domain_list}    Create List    ${domain}
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domain_list}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-node    ${node}
    \    Verify_Configuration_Success_Or_Not    ${resp1}
    \    ${node_list}    Create List    ${i+1}
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node    ${node_list}
    \    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-node    ${input}
    \    ${root}    To Json    ${resp2.content}
    \    ${out_put}    Get From Dictionary    ${root}    output
    \    ${node_list}    Get From Dictionary    ${out_put}    node
    \    ${node}    Get From List    ${node_list}    0
    \    ${node_id}    Get From Dictionary    ${node}    node-id
    \    ${bier_node_params}    Get From Dictionary    ${node}    bier-node-params
    \    ${domain_list}    Get From Dictionary    ${bier_node_params}    domain
    \    ${domain}    Get From List    ${domain_list}    0
    \    ${bier_global}    Get From Dictionary    ${domain}    bier-global
    \    ${subdomain_list}    Get From Dictionary    ${bier_global}    sub-domain
    \    ${subdomain}    Get From List    ${subdomain_list}    0
    \    ${igp_type}    Get From Dictionary    ${subdomain}    igp-type
    \    ${subdomain_bfr_id}    Get From Dictionary    ${subdomain}    bfr-id
    \    ${mt_id}    Get From Dictionary    ${subdomain}    mt-id
    \    BuiltIn.Should_Be_Equal    ${igp_type}    ${IGP_TYPE_LIST[0]}
    \    BuiltIn.Should_Be_Equal    ${subdomain_bfr_id}    ${i+5}
    \    BuiltIn.Should_Be_Equal_As_Strings    ${mt_id}    ${MT_ID_LIST[1]}

TC4_Modify Ipv4 Of Subdomain
    [Documentation]    Modify ${bier_ipv4_mlslab_base} value of one Ipv4 element in one subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    17    5
    ...    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[0]}    ${MT_ID_LIST[1]}    ${i+5}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${i+1}    ${subdomain_list}
    \    ${bie_rglobal}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[1]}    ${10}    ${IPV4_BFR_PREFIX}
    \    ...    ${IPV6_BFR_PREFIX}    ${new_subdomain_list}
    \    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bie_rglobal}
    \    ${domain_list}    Create List    ${domain}
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domain_list}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-node    ${node}
    \    Verify_Configuration_Success_Or_Not    ${resp1}
    \    ${node_list}    Create List    ${i+1}
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node    ${node_list}
    \    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-node    ${input}
    \    ${root}    To Json    ${resp2.content}
    \    ${out_put}    Get From Dictionary    ${root}    output
    \    ${nodelist}    Get From Dictionary    ${out_put}    node
    \    ${node}    Get From List    ${node_list}    0
    \    ${nodeid}    Get From Dictionary    ${node}    node-id
    \    ${bier_node_params}    Get From Dictionary    ${node}    bier-node-params
    \    ${domain_list}    Get From Dictionary    ${bier_node_params}    domain
    \    ${domain}    Get From List    ${domain_list}    0
    \    ${bier_global}    Get From Dictionary    ${domain}    bier-global
    \    ${subdomain_list}    Get From Dictionary    ${bier_global}    sub-domain
    \    ${subdomain}    Get From List    ${subdomain_list}    0
    \    ${af}    Get From Dictionary    ${subdomain}    af
    \    ${ipv4_list}    Get From Dictionary    ${af}    ipv4
    \    ${ipv4}    Get From List    ${ipv4_list}    1
    \    ${bier_ipv4_mlslab_base}    Get From Dictionary    ${ipv4}    bier-mpls-label-base
    \    BuiltIn.Should_Be_Equal    ${bier_ipv4_mlslab_base}    ${17}

TC4_Delete Ipv4 Of Node4
    [Documentation]    Delete Ipv4list in node4
    ${ipv4_one}    Create Dictionary    bitstringlength    64    bier-mpls-label-base    17    bier-mpls-label-range-size
    ...    4
    ${ipv4_two}    Create Dictionary    bitstringlength    256    bier-mpls-label-base    1    bier-mpls-label-range-size
    ...    4
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    ${SUBDOMAIN_ID_LIST[0]}    node-id    ${NOID_ID_LIST[3]}    ipv4    ${ipv4_one}
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-ipv4    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    ${SUBDOMAIN_ID_LIST[0]}    node-id    ${NOID_ID_LIST[3]}    ipv4    ${ipv4_two}
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-ipv4    ${input2}
    Verify_Configuration_Success_Or_Not    ${resp2}

TC4_Delete Node4
    [Documentation]    Delete node4
    : FOR    ${i}    IN RANGE    2
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    \    ...    sub-domain-id    ${i+1}    node-id    ${SUBDOMAIN_ID_LIST[3]}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-node    ${input}
    \    Verify_Configuration_Success_Or_Not    ${resp}

TC5_Add Channel
    [Documentation]    Configure two channels
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    name    channel-1    src-ip
    ...    1.1.1.1    dst-group    224.1.1.1    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    ${SUBDOMAIN_ID_LIST[0]}    source-wildcard    24    group-wildcard    30
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    add-channel    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    name    channel-2    src-ip
    ...    2.2.2.2    dst-group    225.1.1.1    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    ${SUBDOMAIN_ID_LIST[1]}    source-wildcard    24    group-wildcard    30
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    add-channel    ${input2}
    Verify_Configuration_Success_Or_Not    ${resp2}
    ${input3}    Create Dictionary    topology-id    ${TOPOLOGY_ID}
    ${resp3}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    get-channel    ${input3}
    ${root}    To Json    ${resp3.content}
    ${out_put}    Get From Dictionary    ${root}    output
    ${channel_name_list}    Get From Dictionary    ${out_put}    channel-name
    ${channel_num}    Get Length    ${channel_name_list}
    BuiltIn.Should_Be_Equal    ${channel_num}    ${2}
    ${channel_name1}    Get From List    ${channel_name_list}    0
    ${name1}    Get From Dictionary    ${channel_name1}    name
    @{channel_list}    Create List    channel-1    channel-2
    List Should Contain Value    ${channel_list}    ${name1}
    ${channel_name2}    Get From List    ${channel_name_list}    1
    ${name2}    Get From Dictionary    ${channel_name2}    name
    Should Contain    ${channel_list}    ${name2}

TC5_Modify Channel
    [Documentation]    Modify {src_ip} and {dst_group} value of channel-1
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    name    channel-1    src-ip
    ...    3.3.3.3    dst-group    226.1.1.1    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    ${SUBDOMAIN_ID_LIST[0]}    source-wildcard    24    group-wildcard    30
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    modify-channel    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${channel_list}    Create List    channel-1
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    ${channellist}
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    query-channel    ${input2}
    ${channel}    Extract_Channel_Output_And_Verify_Value    ${resp2}    channel-1    3.3.3.3    226.1.1.1    ${1}
    ...    ${1}    ${24}    ${30}

TC5_Deploy Channel
    [Documentation]    Configure ingress-node, egress-node and deploy one channel to device
    ${egress_node1}    Create Dictionary    node-id    2
    ${egress_node2}    Create Dictionary    node-id    3
    ${egress_node}    Create List    ${egress_node1}    ${egress_node2}
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-1    ingress-node
    ...    1    egress-node    ${egress_node}
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    deploy-channel    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${channel_list}    Create List    channel-1
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    ${channel_list}
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    query-channel    ${input2}
    ${channel}    Extract_Channel_Output_And_Verify_Value    ${resp2}    channel-1    3.3.3.3    226.1.1.1    ${1}
    ...    ${1}    ${24}    ${30}
    Extract_Channel_Ingress_And_Egress_Node_Output_And_Verify_Value    ${channel}    1    2    3

TC5_Modify Deploy Channel
    [Documentation]    Modify ingress-node, egress-node and deploy channel to device again
    ${egress_node1}    Create Dictionary    node-id    1
    ${egress_node2}    Create Dictionary    node-id    3
    ${egress_node}    Create List    ${egress_node1}    ${egress_node2}
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-1    ingress-node
    ...    2    egress-node    ${egress_node}
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    deploy-channel    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${channel_list}    Create List    channel-1
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    ${channel_list}
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    query-channel    ${input2}
    ${root}    To Json    ${resp2.content}
    ${out_put}    Get From Dictionary    ${root}    output
    ${channel_list}    Get From Dictionary    ${out_put}    channel
    ${channel}    Get From List    ${channel_list}    0
    Extract_Channel_Ingress_And_Egress_Node_Output_And_Verify_Value    ${channel}    2    1    3

TC5_Remove Channel
    [Documentation]    Remove all channels
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-1
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    remove-channel    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-2
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    remove-channel    ${input2}
    Verify_Configuration_Success_Or_Not    ${resp2}
