*** Settings ***
Documentation     This test suite is to by-pass interface manager and create/delete the tunnels between the switches directly inorder for ITM to scale and build mesh among more number of switches.
Suite Setup       ITM Direct Tunnels Start Suite
Suite Teardown    ITM Direct Tunnels Stop Suite
Test Teardown     Genius Test Teardown    ${data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Library           Collections
Resource          ../../libraries/Utils.robot
Library           re
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/Genius.robot
Resource          ../../variables/Variables.robot
Resource          ../../libraries/OVSDB.robot

*** Variables ***

*** Test Cases ***
Create and Verify VTEP
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    20    Get_Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    20    Get_Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ${tunnel-type}=    Set Variable    type: vxlan
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/
    Wait Until Keyword Succeeds    40    5    Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/
    Wait Until Keyword Succeeds    40    10    Ovs Verification For 2 Dpn    ${conn_id_1}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    ...    ${tunnel-1}    ${tunnel-type}
    Wait Until Keyword Succeeds    40    10    Ovs Verification For 2 Dpn    ${conn_id_2}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_IP}
    ...    ${tunnel-2}    ${tunnel-type}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-2}
    ${Port_num1}    Get Port Number    ${conn_id_1}    ${Bridge-1}    ${tunnel-1}
    ${Port_num2}    Get Port Number    ${conn_id_2}    ${Bridge-2}    ${tunnel-2}
    ${check-3}    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_1}    ${Bridge-1}
    ...    ${Port_num1}
    ${check-4}    Wait Until Keyword Succeeds    40    10    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_2}    ${Bridge-2}
    ...    ${Port_num2}

Verify VTEP After Restarting OVS
    [Documentation]    Verify Testcase, Verifying tunnel state by restarting OVS
    Genius.Verify Tunnel Status as UP
    OVSDB.Restart OVSDB    ${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    30    3    Genius.Verify Tunnel Status as UP

Verify VTEP After Restarting Controller
    [Documentation]    Verify Testcase, Verifying tunnel state by restarting CONTROLLER
    Genius.Verify Tunnel Status as UP
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    Wait Until Keyword Succeeds    10    2    Check Service Status    ACTIVE    OPERATIONAL
    Wait Until Keyword Succeeds    30    3    Genius.Verify Tunnel Status as UP

Delete and Verify VTEP
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel-1}    Get_Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ${tunnel-2}    Get_Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp}    ${tunnel-1}    ${tunnel-2}
    ${Ovs-del-1}    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    ${Ovs-del-2}    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}

Verify Tunnels By Enabling BFD
    [Documentation]    This test case will check the tunnel exists by bringing up/down a switch and check tunnels exist by enabling BFD
    ${result}    Run Keyword And Return Status    Verify Tunnel Monitoring is on
    Run Keyword If    '${result}' == 'False'    Enable_Tunnel_monitoring
    Verify Tunnel State After OVS Restart    ${TOOLS_SYSTEM_IP}
    Verify Tunnel State After OVS Restart    ${TOOLS_SYSTEM_2_IP}

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

Check_Interface_Name
    [Arguments]    ${json}    ${expected_tunnel_interface_name}
    [Documentation]    This keyword Checks the Tunnel interface name is tunnel-interface-names in the output or not .
    ${Tunnels}    Collections.Get From Dictionary    ${json}    ${expected_tunnel_interface_name}
    Log    ${Tunnels}
    [Return]    ${Tunnels}

Enable_Tunnel_Monitoring
    [Documentation]    In this we will enable tunnel monitoring by tep:enable command running in karaf console
    ${output}    Issue_Command_On_Karaf_Console    tep:enable-tunnel-monitor true

Verify Tunnel State After OVS Restart
    [Arguments]    ${TOOLS_SYSTEM_IP}
    [Documentation]    In this we will Verify Tunnel State by Stopping/Starting Switch
    OVSDB.Stop OVS    ${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    2min    20 sec    Verify Tunnel Down
    OVSDB.Start OVS    ${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    2min    20 sec    Genius.Verify Tunnel Status as UP

Verify Tunnel Down
    [Documentation]    In this we will check whether tunnel is in down or not
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Should Contain    ${output}    DOWN

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
