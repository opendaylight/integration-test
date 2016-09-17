*** Settings ***
Documentation     Openstack vpnservice library. This library is useful for vpnservice tests
Library           SSHLibrary
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Associate VPNID to Router
    [Arguments]    ${vpnid}    ${routername}    ${VPN_CONFIG_DIR}    ${REST_CON}
    [Documentation]    Associate a given vpn instance id to a router id
    [Tags]    Post
    ${devstack_conn_id}=    Get ControlNode Connection
    ${routerid}=    Get Router Id    ${routername}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/assoc_router.json
    ${body}    Replace String    ${body}    {vpnId}    ${vpnid}
    ${body}    Replace String    ${body}    {rtrId}    ${routerid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:associateRouter/    data=${body}
    Log    ${resp.content}

Associate Network To VPNID
    [Arguments]    ${networkname}    ${VPN_CONFIG_DIR}    ${JSON_FILE}    ${REST_CON}
    [Documentation]    Associate Networks To VPNID
    [Tags]    Post
    ${devstack_conn_id}=    Get ControlNode Connection
    ${networkid}=    Get Net Id    ${networkname}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${JSON_FILE}
    ${body}    Replace String    ${body}    {netid}    ${networkid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:associateNetworks/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
