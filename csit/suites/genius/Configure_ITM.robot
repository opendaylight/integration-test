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
    Comment    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    Comment    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${vlan}    ${gateway-ip}
    Comment    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}
    ...    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${k}    Set Variable    0
    Set Suite Variable    ${k}
    ${all-tunnels-list}    Get Tunnel Between DPN's    ${type}
    Comment    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    Comment    \    Get Tunnel Between DPN's
    Comment    ${tunnel-1}    Wait Until Keyword Succeeds    40    20    Get Tunnel    ${Dpn_id_1}
    ...    ${Dpn_id_2}    ${type}
    Comment    ${tunnel-2}    Wait Until Keyword Succeeds    40    20    Get Tunnel    ${Dpn_id_2}
    ...    ${Dpn_id_1}    ${type}
    ${tunnel-type}=    Set Variable    type: vxlan
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_List[${i}]}/
    Comment    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    Comment    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification between Dpn
    Comment    Wait Until Keyword Succeeds    40    10    Genius.Ovs Verification For 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ...    ${TOOLS_SYSTEM_IP}    ${tunnel-2}    ${tunnel-type}
    @{network_topology_list}    Create List    ${OPERATIONAL_TOPO_API}
    @{network_topology_list}    Combine Lists    ${network_topology_list}    ${Bridge_List}
    @{network_topology_list}    Combine Lists    ${network_topology_list}    ${all_tunnels}
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${OPERATIONAL_TOPO_API}    ${network_topology_list}
    ${return}    Validate interface state    ${all-tunnels-list}
    log    ${return}
    ${lower-layer-if-1}    Get from List    ${return}    0
    ${port-num-1}    Get From List    ${return}    1
    ${lower-layer-if-2}    Get from List    ${return}    2
    ${port-num-2}    Get From List    ${return}    3
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${dpn}    IN    @{Dpn_id_List}
    \    Should Contain    ${resp.content}    ${dpn}
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    Should Contain    ${resp.content}    ${tools_ip}
    Comment    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-1}
    Comment    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-2}
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
    ${tunnel-1}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
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
    ${tunnel-1}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
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
    ${tunnel-1}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
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

Get Tunnel
    [Arguments]    ${src}    ${dst}    ${type}
    [Documentation]    This Keyword Gets the Tunnel /Interface name which has been created between 2 DPNS by passing source , destination DPN Ids along with the type of tunnel which is configured.
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/${type}/
    log    ${resp.content}
    Log    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${src}    ${dst}
    ${json}=    evaluate    json.loads('''${resp.content}''')    json
    log to console    \nOriginal JSON:\n${json}
    ${return}    Run Keyword And Return Status    Should contain    ${resp.content}    tunnel-interface-names
    log    ${return}
    ${ret}    Run Keyword If    '${return}'=='True'    Check Interface Name    ${json["internal-tunnel"][0]}    tunnel-interface-names
    [Return]    ${ret}

Validate interface state
    [Arguments]    ${all-tunnels-list}
    [Documentation]    Validates the created Interface Tunnel by checking its Operational status as UP/DOWN from the dump.
    Comment    Log    ${tunnel-1},${dpid-1},${tunnel-2},${dpid-2}
    ${data}    Wait Until Keyword Succeeds    40    10    Check Interface Status    ${all-tunnels-list}
    Comment    ${data2-1}    Wait Until Keyword Succeeds    40    10    Check Interface Status    ${tunnel-2}
    Comment    @{data}    combine lists    ${data1-2}    ${data2-1}
    Comment    log    ${data}
    [Return]    ${data}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${subnet}, ${vlan}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}
    @{Itm-no-vlan}    Collections.Combine Lists    @{Itm-no-vlan}    ${data}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Get Network Topology with Tunnel
    [Arguments]    ${url}    ${network_topology_list}
    [Documentation]    Returns the Network topology with Tunnel info in it.
    Check For Elements At URI    ${url}    @{network_topology_list}

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
    [Arguments]    ${all-tunnels-list}
    [Documentation]    Verifies the operational state of the interface .
    ${a}    Set Variable    0
    : FOR    ${a}    INRANGE    ${NUM_TOOLS_SYSTEM} -1
    \    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${all-tunnels-list[${a}]}/
    \    Log    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${all-tunnels-list[${a}]}/
    \    Should Contain    ${resp.content}    ${all-tunnel-list[${a}]}    up    up
    ${a}    Evaluate    ${a} +(${NUM_TOOLS_SYSTEM} -1)
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should not contain    ${resp.content}    down
    Comment    Should Contain    ${resp.content}    ${tunnel}    up    up
    ${result-1}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result-1}
    : FOR    ${dpn}    IN    @{Dpn_id_List}
    \    ${lower_layer_if}    Should Match Regexp    ${result-1}    openflow:${dpn}:[0-9]+
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

Check Interface Name
    [Arguments]    ${json}    ${expected_tunnel_interface_name}
    [Documentation]    This keyword Checks the Tunnel interface name is tunnel-interface-names in the output or not .
    ${Tunnels}    Collections.Get From Dictionary    ${json}    ${expected_tunnel_interface_name}
    Log    ${Tunnels}
    [Return]    ${Tunnels[0]}

Get Tunnel Between DPN's
    [Arguments]    ${type}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    @{Dpn_id_updated_list}    Create List    @{Dpn_id_List}
    \    Remove Values From List    ${Dpn_id_updated_list}    ${Dpn_id_List[${i}]}
    \    Log Many    ${Dpn_id_updated_list}
    \    Set Suite Variable    ${Dpn_id_updated_list}
    \    ${all_tunnels}    Get All Tunnels    ${type}
    Set Suite Variable    ${all_tunnels}
    [Return]    ${all-tunnels}

Get All Tunnels
    [Arguments]    ${type}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM} -1
    \    ${tunnel}    Wait Until Keyword Succeeds    30    10    Get Tunnel    ${Dpn_id_List[${k}]}
    \    ...    ${Dpn_id_updated_list[${i}]}    ${type}
    \    @{tunnel-list}    Create List
    \    Append To List    ${tunnel-list}    ${tunnel}
    \    Log Many    @{tunnel-list}
    ${k}    Evaluate    ${k} +1
    Set Suite Variable    ${k}
    [Return]    @{tunnel-list}
