*** Settings ***
Documentation     Test suite for Cloud Capacity Solution
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/VpnOperations.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/OpenStackOperations.robot
Library           RequestsLibrary

*** Variables ***
${fail_resp}    0
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111
${VPN_NAME}       vpn1
${VPN_RD}      ["100:10","100:11","100:12","100:13","100:14"]
${VPN_UPDATED_RD}      ["100:10","100:11","100:12","100:13","100:14","100:15"]
${EXPORT_RT}    ["210:2"]
${IMPORT_RT}    ["210:2"]
${ODL_STREAM}     dummy

*** Testcases ***
Verify CSC supports VPN creation with multiple RD's via neutron bgpvpn create command
    [Documentation]    Verify CSC supports VPN creation with multiple RD's via neutron bgpvpn create command removed bgpvpn openstack
    Log    Create a VPN with multiple RD's
    ${Additional_Args}    Set Variable    -- --route-distinguishers list=true 100:10 100:11 100:12 100:13 100:14
    Create Bgpvpn     BgpVpn1    ${Additional_Args}
    ${vpnid}    Get Bgpvpn Id    BgpVpn1
    Log    Verify Vpn config in controller
    ${KarafLog}    Issue Command On Karaf Console    vpnservice:l3vpn-config-show -vid ${vpnid}
    ${match}    ${RDs}    Should Match Regexp    ${KarafLog}    ${vpnid}.*\\[(.*)\\]
    Should Contain    ${RDs}    100:10
    Should Contain    ${RDs}    100:11
    Should Contain    ${RDs}    100:12
    Should Contain    ${RDs}    100:13
    Should Contain    ${RDs}    100:14


Verify deletion of BGPVPN with Multiple RD's
    [Documentation]    Verify deletion of BGPVPN with Multiple RD's
    [Tags]    SANITY
    Log    Delete the Vpn with Multiple RD's
    ${vpnid}    Get Bgpvpn Id    BgpVpn1
    Delete Bgpvpn    BgpVpn1
    Sleep    ${3}
    ${KarafLog}    Issue Command On Karaf Console    vpnservice:l3vpn-config-show -vid ${vpnid}
    ${Result}    ${val}    Run Keyword And Ignore Error    Should Contain    ${KarafLog}    ${vpnid} is not present
    ${fail_resp}    Run Keyword If    '${Result}'=='PASS'    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1
    Should Be Equal    ${fail_resp}    ${0}

Verify CSC supports VPN creation with multiple RD's via REST API
    [Documentation]    Verify CSC supports VPN creation with multiple RD's via REST API
    [Tags]    SANITY
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    OpenStackOperations.Create Network    Network100
    ${devstack_conn_id} =    OpenStackOperations.Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${NetID}    OpenStackOperations.Get Net Id    Network100    ${devstack_conn_id}
    ${tenant_id}=    OpenStackOperations.Get Tenant ID From Network    ${NetID}
    Set Global Variable    ${tenant_id}
    OpenStackOperations.Delete Network    Network100
    Log    Create a VPN with multiple RD's via REST API
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=${VPN_RD}    exportrt=${EXPORT_RT}    importrt=${IMPORT_RT}    tenantid=${tenant_id}
    ${resp}    VpnOperations.VPN Get L3VPN     vpnid=${VPN_INSTANCE_ID}
    Log    ${resp}
    ${resp}    RequestsLibrary.Get Request    session    /restconf/config/l3vpn:vpn-instances/
    Log    ${resp.content}
    Log    Verify Vpn config in controller
    ${KarafLog}    Issue Command On Karaf Console    vpnservice:l3vpn-config-show -vid ${VPN_INSTANCE_ID}
    ${match}    ${RDs}    Should Match Regexp    ${KarafLog}    ${VPN_INSTANCE_ID}.*\\[(.*)\\]
    Should Contain    ${RDs}    100:10
    Should Contain    ${RDs}    100:11
    Should Contain    ${RDs}    100:12
    Should Contain    ${RDs}    100:13
    Should Contain    ${RDs}    100:14

Verify CSC supports VPN config Update via REST API
    [Documentation]    Verify CSC supports VPN config Update via REST API
    [Tags]    SANITY
    ${resp}    RequestsLibrary.Get Request    session    /restconf/config/l3vpn:vpn-instances/
    Log    ${resp.content}

    Log    Update the VPN config with multiple RD's via REST API
    VpnOperations.VPN Update L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=${VPN_UPDATED_RD}    tenantid=${tenant_id}

    Log    Verify Vpn config in controller
    ${resp}    RequestsLibrary.Get Request    session    /restconf/config/l3vpn:vpn-instances/
    Log    ${resp.content}
    Should Contain    ${resp.content}    100:10
    Should Contain    ${resp.content}    100:11
    Should Contain    ${resp.content}    100:12
    Should Contain    ${resp.content}    100:13
    Should Contain    ${resp.content}    100:14
    Should Contain    ${resp.content}    100:15


Verify Deletion of VPN using REST
    [Documentation]    Verify Deletion of VPN using REST
    [Tags]    SANITY
    Log    Delete VPN via REST API
    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID}

    ${KarafLog}    Issue Command On Karaf Console    vpnservice:l3vpn-config-show -vid ${VPN_INSTANCE_ID}
    ${Result}    ${val}    Run Keyword And Ignore Error    Should Contain    ${KarafLog}    ${VPN_INSTANCE_ID} is not present
    ${fail_resp}    Run Keyword If    '${Result}'=='PASS'    Evaluate    ${fail_resp}+0    ELSE    Evaluate    ${fail_resp}+1

    Should Be Equal    ${fail_resp}    ${0}



*** Keywords ***
Create Bgpvpn
    [Arguments]    ${vpnname}    ${additional_args}=${EMPTY}
    [Documentation]    Create Bgpvpn with neutron request.
    ${devstack_conn_id}=    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v bgpvpn-create --name ${vpnname} ${additional_args}    30s
    SSHLibrary.Close Connection
    Log    ${output}
    Should Contain    ${output}    Created a new bgpvpn

Bgpvpn Net Associate
    [Arguments]    ${network_name}    ${vpnname}
    [Documentation]    Associate Network to given Vpn with neutron request
    ${devstack_conn_id}=    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron bgpvpn-net-assoc-create --network ${network_name} ${vpnname}
    SSHLibrary.Close Connection
    Log    ${output}

Bgpvpn Router Associate
    [Arguments]    ${router_name}    ${vpnname}
    [Documentation]    Associate Router to given Vpn with neutron request
    ${devstack_conn_id}=    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron bgpvpn-router-assoc-create --router ${router_name} ${vpnname}
    SSHLibrary.Close Connection
    Log    ${output}

Delete Bgpvpn
    [Arguments]    ${vpnname}
    [Documentation]    Delete Bgpvpn with neutron request.
    ${devstack_conn_id}=    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v bgpvpn-delete --name ${vpnname}    30s
    SSHLibrary.Close Connection
    Log    ${output}
    Should Contain    ${output}    Deleted bgpvpn: ${vpnname}

Bgpvpn Net DisAssociate
    [Arguments]    ${AssociationID}    ${vpnname}
    [Documentation]    Dis-Associate Network to given Vpn with neutron request
    ${devstack_conn_id}=    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron bgpvpn-net-assoc-delete ${AssociationID} ${vpnname}
    SSHLibrary.Close Connection
    Log    ${output}

Bgpvpn Router DisAssociate
    [Arguments]    ${AssociationID}    ${vpnname}
    [Documentation]    Dis-Associate Router to given Vpn with neutron request
    ${devstack_conn_id}=    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron bgpvpn-router-assoc-delete ${AssociationID} ${vpnname}
    SSHLibrary.Close Connection
    Log    ${output}

Bgpvpn Update
    [Arguments]    ${vpnname}    ${additional_args}=${EMPTY}
    [Documentation]    Update Bgpvpn with neutron request.
    ${devstack_conn_id}=    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron -v bgpvpn-update ${vpnname} ${additional_args}    30s
    SSHLibrary.Close Connection
    Log    ${output}

Get Bgpvpn Id
    [Arguments]    ${vpnname}
    [Documentation]    Retrieve the Bgpvpn id for the given name
    ${devstack_conn_id}=    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron bgpvpn-list | grep "${vpnname}" | awk '{print $2}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${vpn_id}=    Get from List    ${splitted_output}    0
    [Return]    ${vpn_id}
