*** Settings ***
Documentation     Basic tests for BIER information configuration and verification.
...
...               Copyright (c) 2016-2017 Zte, Inc. and others. All rights reserved.
...
...               Test suite performs basic BIER information configuration and verification test cases for
...               topology domain, subdomain, node and channel as follows:
...
...               Test Case 1: Query the topology, node and check their existence
...               Expected result: Exist a topology which topologyId is flow:1 and seven nodes inside it
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
Resource          ${CURDIR}/../../../libraries/BierResource.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../variables/Variables.robot

*** Variables ***
@{SUBDOMAIN_ID_LIST}    1    2    3    4
@{NOID_ID_LIST}    1    2    3    4
@{BSL_OF_IPV4_AND_IPV6}    64    128    256
@{IGP_TYPE_LIST}    ISIS    OSPF
@{MT_ID_LIST}     0    1    2
@{BITSTRINGLENGTH_LIST}    64-bit    128-bit    256-bit
@{BFR_ID}         1    2    3    4    5    6    7
...               8
@{CHANNEL_NAME_LIST}    channel-1    channel-2
@{SRC_IP_LIST}    1.1.1.1    2.2.2.2    3.3.3.3    4.4.4.4
@{DST_GROUP_LIST}    224.1.1.1    225.1.1.1    226.1.1.1    227.1.1.1
${BIER_VAR_FOLDER}    ${CURDIR}/../../../variables/bier
${SESSION}        session

*** Test Cases ***
TC1_Query All Topology ID
    [Documentation]    Query all bier topology ID
    Wait Until Keyword Succeeds    30s    2s    Node_Online
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
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/query_single_topology    {}    ${SESSION}    True

TC2_Configure Domain
    [Documentation]    Configure a bier domain in the topology
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/configure_domain    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response

TC2_Query Domain
    [Documentation]    Query a bier domain in the topology
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_domain    {}    ${SESSION}    True

TC2_Delete Domain
    [Documentation]    Delete a bier domain in the topology
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_domain    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response

TC3_Configure Subdomain
    [Documentation]    Configure a bier subdomain in the domain
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/configure_domain    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/configure_subdomain    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response

TC3_Query Subdomain
    [Documentation]    Query all bier subdomains in one domain
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_subdomain    {}    ${SESSION}    True

TC3_Delete Subdomain
    [Documentation]    Delete a bier subdomain in one domain
    ${mapping}    Create Dictionary    SUBDOMAINID=${SUBDOMAIN_ID_LIST[3]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_subdomain    ${mapping}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response

TC4_Configure Four Node
    [Documentation]    Configure the bier information to the four nodes in the subdomain
    ${mapping1}    Create Dictionary    NODEID=${NOID_ID_LIST[0]}    DOMAINBFRID=${BFR_ID[0]}    SUBDOMAINBFRID=${BFR_ID[0]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/configure_four_node    ${mapping1}    ${SESSION}    True
    ${mapping2}    Create Dictionary    NODEID=${NOID_ID_LIST[1]}    DOMAINBFRID=${BFR_ID[1]}    SUBDOMAINBFRID=${BFR_ID[1]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/configure_four_node    ${mapping2}    ${SESSION}    True
    ${mapping3}    Create Dictionary    NODEID=${NOID_ID_LIST[2]}    DOMAINBFRID=${BFR_ID[2]}    SUBDOMAINBFRID=${BFR_ID[2]}
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/configure_four_node    ${mapping3}    ${SESSION}    True
    ${mapping4}    Create Dictionary    NODEID=${NOID_ID_LIST[3]}    DOMAINBFRID=${BFR_ID[3]}    SUBDOMAINBFRID=${BFR_ID[3]}
    ${resp4}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/configure_four_node    ${mapping4}    ${SESSION}    True
    ${resp5}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp5}    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    response_for_configure_four_node

TC4_Add Subdomain For Single Node
    [Documentation]    Configure each node in the subdomain
    ${mapping1}    Create Dictionary    NODEID=${NOID_ID_LIST[0]}    DOMAINBFRID=${BFR_ID[0]}    SUBDOMAINBFRID=${BFR_ID[0]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/add_subdomain_for_single_node    ${mapping1}    ${SESSION}    True
    ${mapping2}    Create Dictionary    NODEID=${NOID_ID_LIST[1]}    DOMAINBFRID=${BFR_ID[1]}    SUBDOMAINBFRID=${BFR_ID[1]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/add_subdomain_for_single_node    ${mapping2}    ${SESSION}    True
    ${mapping3}    Create Dictionary    NODEID=${NOID_ID_LIST[2]}    DOMAINBFRID=${BFR_ID[2]}    SUBDOMAINBFRID=${BFR_ID[2]}
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/add_subdomain_for_single_node    ${mapping3}    ${SESSION}    True
    ${mapping4}    Create Dictionary    NODEID=${NOID_ID_LIST[3]}    DOMAINBFRID=${BFR_ID[3]}    SUBDOMAINBFRID=${BFR_ID[3]}
    ${resp4}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/add_subdomain_for_single_node    ${mapping4}    ${SESSION}    True
    ${resp5}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp5}    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    response_for_add_subdomain_for_single_node

TC4_Add Ipv4 Of Subdomain
    [Documentation]    Add one Ipv4 element to Ipv4list in container Af of the subdomain
    ${mapping1}    Create Dictionary    NODEID=${NOID_ID_LIST[0]}    DOMAINBFRID=${BFR_ID[0]}    SUBDOMAINBFRID=${BFR_ID[0]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/add_subdomain_for_single_node    ${mapping1}    ${SESSION}    True
    ${mapping2}    Create Dictionary    NODEID=${NOID_ID_LIST[1]}    DOMAINBFRID=${BFR_ID[1]}    SUBDOMAINBFRID=${BFR_ID[1]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/add_subdomain_for_single_node    ${mapping2}    ${SESSION}    True
    ${mapping3}    Create Dictionary    NODEID=${NOID_ID_LIST[2]}    DOMAINBFRID=${BFR_ID[2]}    SUBDOMAINBFRID=${BFR_ID[2]}
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/add_subdomain_for_single_node    ${mapping3}    ${SESSION}    True
    ${mapping4}    Create Dictionary    NODEID=${NOID_ID_LIST[3]}    DOMAINBFRID=${BFR_ID[3]}    SUBDOMAINBFRID=${BFR_ID[3]}
    ${resp4}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/add_subdomain_for_single_node    ${mapping4}    ${SESSION}    True
    ${resp5}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp5}    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    response_for_add_subdomain_for_single_node

TC4_Modify Leaf Of Domain
    [Documentation]    Modify {bitstringlength} and {bfr_id} value for a domain
    ${mapping1}    Create Dictionary    NODEID=${NOID_ID_LIST[0]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[4]}    IGPTYPE=${IGP_TYPE_LIST[0]}    MTID=${MT_ID_LIST[0]}
    ...    SUBDOMAINBFRID=${BFR_ID[0]}    MPLSLABELRANGESIZE=${4}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping1}    ${SESSION}    True
    ${mapping2}    Create Dictionary    NODEID=${NOID_ID_LIST[1]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[5]}    IGPTYPE=${IGP_TYPE_LIST[0]}    MTID=${MT_ID_LIST[0]}
    ...    SUBDOMAINBFRID=${BFR_ID[1]}    MPLSLABELRANGESIZE=${4}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping2}    ${SESSION}    True
    ${mapping3}    Create Dictionary    NODEID=${NOID_ID_LIST[2]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[6]}    IGPTYPE=${IGP_TYPE_LIST[0]}    MTID=${MT_ID_LIST[0]}
    ...    SUBDOMAINBFRID=${BFR_ID[2]}    MPLSLABELRANGESIZE=${4}
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping3}    ${SESSION}    True
    ${mapping4}    Create Dictionary    NODEID=${NOID_ID_LIST[3]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[7]}    IGPTYPE=${IGP_TYPE_LIST[0]}    MTID=${MT_ID_LIST[0]}
    ...    SUBDOMAINBFRID=${BFR_ID[3]}    MPLSLABELRANGESIZE=${4}
    ${resp4}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping4}    ${SESSION}    True
    ${resp5}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp5}    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    response_for_modify_leaf_of_domain

TC4_Modify Leaf Of Subdomain
    [Documentation]    Modify {igp_type} and {mt_id} value for every subdomain
    ${mapping1}    Create Dictionary    NODEID=${NOID_ID_LIST[0]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[4]}    IGPTYPE=${IGP_TYPE_LIST[1]}    MTID=${MT_ID_LIST[1]}
    ...    SUBDOMAINBFRID=${BFR_ID[0]}    MPLSLABELRANGESIZE=${4}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping1}    ${SESSION}    True
    ${mapping2}    Create Dictionary    NODEID=${NOID_ID_LIST[1]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[5]}    IGPTYPE=${IGP_TYPE_LIST[1]}    MTID=${MT_ID_LIST[1]}
    ...    SUBDOMAINBFRID=${BFR_ID[1]}    MPLSLABELRANGESIZE=${4}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping2}    ${SESSION}    True
    ${mapping3}    Create Dictionary    NODEID=${NOID_ID_LIST[2]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[6]}    IGPTYPE=${IGP_TYPE_LIST[1]}    MTID=${MT_ID_LIST[1]}
    ...    SUBDOMAINBFRID=${BFR_ID[2]}    MPLSLABELRANGESIZE=${4}
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping3}    ${SESSION}    True
    ${mapping4}    Create Dictionary    NODEID=${NOID_ID_LIST[3]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[7]}    IGPTYPE=${IGP_TYPE_LIST[1]}    MTID=${MT_ID_LIST[1]}
    ...    SUBDOMAINBFRID=${BFR_ID[3]}    MPLSLABELRANGESIZE=${4}
    ${resp4}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping4}    ${SESSION}    True
    ${resp5}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp5}    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    response_for_modify_leaf_of_subdomain

TC4_Modify Ipv4 Of Subdomain
    [Documentation]    Modify ${bier_ipv4_mlslab_range_size} value of one Ipv4 element in one subdomain
    ${mapping1}    Create Dictionary    NODEID=${NOID_ID_LIST[0]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[4]}    IGPTYPE=${IGP_TYPE_LIST[1]}    MTID=${MT_ID_LIST[1]}
    ...    SUBDOMAINBFRID=${BFR_ID[0]}    MPLSLABELRANGESIZE=${3}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping1}    ${SESSION}    True
    ${mapping2}    Create Dictionary    NODEID=${NOID_ID_LIST[1]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[5]}    IGPTYPE=${IGP_TYPE_LIST[1]}    MTID=${MT_ID_LIST[1]}
    ...    SUBDOMAINBFRID=${BFR_ID[1]}    MPLSLABELRANGESIZE=${3}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping2}    ${SESSION}    True
    ${mapping3}    Create Dictionary    NODEID=${NOID_ID_LIST[2]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[6]}    IGPTYPE=${IGP_TYPE_LIST[1]}    MTID=${MT_ID_LIST[1]}
    ...    SUBDOMAINBFRID=${BFR_ID[2]}    MPLSLABELRANGESIZE=${3}
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping3}    ${SESSION}    True
    ${mapping4}    Create Dictionary    NODEID=${NOID_ID_LIST[3]}    DOMAINBSL=${BITSTRINGLENGTH_LIST[1]}    DOMAINBFRID=${BFR_ID[7]}    IGPTYPE=${IGP_TYPE_LIST[1]}    MTID=${MT_ID_LIST[1]}
    ...    SUBDOMAINBFRID=${BFR_ID[3]}    MPLSLABELRANGESIZE=${3}
    ${resp4}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/modify_leaf_of_domain    ${mapping4}    ${SESSION}    True
    ${resp5}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp5}    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    response_for_modify_ipv4_of_subdomain

TC4_Delete Ipv4 Of Node4
    [Documentation]    Delete Ipv4list in node4
    ${mapping1}    Create Dictionary    IPV4BSL=${BSL_OF_IPV4_AND_IPV6[0]}    MPLSLABELBASE=${17}    MPLSLABELRANGESIZE=${6}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_ipv4_of_node4    ${mapping1}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response
    ${mapping2}    Create Dictionary    IPV4BSL=${BSL_OF_IPV4_AND_IPV6[2]}    MPLSLABELBASE=${1}    MPLSLABELRANGESIZE=${6}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_ipv4_of_node4    ${mapping2}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response

TC4_Delete Node4
    [Documentation]    Delete node4
    ${mapping1}    Create Dictionary    SUBDOMAINID=${SUBDOMAIN_ID_LIST[1]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_node4    ${mapping1}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response
    ${mapping2}    Create Dictionary    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_node4    ${mapping2}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response

TC5_Add Channel
    [Documentation]    Configure two channels
    ${mapping1}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[0]}    SRCIP=${SRC_IP_LIST[0]}    DSTGROUP=${DST_GROUP_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/add_channel    ${mapping1}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${mapping2}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[1]}    SRCIP=${SRC_IP_LIST[1]}    DSTGROUP=${DST_GROUP_LIST[1]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[1]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/add_channel    ${mapping2}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/get_channel    {}    ${SESSION}    True

TC5_Modify Channel
    [Documentation]    Modify {src_ip} and {dst_group} value of all two channels, and then query them
    ${mapping1}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[0]}    SRCIP=${SRC_IP_LIST[2]}    DSTGROUP=${DST_GROUP_LIST[2]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/modify_channel    ${mapping1}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${mapping2}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[1]}    SRCIP=${SRC_IP_LIST[3]}    DSTGROUP=${DST_GROUP_LIST[3]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[1]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/modify_channel    ${mapping2}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/query_channel    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp3}    ${BIER_VAR_FOLDER}/bier_channel_configuration/query_channel    response_for_undeployed_channel

TC5_Deploy Channel
    [Documentation]    Configure ingress-node, egress-node and deploy two channels to device
    ${mapping1}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[0]}    INGRESSNODE=${NOID_ID_LIST[0]}    EGRESSNODE1=${NOID_ID_LIST[1]}    EGRESSNODE2=${NOID_ID_LIST[2]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/deploy_channel    ${mapping1}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${mapping2}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[1]}    INGRESSNODE=${NOID_ID_LIST[1]}    EGRESSNODE1=${NOID_ID_LIST[0]}    EGRESSNODE2=${NOID_ID_LIST[2]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/deploy_channel    ${mapping2}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/query_channel    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp3}    ${BIER_VAR_FOLDER}/bier_channel_configuration/query_channel    response_for_deployed_channel

TC5_Modify Deploy Channel
    [Documentation]    Modify ingress-node, egress-node and deploy channel to device again
    ${mapping1}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[0]}    INGRESSNODE=${NOID_ID_LIST[1]}    EGRESSNODE1=${NOID_ID_LIST[0]}    EGRESSNODE2=${NOID_ID_LIST[2]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/deploy_channel    ${mapping1}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${mapping2}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[1]}    INGRESSNODE=${NOID_ID_LIST[0]}    EGRESSNODE1=${NOID_ID_LIST[1]}    EGRESSNODE2=${NOID_ID_LIST[2]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/deploy_channel    ${mapping2}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/query_channel    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp3}    ${BIER_VAR_FOLDER}/bier_channel_configuration/query_channel    response_for_modify_deployed_channel

TC5_Remove Channel
    [Documentation]    Remove all channels
    ${mapping1}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[0]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/remove_channel    ${mapping1}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
    ${mapping2}    Create Dictionary    CHANNELNAME=${CHANNEL_NAME_LIST[1]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_channel_configuration/remove_channel    ${mapping2}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_channel_configuration    success_response
