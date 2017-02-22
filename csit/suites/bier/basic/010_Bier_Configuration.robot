*** Settings ***
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/Utils.robot
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
@{BFR_ID_LIST}    1    2    3    4    5    6    7
...               8    9    10
@{BITSTRINGLENGTH_LIST}    64-bit    128-bit    256-bit
${ENCAPSULATION_TYPE}    ietf-bier:bier-encapsulation-mpls
${IPV4_BFR_PREFIX}    10.41.41.41/22
${IPV6_BFR_PREFIX}    fe80::7009:fe25:8170:36af/64
${BIER_QUERYALLTOPOLOGYID_URI}    /restconf/operations/bier-topology-api

*** Test Cases ***
Query All Topology ID
    ${resp}    Send_Request_To_Query_Topology_Id    bier-topology-api    load-topology
    BuiltIn.Log    ${resp.content}

Query Single Topology
    ${input}=    Create Dictionary    topology-id    ${TOPOLOGY_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    query-topology    ${input}

Configuration Domain
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain    ${DOMAIN_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-domain    ${input}

Delete Domain
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    delete-domain    ${input}

Configuration Subdomain
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain    ${DOMAIN_ID}
    ${resp1}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-domain    ${input1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}    sub-domain
    ...    ${SUBDOMAIN_ID_LIST}
    ${resp2}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-subdomain    ${input2}

Delete Subdomain
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    4
    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    delete-subdomain    ${input}

Configuration Four Node
    ${af}    Construct_Af    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${BFR_ID_LIST[9]}    ${BITSTRINGLENGTH_LIST[0]}
    ...    ${af}
    ${subdomainlist}    Create List    ${subdomain}
    ${bierglobal}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[0]}    ${BFR_ID_LIST[0]}    ${IPV4_BFR_PREFIX}    ${IPV6_BFR_PREFIX}
    ...    ${subdomainlist}
    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bierglobal}
    ${domainlist}    Create List    ${domain}
    : FOR    ${i}    IN RANGE    4
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domainlist}
    \    BuiltIn.Log    ${node}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-node    ${node}

Add Subdomain For Single Node
    ${af}    Construct_Af    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${BFR_ID_LIST[9]}    ${BITSTRINGLENGTH_LIST[0]}
    ...    ${af}
    ${subdomainlist}    Create List    ${subdomain}
    ${newsubdomainlist}    Add_Subdomain    ${subdomainlist}    ${af}
    ${bierglobal}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[0]}    ${BFR_ID_LIST[0]}    ${IPV4_BFR_PREFIX}    ${IPV6_BFR_PREFIX}
    ...    ${newsubdomainlist}
    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bierglobal}
    ${domainlist}    Create List    ${domain}
    : FOR    ${i}    IN RANGE    4
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domainlist}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-node    ${node}

Add Ipv4 Of Subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${BFR_ID_LIST[9]}    ${BITSTRINGLENGTH_LIST[0]}
    ...    ${af}
    ${subdomainlist}    Create List    ${subdomain}
    ${newsubdomainlist}    Add_Subdomain    ${subdomainlist}    ${af}
    ${bierglobal}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[0]}    ${BFR_ID_LIST[0]}    ${IPV4_BFR_PREFIX}    ${IPV6_BFR_PREFIX}
    ...    ${newsubdomainlist}
    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bierglobal}
    ${domainlist}    Create List    ${domain}
    : FOR    ${i}    IN RANGE    4
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domainlist}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-node    ${node}

Modify Leaf Of Domain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${BFR_ID_LIST[9]}    ${BITSTRINGLENGTH_LIST[0]}
    ...    ${af}
    ${subdomainlist}    Create List    ${subdomain}
    ${newsubdomainlist}    Add_Subdomain    ${subdomainlist}    ${af}
    ${bierglobal}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[1]}    ${BFR_ID_LIST[9]}    ${IPV4_BFR_PREFIX}    ${IPV6_BFR_PREFIX}
    ...    ${newsubdomainlist}
    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bierglobal}
    ${domainlist}    Create List    ${domain}
    : FOR    ${i}    IN RANGE    4
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domainlist}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-node    ${node}

Modify Leaf Of Subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    4
    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[0]}    ${MT_ID_LIST[1]}    ${BFR_ID_LIST[8]}    ${BITSTRINGLENGTH_LIST[0]}
    ...    ${af}
    ${subdomainlist}    Create List    ${subdomain}
    ${newsubdomainlist}    Add_Subdomain    ${subdomainlist}    ${af}
    ${bierglobal}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[1]}    ${BFR_ID_LIST[9]}    ${IPV4_BFR_PREFIX}    ${IPV6_BFR_PREFIX}
    ...    ${newsubdomainlist}
    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bierglobal}
    ${domainlist}    Create List    ${domain}
    : FOR    ${i}    IN RANGE    4
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domainlist}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-node    ${node}

Modify Ipv4 Of Subdomain
    ${af}    Add_Or_Modify_Ipv4    ${BSL_OF_IPV4_AND_IPV6[2]}    ${BSL_OF_IPV4_AND_IPV6[0]}    1    5
    ${subdomain}    Construct_Subdomain    ${SUBDOMAIN_ID_LIST[0]}    ${IGP_TYPE_LIST[0]}    ${MT_ID_LIST[1]}    ${BFR_ID_LIST[8]}    ${BITSTRINGLENGTH_LIST[0]}
    ...    ${af}
    ${subdomainlist}    Create List    ${subdomain}
    ${newsubdomainlist}    Add_Subdomain    ${subdomainlist}    ${af}
    ${bierglobal}    Construct_Bier_Global    ${ENCAPSULATION_TYPE}    ${BITSTRINGLENGTH_LIST[1]}    ${BFR_ID_LIST[9]}    ${IPV4_BFR_PREFIX}    ${IPV6_BFR_PREFIX}
    ...    ${newsubdomainlist}
    ${domain}    Construct_Domain    ${DOMAIN_ID}    ${bierglobal}
    ${domainlist}    Create List    ${domain}
    : FOR    ${i}    IN RANGE    4
    \    ${node}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    node-id    ${i+1}
    \    ...    domain    ${domainlist}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    configure-node    ${node}

Delete Ipv4 Of Node4
    ${ipv4one}    Create Dictionary    bitstringlength    64    bier-mpls-label-base    1    bier-mpls-label-range-size
    ...    5
    ${ipv4two}    Create Dictionary    bitstringlength    256    bier-mpls-label-base    1    bier-mpls-label-range-size
    ...    5
    : FOR    ${i}    IN RANGE    3
    \    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    \    ...    sub-domain-id    ${i+1}    node-id    ${SUBDOMAIN_ID_LIST[3]}    ipv4
    \    ...    ${ipv4one}
    \    ${resp1}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    delete-ipv4    ${input1}
    \    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    \    ...    sub-domain-id    ${i+1}    node-id    ${SUBDOMAIN_ID_LIST[3]}    ipv4
    \    ...    ${ipv4two}
    \    ${resp2}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    delete-ipv4    ${input2}

Delete Node4
    : FOR    ${i}    IN RANGE    3
    \    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    domain-id    ${DOMAIN_ID}
    \    ...    sub-domain-id    ${i+1}    node-id    ${SUBDOMAIN_ID_LIST[3]}
    \    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-topology-api    delete-node    ${input}

Add Channel
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    name    channel-1    src-ip
    ...    1.1.1.1    dst-group    224.1.1.1    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    ${SUBDOMAIN_ID_LIST[0]}    source-wildcard    24    group-wildcard    30
    ${resp1}    Send_Request_Operation_Besides_QueryTopologyId    bier-channel-api    add-channel    ${input1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    name    channel-2    src-ip
    ...    2.2.2.2    dst-group    225.1.1.1    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    ${SUBDOMAIN_ID_LIST[1]}    source-wildcard    24    group-wildcard    30
    ${resp2}    Send_Request_Operation_Besides_QueryTopologyId    bier-channel-api    add-channel    ${input2}

Modify Channel
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    name    channel-1    src-ip
    ...    3.3.3.3    dst-group    226.1.1.1    domain-id    ${DOMAIN_ID}    sub-domain-id
    ...    ${SUBDOMAIN_ID_LIST[2]}    source-wildcard    24    group-wildcard    30
    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-channel-api    modify-channel    ${input}

Deploy Channel
    ${egressnode1}    Create Dictionary    node-id    node2
    ${egressnode2}    Create Dictionary    node-id    node3
    ${egressnode}    Create List    ${egressnode1}    ${egressnode2}
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-1    ingress-node
    ...    node1    egress-node    ${egressnode}
    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-channel-api    deploy-channel    ${input}

Modify Deploy Channel
    ${egressnode1}    Create Dictionary    node-id    node1
    ${egressnode2}    Create Dictionary    node-id    node3
    ${egressnode}    Create List    ${egressnode1}    ${egressnode2}
    ${input}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-1    ingress-node
    ...    node2    egress-node    ${egressnode}
    ${resp}    Send_Request_Operation_Besides_QueryTopologyId    bier-channel-api    deploy-channel    ${input}

Remove-Channel
    ${input1}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-1
    ${resp1}    Send_Request_Operation_Besides_QueryTopologyId    bier-channel-api    remove-channel    ${input1}
    ${input2}    Create Dictionary    topology-id    ${TOPOLOGY_ID}    channel-name    channel-2
    ${resp2}    Send_Request_Operation_Besides_QueryTopologyId    bier-channel-api    remove-channel    ${input2}
