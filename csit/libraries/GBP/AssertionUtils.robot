*** Settings ***
Documentation     Utils for Restconf operations for GBP
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Variables         ../../variables/Variables.py
Resource          ../../variables/gbp/Constants.robot
Resource          ../Utils.robot
Resource          RestconfUtils.robot

*** Variables ***

*** Keywords ***
Assert Subnet
    [Arguments]    ${subnet_to_check}    ${subnet_name}    ${ip_prefix_to_check}
    [Documentation]    Checks name and ip prefix of given subnet and returns parent ID
    ${parent}    Assert Forwarding Domain    ${subnet_to_check}    ${subnet_name}    return_parent=TRUE
    ${ip_prefix}    Get Ip Prefix of Subnet    ${subnet_to_check}
    Should Be Equal As Strings    ${ip_prefix}    ${ip_prefix_to_check}
    [Return]    ${parent}

Assert L2-Flood-Domain
    [Arguments]    ${l2_flood_domain_to_check}    ${l2_flood_domain_name}
    [Documentation]    Checks name of given l2-flood-domain and returns parent ID
    ${parent}    Assert Forwarding Domain    ${l2_flood_domain_to_check}    ${l2_flood_domain_name}    return_parent=TRUE
    [Return]    ${parent}

Assert L2-Bridge-Domain
    [Arguments]    ${l2_bridge_domain_to_check}    ${l2_bridge_domain_name}
    [Documentation]    Checks name of given l2-bridge-domain and returns parent ID
    ${parent}    Assert Forwarding Domain    ${l2_bridge_domain_to_check}    ${l2_bridge_domain_name}    return_parent=TRUE
    [Return]    ${parent}

Assert L3-Context
    [Arguments]    ${l3_context_to_check}    ${l3_context_name}
    [Documentation]    Checks name of given l3-context
    ${parent}    Assert Forwarding Domain    ${l3_context_to_check}    ${l3_context_name}
    [Return]    ${parent}

Assert Forwarding Domain
    [Arguments]    ${domain_to_check}    ${domain_name}    ${return_parent}=FALSE
    [Documentation]    Checks name of given l3-context
    Check Name    ${domain_to_check}    ${domain_name}
    Return From Keyword If    "${return_parent}" == "FALSE"
    ${parent}    Get Parent    ${domain_to_check}
    [Return]    ${parent}

Check Name
    [Arguments]    ${data}    ${name}
    [Documentation]    Checks correct format of a name field in JSON data
    Should Not Be Empty    ${data}
    Should Match Regexp    ${data}    \"name\":\"${NAME_PATTERN}\"

Check CI Range Values
    [Arguments]    ${range_value_json}    ${min}    ${max}
    [Documentation]    Veriefies min and max values of range-value of classifier-instance in JSON format
    Should Be Equal As Numbers    ${min}    ${range_value_json['min']}
    Should Be Equal As Numbers    ${max}    ${range_value_json['max']}

Get Parent
    [Arguments]    ${data}
    [Documentation]    Returns 'parent' value of an JSON object. Can be applied to Subnet, L2-Flood-Domain or L2-Bridge-Domain
    Should Not Be Empty    ${data}
    ${parent_line}    Should Match Regexp    ${data}    \"parent\":\"${UUID_PATTERN}\"
    ${parent_uuid}    Should Match Regexp    ${parent_line}    ${UUID_PATTERN}
    [Return]    ${parent_uuid}

Check Endpoint
    [Arguments]    ${endpoint}    ${ip_address}    ${epg}    ${l3-context}    ${network-containment}    ${tenant}
    [Documentation]    Verifies parameters of given endpoint in JSON format
    Should Contain    ${endpoint}    ofoverlay:port-name
    @{ep_l3-addresses}    Get L3-Addresses of Endpoint    ${endpoint}
    @{ep_endpoint_groups}    Get Groups of Endpoint    ${endpoint}
    ${ep_network-containment}    Get Network Containment of Endpoint    ${endpoint}
    ${ep_tenant}    Get Tenant of Endpoint    ${endpoint}
    @{ep_endpoint_groups}    Get Groups of Endpoint    ${endpoint}
    Should Be Equal As Strings    ${ep_network-containment}    ${network-containment}
    Should Be Equal As Strings    ${ep_tenant}    ${tenant}
    Check Group References    ${epg}    @{ep_endpoint_groups}
    LOG    ${ep_l3-addresses}
    : FOR    ${l3}    IN    @{ep_l3-addresses}
    \    LOG    ${l3-context}
    \    LOG    ${ip_address}
    \    LOG    ${l3['l3-context']}
    \    LOG    ${l3['ip-address']}
    \    Continue For Loop If    "${l3['l3-context']}" == "${l3-context}" and "${l3['ip-address']}" == "${ip_address}"
    \    Fail

Check Endpoint-L3
    [Arguments]    ${endpoint-l3}    ${mac_address}    ${epg}    ${l2-context}    ${network-containment}    ${tenant}
    [Documentation]    Verifies parameters of registerd endpoint-l3 in JSON format
    Should Contain    ${endpoint-l3}    ofoverlay:port-name
    ${ep_l2-context}    Get L2 Context of Endpoint-L3    ${endpoint-l3}
    ${ep_mac_address}    Get Mac Address of Endpoint-L3    ${endpoint-l3}
    ${ep_network-containment}    Get Network Containment of Endpoint-L3    ${endpoint-l3}
    ${ep_tenant}    Get Tenant of Endpoint-L3    ${endpoint-l3}
    @{ep_endpoint_groups}    Get Groups of Endpoint-L3    ${endpoint-l3}
    Should Be Equal As Strings    ${ep_mac_address}    ${mac_address}
    Should Be Equal As Strings    ${ep_l2-context}    ${l2-context}
    Should Be Equal As Strings    ${network-containment}    ${network-containment}
    Should Be Equal As Strings    ${tenant}    ${tenant}
    Check Group References    ${epg}    @{ep_endpoint_groups}

Check Group References
    [Arguments]    ${epg_to_look_for}    @{endpoint_groups}
    [Documentation]    Verifies presence of endpoint group to which endpoint belongs and presence of network_client group
    ...    among given endpoint groups
    Should Not Be Empty    ${epg_to_look_for}
    Should Not Be Empty    ${endpoint_groups}
    : FOR    ${epg}    IN    @{endpoint_groups}
    \    Continue For Loop If    "${epg}" == "${epg_to_look_for}"
    \    Continue For Loop If    "${epg}" == "${NETWORK_CLIENT_GROUP}"
    \    Fail

Check Endpoint Group Name and Selector
    [Arguments]    ${epg_id}    ${epg_name}    ${tenant_id}    ${contract_id}    ${named-selector}
    [Documentation]    Verifies data generated by security group and security group rules
    ${epg_path}    Get Endpoint Group Path    ${tenant_id}    ${epg_id}
    ${endpoint_group}    Get Data From URI    session    ${epg_path}    headers=${headers}
    Should Not Be Empty    ${endpoint_group}
    Check Name    ${endpoint_group}    ${epg_name}
    ${endpoint_group_json}    To Json    ${endpoint_group}
    ${named_selectors}    Set Variable    ${endpoint_group_json['endpoint-group'][0]['${named-selector}']}
    ${selector_found}    Set Variable    FALSE
    : FOR    ${selector}    IN    @{named_selectors}
    \    Return From Keyword If    "${selector['contract'][0]}" == "${contract_id}"
    Fail

Verify Allow Action in Single Rule Contract
    [Arguments]    ${contract}
    [Documentation]    Verifies allow action in single rule contract
    ${action_ref}    Get Action of Single Rule Contract    ${contract}
    Should Be Equal As Strings    ${action_ref['name']}    Allow

Verify Single Remote Ip Prefix In Contract
    [Arguments]    ${contract}    ${ip_prefix}
    [Documentation]    Verifies remote ip prefix in single prefix contract
    ${prefix_constraint}    Get Prefix Constraint of Single Rule Contract    ${contract}
    Should Be Equal As Strings    ${prefix_constraint['ip-prefix']}    ${ip_prefix}
