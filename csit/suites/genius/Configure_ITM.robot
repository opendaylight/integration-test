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
${Bridge-1}       BR1
${Bridge-2}       BR2
${genius_config_dir}    ${CURDIR}/../../variables/genius
@{PORT}           BR1-eth1    BR2-eth1
@{VLAN}           0    100    101

*** Test Cases ***
Create and Verify VTEP -No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    @{VLAN}[0]    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    @{VLAN}[0]
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    20    Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    20    Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
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
    ${cmd}    Set Variable    tep:delete ${Dpn_id_1} @{PORT}[0] @{VLAN}[0] ${TOOLS_SYSTEM_IP} ${subnet}/24 null ${itm_created[0]}
    ${cmd2}    Set Variable    tep:delete ${Dpn_id_2} @{PORT}[1] @{VLAN}[0] ${TOOLS_SYSTEM_2_IP} ${subnet}/24 null ${itm_created[0]}
    KarafKeywords.Issue Command On Karaf Console    ${cmd}
    KarafKeywords.Issue Command On Karaf Console    tep:commit
    KarafKeywords.Issue Command On Karaf Console    ${cmd2}
    KarafKeywords.Issue Command On Karaf Console    tep:commit
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp}    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    BuiltIn.Should Not Contain    ${resp.content}    ${itm_created[0]}

Create and Verify VTEP IPv6 - No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${gateway-ip}=    Set Variable    ::
    ${TOOLS_SYSTEM_IP}    Set Variable    fd96:2a25:4ad3:3c7d:0:0:0:1000
    ${TOOLS_SYSTEM_2_IP}    Set Variable    fd96:2a25:4ad3:3c7d:0:0:0:2000
    Create Vteps IPv6    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    @{VLAN}[0]    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    @{VLAN}[0]
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
    ${ipv6_1}    Set Variable    fd96:2a25:4ad3:3c7d:0:0:0:1000
    ${ipv6_2}    Set Variable    fd96:2a25:4ad3:3c7d:0:0:0:2000
    ${tunnel-1}    Get_Tunnel    ${Dpn_id_1}    ${Dpn_id_2}    ${type}
    ${tunnel-2}    Get_Tunnel    ${Dpn_id_2}    ${Dpn_id_1}    ${type}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/subnets/${subnet}%2F24/vteps/${Dpn_id_1}/@{PORT}[0]
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/subnets/${subnet}%2F24/vteps/${Dpn_id_2}/@{PORT}[1]
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp}    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    BuiltIn.Should Not Contain    ${resp.content}    ${itm_created[0]}

Create and Verify VTEP-Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and \ without Gateway configured in Json.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    @{VLAN}[1]    ${gateway-ip}
    ${get}    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}
    ...    @{VLAN}[1]    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
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
    ${cmd1}    Set Variable    tep:delete ${Dpn_id_1} @{PORT}[0] @{VLAN}[1] ${TOOLS_SYSTEM_IP} ${subnet}/24 null ${itm_created[0]}
    ${cmd2}    Set Variable    tep:delete ${Dpn_id_2} @{PORT}[1] @{VLAN}[1] ${TOOLS_SYSTEM_2_IP} ${subnet}/24 null ${itm_created[0]}
    KarafKeywords.Issue Command On Karaf Console    ${cmd1}
    KarafKeywords.Issue Command On Karaf Console    tep:commit
    KarafKeywords.Issue Command On Karaf Console    ${cmd2}
    KarafKeywords.Issue Command On Karaf Console    tep:commit
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Wait Until Keyword Succeeds    40    10    Genius.Check ITM Tunnel State    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    BuiltIn.Should Not Contain    ${resp.content}    ${itm_created[0]}

Create VTEP - Vlan and Gateway
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and Gateway configured in Json.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    ${gateway-ip}    Catenate    ${substr}1
    Set Suite Variable    ${GATEWAY_IP}    ${gateway-ip}
    Log    ${subnet}
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    @{VLAN}[2]    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    @{VLAN}[2]
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
    ${cmd1}    Set Variable    tep:delete ${Dpn_id_1} @{PORT}[0] @{VLAN}[2] ${TOOLS_SYSTEM_IP} ${subnet}/24 ${GATEWAY_IP} ${itm_created[0]}
    ${cmd2}    Set Variable    tep:delete ${Dpn_id_2} @{PORT}[1] @{VLAN}[2] ${TOOLS_SYSTEM_2_IP} ${subnet}/24 ${GATEWAY_IP} ${itm_created[0]}
    KarafKeywords.Issue Command On Karaf Console    ${cmd1}
    KarafKeywords.Issue Command On Karaf Console    tep:commit
    KarafKeywords.Issue Command On Karaf Console    ${cmd2}
    KarafKeywords.Issue Command On Karaf Console    tep:commit
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Wait Until Keyword Succeeds    40    10    Genius.Check ITM Tunnel State    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    BuiltIn.Should Not Contain    ${resp.content}    ${itm_created[0]}

*** Keywords ***
Create Vteps IPv6
    [Arguments]    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
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
