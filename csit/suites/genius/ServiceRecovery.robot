*** Settings ***
Documentation     Test Suit for Service Recovery
Suite Setup       SRM Start Suit
Suite Teardown    Genius Suite Teardown
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
    [Documentation]    This test case recover the tunnels using Itransportzone name and system's ip address.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE ITM-TZ TZA:${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify Tunnel Status as UP

ITM TZ Recovery
    [Documentation]    This test case recover the tunnels using transportzone name.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE ITM-TZ TZA
    Wait Until Keyword Succeeds    30s    10s    Verify Tunnel Status as UP

ITM Service Recovery
    [Documentation]    This test case recover the tunnels by recovering the ITM.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover service ITM
    Wait Until Keyword Succeeds    30s    10s    Verify Tunnel Status as UP

IFM Instance Recovery
    [Documentation]    This test case recover the tunnels using tunnel name.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    Log    ${tunnel}
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover INSTANCE IFM-IFACE ${tunnel}
    Wait Until Keyword Succeeds    30s    10s    Verify Tunnel Status as UP

IFM Service Recovery
    [Documentation]    This test case recover the tunnels by recovering IFM.
    Delete Tunnel
    Issue_Command_On_Karaf_Console    srm:recover service IFM
    Wait Until Keyword Succeeds    30s    10s    Verify Tunnel Status as UP

*** Keywords ***
Delete Tunnel
    [Documentation]    this test case delete a tunnel interface and verify deletion on OVS.
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    Switch Connection    ${conn_id_1}
    ${tunnel}    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    Log    ${tunnel}
    ${before_delete}    Execute Command    sudo ovs-vsctl show
    log    ${before_delete}
    Execute Command    sudo ovs-vsctl del-port ${tunnel}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
    Should Not Contain    ${return}    ${tunnel}
