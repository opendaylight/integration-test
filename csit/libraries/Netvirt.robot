*** Settings ***
Library           RequestsLibrary

*** Variables ***
@{data_models}    config/neutron:neutron    config/neutronvpn:subnetmaps    operational/neutronvpn:subnetmaps    config/neutronvpn:networkMaps    config/neutronvpn:vpnMaps    operational/neutronvpn:neutron-vpn-portip-port-data    config/neutronvpn:router-interfaces-map
...               config/odl-fib:fibEntries    config/odl-l3vpn:vpn-instance-to-vpn-id    config/odl-l3vpn:vpn-id-to-vpn-instance    operational/odl-l3vpn:vpn-instance-op-data    operational/odl-l3vpn:neutron-router-dpns    config/odl-l3vpn:router-interfaces    config/odl-nat:external-networks
...               config/odl-nat:ext-routers    config/odl-nat:floating-ip-info    operational/odl-nat:floating-ip-info    config/odl-nat:napt-switches    config/itm:transport-zones    config/itm-state:dpn-endpoints    config/itm-state:tunnel-list
...               operational/itm-state:tunnels_state    config/ietf-interfaces:interfaces    operational/ietf-interfaces:interfaces-state

*** Keywords ***
Get Model Dump
    [Arguments]    ${controller_ip}
    [Documentation]    Will output a list of mdsal models using ${data_models} list
    Create Session    model_dump_session    http://${controller_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    : FOR    ${model}    IN    @{data_models}
    \    ${resp}=    RequestsLibrary.Get Request    model_dump_session    ${model}
    \    Log    ${resp.content}
    \    Log    ${resp.status_code}
