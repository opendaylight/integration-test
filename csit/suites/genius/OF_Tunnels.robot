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
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../variables/Variables.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/ODLTools.robot
Resource          ../../libraries/Genius.robot

*** Variables ***
${VLAN}           0

*** Test Cases ***
Create and Verify VTEP
    [Documentation]    This testcase creates an OF based ITM tunnel between 2 DPNs
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${VLAN}    ${gateway-ip}
    ...    option-of-tunnel=true
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${VLAN}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    20    Get_Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    20    Get_Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ${tunnel-type}=    Set Variable    type: vxlan
    ${remote-ip}=    Set Variable    flow
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    Wait Until Keyword Succeeds    40    10    Ovs Verification For 2 Dpn    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${remote-ip}
    ...    ${tunnel-1}    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${remote-ip}
    ...    ${tunnel-2}    ${tunnel-type}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-2}
    ${Port_num1}    Get Port Number    ${conn_id_1}    ${Bridge}    ${tunnel-1}
    ${Port_num2}    Get Port Number    ${conn_id_2}    ${Bridge}    ${tunnel-2}
    ${check-3}    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_1}    ${Bridge}
    ...    ${Port_num1}
    ${check-4}    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_2}    ${Bridge}
    ...    ${Port_num2}

*** Keywords ***
Get_Tunnel
    [Arguments]    ${src}    ${dst}
    [Documentation]    This Keyword Gets the Tunnel Interface name which has been created between 2 DPNS by passing source , destination DPN Ids along with the type of tunnel which is configured.
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-teps-state/dpns-teps/${src}/remote-dpns/${dst}/
    log    ${resp.content}
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${dst}
    ${json}=    evaluate    json.loads('''${resp.content}''')    json
    ${return}    Run Keyword And Return Status    Should contain    ${resp.content}    tunnel-name
    log    ${return}
    ${ret}    Run Keyword If    '${return}'=='True'    Check_Interface_Name    ${json["remote-dpns"][0]}    tunnel-name
    [Return]    ${ret}

Get Port Number
    [Arguments]    ${connection_id}    ${Bridgename}    ${tunnel}
    [Documentation]    In this we get Port Number to check table0 entry for 2 Dpn
    Switch Connection    ${connection_id}
    ${check-1}    Execute Command    sudo ovs-ofctl -O OpenFlow13 show ${Bridgename}
    Log    ${check-1}
    ${lines}    Get Lines Containing String    ${check-1}    ${tunnel}
    Log    ${lines}
    ${port}    Get Regexp Matches    ${lines}    \\d+
    ${port_num}    Get From List    ${port}    0
    Should Contain    ${check-1}    ${port_num}
    [Return]    ${port_num}
