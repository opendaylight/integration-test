*** Settings ***
Documentation     This test suite is to by-pass interface manager and create/delete the tunnels between the switches directly inorder for ITM to scale and build mesh among more number of switches.
Suite Setup       ITM Direct Tunnels Start Suite
Suite Teardown    ITM Direct Tunnels Stop Suite
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/ToolsSystem.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***

*** Test Cases ***
Create and Verify VTEP
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${subnet}    ${NO_VLAN}
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Genius.Update Dpn id list and get tunnels    ${type}    dpn-teps-state
    Genius.Verify Data From Dpn endpoint config API
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    ${respjson} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Log    ${respjson}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number

Verify VTEP After Restarting OVS
    [Documentation]    Verify Testcase, Verifying tunnel state by restarting OVS
    BuiltIn.Wait Until Keyword Succeeds    20    2    Genius.Verify Tunnel Status As Up
    OVSDB.Restart OVSDB    ${TOOLS_SYSTEM_IP}

Verify VTEP After Restarting Controller
    [Documentation]    Verify Testcase, Verifying tunnel state by restarting CONTROLLER
    BuiltIn.Wait Until Keyword Succeeds    30    3    Genius.Verify Tunnel Status As Up
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    Wait Until Keyword Succeeds    60    3    ClusterManagement.Check Status Of Services Is OPERATIONAL
    Wait Until Keyword Succeeds    30    3    Genius.Verify Tunnel Status As Up

Verify Tunnels By Disabling BFD
    [Documentation]    This test case will verify tunnels after disabling BFD and verifies tunnel status as unknown after stopping OVS.
    ${result} =    BuiltIn.Run Keyword And Return Status    Verify Tunnel Monitoring Is On
    BuiltIn.Run Keyword If    '${result}' == 'True'    Disable_Tunnel_Monitoring
    ${tunnels_on_OVS} =    Genius.Get Tunnels On OVS    ${TOOLS_SYSTEM_ALL_CONN_IDS[0]}
    OVSDB.Stop OVS    ${TOOLS_SYSTEM_IP}
    Genius.Verify Tunnel Status    UNKNOWN    ${tunnels_on_OVS}
    OVSDB.Start OVS    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    20    2    Genius.Verify Tunnel Status As Up

Verify Tunnels By Enabling BFD
    [Documentation]    This test case will check the tunnel exists by bringing up/down a switch and check tunnels exist by enabling BFD
    ${result}    BuiltIn.Run Keyword And Return Status    Genius.Verify Tunnel Monitoring Is On
    BuiltIn.Run Keyword If    '${result}' == 'False'    Enable_Tunnel_monitoring
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    Verify Tunnel State After OVS Restart    ${tools_ip}

Delete and Verify VTEP
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    KarafKeywords.Issue Command On Karaf Console    tep:commit
    ${dpn_id_index} =    Set Variable    0
    ${tunnel-list}    Genius.Get Tunnels List
    : FOR    ${node}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    KarafKeywords.Issue Command On Karaf Console    tep:delete @{DPN_ID_LIST}[${dpn_id_index}] ${port_name} ${NO_VLAN} ${node} ${subnet}/16 null ${itm_created[0]}
    \    KarafKeywords.Issue Command On Karaf Console    tep:commit
    \    ${dpn_id_index} =    Evaluate    ${dpn_id_index}+1
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    BuiltIn.Run Keyword And Ignore Error    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Deleted Tunnels On OVS    ${tunnel-list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel-list}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    Log    ${respjson}
    BuiltIn.Should Not Contain    ${resp.content}    ${itm_created[0]}

*** Keywords ***
Enable_Tunnel_Monitoring
    [Documentation]    In this we will enable tunnel monitoring by tep:enable command running in karaf console
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    tep:enable-tunnel-monitor true

Verify Tunnel State After OVS Restart
    [Arguments]    ${TOOLS_SYSTEM_IP}
    [Documentation]    In this we will Verify Tunnel State by Stopping/Starting Switch
    OVSDB.Stop OVS    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    2min    20 sec    Verify Tunnel Down
    OVSDB.Start OVS    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    2min    20 sec    Genius.Verify Tunnel Status As Up

Verify Tunnel Down
    [Documentation]    In this we will check whether tunnel is in down or not
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Contain    ${output}    DOWN

Disable_Tunnel_Monitoring
    [Documentation]    In this we will disable tunnel monitoring by tep:enable command running in karaf console
    KarafKeywords.Issue_Command_On_Karaf_Console    tep:enable-tunnel-monitor false
