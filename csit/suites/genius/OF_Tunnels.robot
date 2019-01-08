*** Settings ***
Documentation     This test suite is to verify correspondence of OF based tunnels with Non OF based tunnels.
Suite Setup       ITM Direct Tunnels Start Suite
Suite Teardown    ITM Direct Tunnels Stop Suite
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           OperatingSystem
Library           SSHLibrary
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/ODLTools.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/netvirt/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${VLAN}           0

*** Test Cases ***
Create and Verify VTEP
    [Documentation]    This testcase creates an OF based ITM tunnel between 2 DPNs
    ${dpn_id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    ${gateway_ip} =    Set Variable    0.0.0.0
    Genius.Create Vteps    ${dpn_id_1}    ${dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${VLAN}    ${gateway_ip}
    ...    option_of_tunnel=true
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${VLAN}
    ...    ${dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type} =    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel_1} =    Wait Until Keyword Succeeds    40    20    Get Tunnel    ${dpn_id_1}    ${dpn_id_2}
    ${tunnel_2} =    Wait Until Keyword Succeeds    40    20    Get Tunnel    ${dpn_id_2}    ${dpn_id_1}
    ${tunnel_type} =    Set Variable    type: vxlan
    ${remote_ip} =    Set Variable    flow
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn_id_1}/
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn_id_2}/
    Wait Until Keyword Succeeds    40    10    Ovs Verification For 2 Dpn    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${remote_ip}
    ...    ${tunnel_1}    ${tunnel_type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${remote_ip}
    ...    ${tunnel_2}    ${tunnel_type}
    ${list_1} =    Create List    ${dpn_id_1}    ${tunnel_1}    ${dpn_id_2}    ${tunnel_2}
    Check For Elements At URI    ${OPERATIONAL_API}/itm-state:tunnels_state/    ${list_1}    session    pretty_print_json=True
    ${port_num1} =    OVSDB.Get Port Number    ${conn_id_1}    ${tunnel_1}
    ${port_num2} =    OVSDB.Get Port Number    ${conn_id_2}    ${tunnel_2}
    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_1}    ${Bridge}    ${port_num1}
    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_2}    ${Bridge}    ${port_num2}

*** Keywords ***
Get Tunnel
    [Arguments]    ${src}    ${dst}
    [Documentation]    This Keyword Gets the Tunnel Interface name which has been created between 2 DPNS by passing source , destination DPN Ids.
    ${list_1} =    Create List    ${dst}    tunnel-name
    ${resp} =    Check For Elements At URI    ${CONFIG_API}/itm-state:dpn-teps-state/dpns-teps/${src}/remote-dpns/${dst}/    ${list_1}    session    pretty_print_json=True
    ${json} =    evaluate    json.loads('''${resp.content}''')    json
    ${tunnel_name} =    Collections.Get From Dictionary    ${json["remote-dpns"][0]}    tunnel-name
    [Return]    ${tunnel_name}
