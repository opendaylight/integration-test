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

*** Test Cases ***
ITM TZ Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name.
    Delete Tunnel
    Issue Command On Karaf Console    srm:recover INSTANCE ITM-TZ TZA
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnels are UP

ITM TEP Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name and tunnel's ip address.
    Delete Tunnel
    Issue Command On Karaf Console    srm:recover INSTANCE ITM-TEP TZA:${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnels are UP

ITM Service Recovery
    [Documentation]    This test case recovers ITM Service.
    ${tunnel}=    Create Tunnel
    ${Result}=    Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/interface/${tunnel}
    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}
    Issue Command On Karaf Console    srm:recover SERVICE ITM
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnels are UP

IFM Instance Recovery
    [Documentation]    This test case recovers tunnel interface instance using interface name.
    ${tunnel}=    Create Tunnel
    Delete Tunnel
    Issue Command On Karaf Console    srm:recover INSTANCE IFM-IFACE ${tunnel}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnels are UP

IFM Service Recovery
    [Documentation]    This test case recovers IFM Service.
    ${tunnel}=    Create Tunnel
    Switch Connection    ${conn_id_1}
    ${uuid}    ${bridge}=    OVSDB.Get Bridge data
    Remove All Elements At URI And Verify    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${uuid}%2Fbridge%2F${bridge}
    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}
    Issue Command On Karaf Console    srm:recover SERVICE IFM
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnels are UP

*** Keywords ***
Delete Tunnel
    [Documentation]    Deletes a tunnel interface on switch and verify deletion on OVS.
    ${dpn_id_1}=    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_id_2}=    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel}=    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_id_1}    ${dpn_id_2}
    ...    odl-interface:tunnel-type-vxlan
    Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-port ${tunnel}
    Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel}

SRM Start Suite
    [Documentation]    Start suite for service recovery.
    Genius Suite Setup
    ${dpn_id_1}=    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_id_2}=    Genius.Get Dpn Ids    ${conn_id_2}
    Genius.Create Vteps    ${dpn_id_1}    ${dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ${tunnel}=    BuiltIn.Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_id_1}    ${dpn_id_2}
    ...    odl-interface:tunnel-type-vxlan
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Verify tunnels are UP
    [Teardown]    Genius Test Teardown    ${data_models}

SRM Stop Suite
    Delete All Vteps
    Genius Suite Teardown

Create Tunnel
    ${dpn_id_1}=    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_id_2}=    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel}=    BuiltIn.Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_id_1}    ${dpn_id_2}
    ...    odl-interface:tunnel-type-vxlan
    [Return]    ${tunnel}
