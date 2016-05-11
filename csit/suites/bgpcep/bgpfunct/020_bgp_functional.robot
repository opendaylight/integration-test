*** Settings ***
Documentation     Functional test for bgp.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start Suite
Suite Teardown    Stop Suite
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
#${CMD}            source ~/osctestenv/bin/activate; env exabgp.tcp.port=1790 exabgp --debug
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${MULT_VAR_FOLDER}     ${BGP_VAR_FOLDER}/multipaths
${DEFAUTL_RPC_CFG}     exa.cfg
${CONFIG_SESSION}      config-session
${EXARPCSCRIPT}    ${CURDIR}/../../../scripts/exarpc.py
${JOLOKURL}    /jolokia/read/org.opendaylight.controller:instanceName=${BGP_PEER_NAME},type=RuntimeBean,moduleFactoryName=bgp-peer
&{DEFAULT_MAPPING}   ODLIP=${ODL_SYSTEM_IP}   EXAIP=${TOOLS_SYSTEM_IP}    MULTIPATH=disable    ADDPATH=disable
@{PATH_PREF_LIST}    50      100      200
${NEXT_HOP_PREF}     100.100.100.
${rib_uri}    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-bgp-rib-impl-cfg:rib-impl/example-bgp-rib

*** Test Cases ***
Configure_App_Peer_With_Routes
    [Documentation]    Configure bgp application peer
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}   APP_PEER_ID=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    : FOR    ${pref}    IN    @{PATH_PREF_LIST} 
    \    &{route_mapping}     Create Dictionary     NEXTHOP=${NEXT_HOP_PREF}${pref}     LOCALPREF=${pref}
    \    TemplatedRequests.Post_As_Xml_Templated    ${MULT_VAR_FOLDER}/route    mapping=${route_mapping}    session=${CONFIG_SESSION}


Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}


#Multipath Odl Disabled Exa Disabled
#    [Documentation]    Bla Bla Bla
#    [Setup]     Setup Tc Odl Settings And App Peer
#    Check Loc Rib Content   <params>
#    ${cfg_file}=     Get Config File    <params>
#    Start Exabgp Tool
#    Check Exabgps Data
#    [Teardown]     Teardown Tc Odl Settings And App Peer


#Multipath Odl Send Exa Disabled
#    [Documentation]    blabla
#    Fail



#Multipath Odl Allpath Exa Disabled


#dd1) configure odl with capabilities
#2) configure application rib
#33) configure routes into application rib

#connect exabgp
#check counters

#3)
#2)
#1)

Sleep Test
     Sleep     1s


Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{route_mapping}    Create Dictionary
    TemplatedRequests.Delete_Templated    ${MULT_VAR_FOLDER}/route    mapping=${route_mapping}    session=${CONFIG_SESSION}
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
#Setup Tc Odl Settings And App Peer
#1) configure odl with capabilities
#2) configure application rib
#3) configure routes into application rib

#Teardown Tc Odl Settings And App Peer
#3)
#2)
#1)

#Setup Tc Odl Settings And App Peer


Start Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True$
    #${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    #...    return_rc=True
    #${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo pip install exabgp==3.4.16    return_stdout=True    return_stderr=True
    #...    return_rc=True
    RequestsLibrary.Create Session   ${CONFIG_SESSION}     http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    #Upload Config Files
    Configure Odl With Multipaths

Stop Suite
    [Documentation]    Suite teardown keyword
    #restore old rib
    TemplatedRequests.Put_As_Xml_To_Uri    ${rib_uri}   ${rib_old}    session=${CONFIG_SESSION}
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Upload Config Files
    [Arguments]     ${bla}
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put File    ${BGP_VARIABLES_FOLDER}/${DEFAUTL_RPC_CFG}    .
    SSHLibrary.Put File    ${BGP_VARIABLES_FOLDER}/l3vpn_ipv4/${L3VPN_CFG}    .
    SSHLibrary.Put File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List Files In Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute Command    sed -i -e 's/ROUTEREFRESH/enable/g' ${cfgfile}
    \    SSHLibrary.Execute Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute Command    cat ${cfgfile}
    \    Log    ${stdout}

Setup Testcase
    [Arguments]    ${cfg_file}    ${url}    ${empty_response}
    Verify Reported Data     ${url}    ${empty_response}
    Start Tool    ${cfg_file}

Get New Config File
    [Arguments]   ${cfg_template_file}     ${mapping}={}     ${new_cfg_name}=cfg.cfg
    [Documentation]     Returns a new config file from template
    ${cfg_content}=    TemplatedRequests.Resolve_Text_From_Template_File    ${cfg_template}      ${mapping}
    SSHLibrary.Execute Command    echo  ${cfg_content} > ${new_cfg_name}
    [Return]     ${new_cfg_name}

Start_Tool
    [Arguments]    ${cfg_file}      ${mapping}={}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    Get Con
    BuiltIn.Log    ${cmd} ${cfg_file}
    ${output}=    SSHLibrary.Write    ${cmd} ${cfg_file}
    BuiltIn.Log    ${output}

Start_Tool_And_Verify
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    Start_Tool    ${cfg_file}
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

Stop_Tool_And_Verify
    [Arguments]    ${url}    ${emptyrspfile}
    [Documentation]    Stop the tool if still running.
    Stop_Tool
    Verify Reported Data    ${url}    ${emptyrspfile}

Stop_Tool
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${output}

Verify Reported Data
    [Arguments]    ${url}    ${exprspfile}
    [Documentation]    Verify expected response
    ${keys_with_bits}=    BuiltIn.Create_List    op
    ${expected_rsp}=    Get Expected Response From File    ${exprspfile}
    ${expected_json}=    norm_json.Normalize Json Text    ${expected_rsp}    keys_with_bits=${keys_with_bits}
    ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${url}
    BuiltIn.Log    ${rsp.content}
    ${received_json}=    norm_json.Normalize Json Text    ${rsp.content}    keys_with_bits=${keys_with_bits}
    BuiltIn.Log    ${received_json}
    BuiltIn.Log    ${expected_json}
    BuiltIn.Should Be Equal    ${received_json}    ${expected_json}

Get Expected Response From File
    [Arguments]    ${exprspfile}
    [Documentation]    Looks for release specific response first, then take default.
    ${status}    ${expresponse}=    BuiltIn.Run_Keyword_And_Ignore_Error    OperatingSystem.Get File    ${CURDIR}/../../../variables/bgpfunctional/${exprspfile}.${ODL_STREAM}
    Return From Keyword If    '${status}' == 'PASS'    ${expresponse}
    ${expresponse}=    OperatingSystem.Get File    ${BGP_VARIABLES_FOLDER}/${exprspfile}
    [Return]    ${expresponse}

Verify Odl Sent Route Request
    [Arguments]    ${expcount}
    ${count}=    ExaClient.get_received_route_refresh_count
    BuiltIn.Should Be Equal As Numbers     ${count}    ${expcount}

Verify Odl Received Route Request
    [Arguments]    ${expcount}
    ${rsp}=      RequestsLibrary.Get Request      ${CONFIG_SESSION}    ${JOLOKURL}
    BuiltIn.Log     ${rsp.content}
    BuiltIn.Should Be Equal As Numbers     ${rsp.status_code}     200
    BuiltIn.Should Be Equal As Numbers     ${rsp.json()['status']}     200
    #${count}=    BuiltIn.Set Variable    ${rsp.json()}['value']['BgpSessionState']['messagesStats']['routeRefreshMsgs']['received']['count']
    BuiltIn.Should Be Equal As Numbers     ${rsp.json()['value']['BgpSessionState']['messagesStats']['routeRefreshMsgs']['received']['count']}    ${expcount}

Configure Paths
    [Arguments]    ${path_ids}
    : FOR    ${path_id}    IN    ${path_ids}
    \    TemplatedRequests.Post_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}/route_path${path_id}      session=${CONFIG_SESSION}

Remove All Paths
    TemplatedRequests.Delete_Templated     ${BGP_VARIABLES_FOLDER}/route_path0      session=${CONFIG_SESSION}

Configure Application Peer
    Fail

Deconfigure Application Peer
    Fail

Stop Tool And Remove Routes
    Stop Tool
    Remove Routes From Application Peer

Configure Path Selection Mode
    [Arguments]     ${psm}
    &{mapping}      Create Dictionary    PATHSELMODE=${psm}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_psm    mapping=${mapping}    session=${CONFIG_SESSION}

Configure Odl With Multipaths
    [Documentation]    blablabla
    &{mapping}      Create Dictionary
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_n_paths    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/module_all_paths    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/service_psmf    mapping=${mapping}    session=${CONFIG_SESSION}
    Configure Path Selection Mode     n-paths
    ${rib_old}=    TemplatedRequests.Get_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Set Suite Variable    ${rib_old}
    TemplatedRequests.Put_As_Xml_Templated    ${MULT_VAR_FOLDER}/rib    mapping=${mapping}    session=${CONFIG_SESSION}
    
