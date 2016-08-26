*** Settings ***
Documentation     BGP functional HA testing with one exabgp peer.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses exabgp. It is configured to have 3 peers (all 3 nodes of odl).
...               Bgp implemented with singleton accepts only one incomming conection. Exabgp
...               logs will show that one peer will be connected and two will fail.
...               After killing karaf which owned connection new owner should be elected and
...               this new owner should accept incomming bgp connection.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpclustering
${BGP_PEER_FOLDER}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer
${DEFAUTL_EXA_CFG}    exa.cfg
${EXA_CMD}        env exabgp.tcp.port=1790 exabgp
${PEER_CHECK_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F
${DEVICE_NAME}    peer-controller-config
${NETCONF_DEV_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-device
${NETCONF_MOUNT_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-mount
${HOLDTIME}       180
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib

*** Test Cases ***
Get Example Bgp Rib Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${rib_owner}    ${rib_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set Suite variable    ${rib_owner}    ${rib_owner}
    BuiltIn.Set Suite variable    ${rib_owner_node_id}    ${ODL_SYSTEM_${rib_owner}_IP}
    BuiltIn.Set Suite variable    ${rib_candidates}    ${rib_candidates}
    ${session}=    Resolve_Http_Session_For_Member    member_index=${rib_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${rib_owner}

Configure_Netconf_Device
    [Documentation]    Configures and verifies netconf device configuration. If configuration is not successful, it de-configures the device before the next attempt.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    DEVICE_PORT=1830    DEVICE_IP=${rib_owner_node_id}    DEVICE_USER=admin    DEVICE_PASSWORD=admin
    # After the netconf device is configured, odl starts downloading schemas. If the downloading will not finish within akka timeout, more tries are needed, 3 is based on a user experience.
    : FOR    ${index}    IN RANGE    0    3
    \    ${status}    ${value}=    Run Keyword And Ignore Error    Configure Netconf Device And Check Mounted    ${mapping}
    \    Exit For Loop If    '${status}' == 'PASS'
    \    Run Keyword Unless    '${status}' == 'PASS'    TemplatedRequests.Delete_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${living_session}
    Run Keyword Unless    '${status}' == 'PASS'    Fail

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Json_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${living_session}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_ExaBgp_Peer
    [Documentation]    Starts exabgp
    Start_Tool    ${DEFAUTL_EXA_CFG}

Verify ExaBgp Connected
    [Documentation]    Verifies exabgp's presence in operational ds.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Tools_Connection    ${living_session}

Stop_Current_Owner_Member
    [Documentation]    Stopping karaf which is connected with exabgp.
    Kill_Single_Member    ${rib_owner}
    BuiltIn.Set Suite variable    ${odl_rib_owner}    ${rib_owner}
    BuiltIn.Set Suite variable    ${odl_rib_candidates}    ${rib_candidates}
    ${idx}=    Collections.Get From List    ${odl_rib_candidates}    0
    ${session}=    Resolve_Http_Session_For_Member    member_index=${idx}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Verify_New_Rib_Owner
    [Documentation]    Verifies if new owner of example-bgp-rib is elected.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_New_Rib_Owner_Elected    ${odl_rib_owner}    ${living_node}

Verify_ExaBgp_Reconnected
    [Documentation]    Verifies exabgp's presence in operational ds.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Tools_Connection    ${living_session}

Start_Stopped_Member
    [Documentation]    Starting stopped node
    Start_Single_Member    ${odl_rib_owner}

Verify_New_Candidate
    [Documentation]    Verifies started node become candidate for example-bgp-rib
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    Verify_New_Rib_Candidate_Present    ${odl_rib_owner}    ${living_node}

Verify ExaBgp Still Connected
    [Documentation]    Verifies exabgp's presence in operational ds
    Verify_Tools_Connection    ${living_session}

Stop_ExaBgp_Peer
    [Documentation]    Stops exabgp
    Stop_Tool

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ${session}=    Resolve_Http_Session_For_Member    member_index=${odl_rib_owner}
    TemplatedRequests.Delete_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${session}

Delete_Netconf_Device_Configuration
    [Documentation]    Revert the netconf configuration to the original stat
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    DEVICE_PORT=1830    DEVICE_IP=${rib_owner_node_id}    DEVICE_USER=admin    DEVICE_PASSWORD=admin
    ${session}=    Resolve_Http_Session_For_Member    member_index=${odl_rib_owner}
    TemplatedRequests.Delete_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${session}

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    Utils.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    Upload_Config_Files

Teardown_Everything
    [Documentation]    Suite cleanup
    SSHKeywords.Virtual_Env_Delete
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Configure Netconf Device And Check Mounted
    [Arguments]    ${mapping}
    [Documentation]    Configures netconf device and checks mountpoint presence
    TemplatedRequests.Put_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${living_session}
    BuiltIn.Wait Until Keyword Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_MOUNT_FOLDER}    mapping=${mapping}    session=${living_session}

Start_Tool
    [Arguments]    ${cfg_file}    ${mapping}={}
    [Documentation]    Starts the tool
    ${start_cmd}    BuiltIn.Set_Variable    ${EXA_CMD} ${cfg_file}
    BuiltIn.Log    ${start_cmd}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    ${output}=    SSHLibrary.Write    ${start_cmd}
    BuiltIn.Log    ${output}

Stop_Tool
    [Documentation]    Stops the tool by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session    log_output=${True}

Upload_Config_Files
    [Documentation]    Uploads exabgp config files.
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${DEFAUTL_EXA_CFG}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP1/${ODL_SYSTEM_1_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP2/${ODL_SYSTEM_2_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP3/${ODL_SYSTEM_3_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}

Verify_New_Rib_Owner_Elected
    [Arguments]    ${old_owner}    ${node_to_ask}
    [Documentation]    Verifies new owner was elected
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Should_Not_Be_Equal    ${old_owner}    ${owner}

Verify_New_Rib_Candidate_Present
    [Arguments]    ${candidate}    ${node_to_ask}
    [Documentation]    Verifies candidate's presence.
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Should_Contain    ${candidates}    ${candidate}

Verify_Tools_Connection
    [Arguments]    ${session}    ${connected}=${True}
    [Documentation]    Checks peer presence in operational datastore
    ${exp_status_code}=    BuiltIn.Set_Variable_If    ${connected}    ${200}    ${404}
    ${rsp}=    RequestsLibrary.Get Request    ${session}    ${PEER_CHECK_URL}${TOOLS_SYSTEM_IP}
    BuiltIn.Log    ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${rsp.status_code}
