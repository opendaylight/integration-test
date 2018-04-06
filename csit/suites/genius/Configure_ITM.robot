*** Settings ***
Documentation     Test Suite for ITM
Suite Setup       Genius Suite Setup
Suite Teardown    Genius Suite Teardown
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
${Bridge-1}       BR1
${Bridge-2}       BR2

*** Test Cases ***
Create and Verify VTEP -No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    ...    ${tunnel-1}    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_IP}
    ...    ${tunnel-2}    ${tunnel-type}
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-1}    ${tunnel-2}    ${OPERATIONAL_TOPO_API}
    ${return}    Validate interface state    ${tunnel-1}    ${Dpn_id_1}    ${tunnel-2}    ${Dpn_id_2}
    log    ${return}
    ${lower-layer-if-1}    Get from List    ${return}    0
    ${port-num-1}    Get From List    ${return}    1
    ${lower-layer-if-2}    Get from List    ${return}    2
    ${port-num-2}    Get From List    ${return}    3
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_1}    ${Bridge-1}    ${port-num-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_2}    ${Bridge-2}    ${port-num-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-1}    ${lower-layer-if-2}

Delete and Verify VTEP -No Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Get_Tunnel    ${Dpn_id_1}    ${Dpn_id_2}    ${type}
    ${tunnel-2}    Get_Tunnel    ${Dpn_id_2}    ${Dpn_id_1}    ${type}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp}    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}

Create and Verify VTEP IPv6 - No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    ::
    ${TOOLS_SYSTEM_IP}    Set Variable    fd96:2a25:4ad3:3c7d:0:0:0:1000
    ${TOOLS_SYSTEM_2_IP}    Set Variable    fd96:2a25:4ad3:3c7d:0:0:0:2000
    Create Vteps IPv6    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    10    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    10    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    ...    ${tunnel-1}    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_IP}
    ...    ${tunnel-2}    ${tunnel-type}
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-1}    ${tunnel-2}    ${OPERATIONAL_TOPO_API}

Delete and Verify VTEP IPv6 -No Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Get_Tunnel    ${Dpn_id_1}    ${Dpn_id_2}    ${type}
    ${tunnel-2}    Get_Tunnel    ${Dpn_id_2}    ${Dpn_id_1}    ${type}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp}    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}

Create and Verify VTEP-Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and \ without Gateway configured in Json.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    100
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ${get}    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}
    ...    ${vlan}    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    Log    ${get}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    10    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    10    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    ...    ${tunnel-1}    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_IP}
    ...    ${tunnel-2}    ${tunnel-type}
    ${url_2}    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}    ${tunnel-1}
    ...    ${tunnel-2}    ${url_2}
    ${return}    Validate interface state    ${tunnel-1}    ${Dpn_id_1}    ${tunnel-2}    ${Dpn_id_2}
    log    ${return}
    ${lower-layer-if-1}    Get from List    ${return}    0
    ${port-num-1}    Get From List    ${return}    1
    ${lower-layer-if-2}    Get from List    ${return}    2
    ${port-num-2}    Get From List    ${return}    3
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_1}    ${Bridge-1}    ${port-num-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_2}    ${Bridge-2}    ${port-num-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-2}    ${lower-layer-if-1}

Delete and Verify VTEP -Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Get_Tunnel    ${Dpn_id_1}    ${Dpn_id_2}    ${type}
    ${tunnel-2}    Get_Tunnel    ${Dpn_id_2}    ${Dpn_id_1}    ${type}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Wait Until Keyword Succeeds    40    10    Genius.Check ITM Tunnel State    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}

Create VTEP - Vlan and Gateway
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and Gateway configured in Json.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    101
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    ${gateway-ip}    Catenate    ${substr}1
    Log    ${subnet}
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    10    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    10    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    ...    ${tunnel-1}    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_IP}
    ...    ${tunnel-2}    ${tunnel-type}
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-1}    ${tunnel-2}    ${OPERATIONAL_TOPO_API}
    Log    ${resp}
    ${return}    Validate interface state    ${tunnel-1}    ${Dpn_id_1}    ${tunnel-2}    ${Dpn_id_2}
    log    ${return}
    ${lower-layer-if-1}    Get from List    ${return}    0
    ${port-num-1}    Get From List    ${return}    1
    ${lower-layer-if-2}    Get from List    ${return}    2
    ${port-num-2}    Get From List    ${return}    3
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_1}    ${Bridge-1}    ${port-num-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_2}    ${Bridge-2}    ${port-num-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-2}    ${lower-layer-if-1}

Delete VTEP -Vlan and gateway
    [Documentation]    This testcase deletes the ITM tunnel created between 2 dpns.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Get_Tunnel    ${Dpn_id_1}    ${Dpn_id_2}    ${type}
    ${tunnel-2}    Get_Tunnel    ${Dpn_id_2}    ${Dpn_id_1}    ${type}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Wait Until Keyword Succeeds    40    10    Genius.Check ITM Tunnel State    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}

*** Keywords ***
Create Vteps IPv6
    [Arguments]    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    Genius.Set Json    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}
    ...    ${gateway-ip}    ${subnet}
    Post Log Check    ${CONFIG_API}/itm:transport-zones/    ${body}    204

Validate interface state
    [Arguments]    ${tunnel-1}    ${dpid-1}    ${tunnel-2}    ${dpid-2}
    [Documentation]    Validates the created Interface Tunnel by checking its Operational status as UP/DOWN from the dump.
    Log    ${tunnel-1},${dpid-1},${tunnel-2},${dpid-2}
    ${data1-2}    Wait Until Keyword Succeeds    40    10    Check Interface Status    ${tunnel-1}    ${dpid-1}
    ${data2-1}    Wait Until Keyword Succeeds    40    10    Check Interface Status    ${tunnel-2}    ${dpid-2}
    @{data}    combine lists    ${data1-2}    ${data2-1}
    log    ${data}
    [Return]    ${data}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}
    ...    ${TOOLS_SYSTEM_2_IP}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${subnet}, ${vlan}, ${Dpn_id_1},${TOOLS_SYSTEM_IP}, ${Dpn_id_2}, ${TOOLS_SYSTEM_2_IP}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${Bridge-2}-eth1    ${TOOLS_SYSTEM_2_IP}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Get Network Topology with Tunnel
    [Arguments]    ${Bridge-1}    ${Bridge-2}    ${tunnel-1}    ${tunnel-2}    ${url}
    [Documentation]    Returns the Network topology with Tunnel info in it.
    @{bridges}    Create List    ${Bridge-1}    ${Bridge-2}    ${tunnel-1}    ${tunnel-2}
    Check For Elements At URI    ${url}    ${bridges}

Get Network Topology without Tunnel
    [Arguments]    ${url}    ${tunnel-1}    ${tunnel-2}
    [Documentation]    Returns the Network Topology after Deleting of ITM transport zone is done , which wont be having any TUNNEL info in it.
    @{tunnels}    create list    ${tunnel-1}    ${tunnel-2}
    Check For Elements Not At URI    ${url}    ${tunnels}

Validate interface state Delete
    [Arguments]    ${tunnel}
    [Documentation]    Check for the Tunnel / Interface absence in OPERATIONAL data base of IETF interface after ITM transport zone is deleted.
    Log    ${tunnel}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    404
    Should not contain    ${resp.content}    ${tunnel}

check-Tunnel-delete-on-ovs
    [Arguments]    ${connection-id}    ${tunnel}
    [Documentation]    Verifies the Tunnel is deleted from OVS
    Log    ${tunnel}
    Switch Connection    ${connection-id}
    Log    ${connection-id}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
    Should Not Contain    ${return}    ${tunnel}
    [Return]    ${return}

Check Interface Status
    [Arguments]    ${tunnel}    ${dpid}
    [Documentation]    Verifies the operational state of the interface .
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/
    Log    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should not contain    ${resp.content}    down
    Should Contain    ${resp.content}    ${tunnel}    up    up
    ${result-1}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result-1}
    ${lower_layer_if}    Should Match Regexp    ${result-1}    openflow:${dpid}:[0-9]+
    log    ${lower_layer_if}
    @{resp_array}    Split String    ${lower_layer_if}    :
    ${port-num}    Get From List    ${resp_array}    2
    Log    ${port-num}
    [Return]    ${lower_layer_if}    ${port-num}

Verify Data Base after Delete
    [Arguments]    ${Dpn_id_1}    ${Dpn_id_2}    ${tunnel-1}    ${tunnel-2}
    [Documentation]    Verifies the config database after the Tunnel deletion is done.
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    No Content From URI    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_1}/${Dpn_id_2}/${type}/
    No Content From URI    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_2}/${Dpn_id_1}/${type}/
    No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    ${resp_7}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    Run Keyword if    '${resp_7.content}'=='404'    Response is 404
    Run Keyword if    '${resp_7.content}'=='200'    Response is 200
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${CONFIG_TOPO_API}    ${tunnel-1}
    ...    ${tunnel-2}
    Log    ${resp_8}
    Wait Until Keyword Succeeds    40    10    check-Tunnel-delete-on-ovs    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    check-Tunnel-delete-on-ovs    ${conn_id_2}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${OPERATIONAL_TOPO_API}    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-2}
