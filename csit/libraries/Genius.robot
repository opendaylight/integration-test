*** Settings ***
Documentation     This suite is a common keywords file for genius project.
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           string
Resource          ClusterManagement.robot
Resource          CompareStream.robot
Resource          DataModels.robot
Resource          KarafKeywords.robot
Resource          ODLTools.robot
Resource          OVSDB.robot
Resource          ToolsSystem.robot
Resource          Utils.robot
Resource          VpnOperations.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../variables/genius
${Bridge}         ${INTEGRATION_BRIDGE}
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
@{GENIUS_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    OVSDB
${gateway_ip}     0.0.0.0
${port_name}      br-int-eth1
${VLAN}           100
${NO_VLAN}        0
${DEFAULT_TRANSPORT_ZONE}    default-transport-zone
${SET_LOCAL_IP}    sudo ovs-vsctl set O . other_config:local_ip=
${REMOVE_LOCAL_IP}    sudo ovs-vsctl remove O . other_config local_ip

*** Keywords ***
Genius Suite Setup
    [Documentation]    Create Rest Session to http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    Genius.Start Suite
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5

Genius Suite Teardown
    [Documentation]    Delete all sessions
    RequestsLibrary.Delete All Sessions
    Genius.Stop Suite

Start Suite
    [Documentation]    Initial setup for Genius test suites
    Run_Keyword_If_At_Least_Oxygen    Wait Until Keyword Succeeds    60    2    ClusterManagement.Check Status Of Services Is OPERATIONAL    @{GENIUS_DIAG_SERVICES}
    KarafKeywords.Setup_Karaf_Keywords
    ToolsSystem.Get Tools System Nodes Data
    ${karaf_debug_enabled} =    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius
    Genius.Set Switch Configuration
    ${check} =    BuiltIn.Wait Until Keyword Succeeds    30    10    Check Port Status Is ESTABLISHED    ${ODL_OF_PORT_6653}    @{TOOLS_SYSTEM_ALL_IPS}
    ${check} =    BuiltIn.Wait Until Keyword Succeeds    30    10    Check Port Status Is ESTABLISHED    ${OVSDBPORT}    @{TOOLS_SYSTEM_ALL_IPS}
    Genius.Build Dpn List
    @{SWITCH_DATA} =    Collections.Combine Lists    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Set Suite Variable    @{SWITCH_DATA}
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_1_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${SUBNET} =    Catenate    ${substr}0
    BuiltIn.Set Suite Variable    ${SUBNET}

Stop Suite
    [Documentation]    stops all connections and deletes all the bridges available on OVS
    : FOR    ${tool_system_index}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    SSHLibrary.Switch Connection    @{TOOLS_SYSTEM_ALL_CONN_IDS}[${tool_system_index}]
    \    SSHLibrary.Execute Command    sudo ovs-vsctl del-br ${Bridge}
    \    SSHLibrary.Execute Command    sudo ovs-vsctl del-manager
    \    SSHLibrary.Write    exit
    \    SSHLibrary.Close Connection

Check Port Status Is ESTABLISHED
    [Arguments]    ${port}    @{tools_ips}
    [Documentation]    This keyword will check whether ports are established or not on OVS
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    ${check_establishment} =    Utils.Run Command On Remote System And Log    ${tools_ip}    netstat -anp | grep ${port}
    \    BuiltIn.Should Contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Create Vteps
    [Arguments]    ${vlan_id}    ${gateway_ip}
    [Documentation]    This keyword creates VTEPs between OVS
    ${body} =    Genius.Set Json    ${vlan_id}    ${gateway_ip}    ${SUBNET}    @{TOOLS_SYSTEM_ALL_IPS}
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/TZA    data=${body}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Set Json
    [Arguments]    ${vlan}    ${gateway_ip}    ${subnet}    @{tools_ips}
    [Documentation]    Sets Json with the values passed for it.
    ${body} =    BuiltIn.Run Keyword If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[neon]    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan_below_sodium.json
    ...    ELSE    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan_sodium_and_above.json
    ${body} =    BuiltIn.Run Keyword If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[neon]    String.Replace String    ${body}    1.1.1.1    ${subnet}
    ...    ELSE    BuiltIn.Set Variable    ${body}
    ${body} =    BuiltIn.Run Keyword If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[neon]    String.Replace String    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ...    ELSE    BuiltIn.Set Variable    ${body}
    ${body} =    BuiltIn.Run Keyword If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[neon]    String.Replace String    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway_ip}"
    ...    ELSE    BuiltIn.Set Variable    ${body}
    : FOR    ${tool_system_index}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    ${body}    String.Replace String    ${body}    "dpn-id": 10${tool_system_index}    "dpn-id": ${DPN_ID_LIST[${tool_system_index}]}
    \    ${body}    String.Replace String    ${body}    "ip-address": "${tool_system_index+2}.${tool_system_index+2}.${tool_system_index+2}.${tool_system_index+2}"    "ip-address": "@{tools_ips}[${tool_system_index}]"
    BuiltIn.Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Build Dpn List
    [Documentation]    This keyword builds the list of DPN ids after configuring OVS bridges on each of the TOOLS_SYSTEM_IPs.
    @{DPN_ID_LIST} =    BuiltIn.Create List
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${output}    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl show -O Openflow13 ${Bridge} | head -1 | awk -F "dpid:" '{ print $2 }'
    \    ${dpn_id}    Utils.Run Command On Remote System And Log    ${tools_ip}    echo \$\(\(16\#${output}\)\)
    \    Collections.Append To List    ${DPN_ID_LIST}    ${dpn_id}
    BuiltIn.Set Suite Variable    @{DPN_ID_LIST}

BFD Suite Teardown
    [Documentation]    Run at end of BFD suite
    Genius.Delete All Vteps
    Genius.Stop Suite

Delete All Vteps
    [Documentation]    This will delete vtep.
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Wait Until Keyword Succeeds    30    5    Genius.Verify Tunnel Delete on DS    tun

Genius Test Setup
    [Documentation]    Genius test case setup
    BuiltIn.Run Keyword And Ignore Error    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf

Genius Test Teardown
    [Arguments]    ${data_models}    ${test_name}=${SUITE_NAME}.${TEST_NAME}    ${fail}=${FAIL_ON_EXCEPTIONS}
    : FOR    ${tool_system_index}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    OVSDB.Get DumpFlows And Ovsconfig    @{TOOLS_SYSTEM_ALL_CONN_IDS}[${tool_system_index}]    ${Bridge}
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
    KarafKeywords.Fail If Exceptions Found During Test    ${test_name}    fail=${fail}
    ODLTools.Get All    test_name=${test_name}

Genius Suite Debugs
    [Arguments]    ${data_models}
    Genius.Genius Test Teardown    ${data_models}    test_name=${SUITE_NAME}    fail=False

ITM Direct Tunnels Start Suite
    [Documentation]    start suite for itm scalability
    ClusterManagement.ClusterManagement_Setup
    ClusterManagement.Stop_Members_From_List_Or_All
    : FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<itm-direct-tunnels>false/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    ClusterManagement.Start_Members_From_List_Or_All
    Genius.Genius Suite Setup

ITM Direct Tunnels Stop Suite
    [Documentation]    Stop suite for ITM Direct Tunnels.
    : FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<itm-direct-tunnels>true/<itm-direct-tunnels>false/g' ${GENIUS_IFM_CONFIG_FLAG}
    Genius.Genius Suite Teardown

Ovs Interface Verification
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    Genius.Ovs Verification For Each Dpn    ${tools_ip}    ${TOOLS_SYSTEM_ALL_IPS}

Get ITM
    [Arguments]    ${itm_created[0]}    ${switch_data}=${SWITCH_DATA}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Collections.Append To List    ${switch_data}    ${itm_created[0]}
    Utils.Check For Elements At URI    ${TUNNEL_TRANSPORTZONE}/transport-zone/${itm_created[0]}    ${switch_data}

Check Tunnel Delete On OVS
    [Arguments]    ${tunnel_list}
    [Documentation]    Verifies the Tunnel is deleted from OVS.
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${output} =    Utils.Run Command On Remote System    ${tools_ip}    sudo ovs-vsctl show
    \    Genius.Verify Deleted Tunnels on OVS    ${tunnel_list}    ${output}

Check Table0 Entry In a Dpn
    [Arguments]    ${tools_ip}    ${bridgename}    ${port_numbers}
    [Documentation]    Checks the Table 0 entry in the OVS when flows are dumped.
    ${check} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${bridgename}
    ${num_ports} =    BuiltIn.Get Length    ${port_numbers}
    : FOR    ${port_index}    IN RANGE    ${num_ports}
    \    BuiltIn.Should Contain    ${check}    in_port=@{port_numbers}[${port_index}]

Verify Tunnel Status As Up
    [Arguments]    ${no_of_switches}=${NUM_TOOLS_SYSTEM}
    [Documentation]    Verify that the number of tunnels are UP
    ${no_of_tunnels} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    ${lines_of_state_up} =    String.Get Lines Containing String    ${no_of_tunnels}    ${STATE_UP}
    ${actual_tunnel_count} =    String.Get Line Count    ${lines_of_state_up}
    ${expected_tunnel_count} =    BuiltIn.Evaluate    ${no_of_switches}*(${no_of_switches}-1)
    BuiltIn.Should Be Equal As Strings    ${actual_tunnel_count}    ${expected_tunnel_count}

Verify Tunnel Status
    [Arguments]    ${tunnel_status}    ${tunnel_names}
    [Documentation]    Verifies if all tunnels in the input, has the expected status(UP/DOWN/UNKNOWN)
    ${tep_result} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    ${number_of_tunnels} =    BuiltIn.Get Length    ${tunnel_names}
    : FOR    ${each_tunnel}    IN RANGE    ${number_of_tunnels}
    \    ${tunnel} =    Collections.Get From List    ${tunnel_names}    ${each_tunnel}
    \    ${tep_output} =    String.Get Lines Containing String    ${tep_result}    ${tunnel}
    \    BuiltIn.Should Contain    ${tep_output}    ${tunnel_status}

Get Tunnels On OVS
    [Arguments]    ${connection_id}
    [Documentation]    Retrieves the list of tunnel ports present on OVS
    SSHLibrary.Switch Connection    ${connection_id}
    ${ovs_result} =    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{tunnel_names} =    BuiltIn.Create List
    ${tunnels} =    String.Get Lines Matching Regexp    ${ovs_result}    Interface "tun.*"    True
    @{tunnels_list} =    String.Split To Lines    ${tunnels}
    : FOR    ${tun}    IN    @{tunnels_list}
    \    ${tun_list}    Get Regexp Matches    ${tun}    tun.*\\w
    \    Collections.Append To List    ${tunnel_names}    @{tun_list}
    ${items_in_list} =    BuiltIn.Get Length    ${tunnel_names}
    [Return]    @{tunnel_names}

Get Tunnel
    [Arguments]    ${src}    ${dst}    ${type}    ${config_api_type}=${EMPTY}
    [Documentation]    This keyword returns tunnel interface name between source DPN and destination DPN.
    ...    Statements are executed depending on whether it is itm tunnel state(default) or dpn tep state.
    ${resp} =    BuiltIn.Run Keyword If    '${config_api_type}' == '${EMPTY}'    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/${type}/
    ...    ELSE    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-teps-state/dpns-teps/${src}/remote-dpns/${dst}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    BuiltIn.Log    ${resp.content}
    ${respjson} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    ${json} =    Utils.Json Parse From String    ${resp.content}
    BuiltIn.Should Contain    ${resp.content}    ${dst}
    BuiltIn.Run Keyword If    '${config_api_type}' == '${EMPTY}'    BuiltIn.Should Contain    ${resp.content}    ${src}
    ${tunnel_interface_name} =    BuiltIn.Run Keyword If    "tunnel-interface-names" in "${json}"    Genius.Get Tunnel Interface Name    ${json["internal-tunnel"][0]}    tunnel-interface-names
    ${tunnel_name_output}    ${tunnel_name} =    BuiltIn.Run Keyword Unless    '${config_api_type}' == '${EMPTY}'    BuiltIn.Should Match Regexp    ${resp.content}    "tunnel-name":"(tun[\\w\\d]+)"
    ${tunnel} =    BuiltIn.Set Variable If    '${config_api_type}' == '${EMPTY}'    ${tunnel_interface_name}    ${tunnel_name}
    [Return]    ${tunnel}

Get Tunnel Interface Name
    [Arguments]    ${json}    ${expected_tunnel_interface_name}
    [Documentation]    This keyword extracts tunnel interface name from json given as input.
    ${tunnels} =    Collections.Get From Dictionary    ${json}    ${expected_tunnel_interface_name}
    [Return]    ${tunnels[0]}

Verify Tunnel Delete on DS
    [Arguments]    ${tunnel}
    [Documentation]    This keyword confirms that specified tunnel is not present by giving command from karaf console.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${output}    ${tunnel}

SRM Start Suite
    [Documentation]    Start suite for service recovery.
    Genius Suite Setup
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status As Up
    Genius.Genius Suite Debugs    ${data_models}

SRM Stop Suite
    [Documentation]    Stop suite for service recovery.
    Genius.Delete All Vteps
    Genius.Genius Suite Debugs    ${data_models}
    Genius.Genius Suite Teardown

Verify Tunnel Monitoring Status
    [Arguments]    ${tunnel_monitor_status}
    ${output}=    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${output}    ${tunnel_monitor_status}

Set Switch Configuration
    [Documentation]    This keyword will set manager,controller,tap port,bridge on each OVS
    : FOR    ${tool_system_index}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    SSHLibrary.Switch Connection    @{TOOLS_SYSTEM_ALL_CONN_IDS}[${tool_system_index}]
    \    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    \    SSHLibrary.Execute Command    sudo ovs-vsctl add-br ${Bridge}
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set bridge ${Bridge} protocols=OpenFlow13
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set-controller ${Bridge} tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT_6653}
    \    SSHLibrary.Execute Command    sudo ifconfig ${Bridge} up
    \    SSHLibrary.Execute Command    sudo ovs-vsctl add-port ${Bridge} tap${tool_system_index}ed70586-6c -- set Interface tap${tool_system_index}ed70586-6c type=tap
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT}
    \    SSHLibrary.Execute Command    sudo ovs-vsctl show

Ovs Verification For Each Dpn
    [Arguments]    ${tools_system_ip}    ${tools_ips}
    [Documentation]    This keyword will verify whether local and remote ip are present on the tunnels available on OVS
    ${ovs_output} =    Utils.Run Command On Remote System And Log    ${tools_system_ip}    sudo ovs-vsctl show
    @{updated_tools_ip_list} =    BuiltIn.Create List    @{tools_ips}
    Collections.Remove Values From List    ${updated_tools_ip_list}    ${tools_system_ip}
    BuiltIn.Log Many    @{updated_tools_ip_list}
    ${num_tool_ips}    BuiltIn.Get Length    ${updated_tools_ip_list}
    : FOR    ${num}    IN RANGE    ${num_tool_ips}
    \    ${tools_ip} =    Collections.Get From List    ${updated_tools_ip_list}    ${num}
    \    BuiltIn.Should Contain    ${ovs_output}    ${tools_ip}

Get Tunnels List
    [Documentation]    The keyword fetches the list of operational tunnels from ODL
    ${no_of_tunnels}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    ${tunnels} =    String.Get Regexp Matches    ${no_of_tunnels}    tun[\\w\\d]+
    BuiltIn.Log    ${tunnels}
    [Return]    ${tunnels}

Verify Table0 Entry After fetching Port Number
    [Documentation]    This keyword will get the port number and checks the table0 entry for each dpn
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${check} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -O OpenFlow13 show ${Bridge}
    \    ${port_numbers} =    String.Get Regexp Matches    ${check}    (\\d+).tun.*    1
    \    Genius.Check Table0 Entry In a Dpn    ${tools_ip}    ${Bridge}    ${port_numbers}

Verify Deleted Tunnels On OVS
    [Arguments]    ${tunnel_list}    ${resp_data}
    [Documentation]    This will verify whether tunnel is deleted.
    BuiltIn.Log    ${resp_data}
    : FOR    ${tunnel}    IN    @{tunnel_list}
    \    BuiltIn.Should Not Contain    ${resp_data}    ${tunnel}

Verify Response Code Of Dpn End Point Config API
    [Arguments]    ${dpn_list}=${DPN_ID_LIST}
    [Documentation]    This keyword will verify response code from itm-state: dpn endpoints config api for each dpn
    : FOR    ${dpn}    IN    @{dpn_list}
    \    BuiltIn.Wait Until Keyword Succeeds    40    5    Utils.Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn}/

Get Tunnel Between DPNs
    [Arguments]    ${tunnel_type}    ${config_api_type}    ${src_dpn_id}    @{dst_dpn_ids}
    [Documentation]    This keyword will Get All the Tunnels available on DPN's
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_ids}
    \    ${tunnel} =    BuiltIn.Wait Until Keyword Succeeds    30    10    Genius.Get Tunnel    ${src_dpn_id}
    \    ...    ${dst_dpn_id}    ${tunnel_type}    ${config_api_type}

Update Dpn id List And Get Tunnels
    [Arguments]    ${tunnel_type}    ${config_api_type}=${EMPTY}    ${dpn_ids}=${DPN_ID_LIST}
    [Documentation]    Update the exisisting dpn id list to form different combination of dpn ids such that tunnel formation between all dpns is verified.
    : FOR    ${dpn_id}    IN    @{dpn_ids}
    \    @{dpn_ids_updated} =    BuiltIn.Create List    @{dpn_ids}
    \    Collections.Remove Values From List    ${dpn_ids_updated}    ${dpn_id}
    \    BuiltIn.Log Many    ${dpn_ids_updated}
    \    Genius.Get Tunnel Between DPNs    ${tunnel_type}    ${config_api_type}    ${dpn_id}    @{dpn_ids_updated}
