*** Settings ***
Documentation     Test Suite for BFD tunnel monitoring
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Teardown     Get Model Dump    ${ODL_SYSTEM_IP}    ${bfd_data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Library           SSHLibrary
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/KarafKeywords.robot

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
${INTERFACE_DS_MONI_FALSE}    "odl-interface:monitor-enabled": false
${INTERFACE_DS_MONI_TRUE}    "odl-interface:monitor-enabled": true
${INTERFACE_DS_MONI_INT_1000}    "odl-interface:monitor-interval": 1000
${INTERFACE_DS_MONI_INT_5000}    "odl-interface:monitor-interval": 5000
${TUNNEL_MONI_PROTO}    tunnel-monitoring-type-bfd

*** Test Cases ***
BFD_TC00 Create ITM between DPNs Verify_BFD_Enablement
    [Documentation]    Create ITM between DPNs Verify_BFD_Enablement
    ${Dpn_id_1}    Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Get Dpn Ids    ${conn_id_2}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status as UP

BFD_TC01 Verify by default BFD monitoring is enabled on Controller
    [Documentation]    Verify by default BFD monitoring is enabled on Controller
    Verify Tunnel Monitoring Is On
    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC02 Verify that BFD tunnel monitoring interval is set with appropriate default value i.e.,1000
    [Documentation]    This will verify BFD tunnel monitoring default interval
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${DEFAULT_MONITORING_INTERVAL}
    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC04 Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    [Documentation]    Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    Verify Tunnel Monitoring Is On
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status as UP
    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC05 Verify BFD tunnel monitoring interval can be changed.
    [Documentation]    Verify BFD tunnel monitoring interval can be changed.
    Log    "Value of BFD monitoring interval before updating with new value"
    ${oper_int}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    Log    "Value of BFD monitoring interval is getting updated"
    ${oper_int}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-interval/    data=${INTERVAL_5000}
    ${oper_int}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    5000
    ${config_int}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${config_int.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    5000
    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-port BR1 tap8ed70586-6c
    ${tun_name}    Execute Command    sudo ovs-vsctl list-ports BR1
    ${BFD_int_verification}    Execute Command    sudo ovs-vsctl list interface ${tun_name}
    Should Contain    ${BFD_int_verification}    5000
    SSHLibrary.Switch Connection    ${conn_id_2}
    ${tun_name}    Execute Command    sudo ovs-vsctl list-ports BR2
    ${BFD_int_verification}    Execute Command    sudo ovs-vsctl list interface ${tun_name}
    Should Contain    ${BFD_int_verification}    5000

BFD_TC06 Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    [Documentation]    Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-controller BR1
    SSHLibrary.Switch Connection    ${conn_id_2}
    Execute Command    sudo ovs-vsctl del-controller BR2
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status as UNKNOWN
    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl set-controller BR1 tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}
    SSHLibrary.Switch Connection    ${conn_id_2}
    Execute Command    sudo ovs-vsctl set-controller BR2 tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}
    Log    "After connecting CSS with controller"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status as UP
    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}

BFD_TC07 Verify that BFD monitoring is disabled on Controller
    [Documentation]    Verify that BFD monitoring is disabled on Controller
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${DISABLE_MONITORING}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${oper}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
    Log    ${oper}
    ${respjson}    RequestsLibrary.To Json    ${oper.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    false
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_OFF}
    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_FALSE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    Log    "Verifying tunnel is UP after BFD is disabled"
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status as UP
    Log    "Enabling tunnel monitoring once again"
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${ENABLE_MONITORING}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${oper}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
    Log    ${oper}
    ${respjson}    RequestsLibrary.To Json    ${oper.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    true
    Verify Tunnel Monitoring Is On
    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}

*** Keywords ***
Verify Config Ietf Interface Output
    [Arguments]    ${state}    ${interval}    ${proto}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${state}
    Should Contain    ${respjson}    ${interval}
    Should Contain    ${respjson}    ${proto}

Verify Tunnel Monitoring Is On
    [Documentation]    This keyword will get tep:show output and verify tunnel monitoring status
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
