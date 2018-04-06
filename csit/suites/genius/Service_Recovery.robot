*** Settings ***
Documentation     Test Suite for Service Recovery.
...               Find detailed test plan here, http://docs.opendaylight.org/en/latest/submodules/genius/docs/testplans/service-recovery.html
Suite Setup       Genius.SRM Start Suite
Suite Teardown    Genius.SRM Stop Suite
Test Teardown     Genius Test Teardown    ${data_models}
Library           re
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Resource          ../../libraries/VpnOperations.robot

*** Variables ***

*** Test Cases ***
ITM TZ Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name.
    [Setup]
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE ITM-TZ TZA
    Wait Until Keyword Succeeds    30s    5s    Genius.Verify Tunnels are UP

ITM TEP Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name and tunnel's ip address.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE ITM-TEP TZA:${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    90s    5s    Genius.Verify Tunnels are UP

ITM Service Recovery
    [Documentation]    This test case recovers ITM Service.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    odl-interface:tunnel-type-vxlan
    ${Result}    Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/interface/${tunnel}
    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}
    Issue_Command_On_Karaf_Console    srm:recover SERVICE ITM
    Wait Until Keyword Succeeds    60s    10s    Genius.Verify Tunnels are UP

IFM Instance Recovery
    [Documentation]    This test case recovers tunnel interface instance using interface name.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    odl-interface:tunnel-type-vxlan
    Log    ${tunnel}
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE IFM-IFACE ${tunnel}
    Wait Until Keyword Succeeds    60s    10s    Genius.Verify Tunnels are UP

IFM Service Recovery
    [Documentation]    This test case recovers IFM Service.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    Switch Connection    ${conn_id_1}
    ${uuid}    ${bridge}    OVSDB.Get Bridge data
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    odl-interface:tunnel-type-vxlan
    Remove All Elements At URI And Verify    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${uuid}%2Fbridge%2F${bridge}
    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}
    Issue_Command_On_Karaf_Console    srm:recover SERVICE IFM
    Wait Until Keyword Succeeds    60s    10s    Genius.Verify Tunnels are UP

*** Keywords ***
Delete Tunnel
    [Documentation]    Deletes a tunnel interface on switch and verify deletion on OVS.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    odl-interface:tunnel-type-vxlan
    Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-port ${tunnel}
    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}
