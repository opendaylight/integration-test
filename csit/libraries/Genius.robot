*** Settings ***
Documentation     This suite is a common keywordis file for genius project.
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Variables         ../../variables/Variables.py

*** Variables ***

*** Keywords ***
Common Genius Dump DS At TC End
    [Documentation]    This will dump various datastore for debugging.
    Switch Connection    ${conn_id_1}
    ${ovs_show}    Execute Command    sudo ovs-vsctl show
    Log    ${ovs_show}
    Switch Connection    ${conn_id_2}
    ${ovs_show}    Execute Command    sudo ovs-vsctl show
    Log    ${ovs_show}
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:external-tunnel-list/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${oper_int}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-enabled/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${oper_int}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-enabled/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${oper_int}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/odl-interface-meta:bridge-ref-info/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${oper_int}    RequestsLibrary.Get Request    session    ${CONFIG_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/network-topology:network-topology/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    ${int_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/network-topology:network-topology/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
