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
${TEP_SHOW_OF_PORTS}    tep:show-ofports

*** Test Cases ***
Create and Verify OFT TEPs
    [Documentation]    Create TEPs set to use OF based Tunnels and verify.
    CompareStream.Run_Keyword_If_Less_Than_Sodium    BuiltIn.Pass Execution    Test case valid only for versions Sodium and above
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify OFT TEPs
    [Documentation]    Delete TEPs set to use OF based Tunnels and verify.
    CompareStream.Run_Keyword_If_Less_Than_Sodium    BuiltIn.Pass Execution    Test case valid only for versions Sodium and above
    OFT Delete Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Deleted    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Utils.No Content From URI    session    ${OPERATIONAL_API}/itm-state:tunnels_state

Create and Verify single OFT TEPs
    [Documentation]    Create single TEPs set to use OF based Tunnels and verify.
    CompareStream.Run_Keyword_If_Less_Than_Sodium    BuiltIn.Pass Execution    Test case valid only for versions Sodium and above
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ips}    -1
    ${dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}
    Collections.Remove From List    ${dpn_ids}    -1
    OFT Create Vteps using Auto Tunnels    @{tools_ips}
    OFT Verify Vteps Created    ${dpn_ids}    ${tools_ips}
    OFT Create Vteps using Auto Tunnels    ${TOOLS_SYSTEM_ALL_IPS}[-1]
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify single OFT TEPs
    [Documentation]    Delete single TEPs set to use OF based Tunnels and verify.
    CompareStream.Run_Keyword_If_Less_Than_Sodium    BuiltIn.Pass Execution    Test case valid only for versions Sodium and above
    ${deleted_tools_ip_list} =    BuiltIn.Set Variable    ${TOOLS_SYSTEM_ALL_IPS}[0]
    OFT Delete Vteps using Auto Tunnels    ${deleted_tools_ip_list}
    ${deleted_tools_ip_list} =    BuiltIn.CreateList    ${TOOLS_SYSTEM_ALL_IPS}[0]
    ${deleted_dpn_id_list} =    BuiltIn.CreateList    ${DPN_ID_LIST}[0]
    OFT Verify Vteps Deleted    ${deleted_dpn_id_list}    ${deleted_tools_ip_list}

*** Keywords ***
OFT Create Vteps using Auto Tunnels
    [Arguments]    @{tools_ip_list}
    [Documentation]    Create VTEPs for selected tools systems in ODL using Auto Tunnels.
    FOR    ${tools_ip}    IN    @{tools_ip_list}
    Utils.Run Command On Remote System And Log    ${tools_ip}    ${SET_LOCAL_IP}${tools_ip}
    END

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
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Tunnel Status as UP    ${num_switches}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    @{tools_ip_list}
    ${tools_system_len} =    BuiltIn.Get Length    ${tools_ip_list}
    FOR    ${tools_system_index}    IN RANGE    ${tools_system_len}
    ${tun_ip_list} =    BuiltIn.CreateList    @{tools_ip_list}
    Collections.Remove From List    ${tun_ip_list}    ${tools_system_index}
    ${ports_output} =    Utils.Run Command On Remote System And Log    ${tools_ip_list}[${tools_system_index}]    sudo ovs-ofctl -Oopenflow13 dump-ports-desc ${Bridge}
    ${port_numbers} =    String.Get Regexp Matches    ${ports_output}    (\\d+).of.*    ${1}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Created per Switch    ${tools_ip_list}[${tools_system_index}]    ${tun_ip_list}    ${port_numbers}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Egress Flows Created per Switch    ${tools_ip_list}[${tools_system_index}]    ${tun_ip_list}    ${port_numbers}
    END

OFT OVS Verify Tunnels Created
    [Arguments]    @{tools_ip_list}
    [Documentation]    Verify if tunnels are created in OVS for selected tools systems.
    FOR    ${tools_ip}    IN    @{tools_ip_list}
    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    BuiltIn.Should Contain X Times    ${output}    local_ip="${tools_ip}", remote_ip=flow    ${1}
    END

OFT OVS Verify Ingress Flows Created per Switch
    [Arguments]    ${tools_ip}    ${tun_src_list}    ${port_numbers}
    [Documentation]    Verify if Ingress flow rules are created in OVS for a given switch.
    ${flows_table0_output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} ${FLOWS_FILTER_TABLE0}
    BuiltIn.Should Not Contain    ${flows_table0_output}    tun_src=${tools_ip},
    FOR    ${tun_src}    IN    @{tun_src_list}
    BuiltIn.Should Contain    ${flows_table0_output}    tun_src=${tun_src},
    END
    FOR    ${port_number}    IN    @{port_numbers}
    BuiltIn.Should Contain    ${flows_table0_output}    in_port=${port_number}
    END

OFT OVS Verify Egress Flows Created per Switch
    [Arguments]    ${tools_ip}    ${tun_dst_list}    ${port_numbers}
    [Documentation]    Verify if Egress flow rules are created in OVS for a given switch.
    ${flows_table95_output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} ${FLOWS_FILTER_TABLE95}
    FOR    ${tun_dst}    IN    @{tun_dst_list}
    ${tun_dst_hex} =    BuiltIn.Evaluate    hex(struct.unpack('!I',socket.inet_aton('${tun_dst}'))[0])    modules=socket,struct
    BuiltIn.Should Contain    ${flows_table95_output}    load:${tun_dst_hex}->NXM_NX_TUN_IPV4_DST[]
    END
    FOR    ${port_number}    IN    @{port_numbers}
    BuiltIn.Should Contain    ${flows_table95_output}    output:${port_number}
    END

OFT Delete Vteps using Auto Tunnels
    [Arguments]    @{tools_ip_list}
    [Documentation]    Delete VTEPs for selected tools systems in ODL using Auto Tunnel.
    FOR    ${tools_ip}    IN    @{tools_ip_list}
    Utils.Run Command On Remote System And Log    ${tools_ip}    ${REMOVE_LOCAL_IP}
    END

OFT Verify Vteps Deleted
    [Arguments]    ${dpn_id_list}    ${tools_ip_list}
    [Documentation]    Verify if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    ${deleted_tep_len} =    BuiltIn.Get Length    ${dpn_id_list}
    ${existing_tep_len} =    BuiltIn.Evaluate    ${NUM_TOOLS_SYSTEM}-${deleted_tep_len}
    BuiltIn.Run Keyword If    ${existing_tep_len} > 0    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${existing_tep_len}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    ${tep_show_state_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    FOR    ${tools_system_index}    IN RANGE    ${deleted_tep_len}
    ${tep_show_state_output_1} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${tools_ip_list}
    Log    ${tools_ip_list}[${tools_system_index}]
    BuiltIn.Should Not Contain    ${tep_show_output}    ${tools_ip_list}[${tools_system_index}]
    BuiltIn.Should Not Contain    ${tep_show_state_output}    ${tools_ip_list}[${tools_system_index}]
    BuiltIn.Wait Until Keyword Succeeds    60    5    Utils.No Content From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn_id_list}[${tools_system_index}]/
    ${dst_dpn_id_list} =    BuiltIn.Create List    @{DPN_ID_LIST}
    Collections.Remove From List    ${dst_dpn_id_list}    ${tools_system_index}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Teps State per Interface    ${dpn_id_list}[${tools_system_index}]    ${dst_dpn_id_list}
    ${ovs_vsctl_output} =    BuiltIn.Wait Until Keyword Succeeds    40    10    Utils.Run Command On Remote System And Log    ${tools_ip_list}[${tools_system_index}]    sudo ovs-vsctl show
    BuiltIn.Should Not Contain    ${ovs_vsctl_output}    remote_ip=flow
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Deleted per Switch    ${tools_ip_list}[${tools_system_index}]
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Egress Flows Deleted per Switch    ${tools_ip_list}[${tools_system_index}]
    END

OFT Verify Vteps Deleted at Dpn Teps State per Interface
    [Arguments]    ${src_dpn_id}    ${dst_dpn_id_list}
    [Documentation]    Verify if vteps are deleted for all src-dst intf pair at dpn-teps-state in ODL for a given src intf.
    FOR    ${dst_dpn_id}    IN    @{dst_dpn_id_list}
    ${status} =    BuiltIn.Run Keyword And Return Status    Genius.Get Tunnel    ${src_dpn_id}    ${dst_dpn_id}    odl-interface:tunnel-type-vxlan    dpn-teps-state
    BuiltIn.Should Be True    ${status} == ${False}
    END

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

OF Tunnels Start Suite
    [Documentation]    Start suite for OF Tunnels.
    ClusterManagement.ClusterManagement_Setup
    ClusterManagement.Stop_Members_From_List_Or_All
    FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<itm-direct-tunnels>false/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<use-of-tunnels>false/<use-of-tunnels>true/g' ${GENIUS_ITM_CONFIG_FLAG}
    END
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Setup

OF Tunnels Stop Suite
    [Documentation]    Stop suite for OF Tunnels.
    FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<itm-direct-tunnels>true/<itm-direct-tunnels>false/g' ${GENIUS_IFM_CONFIG_FLAG}
    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<use-of-tunnels>true/<use-of-tunnels>false/g' ${GENIUS_ITM_CONFIG_FLAG}
    END
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Teardown

OFT Verify Tunnel status as UP
    [Arguments]    ${no_of_switches}=${NUM_TOOLS_SYSTEM}
    ${no_of_tunnels} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_OF_PORTS}
    ${lines_of_state_up} =    String.Get Lines Containing String    ${no_of_tunnels}    ${STATE_UP}
    ${actual_tunnel_count} =    String.Get Line Count    ${lines_of_state_up}
    BuiltIn.Should Be Equal As Strings    ${actual_tunnel_count}    ${no_of_switches}
