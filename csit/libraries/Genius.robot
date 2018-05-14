*** Settings ***
Documentation     This suite is a common keywords file for genius project.
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ClusterManagement.robot
Resource          CompareStream.robot
Resource          DataModels.robot
Resource          KarafKeywords.robot
Resource          OVSDB.robot
Resource          ToolsSystem.robot
Resource          Utils.robot
Resource          VpnOperations.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../variables/genius
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
@{GENIUS_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    OVSDB
${vlan}           0
${gateway_ip}     0.0.0.0
${BRIDGE}         br-int

*** Keywords ***
Genius Suite Setup
    [Documentation]    Create Rest Session to http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    Start Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5

Genius Suite Teardown
    [Documentation]    Delete all sessions
    Delete All Sessions
    Stop Suite

Start Suite
    [Documentation]    Initial setup for Genius test suites
    CompareStream.Run_Keyword_If_At_Least_Oxygen    Wait Until Keyword Succeeds    60    2    ClusterManagement.Check Status Of Services Is OPERATIONAL    @{GENIUS_DIAG_SERVICES}
    KarafKeywords.Setup_Karaf_Keywords
    ToolsSystem.Get Tools System Nodes Data
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius
    Genius.Set Bridge Configuration
    ${check} =    BuiltIn.Wait Until Keyword Succeeds    30    10    Check Establishment    ${ODL_OF_PORT_6653}
    BuiltIn.Log    ${check}
    ${check} =    BuiltIn.Wait Until Keyword Succeeds    30    10    Check Establishment    ${OVSDBPORT}
    BuiltIn.Log    ${check}
    Genius.Build Dpn List
    @{GENIUS_DATA} =    Collections.Combine Lists    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Set Suite Variable    @{GENIUS_DATA}

Stop Suite
    [Documentation]    stops all connections and deletes all the bridges available on OVS
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    SSHLibrary.Switch Connection    @{TOOLS_SYSTEM_ALL_CONN_IDS}[${i}]
    \    SSHLibrary.Execute Command    sudo ovs-vsctl del-br ${BRIDGE}
    \    SSHLibrary.Execute Command    sudo ovs-vsctl del-manager
    \    SSHLibrary.Write    exit
    \    SSHLibrary.Close Connection

Check Establishment
    [Arguments]    ${port}
    [Documentation]    This keyword will check whether ports are established or not on OVS
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${check_establishment}    Utils.Run Command On Remote System And Log    ${tools_ip}    netstat -anp | grep ${port}
    \    BuiltIn.Should Contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Create Vteps
    [Arguments]    ${vlan}    ${gateway_ip}
    [Documentation]    This keyword creates VTEPs between OVS
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr} =    BuiltIn.Should Match Regexp    ${TOOLS_SYSTEM_1_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet} =    Catenate    ${substr}0
    BuiltIn.Set Suite Variable    ${subnet}
    ${vlan} =    BuiltIn.Set Variable    ${vlan}
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${body} =    Genius.Set Json    ${vlan}    ${gateway_ip}    ${subnet}
    ${VTEP_BODY} =    BuiltIn.Set Variable    ${body}
    BuiltIn.Set Suite Variable    ${VTEP_BODY}
    ${resp} =    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    204

Set Json
    [Arguments]    ${vlan}    ${gateway_ip}    ${subnet}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${body}    String.Replace String    ${body}    1.1.1.1    ${subnet}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${body}    String.Replace String    ${body}    "dpn-id": 10${i}    "dpn-id": ${DPN_ID_LIST[${i}]}
    \    ${body}    String.Replace String    ${body}    "ip-address": "${i+2}.${i+2}.${i+2}.${i+2}"    "ip-address": "@{TOOLS_SYSTEM_ALL_IPS}[${i}]"
    ${body}    String.Replace String    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    String.Replace String    ${body}    "gateway_ip": "0.0.0.0"    "gateway_ip": "${gateway_ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Build Dpn List
    [Documentation]    This keyword gets the list of DPN id's of the switch after configuring bridges on it.It returns the captured DPN id list.
    @{DPN_ID_LIST}    BuiltIn.Create List
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${bridge_name1} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show | grep Bridge | awk '{print $2}'
    \    ${output}    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl show -O Openflow13 ${bridge_name1} | head -1 | awk -F "dpid:" '{ print $2 }'
    \    ${dpn_id}    Utils.Run Command On Remote System And Log    ${tools_ip}    echo \$\(\(16\#${output}\)\)
    \    Collections.Append To List    ${DPN_ID_LIST}    ${dpn_id}
    BuiltIn.Set Suite Variable    @{DPN_ID_LIST}

BFD Suite Stop
    [Documentation]    Run at end of BFD suite
    Delete All Vteps
    Stop Suite

Delete All Vteps
    [Documentation]    This will delete vtep.
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${VTEP_BODY}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Wait Until Keyword Succeeds    30    5    Verify Tunnel Delete on DS    tun

Genius Test Setup
    [Documentation]    Genius test case setup
    BuiltIn.Run Keyword And Ignore Error    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf

Genius Test Teardown
    [Arguments]    ${data_models}
    [Documentation]    This will give all the dumpflows
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    OVSDB.Get DumpFlows And Ovsconfig    @{TOOLS_SYSTEM_ALL_CONN_IDS}[${i}]    ${BRIDGE}
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}

ITM Direct Tunnels Start Suite
    [Documentation]    start suite for itm scalability
    ClusterManagement.ClusterManagement_Setup
    ClusterManagement.Stop_Members_From_List_Or_All
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${i+1}_IP}    sed -i -- 's/<itm-direct-tunnels>false/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Setup

ITM Direct Tunnels Stop Suite
    [Documentation]    Stop suite for ITM scalability
    : FOR    ${i}    INRANGE    ${NUM_ODL_SYSTEM}
    \    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_${i+1}_IP}    sed -i -- 's/<itm-direct-tunnels>true/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    Genius Suite Teardown

Verify Tunnel Monitoring Is On
    [Documentation]    This keyword will get tep:show output and verify tunnel monitoring status
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${output}    ${TUNNEL_MONITOR_ON}

Ovs Interface Verification
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    Ovs Verification For Each Dpn    ${tools_ip}    ${TOOLS_SYSTEM_ALL_IPS}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    @{Itm-no-vlan}    BuiltIn.Create List    ${itm_created[0]}    ${subnet}    ${vlan}
    @{Itm-no-vlan}    Collections.Combine Lists    @{Itm-no-vlan}    ${GENIUS_DATA}
    Utils.Check For Elements At URI    ${TUNNEL_TRANSPORTZONE}/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Check Tunnel Delete On OVS
    [Arguments]    ${tunnel_list}
    [Documentation]    Verifies the Tunnel is deleted from OVS.
    Builtin.Log    TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    \    BuiltIn.Log    ${output}
    \    Genius.Verify Deleted Tunnels on OVS    ${tunnel_list}    ${output}

Check Table0 Entry In a Dpn
    [Arguments]    ${tools_ip}    ${bridgename}    ${port_numbers}
    [Documentation]    Checks the Table 0 entry in the OVS when flows are dumped.
    ${check} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${bridgename}
    ${num_ports} =    BuiltIn.Get Length    ${port_numbers}
    : FOR    ${i}    INRANGE    ${num_ports}
    \    BuiltIn.Should Contain    ${check}    in_port=@{port_numbers}[${i}]

Verify Tunnel Status As Up
    [Documentation]    Verify that the number of tunnels are UP
    ${no_of_tunnels} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    ${lines_of_state_up} =    String.Get Lines Containing String    ${no_of_tunnels}    ${STATE_UP}
    ${actual_tunnel_count} =    String.Get Line Count    ${lines_of_state_up}
    ${expected_tunnel_count} =    BuiltIn.Evaluate    ${NUM_TOOLS_SYSTEM}*(${NUM_TOOLS_SYSTEM}-1)
    BuiltIn.Should Be Equal As Strings    ${actual_tunnel_count}    ${expected_tunnel_count}

Verify Tunnel Status
    [Arguments]    ${tunnel_status}    ${tunnel_names}
    [Documentation]    Verifies if all tunnels in the input, has the expected status(UP/DOWN/UNKNOWN)
    ${tep_result} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    ${num_tunnels} =    BuiltIn.Get Length    ${tunnel_names}
    : FOR    ${each_item}    INRANGE    ${num_tunnels}
    \    ${tun} =    Collections.Get From List    ${tunnel_names}    ${each_item}
    \    ${tep_output} =    String.Get Lines Containing String    ${tep_result}    ${tun}
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
    \    ${tun_list}    String.Get Regexp Matches    ${tun}    tun.*\\w
    \    Collections.Append To List    ${tunnel_names}    @{tun_list}
    ${items_in_list} =    BuiltIn.Get Length    ${tunnel_names}
    [Return]    @{tunnel_names}

Get Tunnel
    [Arguments]    ${src}    ${dst}    ${type}
    [Documentation]    This keyword returns tunnel interface name between source DPN and destination DPN.
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/${type}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    BuiltIn.Should Contain    ${resp.content}    ${src}
    BuiltIn.Should Contain    ${resp.content}    ${dst}
    ${json} =    Utils.Json Parse From String    ${resp.content}
    ${tunnel} =    BuiltIn.Run Keyword If    "tunnel-interface-names" in "${json}"    Get Tunnel Interface Name    ${json["internal-tunnel"][0]}    tunnel-interface-names
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
    Genius.Create Vteps    ${vlan}    ${gateway_ip}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status As Up
    Genius Test Teardown    ${data_models}

SRM Stop Suite
    [Documentation]    Stop suite for service recovery.
    Delete All Vteps
    Genius Test Teardown    ${data_models}
    Genius Suite Teardown

Set Bridge Configuration
    [Documentation]    This keyword will set the bridges on each OVS
    : FOR    ${i}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    SSHLibrary.Switch Connection    @{TOOLS_SYSTEM_ALL_CONN_IDS}[${i}]
    \    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    \    SSHLibrary.Execute Command    sudo ovs-vsctl add-br ${BRIDGE}
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set bridge ${BRIDGE} protocols=OpenFlow13
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set-controller ${BRIDGE} tcp:${ODL_SYSTEM_IP}:6653
    \    SSHLibrary.Execute Command    sudo ifconfig ${BRIDGE} up
    \    SSHLibrary.Execute Command    sudo ovs-vsctl add-port ${BRIDGE} tap${i}ed70586-6c -- set Interface tap${i}ed70586-6c type=tap
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    \    SSHLibrary.Execute Command    sudo ovs-vsctl show

Ovs Verification For Each Dpn
    [Arguments]    ${tools_system_ip}    ${tools_ips}
    [Documentation]    This keyword will verify whether local and remote ip are present on the tunnels available on OVS
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    ${ovs_output} =    Utils.Run Command On Remote System And Log    ${tools_system_ip}    sudo ovs-vsctl show
    @{updated_tools_ip_list} =    BuiltIn.Create List    @{tools_ips}
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove Values From List    ${updated_tools_ip_list}    ${tools_system_ip}
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}
    BuiltIn.Log Many    @{updated_tools_ip_list}
    ${num_tool_ips}    BuiltIn.Get Length    ${updated_tools_ip_list}
    : FOR    ${num}    INRANGE    ${num_tool_ips}
    \    ${tools_ip} =    Collections.Get From List    ${updated_tools_ip_list}    ${num}
    \    BuiltIn.Should Contain    ${ovs_output}    ${tools_ip}
    BuiltIn.Log    NUM_TOOLS_SYSTEM: ${NUM_TOOLS_SYSTEM}, TOOLS_SYSTEM_ALL_IPS: @{TOOLS_SYSTEM_ALL_IPS}

Get Tunnels List
    [Documentation]    The keyword fetches the list of operational tunnels from ODL
    ${no_of_tunnels}    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    ${tunnels} =    String.Get Regexp Matches    ${no_of_tunnels}    tun[\\w\\d]+
    BuiltIn.Log    ${tunnels}
    [Return]    ${tunnels}

Verify Table0 Entry After fetching Port Number
    [Documentation]    This keyword will get the port number and checks the table0 entry for each dpn
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${check} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -O OpenFlow13 show ${BRIDGE}
    \    ${port_numbers} =    String.Get Regexp Matches    ${check}    (\\d+).tun.*    1
    \    Genius.Check Table0 Entry In a Dpn    ${tools_ip}    ${BRIDGE}    ${port_numbers}

Verify Deleted Tunnels On OVS
    [Arguments]    ${tunnel_list}    ${resp_data}
    [Documentation]    This will verify whether tunnel deleted.
    BuiltIn.Log    ${resp_data}
    : FOR    ${tun}    IN    @{tunnel_list}
    \    BuiltIn.Should Not Contain    ${resp_data}    ${tun}

Verify Data From URL
    [Documentation]    This keyword will verify data from itm-state: dpn endpoints config api for each dpn
    : FOR    ${dpn}    IN    @{DPN_ID_LIST}
    \    BuiltIn.Wait Until Keyword Succeeds    40    5    Utils.Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn}/
