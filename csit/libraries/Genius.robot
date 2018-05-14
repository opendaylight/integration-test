*** Settings ***
Documentation     This suite is a common keywords file for genius project.
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           re
Library           string
Resource          KarafKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot
Resource          OVSDB.robot
Resource          ../variables/netvirt/Variables.robot
Resource          VpnOperations.robot
Resource          DataModels.robot
Library           Collections

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../variables/genius
${Bridge-1}       BR1
${Bridge-2}       BR2
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
@{GENIUS_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE
${vlan}           0
${gateway-ip}     0.0.0.0
@{DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE
@{Brideg_list}    BR1    BR2    BR3

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
    CompareStream.Run_Keyword_If_At_Least_Oxygen    BuiltIn.Wait Until Keyword Succeeds    60    2    Check System Status    @{GENIUS_DIAG_SERVICES}
    CompareStream.Run_Keyword_If_At_Least_Oxygen    BuiltIn.Wait Until Keyword Succeeds    60    2    Check System Status
    KarafKeywords.Setup_Karaf_Keywords
    @{TOOLS_SYSTEM_LIST}    BuiltIn.Create List
    : FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM} +1
    \    Collections.Append To List    ${TOOLS_SYSTEM_LIST}    ${TOOLS_SYSTEM_${i}_IP}
    BuiltIn.Log    ${TOOLS_SYSTEM_LIST}
    BuiltIn.Set Global Variable    ${TOOLS_SYSTEM_LIST}
    @{conn_id_list}    BuiltIn.Create List
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    ${conn_id} =    SSHLibrary.Open Connection    ${tools_ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    \    Collections.Append To List    ${conn_id_list}    ${conn_id}
    BuiltIn.Log    ${conn_id_list}
    BuiltIn.Set Global Variable    ${conn_id_list}
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius
    @{Bridge_List}    BuiltIn.Create List
    : FOR    ${i}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    Collections.Append To List    ${Bridge_List}    BR${i}
    BuiltIn.Log    ${Bridge_List}
    BuiltIn.Set Global Variable    ${Bridge_List}
    Genius.Set Bridge
    ${check}    BuiltIn.Wait Until Keyword Succeeds    30    10    check establishment    6633
    log    ${check}
    ${check_2}    BuiltIn.Wait Until Keyword Succeeds    30    10    check establishment    6640
    log    ${check_2}
    Genius.Get Dpn Ids
    @{data}    Collections.Combine Lists    ${Dpn_id_List}    ${Bridge_List}
    @{data}    Collections.Combine Lists    @{data}    ${TOOLS_SYSTEM_LIST}
    BuiltIn.Set Global Variable    ${data}

Stop Suite
    [Documentation]    stops all connections and deletes all the bridges available on OVS
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    SSHLibrary.Switch Connection    ${conn_id_list[${i}]}
    \    SSHLibrary.Execute Command    sudo ovs-vsctl del-br BR{i}
    \    SSHLibrary.Execute Command    sudo ovs-vsctl del-manager
    \    SSHLibrary.Write    exit
    \    SSHLibrary.Close Connection

check establishment
    [Arguments]    ${port}
    [Documentation]    This keyword will check whether ports are established or not on OVS
    ${check_establishment}    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    netstat -anp | grep ${port}
    BuiltIn.Should Contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Check Service Status
    [Arguments]    ${odl_ip}    ${system_ready_state}    ${service_state}    @{service_list}
    [Documentation]    Issues the karaf shell command showSvcStatus to verify the ready and service states are the same as the arguments passed
    ${service_status_output} =    BuiltIn.Run Keyword If    ${NUM_ODL_SYSTEM} > 1    KarafKeywords.Issue_Command_On_Karaf_Console    showSvcStatus -n ${odl_ip}    ${odl_ip}    ${KARAF_SHELL_PORT}
    ...    ELSE    Issue_Command_On_Karaf_Console    showSvcStatus    ${odl_ip}    ${KARAF_SHELL_PORT}
    BuiltIn.Should Contain    ${service_status_output}    ${system_ready_state}
    : FOR    ${service}    IN    @{service_list}
    \    BuiltIn.Should Match Regexp    ${service_status_output}    ${service} +: ${service_state}

Create Vteps
    [Arguments]    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between OVS
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    BuiltIn.Should Match Regexp    ${TOOLS_SYSTEM_1_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    BuiltIn.Set Global Variable    ${subnet}
    ${vlan} =    BuiltIn.Set Variable    ${vlan}
    ${gateway-ip} =    BuiltIn.Set Variable    ${gateway-ip}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${body}    Genius.Set Json    ${vlan}    ${gateway-ip}    ${subnet}    ${TOOLS_SYSTEM_LIST}
    ${vtep_body}    BuiltIn.Set Variable    ${body}
    BuiltIn.Set Global Variable    ${vtep_body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    should be equal as strings    ${resp.status_code}    204

Set Json
    [Arguments]    ${vlan}    ${gateway-ip}    ${subnet}    ${TOOLS_SYSTEM_LIST}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${body}    String.Replace String    ${body}    1.1.1.1    ${subnet}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${body}    String.Replace String    ${body}    "dpn-id": 10${i}    "dpn-id": ${Dpn_id_List[${i}]}
    \    ${body}    String.Replace String    ${body}    "ip-address": "${i+2}.${i+2}.${i+2}.${i+2}"    "ip-address": "${TOOLS_SYSTEM_LIST[${i}]}"
    ${body}    String.Replace String    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    String.Replace String    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Get Dpn Ids
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    @{Dpn_id_List}    BuiltIn.Create List
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    ${Bridgename1}    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show | grep Bridge | awk -F "\\"" '{print $2}'
    \    ${output1}    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl show -O Openflow13 ${Bridgename1} | head -1 | awk -F "dpid:" '{ print $2 }'
    \    ${Dpn_id}    Utils.Run Command On Remote System And Log    ${tools_ip}    echo \$\(\(16\#${output1}\)\)
    \    Collections.Append To List    ${Dpn_id_List}    ${Dpn_id}
    BuiltIn.Set Global Variable    ${Dpn_id_List}
    [Return]    ${Dpn_id_List}

BFD Suite Stop
    [Documentation]    Run at end of BFD suite
    Delete All Vteps
    Stop Suite

Delete All Vteps
    [Documentation]    This will delete vtep.
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${vtep_body}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Log    "Before disconnecting CSS with controller"
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW}
    BuiltIn.Wait Until Keyword Succeeds    30    5    Verify Tunnel Delete on DS    tun

Genius Test Teardown
    [Arguments]    ${data_models}
    [Documentation]    This will give all the dumpflows
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_list[${i}]}    ${Bridge_List[${i}]}
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}

ITM Direct Tunnels Start Suite
    [Documentation]    start suite for itm scalability
    ClusterManagement.ClusterManagement_Setup
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Clean_Journals_Data_And_Snapshots_On_List_Or_All
    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    sed -i -- 's/<itm-direct-tunnels>false/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Setup

ITM Direct Tunnels Stop Suite
    [Documentation]    This will flip the itm-direct-tunnels flag to false and closes all the connections
    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    sed -i -- 's/<itm-direct-tunnels>true/<itm-direct-tunnels>false/g' ${GENIUS_IFM_CONFIG_FLAG}
    Genius Suite Teardown

Verify Tunnel Monitoring is on
    [Documentation]    This keyword will get tep:show output and verify tunnel monitoring status
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${output}    ${TUNNEL_MONITOR_ON}

Ovs Verification between Dpn
    [Arguments]    @{TOOLS_SYSTEM_LIST}
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    Ovs Verification For Each Dpn    ${tools_ip}    ${TOOLS_SYSTEM_LIST}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    @{Itm-no-vlan}    BuiltIn.Create List    ${itm_created[0]}    ${subnet}    ${vlan}
    @{Itm-no-vlan}    Collections.Combine Lists    @{Itm-no-vlan}    ${data}
    Utils.Check For Elements At URI    ${TUNNEL_TRANSPORTZONE}/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Check Tunnel Delete On OVS
    [Arguments]    ${tunnel-list}
    [Documentation]    Verifies the Tunnel is deleted from OVS.
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${return} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_${i+1}_IP}    sudo ovs-vsctl show
    \    Genius.verify Deleted Tunnels on OVS    ${tunnel-list}    ${return}
    [Return]    ${return}

Check Table0 Entry For 2 Dpn
    [Arguments]    ${connection_id}    ${Bridgename}
    [Documentation]    Checks the Table 0 entry in the OVS when flows are dumped.
    SSHLibrary.Switch Connection    ${connection_id}
    ${check}    SSHLibrary.Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridgename}
    BuiltIn.Log    ${check}
    ${items}    BuiltIn.Get Length    ${port}
    : FOR    ${i}    INRANGE    ${items}
    \    BuiltIn.Should Contain    ${check}    in_port=${port[${i}]}

Check ITM Tunnel State
    [Arguments]    ${tunnel1}    ${tunnel2}
    [Documentation]    Verifies the Tunnel is deleted from datastore
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp.content}    ${tunnel1}    ${tunnel2}

Verify Tunnel Status as UP
    [Documentation]    Verify that the number of tunnels are UP
    ${no_of_tunnels}    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    ${lines_of_State_UP}    String.Get Lines Containing String    ${no_of_tunnels}    ${STATE_UP}
    ${Actual_Tunnel_Count}    String.Get Line Count    ${lines_of_State_UP}
    ${Expected_Tunnel_Count}    BuiltIn.Evaluate    ${NUM_TOOLS_SYSTEM}*(${NUM_TOOLS_SYSTEM}-1)
    BuiltIn.Should Be Equal As Strings    ${Actual_Tunnel_Count}    ${Expected_Tunnel_Count}

Check System Status
    [Arguments]    @{service_list}
    [Documentation]    This keyword will verify whether all the services are in operational and all nodes are active based on the number of odl systems
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Check Service Status    ${ODL_SYSTEM_${i+1}_IP}    ACTIVE    OPERATIONAL    @{service_list}

Verify Tunnel Status
    [Arguments]    ${tunnel_status}    ${tunnel_names}
    [Documentation]    Verifies if all tunnels in the input, has the expected status(UP/DOWN/UNKNOWN)
    ${tep_result} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    ${items}    BuiltIn.Get Length    ${tunnel_names}
    : FOR    ${i}    INRANGE    ${items}
    \    ${tun}    Collections.Get From List    ${tunnel_names}    ${i}
    \    ${tep_output} =    String.Get Lines Containing String    ${tep_result}    ${tun}
    \    BuiltIn.Should Contain    ${tep_output}    ${tunnel_status}

Get Tunnels On OVS
    [Arguments]    ${connection_id}
    [Documentation]    Retrieves the list of tunnel ports present on OVS
    SSHLibrary.Switch Connection    ${connection_id}
    ${ovs_result} =    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{tunnel_names}    BuiltIn.Create List
    ${tunnels} =    String.Get Lines Matching Regexp    ${ovs_result}    Interface "tun.*"    True
    @{tunnels_list} =    String.Split To Lines    ${tunnels}
    : FOR    ${tun}    IN    @{tunnels_list}
    \    ${tun_list}    String.Get Regexp Matches    ${tun}    tun.*\\w
    \    Collections.Append To List    ${tunnel_names}    @{tun_list}
    ${items_in_list} =    BuiltIn.Get Length    ${tunnel_names}
    [Return]    @{Tunnel_Names}

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

Verify All Tunnel Delete on DS
    [Documentation]    This keyword confirms that tunnels are not present by giving command from karaf console.
    Verify Tunnel Delete on DS    tun

Verify Tunnel Delete on DS
    [Arguments]    ${tunnel}
    [Documentation]    This keyword confirms that specified tunnel is not present by giving command from karaf console.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${output}    ${tunnel}

SRM Start Suite
    [Documentation]    Start suite for service recovery.
    Genius Suite Setup
    Genius.Create Vteps    ${vlan}    ${gateway-ip}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP

SRM Stop Suite
    [Documentation]    Stop suite for service recovery.
    Delete All Vteps
    Genius Suite Teardown

Set Bridge
    [Documentation]    This keyword will set the bridges on each OVS
    : FOR    ${i}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    SSHLibrary.Switch Connection    ${conn_id_list[${i}]}
    \    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    \    SSHLibrary.Execute Command    sudo ovs-vsctl add-br BR${i}
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set bridge BR${i} protocols=OpenFlow13
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set-controller BR${i} tcp:${ODL_SYSTEM_IP}:6633
    \    SSHLibrary.Execute Command    sudo ifconfig BR${i} up
    \    SSHLibrary.Execute Command    sudo ovs-vsctl add-port BR${i} tap${i}ed70586-6c -- set Interface tap${i}ed70586-6c type=tap
    \    SSHLibrary.Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    \    SSHLibrary.Execute Command    sudo ovs-vsctl show

Ovs Verification For Each Dpn
    [Arguments]    ${tools_system_ip}    @{TOOLS_SYSTEM_LIST}
    [Documentation]    This keyword will verify the tunnels available on OVS whether local and remote ip are present
    ${ovs_output}    Utils.Run Command On Remote System And Log    ${tools_system_ip}    sudo ovs-vsctl show
    @{updated_tools_ip_list}    BuiltIn.Create List    @{TOOLS_SYSTEM_LIST}
    Collections.Remove Values From List    @{updated_tools_ip_list}    ${tools_system_ip}
    BuiltIn.Log Many    @{updated_tools_ip_list}
    ${items}    BuiltIn.Get Length    @{updated_tools_ip_list}
    : FOR    ${i}    INRANGE    ${items}
    \    ${ip}    Collections.Get From List    @{updated_tools_ip_list}    ${i}
    \    BuiltIn.Should Contain    ${ovs_output}    ${ip}
    [Teardown]

Get Tunnels List
    [Documentation]    We will get all the tunnels in a list
    ${no_of_tunnels}    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    ${tunnels}    String.Get Regexp Matches    ${no_of_tunnels}    tun[\\w\\d]+
    BuiltIn.Log    ${tunnels}
    [Return]    ${tunnels}

Get Port Number
    [Documentation]    This keyword will get the port number and checks the table0 entry for 2 DPN
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${check}    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_${i+1}_IP}    sudo ovs-ofctl -O OpenFlow13 show BR${i}
    \    ${port}    String.Get Regexp Matches    ${check}    (\\d+).tun.*    1
    \    BuiltIn.Set Global Variable    ${port}
    \    Genius.Check Table0 Entry For 2 Dpn    ${conn_id_list[${i}]}    ${Bridge_List[${i}]}

verify Deleted Tunnels on OVS
    [Arguments]    ${tunnel-list}    ${return}
    [Documentation]    This will verify whether tunnel deleted on OVS or not
    : FOR    ${tun}    IN    @{tunnel-list}
    \    BuiltIn.Should Not Contain    ${return}    ${tun}
