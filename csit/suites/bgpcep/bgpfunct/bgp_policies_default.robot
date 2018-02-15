*** Settings ***
Documentation     Functional test for bgp routing policies
...
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses 7 peers: app peer, 2x rr-client, 2x ebgp, 2x ibgp
...               Tests results on effective-rib-in dependant on their respective configurations.
...               Peers 1,2,4,5 are testing multiple ipv4 routes with additional arguments.
...               Peers 3,6 have ipv4 and ipv6 mpls-labeled routes.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/ExaBgpLib.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SSHKeywords.robot

*** Variables ***
${POLICIES_VAR}    ${CURDIR}/../../../variables/bgpfunctional/bgppolicies
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
@{PEER_TYPES}     ibgp_peer    ibgp_peer    ebgp_peer    ebgp_peer    rr_client_peer    rr_client_peer
@{NUMBERS}        1    2    3    4    5    6
${HOLDTIME}       180
${RIB_INSTANCE}    example-bgp-rib
${CONFIG_SESSION}    config-session

*** Test Cases ***
Verify_Rib_Empty
    [Documentation]    Checks empty example-ipv4-topology ready.
    Verify_Rib_Status_Empty

Configure_App_Peer
    [Documentation]    Configures bgp application peer, and configures it's routes.
    &{mapping}    BuiltIn.Create_Dictionary    RIB_INSTANCE_NAME=${RIB_INSTANCE}    APP_PEER_ID=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Post_As_Xml_Templated    ${POLICIES_VAR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Post_As_Xml_Templated    ${POLICIES_VAR}/app_peer_route    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false.
    ...    Configures 6 different peers, two internal, two external and two route-reflectors.
    : FOR    ${index}    ${peer_type}    IN ZIP    ${NUMBERS}    ${PEER_TYPES}
    \    &{mapping}    Create Dictionary    IP=127.0.0.${index}    HOLDTIME=${HOLDTIME}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    \    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    \    TemplatedRequests.Put_As_Xml_Templated    ${POLICIES_VAR}${/}${peer_type}    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Exabgps
    [Documentation]    Start 6 exabgps as processes in background, each with it's own configuration.
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    : FOR    ${index}    IN    @{NUMBERS}
    \    ${start_cmd}    BuiltIn.Set_Variable    ${CMD} exabgp${index}.cfg > exa${index}.log &
    \    BuiltIn.Log    ${start_cmd}
    \    ${output}    SSHLibrary.Write    ${start_cmd}
    \    BuiltIn.Log    ${output}

Verify_Rib_Filled
    [Documentation]    Verifies that sent routes are present in particular ribs.
    [Tags]    critical
    Verify_Rib_Status

Stop_All_Peers
    [Documentation]    Send command to kill all exabgp processes running on controller
    ExaBgpLib.Stop_All_ExaBgps
    : FOR    ${index}    IN    @{NUMBERS}
    \    BGPcliKeywords.Store_File_To_Workspace    exa${index}.log    exa${index}.log

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    : FOR    ${index}    ${peer_type}    IN ZIP    ${NUMBERS}    ${PEER_TYPES}
    \    &{mapping}    Create Dictionary    IP=127.0.0.${index}    HOLDTIME=${HOLDTIME}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    \    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    \    TemplatedRequests.Delete_Templated    ${POLICIES_VAR}/${peer_type}    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    BuiltIn.Create_Dictionary    IP=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${POLICIES_VAR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Delete_Templated    ${POLICIES_VAR}/app_peer_route    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=10s
    Builtin.Set_Suite_Variable    ${conn_id}
    SSHKeywords.Flexible_Controller_Login
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==4.0.5
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Verify_Rib_Status
    [Documentation]    Verify output from effective-rib-in for each of the 6 exabgp peers and app peer.
    ...    First request is for full example-bgp-rib and it's output is logged for debug purposes.
    ...    Each of the peers have different output which is stored in folder by their respective
    ...    numbers as peer_${index} (peer_1, peer_2 ...)
    # gets and outputs full rib output for debug purposes if one of the peers reports faulty data.
    ${output}    TemplatedRequests.Get_As_Json_Templated    ${POLICIES_VAR}/rib_state    session=${CONFIG_SESSION}
    BuiltIn.Log    ${output}
    : FOR    ${index}    IN    @{NUMBERS}
    \    &{mapping}    BuiltIn.Create_Dictionary    IP=127.0.0.${index}
    \    BuiltIn.Wait_Until_Keyword_Succeeds    5x    3s    TemplatedRequests.Get_As_Json_Templated    ${POLICIES_VAR}/effective_rib_in/peer_${index}    mapping=${mapping}
    \    ...    session=${CONFIG_SESSION}    verify=True
    &{mapping}    BuiltIn.Create_Dictionary    IP=${ODL_SYSTEM_IP}
    # application peer verification
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    3s    TemplatedRequests.Get_As_Json_Templated    ${POLICIES_VAR}/app_peer_rib    mapping=${mapping}    session=${CONFIG_SESSION}
    ...    verify=True

Verify_Rib_Status_Empty
    [Documentation]    Checks that example-ipv4-topology is ready, and therefore full rib is ready to be configured.
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    3s    TemplatedRequests.Get_As_Json_Templated    ${POLICIES_VAR}/topology_state    session=${CONFIG_SESSION}    verify=True

Upload_Config_Files
    [Documentation]    Uploads exabgp config files and replaces variables within those
    ...    config files with desired values.
    : FOR    ${index}    IN    @{NUMBERS}
    \    SSHLibrary.Put_File    ${POLICIES_VAR}/exabgp_configs/exabgp${index}.cfg    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}
