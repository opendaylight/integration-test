*** Settings ***
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
Suite Teardown    Delete_All
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Library           XML
Resource          ../../../libraries/BierResource.robot
Resource          ../../../variables/Variables.robot

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

*** Test Cases ***
Query All Topology ID
    [Documentation]    Query all bier topology ID
    ${resp}    Send_Request_To_Query_Topology_Id    bier-topology-api    load-topology
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    ${root}    to json    ${resp.content}
    ${out_put}    get from dictionary    ${root}    output
    ${topology_list}    get from dictionary    ${out_put}    topology
    ${topology}    get from list    ${topology_list}    0
    ${topology_id}    get from dictionary    ${topology}    topology-id
    BuiltIn.Should_Be_Equal    ${topology_id}    flow:1

Query Single Topology
    [Documentation]    Query the topology which assigned by RestAPI
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-topology    ${input}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    ${root}    to json    ${resp.content}
    ${out_put}    get from dictionary    ${root}    output
    ${topology_id}    get from dictionary    ${out_put}    topology-id
    BuiltIn.Should_Be_Equal    ${topology_id}    flow:1

Configuration Domain
    [Documentation]    Configure a bier domain in the topology
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain    ${DOMAIN_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-domain    ${input}
    Verify_Configuration_Success_Or_Not    ${resp}

Query Domain
    [Documentation]    Query a bier domain in the topology
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-domain    ${input}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    ${root}    to json    ${resp.content}
    ${out_put}    get from dictionary    ${root}    output
    ${domain_list}    get from dictionary    ${out_put}    domain
    ${domain_id}    get from list    ${domain_list}    0
    ${value}    get from dictionary    ${domain_id}    domain-id
    BuiltIn.Should_Be_Equal    ${value}    ${1}

Delete Domain
    [Documentation]    Delete a bier domain in the topology
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-domain    ${input}
    Verify_Configuration_Success_Or_Not    ${resp}

Configuration Subdomain
    [Documentation]    Configure a  bier subdomain in the domain
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain    ${DOMAIN_ID}
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-domain    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}    sub-domain
    ...    ${SUBDOMAIN_ID_LIST}
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    configure-subdomain    ${input2}
    Verify_Configuration_Success_Or_Not    ${resp2}

Query Subdomain
    [Documentation]    Query all bier subdomains in one domain
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    query-subdomain    ${input}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    ${root}    to json    ${resp.content}
    ${out_put}    get from dictionary    ${root}    output
    ${subdomain_list}    get from dictionary    ${out_put}    subdomain
    ${fixed_value}    Set Variable    ${4}
    : FOR    ${i}    IN    3    2    1    0
    \    ${subdomain_id}    get from list    ${subdomain_list}    ${i}
    \    ${value}    get from dictionary    ${subdomain_id}    sub-domain-id
    \    ${sub_value}    Evaluate    ${4}-${i}
    \    BuiltIn.Should_Be_Equal    ${value}    ${sub_value}

Delete Subdomain
    [Documentation]    Delete a bier subdomain in one domain
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    4
    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-subdomain    ${input}
    Verify_Configuration_Success_Or_Not    ${resp}

Configuration Four Node
    [Documentation]    Configure the bier information to the four nodes in the subdomain
    ${af}    Construct_Af    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
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
    \    ...    ${1}    ${4}    ${64}    ${1}    ${4}

Add Subdomain For Single Node
    [Documentation]    Configure each  node in the subdomain
    ${af}    Construct_Af    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${i+1}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${subdomain_list}    ${af}
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
    \    ...    OSPF    64-bit    ${2}    ${0}    ${256}
    \    ...    ${1}    ${4}    ${64}    ${1}    ${4}

Add Ipv4 Of Subdomain
    [Documentation]    Add one Ipv4 element to Ipv4list in container Af of the subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${i+1}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${subdomain_list}    ${af}
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
    \    ...    ${1}    ${4}    ${64}    ${1}    ${4}

Modify Leaf Of Domain
    [Documentation]    Modify {bitstringlength} and {bfr_id} value for a domain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${i+1}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${subdomain_list}    ${af}
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
    \    ${root}    to json    ${resp2.content}
    \    ${out_put}    get from dictionary    ${root}    output
    \    ${node_list}    get from dictionary    ${out_put}    node
    \    ${node}    get from list    ${node_list}    0
    \    ${node_id}    get from dictionary    ${node}    node-id
    \    ${bier_node_params}    get from dictionary    ${node}    bier-node-params
    \    ${domain_list}    get from dictionary    ${bier_node_params}    domain
    \    ${domain}    get from list    ${domain_list}    0
    \    ${domain_id}    get from dictionary    ${domain}    domain-id
    \    ${bier_global}    get from dictionary    ${domain}    bier-global
    \    ${bit_string_length}    get from dictionary    ${bier_global}    bitstringlength
    \    ${bfr_id}    get from dictionary    ${bier_global}    bfr-id
    \    BuiltIn.Should_Be_Equal    ${bit_string_length}    ${BITSTRINGLENGTH_LIST[1]}
    \    BuiltIn.Should_Be_Equal    ${bfr_id}    ${10}

Modify Leaf Of Subdomain
    [Documentation]    Modify {igp_type}, {mt_id} and {bfr_id} value for every subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[0]}    ${MT_ID_LIST[1]}    ${9}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${subdomain_list}    ${af}
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
    \    ${root}    to json    ${resp2.content}
    \    ${out_put}    get from dictionary    ${root}    output
    \    ${node_list}    get from dictionary    ${out_put}    node
    \    ${node}    get from list    ${node_list}    0
    \    ${node_id}    get from dictionary    ${node}    node-id
    \    ${bier_node_params}    get from dictionary    ${node}    bier-node-params
    \    ${domain_list}    get from dictionary    ${bier_node_params}    domain
    \    ${domain}    get from list    ${domain_list}    0
    \    ${bier_global}    get from dictionary    ${domain}    bier-global
    \    ${subdomain_list}    get from dictionary    ${bier_global}    sub-domain
    \    ${subdomain}    get from list    ${subdomain_list}    0
    \    ${igp_type}    get from dictionary    ${subdomain}    igp-type
    \    ${subdomain_bfr_id}    get from dictionary    ${subdomain}    bfr-id
    \    ${mt_id}    get from dictionary    ${subdomain}    mt-id
    \    BuiltIn.Should_Be_Equal    ${igp_type}    ${IGP_TYPE_LIST[0]}
    \    BuiltIn.Should_Be_Equal    ${subdomain_bfr_id}    ${9}
    \    BuiltIn.Should_Be_Equal_As_Strings    ${mt_id}    ${MT_ID_LIST[1]}

Modify Ipv4 Of Subdomain
    [Documentation]    Modify {ipv4_bier_mpls_label_range_size} value of one Ipv4 element in one subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    5
    : FOR    ${i}    IN RANGE    4
    \    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[0]}    ${MT_ID_LIST[1]}    ${9}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    ${subdomain_list}    Create List    ${subdomain}
    \    ${new_subdomain_list}    Add_Subdomain    ${subdomain_list}    ${af}
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
    \    ${root}    to json    ${resp2.content}
    \    ${out_put}    get from dictionary    ${root}    output
    \    ${nodelist}    get from dictionary    ${out_put}    node
    \    ${node}    get from list    ${node_list}    0
    \    ${nodeid}    get from dictionary    ${node}    node-id
    \    ${bier_node_params}    get from dictionary    ${node}    bier-node-params
    \    ${domain_list}    get from dictionary    ${bier_node_params}    domain
    \    ${domain}    get from list    ${domain_list}    0
    \    ${bier_global}    get from dictionary    ${domain}    bier-global
    \    ${subdomain_list}    get from dictionary    ${bier_global}    sub-domain
    \    ${subdomain}    get from list    ${subdomain_list}    0
    \    ${af}    get from dictionary    ${subdomain}    af
    \    ${ipv4_list}    get from dictionary    ${af}    ipv4
    \    ${ipv4}    get from list    ${ipv4_list}    1
    \    ${ipv4_bier_mpls_label_range_size}    get from dictionary    ${ipv4}    bier-mpls-label-range-size
    \    BuiltIn.Should_Be_Equal    ${ipv4_bier_mpls_label_range_size}    ${5}

Delete Ipv4 Of Node4
    [Documentation]    Delete Ipv4list in node4
    ${ipv4_one}    Create Dictionary    bitstringlength    64    bier-mpls-label-base    1    bier-mpls-label-range-size
    ...    5
    ${ipv4_two}    Create Dictionary    bitstringlength    256    bier-mpls-label-base    1    bier-mpls-label-range-size
    ...    5
    : FOR    ${i}    IN RANGE    3
    \    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    \    ...    sub-domain-id    ${i+1}    node-id    ${SUBDOMAIN_ID_LIST[3]}    ipv4
    \    ...    ${ipv4_one}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-ipv4    ${input1}
    \    Verify_Configuration_Success_Or_Not    ${resp1}
    \    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    \    ...    sub-domain-id    ${i+1}    node-id    ${SUBDOMAIN_ID_LIST[3]}    ipv4
    \    ...    ${ipv4_two}
    \    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-ipv4    ${input2}
    \    Verify_Configuration_Success_Or_Not    ${resp2}

Delete Node4
    [Documentation]    Delete node4
    : FOR    ${i}    IN RANGE    3
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    \    ...    sub-domain-id    ${i+1}    node-id    ${SUBDOMAIN_ID_LIST[3]}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-node    ${input}
    \    Verify_Configuration_Success_Or_Not    ${resp}

Add Channel
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
    ${root}    to json    ${resp3.content}
    ${out_put}    get from dictionary    ${root}    output
    ${channel_name_list}    get from dictionary    ${out_put}    channel-name
    ${channel_name1}    get from list    ${channel_name_list}    0
    ${name1}    get from dictionary    ${channel_name1}    name
    BuiltIn.Should_Be_Equal    ${name1}    channel-1
    ${channel_name2}    get from list    ${channel_name_list}    1
    ${name2}    get from dictionary    ${channel_name2}    name
    BuiltIn.Should_Be_Equal    ${name2}    channel-2

Modify Channel
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

Deploy Channel
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

Modify Deploy Channel
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
    ${root}    to json    ${resp2.content}
    ${out_put}    get from dictionary    ${root}    output
    ${channel_list}    get from dictionary    ${out_put}    channel
    ${channel}    get from list    ${channel_list}    0
    Extract_Channel_Ingress_And_Egress_Node_Output_And_Verify_Value    ${channel}    2    1    3

Remove Channel
    [Documentation]    Remove all channels
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-1
    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    remove-channel    ${input1}
    Verify_Configuration_Success_Or_Not    ${resp1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-2
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-channel-api    remove-channel    ${input2}
    Verify_Configuration_Success_Or_Not    ${resp2}
