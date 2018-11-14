*** Settings ***
Documentation     Test Suite for Service Recovery.
...               Find detailed test plan here, http://docs.opendaylight.org/en/latest/submodules/genius/docs/testplans/service-recovery.html
Suite Setup       Genius.SRM Start Suite
Suite Teardown    Genius.SRM Stop Suite
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           re
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Test Cases ***
ITM TZ Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name.
    Delete Tunnel on OVS
    KarafKeywords.Issue Command On Karaf Console    srm:recover INSTANCE ITM-TZ TZA
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP    TZA

ITM TEP Recovery
    [Documentation]    This test case recovers the tunnels using transportzone name and tunnel's ip address.
    Delete Tunnel on OVS
    KarafKeywords.Issue Command On Karaf Console    srm:recover INSTANCE ITM-TEP TZA:${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP    TZA

ITM Service Recovery
    [Documentation]    This test case recovers ITM Service.
    ${tunnel} =    Get Tunnel name
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/interface/${tunnel}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Delete on DS    ${tunnel}
    KarafKeywords.Issue Command On Karaf Console    srm:recover SERVICE ITM
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP    TZA

IFM Instance Recovery
    [Documentation]    This test case recovers tunnel interface instance using interface name.
    ${tunnel} =    Get Tunnel name
    Delete Tunnel on OVS
    KarafKeywords.Issue Command On Karaf Console    srm:recover INSTANCE IFM-IFACE ${tunnel}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP    TZA

IFM Service Recovery
    [Documentation]    This test case recovers IFM Service.
    ${tunnel} =    Get Tunnel name
    SSHLibrary.Switch Connection    ${conn_id_1}
    ${uuid}    ${bridge} =    OVSDB.Get Bridge Data
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}uuid%2F${uuid}%2Fbridge%2F${Bridge}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Delete on DS    ${tunnel}
    KarafKeywords.Issue Command On Karaf Console    srm:recover SERVICE IFM
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP    TZA

*** Keywords ***
Delete Tunnel on OVS
    [Documentation]    Deletes a tunnel interface on switch and verify deletion on OVS.
    ${dpn_Id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_Id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel} =    Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_Id_1}    ${dpn_Id_2}
    ...    odl-interface:tunnel-type-vxlan
    SSHLibrary.Switch Connection    ${conn_id_1}
    SSHLibrary.Execute Command    sudo ovs-vsctl del-port ${tunnel}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Delete on DS    ${tunnel}

Get Tunnel name
    [Documentation]    This keyword returns tunnel interface name.
    ${dpn_id_1}=    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_id_2}=    Genius.Get Dpn Ids    ${conn_id_2}
    ${tunnel}=    BuiltIn.Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_id_1}    ${dpn_id_2}
    ...    odl-interface:tunnel-type-vxlan
    [Return]    ${tunnel}
