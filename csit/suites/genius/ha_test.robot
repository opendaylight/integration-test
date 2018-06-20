*** Settings ***
Suite Setup       Start Suite for ha
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/Genius.robot

*** Variables ***
${bridgename}     BR1
${interface_name}    l2vlan-trunk

*** Test Cases ***
Take Down ODL1
    Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    ps -ef | grep karaf
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    1
    BuiltIn.Set Suite Variable    ${new_cluster_list}
    Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    ps -ef | grep karaf
    Verify OVS Configuration

Bring Up ODL1
    ClusterManagement.Start Single Member    1
    Verify OVS Configuration

Delete VTEP and Verify
    Delete VTEP
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}

Delete Interface
    Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/
    No Content From URI    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/
    Wait Until Keyword Succeeds    30    10    no table0 entry

*** Keywords ***
Start Suite for ha
    ClusterManagement.ClusterManagement Setup
    ${conn_id_1}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Set Global Variable    ${conn_id_1}
    ${check}    Wait Until Keyword Succeeds    30    10    check establishment    ${conn_id_1}    6633
    ${conn_id_2}=    Open Connection    ${TOOLS_SYSTEM_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Set Global Variable    ${conn_id_2}
    ${check}    Wait Until Keyword Succeeds    30    10    check establishment    ${conn_id_2}    6633
    : FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM }
    \    Create Bridge    ${TOOLS_SYSTEM_${i}_IP}    BR${i}
    Create VTEP and Verify
    Create Interfaces and Verify

Create Bridge
    [Arguments]    ${ovs_ip}    ${bridge}
    Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl add-br ${bridge}
    : FOR    ${i}    IN RANGE    1    ${NUM_ODL_SYSTEM}+1
    \    Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl set-controller ${bridge} tcp:${ODL_SYSTEM_${i}_IP}:${ODL_OF_PORT_6653}

Create VTEP and Verify
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    Genius.Verify Tunnel Status as UP    TZA

Create IETF Interface
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/${json_file}
    log    ${genius_config_dir}/${json_file}
    ${body}    replace string    ${body}    "l2vlan-mode":"trunk"    "l2vlan-mode":"${interface_mode}"
    log    "l2vlan-mode":"${interface_mode}"
    log    ${body}
    ${post_resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    Log    ${post_resp.content}
    Log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204

Create Interfaces and Verify
    Create IETF Interface
    Verify IETF Interfaces

Verify IETF Interfaces
    Wait Until Keyword Succeeds    50    5    get operational interface    ${interface_name}
    Wait Until Keyword Succeeds    40    10    table0 entry    ${conn_id_1}    ${bridgename}

get operational interface
    [Arguments]    ${interface_name}
    ${get_oper_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${interface_name}/
    ${respjson}    RequestsLibrary.To Json    ${get_oper_resp.content}    pretty_print=True
    log    ${respjson}
    log    ${get_oper_resp.status_code}
    Should Be Equal As Strings    ${get_oper_resp.status_code}    200
    Should not contain    ${get_oper_resp.content}    down
    Should Contain    ${get_oper_resp.content}    up    up

table0 entry
    [Arguments]    ${connection-id}    ${bridgename}
    switch connection    ${connection-id}
    log    switch connection
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should contain    ${ovs-check}    table=0

notable0 entry
    switch connection    ${conn_id_1}
    ${bridgename}    Set Variable    BR1
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should not contain    ${ovs-check}    table=0
    should not contain    ${ovs-check}    goto_table:17

Delete VTEP
    ${Dpn_id_1}    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Genius.Get Dpn Ids    ${conn_id_2}
    ${type}    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}    ${type}
    ${tunnel-2}    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}    ${type}
    Should Not Contain    ${resp}    ${tunnel-1}    ${tunnel-2}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/

Verify OVS Configuration
    Genius.Verify Tunnel Status as UP    TZA
    Verify IETF Interfaces
