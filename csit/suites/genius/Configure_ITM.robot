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
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/ToolsSystem.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../../variables/genius
@{VLAN}           0    100    101

*** Test Cases ***
Create and Verify VTEP -No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    ${gateway_ip} =    BuiltIn.Set Variable    0.0.0.0
    Genius.Create Vteps    @{VLAN}[0]    ${gateway_ip}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${subnet}    @{VLAN}[0]
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Get Tunnels On All DPNs    ${type}
    Genius.Verify Data From URL
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    Verify Network Topology
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    Verify Ietf Interface State
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    ${respjson} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Log    ${respjson}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Delete and Verify VTEP -No Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${i} =    BuiltIn.Set Variable    0
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    ${tunnel_list} =    Genius.Get Tunnels List
    : FOR    ${node}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    KarafKeywords.Issue Command On Karaf Console    tep:delete @{DPN_ID_LIST}[${i}] ${port_name} @{VLAN}[0] ${node} ${subnet}/24 null ${itm_created[0]}
    \    KarafKeywords.Issue Command On Karaf Console    tep:commit
    \    ${i} =    Evaluate    ${i}+1
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Deleted Tunnels On OVS    ${tunnel_list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel_list}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    BuiltIn.Should Not Contain    ${resp.content}    ${itm_created[0]}

Create and Verify VTEP IPv6 - No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    ${gateway_ip} =    BuiltIn.Set Variable    ::
    @{TOOLS_SYSTEM_IPV6_LIST} =    BuiltIn.Create List
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    Collections.Append To List    ${TOOLS_SYSTEM_IPV6_LIST}    fd96:2a25:4ad3:3c7d:0:0:${i}:1000
    BuiltIn.Log Many    @{TOOLS_SYSTEM_IPV6_LIST}
    BuiltIn.Set Suite Variable    @{TOOLS_SYSTEM_IPV6_LIST}
    Create Vteps IPv6    @{VLAN}[0]    ${gateway_ip}    ${TOOLS_SYSTEM_IPV6_LIST}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Get ITM IPV6    ${itm_created[0]}    ${subnet}    @{VLAN}[0]
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Get Tunnels On All DPNs    ${type}
    : FOR    ${dpn}    IN    @{DPN_ID_LIST}
    \    BuiltIn.Wait Until Keyword Succeeds    40    5    Utils.Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn}/
    \    ...    headers=${ACCEPT_XML}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OVS Verification Between IPV6
    @{all_tunnels} =    BuiltIn.Create List
    : FOR    ${conn_id}    IN    @{TOOLS_SYSTEM_ALL_CONN_IDS}
    \    ${tun_names} =    Genius.Get Tunnels On OVS    ${conn_id}
    \    Collections.Append To List    ${all_tunnels}    @{tun_names}
    BuiltIn.Log Many    @{all_tunnels}
    @{network_topology_list}    BuiltIn.Create List    @{all_tunnels}
    @{network_topology_list}    Collections.Combine Lists    ${network_topology_list}    ${INTEGRATION_BRIDGE}
    ${resp}    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${OPERATIONAL_TOPO_API}    ${network_topology_list}

Delete and Verify VTEP IPv6 -No Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel_list} =    Genius.Get Tunnels List
    : FOR    ${dpn}    IN    @{DPN_ID_LIST}
    \    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/subnets/${subnet}%2F24/vteps/${dpn}/${port_name}
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Deleted Tunnels On OVS    ${tunnel_list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel_list}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    BuiltIn.Should Not Contain    ${resp.content}    ${itm_created[0]}

Create and Verify VTEP-Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and \ without Gateway configured in Json.
    ${gateway_ip} =    BuiltIn.Set Variable    0.0.0.0
    Genius.Create Vteps    @{vlan}[1]    ${gateway_ip}
    ${get} =    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${subnet}
    ...    @{vlan}[1]
    BuiltIn.Log    ${get}
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Get Tunnels On All DPNs    ${type}
    Genius.Verify Data From URL
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification
    ${url_2} =    BuiltIn.Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    Verify Network Topology
    Verify Ietf Interface State
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Delete and Verify VTEP -Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${i} =    BuiltIn.Set Variable    0
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel_list} =    Genius.Get Tunnels List
    : FOR    ${node}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    KarafKeywords.Issue Command On Karaf Console    tep:delete @{DPN_ID_LIST}[${i}] ${port_name} @{VLAN}[1] ${node} ${subnet}/24 null ${itm_created[0]}
    \    KarafKeywords.Issue Command On Karaf Console    tep:commit
    \    ${i} =    Evaluate    ${i}+1
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Deleted Tunnels On OVS    ${tunnel_list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel_list}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    BuiltIn.Should Not Contain    ${resp.content}    ${itm_created[0]}

Create VTEP - Vlan and Gateway
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and Gateway configured in Json.
    ${substr} =    BuiltIn.Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet} =    BuiltIn.Catenate    ${substr}0
    ${gateway_ip} =    BuiltIn.Catenate    ${substr}1
    Comment    \ \ \ Set Suite Variable \ \    ${GATEWAY_IP}    ${gateway-ip}
    BuiltIn.Log    ${subnet}
    Genius.Create Vteps    @{VLAN}[2]    ${gateway_ip}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${subnet}    @{VLAN}[2]
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Get Tunnels On All DPNs    ${type}
    ${tunnel-type}=    BuiltIn.Set Variable    type: vxlan
    Genius.Verify Data From URL
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up
    Verify Network Topology
    Verify Ietf Interface State
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Delete VTEP -Vlan and gateway
    [Documentation]    This testcase deletes the ITM tunnel created between 2 dpns.
    ${i} =    BuiltIn.Set Variable    0
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel_list}    Genius.Get Tunnels List
    : FOR    ${node}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    KarafKeywords.Issue Command On Karaf Console    tep:delete @{DPN_ID_LIST}[${i}] ${port_name} @{VLAN}[2] ${node} ${subnet}/24 null ${itm_created[0]}
    \    KarafKeywords.Issue Command On Karaf Console    tep:commit
    \    ${i} =    Evaluate    ${i}+1
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Deleted Tunnels On OVS    ${tunnel_list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel_list}

*** Keywords ***
Create Vteps IPv6
    [Arguments]    ${vlan}    ${gateway_ip}    ${tools_ips}
    [Documentation]    This keyword creates VTEPs between IPV6 ip's
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr} =    BuiltIn.Should Match Regexp    @{tools_ips}[0]    [0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:
    ${subnet} =    BuiltIn.Catenate    ${substr}0
    BuiltIn.Set Global Variable    ${subnet}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${body} =    Genius.Set Json    ${vlan}    ${gateway_ip}    ${subnet}    ${tools_ips}
    Utils.Post Log Check    ${CONFIG_API}/itm:transport-zones/    ${body}    204

Get Network Topology with Tunnel
    [Arguments]    ${url}    ${network_topology_list}
    [Documentation]    Returns the Network topology with Tunnel info in it.
    Utils.Check For Elements At URI    ${url}    ${network_topology_list}

Get Tunnel Between DPNs
    [Arguments]    ${type}
    [Documentation]    This keyword will get the tunnels between DPN's
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    @{DPN_ID_UPDATED_LIST} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove Values From List    ${DPN_ID_UPDATED_LIST}    ${DPN_ID_LIST[${i}]}
    \    BuiltIn.Log Many    ${DPN_ID_UPDATED_LIST}
    \    BuiltIn.Set Suite Variable    ${DPN_ID_UPDATED_LIST}
    \    Get Tunnels On OVS    ${type}

Get Tunnels On OVS
    [Arguments]    ${type}
    [Documentation]    This keyword will get available tunnels
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM} -1
    \    ${tunnel}    BuiltIn.Wait Until Keyword Succeeds    30    10    Genius.Get Tunnel    ${DPN_ID_LIST[${k}]}
    \    ...    ${DPN_ID_UPDATED_LIST[${i}]}    ${type}
    ${k} =    BuiltIn.Evaluate    ${k} +1
    BuiltIn.Set Suite Variable    ${k}

Get ITM IPV6
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    @{Itm-no-vlan} =    BuiltIn.Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${DPN_ID_LIST}    ${INTEGRATION_BRIDGE}
    @{Itm-no-vlan} =    Collections.Combine Lists    @{Itm-no-vlan}    ${TOOLS_SYSTEM_IPV6_LIST}
    BuiltIn.Log Many    @{Itm-no-vlan}
    Utils.Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

OVS Verification Between IPV6
    [Documentation]    This keyword will verify tunnels available on ovs
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    Genius.Ovs Verification For Each Dpn    ${tools_ip}    ${TOOLS_SYSTEM_IPV6_LIST}

Get Tunnels On All DPNs
    [Arguments]    ${type}
    [Documentation]    This keyword will Get All the Tunnels available on DPN's
    ${k} =    BuiltIn.Set Variable    0
    BuiltIn.Set Suite Variable    ${k}
    Get Tunnel Between DPNs    ${type}

Verify Network Topology
    [Documentation]    This keyword will verify whether all tunnels and bridges are populated in network topology
    ${all_tunnels}    Genius.Get Tunnels List
    @{network_topology_list}    BuiltIn.Create List
    @{network_topology_list}    Collections.Combine Lists    ${network_topology_list}    ${INTEGRATION_BRIDGE}
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
