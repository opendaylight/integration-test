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
${DEFAULT_SUBNET}    255.255.255.255/32
${OFT_TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan

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
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Get ITM    ${DEFAULT_TRANSPORT_ZONE}    ${DEFAULT_SUBNET}    ${NO_VLAN}
    ...    ${switch_data}
    ${tep_show_output} =    BuiltIn.Wait Until Keyword Succeeds    60    5    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain Any    ${tep_show_output}    ${DEFAULT_TRANSPORT_ZONE}    VXLAN    @{switch_data}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Update Dpn id List And Get Tunnels    ${OFT_TUNNEL_TYPE}    dpn-teps-state    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Response Code Of Dpn End Point Config API    ${dpn_id_list}
    ${num_switches} =    BuiltIn.Get Length    ${dpn_id_list}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${num_switches}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    @{tools_ip_list}
    ${len} =    BuiltIn.Get Length    ${tools_ip_list}
    : FOR    ${num}    IN RANGE    ${len}
    \    ${tun_src_list} =    BuiltIn.CreateList    @{tools_ip_list}
    \    Collections.Remove From List    ${tun_src_list}    ${num}
    \    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Created per Switch    @{tools_ip_list}[${num}]    ${tun_src_list}
    BuiltIn.Comment    TODO: Check egress flows (table 95)

OFT OVS Verify Tunnels Created
    [Arguments]    @{tools_ip_list}
    [Documentation]    Verifies if tunnels are created in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    \    BuiltIn.Should Contain X Times    ${output}    remote_ip=flow    ${1}

OFT OVS Verify Ingress Flows Created per Switch
    [Arguments]    ${tools_ip}    ${tun_src_list}
    [Documentation]    Verifies if Ingress flow rules are created in OVS for a given switch.
    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    : FOR    ${tun_src}    IN    @{tun_src_list}
    \    BuiltIn.Should Contain    ${output}    tun_src=${tun_src}

OFT Delete Vteps using Auto Tunnels
    [Arguments]    @{tools_ip_list}
    [Documentation]    Deletes VTEPs for selected tools systems in ODL using Auto Tunnel.
    : FOR    ${tools_ip}    IN    @{tools_ip_list}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    ${REMOVE_LOCAL_IP}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl set O . external_ids:of-tunnel=false

OFT Verify Vteps Deleted
    [Arguments]    ${dpn_id_list}    ${tools_ip_list}
    [Documentation]    Verifies if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    ${len} =    BuiltIn.Set Variable    ${dpn_id_list}
    ${tep_show_output} =    BuiltIn.Wait Until Keyword Succeeds    60    5    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    ${tep_show_state_output} =    BuiltIn.Wait Until Keyword Succeeds    60    5    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    ${tunne_state_resp_data} =    BuiltIn.Wait Until Keyword Succeeds    60    5    Utils.Get Data From URI    session    ${OPERATIONAL_API}/itm-state:tunnels_state
    : FOR    ${num}    IN RANGE    ${len}
    \    BuiltIn.Should Not Contain    ${tep_show_output}    @{tools_ip_list}[${num}]
    \    BuiltIn.Should Not Contain    ${tep_show_state_output}    @{tools_ip_list}[${num}]
    \    BuiltIn.Should Not Contain    ${tunne_state_resp_data}    @{tools_ip_list}[${num}]
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    Utils.No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/@{dpn_id_list}[${num}]/
    \    ${dst_dpn_id_list} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove From List    ${dst_dpn_id_list}    ${num}
    \    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Teps State per Interface    @{dpn_id_list}[${num}]    ${dst_dpn_id_list}
    \    ${ovs_vsctl_output} =    BuiltIn.Wait Until Keyword Succeeds    40    10    Utils.Run Command On Remote System And Log    @{tools_ip_list}[${num}]
    \    ...    sudo ovs-vsctl show
    \    BuiltIn.Should Not Contain    ${ovs_vsctl_output}    remote_ip=flow
    \    ${tun_src_list} =    BuiltIn.CreateList    @{tools_ip_list}
    \    Collections.Remove From List    ${tun_src_list}    ${num}
    \    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Deleted per Switch    @{tools_ip_list}[${num}]    ${tun_src_list}
    BuiltIn.Comment    TODO: Check egress flows (table 95)

OFT Verify Vteps Deleted at Dpn Teps State per Interface
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}
    [Documentation]    Verifies if vteps are deleted for all src-dst intf pair at dpn-teps-state in ODL for a given src intf.
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    \    ${status} =    BuiltIn.Run Keyword And Return Status    Genius.Get Tunnel    ${src_dpn_id}    ${dst_dpn_id}    ${OFT_TUNNEL_TYPE}
    \    ...    dpn-teps-state
    \    BuiltIn.Should Be True    ${status} == ${False}

OFT OVS Verify Ingress Flows Deleted per Switch
    [Arguments]    ${tools_ip}    ${other_tools_ip_list}
    [Documentation]    Verifies if Ingress flow rules are deleted in OVS for a given switch.
    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    : FOR    ${other_tools_ip}    IN    @{other_tools_ip_list}
    \    BuiltIn.Should Not Contain    ${output}    tun_src=${other_tools_ip}

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
