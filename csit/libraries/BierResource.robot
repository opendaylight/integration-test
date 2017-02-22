*** Settings ***
Library           Collections
Library           RequestsLibrary
Library           json

*** Keywords ***
Send_Request_To_Query_Topology_Id
    [Arguments]    ${module}    ${oper}
    [Documentation]    Send request to controller to query topologyid through REST-API using POST method, ${module} represents yang module and ${oper} represents rpc operation
    ${resp}    Post Request    session    /restconf/operations/${module}:${oper}
    BuiltIn.Log    ${resp.content}
    [Return]    ${resp}

Send_Request_Operation_Besides_QueryTopology_Id
    [Arguments]    ${module}    ${oper}    ${input}
    [Documentation]    Send other request to controller besides query topologyid, for example configures domain, subdomain, node and so on. ${input} represents the request body
    ${pkg}    Create Dictionary    input=${input}
    ${data}    dumps    ${pkg}
    ${resp}    Post Request    session    /restconf/operations/${module}:${oper}    data=${data}
    BuiltIn.Log    ${resp.content}
    [Return]    ${resp}

Construct_Af
    [Arguments]    ${ipv4_bsl}    ${ipv6_bsl}    ${bier_mlslab_base}    ${bier_mlslab_range_size}
    [Documentation]    Construct container af inside single subdomain by given details ${ipv4_bsl}, ${ipv6_bsl}, ${bier_mlslab_base} and ${bier_mlslab_range_size}
    ${ipv4}    Create Dictionary    bitstringlength=${ipv4_bsl}    bier-mpls-label-base=${bier_mlslab_base}    bier-mpls-label-range-size=${bier_mlslab_range_size}
    ${ipv6}    Create Dictionary    bitstringlength=${ipv6_bsl}    bier-mpls-label-base=${bier_mlslab_base}    bier-mpls-label-range-size=${bier_mlslab_range_size}
    ${ipv4_list}    Create List    ${ipv4}
    ${ipv6_list}    Create List    ${ipv6}
    ${af}    Create Dictionary    ipv4=${ipv4_list}    ipv6=${ipv6_list}
    [Return]    ${af}

Construct_Subdomain
    [Arguments]    ${subdomain_id}    ${igp_type}    ${mt_id}    ${bfr_id}    ${bit_string_length}    ${af}
    [Documentation]    Construct subdomain list inside domain by given details ${subdomain_id}, ${igp_type}, ${mt_id}, ${bfr_id}, ${bit_string_length}, ${af}
    ${subdomain}    Create Dictionary    sub-domain-id=${subdomain_id}    igp-type=${igp_type}    mt-id=${mt_id}    bfr-id=${bfr_id}    bitstringlength=${bit_string_length}
    ...    af=${af}
    [Return]    ${subdomain}

Construct_Bier_Global
    [Arguments]    ${encapsulation_type}    ${bit_string_length}    ${bfr_id}    ${ipv4_bfr_prefix}    ${ipv6_bfr_prefix}    ${subdomain_list}
    [Documentation]    Construct bier global inside domain by given details ${encapsulation_type}, ${bit_string_length}, ${bfr_id}, ${ipv4_bfr_prefix}, ${ipv6_bfr_prefix}, ${subdomain_list}
    ${bier_global}    Create Dictionary    encapsulation-type=${encapsulation_type}    bitstringlength=${bit_string_length}    bfr-id=${bfr_id}    ipv4-bfr-prefix=${ipv4_bfr_prefix}    ipv6-bfr-prefix=${ipv6_bfr_prefix}
    ...    sub-domain=${subdomain_list}
    [Return]    ${bier_global}

Construct_Domain
    [Arguments]    ${domain_id}    ${bier_global}
    [Documentation]    Construct domain by given details ${domain_id}, ${bier_global}
    ${domain}    Create Dictionary    domain-id=${domain_id}    bier-global=${bier_global}
    [Return]    ${domain}

Add_Subdomain
    [Arguments]    ${subdomain_list}    ${af}
    [Documentation]    Use ${af} to contruct new subdomain and added to previous ${subdomain_list}
    : FOR    ${i}    IN RANGE    1    3
    \    ${subdomain}    Construct_Subdomain    ${i+1}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${i+1}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    Append To List    ${subdomain_list}    ${subdomain}
    BuiltIn.Log    ${subdomain_list}
    [Return]    ${subdomain_list}

Add_Or_Modify_Ipv4
    [Arguments]    ${ipv4_bsl}    ${ipv6_bsl}    ${bier_mlslab_base}    ${bier_mlslab_range_size}
    [Documentation]    Add or modify ipv4 inside af by given details ${ipv4_bsl}, ${ipv6_bsl}, ${bier_mlslab_base}, ${bier_mlslab_range_size}
    ${ipv4_one}    Create Dictionary    bitstringlength=${ipv4_bsl}    bier-mpls-label-base=${bier_mlslab_base}    bier-mpls-label-range-size=${bier_mlslab_range_size}
    ${ipv4_two}    Create Dictionary    bitstringlength=${ipv6_bsl}    bier-mpls-label-base=${bier_mlslab_base}    bier-mpls-label-range-size=${bier_mlslab_range_size}
    ${ipv6}    Create Dictionary    bitstringlength=${ipv6_bsl}    bier-mpls-label-base=${bier_mlslab_base}    bier-mpls-label-range-size=${bier_mlslab_range_size}
    ${ipv4_list}    Create List    ${ipv4_one}    ${ipv4_two}
    ${ipv6_list}    Create List    ${ipv6}
    ${af}    Create Dictionary    ipv4=${ipv4_list}    ipv6=${ipv6_list}
    [Return]    ${af}

Verify_Configuration_Success_Or_Not
    [Arguments]    ${resp}
    [Documentation]    Verify the return value ${resp} of request to controller success or not
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    ${root}    to json    ${resp.content}
    ${output}    get from dictionary    ${root}    output
    ${configure_result}    get from dictionary    ${output}    configure-result
    ${result}    get from dictionary    ${configure_result}    result
    BuiltIn.Should_Be_Equal    ${result}    SUCCESS

Extract_NodeConfig_Output_And_Verify_Value
    [Arguments]    ${resp}    ${subdomain_index}    ${ipv4_list_index}    ${node_id_value}    ${domain_id_value}    ${ipv4_value}
    ...    ${ipv6_value}    ${bit_string_length_value}    ${bfr_id_value}    ${subdomain_id_value}    ${igp_type_value}    ${subdomain_bit_string_length_value}
    ...    ${subdomain_bfr_id_value}    ${mt_id_value}    ${ipv4_bit_string_length_value}    ${ipv4_bier_mpls_label_base_value}    ${ipv4_bier_mpls_label_range_size_value}    ${ipv6_bit_string_length_value}
    ...    ${ipv6_bier_mpls_label_base_value}    ${ipv6_bier_mpls_label_range_size_value}
    [Documentation]    Extract the output of node configuration request and verify its value
    ${root}    to json    ${resp.content}
    ${out_put}    get from dictionary    ${root}    output
    ${node_list}    get from dictionary    ${out_put}    node
    ${node}    get from list    ${node_list}    0
    ${node_id}    get from dictionary    ${node}    node-id
    ${bier_node_params}    get from dictionary    ${node}    bier-node-params
    ${domain_list}    get from dictionary    ${bier_node_params}    domain
    ${domain}    get from list    ${domain_list}    0
    ${domain_id}    get from dictionary    ${domain}    domain-id
    ${bier_global}    get from dictionary    ${domain}    bier-global
    ${ipv4_bfr_prefix}    get from dictionary    ${bier_global}    ipv4-bfr-prefix
    ${ipv6_bfr_prefix}    get from dictionary    ${bier_global}    ipv6-bfr-prefix
    ${encapsulation_type}    get from dictionary    ${bier_global}    encapsulation-type
    ${bit_string_length}    get from dictionary    ${bier_global}    bitstringlength
    ${bfr_id}    get from dictionary    ${bier_global}    bfr-id
    ${subdomain_list}    get from dictionary    ${bier_global}    sub-domain
    ${subdomain}    get from list    ${subdomain_list}    ${subdomain_index}
    ${subdomain_id}    get from dictionary    ${subdomain}    sub-domain-id
    ${igp_type}    get from dictionary    ${subdomain}    igp-type
    ${subdomain_bit_string_length}    get from dictionary    ${subdomain}    bitstringlength
    ${subdomain_bfr_id}    get from dictionary    ${subdomain}    bfr-id
    ${mt_id}    get from dictionary    ${subdomain}    mt-id
    ${af}    get from dictionary    ${subdomain}    af
    ${ipv4_list}    get from dictionary    ${af}    ipv4
    ${ipv6_list}    get from dictionary    ${af}    ipv6
    ${ipv4}    get from list    ${ipv4_list}    ${ipv4_list_index}
    ${ipv6}    get from list    ${ipv6_list}    0
    ${ipv4_bit_string_length}    get from dictionary    ${ipv4}    bitstringlength
    ${ipv4_bier_mpls_label_base}    get from dictionary    ${ipv4}    bier-mpls-label-base
    ${ipv4_bier_mpls_label_range_size}    get from dictionary    ${ipv4}    bier-mpls-label-range-size
    ${ipv6_bit_string_length}    get from dictionary    ${ipv6}    bitstringlength
    ${ipv6_bier_mpls_label_base}    get from dictionary    ${ipv6}    bier-mpls-label-base
    ${ipv6_bier_mpls_label_range_size}    get from dictionary    ${ipv6}    bier-mpls-label-range-size
    BuiltIn.Should_Be_Equal_As_strings    ${node_id}    ${node_id_value}
    BuiltIn.Should_Be_Equal    ${domain_id}    ${domain_id_value}
    BuiltIn.Should_Be_Equal    ${ipv4_bfr_prefix}    ${ipv4_value}
    BuiltIn.Should_Be_Equal    ${ipv6_bfr_prefix}    ${ipv6_value}
    BuiltIn.Should_Be_Equal    ${bit_string_length}    ${bit_string_length_value}
    BuiltIn.Should_Be_Equal    ${bfr_id}    ${bfr_id_value}
    BuiltIn.Should_Be_Equal    ${subdomain_id}    ${subdomain_id_value}
    BuiltIn.Should_Be_Equal    ${igp_type}    ${igp_type_value}
    BuiltIn.Should_Be_Equal    ${subdomain_bit_string_length}    ${subdomain_bit_string_length_value}
    BuiltIn.Should_Be_Equal    ${subdomain_bfr_id}    ${subdomain_bfr_id_value}
    BuiltIn.Should_Be_Equal    ${mt_id}    ${mt_id_value}
    BuiltIn.Should_Be_Equal    ${ipv4_bit_string_length}    ${ipv4_bit_string_length_value}
    BuiltIn.Should_Be_Equal    ${ipv4_bier_mpls_label_base}    ${ipv4_bier_mpls_label_base_value}
    BuiltIn.Should_Be_Equal    ${ipv4_bier_mpls_label_range_size}    ${ipv4_bier_mpls_label_range_size_value}
    BuiltIn.Should_Be_Equal    ${ipv6_bit_string_length}    ${ipv6_bit_string_length_value}
    BuiltIn.Should_Be_Equal    ${ipv6_bier_mpls_label_base}    ${ipv6_bier_mpls_label_base_value}
    BuiltIn.Should_Be_Equal    ${ipv6_bier_mpls_label_range_size}    ${ipv6_bier_mpls_label_range_size_value}

Extract_Channel_Output_And_Verify_Value
    [Arguments]    ${resp}    ${name}    ${src_ip_value}    ${dst_group_value}    ${domain_id_value}    ${subdomain_id_value}
    ...    ${source_wildcard_value}    ${group_wildcard_value}
    [Documentation]    Extract the output of channel configuration request and verify its value
    ${root}    to json    ${resp.content}
    ${out_put}    get from dictionary    ${root}    output
    ${channel_list}    get from dictionary    ${out_put}    channel
    ${channel}    get from list    ${channel_list}    0
    ${channel_name}    get from dictionary    ${channel}    name
    ${src_ip}    get from dictionary    ${channel}    src-ip
    ${subdomain_id}    get from dictionary    ${channel}    sub-domain-id
    ${source_wildcard}    get from dictionary    ${channel}    source-wildcard
    ${dst_group}    get from dictionary    ${channel}    dst-group
    ${domain_id}    get from dictionary    ${channel}    domain-id
    ${group_wildcard}    get from dictionary    ${channel}    group-wildcard
    BuiltIn.Should_Be_Equal    ${channel_name}    ${name}
    BuiltIn.Should_Be_Equal    ${src_ip}    ${src_ip_value}
    BuiltIn.Should_Be_Equal    ${dst_group}    ${dst_group_value}
    BuiltIn.Should_Be_Equal    ${domain_id}    ${domain_id_value}
    BuiltIn.Should_Be_Equal    ${subdomain_id}    ${subdomain_id_value}
    BuiltIn.Should_Be_Equal    ${source_wildcard}    ${source_wildcard_value}
    BuiltIn.Should_Be_Equal    ${group_wildcard}    ${group_wildcard_value}
    [Return]    ${channel}

Extract_Channel_Ingress_And_Egress_Node_Output_And_Verify_Value
    [Arguments]    ${channel}    ${ingress_node_value}    ${egress_node1_value}    ${egress_node2_value}
    [Documentation]    Extract the ingress and egress node of deployed channel and verify its value
    ${ingress_node}    get from dictionary    ${channel}    ingress-node
    ${egress_node_list}    get from dictionary    ${channel}    egress-node
    ${egress_node1}    get from list    ${egress_node_list}    0
    ${egress_node2}    get from list    ${egress_node_list}    1
    ${node_id1}    get from dictionary    ${egress_node1}    node-id
    ${node_id2}    get from dictionary    ${egress_node2}    node-id
    BuiltIn.Should_Be_Equal    ${ingress_node}    ${ingress_node_value}
    BuiltIn.Should_Be_Equal    ${node_id1}    ${egress_node1_value}
    BuiltIn.Should_Be_Equal    ${node_id2}    ${egress_node2_value}

Delete_All
    [Documentation]    Delete domain and subdomain which were configured previous and close restconf session
    : FOR    ${i}    IN RANGE    3
    \    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    \    ...    sub-domain-id    ${i+1}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-subdomain    ${input1}
    \    Verify_Configuration_Success_Or_Not    ${resp1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    ${resp2}    Send_Request_Operation_Besides_QueryTopology_Id    bier-topology-api    delete-domain    ${input2}
    Verify_Configuration_Success_Or_Not    ${resp2}
    RequestsLibrary.Delete_All_Sessions
