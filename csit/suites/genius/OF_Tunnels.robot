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
    Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${SUBNET}    ${NO_VLAN}
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Genius.Update Dpn id list and get tunnels    ${type}    dpn-teps-state
    Genius.Verify Response Code Of Dpn End Point Config API
    Wait Until Keyword Succeeds    40    10    Genius.Ovs OFT Interface Verification
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up
    Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number    oft_enabled=true
    Comment    TODO: Add Check for Table 95

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
