*** Settings ***
Documentation     Functional test for bgp.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Library           RequestsLibrary
Library           SSHLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Library           ${CURDIR}/../../../libraries/norm_json.py
Library           ${CURDIR}/../../../libraries/BgpRpcClient.py        ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot

*** Variables ***
${HOLDTIME}       180
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${APP_PEER_NAME}   example-bgp-peer-app
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${MULT_VAR_FOLDER}     ${BGP_VAR_FOLDER}/multipaths
${DEFAUTL_RPC_CFG}     exa.cfg
${CONFIG_SESSION}      config-session
${EXARPCSCRIPT}    ${CURDIR}/../../../scripts/exarpc.py
${TWO_PATHS}      2
&{DEFAULT_MAPPING}   ODLIP=${ODL_SYSTEM_IP}   EXAIP=${TOOLS_SYSTEM_IP}      NPATHS=${TWO_PATHS}
@{PATH_ID_LIST}    1     2      3
${PATH_ID_LIST_LEN}     3
${NEXT_HOP_PREF}     100.100.100.
${RIB_URI}    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-bgp-rib-impl-cfg:rib-impl/example-bgp-rib
${PEER_CHECK_URL}     /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F
${NPATHS_SELM}      n-paths
${ALLPATHS_SELM}     all-paths
${ADDPATHCAP_SR}     send\\/receive
${ADDPATHCAP_S}     send
${ADDPATHCAP_R}     receive
${ADDPATHCAP_D}     disable

*** Test Cases ***
Configure_App_Peer_With_Routes
    [Documentation]    Configure bgp application peer
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}   APP_PEER_ID=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    : FOR    ${pathid}    IN    @{PATH_ID_LIST} 
    \    &{route_mapping}     BuiltIn.Create_Dictionary     NEXTHOP=${NEXT_HOP_PREF}${pathid}     LOCALPREF=${pathid}00    PATHID=${pathid}
    \    TemplatedRequests.Post_As_Xml_Templated    ${MULT_VAR_FOLDER}/route    mapping=${route_mapping}    session=${CONFIG_SESSION}


Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}


Odl Allpaths Exa SendReceived
    [Documentation]    all-paths selected policy selected
    [Setup]     Configure_Path_Sellection_And_Connect_Peer       ${ALLPATHS_SELM}     ${ADDPATHCAP_SR}
    Log_Loc_Rib_Operational
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s     Verify_Expected_Update_Count     ${PATH_ID_LIST_LEN}
    [Teardown]     Stop_Tool


Odl Npaths Exa SendReceived
    [Documentation]    n-paths policy selected on odl
    [Setup]     Configure_Path_Sellection_And_Connect_Peer       ${NPATHS_SELM}     ${ADDPATHCAP_SR}
    Log_Loc_Rib_Operational
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s     Verify_Expected_Update_Count     ${TWO_PATHS}
    [Teardown]     Stop_Tool

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{route_mapping}    BuiltIn.Create_Dictionary
    TemplatedRequests.Delete_Templated    ${MULT_VAR_FOLDER}/route    mapping=${route_mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True$
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    sudo pip install exabgp==3.4.16    return_stdout=True    return_stderr=True
    ...    return_rc=True
    RequestsLibrary.Create_Session   ${CONFIG_SESSION}     http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files
    Configure_Odl_With_Multipaths

Stop_Suite
    [Documentation]    Suite teardown keyword
    #restore old rib
    TemplatedRequests.Put_As_Xml_To_Uri    ${RIB_URI}   ${rib_old}    session=${CONFIG_SESSION}
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Upload_Config_Files
    [Arguments]        ${addpath}=disable
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

Configure_Path_Sellection_And_Connect_Peer
    [Arguments]     ${odl_path_sel_mode}      ${exa_add_path_value}
    [Documentation]    Setup test case keyword
    KarafKeywords.Log Testcase Start To Controller Karaf
    Configure_Path_Selection_Mode     ${odl_path_sel_mode}
    Upload_Config_Files     addpath=${exa_add_path_value}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s   Start_Tool_And_Verify_Connected    ${DEFAUTL_RPC_CFG}

Get_New_Config_File
    [Arguments]   ${cfg_template_file}     ${mapping}={}     ${new_cfg_name}=cfg.cfg
    [Documentation]     Returns a new config file from template
    ${cfg_content}=    TemplatedRequests.Resolve_Text_From_Template_File    ${cfg_template}      ${mapping}
    SSHLibrary.Execute_Command    echo  ${cfg_content} > ${new_cfg_name}
    [Return]     ${new_cfg_name}

Start_Tool
    [Arguments]    ${cfg_file}      ${mapping}={}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    BuiltIn.Log    ${cmd} ${cfg_file}
    ${output}=    SSHLibrary.Write    ${cmd} ${cfg_file}
    BuiltIn.Log    ${output}

Verify_Tools_Connection
    [Arguments]     ${connected}=${True}
    ${exp_status_code}=      BuiltIn.Set_Variable_If   ${connected}     ${200}      ${404}
    ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${PEER_CHECK_URL}${TOOLS_SYSTEM_IP}
    BuiltIn.Log    ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${rsp.status_code}

Start_Tool_And_Verify_Connected
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    Start_Tool    ${cfg_file}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    3s    Verify_Tools_Connection     connected=${True}
    
Stop_Tool
    [Documentation]    Stop the tool if still running.
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

Verify_Expected_Update_Count
    [Arguments]     ${exp_count}
    ${tool_count}=     BgpRpcClient.exa_get_received_update_count
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_count}       ${tool_count}

Configure_Path_Selection_Mode
    [Arguments]     ${psm}
    &{mapping}      BuiltIn.Create_Dictionary    PATHSELMODE=${psm}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_psm    mapping=${mapping}    session=${CONFIG_SESSION}

Configure_Odl_With_Multipaths
    [Documentation]    Configures odl to support n-paths or all-paths selection
    ${mapping}=     BuiltIn.Set Variable      ${DEFAULT_MAPPING}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_n_paths    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_all_paths    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/service_psmf    mapping=${mapping}    session=${CONFIG_SESSION}
    Configure_Path_Selection_Mode     n-paths
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/service_bpsm    mapping=${mapping}    session=${CONFIG_SESSION}
    ${rib_old}=    TemplatedRequests.Get_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Set_Suite_Variable    ${rib_old}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib    mapping=${mapping}    session=${CONFIG_SESSION}

Log_Loc_Rib_Operational
     ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/
     BuiltIn.Log    ${rsp.content}

