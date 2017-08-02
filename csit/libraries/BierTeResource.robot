*** Settings ***
Documentation     Robot keyword library (Resource) for BIER information configuration and verification Python utilities.
...
...               Copyright (c) 2016-2017 Zte, Inc. and others. All rights reserved.
...
...               This resource contains some keywords which complete four main functions:
...               Send corresponding request to datastore,
...               Construct BIER information,
...               Verity Configuration success or not and its result,
...               Delete BIER configuration and close all session.
Resource          TemplatedRequests.robot
Library           SSHLibrary

*** Variables ***
${BIER_TE_VAR_FOLDER}    ${CURDIR}/../variables/bier
@{NETCONF_PORT_LIST}    17830    17831    17832    17833    17834
${TESTTOOL_PATH}    /root
${TESTTOOL_VERSION}    netconf-testtool-1.3.0-SNAPSHOT-executable.jar
${TESTTOOL_SCHEME}    ./yang_ietf_bier

*** Keywords ***
InitAll
    [Documentation]    Init the configuration datastore defined by YANG modules bier-network-topology and bier-network-channel, the Testtool for to simulate the netconf devices, and the netconf connecting IP address and port for the ODL controller.
    InitBierTopology
    InitChannel

InitBierTopology
    [Documentation]    Init the configuration datastore defined by the YANG module bier-network-topology.
    ${resp}    TemplatedRequests.Put_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_init_all/bier_init_biertopology    {}    session

Initchannel
    [Documentation]    Init the configuration datastore defined by the YANG module bier-network-channel.
    ${resp}    TemplatedRequests.Put_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_init_all/bier_init_channel    {}    session

DeleteAll
    [Documentation]    Delete the testtool process and http sessions.
    DeleteSessions

DeleteSessions
    [Documentation]    Shut down the http sessions.
    Delete All Sessions

NodeOnline
    [Documentation]    Verify the Keyword InitBierTopology has been successfully executed by query and verify the nodes in the datastore.
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/query_node    {}    session    True

FORJ
    [Arguments]    ${node-id}    ${tp-id-list}    ${bp-list}    ${length}
    : FOR    ${j}    IN RANGE    ${length}
    \    ${tp-id}    Get From List    ${tp-id-list}    ${j}
    \    ${bp}    Get From List    ${bp-list}    ${j}
    \    ${mapping}    Create Dictionary    TOPOLOGYID=${TOPOLOGY_ID}    NODEID=${node-id}    DOMAINID=${DOMAIN_ID_LIST[0]}    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    \    ...    TPID=${tp-id}    BP=${bp}
    \    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_TE_VAR_FOLDER}/bier_node_configuration/configure_te_node    ${mapping}    session
    \    Verify_Response_As_Json_Templated    ${resp}    ${BIER_TE_VAR_FOLDER}/common    success_response
