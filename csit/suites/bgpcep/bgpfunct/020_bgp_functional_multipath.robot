*** Settings ***
Documentation     Functional test suite for bgp - n-path and all-path selection
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests n-path and all-path selection policy.
...               It uses odl and exabgp as bgp peers. Routes advertized from odl
...               are configured via application peer.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/ExaBgpLib.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Library           ${CURDIR}/../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot

*** Variables ***
${HOLDTIME}       180
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${APP_PEER_NAME}    example-bgp-peer-app
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${MULT_VAR_FOLDER}    ${BGP_VAR_FOLDER}/multipaths
${DEFAUTL_RPC_CFG}    exa.cfg
${CONFIG_SESSION}    config-session
${EXARPCSCRIPT}    ${CURDIR}/../../../../tools/exabgp_files/exarpc.py
${N_PATHS_VALUE}    2
&{DEFAULT_MAPPING}    ODLIP=${ODL_SYSTEM_IP}    EXAIP=${TOOLS_SYSTEM_IP}    NPATHS=${N_PATHS_VALUE}
@{PATH_ID_LIST}    1    2    3
${PATH_ID_LIST_LEN}    3
${NEXT_HOP_PREF}    100.100.100.
${RIB_URI}        /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-bgp-rib-impl-cfg:rib-impl/example-bgp-rib
${OPENCONFIG_RIB_URI}    /restconf/config/openconfig-network-instance:network-instances/network-instance/global-bgp/openconfig-network-instance:protocols/protocol/openconfig-policy-types:BGP/example-bgp-rib
${NPATHS_SELM}    n-paths
${ALLPATHS_SELM}    all-paths
${ADDPATHCAP_SR}    send\\/receive
${ADDPATHCAP_S}    send
${ADDPATHCAP_R}    receive
${ADDPATHCAP_D}    disable

*** Test Cases ***
Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    PASSIVE_MODE=true

Odl Allpaths Exa SendReceived
    [Documentation]    all-paths selected policy selected
    [Tags]    critical
    [Setup]    Configure_Path_Selection_And_App_Peer_And_Connect_Peer    ${ALLPATHS_SELM}    ${ADDPATHCAP_SR}
    Log_Loc_Rib_Operational
    BuiltIn.Wait_Until_Keyword_Succeeds    6x    2s    Verify_Expected_Update_Count    ${PATH_ID_LIST_LEN}
    [Teardown]    Remove_Odl_And_App_Peer_Configuration_And_Stop_ExaBgp

Odl Npaths Exa SendReceived
    [Documentation]    n-paths policy selected on odl
    [Tags]    critical
    [Setup]    Configure_Path_Selection_And_App_Peer_And_Connect_Peer    ${NPATHS_SELM}    ${ADDPATHCAP_SR}
    Log_Loc_Rib_Operational
    BuiltIn.Wait_Until_Keyword_Succeeds    6x    2s    Verify_Expected_Update_Count    ${N_PATHS_VALUE}
    [Teardown]    Remove_Odl_And_App_Peer_Configuration_And_Stop_ExaBgp

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files
    Store_Rib_Configuration

Stop_Suite
    [Documentation]    Suite teardown keyword with old rib restoration
    SSHKeywords.Virtual_Env_Delete
    TemplatedRequests.Put_As_Xml_To_Uri    ${OPENCONFIG_RIB_URI}    ${rib_old}    session=${CONFIG_SESSION}
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Upload_Config_Files
    [Arguments]    ${addpath}=disable
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${DEFAUTL_RPC_CFG}    .
    SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/enable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/${addpath}/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}

Configure_Path_Selection_And_App_Peer_And_Connect_Peer
    [Arguments]    ${odl_path_sel_mode}    ${exa_add_path_value}
    [Documentation]    Setup test case keyword. Early after the path selection config the incomming connection
    ...    from exabgp towards odl may be rejected by odl due to config process not finished yet. Because of that
    ...    we try to start the tool 3 times in case early attempts fail.
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Configure_Odl_Peer_With_Path_Selection_Mode    ${odl_path_sel_mode}
    Configure_App_Peer_With_Routes
    Upload_Config_Files    addpath=${exa_add_path_value}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${DEFAUTL_RPC_CFG}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}    connection_retries=${3}

Remove_Odl_And_App_Peer_Configuration_And_Stop_ExaBgp
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${MULT_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    Deconfigure_App_Peer
    ExaBgpLib.Stop_ExaBgp
    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Verify_Expected_Update_Count
    [Arguments]    ${exp_count}
    [Documentation]    Verify number of received update messages
    ${tool_count}=    BgpRpcClient.exa_get_received_update_count
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_count}    ${tool_count}

Configure_Path_Selection_Mode
    [Arguments]    ${psm}
    [Documentation]    Configure path selection mode and get rib information for potential debug purposes
    &{mapping}    BuiltIn.Create_Dictionary    PATHSELMODE=${psm}
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    TemplatedRequests.Get_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib    mapping=${mapping}    session=${CONFIG_SESSION}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    TemplatedRequests.Get_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib_policies    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_psm    mapping=${mapping}    session=${CONFIG_SESSION}

Configure_Odl_Peer_With_Path_Selection_Mode
    [Arguments]    ${psm}
    [Documentation]    Configures odl peer with path selection mode
    ${npaths}=    BuiltIn.Set_Variable_If    "${psm}"=="${ALLPATHS_SELM}"    0    ${N_PATHS_VALUE}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true    MULTIPATH=${npaths}
    ...    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Configure_Odl_With_Multipaths
    [Documentation]    Configures odl to support n-paths or all-paths selection
    ${mapping}=    BuiltIn.Set Variable    ${DEFAULT_MAPPING}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_n_paths    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_all_paths    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/service_psmf    mapping=${mapping}    session=${CONFIG_SESSION}
    Configure_Path_Selection_Mode    n-paths
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/service_bpsm    mapping=${mapping}    session=${CONFIG_SESSION}
    Store_Rib_Configuration
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib    mapping=${mapping}    session=${CONFIG_SESSION}

Store_Rib_Configuration
    [Documentation]    Stores rib configuration
    ${rib_old}=    TemplatedRequests.Get_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib    mapping=${DEFAULT_MAPPING}    session=${CONFIG_SESSION}
    BuiltIn.Set_Suite_Variable    ${rib_old}

Log_Loc_Rib_Operational
    ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/
    BuiltIn.Log    ${rsp.content}

Configure_App_Peer_With_Routes
    [Documentation]    Configure bgp application peer and fill it immediately with routes.
    ${app_rib}    Set Variable    ${ODL_SYSTEM_IP}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    APP_PEER_ID=${ODL_SYSTEM_IP}    IP=${ODL_SYSTEM_IP}
    ...    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    : FOR    ${pathid}    IN    @{PATH_ID_LIST}
    \    &{route_mapping}    BuiltIn.Create_Dictionary    NEXTHOP=${NEXT_HOP_PREF}${pathid}    LOCALPREF=${pathid}00    PATHID=${pathid}    APP_RIB=${app_rib}
    \    TemplatedRequests.Post_As_Xml_Templated    ${MULT_VAR_FOLDER}/route    mapping=${route_mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    ${app_rib}    Set Variable    ${ODL_SYSTEM_IP}
    &{route_mapping}    BuiltIn.Create_Dictionary    APP_RIB=${app_rib}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${MULT_VAR_FOLDER}/route    mapping=${route_mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    IP=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
