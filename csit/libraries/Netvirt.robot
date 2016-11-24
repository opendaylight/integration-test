*** Settings ***
Library           RequestsLibrary

*** Variables ***
@{data_models}    config/ietf-interfaces:interfaces
...               config/itm-state:dpn-endpoints
...               config/itm-state:tunnel-list
...               config/itm:transport-zones
...               config/neutron:neutron    
...               config/neutronvpn:networkMaps
...               config/neutronvpn:router-interfaces-map
...               config/neutronvpn:subnetmaps
...               config/neutronvpn:vpnMaps
...               config/odl-fib:fibEntries
...               config/odl-l3vpn:router-interfaces
...               config/odl-l3vpn:vpn-id-to-vpn-instance
...               config/odl-l3vpn:vpn-instance-to-vpn-id
...               config/odl-nat:ext-routers
...               config/odl-nat:external-networks
...               config/odl-nat:floating-ip-info
...               config/odl-nat:napt-switches
...               operational/ietf-interfaces:interfaces-state
...               operational/itm-state:tunnels_state
...               operational/neutronvpn:neutron-vpn-portip-port-data
...               operational/neutronvpn:subnetmaps
...               operational/odl-l3vpn:neutron-router-dpns
...               operational/odl-l3vpn:vpn-instance-op-data
...               operational/odl-nat:floating-ip-info

*** Keywords ***
Get Model Dump
    [Arguments]    ${controller_ip}
    [Documentation]    Will output a list of mdsal models using ${data_models} list
    Create Session    model_dump_session    http://${controller_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    : FOR    ${model}    IN    @{data_models}
    \    ${resp}=    RequestsLibrary.Get Request    model_dump_session    restconf/${model}
    \    Log    ${resp.content}
    \    Log    ${resp.status_code}
