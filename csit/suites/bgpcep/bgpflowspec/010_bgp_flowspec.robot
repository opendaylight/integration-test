*** Settings ***
Documentation     Test for measuring execution time of MD-SAL DataStore operations.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This test suite requires odl-restconf and odl-clustering-test-app modules.
...               The script cluster_rest_script.py is used for generating requests for
...               operations on people, car and car-people DataStore test models.
...               (see the https://wiki.opendaylight.org/view/MD-SAL_Clustering_Test_Plan)
...
...               Reported bugs:
...               https://bugs.opendaylight.org/show_bug.cgi?id=4220
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/Variables.py
Variables         ../../../variables/bgpflowspec/bgp_flowspec.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SetupUtils.robot


*** Variables ***
${cmd}      source ~/osctestenv/bin/activate; env exabgp.tcp.port=1790 exabgp --debug
${cfg1}     bgp-flowspec.cfg
${exp1}     ${bgp_flowspec_exp}
${cfg2}     bgp-flowspec-redirect.cfg
${exp2}     ${bgp_flowspec_redirect_exp}


*** Test Cases ***
#Reconfigure_ODL_To_Accept_BGP_Peer_Connection
#    [Documentation]    Configure BGP peer module with initiate-connection set to false.
#    [Tags]    critical
#    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer', 'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
#    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

#Reconfigure_ODL_To_Accept_BGP_Application_Peer
#    [Documentation]    Configure BGP application peer module.
#    [Tags]    critical
#    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-app', 'IP': '${BGP_APP_PEER_ID}'}
#    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    ${template_as_string}

#Check_For_Empty_Example-IPv4-Topology
#    [Documentation]    Sanity check example-ipv4-topology is up but empty.
#    [Tags]    critical
#    Wait_For_Topology_To_Change_To    ${empty_json}    000_Empty.json    timeout=120s

FlowSpec Test 1
    [Documentation]    Testing flowspec values for ${cfg1}
    [Setup]     Setup Testcase     ${cfg1}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Flowspec Data    ${exp1}
    [Teardown]     Stop_Tool

FlowSpec Test 2
    [Documentation]    Testing flowspec values for ${cfg2}
    [Setup]     Setup Testcase     ${cfg2}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Flowspec Data    ${exp2}
    [Teardown]     Stop_Tool


*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    #SSHLibrary.Put Directory    ${CURDIR}/../../../variables/bgpflowspec/    .
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    #${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo pip install exabgp    return_stdout=True    return_stderr=True     return_rc=True
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload Config Files     ${CURDIR}/../../../variables/bgpflowspec/

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Upload Config Files
    [Arguments]    ${dir_name}
    SSHLibrary.Put Directory    ${CURDIR}/../../../variables/bgpflowspec/    .
    @{cfgfiles}= 	SSHLibrary.List Files In Directory 	. 	*.cfg
    :FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute Command      sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute Command      sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute Command        cat ${cfgfile}
    \    Log     ${stdout}

Setup Testcase
    [Arguments]    ${cfg_file}
    Verify Empty Flowspec Data
    Start Tool     ${cfg_file}


Start_Tool
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    BuiltIn.Log    ${cmd} ${cfg_file}
    ${output}=    SSHLibrary.Write    ${cmd} ${cfg_file}
    BuiltIn.Log    ${output}

Wait_Until_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait ${timeout} for the tool exit.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    1s    SSHLibrary.Read Until Prompt

Stop_Tool
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read    delay=1s
    BuiltIn.Log    ${output}
    Verify Empty Flowspec Data

Verify Empty Flowspec Data
    ${rsp}=    RequestsLibrary.Get     session     /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-flowspec:flowspec-subsequent-address-family/bgp-flowspec:flowspec-routes      #headers=${ACCEPT_XML}
    Log     ${rsp.content}
    Should Be Equal     ${rsp.json()}      ${empty_flowspec}


Verify Flowspec Data
    [Documentation]    Verify bla bla bla
    [Arguments]    ${exprsp}
    ${rsp}=    RequestsLibrary.Get     session     /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-flowspec:flowspec-subsequent-address-family/bgp-flowspec:flowspec-routes     #headers=${ACCEPT_XML}
    Log     ${rsp.content}
    Should Be Equal     ${rsp.json()}      ${exprsp}
