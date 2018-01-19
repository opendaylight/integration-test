*** Settings ***
Documentation     Test Suite for New ITM
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Teardown     Get Model Dump    ${ODL_SYSTEM_IP}    ${new_itm_data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../variables/Variables.py
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Library           Collections
Resource          ../../libraries/Utils.robot
Library           re

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../../variables/genius
${Bridge-1}       BR1
${Bridge-2}       BR2

*** Test Cases ***
Create and Verify TunnelZone with VTEPs
    [Documentation]    This testcase creates ITM TunnelZone between 2 OVS.
    ${Ovs_Uuid_1}    Get Ovs UUIDs    ${conn_id_1}
    ${Ovs_Uuid_2}    Get Ovs UUIDs    ${conn_id_2}
    Set Global Variable    ${Ovs_Uuid_1}
    Set Global Variable    ${Ovs_Uuid_2}
    Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    Wait Until Keyword Succeeds    40    10    Get New ITM    ${itm_created[0]}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}

Delete and Verify TunnelZone with VTEPs
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 OVS.
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm-tep:tunnel-zones/tunnel-zone/${itm_created[0]}/

*** Keywords ***
Create Vteps
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/tz_creation.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${body}    set json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    Post Log Check    ${CONFIG_API}/itm-tep:tunnel-zones/    ${body}    204

Create Vteps IPv6
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:[0-9a-fA-F]{1,4}:
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    set json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}    ${subnet}
    Post Log Check    ${CONFIG_API}/itm:transport-zones/    ${body}    204

Get Ovs UUIDs
    [Arguments]    ${connection_id}
    [Documentation]    This keyword gets the UUID of the OVS and returns it after capturing it
    Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl show | awk 'NR==1{print $1}'
    ${Ovs_Uuid}    Execute command    ${cmd}
    log    ${Ovs_Uuid}
    [Return]    ${Ovs_Uuid}

Get Dpn Ids
    [Arguments]    ${connection_id}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl show | grep Bridge | awk -F "\\"" '{print $2}'
    ${Bridgename1}    Execute command    ${cmd}
    log    ${Bridgename1}
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${Bridgename1} | head -1 | awk -F "dpid:" '{ print $2 }'
    log    ${output1}
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    log    ${Dpn_id}
    [Return]    ${Dpn_id}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}
    ...    ${TOOLS_SYSTEM_2_IP}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${subnet}, ${vlan}, ${Dpn_id_1},${TOOLS_SYSTEM_IP}, ${Dpn_id_2}, ${TOOLS_SYSTEM_2_IP}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${Bridge-2}-eth1    ${TOOLS_SYSTEM_2_IP}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

set json
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/tz_creation.json
    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${TOOLS_SYSTEM_IP}"
    ${body}    replace string    ${body}    "ip-address": "3.3.3.3"    "ip-address": "${TOOLS_SYSTEM_2_IP}"
    ${body}    replace string    ${body}    "OvsUuid1"    "${Ovs_Uuid_1}"
    ${body}    replace string    ${body}    "OvsUuid1"    "${Ovs_Uuid_1}"
    ${body}    replace string    ${body}    "Bridge1"    "${Bridge-1}"
    ${body}    replace string    ${body}    "Bridge2"    "${Bridge-2}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Get New ITM
    [Arguments]    ${itm_created[0]}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${TOOLS_SYSTEM_IP}, ${TOOLS_SYSTEM_2_IP}
    @{Itm-vteps}    Create List    ${itm_created[0]}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    Check For Elements At URI    ${CONFIG_API}/itm-tep:tunnel-zones/tunnel-zone/${itm_created[0]}    ${Itm-vteps}
