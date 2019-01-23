*** Settings ***
Documentation     Test Suite for BFD tunnel monitoring
Suite Setup       Genius Suite Setup
Suite Teardown    BFD Suite Teardown
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Library           SSHLibrary
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Resource          ../../libraries/CompareStream.robot

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../../variables/genius
${TEP_SHOW}       tep:show
${TEP_SHOW_STATE}    tep:show-state
${TUNNEL_MONITOR_ON}    Tunnel Monitoring (for VXLAN tunnels): On
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
${TUNNEL_MONITOR_OFF}    Tunnel Monitoring (for VXLAN tunnels): Off
${INTERVAL_5000}    {"tunnel-monitor-interval":{"interval":5000}}
${ENABLE_MONITORING}    {"tunnel-monitor-params":{"enabled":true,"monitor-protocol":"odl-interface:tunnel-monitoring-type-bfd"}}
${DISABLE_MONITORING}    {"tunnel-monitor-params":{"enabled":"false","monitor-protocol":"odl-interface:tunnel-monitoring-type-bfd"}}
${TUNNEL_MONI_PARAMS_TRUE}    true
${TUNNEL_MONI_PARAMS_FALSE}    false
${INTERFACE_DS_MONI_FALSE}    "odl-interface:monitor-enabled": false
${INTERFACE_DS_MONI_TRUE}    "odl-interface:monitor-enabled": true
${INTERFACE_DS_MONI_INT_1000}    "odl-interface:monitor-interval": 1000
${INTERFACE_DS_MONI_INT_5000}    "odl-interface:monitor-interval": 5000
${TUNNEL_MONI_PROTO}    tunnel-monitoring-type-bfd

*** Test Cases ***
BFD_TC00 Create ITM between DPNs
    [Documentation]    Create ITM between DPNs
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    30s    5s    Genius.Verify Tunnel Status as UP    TZA

BFD_TC01 Verify default BFD monitoring status on Controller
    [Documentation]    Verify the default value of BFD monitoring \ on the Controller
    ${branch} =    CompareStream.Set_Variable_If_At_Least_Neon    ATLEAST NEON    LESS THAN NEON
    ${tunnel_monitoring _status} =    BuiltIn.Set Variable If    '${branch}' == 'ATLEAST NEON'    ${TUNNEL_MONITOR_OFF}    ${TUNNEL_MONITOR_ON}
    ${interface_monitoring_status} =    BuiltIn.Set Variable If    '${branch}' == 'ATLEAST NEON'    ${INTERFACE_DS_MONI_FALSE}    ${INTERFACE_DS_MONI_TRUE}
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Status    ${tunnel_monitoring _status}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${interface_monitoring_status}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC02 Enable BFD Monitoring And Verify On Controller
    [Documentation]    Enable BFD monitoring in branches greater than neon and verify that BFD is enabled in the controller.
    ${branch} =    CompareStream.Set_Variable_If_At_Least_Neon    ATLEAST NEON    LESS THAN NEON
    BuiltIn.Run Keyword If    '${branch}' == 'ATLEAST NEON'    Enable BFD And Verify    ${INTERFACE_DS_MONI_INT_1000}
    Run_Keyword_If_At_Least_Neon    Enable BFD And Verify

BFD_TC03 Verify that BFD tunnel monitoring interval is set with appropriate default value i.e.,1000
    [Documentation]    This will verify BFD tunnel monitoring default interval
    ${output} =    Issue Command On Karaf Console    ${TEP_SHOW}
    ${tunnel_monitoring} =    Get Lines Containing String    ${output}    Tunnel Monitoring Interval
    Should Be Equal    ${tunnel_monitoring}    ${DEFAULT_MONITORING_INTERVAL}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC04 Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    [Documentation]    Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Is On
    Wait Until Keyword Succeeds    10s    1s    Genius.Verify Tunnel Status as UP    TZA
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC05 Verify BFD tunnel monitoring interval can be changed.
    [Documentation]    Verify BFD tunnel monitoring interval can be changed.
    ${oper_int}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-interval/    data=${INTERVAL_5000}
    ${Bfd_updated_value}=    Create List    5000
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At Uri    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/    ${Bfd_updated_value}
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At Uri    ${CONFIG_API}/itm-config:tunnel-monitor-interval/    ${Bfd_updated_value}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    ${tun_name}    Wait Until Keyword Succeeds    20    5    Ovs Tunnel Get    ${TOOLS_SYSTEM_1_IP}
    Wait Until Keyword Succeeds    20s    5    OVSDB.Verify Ovs-vsctl Output    list interface ${tun_name}    5000    ovs_system=${TOOLS_SYSTEM_1_IP}
    ${tun_name}    Wait Until Keyword Succeeds    20    5    Ovs Tunnel Get    ${TOOLS_SYSTEM_2_IP}
    Wait Until Keyword Succeeds    20s    5    OVSDB.Verify Ovs-vsctl Output    list interface ${tun_name}    5000    ovs_system=${TOOLS_SYSTEM_2_IP}

BFD_TC06 Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    [Documentation]    Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    Issue Command On Karaf Console    ${TEP_SHOW}
    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-controller ${Bridge}
    SSHLibrary.Switch Connection    ${conn_id_2}
    Execute Command    sudo ovs-vsctl del-controller ${Bridge}
    Issue Command On Karaf Console    ${TEP_SHOW}
    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status as UNKNOWN
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl set-controller ${Bridge} tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}
    SSHLibrary.Switch Connection    ${conn_id_2}
    Execute Command    sudo ovs-vsctl set-controller ${Bridge} tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}
    Log    "After connecting CSS with controller"
    Issue Command On Karaf Console    ${TEP_SHOW}
    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Wait Until Keyword Succeeds    10s    1s    Genius.Verify Tunnel Status as UP    TZA
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}

BFD_TC07 Set BFD monitoring To Default Value
    [Documentation]    Disable BFD monitoring(setting it to default value) and verify that BFD is disabled on the controller.
    ${branch} =    CompareStream.Set_Variable_If_At_Least_Neon    ATLEAST NEON    LESS THAN NEON
    BuiltIn.Run Keyword If    '${branch}' == 'ATLEAST NEON'    Disable BFD And Verify
    ...    ELSE    Enable BFD And Verify    ${INTERFACE_DS_MONI_INT_5000}

*** Keywords ***
Verify Config Ietf Interface Output
    [Arguments]    ${state}    ${interval}    ${proto}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${state}
    Should Contain    ${respjson}    ${interval}
    Should Contain    ${respjson}    ${proto}

Ovs Tunnel Get
    [Arguments]    ${tools_ip}
    [Documentation]    This keyword will return the tunnel name on OVS
    ${list_interface}    Utils.Run Command On Remote System    ${tools_ip}    sudo ovs-vsctl list interface
    ${tun_line}    ${tun_name}    Should Match Regexp    ${list_interface}    name\\s+: "(tun.*)"
    log    ${tun_name}
    Should Not Be Empty    ${tun_name}
    [Return]    ${tun_name}

Verify Tunnel Monitoring Params
    [Arguments]    ${flag}
    @{checklist}    create list    ${flag}
    Check For Elements At URI    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/    ${checklist}

Enable BFD And Verify
    [Arguments]    ${interface_ds_moni_int}
    [Documentation]    Enable BFD Monitoring And Verify On Controller.
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${ENABLE_MONITORING}
    Should Be Equal As Strings    ${resp.status_code}    201
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Params    ${TUNNEL_MONI_PARAMS_TRUE}
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Status    ${TUNNEL_MONITOR_ON}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${interface_ds_moni_int}    ${TUNNEL_MONI_PROTO}
    Wait Until Keyword Succeeds    20    2    Genius.Verify Tunnel Status as UP    TZA

Disable BFD And Verify
    [Documentation]    Disable BFD Monitoring And Verify On Controller.
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${DISABLE_MONITORING}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Params    ${TUNNEL_MONI_PARAMS_FALSE}
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Status    ${TUNNEL_MONITOR_OFF}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_FALSE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    Wait Until Keyword Succeeds    10s    1s    Genius.Verify Tunnel Status as UP    TZA
