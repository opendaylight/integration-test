*** Settings ***
Documentation     Test Suit for Service Recovery
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
ITM TEP Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name and tunnel's ip address.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE ITM-TEP TZA:${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    60s    5s    Tunnel status as UP

ITM TZ Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE ITM-TZ TZA
    Wait Until Keyword Succeeds    30s    5s    Tunnel status as UP

ITM Service Recovery
    [Documentation]    This test case recovers ITM Service.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${Result}    Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/interface/${tunnel}
    Switch Connection    ${conn_id_1}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
    Should Not Contain    ${return}    ${tunnel}
    Issue_Command_On_Karaf_Console    srm:recover SERVICE ITM
    Wait Until Keyword Succeeds    60s    10s    Tunnel status as UP

IFM Instance Recovery
    [Documentation]    This test case recovers tunnel interface instance using interface name.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    Log    ${tunnel}
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE IFM-IFACE ${tunnel}
    Wait Until Keyword Succeeds    60s    10s    Tunnel status as UP

IFM Service Recovery
    [Documentation]    This test case recovers IFM Service.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    Switch Connection    ${conn_id_1}
    ${result}    Execute Command    sudo ovs-vsctl show
    ${uuid}    Get Line    ${result}    0
    ${line}    ${bridge}    Should Match Regexp    ${result}    Bridge "(\\w+)"
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    Remove All Elements At URI And Verify    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${uuid}%2Fbridge%2F${bridge}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
    Should Not Contain    ${return}    ${tunnel}
    Issue_Command_On_Karaf_Console    srm:recover SERVICE IFM
    Wait Until Keyword Succeeds    60s    10s    Tunnel status as UP

*** Keywords ***
Delete Tunnel
    [Documentation]    this test case delete a tunnel interface on switch and verify deletion on OVS.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    Switch Connection    ${conn_id_1}
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    Execute Command    sudo ovs-vsctl del-port ${tunnel}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
    Should Not Contain    ${return}    ${tunnel}
