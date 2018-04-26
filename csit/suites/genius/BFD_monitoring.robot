*** Settings ***
Documentation     Test Suite for BFD tunnel monitoring
Suite Setup       Genius Suite Setup
Suite Teardown    BFD Suite Stop
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

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../../variables/genius
${Bridge-1}       BR1
${Bridge-2}       BR2
${TEP_SHOW}       tep:show
${TEP_SHOW_STATE}    tep:show-state
${TUNNEL_MONITOR_ON}    Tunnel Monitoring (for VXLAN tunnels): On
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
${TUNNEL_MONITOR_OFF}    Tunnel Monitoring (for VXLAN tunnels): Off
${INTERVAL_5000}    {"tunnel-monitor-interval":{"interval":5000}}
${OK_201}         201
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
BFD_TC00 Create ITM between DPNs Verify_BFD_Enablement
    [Documentation]    Create ITM between DPNs Verify_BFD_Enablement
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    30s    5s    Genius.Verify Tunnel Status as UP

BFD_TC01 Verify by default BFD monitoring is enabled on Controller
    [Documentation]    Verify by default BFD monitoring is enabled on Controller
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Is On
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC02 Verify that BFD tunnel monitoring interval is set with appropriate default value i.e.,1000
    [Documentation]    This will verify BFD tunnel monitoring default interval
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Should Contain    ${output}    ${DEFAULT_MONITORING_INTERVAL}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC04 Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    [Documentation]    Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Is On
    Wait Until Keyword Succeeds    10s    1s    Genius.Verify Tunnel Status as UP
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC05 Verify BFD tunnel monitoring interval can be changed.
    [Documentation]    Verify BFD tunnel monitoring interval can be changed.
    ${oper_int}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    ${oper_int}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-interval/    data=${INTERVAL_5000}
    ${Bfd_updated_value}=    Create List    5000
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At Uri    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/    ${Bfd_updated_value}
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At Uri    ${CONFIG_API}/itm-config:tunnel-monitor-interval/    ${Bfd_updated_value}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-port ${Bridge-1} tap8ed70586-6c
    ${ovs_1}    Execute Command    sudo ovs-vsctl show
    log    ${ovs_1}
    ${tun_name}    Wait Until Keyword Succeeds    20    5    Ovs Tunnel Get    ${Bridge-1}
    Wait Until Keyword Succeeds    20s    5    OVSDB.Verify Ovs-vsctl Output    list interface ${tun_name}    5000    ovs_system=${TOOLS_SYSTEM_IP}
    SSHLibrary.Switch Connection    ${conn_id_2}
    ${ovs_2}    Execute Command    sudo ovs-vsctl show
    ${tun_name}    Wait Until Keyword Succeeds    20    5    Ovs Tunnel Get    ${Bridge-2}
    Wait Until Keyword Succeeds    20s    5    OVSDB.Verify Ovs-vsctl Output    list interface ${tun_name}    5000    ovs_system=${TOOLS_SYSTEM_2_IP}

BFD_TC06 Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    [Documentation]    Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    Issue Command On Karaf Console    ${TEP_SHOW}
    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-controller BR1
    SSHLibrary.Switch Connection    ${conn_id_2}
    Execute Command    sudo ovs-vsctl del-controller BR2
    Issue Command On Karaf Console    ${TEP_SHOW}
    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status as UNKNOWN
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl set-controller BR1 tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}
    SSHLibrary.Switch Connection    ${conn_id_2}
    Execute Command    sudo ovs-vsctl set-controller BR2 tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}
    Log    "After connecting CSS with controller"
    Issue Command On Karaf Console    ${TEP_SHOW}
    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Wait Until Keyword Succeeds    10s    1s    Genius.Verify Tunnel Status as UP
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}

BFD_TC07 Verify that BFD monitoring is disabled on Controller
    [Documentation]    Verify that BFD monitoring is disabled on Controller
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${DISABLE_MONITORING}
    Should Be Equal As Strings    ${resp.status_code}    201
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Params    ${TUNNEL_MONI_PARAMS_FALSE}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Should Contain    ${output}    ${TUNNEL_MONITOR_OFF}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_FALSE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    Wait Until Keyword Succeeds    10s    1s    Genius.Verify Tunnel Status as UP
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${ENABLE_MONITORING}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Params    ${TUNNEL_MONI_PARAMS_TRUE}
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Is On
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}

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
    [Arguments]    ${bridge}
    log    sudo ovs-vsctl list-ports ${bridge}
    ${tun_name}    Execute Command    sudo ovs-vsctl list-ports ${bridge}
    log    ${tun_name}
    Should Not Be Empty    ${tun_name}
    [Return]    ${tun_name}

Verify Tunnel Monitoring Params
    [Arguments]    ${flag}
    @{checklist}    create list    ${flag}
    Check For Elements At URI    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/    ${checklist}
