*** Settings ***
Documentation     This suite is a common keywords file for genius project.
Library           Collections
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

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../variables/genius
${Bridge-1}       BR1
${Bridge-2}       BR2
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
@{DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE

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
    Run_Keyword_If_At_Least_Oxygen    Wait Until Keyword Succeeds    60    2    Check System Status
    Log    Start the tests
    : FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM}
    \    ${conn_id_${i}} =    Open Connection    ${TOOLS_SYSTEM_${i}_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    \    Set Global Variable    ${conn_id_${i}}
    KarafKeywords.Setup_Karaf_Keywords
    Comment    ${conn_id_1} =    Open Connection    ${TOOLS_SYSTEM_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Comment    Set Global Variable    ${conn_id_1}
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius
    : FOR    ${i}    INRANGE    ${NUM_TOOLS_SYSTEM}
    \    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    \    Execute Command    sudo ovs-vsctl add-br BR${i}
    \    Execute Command    sudo ovs-vsctl set bridge BR${i} protocols=OpenFlow13
    \    Execute Command    sudo ovs-vsctl set-controller BR${i} tcp:${ODL_SYSTEM_IP}:6633
    \    Execute Command    sudo ifconfig BR${i} up
    \    Execute Command    sudo ovs-vsctl add-port BR${i} tap8ed70586-6c -- set Interface tap8ed70586-6c type=tap
    \    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    \    Execute Command    sudo ovs-vsctl show
    Comment    Log    ${output_1}
    ${check}    Wait Until Keyword Succeeds    30    10    check establishment    ${conn_id_1}    6633
    log    ${check}
    ${check_2}    Wait Until Keyword Succeeds    30    10    check establishment    ${conn_id_1}    6640
    log    ${check_2}
    Log    >>>>>Switch 2 configuration <<<<<
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

Stop Suite
    Log    Stop the tests
    Switch Connection    ${conn_id_1}
    Log    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR1
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit
    close connection
    Switch Connection    ${conn_id_2}
    Log    ${conn_id_2}
    Execute Command    sudo ovs-vsctl del-br BR2
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit
    close connection
    Switch Connection    ${conn_id_3}
    Log    ${conn_id_3}
    Execute Command    sudo ovs-vsctl del-br BR3
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit
    close connection

check establishment
    [Arguments]    ${conn_id}    ${port}
    Switch Connection    ${conn_id}
    ${check_establishment}    Execute Command    netstat -anp | grep ${port}
    Should contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Check Service Status
    [Arguments]    ${odl_ip}    ${system_ready_state}    ${service_state}
    [Documentation]    Issues the karaf shell command showSvcStatus to verify the ready and service states are the same as the arguments passed
    ${service_status_output}    Issue_Command_On_Karaf_Console    showSvcStatus    ${odl_ip}    8101
    Should Contain    ${service_status_output}    ${system_ready_state}
    : FOR    ${service}    IN    @{DIAG_SERVICES}
    \    Should Match Regexp    ${service_status_output}    ${service} +: ${service_state}

Create Vteps
    [Arguments]    ${Dpn_id1}    ${Dpn_id2}    ${Dpn_id3}    ${TOOLS_SYSTEM_IP_1}    ${TOOLS_SYSTEM_IP_2}    ${TOOLS_SYSTEM_IP_3}
    ...    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_1_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan} =    Set Variable    ${vlan}
    ${gateway-ip} =    Set Variable    ${gateway-ip}
    ${body}    Genius.Set Json    ${Dpn_id1}    ${Dpn_id2}    ${Dpn_id3}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}
    ...    ${TOOLS_SYSTEM_3_IP}    ${vlan}    ${gateway-ip}    ${subnet}
    ${vtep_body}    Set Variable    ${body}
    Set Global Variable    ${vtep_body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

Set Json
    [Arguments]    ${Dpn_id1}    ${Dpn_id2}    ${Dpn_id3}    ${TOOLS_SYSTEM_IP_1}    ${TOOLS_SYSTEM_IP_2}    ${TOOLS_SYSTEM_IP_3}
    ...    ${vlan}    ${gateway-ip}    ${subnet}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id": 101    "dpn-id": ${Dpn_id1}
    ${body}    replace string    ${body}    "dpn-id": 102    "dpn-id": ${Dpn_id2}
    ${body}    replace string    ${body}    "dpn-id": 103    "dpn-id": ${Dpn_id3}
    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${TOOLS_SYSTEM_IP_1}"
    ${body}    replace string    ${body}    "ip-address": "3.3.3.3"    "ip-address": "${TOOLS_SYSTEM_IP_2}"
    ${body}    replace string    ${body}    "ip-address": "4.4.4.4"    "ip-address": "${TOOLS_SYSTEM_IP_3}"
    ${body}    replace string    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Get Dpn Ids
    [Arguments]    ${connection_id}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl show | grep Bridge | awk -F "\\"" '{print $2}'
    ${Bridgename1}    Execute command    ${cmd}
    log    ${Bridgename1}
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${Bridgename1} | head -1 | awk -F "dpid:" '{ print $2 }'
    log    ${output1}
    # "echo \$\(\(16\#${output1}\)\) command below converts ovs dpnid (i.e., output1) from hexadecimal to decimal."
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    log    ${Dpn_id}
    [Return]    ${Dpn_id}

BFD Suite Stop
    [Documentation]    Run at end of BFD suite
    Delete All Vteps
    Stop Suite

Delete All Vteps
    [Documentation]    This will delete vtep.
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${vtep_body}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    "Before disconnecting CSS with controller"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}

Genius Test Teardown
    [Arguments]    ${data_models}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    BR1
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    BR2
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

Ovs Verification For 2 Dpn
    [Arguments]    ${connection_id}    ${local}    ${remote-1}    ${tunnel}    ${tunnel-type}
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    Switch Connection    ${connection_id}
    ${check}    Execute Command    sudo ovs-vsctl show
    Log    ${check}
    Should Contain    ${check}    local_ip="${local}"    remote_ip="${remote-1}"    ${tunnel}    ${tunnel-type}
    [Return]    ${check}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}
    ...    ${TOOLS_SYSTEM_2_IP}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${subnet}, ${vlan}, ${Dpn_id_1},${TOOLS_SYSTEM_IP}, ${Dpn_id_2}, ${TOOLS_SYSTEM_2_IP}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${Bridge-2}-eth1    ${TOOLS_SYSTEM_2_IP}
    Check For Elements At URI    ${TUNNEL_TRANSPORTZONE}/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Check Tunnel Delete On OVS
    [Arguments]    ${connection-id}    ${tunnel}
    [Documentation]    Verifies the Tunnel is deleted from OVS
    Switch Connection    ${connection-id}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
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
    [Arguments]    ${Transport_zone}
    [Documentation]    Verify that the number of tunnels are UP
    ${No_of_Teps}    Issue_Command_On_Karaf_Console    ${TEP_SHOW}
    ${Lines_of_TZA}    Get Lines Containing String    ${No_of_Teps}    ${Transport_zone}
    ${Expected_Node_Count}    Get Line Count    ${Lines_of_TZA}
    ${no_of_tunnels}    Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    ${lines_of_VXLAN}    Get Lines Containing String    ${no_of_tunnels}    VXLAN
    Should Contain    ${no_of_tunnels}    ${STATE_UP}
    Should Not Contain    ${no_of_tunnels}    ${STATE_DOWN}
    Should Not Contain    ${no_of_tunnels}    ${STATE_UNKNOWN}
    ${Actual_Tunnel_Count}    Get Line Count    ${lines_of_VXLAN}
    ${Expected_Tunnel_Count}    Set Variable    ${Expected_Node_Count*${Expected_Node_Count - 1}}
    Should Be Equal As Strings    ${Actual_Tunnel_Count}    ${Expected_Tunnel_Count}

Check System Status
    [Documentation]    This keyword will verify whether all the services are in operational and all nodes are active based on the number of odl systems
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Check Service Status    ${ODL_SYSTEM_${i+1}_IP}    ACTIVE    OPERATIONAL
