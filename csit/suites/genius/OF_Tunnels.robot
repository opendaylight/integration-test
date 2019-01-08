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
    [Documentation] Creates a TZ with TEPs set to use OF based Tunnels and verify
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}
    Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${SUBNET}    ${NO_VLAN}
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Genius.Update Dpn id list and get tunnels    ${type}    dpn-teps-state
    Genius.Verify Response Code Of Dpn Endpointconfig API
    Wait Until Keyword Succeeds    40    10    Genius.Ovs OFT Interface Verification
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up
    Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number    oft_enabled=true
    Comment TODO: Add Check for Table 95
