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
Library           Collections
Library           RequestsLibrary
Library           json
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${SESSION}        session
${BIER_VAR_FOLDER}    ${CURDIR}/../variables/bier

*** Keywords ***
Node_Online
    [Documentation]    Send request to query nodes and verify their existence
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/query_node    {}    ${SESSION}    True

Send_Request_To_Query_Topology_Id
    [Arguments]    ${module}    ${oper}
    [Documentation]    Send request to controller to query topologyid through REST-API using POST method, ${module} represents yang module and ${oper} represents rpc operation
    ${resp}    Post Request    ${SESSION}    /restconf/operations/${module}:${oper}
    BuiltIn.Log    ${resp.content}
    [Return]    ${resp}

Delete_All
    [Documentation]    Delete domain and subdomain which were configured previous and close restconf session
    ${mapping1}    Create Dictionary    SUBDOMAINID=${SUBDOMAIN_ID_LIST[2]}
    ${resp1}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_subdomain    ${mapping1}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp1}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response
    ${mapping2}    Create Dictionary    SUBDOMAINID=${SUBDOMAIN_ID_LIST[1]}
    ${resp2}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_subdomain    ${mapping2}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp2}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response
    ${mapping3}    Create Dictionary    SUBDOMAINID=${SUBDOMAIN_ID_LIST[0]}
    ${resp3}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_subdomain    ${mapping3}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp3}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response
    ${resp4}    TemplatedRequests.Post_As_Json_Templated    ${BIER_VAR_FOLDER}/bier_node_configuration/delete_domain    {}    ${SESSION}
    Verify_Response_As_Json_Templated    ${resp4}    ${BIER_VAR_FOLDER}/bier_node_configuration    success_response
    RequestsLibrary.Delete_All_Sessions
