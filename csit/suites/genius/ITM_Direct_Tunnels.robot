*** Settings ***
Documentation     This test suite is to by-pass interface manager and create/delete the tunnels between the switches directly inorder for ITM to scale and build mesh among more number of switches.
Suite Setup       ITM Direct Tunnels Start Suite
Suite Teardown    ITM Direct Tunnels Stop Suite
Test Setup        Genius Test Setup
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
    ${vlan}=    BuiltIn.Set Variable    0
    ${gateway-ip}=    BuiltIn.Set Variable    0.0.0.0
    Genius.Create Vteps    ${vlan}    ${gateway-ip}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ${type}    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${k}    BuiltIn.Set Variable    0
    BuiltIn.Set Suite Variable    ${k}
    Get Tunnel Between DPN's
    ${tunnel-type}=    BuiltIn.Set Variable    type: vxlan
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    BuiltIn.Wait Until Keyword Succeeds    40    5    Utils.Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${DPN_ID_LIST[${i}]}/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification    @{TOOLS_SYSTEM_LIST}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status as UP
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number

Verify VTEP After Restarting OVS
    [Documentation]    Verify Testcase, Verifying tunnel state by restarting OVS
    BuiltIn.Wait Until Keyword Succeeds    20    2    Genius.Verify Tunnel Status as UP
    OVSDB.Restart OVSDB    ${TOOLS_SYSTEM_IP}

Verify VTEP After Restarting Controller
    [Documentation]    Verify Testcase, Verifying tunnel state by restarting CONTROLLER
    BuiltIn.Wait Until Keyword Succeeds    30    3    Genius.Verify Tunnel Status as UP
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    Wait Until Keyword Succeeds    60    3    ClusterManagement.Check Status Of Services Is OPERATIONAL
    Wait Until Keyword Succeeds    30    3    Genius.Verify Tunnel Status as UP

Verify Tunnels By Disabling BFD
    [Documentation]    This test case will verify tunnels after disabling BFD and verifies tunnel status as unknown after stopping OVS.
    ${result} =    BuiltIn.Run Keyword And Return Status    Verify Tunnel Monitoring is on
    BuiltIn.Run Keyword If    '${result}' == 'True'    Disable_Tunnel_Monitoring
    ${tunnels_on_OVS} =    Genius.Get Tunnels On OVS    ${CONN_ID_LIST[0]}
    OVSDB.Stop OVS    ${TOOLS_SYSTEM_IP}
    Genius.Verify Tunnel Status    UNKNOWN    ${tunnels_on_OVS}
    OVSDB.Start OVS    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    20    2    Genius.Verify Tunnel Status as UP

Verify Tunnels By Enabling BFD
    [Documentation]    This test case will check the tunnel exists by bringing up/down a switch and check tunnels exist by enabling BFD
    ${result}    BuiltIn.Run Keyword And Return Status    Genius.Verify Tunnel Monitoring is on
    BuiltIn.Run Keyword If    '${result}' == 'False'    Enable_Tunnel_monitoring
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    Verify Tunnel State After OVS Restart    ${tools_ip}

Delete and Verify VTEP
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${tunnel-list}    Genius.Get Tunnels List
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.verify Deleted Tunnels on OVS    ${tunnel-list}    ${resp}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel-list}

*** Keywords ***
Get_Tunnel
    [Arguments]    ${src}    ${dst}
    [Documentation]    This Keyword Gets the Tunnel Interface name which has been created between 2 DPNS by passing source , destination DPN Ids along with the type of tunnel which is configured.
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-teps-state/dpns-teps/${src}/remote-dpns/${dst}/
    BuiltIn.Log    ${resp.content}
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Should Contain    ${resp.content}    ${dst}
    ${json} =    BuiltIn.Evaluate    json.loads('''${resp.content}''')    json
    ${return}    BuiltIn.Run Keyword And Return Status    BuiltIn.Should Contain    ${resp.content}    tunnel-name
    BuiltIn.Log    ${return}
    ${ret}    BuiltIn.Run Keyword If    '${return}'=='True'    Check_Interface_Name    ${json["remote-dpns"][0]}    tunnel-name
    [Return]    ${ret}

Check_Interface_Name
    [Arguments]    ${json}    ${expected_tunnel_interface_name}
    [Documentation]    This keyword Checks the Tunnel interface name is tunnel-interface-names in the output or not .
    ${Tunnels}    Collections.Get From Dictionary    ${json}    ${expected_tunnel_interface_name}
    BuiltIn.Log    ${Tunnels}
    [Return]    ${Tunnels}

Enable_Tunnel_Monitoring
    [Documentation]    In this we will enable tunnel monitoring by tep:enable command running in karaf console
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    tep:enable-tunnel-monitor true

Verify Tunnel State After OVS Restart
    [Arguments]    ${TOOLS_SYSTEM_IP}
    [Documentation]    In this we will Verify Tunnel State by Stopping/Starting Switch
    OVSDB.Stop OVS    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    2min    20 sec    Verify Tunnel Down
    OVSDB.Start OVS    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    2min    20 sec    Genius.Verify Tunnel Status as UP

Verify Tunnel Down
    [Documentation]    In this we will check whether tunnel is in down or not
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Contain    ${output}    DOWN

Disable_Tunnel_Monitoring
    [Documentation]    In this we will disable tunnel monitoring by tep:enable command running in karaf console
    KarafKeywords.Issue_Command_On_Karaf_Console    tep:enable-tunnel-monitor false

Get Tunnel Between DPN's
    [Documentation]    This keyword will get the tunnels between DPN's
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    @{Dpn_id_updated_list}    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove Values From List    ${Dpn_id_updated_list}    ${DPN_ID_LIST[${i}]}
    \    BuiltIn.Log Many    ${Dpn_id_updated_list}
    \    BuiltIn.Set Suite Variable    ${Dpn_id_updated_list}
    \    Get All Tunnels

Get All Tunnels
    [Documentation]    This keyword will get all the tunnels available
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM} -1
    \    ${tunnel}    BuiltIn.Wait Until Keyword Succeeds    30    10    Get_Tunnel    ${DPN_ID_LIST[${k}]}
    \    ...    ${Dpn_id_updated_list[${i}]}
    ${k}    BuiltIn.Evaluate    ${k} +1
    BuiltIn.Set Suite Variable    ${k}
