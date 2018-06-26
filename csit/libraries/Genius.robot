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
    Run_Keyword_If_At_Least_Oxygen    Wait Until Keyword Succeeds    60    2    Check System Status    @{GENIUS_DIAG_SERVICES}
    Log    Start the tests
    Comment    ${conn_id_1}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Comment    Set Global Variable    ${conn_id_1}
    Run_Keyword_If_At_Least_Oxygen    Wait Until Keyword Succeeds    60    2    Check System Status
    KarafKeywords.Setup_Karaf_Keywords
    @{TOOLS_SYSTEM_LIST}    Create List
    : FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM} +1
    \    Append To List    ${TOOLS_SYSTEM_LIST}    ${TOOLS_SYSTEM_${i}_IP}
    \    log    ${TOOLS_SYSTEM_LIST}
    log    ${TOOLS_SYSTEM_LIST}
    Set Global Variable    ${TOOLS_SYSTEM_LIST}
    @{conn_id_list}    Create List
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    ${conn_id} =    Open Connection    ${tools_ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    \    Append To List    ${conn_id_list}    ${conn_id}
    \    log    ${conn_id_list}
    log    ${conn_id_list}
    Set Global Variable    ${conn_id_list}
    Comment    ${conn_id_1} =    Open Connection    ${TOOLS_SYSTEM_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Comment    Set Global Variable    ${conn_id_1}
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius
    @{Bridge_List}    Create List
    : FOR    ${i}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    Append To List    ${Bridge_List}    BR${i}
    \    log    ${Bridge_List}
    Set Global Variable    ${Bridge_List}
    Genius.Set Bridge
    Comment    : FOR    ${bridge}    IN    @{Bridge_List}
    Comment    \    Set Bridge    ${NUM_TOOLS_SYSTEM}    ${bridge}
    Comment    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    Comment    \    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Comment    \    Execute Command    sudo ovs-vsctl add-br BR${i}
    Comment    \    Execute Command    sudo ovs-vsctl set bridge BR${i} protocols=OpenFlow13
    Comment    \    Execute Command    sudo ovs-vsctl set-controller BR${i} tcp:${ODL_SYSTEM_IP}:6633
    Comment    \    Execute Command    sudo ifconfig BR${i} up
    Comment    \    Execute Command    sudo ovs-vsctl add-port BR${i} tap8ed70586-6c -- set Interface tap8ed70586-6c type=tap
    Comment    \    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Comment    \    Execute Command    sudo ovs-vsctl show
    Comment    Log    ${output_1}
    ${check}    Wait Until Keyword Succeeds    30    10    check establishment    6633
    log    ${check}
    ${check_2}    Wait Until Keyword Succeeds    30    10    check establishment    6640
    log    ${check_2}
    Comment    Log    >>>>>Switch 2 configuration <<<<<
    Comment    ${conn_id_2} =    Open Connection    ${TOOLS_SYSTEM_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Comment    Set Global Variable    ${conn_id_2}
    Comment    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Comment    Execute Command    sudo ovs-vsctl add-br BR2
    Comment    Execute Command    sudo ovs-vsctl set bridge BR2 protocols=OpenFlow13
    Comment    Execute Command    sudo ovs-vsctl set-controller BR2 tcp:${ODL_SYSTEM_IP}:6633
    Comment    Execute Command    sudo ifconfig BR2 up
    Comment    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Comment    ${output_2}    Execute Command    sudo ovs-vsctl show
    Comment    Log    ${output_2}
    Comment    ${conn_id_3} =    Open Connection    ${TOOLS_SYSTEM_3_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Comment    Set Global Variable    ${conn_id_3}
    Comment    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Comment    Execute Command    sudo ovs-vsctl add-br BR3
    Comment    Execute Command    sudo ovs-vsctl set bridge BR3 protocols=OpenFlow13
    Comment    Execute Command    sudo ovs-vsctl set-controller BR3 tcp:${ODL_SYSTEM_IP}:6633
    Comment    Execute Command    sudo ifconfig BR3 up
    Comment    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Comment    ${output_3}    Execute Command    sudo ovs-vsctl show
    Comment    Log    ${output_3}
    Comment    ${Dpn_id_List}    Create List
    Comment    : FOR    ${i}    INRANGE    1    ${NUM_TOOLS_SYSTEM} +1
    Comment    \    ${Dpn_id}    Genius.Get Dpn Ids
    Comment    \    Collections.Append To List    ${Dpn_id_List}    ${Dpn_id}
    Comment    \    log    ${Dpn_id_List}
    Genius.Get Dpn Ids
    @{data}    Collections.Combine Lists    ${Dpn_id_List}    ${Bridge_List}
    @{data}    Collections.Combine Lists    @{data}    ${TOOLS_SYSTEM_LIST}
    Set Global Variable    ${data}

Stop Suite
    Log    Stop the tests
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    Switch Connection    ${conn_id_list[${i}]}
    \    Execute Command    sudo ovs-vsctl del-br BR{i}
    \    Execute Command    sudo ovs-vsctl del-manager
    \    Write    exit
    \    close connection
    Comment    Switch Connection    ${conn_id_2}
    Comment    Log    ${conn_id_2}
    Comment    Execute Command    sudo ovs-vsctl del-br BR2
    Comment    Execute Command    sudo ovs-vsctl del-manager
    Comment    Write    exit
    Comment    close connection
    Comment    Switch Connection    ${conn_id_3}
    Comment    Log    ${conn_id_3}
    Comment    Execute Command    sudo ovs-vsctl del-br BR3
    Comment    Execute Command    sudo ovs-vsctl del-manager
    Comment    Write    exit
    Comment    close connection

check establishment
    [Arguments]    ${port}
    [Documentation]    This keyword will check whether ports are established or not on OVS
    ${check_establishment}    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    netstat -anp | grep ${port}
    Should contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Check Service Status
    [Arguments]    ${odl_ip}    ${system_ready_state}    ${service_state}    @{service_list}
    [Documentation]    Issues the karaf shell command showSvcStatus to verify the ready and service states are the same as the arguments passed
    ${service_status_output} =    Run Keyword If    ${NUM_ODL_SYSTEM} > 1    Issue_Command_On_Karaf_Console    showSvcStatus -n ${odl_ip}    ${odl_ip}    ${KARAF_SHELL_PORT}
    ...    ELSE    Issue_Command_On_Karaf_Console    showSvcStatus    ${odl_ip}    ${KARAF_SHELL_PORT}
    Should Contain    ${service_status_output}    ${system_ready_state}
    : FOR    ${service}    IN    @{service_list}
    \    Should Match Regexp    ${service_status_output}    ${service} +: ${service_state}

Create Vteps
    [Arguments]    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between OVS
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_1_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan} =    Set Variable    ${vlan}
    ${gateway-ip} =    Set Variable    ${gateway-ip}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${body}    Genius.Set Json    ${vlan}    ${gateway-ip}    ${subnet}
    ${vtep_body}    Set Variable    ${body}
    Set Global Variable    ${vtep_body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

Set Json
    [Arguments]    ${vlan}    ${gateway-ip}    ${subnet}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    ${body}    replace string    ${body}    "dpn-id": 10${i}    "dpn-id": ${Dpn_id_List[${i}]}
    \    ${body}    replace string    ${body}    "ip-address": "${i+2}.${i+2}.${i+2}.${i+2}"    "ip-address": "${TOOLS_SYSTEM_LIST[${i}]}"
    Comment    ${body}    replace string    ${body}    "dpn-id": 101    "dpn-id": ${Dpn_id1}
    Comment    ${body}    replace string    ${body}    "dpn-id": 102    "dpn-id": ${Dpn_id2}
    Comment    ${body}    replace string    ${body}    "dpn-id": 103    "dpn-id": ${Dpn_id3}
    Comment    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${TOOLS_SYSTEM_IP_1}"
    Comment    ${body}    replace string    ${body}    "ip-address": "3.3.3.3"    "ip-address": "${TOOLS_SYSTEM_IP_2}"
    Comment    ${body}    replace string    ${body}    "ip-address": "4.4.4.4"    "ip-address": "${TOOLS_SYSTEM_IP_3}"
    ${body}    replace string    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Get Dpn Ids
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Comment    Switch connection    ${connection_id}
    Comment    ${cmd}    set Variable    sudo ovs-vsctl show | grep Bridge | awk -F "\\"" '{print $2}'
    Comment    ${Bridgename1}    Execute command    ${cmd}
    Comment    log    ${Bridgename1}
    @{Dpn_id_List}    Create List
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    ${Bridgename1}    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show | grep Bridge | awk -F "\\"" '{print $2}'
    \    ${output1}    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl show -O Openflow13 ${Bridgename1} | head -1 | awk -F "dpid:" '{ print $2 }'
    \    ${Dpn_id}    Utils.Run Command On Remote System And Log    ${tools_ip}    echo \$\(\(16\#${output1}\)\)
    \    Collections.Append To List    ${Dpn_id_List}    ${Dpn_id}
    \    log    ${Dpn_id_List}
    Set Global Variable    ${Dpn_id_List}
    Comment    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    Comment    log    ${Dpn_id}
    [Return]    ${Dpn_id_List}

BFD Suite Stop
    [Documentation]    Run at end of BFD suite
    Delete All Vteps
    Stop Suite

Delete All Vteps
    [Documentation]    This will delete vtep.
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${vtep_body}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    "Before disconnecting CSS with controller"
    ${output} =    Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Wait Until Keyword Succeeds    30    5    Verify All Tunnel Delete on DS

Genius Test Teardown
    [Arguments]    ${data_models}
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_list[${i}]}    ${Bridge_List[${i}]}
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}

ITM Direct Tunnels Start Suite
    [Documentation]    start suite for itm scalability
    ClusterManagement.ClusterManagement_Setup
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Clean_Journals_Data_And_Snapshots_On_List_Or_All
    Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    sed -i -- 's/<itm-direct-tunnels>false/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Setup

ITM Direct Tunnels Stop Suite
    Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    sed -i -- 's/<itm-direct-tunnels>true/<itm-direct-tunnels>false/g' ${GENIUS_IFM_CONFIG_FLAG}
    Genius Suite Teardown

Verify Tunnel Monitoring is on
    [Documentation]    This keyword will get tep:show output and verify tunnel monitoring status
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}

Ovs Verification between Dpn
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    Comment    Switch Connection    ${connection_id}
    Comment    ${check}    Execute Command    sudo ovs-vsctl show
    Comment    Log    ${check}
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_LIST}
    \    Ovs Verification For Each Dpn    ${tools_ip}
    \    Comment    ${check}    Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    \    Comment    Should Contain    ${check}    local_ip="${local}"    remote_ip="${remote-1}"    ${tunnel}
    \    ...    ${tunnel-type}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${subnet}, ${vlan}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}
    @{Itm-no-vlan}    Collections.Combine Lists    @{Itm-no-vlan}    ${data}
    Check For Elements At URI    ${TUNNEL_TRANSPORTZONE}/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Check Tunnel Delete On OVS
    [Arguments]    ${connection-id}    ${tunnel}
    [Documentation]    Verifies the Tunnel is deleted from OVS.
    Switch Connection    ${connection-id}
    ${return} =    Execute Command    sudo ovs-vsctl show
    log    ${return}
    Should Not Contain    ${return}    ${tunnel}
    [Return]    ${return}

Check Table0 Entry For 2 Dpn
    [Arguments]    ${connection_id}    ${Bridgename}    ${port-num1}
    [Documentation]    Checks the Table 0 entry in the OVS when flows are dumped.
    Switch Connection    ${connection_id}
    Log    ${connection_id}
    ${check}    Execute Command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridgename}
    Log    ${check}
    Should Contain    ${check}    in_port=${port-num1}
    [Return]    ${check}

Check ITM Tunnel State
    [Arguments]    ${tunnel1}    ${tunnel2}
    [Documentation]    Verifies the Tunnel is deleted from datastore
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp.content}    ${tunnel1}    ${tunnel2}

Verify Tunnel Status as UP
    [Documentation]    Verify that the number of tunnels are UP
    ${no_of_tunnels}    Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    ${lines_of_State_UP}    Get Lines Containing String    ${no_of_tunnels}    ${STATE_UP}
    ${Actual_Tunnel_Count}    Get Line Count    ${lines_of_State_UP}
    ${Expected_Tunnel_Count}    BuiltIn.Evaluate    ${NUM_TOOLS_SYSTEM}*(${NUM_TOOLS_SYSTEM}-1)
    Should Be Equal As Strings    ${Actual_Tunnel_Count}    ${Expected_Tunnel_Count}

Check System Status
    [Arguments]    @{service_list}
    [Documentation]    This keyword will verify whether all the services are in operational and all nodes are active based on the number of odl systems
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Check Service Status    ${ODL_SYSTEM_${i+1}_IP}    ACTIVE    OPERATIONAL    @{service_list}

Verify Tunnel Status
    [Arguments]    ${tunnel_names}    ${tunnel_status}
    [Documentation]    Verifies if all tunnels in the input, has the expected status(UP/DOWN/UNKNOWN)
    ${tep_result} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    : FOR    ${tunnel}    IN    @{tunnel_names}
    \    ${tep_output} =    String.Get Lines Containing String    ${tep_result}    ${tunnel}
    \    BuiltIn.Should Contain    ${tep_output}    ${tunnel_status}

Get Tunnels On OVS
    [Arguments]    ${connection_id}
    [Documentation]    Retrieves the list of tunnel ports present on OVS
    SSHLibrary.Switch Connection    ${connection_id}
    ${ovs_result} =    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${tunnel_names}    BuiltIn.Create List
    ${tunnels} =    String.Get Lines Matching Regexp    ${ovs_result}    Interface "tun.*"    True
    @{tunnels_list} =    String.Split To Lines    ${tunnels}
    : FOR    ${tun}    IN    @{tunnels_list}
    \    ${tun_list}    BuiltIn.Should Match Regexp    @{tunnels_list}    tun.*\\w
    \    Collections.Append To List    ${tunnel_names}    ${tun_list}
    ${items_in_list} =    BuiltIn.Get Length    ${tunnel_names}
    [Return]    ${Tunnel_Names}

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
    ${dpn_Id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_Id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    Genius.Create Vteps    ${dpn_Id_1}    ${dpn_Id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ${tunnel} =    BuiltIn.Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_Id_1}    ${dpn_Id_2}
    ...    odl-interface:tunnel-type-vxlan
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP    TZA

SRM Stop Suite
    [Documentation]    Stop suite for service recovery.
    Delete All Vteps
    Genius Suite Teardown

Set Bridge
    : FOR    ${i}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    Log    ${conn_id_list[${i}]}
    \    Switch Connection    ${conn_id_list[${i}]}
    \    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    \    Execute Command    sudo ovs-vsctl add-br BR${i}
    \    Execute Command    sudo ovs-vsctl set bridge BR${i} protocols=OpenFlow13
    \    Execute Command    sudo ovs-vsctl set-controller BR${i} tcp:${ODL_SYSTEM_IP}:6633
    \    Execute Command    sudo ifconfig BR${i} up
    \    Execute Command    sudo ovs-vsctl add-port BR${i} tap${i}ed70586-6c -- set Interface tap${i}ed70586-6c type=tap
    \    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    \    Execute Command    sudo ovs-vsctl show

Ovs Verification For Each Dpn
    [Arguments]    ${tools_system_ip}
    ${ovs_output}    Run Command On Remote System And Log    ${tools_system_ip}    sudo ovs-vsctl show
    @{updated_tools_ip_list}    Create List    ${TOOLS_SYSTEM_LIST}
    Remove Values From List    @{updated_tools_ip_list}    ${tools_system_ip}
    Log Many    @{updated_tools_ip_list}
    ${items}    Get Length    @{updated_tools_ip_list}
    : FOR    ${i}    INRANGE    ${items}
    \    ${ip}    Collections.Get From List    @{updated_tools_ip_list}    ${i}
    \    Should Contain    ${ovs_output}    ${ip}
    [Teardown]

Get Tunnels List
    ${no_of_tunnels}    Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    ${tunnels}    Get Regexp Matches    ${no_of_tunnels}    tun[\\w\\d]+
    log    ${tunnels}
    [Return]    ${tunnels}
