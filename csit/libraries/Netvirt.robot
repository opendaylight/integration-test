*** Settings ***
Library           RequestsLibrary

*** Variables ***
@{data_models}    config/ietf-interfaces:interfaces    config/interface-service-bindings:service-bindings    config/itm-state:dpn-endpoints    config/itm-state:tunnel-list    config/itm:transport-zones    config/neutron:neutron    config/neutronvpn:networkMaps    config/neutronvpn:subnetMaps    config/neutronvpn:router-interfaces-map
...               config/neutronvpn:vpnMaps    config/odl-fib:fibEntries    config/odl-l3vpn:router-interfaces    config/l3vpn:vpn-instances    config/odl-l3vpn:vpn-id-to-vpn-instance    config/odl-l3vpn:vpn-instance-to-vpn-id    config/l3vpn:vpn-interfaces    operational/neutronvpn:neutron-vpn-portip-port-data
...               config/odl-nat:ext-routers    config/odl-nat:external-networks    config/odl-nat:floating-ip-info    config/odl-nat:napt-switches    config/opendaylight-inventory:nodes    operational/ietf-interfaces:interfaces-state    operational/odl-l3vpn:vpn-to-extraroute    operational/l3nexthop:l3nexthop
...               operational/itm-state:tunnels_state    operational/odl-l3vpn:neutron-router-dpns    operational/odl-l3vpn:vpn-instance-op-data    operational/l3vpn:vpn-interfaces    operational/odl-nat:floating-ip-info    operational/odl-l3vpn:prefix-to-interface
...               config/elan:elan-instances    config/elan:elan-interfaces    operational/elan:elan-interfaces    operational/elan:elan-forwarding-tables    operational/elan:elan-state

*** Keywords ***
Get Model Dump
    [Arguments]    ${controller_ip}
    [Documentation]    Will output a list of mdsal models using ${data_models} list
    Create Session    model_dump_session    http://${controller_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    : FOR    ${model}    IN    @{data_models}
    \    ${resp}=    RequestsLibrary.Get Request    model_dump_session    restconf/${model}
    \    Log    ${resp.status_code}
    \    ${pretty_output}=    To Json    ${resp.content}    pretty_print=True
    \    Log    ${pretty_output}
