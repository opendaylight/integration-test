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
Resource          ../../variables/netvirt/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${OFT_TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan
${DEFAULT_SUBNET}    255.255.255.255/32
${DEFAULT_VLAN}    ${NO_VLAN}

*** Test Cases ***
Create and Verify OFT TEPs
    [Documentation]    Creates TEPs set to use OF based Tunnels and verifies.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify OFT TEPs
    [Documentation]    Deletes TEPs set to use OF based Tunnels and verifies.
    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Delete Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Deleted    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Create and Verify single OFT TEPs
    [Documentation]    Creates single TEPs set to use OF based Tunnels and verifies.
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ips}    -1
    ${dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}
    Collections.Remove From List    ${dpn_ids}    -1
    OFT Create Vteps using Auto Tunnels    @{tools_ips}
    OFT Verify Vteps Created    ${dpn_ids}    ${tools_ips}
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[-1]
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify single OFT TEPs
    [Documentation]    Deletes single TEPs set to use OF based Tunnels and verifies.
    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}
    ${deleted_tools_ip_list} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}[0]
    OFT Delete Vteps using Auto Tunnels    @{deleted_tools_ip_list}
    ${deleted_dpn_id_list} =    BuiltIn.CreateList    @{DPN_ID_LIST}[0]
    OFT Verify Vteps Deleted    ${deleted_dpn_id_list}    ${deleted_tools_ip_list}

Verify OFT supports only Selective BFD
    [Documentation]    Verifies that only Selective BFD monitoring can be enabled for OF based Tunnels
    Utils.Add Elements To URI And Verify    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${ENABLE_MONITORING}

Verify Reference Count with Selective BFD
    [Documentation]    Verifies if Reference Count is increased accordingly for Selective BFD monitoring.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}[0]
    OFT Set BFD State    ${DPN_ID_LIST}    true
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State    ${DPN_ID_LIST}    true
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Reference Count    ${DPN_ID_LIST}    1
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify P2P Created    ${DPN_ID_LIST}    ${DPN_ID_LIST}

Verify Tunnel State with BFD Enabled and Interface State Down
    [Documentation]    Verifies Tunnel state with BFD Enabled and Interface state as Down.
    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    OFT Verify BFD State    ${DPN_ID_LIST}    true
    ${tools_ip_list} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ip_list}    0
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    OVSDB.Stop OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify No Tunnel Status As Up

Verify Tunnel State with BFD Enabled and Interface State Up
    [Documentation]    Verifies Tunnel state with BFD Enabled and Interface state as Up.
    BuiltIn.Comment    Preconditions are unclear.
    ${tools_ip_list} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ip_list}    0
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    OVSDB.Start OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}

Delete and Verify OFT TEPs with Non-Zero Reference Count
    [Documentation]    Verifies that OFT TEPs can be deleted even if the Reference Count is Non-Zero.
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State    ${DPN_ID_LIST}    true
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Reference Count    ${DPN_ID_LIST}    0    \>
    ${deleted_tools_ip_list} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}[0]
    OFT Delete Vteps using Auto Tunnels    @{deleted_tools_ip_list}
    ${deleted_dpn_id_list} =    BuiltIn.CreateList    @{DPN_ID_LIST}[0]
    OFT Verify Vteps Deleted    ${deleted_dpn_id_list}    ${deleted_tools_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify P2P Deleted    ${deleted_dpn_id_list}    ${DPN_ID_LIST}

Verify Reference Count with BFD disable RPC
    [Documentation]    Verifies that Reference Count decreases accordingly when BFD disable RPC is called.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    @{TOOLS_SYSTEM_ALL_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State    ${DPN_ID_LIST}    true
    OFT Set BFD State    ${DPN_ID_LIST}    false
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify BFD State    ${DPN_ID_LIST}    false
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Reference Count    ${DPN_ID_LIST}    0

Verify Interface State with BFD Disabled
    [Documentation]    Verifies that Tunnel State remains same even after toggling of interface state once BFD is Disabled.
    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    OFT Verify BFD State    ${DPN_ID_LIST}    false
    OFT Verify Reference Count    ${DPN_ID_LIST}    0
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    OVSDB.Stop OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    OVSDB.Start OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}

*** Keywords ***
OFT Create Vteps using Auto Tunnels
    [Arguments]    @{tools_ip_list}
    [Documentation]    Creates VTEPs for selected tools systems in ODL using Auto Tunnels.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl set O . external_ids:of-tunnel=true
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    ${SET_LOCAL_IP}${tools_ip}

OFT Verify Vteps Created
    [Arguments]    ${dpn_id_list}    ${tools_ip_list}
    [Documentation]    Verifies if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    ${switch_data} =    BuiltIn.Create List    @{dpn_id_list}    @{tools_ip_list}
    ${num_switches} =    BuiltIn.Get Length    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Get ITM    ${DEFAULT_TRANSPORT_ZONE}    ${DEFAULT_SUBNET}    ${DEFAULT_VLAN}
    ...    ${switch_data}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Created at Tep Show    ${dpn_id_list}    ${tools_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Update Dpn id List And Get Tunnels    ${OFT_TUNNEL_TYPE}    dpn-teps-state    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Response Code Of Dpn End Point Config API    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${num_switches}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${tools_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Created    ${tools_ip_list}
    BuiltIn.Comment    TODO: Check egress flows (table 95)

OFT Verify Vteps Created at Tep Show
    [Arguments]    ${dpn_ids}    ${tools_ip_list}
    [Documentation]    Verifies if vteps are created at tep:show in ODL for selected tools systems.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${output}    ${DEFAULT_TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${output}    VXLAN
    ${len} =    BuiltIn.Get Length    ${dpn_ids}
    : FOR    ${num}    IN RANGE    ${len}
    \    BuiltIn.Should Contain    ${output}    @{dpn_ids}[${num}]
    \    BuiltIn.Should Contain    ${output}    @{tools_ip_list}[${num}]

OFT OVS Verify Tunnels Created
    [Arguments]    ${tools_ip_list}
    [Documentation]    Verifies if tunnels are created in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    \    BuiltIn.Should Contain X Times    ${output}    remote_ip=flow    ${1}

OFT OVS Verify Ingress Flows Created per Switch
    [Arguments]    ${tools_ip}    ${other_tools_ip_list}
    [Documentation]    Verifies if Ingress flow rules are created in OVS for selected tools systems per switch.
    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    : FOR    ${other_tools_ip}    IN    @{other_tools_ip_list}
    \    BuiltIn.Should Contain    ${output}    tun_src=${other_tools_ip}
    \    ${output2} =    Utils.Run Command On Remote System And Log    ${other_tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    \    BuiltIn.Should Contain    ${output2}    tun_src=${tools_ip}

OFT OVS Verify Ingress Flows Created
    [Arguments]    ${tools_ip_list}
    [Documentation]    Verifies if Ingress flow rules are created in OVS for selected tools systems per switch.
    ${len} =    BuiltIn.Get Length    ${tools_ip_list}
    : FOR    ${num}    IN RANGE    ${len}
    \    ${other_tools_ip_list} =    BuiltIn.CreateList    @{tools_ip_list}
    \    Collections.Remove From List    ${other_tools_ip_list}    ${num}
    \    OFT Ovs Verify Flow Deleted Per Tools IP    @{tools_ip_list}[${num}]    ${other_tools_ip_list}

OFT Delete Vteps using Auto Tunnels
    [Arguments]    @{tools_ip_list}
    [Documentation]    Deletes VTEPs for selected tools systems in ODL using Auto Tunnel.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    ${REMOVE_LOCAL_IP}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl set O . external_ids:of-tunnel=false

OFT Verify Vteps Deleted
    [Arguments]    ${dpn_id_list}    ${tools_ip_list}
    [Documentation]    Verifies if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Tep Show    ${tools_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Tep Show State    ${tools_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Endpoints    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Teps State    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Tunnels State    ${tools_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Deleted    @{tools_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Deleted    ${tools_ip_list}
    BuiltIn.Comment    TODO: Check egress flows (table 95)

OFT Verify Vteps Deleted at Tep Show
    [Arguments]    ${tools_ip_list}
    [Documentation]    Verifies if vteps are deleted at tep:show for selected tools systems in ODL.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    : FOR    ${tools_ip}    IN    ${tools_ip_list}
    \    BuiltIn.Should Not Contain    ${output}    ${tools_ip}

OFT Verify Vteps Deleted at Dpn Teps State per Interface
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}
    [Documentation]    Verifies if vteps are deleted for given dpn pair at dpn-teps-state for selected tools systems in ODL per interface.
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    ${status} =    BuiltIn.Run Keyword And Return Status    Genius.Get Tunnel    ${src_dpn_id}    ${dst_dpn_id}    ${OFT_TUNNEL_TYPE}
    \    ...    dpn-teps-state
    \    BuiltIn.Should Be True    ${status} == ${False}
    \    ${status} =    BuiltIn.Run Keyword And Return Status    Genius.Get Tunnel    ${dst_dpn_id}    ${src_dpn_id}    ${OFT_TUNNEL_TYPE}
    \    ...    dpn-teps-state
    \    BuiltIn.Should Be True    ${status} == ${False}

OFT Verify Vteps Deleted at Dpn Teps State
    [Arguments]    ${src_dpn_id_list}    ${dst_dpn_id_list}
    [Documentation]    Verifies if vteps are deleted for given dpn pair at dpn-teps-state for selected tools systems in ODL.
    : FOR    ${src_dpn_id}    IN    @{src_dpn_id_list}
    \    OFT Verify Vteps Deleted at Dpn Teps State per Interface    ${src_dpn_id}    ${dst_dpn_id_list}

OFT Verify Vteps Deleted at Dpn Endpoints
    [Arguments]    ${dpn_id_list}
    [Documentation]    Verifies if vteps are deleted at itm-state:dpn-endpoints in ODL for selected tools systems.
    : FOR    ${dpn_id}    IN    @{dpn_id_list}
    \    Utils.No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn_id}/

OFT Verify Vteps Deleted at Tep Show State
    [Arguments]    ${tools_ip_list}
    [Documentation]    Verifies if vteps are deleted at tep:show-state in ODL for selected tools systems.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    BuiltIn.Should Not Contain    ${output}    ${tools_ip}

OFT Verify Vteps Deleted at Tunnels State
    [Arguments]    ${tools_ip_list}
    [Documentation]    Verifies if vteps are deleted at tunnels_state in ODL for selected tools systems.
    ${resp_data} =    Utils.Get Data From URI    session    ${OPERATIONAL_API}/itm-state:tunnels_state
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    BuiltIn.Should Not Contain    ${resp_data}    ${tools_ip}

OFT OVS Verify Tunnels Deleted
    [Arguments]    @{tools_ip_list}
    [Documentation]    Verifies if tunnels are deleted in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    \    BuiltIn.Should Not Contain    ${output}    remote_ip=flow

OFT OVS Verify Ingress Flows Deleted per Switch
    [Arguments]    ${tools_ip}    ${other_tools_ip_list}
    [Documentation]    Verifies if Ingress flow rules are deleted in OVS for selected tools systems per switch.
    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    : FOR    ${other_tools_ip}    IN    @{other_tools_ip_list}
    \    BuiltIn.Should Not Contain    ${output}    tun_src=${other_tools_ip}
    \    ${output2} =    Utils.Run Command On Remote System And Log    ${other_tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    \    BuiltIn.Should Not Contain    ${output2}    tun_src=${tools_ip}

OFT OVS Verify Ingress Flows Deleted
    [Arguments]    ${tools_ip_list}
    [Documentation]    Verifies if Ingress flow rules are deleted in OVS for selected tools systems.
    ${len} =    BuiltIn.Get Length    ${tools_ip_list}
    : FOR    ${num}    IN RANGE    @{len}
    \    ${other_tools_ip_list} =    BuiltIn.CreateList    ${tools_ip_list}
    \    Collections.Remove From List    ${other_tools_ip_list}    ${num}
    \    OFT OVS Verify Flows Deleted per Switch    @{tools_ip_list}[${num}]    ${other_tools_ip_list}

OFT Verify BFD State per Switch
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}    ${enable}
    [Documentation]    Verifies BFD State in ODL for selected tools systems per switch.
    ${enable} =    BuiltIn.Evaluate    str(${enable}).lower()
    ${elements} =    BuiltIn.Create List    <monitoring-enabled>${enable}</monitoring-enabled>
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    Utils.Check For Elements At URI    ${CONFIG_API}/itm-state:dpn-teps-state/dpns-teps/${src_dpn_id}/remote-dpns/${dst_dpn_id}    ${elements}

OFT Verify BFD State
    [Arguments]    ${dpn_id_list}    ${enable}
    [Documentation]    Verifies BFD State in ODL for selected tools systems.
    ${len} =    BuiltIn.Get Length    ${dpn_id_list}
    : FOR    ${num}    IN RANGE    ${len}
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{dpn_id_list}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${num}
    \    OFT Verify BFD State per Switch    @{dpn_id_list}[${num}]    ${dst_dpn_id_list}    ${enable}

OFT Set BFD State per Switch
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}    ${enable}
    [Documentation]    Sets BFD State in ODL for selected tools systems per switch.
    ${input} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${input}    monitoring-enabled=${enable}
    ${body} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${body}    input=${input}
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    Collections.Set To Dictionary    ${input}    source-node=${src_dpn_id}
    \    Collections.Set To Dictionary    ${input}    destination-node=${dst_dpn_id}
    \    ${data} =    BuiltIn.Evaluate    json.dumps(${body}, indent=4)    json
    \    Utils.Post Elements To URI    ${OPERATIONS_API}/itm-rpc:set-bfd-param-on-tunnel    data=${data}

OFT Set BFD State
    [Arguments]    ${dpn_id_list}    ${enable}
    [Documentation]    Sets BFD State in ODL for selected tools systems.
    ${len} =    BuiltIn.Get Length    ${dpn_id_list}
    : FOR    ${num}    IN RANGE    ${len}
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{dpn_id_list}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${num}
    \    OFT Set BFD State per Switch    @{dpn_id_list}[${num}]    ${dst_dpn_id_list}    ${enable}

OFT Verify No Tunnel Status As Up
    [Documentation]    Verifies that no Tunnel status is UP in ODL.
    ${result} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${result}    UP

OFT Verify Reference Count per Source
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}    ${value}    ${condition}=\=\=
    [Documentation]    Verifies the value of Reference Count in ODL for selected tools systems per source.
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    ${resp_data} =    Utils.Get Data From URI    session    ${OPERATIONAL_API}/odl-itm-meta:monitoring-ref-count/monitored-tunnels/${src_dpn_id}/${dst_dpn_id}
    \    ${matches} =    String.Get Regexp Matches    ${resp_data}    <reference-count>(\\d+)</reference-count>    1
    \    BuiltIn.Log    ${matches}
    \    BuiltIn.Length Should Be    ${matches}    1
    \    ${result} =    BuiltIn.Evaluate    ${count}${condition}${value}
    \    BuiltIn.Should Be Equal    ${result}    ${True}

OFT Verify Reference Count
    [Arguments]    ${dpn_id_list}    ${value}    ${condition}=\=\=
    [Documentation]    Verifies the value of Reference Count in ODL for selected tools systems.
    ${len} =    BuiltIn.Get Length    ${dpn_id_list}
    : FOR    ${num}    IN RANGE    ${len}
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{dpn_id_list}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${num}
    \    OFT Verify Reference Count per Source    @{dpn_id_list}[${num}]    ${dst_dpn_id_list}    ${value}    ${condition}

OFT Verify P2P Created per Source
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}
    [Documentation]    Verifies P2P is created in ODL for selected tools systems.
    ${input} =    BuiltIn.Create Dictionary
    ${body} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${body}    input=${input}
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    Collections.Set To Dictionary    ${input}    source-node=${src_dpn_id}
    \    Collections.Set To Dictionary    ${input}    destination-node=${dst_dpn_id}
    \    ${data} =    BuiltIn.Evaluate    json.dumps(${body}, indent=4)    json
    \    Utils.Post Elements To URI    ${OPERATIONS_API}/itm-rpc:get-watch-port-for-tunnel    data=${data}

OFT Verify P2P Created
    [Arguments]    ${src_dpn_id_list}    ${dst_dpn_id_list}
    [Documentation]    Verifies P2P is created in ODL for selected tools systems.
    : FOR    ${src_dpn_id}    IN    @{src_dpn_id_list}
    \    OFT Verify P2P Created per Source    ${src_dpn_id}    ${dst_dpn_id_list}

OFT Verify P2P Deleted per Source
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}
    [Documentation]    Verifies P2P is deleted in ODL for selected tools systems.
    ${input} =    BuiltIn.Create Dictionary
    ${body} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${body}    input=${input}
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    Collections.Set To Dictionary    ${input}    source-node=${src_dpn_id}
    \    Collections.Set To Dictionary    ${input}    destination-node=${dst_dpn_id}
    \    ${data} =    BuiltIn.Evaluate    json.dumps(${body}, indent=4)    json
    \    ${status} =    BuiltIn.Run Keyword And Return Status    Utils.Post Elements To URI    ${OPERATIONS_API}/itm-rpc:get-watch-port-for-tunnel    data=${data}
    \    BuiltIn.Should Be True    ${status} == ${False}

OFT Verify P2P Deleted
    [Arguments]    ${src_dpn_id_list}    ${dst_dpn_id_list}
    [Documentation]    Verifies P2P is deleted in ODL for selected tools systems.
    : FOR    ${src_dpn_id}    IN    @{src_dpn_id_list}
    \    OFT Verify P2P Deleted per Source    ${src_dpn_id}    ${dst_dpn_id_list}

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
    Genius Suite Teardown
