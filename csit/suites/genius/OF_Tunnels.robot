*** Settings ***
Documentation     This test suite is to verify working of OF based Tunnels
Suite Setup       OF Tunnels Start Suite
Suite Teardown    OF Tunnels Stop Suite
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/ODLTools.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py
Resource          ../../variables/netvirt/Variables.robot

*** Variables ***
${FLOWS_FILTER_TABLE0}    | grep table=0
${FLOWS_FILTER_TABLE95}    | grep table=95

*** Test Cases ***
Create and Verify OFT TEPs
    [Documentation]    Create TEPs set to use OF based Tunnels and verify.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify OFT TEPs
    [Documentation]    Delete TEPs set to use OF based Tunnels and verify.
    OFT Delete Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Deleted    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Utils.No Content From URI    session    ${OPERATIONAL_API}/itm-state:tunnels_state

Create and Verify single OFT TEPs
    [Documentation]    Create single TEPs set to use OF based Tunnels and verify.
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ips}    -1
    ${dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}
    Collections.Remove From List    ${dpn_ids}    -1
    OFT Create Vteps using Auto Tunnels    @{tools_ips}
    OFT Verify Vteps Created    ${dpn_ids}    ${tools_ips}
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[-1]
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify single OFT TEPs
    [Documentation]    Delete single TEPs set to use OF based Tunnels and verify.
    ${deleted_tools_ip_list} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}[0]
    OFT Delete Vteps using Auto Tunnels    @{deleted_tools_ip_list}
    ${deleted_dpn_id_list} =    BuiltIn.CreateList    @{DPN_ID_LIST}[0]
    OFT Verify Vteps Deleted    ${deleted_dpn_id_list}    ${deleted_tools_ip_list}

Verify OFT supports only Selective BFD
    [Documentation]    Verify that only Selective BFD monitoring can be enabled for OF based Tunnels.
    ${status} =    BuiltIn.Run Keyword And Return Status    Utils.Add Elements To URI And Verify    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${ENABLE_MONITORING}
    BuiltIn.Should Be True    ${status} == ${False}

Verify Reference Count with Selective BFD
    [Documentation]    Verify if Reference Count is increased accordingly for Selective BFD monitoring.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}[0]
    ${tools_system_len} =    BuiltIn.Get Length    ${DPN_ID_LIST}
    : FOR    ${tools_system_index}    IN RANGE    ${tools_system_len}
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${tools_system_index}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Set BFD State per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${True}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${True}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Reference Count per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    1
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify P2P per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${True}

Verify Tunnel State with BFD Enabled and Interface State Down
    [Documentation]    Verify Tunnel state with BFD Enabled and Interface state as Down.
    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}
    ${tools_system_len} =    BuiltIn.Get Length    ${DPN_ID_LIST}
    : FOR    ${tools_system_index}    IN RANGE    ${tools_system_len}
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${tools_system_index}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${True}
    ${tools_ip_list} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ip_list}    0
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    OVSDB.Stop OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    0

Verify Tunnel State with BFD Enabled and Interface State Up
    [Documentation]    Verify Tunnel state with BFD Enabled and Interface state as Up.
    BuiltIn.Comment    Preconditions are unclear.
    ${tools_ip_list} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ip_list}    0
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    OVSDB.Start OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}

Delete and Verify OFT TEPs with Non-Zero Reference Count
    [Documentation]    Verify that OFT TEPs can be deleted even if the Reference Count is Non-Zero.
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}
    ${tools_system_len} =    BuiltIn.Get Length    ${DPN_ID_LIST}
    : FOR    ${tools_system_index}    IN RANGE    ${tools_system_len}
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${tools_system_index}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${True}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Reference Count per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    0    \>
    ${deleted_tools_ip_list} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}[0]
    OFT Delete Vteps using Auto Tunnels    @{deleted_tools_ip_list}
    ${deleted_dpn_id_list} =    BuiltIn.CreateList    @{DPN_ID_LIST}[0]
    OFT Verify Vteps Deleted    ${deleted_dpn_id_list}    ${deleted_tools_ip_list}
    : FOR    ${src_dpn_id}    IN    @{deleted_dpn_id_list}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify P2P per Switch    ${src_dpn_id}    ${DPN_ID_LIST}
    \    ...    ${False}

Verify Reference Count with BFD disable RPC
    [Documentation]    Verify that Reference Count decreases accordingly when BFD disable RPC is called.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}[0]
    ${tools_system_len} =    BuiltIn.Get Length    ${DPN_ID_LIST}
    : FOR    ${tools_system_index}    IN RANGE    ${tools_system_len}
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${tools_system_index}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${True}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Set BFD State per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${False}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${False}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Reference Count per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    0

Verify Interface State with BFD Disabled
    [Documentation]    Verify that Tunnel State remains same even after toggling of interface state once BFD is Disabled.
    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}
    ${tools_system_len} =    BuiltIn.Get Length    ${DPN_ID_LIST}
    : FOR    ${tools_system_index}    IN RANGE    ${tools_system_len}
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${tools_system_index}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    ${False}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Reference Count per Switch    @{DPN_ID_LIST}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ...    0
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    OVSDB.Stop OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    OVSDB.Start OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}

*** Keywords ***
OFT Create Vteps using Auto Tunnels
    [Arguments]    @{tools_ip_list}
    [Documentation]    Create VTEPs for selected tools systems in ODL using Auto Tunnels.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    ${SET_LOCAL_IP}${tools_ip}

OFT Verify Vteps Created
    [Arguments]    ${dpn_id_list}    ${tools_ip_list}
    [Documentation]    Verify if OFT VTEPs are created successfully or not for given Tools IPs and DPN-IDs.
    ${switch_data} =    BuiltIn.Create List    @{dpn_id_list}    @{tools_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Get ITM    ${DEFAULT_TRANSPORT_ZONE}    ${switch_data}
    ${tep_show_output} =    BuiltIn.Wait Until Keyword Succeeds    60    5    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain Any    ${tep_show_output}    ${DEFAULT_TRANSPORT_ZONE}    VXLAN    @{switch_data}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Update Dpn id List And Get Tunnels    odl-interface:tunnel-type-vxlan    dpn-teps-state    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Response Code Of Dpn End Point Config API    ${dpn_id_list}
    ${num_switches} =    BuiltIn.Get Length    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${num_switches}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    @{tools_ip_list}
    ${tools_system_len} =    BuiltIn.Get Length    ${tools_ip_list}
    : FOR    ${tools_system_index}    IN RANGE    ${tools_system_len}
    \    ${tun_ip_list} =    BuiltIn.CreateList    @{tools_ip_list}
    \    Collections.Remove From List    ${tun_ip_list}    ${tools_system_index}
    \    ${ports_output} =    Utils.Run Command On Remote System And Log    @{tools_ip_list}[${tools_system_index}]    sudo ovs-ofctl -Oopenflow13 dump-ports-desc ${Bridge}
    \    ${port_numbers} =    String.Get Regexp Matches    ${ports_output}    (\\d+).of.*    ${1}
    \    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Created per Switch    @{tools_ip_list}[${tools_system_index}]    ${tun_ip_list}
    \    ...    ${port_numbers}
    \    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Egress Flows Created per Switch    @{tools_ip_list}[${tools_system_index}]    ${tun_ip_list}
    \    ...    ${port_numbers}

OFT OVS Verify Tunnels Created
    [Arguments]    @{tools_ip_list}
    [Documentation]    Verify if tunnels are created in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    \    BuiltIn.Should Contain X Times    ${output}    local_ip="${tools_ip}", remote_ip=flow    ${1}

OFT OVS Verify Ingress Flows Created per Switch
    [Arguments]    ${tools_ip}    ${tun_src_list}    ${port_numbers}
    [Documentation]    Verify if Ingress flow rules are created in OVS for a given switch.
    ${flows_table0_output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} ${FLOWS_FILTER_TABLE0}
    BuiltIn.Should Not Contain    ${flows_table0_output}    tun_src=${tools_ip},
    : FOR    ${tun_src}    IN    @{tun_src_list}
    \    BuiltIn.Should Contain    ${flows_table0_output}    tun_src=${tun_src},
    : FOR    ${port_number}    IN    @{port_numbers}
    \    BuiltIn.Should Contain    ${flows_table0_output}    in_port=${port_number}

OFT OVS Verify Egress Flows Created per Switch
    [Arguments]    ${tools_ip}    ${tun_dst_list}    ${port_numbers}
    [Documentation]    Verify if Egress flow rules are created in OVS for a given switch.
    ${flows_table95_output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} ${FLOWS_FILTER_TABLE95}
    : FOR    ${tun_dst}    IN    @{tun_dst_list}
    \    ${tun_dst_hex} =    BuiltIn.Evaluate    hex(struct.unpack('!I',socket.inet_aton('${tun_dst}'))[0])    modules=socket,struct
    \    BuiltIn.Should Contain    ${flows_table95_output}    load:${tun_dst_hex}->NXM_NX_TUN_IPV4_DST[]
    : FOR    ${port_number}    IN    @{port_numbers}
    \    BuiltIn.Should Contain    ${flows_table95_output}    output:${port_number}

OFT Delete Vteps using Auto Tunnels
    [Arguments]    @{tools_ip_list}
    [Documentation]    Delete VTEPs for selected tools systems in ODL using Auto Tunnel.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    ${REMOVE_LOCAL_IP}

OFT Verify Vteps Deleted
    [Arguments]    ${dpn_id_list}    ${tools_ip_list}
    [Documentation]    Verify if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    ${deleted_tep_len} =    BuiltIn.Get Length    ${dpn_id_list}
    ${existing_tep_len} =    BuiltIn.Evaluate    ${NUM_TOOLS_SYSTEM}-${deleted_tep_len}
    BuiltIn.Run Keyword If    ${existing_tep_len} > 0    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${existing_tep_len}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    ${tep_show_state_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    : FOR    ${tools_system_index}    IN RANGE    ${deleted_tep_len}
    \    ${tep_show_state_output_1} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    \    BuiltIn.Should Not Contain    ${tep_show_output}    @{tools_ip_list}[${tools_system_index}]
    \    BuiltIn.Should Not Contain    ${tep_show_state_output}    @{tools_ip_list}[${tools_system_index}]
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    Utils.No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/@{dpn_id_list}[${tools_system_index}]/
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${tools_system_index}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Teps State per Interface    @{dpn_id_list}[${tools_system_index}]    ${dst_dpn_id_list}
    \    ${ovs_vsctl_output} =    BuiltIn.Wait Until Keyword Succeeds    40    10    Utils.Run Command On Remote System And Log    @{tools_ip_list}[${tools_system_index}]
    \    ...    sudo ovs-vsctl show
    \    BuiltIn.Should Not Contain    ${ovs_vsctl_output}    remote_ip=flow
    \    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Deleted per Switch    @{tools_ip_list}[${tools_system_index}]
    \    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Egress Flows Deleted per Switch    @{tools_ip_list}[${tools_system_index}]

OFT Verify Vteps Deleted at Dpn Teps State per Interface
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}
    [Documentation]    Verify if vteps are deleted for all src-dst intf pair at dpn-teps-state in ODL for a given src intf.
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    ${status} =    BuiltIn.Run Keyword And Return Status    Genius.Get Tunnel    ${src_dpn_id}    ${dst_dpn_id}    odl-interface:tunnel-type-vxlan
    \    ...    dpn-teps-state
    \    BuiltIn.Should Be True    ${status} == ${False}

OFT OVS Verify Ingress Flows Deleted per Switch
    [Arguments]    ${tools_ip}
    [Documentation]    Verify if Ingress flow rules are deleted in OVS for a given switch.
    ${flows_table0_output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} ${FLOWS_FILTER_TABLE0}
    BuiltIn.Should Not Contain    ${flows_table0_output}    tun_src=

OFT OVS Verify Egress Flows Deleted per Switch
    [Arguments]    ${tools_ip}
    [Documentation]    Verify if Egress flow rules are deleted in OVS for a given switch.
    ${flows_table95_output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} ${FLOWS_FILTER_TABLE95}
    BuiltIn.Should Not Contain    ${flows_table95_output}    output:

OFT Verify BFD State per Switch
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}    ${is_enabled}
    [Documentation]    Verify BFD State in ODL for all src-dst dpn pair for a given switch.
    ${is_enabled} =    BuiltIn.Evaluate    str(${is_enabled}).lower()
    ${elements} =    BuiltIn.Create List    "monitoring-enabled":${is_enabled}
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    Utils.Check For Elements At URI    ${CONFIG_API}/itm-state:dpn-teps-state/dpns-teps/${src_dpn_id}/remote-dpns/${dst_dpn_id}    ${elements}

OFT Set BFD State per Switch
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}    ${enable}
    [Documentation]    Set BFD State in ODL for all src-dst dpn pair for a given switch.
    ${input} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${input}    monitoring-enabled=${enable}
    ${body} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${body}    input=${input}
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    Collections.Set To Dictionary    ${input}    source-node=${src_dpn_id}
    \    Collections.Set To Dictionary    ${input}    destination-node=${dst_dpn_id}
    \    ${data} =    BuiltIn.Evaluate    json.dumps(${body}, indent=4)    json
    \    Utils.Post Elements To URI    ${OPERATIONS_API}/itm-rpc:set-bfd-param-on-tunnel    data=${data}

OFT Verify Reference Count per Switch
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}    ${value}    ${condition}=\=\=
    [Documentation]    Verify Reference Count in ODL for all src-dst dpn pair for a given switch.
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    ${resp_data} =    Utils.Get Data From URI    session    ${OPERATIONAL_API}/odl-itm-meta:monitoring-ref-count/monitored-tunnels/${src_dpn_id}/${dst_dpn_id}
    \    ${matches} =    String.Get Regexp Matches    ${resp_data}    <reference-count>(\\d+)</reference-count>    1
    \    BuiltIn.Log    ${matches}
    \    BuiltIn.Length Should Be    ${matches}    1
    \    ${result} =    BuiltIn.Evaluate    ${count}${condition}${value}
    \    BuiltIn.Should Be Equal    ${result}    ${True}

OFT Verify P2P per Switch
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}    ${is_created}
    [Documentation]    Verify that P2P is created or deleted in ODL for all src-dst dpn pair for a given switch.
    ${input} =    BuiltIn.Create Dictionary
    ${body} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${body}    input=${input}
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    Collections.Set To Dictionary    ${input}    source-node=${src_dpn_id}
    \    Collections.Set To Dictionary    ${input}    destination-node=${dst_dpn_id}
    \    ${data} =    BuiltIn.Evaluate    json.dumps(${body}, indent=4)    json
    \    ${status} =    BuiltIn.Run Keyword And Return Status    Utils.Post Elements To URI    ${OPERATIONS_API}/itm-rpc:get-watch-port-for-tunnel    data=${data}
    \    BuiltIn.Should Be True    ${status} == ${is_created}

OF Tunnels Start Suite
    [Documentation]    Start suite for OF Tunnels.
    ClusterManagement.ClusterManagement_Setup
    ClusterManagement.Stop_Members_From_List_Or_All
    : FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<itm-direct-tunnels>false/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<use-of-tunnels>false/<use-of-tunnels>true/g' ${GENIUS_ITM_CONFIG_FLAG}
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Setup

OF Tunnels Stop Suite
    [Documentation]    Stop suite for OF Tunnels.
    : FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<itm-direct-tunnels>true/<itm-direct-tunnels>false/g' ${GENIUS_IFM_CONFIG_FLAG}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<use-of-tunnels>true/<use-of-tunnels>false/g' ${GENIUS_ITM_CONFIG_FLAG}
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Teardown
