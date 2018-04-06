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
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE ITM-TZ TZA:${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    30s    10s    Genius.Tunnel status UP

ITM TZ Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE ITM-TZ TZA
    Wait Until Keyword Succeeds    30s    10s    Genius.Tunnel status UP

ITM Service Recovery
    [Documentation]    This test case recovers ITM Service.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover service ITM
    Wait Until Keyword Succeeds    30s    10s    Genius.Tunnel status UP

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
    Wait Until Keyword Succeeds    30s    10s    Genius.Tunnel status UP

IFM Service Recovery
    [Documentation]    This test case recovers IFM Service.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover service IFM
    Wait Until Keyword Succeeds    30s    10s    Genius.Tunnel status UP

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
