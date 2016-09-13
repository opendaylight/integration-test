*** Settings ***
Documentation     Vpnservice library. This library is useful for tests
                  ...  to create network, subnet, router and vm instances
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
                  ...  auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py
${VPN_CONFIG_DIR}    ${CURDIR}/../../variables/vpnservice
${REST_CON}       /restconf/config/
${REST_CON_OP}     /restconf/operations/



*** Keywords ***

Create L3 VPN Instance
    [Arguments]    ${vpn_instance}
    [Documentation]    Creates L3 VPN Instance through restconf
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${vpn_instance}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON_OP}neutronvpn:createL3VPN
    ...   data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Verify L3 vpn instance
    [Arguments]    ${vpnid_instance}
    [Documentation]    Verify L3 VPN Instance through restconf
    [Tags]    Get
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${vpnid_instance}
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CON_OP}neutronvpn:getL3VPN
    ...  data=${body}       headers=  ${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete L3 VPNs instances
    [Documentation]    Delete L3 VPN instance
    ${resp}    RequestsLibrary.Delete Request    session    ${REST_CON}l3vpn:vpn-instances
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Create L3 VM-VPN interface
    [Arguments]  ${body}
    [Documentation]    Creates vm-vpn interface for the corresponding ietf interface
    [Tags]    Post
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}l3vpn:vpn-interfaces/
    ...   data=${body}
    Should Be Equal As Strings    ${resp.status_code}    204

Create L3 VPN interface
    [Arguments]  ${VPN_NAME} ${vm_id} ${vm_ip} ${vm_mac}
    [Documentation]    creating L3 vpn interfaces
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vm_vpn_interface.json
    ${body} =    Replace String    ${body}    VM_ID    ${vm_id}
    ${body} =    Replace String    ${body}    VM_IP    ${vm_ip}
    ${body} =    Replace String    ${body}    VM_MAC    ${vm_mac}
    ${body} =    Replace String    ${body}    VPN_NAME    ${VPN_NAME}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}l3vpn:vpn-interfaces/
    ...  data=${body}
    Should Be Equal As Strings    ${resp.status_code}    204

Associate VPN to Router
    [Documentation]    Associate VPN to Router
    [Arguments]  ${ROUTER} ${VPN_INSTANCE_NAME}
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_router.json
    ${body} =    Replace String    ${body}    VPN_ID    ${VPN_INSTANCE_NAME}
    ${body} =    Replace String    ${body}    ROUTER_ID    ${ROUTER}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON_OP}neutronvpn:associateRouter
    ...  data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Restart VM
    [Arguments]  ${VM_INSTANCES}
    [Documentation]    Restart VMs
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write   sudo nova reboot ${VM_INSTANCES}
    sleep     60s
    Close Connection

Associate Network to VPN
    [Arguments]  ${VPN_ID} ${NETWORK_ID}
    [Documentation]    Associate Network to VPN
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_network.json
    ${body} =    Replace String    ${body}    VPN_ID    ${VPN_ID}
    ${body} =    Replace String    ${body}    NETWORK_ID    ${NETWORK_ID}
    ${resp}    RequestsLibrary.Post Request    session  ${REST_CON_OP}neutronvpn:associateNetworks
    ...  data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Disassociate Network from VPN
    [Arguments]  ${VPN_ID} ${NETWORK_ID}
    [Documentation]    Disassociate Network from VPN
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_network.json
    ${body} =    Replace String    ${body}    VPN_ID    ${VPN_ID}
    ${body} =    Replace String    ${body}    NETWORK_ID    ${NETWORK_ID}
    ${resp}    RequestsLibrary.Post Request    session  ${REST_CON_OP}neutronvpn:dissociateNetworks
    ...  data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204