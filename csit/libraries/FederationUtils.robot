*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          Netvirt.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot

*** Keywords ***
Run Rest Command For Connecting Networks
    [Arguments]    ${netSiteA}    ${netSiteB}    ${subnetNetSiteA}    ${subnetNetSiteB}    ${subnet_range}    ${session_ip}
    ...    ${odl_ip}
    [Documentation]    run the rest command that connects 2 networks.
    Create Session    session    http://${session_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${data}=    Set Variable    {"input":{"federated-networks-in": [{"self-subnet-id": "${subnetNetSiteA}", "self-net-id": "${netSiteA}", "site-network": [{"site-tenant-id": "7dddfebf-0c32-4d82-9b62-ffbd02d57870", "id": "bc2EaF0B-eBAf-B7b7-92fa-BAA1e83BDEcE", "site-ip": "${odl_ip}", "site-net-id": "${netSiteB}", "site-subnet-id": "${subnetNetSiteB}"}], "subnet-ip": "${subnet_range}", "self-tenant-id": "155d9562-325c-4b3e-bd59-cc551510aa03"}]}, "federated-acls-in":[{"federation-plugin-rpc:self-acl-id": "1784A7D5-d4Ed-6CAB-1b59-ebA5eAD117Af","federation-plugin-rpc:site-acl": [{"federation-plugin-rpc:id": "1784A7D5-d4Ed-6CAB-1b59-ebA5eAD11766","federation-plugin-rpc:site-acl-id": "dccdCf3C-5ABB-128E-ee7C-CcdfDFbCBdbF"}]}]}
    Log    ${data}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/federation-plugin-rpc:update-federated-networks    data=${data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Run Rest Command For Disconnecting Networks
    [Arguments]    ${netSite}    ${subnetNetSite}    ${subnet_range}    ${odl_ip}
    [Documentation]    run the rest command that disconnects 2 networks.
    Create Session    session    http://${odl_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${data}=    Set Variable    {"input":{"federated-networks-in": [{"self-subnet-id": "${subnetNetSite}", "self-net-id": "${netSite}", "site-network": [], "subnet-ip": "${subnet_range}", "self-tenant-id": "155d9562-325c-4b3e-bd59-cc551510aa03"}]}, "federated-acls-in":[]}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/federation-plugin-rpc:update-federated-networks    data=${data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Connect Two Networks
    [Arguments]    ${siteA_index}    ${siteB_index}    ${net_name}    ${subnet_name}    ${subnet_range}
    [Documentation]    Connect networks between 2 sites.
    ${netSiteA}=    Get Network Id    ${siteA_index}    ${net_name}
    ${netSiteB}=    Get Network Id    ${siteB_index}    ${net_name}
    ${subnetNetSiteA}=    Get Network Subnet Id    ${siteA_index}    ${subnet_name}
    ${subnetNetSiteB}=    Get Network Subnet Id    ${siteB_index}    ${subnet_name}
    Run Rest Command For Connecting Networks    ${netSiteA}    ${netSiteB}    ${subnetNetSiteA}    ${subnetNetSiteB}    ${subnet_range}    ${ODL_SYSTEM_1_IP}
    ...    ${ODL_SYSTEM_2_IP}
    Run Rest Command For Connecting Networks    ${netSiteB}    ${netSiteA}    ${subnetNetSiteB}    ${subnetNetSiteA}    ${subnet_range}    ${ODL_SYSTEM_2_IP}
    ...    ${ODL_SYSTEM_1_IP}

Disconnect Two Networks
    [Arguments]    ${siteA_index}    ${siteB_index}    ${net_name}    ${subnet_name}    ${subnet_range}
    [Documentation]    Disconnect networks between 2 sites.
    ${netSiteA}=    Get Network Id    ${siteA_index}    ${net_name}
    ${subnetNetSiteA}=    Get Network Subnet Id    ${siteA_index}    ${subnet_name}
    ${netSiteB}=    Get Network Id    ${siteB_index}    ${net_name}
    ${subnetNetSiteB}=    Get Network Subnet Id    ${siteB_index}    ${subnet_name}
    Run Rest Command For Disconnecting Networks    ${netSiteA}    ${subnetNetSiteA}    ${subnet_range}    ${ODL_SYSTEM_1_IP}
    Run Rest Command For Disconnecting Networks    ${netSiteB}    ${subnetNetSiteB}    ${subnet_range}    ${ODL_SYSTEM_2_IP}
