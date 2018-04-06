*** Settings ***
Documentation     Test Suite for Service Recovery.
...               Find detailed test plan here, http://docs.opendaylight.org/en/latest/submodules/genius/docs/testplans/service-recovery.html
Suite Setup       SRM Start Suite
Suite Teardown    SRM Stop Suite
Test Teardown     Genius Test Teardown    ${data_models}
Library           re
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/OVSDB.robot

*** Test Cases ***
ITM TZ Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name.
    Delete Tunnel on OVS
    Issue Command On Karaf Console    srm:recover INSTANCE ITM-TZ TZA
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP

ITM TEP Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name and tunnel's ip address.
    Delete Tunnel on OVS
    Issue Command On Karaf Console    srm:recover INSTANCE ITM-TEP TZA:${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP

ITM Service Recovery
    [Documentation]    This test case recovers ITM Service.
    ${tunnel} =    Get Tunnel
    Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/interface/${tunnel}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}
    Issue Command On Karaf Console    srm:recover SERVICE ITM
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP

IFM Instance Recovery
    [Documentation]    This test case recovers tunnel interface instance using interface name.
    ${tunnel} =    Get Tunnel
    Delete Tunnel on OVS
    Issue Command On Karaf Console    srm:recover INSTANCE IFM-IFACE ${tunnel}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP

IFM Service Recovery
    [Documentation]    This test case recovers IFM Service.
    ${tunnel} =    Get Tunnel
    Switch Connection    ${conn_id_1}
    ${uuid}    ${bridge} =    OVSDB.Get Bridge data
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}uuid%2F${uuid}%2Fbridge%2F${bridge}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}
    Issue Command On Karaf Console    srm:recover SERVICE IFM
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP

*** Keywords ***
Delete Tunnel on OVS
    [Documentation]    Deletes a tunnel interface on switch and verify deletion on OVS.
    ${dpn_Id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_Id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel} =    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_Id_1}    ${dpn_Id_2}
    ...    odl-interface:tunnel-type-vxlan
    Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-port ${tunnel}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}

SRM Start Suite
    [Documentation]    Start suite for service recovery.
    Genius Suite Setup
    ${dpn_Id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_Id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    Genius.Create Vteps    ${dpn_Id_1}    ${dpn_Id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ${tunnel} =    BuiltIn.Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_Id_1}    ${dpn_Id_2}
    ...    odl-interface:tunnel-type-vxlan
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP
    [Teardown]    Genius Test Teardown    ${data_models}

SRM Stop Suite
    Delete All Vteps
    Genius Suite Teardown

Get Tunnel
    ${dpn_Id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_Id_2 } =    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel} =    BuiltIn.Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_Id_1}    ${dpn_Id_2}
    ...    odl-interface:tunnel-type-vxlan
    [Return]    ${tunnel}
