*** Settings ***
Documentation     Test Suite for ITM
Suite Setup       Genius Suite Setup
Suite Teardown    Genius Suite Teardown
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           re
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../../variables/genius

*** Test Cases ***
Create and Verify VTEP -No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    ${vlan}=    BuiltIn.Set Variable    0
    ${gateway-ip}=    BuiltIn.Set Variable    0.0.0.0
    Genius.Create Vteps    ${vlan}    ${gateway-ip}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Get Tunnels On All DPNs
    Comment    ${k}    BuiltIn.Set Variable    0
    Comment    BuiltIn.Set Suite Variable    ${k}
    Comment    Get Tunnel Between DPNs    ${type}
    ${tunnel-type}=    BuiltIn.Set Variable    type: vxlan
    Genius.Verify Data From URL
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification    @{TOOLS_SYSTEM_LIST}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status as UP
    Verify Network Topology
    Verify Ietf Interface State
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Log    ${respjson}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Delete and Verify VTEP -No Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-list}    Genius.Get Tunnels List
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.verify Deleted Tunnels on OVS    ${tunnel-list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel-list}

Create and Verify VTEP IPv6 - No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    ${vlan}=    BuiltIn.Set Variable    0
    ${gateway-ip}=    BuiltIn.Set Variable    ::
    @{TOOLS_SYSTEM_IPV6_LIST}    BuiltIn.Create List
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    Collections.Append To List    ${TOOLS_SYSTEM_IPV6_LIST}    fd96:2a25:4ad3:3c7d:0:0:${i}:1000
    BuiltIn.Log Many    @{TOOLS_SYSTEM_IPV6_LIST}
    BuiltIn.Set Suite Variable    @{TOOLS_SYSTEM_IPV6_LIST}
    Create Vteps IPv6    ${vlan}    ${gateway-ip}    ${TOOLS_SYSTEM_IPV6_LIST}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Get ITM IPV6    ${itm_created[0]}    ${subnet}    ${vlan}
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-type}=    BuiltIn.Set Variable    type: vxlan
    Get Tunnels On All DPNs
    Comment    ${k}    BuiltIn.Set Variable    0
    Comment    BuiltIn.Set Suite Variable    ${k}
    Comment    Get Tunnel Between DPNs    ${type}
    : FOR    ${dpn}    IN    @{DPN_ID_LIST}
    \    BuiltIn.Wait Until Keyword Succeeds    40    5    Utils.Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn}/
    \    ...    headers=${ACCEPT_XML}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OVS Verification Between IPV6    @{TOOLS_SYSTEM_LIST}
    @{all_tunnels}    BuiltIn.Create List
    : FOR    ${conn_id}    IN    @{CONN_ID_LIST}
    \    ${tun_names}    Genius.Get Tunnels On OVS    ${conn_id}
    \    Collections.Append To List    ${all_tunnels}    @{tun_names}
    BuiltIn.Log Many    @{all_tunnels}
    @{network_topology_list}    BuiltIn.Create List    @{all_tunnels}
    @{network_topology_list}    Collections.Combine Lists    ${network_topology_list}    ${BRIDGE}
    ${resp}    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${OPERATIONAL_TOPO_API}    ${network_topology_list}

Delete and Verify VTEP IPv6 -No Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-list}    Genius.Get Tunnels List
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.verify Deleted Tunnels on OVS    ${tunnel-list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel-list}

Create and Verify VTEP-Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and \ without Gateway configured in Json.
    ${vlan}=    BuiltIn.Set Variable    100
    ${gateway-ip}=    BuiltIn.Set Variable    0.0.0.0
    Genius.Create Vteps    ${vlan}    ${gateway-ip}
    ${get}    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${subnet}
    ...    ${vlan}
    BuiltIn.Log    ${get}
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Get Tunnels On All DPNs
    Comment    ${k}    BuiltIn.Set Variable    0
    Comment    BuiltIn.Set Suite Variable    ${k}
    Comment    Get Tunnel Between DPNs    ${type}
    ${tunnel-type}=    BuiltIn.Set Variable    type: vxlan
    Genius.Verify Data From URL
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification    @{TOOLS_SYSTEM_LIST}
    ${url_2}    BuiltIn.Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    Verify Network Topology
    Verify Ietf Interface State
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Delete and Verify VTEP -Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-list}    Genius.Get Tunnels List
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.verify Deleted Tunnels on OVS    ${tunnel-list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel-list}

Create VTEP - Vlan and Gateway
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and Gateway configured in Json.
    ${vlan}=    BuiltIn.Set Variable    101
    ${substr}    BuiltIn.Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    BuiltIn.Catenate    ${substr}0
    ${gateway-ip}    BuiltIn.Catenate    ${substr}1
    BuiltIn.Log    ${subnet}
    Genius.Create Vteps    ${vlan}    ${gateway-ip}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Get Tunnels On All DPNs
    ${tunnel-type}=    BuiltIn.Set Variable    type: vxlan
    Genius.Verify Data From URL
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification    @{TOOLS_SYSTEM_LIST}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status as UP
    Verify Network Topology
    Verify Ietf Interface State
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Delete VTEP -Vlan and gateway
    [Documentation]    This testcase deletes the ITM tunnel created between 2 dpns.
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-list}    Genius.Get Tunnels List
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.verify Deleted Tunnels on OVS    ${tunnel-list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel-list}

*** Keywords ***
Create Vteps IPv6
    [Arguments]    ${vlan}    ${gateway-ip}    ${TOOLS_SYSTEM_LIST}
    [Documentation]    This keyword creates VTEPs between IPV6 ip's
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    BuiltIn.Should Match Regexp    ${TOOLS_SYSTEM_IPV6_LIST}[0]    [0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:
    ${subnet}    BuiltIn.Catenate    ${substr}0
    BuiltIn.Set Global Variable    ${subnet}
    ${vlan}=    BuiltIn.Set Variable    ${vlan}
    ${gateway-ip}=    BuiltIn.Set Variable    ${gateway-ip}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${body}    Genius.Set Json    ${vlan}    ${gateway-ip}    ${subnet}    ${TOOLS_SYSTEM_LIST}
    Utils.Post Log Check    ${CONFIG_API}/itm:transport-zones/    ${body}    204

Get Network Topology with Tunnel
    [Arguments]    ${url}    ${network_topology_list}
    [Documentation]    Returns the Network topology with Tunnel info in it.
    Utils.Check For Elements At URI    ${url}    ${network_topology_list}

Get Tunnel Between DPNs
    [Arguments]    ${type}
    [Documentation]    This keyword will get the tunnels between DPN's
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    @{Dpn_id_updated_list}    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove Values From List    ${Dpn_id_updated_list}    ${DPN_ID_LIST[${i}]}
    \    BuiltIn.Log Many    ${Dpn_id_updated_list}
    \    BuiltIn.Set Suite Variable    ${Dpn_id_updated_list}
    \    Get Tunnels On OVS    ${type}

Get Tunnels On OVS
    [Arguments]    ${type}
    [Documentation]    This keyword will get available tunnels
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM} -1
    \    ${tunnel}    BuiltIn.Wait Until Keyword Succeeds    30    10    Genius.Get Tunnel    ${DPN_ID_LIST[${k}]}
    \    ...    ${Dpn_id_updated_list[${i}]}    ${type}
    ${k}    BuiltIn.Evaluate    ${k} +1
    BuiltIn.Set Suite Variable    ${k}

Get ITM IPV6
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    @{Itm-no-vlan}    BuiltIn.Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${DPN_ID_LIST}    ${BRIDGE}
    @{Itm-no-vlan}    Collections.Combine Lists    @{Itm-no-vlan}    ${TOOLS_SYSTEM_IPV6_LIST}
    BuiltIn.Log Many    @{Itm-no-vlan}
    Utils.Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

OVS Verification Between IPV6
    [Arguments]    @{TOOLS_SYSTEM_LIST}
    [Documentation]    This keyword will verify tunnels available on ovs
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    Genius.Ovs Verification For Each Dpn    ${tools_ip}    ${TOOLS_SYSTEM_IPV6_LIST}

Get Tunnels On All DPNs
    [Documentation]    This keyword will Get All the Tunnels available on DPN's
    ${k}    BuiltIn.Set Variable    0
    BuiltIn.Set Suite Variable    ${k}
    Get Tunnel Between DPNs    ${type}

Verify Network Topology
    [Documentation]    This keyword will verify whether all tunnels and bridges are populated in network topology
    ${all_tunnels}    Genius.Get Tunnels List
    @{network_topology_list}    BuiltIn.Create List
    @{network_topology_list}    Collections.Combine Lists    ${network_topology_list}    ${BRIDGE}
    @{network_topology_list}    Collections.Combine Lists    ${network_topology_list}    ${all_tunnels}
    ${resp}    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${OPERATIONAL_TOPO_API}    ${network_topology_list}

Verify Ietf Interface State
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Log    ${respjson}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${dpn}    IN    @{DPN_ID_LIST}
    \    BuiltIn.Should Contain    ${resp.content}    ${dpn}
    ${all_tunnels}    Genius.Get Tunnels List
    : FOR    ${tun}    IN    @{all_tunnels}
    \    BuiltIn.Should Contain    ${resp.content}    ${tun}
