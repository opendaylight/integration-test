*** Settings ***
Documentation     Basic tests for BIER information configuration and verification.
...               Copyright (c) 2016-2017 Zte, Inc. and others. All rights reserved.
...               Test suite performs basic BIER information configuration and verification test cases for topology domain, subdomain, node and channel as follows:
...               Test Case 1: Query the topology, node and check their existence
...               Expected result: Exist a topology which topologyId is example-linkstate-topology and five nodes inside it
...               Test Case 2: Configure domain with add and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...               Test Case 3: Configure subdomain with add and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...               Test Case 4: Configure bier node params with add, modify and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...               Test Case 5: Configure bier-te node params with add, modify and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...               Test Case 6: Configure channel with add, modify, deploy and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
Suite Setup       Init All
Suite Teardown    Delete All Sessions
Resource          ../../../libraries/BierTeResource.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot
Library           RequestsLibrary

*** Variables ***
@{NODE_ID_LIST}    1111.1111.1111    1111.1111.1122    1111.1111.1133    1111.1111.1144    1111.1111.1155
${TOPOLOGY_ID}    example-linkstate-topology
@{DOMAIN_ID_LIST}    ${1}    ${2}
@{SUBDOMAIN_ID_LIST}    ${1}    ${2}
@{BFR_ID_LIST}    ${1}    ${2}    ${3}    ${4}    ${5}
@{TE_LABEL_BASE_LIST}    ${1100}    ${2200}    ${3300}    ${4400}    ${5500}
${TE_LABEL_RANGE_SIZE}    ${100}
@{TP_ID_LIST_OF_NODE1}    fei-0/1/0/4    fei-0/1/0/1    fei-0/1/0/7    atm135-0/1/2/2
@{BP_LIST_OF_NODE1}    1    2    3    4
@{TP_ID_LIST_OF_NODE2}    fei-0/1/0/1    atm155-0/1/2/1    fei-0/1/0/6
@{BP_LIST_OF_NODE2}    5    6    15
@{TP_ID_LIST_OF_NODE3}    fei-0/1/0/4    fei-0/1/0/5    pos192-0/1/0/3
@{BP_LIST_OF_NODE3}    7    8    9
@{TP_ID_LIST_OF_NODE4}    fei-0/1/0/5    spi-0/1/0/4    fei-0/1/0/6
@{BP_LIST_OF_NODE4}    10    11    14
&{NODE_TO_TP_ID_LIST}    1111.1111.1111=${TP_ID_LIST_OF_NODE1}    1111.1111.1122=${TP_ID_LIST_OF_NODE2}    1111.1111.1133=${TP_ID_LIST_OF_NODE3}    1111.1111.1144=${TP_ID_LIST_OF_NODE4}
&{NODE_TO_BP_LIST}    1111.1111.1111=${BP_LIST_OF_NODE1}    1111.1111.1122=${BP_LIST_OF_NODE2}    1111.1111.1133=${BP_LIST_OF_NODE3}    1111.1111.1144=${BP_LIST_OF_NODE4}
@{CHANNEL_NAME_LIST}    channel1    channel2    channel3
@{SRC_IP_LIST}    1.1.1.1    2.2.2.2    3.3.3.3
@{DST_GROUP_LIST}    239.1.1.1    239.2.2.2    239.3.3.3

*** Test Cases ***
TC1_Load Topology
    [Documentation]    Verify the topology has been succesfully put into the datastore by querying nodes and topology names.
    Wait Until Keyword Succeeds    30s    2s    Node Online
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/load_topology    {}    session    True

TC1_Query Link
    [Documentation]    Query the all links in the bier topology.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/query_link    ${mapping1}    session    True

TC2_Configure Domain
    [Documentation]    Configure two BIER domains with domain id list ${DOMAIN_ID_LIST}.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    DOMAINID1=${DOMAIN_ID_LIST[0]}    DOMAINID2=${DOMAIN_ID_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_domain_configuration/configure_domain    ${mapping1}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC2_Delete Domain
    [Documentation]    Delete the second domain created in the testcase TC2_Configure Domain.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    DOMAINID=${DOMAIN_ID_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_domain_configuration/delete_domain    ${mapping1}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC2_Query Domain
    [Documentation]    Query the domains created in the datastore.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_domain_configuration/query_domain    ${mapping1}    session    True

TC3_Configure Subdomain
    [Documentation]    Configure two subdomains with subdomain list ${SUBDOMAIN_ID_LIST}.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAIN1=${SUBDOMAIN_ID_LIST[0]}    SUBDOMAIN2=${SUBDOMAIN_ID_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_domain_configuration/configure_subdomain    ${mapping1}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC3_Delete Subdomain
    [Documentation]    Delete the second subdomain created in TC3_Configure Subdomain.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_domain_configuration/delete_subdomain    ${mapping1}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC3_Query Subdomain
    [Documentation]    Query the subdomains in the datastore.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    DOMAINID=${DOMAIN_ID_LIST[0]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_domain_configuration/query_subdomain    ${mapping1}    session    True

TC4_Configure Node
    [Documentation]    Configure the bier params of nodes in the bier network topology.
    FOR    ${i}    IN RANGE    len(${NODE_ID_LIST})
        ${domain-bfr-id}    Get From List    ${BFR_ID_LIST}    ${i}
        ${node-id}    Get From List    ${NODE_ID_LIST}    ${i}
        ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${node-id}    DOMAINID=${DOMAIN_ID_LIST[0]}    DOMAINBFRID=${domain-bfr-id}
        ...    SUBDOMAINBFRID=${domain-bfr-id}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
        ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/configure_node    ${mapping1}    session
        Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response
    END
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/query_node    {}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/configure_node    config_node_response

TC4_Delete Node
    [Documentation]    Configure the bier params of one node in the bier network topology and then delete it.
    ${node-id}    Get From List    ${NODE_ID_LIST}    ${3}
    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}    NODEID=${node-id}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/delete_node    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC4_Delete IPV4
    [Documentation]    Configure the bier params of one node in the bier network topology and delete the ipv4 parameter of it.
    ${node-id}    Get From List    ${NODE_ID_LIST}    ${4}
    ${mapping}    Create Dictionary    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}    NODEID=${node-id}    TOPOLOGYID=${TOPOLOGY_ID}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/delete_ipv4    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC4_Query Subdomain Link
    [Documentation]    Query the bier links in the domain 1 and subdomain 1.
    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/query_subdomain_link    ${mapping}    session    True

TC5_Configure Te Label
    [Documentation]    Configure the BIER-TE label base and label range size for all nodes in the bier topology.
    FOR    ${i}    IN RANGE    len(${NODE_ID_LIST})
        ${node-id}    Get From List    ${NODE_ID_LIST}    ${i}
        ${label-base}    Get From List    ${TE_LABEL_BASE_LIST}    ${i}
        ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${node-id}    LABELBASE=${label-base}    LABELRANGESIZE=${TE_LABEL_RANGE_SIZE}
        ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/configure_te_label    ${mapping}    session
        Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response
    END

TC5_Configure Te Node
    [Documentation]    Configure the BIER-TE params of nodes in the bier network topology.
    FOR    ${i}    IN RANGE    4
        ${node-id}    Get From List    ${NODE_ID_LIST}    ${i}
        ${tp-id-list}    Get From Dictionary    ${NODE_TO_TP_ID_LIST}    ${node-id}
        ${bp-list}    Get From Dictionary    ${NODE_TO_BP_LIST}    ${node-id}
        Second Layer Loop    ${node-id}    ${tp-id-list}    ${bp-list}    len(${bp-list})
    END

TC5_Query Te Subdomain Link
    [Documentation]    Query the bier links in the te-domain 1 and te-subdomain 1.
    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/query_te_subdomain_link    ${mapping}    session    True

TC5_Delete Te BP
    [Documentation]    Configure the bier te params of one node and delete the BP parameter.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${NODE_ID_LIST[4]}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}    TPID=spi-0/1/0/3
    ...    BP=13
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/configure_te_node    ${mapping1}    session
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_TE_VAR_FOLDER}/common    success_response
    ${mapping2}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${NODE_ID_LIST[4]}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}    TPID=spi-0/1/0/3
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/delete_te_bp    ${mapping2}    session
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC5_Delete Te SI
    [Documentation]    Configure the bier te params of one node and delete the SI parameter.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${NODE_ID_LIST[4]}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}    TPID=spi-0/1/0/3
    ...    BP=13
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/configure_te_node    ${mapping1}    session
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_TE_VAR_FOLDER}/common    success_response
    ${mapping2}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${NODE_ID_LIST[4]}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/delete_te_si    ${mapping2}    session
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC5_Delete Te BSL
    [Documentation]    Configure the bier te params of one node and delete the BSL parameter.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${NODE_ID_LIST[4]}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}    TPID=spi-0/1/0/3
    ...    BP=13
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/configure_te_node    ${mapping1}    session
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_TE_VAR_FOLDER}/common    success_response
    ${mapping2}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${NODE_ID_LIST[4]}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/delete_te_bsl    ${mapping2}    session
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC5_Delete Te Label
    [Documentation]    Delete te label base and label range size of one node.
    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${NODE_ID_LIST[4]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/delete_te_label    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response

TC6_Add Channel
    [Documentation]    Add three channels to the datastore defined by bier-network-channel.
    FOR    ${i}    IN RANGE    len(${CHANNEL_NAME_LIST})
        ${channel-name}    Get From List    ${CHANNEL_NAME_LIST}    ${i}
        ${src-ip}    Get From List    ${SRC_IP_LIST}    ${i}
        ${dst-group}    Get From List    ${DST_GROUP_LIST}    ${i}
        ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    CHANNELNAME=${channel-name}    SRCIP=${src-ip}    DSTGROUP=${dst-group}
        ...    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
        ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration/add_channel    ${mapping}    session
        Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration    success_response
    END

TC6_Get Channel
    [Documentation]    Query the channels put into the datastore.
    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration/get_channel    ${mapping}    session    True

TC6_Query Channel
    [Documentation]    Query the channel put into the datastore by given name .
    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    CHANNEL1=${CHANNEL_NAME_LIST[0]}    CHANNEL2=${CHANNEL_NAME_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration/query_channel    ${mapping}    session    True

TC6_Remove Channel
    [Documentation]    Remove one channel which was put into the datastore.
    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    CHANNELNAME=channel3
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration/remove_channel    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration    success_response

TC6_Modify Channel
    [Documentation]    Modify one channel which was put into the datastore.
    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    CHANNELNAME=${CHANNEL_NAME_LIST[0]}    SRCIP=10.10.10.10    DSTGROUP=${DST_GROUP_LIST[0]}    DOMAINID=${DOMAIN_ID_LIST[0]}
    ...    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration/modify_channel    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration    success_response

TC6_Deploy Channel
    [Documentation]    Deploy two channels which was put into the datastore, by giving the ingress node, ingress tp, egress nodes and coressponding tps.
    ${mapping1}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    CHANNELNAME=${CHANNEL_NAME_LIST[0]}    INGRESSNODE=${NODE_ID_LIST[0]}    SRCTP=${TP_ID_LIST_OF_NODE1[3]}    NODEID1=${NODE_ID_LIST[1]}
    ...    RCVTP1=${TP_ID_LIST_OF_NODE2[1]}    NODEID2=${NODE_ID_LIST[2]}    RCVTP2=${TP_ID_LIST_OF_NODE3[2]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration/deploy_channel    ${mapping1}    session
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration    success_response
    ${mapping2}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    CHANNELNAME=${CHANNEL_NAME_LIST[1]}    INGRESSNODE=${NODE_ID_LIST[0]}    SRCTP=${TP_ID_LIST_OF_NODE1[3]}    NODEID1=${NODE_ID_LIST[1]}
    ...    RCVTP1=${TP_ID_LIST_OF_NODE2[1]}    NODEID2=${NODE_ID_LIST[3]}    RCVTP2=${TP_ID_LIST_OF_NODE4[1]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration/deploy_channel    ${mapping2}    session
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_TE_VAR_FOLDER}/bier_channel_configuration    success_response
