*** Settings ***
Documentation     This test suite is to verify working of OF based Tunnels
Suite Setup       OF Tunnels Start Suite
Suite Teardown    OF Tunnels Stop Suite
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

*** Test Cases ***
Create TZ with OFT TEPs
    [Documentation]    Creates a TZ with TEPs set to use OF based Tunnels and verify
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}
    Verify OFT Vteps Created

Delete TZ with OFT TEPs
    [Documentation]    Deletes a TZ with TEPs set to use OF based Tunnels and verify
    ${tunnel_list}    Genius.Get Tunnels List
    : FOR    ${dpn_id}    IN    @{DPN_ID_LIST}
    \    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/subnets/${SUBNET}%2F16/vteps/${dpn_id}/${port_name}
    ${output}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    Utils.Get Data From URI    session    ${CONFIG_API}/itm:transport-zones/
    BuiltIn.Should Not Contain    ${resp}    ${itm_created[0]}
    Wait Until Keyword Succeeds    40    10    Genius.Verify Deleted Tunnels On OVS    ${tunnel_list}    ${resp}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${tunnel_list}
    Comment    Needs Rework

Create TZ with single OFT TEPs
    [Documentation]    Creates a TZ with single TEPs set to use OF based Tunnels and verify
    ${dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}[0]    @{DPN_ID_LIST}[1]    ${EMPTY}
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}[0]    @{TOOLS_SYSTEM_ALL_IPS}[1]    ${EMPTY}
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}    ${tools_ips}
    Verify OFT Vteps Created    ${dpn_ids}    ${tools_ips}
    ${tools_ips} =    BuiltIn.Create List    ${EMPTY}    ${EMPTY}    @{TOOLS_SYSTEM_ALL_IPS}[2]
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}    ${tools_ips}
    Verify OFT Vteps Created

Delete TZ with single OFT TEPs
    [Documentation]    Delete a TZ with single TEPs set to use OF based Tunnels and verify
    Comment    TODO

*** Keywords ***
Verify OFT Vteps Created
    [Arguments]    ${dpn_ids}=${DPN_ID_LIST}    ${tools_ips}=${TOOLS_SYSTEM_ALL_IPS}
    ${extra_data} =    Collections.Combine Lists    ${dpn_ids}    ${tools_ips}
    Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${SUBNET}    ${NO_VLAN}
    ...    ${extra_data}  
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Genius.Update Dpn id list and get tunnels    ${type}    dpn-teps-state    ${dpn_ids}
    Genius.Verify Response Code Of Dpn End Point Config API    ${dpn_ids}
    Wait Until Keyword Succeeds    40    10    Genius.Ovs OFT Interface Verification    ${tools_ips}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    60    5    Verify Tunnel Status As Up
    Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number    oft_enabled=true    ${tools_ips}
    Comment    TODO: Add Check for Table 95
