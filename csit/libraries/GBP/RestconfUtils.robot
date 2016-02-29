*** Settings ***
Documentation     Utils for Restconf operations for GBP
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           json
Variables         ../../variables/Variables.py
Resource          ../Utils.robot

*** Variables ***
${ENDPOINT_UNREG_PATH}    ${GBP_UNREGEP_API}
${ENDPOINTS_OPER_PATH}    /restconf/operational/endpoint:endpoints

*** Keywords ***
Unregister Endpoints
    [Documentation]    Unregister Endpoints Endpoints from ODL
    ${result} =    RequestsLibrary.Get Request    session    ${ENDPOINTS_OPER_PATH}
    ${json_result} =    json.loads    ${result.text}
    Pass Execution If    ${json_result['endpoints']}=={}    No Endpoints available
    ${L2_ENDPOINTS} =    Set Variable    ${json_result['endpoints']['endpoint']}
    ${L3_ENDPOINTS} =    Set Variable    ${json_result['endpoints']['endpoint-l3']}
    Log    ${L2_ENDPOINTS}
    Unregister L2Endpoints    ${L2_ENDPOINTS}
    Log    ${L3_ENDPOINTS}
    Unregister L3Endpoints    ${L3_ENDPOINTS}
    ${result} =    RequestsLibrary.Get Request    session    ${ENDPOINTS_OPER_PATH}
    ${json_result} =    json.loads    ${result.text}
    Should Be Empty    ${json_result['endpoints']}

Unregister L2Endpoints
    [Arguments]    ${l2_eps}
    [Documentation]    Unregister Endpoints L2Endpoints from ODL
    : FOR    ${endpoint}    IN    @{l2_eps}
    \    ${l2_data} =    Create L2 Endpoint JSON Data    ${endpoint}
    \    Post Elements To URI    ${ENDPOINT_UNREG_PATH}    ${l2_data}    ${HEADERS_YANG_JSON}

Unregister L3Endpoints
    [Arguments]    ${l3_eps}
    [Documentation]    Unregister Endpoints L3Endpoints from ODL
    : FOR    ${endpoint}    IN    @{l3_eps}
    \    ${l3_data} =    Create L3 Endpoint JSON Data    ${endpoint}
    \    Post Elements To URI    ${ENDPOINT_UNREG_PATH}    ${l3_data}    ${HEADERS_YANG_JSON}

Create L2 Endpoint JSON Data
    [Arguments]    ${endpoint}
    [Documentation]    Generate the JSON data required for unregistering L2 Endpoints
    ${data}    Set Variable    {"input": {"l2": [{"mac-address": "${endpoint['mac-address']}", "l2-context": "${endpoint['l2-context']}"}]}}
    [Return]    ${data}

Create L3 Endpoint JSON Data
    [Arguments]    ${endpoint}
    [Documentation]    Generate the JSON data required for unregistering L3 Endpoints
    ${data}    Set Variable    {"input": {"l3": [{"l3-context": "${endpoint['l3-context']}", "ip-address": "${endpoint['ip-address']}"}]}}
    [Return]    ${data}

Get Endpoint Path
    # TODO endpoints path
    [Arguments]    ${l2-context}    ${mac_address}
    ${mac_address}    Convert To Uppercase    ${mac_address}
    [Return]    restconf/operational/endpoint:endpoints/endpoint/${l2-context}/${mac_address}

Get EndpointL3 Path
    # TODO endpoints path
    [Arguments]    ${l3-context}    ${ip_address}
    [Return]    restconf/operational/endpoint:endpoints/endpoint-l3/${l3-context}/${ip_address}

Get Tenant Path
    [Arguments]    ${tenant_id}
    # TODO variables
    [Return]    ${TENANTS_CONF_PATH}/policy:tenant/${tenant_id}

Get Policy Path
    [Arguments]    ${tenant_id}
    ${tenant_path}    Get Tenant Path    ${tenant_id}
    [Return]    ${tenant_path}/policy

Get Contract Path
    [Arguments]    ${tenant_id}    ${contract_id}
    ${policy_path}    Get Policy Path    ${tenant_id}
    [Return]    ${policy_path}/contract/${contract_id}

Get Endpoint Group Path
    [Arguments]    ${tenant_id}    ${endpoint_group_id}
    ${policy_path}    Get Policy Path    ${tenant_id}
    [Return]    ${policy_path}/endpoint-group/${endpoint_group_id}

Get Classifier Instance Path
    [Arguments]    ${tenant_id}    ${classif_instance_id}
    ${policy_path}    Get Policy Path    ${tenant_id}
    [Return]    ${policy_path}/subject-feature-instances/classifier-instance/${classif_instance_id}

Get Forwarding Context Path
    [Arguments]    ${tenant_id}
    ${tenant_path}    Get Tenant Path    ${tenant_id}
    [Return]    ${tenant_path}/forwarding-context

Get L3 Context Path
    [Arguments]    ${tenant_id}    ${l3_ctx_id}
    ${fwd_ctx_path}    Get Forwarding Context Path    ${tenant_id}
    [Return]    ${fwd_ctx_path}/l3-context/${l3_ctx_id}

Get L2 Bridge Domain Path
    [Arguments]    ${tenant_id}    ${l2_br_domain_id}
    ${fwd_ctx_path}    Get Forwarding Context Path    ${tenant_id}
    [Return]    ${fwd_ctx_path}/l2-bridge-domain/${l2_br_domain_id}

Get L2 Flood Domain Path
    [Arguments]    ${tenant_id}    ${l2_flood_domain_id}
    ${fwd_ctx_path}    Get Forwarding Context Path    ${tenant_id}
    [Return]    ${fwd_ctx_path}/l2-flood-domain/${l2_flood_domain_id}

Get Subnet Path
    [Arguments]    ${tenant_id}    ${subnet_id}
    ${fwd_ctx_path}    Get Forwarding Context Path    ${tenant_id}
    [Return]    ${fwd_ctx_path}/subnet/${subnet_id}

Get Prefix Constraint of Single Rule Contract
    [Arguments]    ${contract}
    ${contract_json}    To Json    ${contract}
    ${eic}   Set Variable
    ...    ${contract_json['contract'][0]['clause'][0]['consumer-matchers']['endpoint-identification-constraints']}
    [Return]    ${eic['l3-endpoint-identification-constraints']['prefix-constraint'][0]}

Get Action of Single Rule Contract
    [Arguments]    ${contract}
    ${contract_json}    To Json    ${contract}
    [Return]    ${contract_json['contract'][0]['subject'][0]['rule'][0]['action-ref'][0]}

Get Ip Prefix of Subnet
    [Arguments]    ${subnet}
    ${subnet_json}    To Json    ${subnet}
    [Return]    ${subnet_json['subnet'][0]['ip-prefix']}

Get Action Instance Name of Single Rule Contract
    [Arguments]    ${contract}
    ${contract_json}    To Json    ${contract}
    [Return]    ${contract_json['contract'][0]['subject'][0]['rule'][0]['classifier-ref'][0]['instance-name']}

Get Groups of Endpoint
    [Arguments]    ${endpoint}
    ${endpoint_json}    To Json    ${endpoint}
    [Return]    ${endpoint_json['endpoint'][0]['endpoint-groups']}

Get Groups of Endpoint-L3
    [Arguments]    ${endpoint-l3}
    ${endpoint_json}    To Json    ${endpoint-l3}
    [Return]    ${endpoint_json['endpoint-l3'][0]['endpoint-groups']}

Get L3-Addresses of Endpoint
    [Arguments]    ${endpoint}
    ${endpoint_json}    To Json    ${endpoint}
    [Return]    ${endpoint_json['endpoint'][0]['l3-address']}

Get Tenant of Endpoint
    [Arguments]    ${endpoint}
    ${endpoint_json}    To Json    ${endpoint}
    [Return]    ${endpoint_json['endpoint'][0]['tenant']}

Get Tenant of Endpoint-L3
    [Arguments]    ${endpoint-l3}
    ${endpoint_json}    To Json    ${endpoint-l3}
    [Return]    ${endpoint_json['endpoint-l3'][0]['tenant']}

Get Network Containment of Endpoint
    [Arguments]    ${endpoint}
    ${endpoint_json}    To Json    ${endpoint}
    [Return]    ${endpoint_json['endpoint'][0]['network-containment']}

Get Network Containment of Endpoint-L3
    [Arguments]    ${endpoint-l3}
    ${endpoint_json}    To Json    ${endpoint-l3}
    [Return]    ${endpoint_json['endpoint-l3'][0]['network-containment']}

Get Mac Address of Endpoint
    [Arguments]    ${endpoint}
    ${endpoint_json}  To Json       ${endpoint}
    [Return]          ${endpoint_json['endpoint'][0]['mac-address']}

Get Mac Address of Endpoint-L3
    [Arguments]    ${endpoint-l3}
    ${endpoint_json}  To Json       ${endpoint-l3}
    [Return]          ${endpoint_json['endpoint-l3'][0]['mac-address']}

Get L2 Context of Endpoint-L3
    [Arguments]    ${endpoint-l3}
    ${endpoint_json}    To Json    ${endpoint-l3}
    [Return]    ${endpoint_json['endpoint-l3'][0]['l2-context']}
