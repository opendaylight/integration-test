*** Settings ***
Documentation     Test Suite for OF Tunnel Testing

Suite Setup       Genius Suite Setup
Suite Teardown    Genius Suite Teardown
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../variables/Variables.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ../../../variables/genius/
${Bridge-1}       BR1
${Bridge-2}       BR2
${Bridge-3}       BR3
${TUN}            tun
${ONE}            1
${THREE}          3
${DISABLE}        DISABLED
${DOWN}           DOWN
${ENABLED}        ENABLED
@{Bridge}         BR1    BR2    BR3
${VXLAN_SHOW}     vxlan:show

*** Test Cases ***
Verify OF based tunnels on 2 DPNs
    [Documentation]    This testcase creates OF tunnels - ITM tunnel between 2 DPNs configured in Json.
    Set Variable    1
    ${Dpn_id_1}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    ${Dpn_id_2}    OVSDB.Get DPID    ${OS_COMPUTE_2_IP}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-port BR1 tap8ed70586-6c
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${file_name}=    Set Variable    vtep_two_dpns_with_of_tunnel.json
    Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${GATEWAY-IP}    ${file_name}
    ...    2
    Sleep    5
    Display OVS Show    ${conn_id_1}
    Sleep    5
    Display OVS Show    ${conn_id_2}
    Sleep    5
    ${ovs_of_tunnel_1}    Get Tunnel From OVS Show    ${conn_id_1}    ${Bridge[0]}
    Should Contain    ${ovs_of_tunnel_1}    ${TUN}
    ${ovs_of_tunnel_2}    Get Tunnel From OVS Show    ${conn_id_2}    ${Bridge[1]}
    Should Contain    ${ovs_of_tunnel_2}    ${TUN}
    ${count}    Get Count    ${ovs_of_tunnel_1}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    ${count}    Get Count    ${ovs_of_tunnel_2}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
     Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
   
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
     @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${Bridge-2}-eth1    ${TOOLS_SYSTEM_2_IP}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}
     ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${ovs_of_tunnel_1}
    ...    ${tunnel-type}
     Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${ovs_of_tunnel_2}
    ...    ${tunnel-type}
     ${url-2}=    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${ovs_of_tunnel_1}    ${ovs_of_tunnel_2}    ${url-2}
     ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${ovs_of_tunnel_1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${ovs_of_tunnel_2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    ${output}=    Issue Command On Karaf Console    ${VXLAN_SHOW}
    Should Not Contain    ${output}    ${DISABLE}
    Should Not Contain    ${output}    ${DOWN}

Delete OF tunnel on 2 dpn and verify
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Display OVS Show    ${conn_id_1}
    Display OVS Show    ${conn_id_2}
    Display OVS Show    ${conn_id_3}

Verify OF tunnels on 1 DPN and non-OF tunnel on another DPN
    ${POSITIVE_VAL}    Set Variable    1
    Set Global Variable    ${POSITIVE_VAL}
    ${Dpn_id_1}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}    BR1
    ${Dpn_id_2}    OVSDB.Get DPID    ${TOOLS_SYSTEM_2_IP}    BR2
    ${Dpn_id_3}    OVSDB.Get DPID    ${TOOLS_SYSTEM_3_IP}    BR3
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${file_name}=    Set Variable    vtep_two_dpns_with_mix_match.json
    Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${file_name}
    ...    2
    Sleep    5
    Display OVS Show    ${conn_id_1}
    Sleep    2
    Display OVS Show    ${conn_id_2}
    Sleep    2
    ${ovs_of_tunnel_1}    Get Tunnel From OVS Show    ${conn_id_1}    ${Bridge-1}
    Should Contain    ${ovs_of_tunnel_1}    ${TUN}
    ${ovs_of_tunnel_2}    Get Tunnel From OVS Show    ${conn_id_2}    BR2
    Should Contain    ${ovs_of_tunnel_2}    ${TUN}
    ${count}    Get Count    ${ovs_of_tunnel_1}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    ${count}    Get Count    ${ovs_of_tunnel_2}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    SLEEP    5
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${tunnel-type}=    Set Variable    type: vxlan
    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_IP}
    ...    ${ovs_of_tunnel_2}    ${tunnel-type}
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${ovs_of_tunnel_1}
    ...    ${tunnel-type}
    ${url-2}=    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${ovs_of_tunnel_1}    ${ovs_of_tunnel_2}    ${url-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${ovs_of_tunnel_1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${ovs_of_tunnel_2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    ${output}=    Issue Command On Karaf Console    ${VXLAN_SHOW}
    Should Not Contain    ${output}    ${DISABLE}
    Should Contain    ${output}    ${ENABLED}

Delete and verify OF tunnels on 1 DPN and non-OF tunnel on another DPN
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    SLEEP    5
    Display OVS Show    ${conn_id_1}
    Display OVS Show    ${conn_id_2}
    Display OVS Show    ${conn_id_3}

Configure and verify OF based tunnels on two of 3 DPNs
    ${POSITIVE_VAL}=    Set Variable    1
    Set Global Variable    ${POSITIVE_VAL}
    ${Dpn_id_1}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}    BR1
    ${Dpn_id_2}    OVSDB.Get DPID    ${TOOLS_SYSTEM_2_IP}    BR2
    ${Dpn_id_3}    OVSDB.Get DPID    ${TOOLS_SYSTEM_3_IP}    BR3
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    Set Global Variable    ${Dpn_id_3}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${file_name}=    Set Variable    vtep_three_dpns_with_of_tunnel.json
    Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${file_name}
    ...    3
    Sleep    5
    Display OVS Show    ${conn_id_1}
    Sleep    2
    Display OVS Show    ${conn_id_2}
    Sleep    2
    Display OVS Show    ${conn_id_3}
    Sleep    2
    ${ovs_of_tunnel_1}    Get Tunnel From OVS Show    ${conn_id_1}    BR1
    Should Contain    ${ovs_of_tunnel_1}    ${TUN}
    ${ovs_of_tunnel_2}    Get Tunnel From OVS Show    ${conn_id_2}    BR2
    Should Contain    ${ovs_of_tunnel_2}    ${TUN}
    ${ovs_of_tunnel_3}    Get Tunnel From OVS Show    ${conn_id_3}    BR3
    Should Contain    ${ovs_of_tunnel_3}    ${TUN}
    ${count}    Get Count    ${ovs_of_tunnel_1}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    ${count}    Get Count    ${ovs_of_tunnel_2}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    ${count}    Get Count    ${ovs_of_tunnel_3}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    SLEEP    5
    Wait Until Keyword Succeeds    40    10    Get ITM for 3 DPNs    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${Dpn_id_3}    ${TOOLS_SYSTEM_3_IP}
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${tunnel-type}=    Set Variable    type: vxlan
    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${ovs_of_tunnel_1}
    ...    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${ovs_of_tunnel_2}
    ...    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_3}    ${TOOLS_SYSTEM_3_IP}    ${ovs_of_tunnel_3}
    ...    ${tunnel-type}
    ${url-2}=    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${ovs_of_tunnel_1}    ${ovs_of_tunnel_2}    ${url-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
    ${Dpn_id_3}=    Convert To String    ${Dpn_id_3}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${ovs_of_tunnel_1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${ovs_of_tunnel_2}
    Should Contain    ${resp.content}    ${Dpn_id_3}    ${ovs_of_tunnel_3}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    30s    10s    Check karaf output

Delete and verify OF tunnels on all 3 DPNs
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    SLEEP    5
    Display OVS Show    ${conn_id_1}
    Display OVS Show    ${conn_id_2}
    Display OVS Show    ${conn_id_3}

Configure and Verify OF based Tunnels of Two of 3 Dpns
    ${POSITIVE_VAL}=    Set Variable    1
    Set Global Variable    ${POSITIVE_VAL}
    ${Dpn_id_1}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}    BR1
    ${Dpn_id_2}    OVSDB.Get DPID    ${TOOLS_SYSTEM_2_IP}    BR2
    ${Dpn_id_3}    OVSDB.Get DPID    ${TOOLS_SYSTEM_3_IP}    BR3
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    Set Global Variable    ${Dpn_id_3}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${file_name}=    Set Variable    vtep_three_dpns_with_mix_match.json
    Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${file_name}
    ...    3
    Sleep    5
    Display OVS Show    ${conn_id_1}
    Sleep    2
    Display OVS Show    ${conn_id_2}
    Sleep    2
    Display OVS Show    ${conn_id_3}
    Sleep    2
    ${ovs_of_tunnel_1}    Get Tunnel From OVS Show    ${conn_id_1}    BR1
    Should Contain    ${ovs_of_tunnel_1}    ${TUN}
    ${ovs_of_tunnel_2}    Get Tunnel From OVS Show    ${conn_id_2}    BR2
    Should Contain    ${ovs_of_tunnel_2}    ${TUN}
    ${ovs_of_tunnel_3}    Get Tunnel From OVS Show    ${conn_id_3}    BR3
    Should Contain    ${ovs_of_tunnel_3}    ${TUN}
    ${count}    Get Count    ${ovs_of_tunnel_1}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    ${count}    Get Count    ${ovs_of_tunnel_2}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    ${count}    Get Count    ${ovs_of_tunnel_3}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${THREE}
    SLEEP    5
    Wait Until Keyword Succeeds    40    10    Get ITM for 3 DPNs    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${Dpn_id_3}    ${TOOLS_SYSTEM_3_IP}
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${ovs_of_tunnel_1}
    ...    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${ovs_of_tunnel_2}
    ...    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_3}    ${TOOLS_SYSTEM_3_IP}    ${ovs_of_tunnel_3}
    ...    ${tunnel-type}
    ${url-2}=    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${ovs_of_tunnel_1}    ${ovs_of_tunnel_2}    ${url-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
    ${Dpn_id_3}=    Convert To String    ${Dpn_id_3}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${ovs_of_tunnel_1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${ovs_of_tunnel_2}
    Should Contain    ${resp.content}    ${Dpn_id_3}    ${ovs_of_tunnel_3}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    ${output}=    Issue Command On Karaf Console    ${VXLAN_SHOW}
    Should Not Contain    ${output}    ${DISABLE}
    Should Contain    ${output}    ${ENABLED}

Delete and verify OF tunnels on two of 3 Dpns
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    SLEEP    5
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    SLEEP    1
    Display OVS Show    ${conn_id_1}
    Display OVS Show    ${conn_id_2}
    Display OVS Show    ${conn_id_3}

Verify \ Of Tunnel ports gets deleted when TEP is deleted from DPN
    ${Dpn_id_1}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}    BR1
    ${Dpn_id_2}    OVSDB.Get DPID    ${TOOLS_SYSTEM_2_IP}    BR2
    ${Dpn_id_3}    OVSDB.Get DPID    ${TOOLS_SYSTEM_3_IP}    BR3
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    Set Global Variable    ${Dpn_id_3}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${file_name}=    Set Variable    vtep_three_dpns_with_of_tunnel.json
      Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${file_name}
    ...    3
    Sleep    5
    Display OVS Show    ${conn_id_1}
    Sleep    2
    Display OVS Show    ${conn_id_2}
    Sleep    2
    Display OVS Show    ${conn_id_3}
    Sleep    2
    ${file_name}=    Set Variable    vtep_two_dpns_with_of_tunnel.json
    ${body}    set json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}
    ...    ${subnet}    ${file_name}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/TZA    data=${body}
    Sleep    5
    Display OVS Show    ${conn_id_1}
    Sleep    2
    Display OVS Show    ${conn_id_2}
    Sleep    2
    Display OVS Show    ${conn_id_3}
    Sleep    2
    ${ovs_of_tunnel_1}    Get Tunnel From OVS Show    ${conn_id_1}    BR1
    Should Contain    ${ovs_of_tunnel_1}    ${TUN}
    ${ovs_of_tunnel_2}    Get Tunnel From OVS Show    ${conn_id_2}    BR2
    Should Contain    ${ovs_of_tunnel_2}    ${TUN}
    ${ovs_of_tunnel_3}    Get Tunnel From OVS Show    ${conn_id_3}    BR3
    ${count}    Get Count    ${ovs_of_tunnel_1}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    ${count}    Get Count    ${ovs_of_tunnel_2}    ${TUN}
    ${count}=    Convert To String    ${count}
    Should Be Equal    ${count}    ${ONE}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${ovs_of_tunnel_1}
    ...    ${tunnel-type}
       Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${ovs_of_tunnel_2}
    ...    ${tunnel-type}
       ${url-2}=    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${ovs_of_tunnel_1}    ${ovs_of_tunnel_2}    ${url-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${ovs_of_tunnel_1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${ovs_of_tunnel_2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    Should Be Equal As Strings    ${resp.status_code}    200

Delete and Verify Of tunnels on two of 3 DPNSs
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    SLEEP    5
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    SLEEP    1
    Display OVS Show    ${conn_id_1}
    Display OVS Show    ${conn_id_2}
    Display OVS Show    ${conn_id_3}

Verify OF Tunnel ports gets deleted when all TEP are deleted on other DPNs
    ${POSITIVE_VAL}    Set Variable    1
    Set Global Variable    ${POSITIVE_VAL}
    ${Dpn_id_1}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}    BR1
    ${Dpn_id_2}    OVSDB.Get DPID    ${TOOLS_SYSTEM_2_IP}    BR2
    ${Dpn_id_3}    OVSDB.Get DPID    ${TOOLS_SYSTEM_3_IP}    BR3
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    Set Global Variable    ${Dpn_id_3}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${file_name}=    Set Variable    vtep_three_dpns_with_of_tunnel.json
      Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${file_name}
    ...    3
    Sleep    5
    Display OVS Show    ${conn_id_1}
    Sleep    2
    Display OVS Show    ${conn_id_2}
    Sleep    2
    Display OVS Show    ${conn_id_3}
    Sleep    2
    ${file_name}=    Set Variable    vtep_one_dpns_with_of_tunnel.json
    ${body}    Set Json for 1 DPN    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}
    ...    ${subnet}    ${file_name}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/TZA    data=${body}
    ${ovs_of_tunnel_1}    Get Tunnel From OVS Show    ${conn_id_1}    BR1
    Should Contain    ${ovs_of_tunnel_1}    ${TUN}
    ${ovs_of_tunnel_2}    Get Tunnel From OVS Show    ${conn_id_2}    BR2
    Should Contain    ${ovs_of_tunnel_2}    ${TUN}
    ${ovs_of_tunnel_3}    Get Tunnel From OVS Show    ${conn_id_3}    BR3
    Should Contain    ${ovs_of_tunnel_3}    ${TUN}
    SLEEP    5
    Wait Until Keyword Succeeds    40    10    Get ITM for 1 Dpn    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${Dpn_id_3}    ${TOOLS_SYSTEM_3_IP}
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${tunnel-type}=    Set Variable    type: vxlan
    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${ovs_of_tunnel_1}
    ...    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${ovs_of_tunnel_2}
    ...    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For OF Tunnels    ${conn_id_3}    ${TOOLS_SYSTEM_3_IP}    ${ovs_of_tunnel_3}
    ...    ${tunnel-type}
    ${url-2}=    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${ovs_of_tunnel_1}    ${ovs_of_tunnel_2}    ${url-2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
     Should Be Equal As Strings    ${resp.status_code}    200
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
    ${Dpn_id_3}=    Convert To String    ${Dpn_id_3}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${ovs_of_tunnel_1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${ovs_of_tunnel_2}
    Should Contain    ${resp.content}    ${Dpn_id_3}    ${ovs_of_tunnel_3}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
     Should Be Equal As Strings    ${resp.status_code}    200
    sleep    60
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Issue Command On Karaf Console    ${VXLAN_SHOW}
    Should Not Contain    ${output}    ${DISABLE}
    Should Not Contain    ${output}    ${DOWN}

Delete and Verify when 2 Dpns deleted
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    SLEEP    5
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    SLEEP    1
    Display OVS Show    ${conn_id_1}
    Display OVS Show    ${conn_id_2}
    Display OVS Show    ${conn_id_3}

Verify update or modification of OF based tunnels on one DPN of 2 DPNso
    ${POSITIVE_VAL}    Set Variable    1
    Set Global Variable    ${POSITIVE_VAL}
    ${Dpn_id_1}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}    BR1
    ${Dpn_id_2}    OVSDB.Get DPID    ${TOOLS_SYSTEM_2_IP}    BR2
    ${Dpn_id_3}    OVSDB.Get DPID    ${TOOLS_SYSTEM_3_IP}    BR3
    Switch Connection    ${conn_id_1}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${file_name}=    Set Variable    vtep_two_dpns_with_of_tunnel.json
    Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${file_name}
    ...    2
    sleep    60
    ${output}=    Issue Command On Karaf Console    ${VXLAN_SHOW}
    Display OVS Show    ${conn_id_1}
    Sleep    5
    Display OVS Show    ${conn_id_2}
    Sleep    5
    ${file_name}=    Set Variable    vtep_one_dpns_without_of_tunnel .json
    ${body}    Set Json for 1 DPN    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}
    ...    ${subnet}    ${file_name}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/TZA    data=${body}

    ${output}=    Wait Until Keyword Succeeds    60s    10s    Issue Command On Karaf Console    ${VXLAN_SHOW}


*** Keywords ***
Create Vteps
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${file_name}
    ...    ${No_Of_Dpns}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${TWO_DPNs}    Set Variable    2
    ${THREE_DPNs}    Set Variable    3
    ${file_dir}    Catenate    ${genius_config_dir}/
    ${file}    Catenate    SEPARATOR=    ${file_dir}    ${file_name}
    ${body}    OperatingSystem.Get File    ${file}
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    Run Keyword If    ${No_Of_Dpns} == ${TWO_DPNs}    set json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
    ...    ${vlan}    ${gateway-ip}    ${subnet}    ${file_name}
    ...    ELSE IF    ${No_Of_Dpns} == ${THREE_DPNs}    set json for 3 Dpns    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
    ...    ${vlan}    ${gateway-ip}    ${subnet}    ${file_name}

    Set Global variable    ${body}    #${body}    set json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
    ...    #${vlan}    ${gateway-ip}    ${subnet}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    should be equal as strings    ${resp.status_code}    204

Get Dpn Ids
    [Arguments]    ${connection_id}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl show | grep Bridge | awk -F "\\"" '{print $2}'
    ${Bridgename1}    Execute command    ${cmd}
    SLEEP    2
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${Bridgename1} | head -1 | awk -F "dpid:" '{ print $2 }'
    SLEEP    2
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    SLEEP    2
    [Return]    ${Dpn_id}

Get Tunnel
    [Arguments]    ${src}    ${dst}    ${type}
    [Documentation]    This Keyword Gets the Tunnel /Interface name which has been created between 2 DPNS by passing source , destination DPN Ids along with the type of tunnel which is configured.
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/${type}/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${src}    ${dst}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel}    Get From List    ${resp_array}    4
    [Return]    ${Tunnel}

Validate interface state
    [Arguments]    ${tunnel-1}    ${dpid-1}    ${tunnel-2}    ${dpid-2}
    [Documentation]    Validates the created Interface Tunnel by checking its Operational status as UP/DOWN from the dump.
    ${data1-2}    Wait Until Keyword Succeeds    40    10    Check Interface status    ${tunnel-1}    ${dpid-1}
    ${data2-1}    Wait Until Keyword Succeeds    40    10    Check Interface status    ${tunnel-2}    ${dpid-2}
    @{data}    combine lists    ${data1-2}    ${data2-1}
    [Return]    ${data}

Check Table0 Entry for 2 Dpn
    [Arguments]    ${connection_id}    ${Bridgename}    ${port-num1}
    [Documentation]    Checks the Table 0 entry in the OVS when flows are dumped.
    Switch Connection    ${connection_id}
    ${check}    Execute Command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridgename}
    Should Contain    ${check}    in_port=${port-num1}
    [Return]    ${check}

Ovs Verification 2 Dpn
    [Arguments]    ${connection_id}    ${local}    ${remote-1}    ${tunnel}    ${tunnel-type}
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    Switch Connection    ${connection_id}
    ${check}    Execute Command    sudo ovs-vsctl show
    Should Contain    ${check}    local_ip="${local}"    remote_ip="${remote-1}"    ${tunnel}
    Should Contain    ${check}    ${tunnel-type}
    [Return]    ${check}

Ovs Verification For OF Tunnels
    [Arguments]    ${connection_id}    ${local}    ${tunnel}    ${tunnel-type}
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    Switch Connection    ${connection_id}
    ${check}    Execute Command    sudo ovs-vsctl show
    Should Contain    ${check}    local_ip="${local}"    remote_ip=flow    ${tunnel}
    Should Contain    ${check}    ${tunnel-type}
    [Return]    ${check}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}
    ...    ${TOOLS_SYSTEM_2_IP}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${Bridge-2}-eth1    ${TOOLS_SYSTEM_2_IP}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Get ITM for 3 DPNs
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}
    ...    ${TOOLS_SYSTEM_2_IP}    ${Dpn_id_3}    ${TOOLS_SYSTEM_3_IP}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    ${Dpn_id_2}=    Convert To String    ${Dpn_id_2}
    ${Dpn_id_3}=    Convert To String    ${Dpn_id_3}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${Bridge-2}-eth1    ${TOOLS_SYSTEM_2_IP}    ${Dpn_id_3}    ${Bridge-3}-eth1
    ...    ${TOOLS_SYSTEM_3_IP}
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
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/    headers=${ACCEPT_XML}
    #${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    404
    Should not contain    ${resp.content}    ${tunnel}

set json
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${subnet}
    ...    ${file}
    [Documentation]    Sets Json for 2 dpns with the values passed for it.
    #${body}    OperatingSystem.Get File    ${genius_config_dir}/vtep_two_dpns_with_of_tunnel.json
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/${file}
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id": 101    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id": 102    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${TOOLS_SYSTEM_IP}"
    ${body}    replace string    ${body}    "ip-address": "3.3.3.3"    "ip-address": "${TOOLS_SYSTEM_2_IP}"
    ${body}    replace string    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    ${2_node_vtep}    Set Variable    ${body}
    Set Global Variable    ${2_node_vtep}
    [Return]    ${body}    # returns complete json that has been updated

set json for 3 dpns
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${subnet}
    ...    ${file}
    [Documentation]    Sets Json for 3 dpns with the values passed for it.
    #${body}    OperatingSystem.Get File    ${genius_config_dir}/vtep_three_dpns_with_of_tunnel.json
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/${file}
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id": 101    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id": 102    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "dpn-id": 103    "dpn-id": ${Dpn_id_3}
    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${TOOLS_SYSTEM_IP}"
    ${body}    replace string    ${body}    "ip-address": "3.3.3.3"    "ip-address": "${TOOLS_SYSTEM_2_IP}"
    ${body}    replace string    ${body}    "ip-address": "4.4.4.4"    "ip-address": "${TOOLS_SYSTEM_3_IP}"
    ${body}    replace string    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    [Return]    ${body}    # returns complete json that has been updated

Set Json for 1 DPN
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${subnet}
    ...    ${file}
    [Documentation]    Sets Json for 1 dpn with the values passed for it.
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/${file}
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id": 101    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${TOOLS_SYSTEM_IP}"
    ${body}    replace string    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    [Return]    ${body}    # returns complete json that has been updated

check-Tunnel-delete-on-ovs
    [Arguments]    ${connection-id}    ${tunnel}
    [Documentation]    Verifies the Tunnel is deleted from OVS
    Switch Connection    ${connection-id}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
    Should Not Contain    ${return}    ${tunnel}
    [Return]    ${return}

check interface status
    [Arguments]    ${tunnel}    ${dpid}
    [Documentation]    Verifies the operational state of the interface .
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/    headers=${ACCEPT_XML}
    #${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    Should not contain    ${resp.content}    down
    Should Contain    ${resp.content}    ${tunnel}    up    up
    ${result-1}    re.sub    <.*?>    ,    ${resp.content}
    ${lower_layer_if}    Should Match Regexp    ${result-1}    openflow:${dpid}:[0-9]+
    @{resp_array}    Split String    ${lower_layer_if}    :
    ${port-num}    Get From List    ${resp_array}    2
    [Return]    ${lower_layer_if}    ${port-num}

Verify Data Base after Delete
    [Arguments]    ${Dpn_id_1}    ${Dpn_id_2}    ${tunnel-1}    ${tunnel-2}
    [Documentation]    Verifies the config database after the Tunnel deletion is done.
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    No Content From URI    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_1}/${Dpn_id_2}/${type}/    headers=${ACCEPT_XML}
    No Content From URI    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_2}/${Dpn_id_1}/${type}/    headers=${ACCEPT_XML}
    No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    ${resp_7}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Run Keyword if    '${resp_7.content}'=='404'    Response is 404
    Run Keyword if    '${resp_7.content}'=='200'    Response is 200
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${CONFIG_TOPO_API}    ${tunnel-1}
    ...    ${tunnel-2}
    ${Ovs-del-1}    Wait Until Keyword Succeeds    40    10    check-Tunnel-delete-on-ovs    ${conn_id_1}    ${tunnel-1}
    ${Ovs-del-2}    Wait Until Keyword Succeeds    40    10    check-Tunnel-delete-on-ovs    ${conn_id_2}    ${tunnel-2}
    ${url-2}=    Set variable    ${OPERATIONAL_API}/network-topology:network-topology/
    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${url-2}    ${tunnel-1}    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-2}

Display OVS Show
    [Arguments]    ${connection_id}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl show
    ${Bridgename1}    Execute command    ${cmd}
    log    ${Bridgename1}

Get Tunnel From OVS Show
    [Arguments]    ${connection_id}    ${bridge}
    [Documentation]    This keyword gets the tunnel id from ovs switch and return it.
    Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl list-ports
    ${cmd1}=    Catenate    ${cmd}    ${bridge}
    ${Oftunnel}    Execute command    ${cmd1}
    [Return]    ${Oftunnel}

Update Vteps
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${file_name}
    ...    ${No_Of_Dpns}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${TWO_DPNs}    Set Variable    2
    ${THREE_DPNs}    Set Variable    3
    #${file}    Catenate    SEPARATOR=/    ${genius_config_dir}    ${file_name}
    ${file_dir}    Catenate    ${genius_config_dir}/
    ${file}    Catenate    SEPARATOR=    ${file_dir}    ${file_name}
    #${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    #${body}    OperatingSystem.Get File    ${genius_config_dir}/vtep_three_dpns_with_of_tunnel.json
    ${body}    OperatingSystem.Get File    ${file}
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    Run Keyword If    ${No_Of_Dpns} == ${TWO_DPNs}    set json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
    ...    ${vlan}    ${gateway-ip}    ${subnet}    ${file_name}
    ...    ELSE IF    ${No_Of_Dpns} == ${THREE_DPNs}    set json for 3 Dpns    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
    ...    ${vlan}    ${gateway-ip}    ${subnet}    ${file_name}

    Set Global variable    ${body}    #${body}    set json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
    ...    #${vlan}    ${gateway-ip}    #${subnet}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/TZA    data=${body}
    should be equal as strings    ${resp.status_code}    200

Check karaf output
    ${output}=    Issue Command On Karaf Console    ${VXLAN_SHOW}
    Should Not Contain    ${output}    ${DISABLE}
    Should Not Contain    ${output}    ${DOWN}

Get ITM for 1 Dpn
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}
    ...    ${TOOLS_SYSTEM_2_IP}    ${Dpn_id_3}    ${TOOLS_SYSTEM_3_IP}
    ${Dpn_id_1}=    Convert To String    ${Dpn_id_1}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}
