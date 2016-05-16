*** Settings ***
Documentation     Test for running openflow monkey test on ODL cluster
...
...               Test main role is to run ofclustermonkey.py python script which runs monkey
...               test on cluster and connected mininet.
...
...               Monkey script has some dependencies that need to be satisfied prior it's
...               execution. These are robot-framework SSHLibrary and libraries/VsctlListParser.py
...               SSHLibrary is used to connect and alternate iptables rules on cluster nodes.
...               libraries/VsctlListParser.py is used to parse ovsct controller and bridge lists.
...               After installation of dependecies, mininet is started and connected to cluster nodes.
...
...               Test case itself consists of connecting to tools system where are dependecies and
...               script itself are installed/copied. Logs from monkey scripts are then copied back
...               to home system and checked for invalid states (notok string)
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html

Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           XML
Resource          ${CURDIR}/../../../libraries/OVSDB.robot
Resource          ${CURDIR}/../../../libraries/OvsManager.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot

*** Variables ***
${SWITCHES}              5
${MONKEY_COUNT}          2
${MONKEY_INTERVAL}       10
${RUN_TIME}              30
${MONKEY_LOG_FILE}       results-ofclustermonkey.log
${MONKEY_DUMP_FILE}      dump-ofclustermonkey.log
${MONKEY_SCRIPT_FILE}    ofclustermonkey.py
${MONKEY_LOG_LEVEL}      info
#${START_CMD}             sudo mn --controller 'remote,ip=${ODL_SYSTEM_1_IP},port=6633' --controller 'remote,ip=${ODL_SYSTEM_2_IP},port=6633' --controller 'remote,ip=${ODL_SYSTEM_3_IP},port=6633' --topo tree,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${CTRL_REST_SESSION}     controller
${START_CMD}             sudo mn --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${START_MONKEY_CMD}      sudo python ${MONKEY_SCRIPT_FILE} --monkey-count ${MONKEY_COUNT} --interval ${MONKEY_INTERVAL} --run-time ${RUN_TIME} --logfile ${MONKEY_LOG_FILE} --dumpfile ${MONKEY_DUMP_FILE} --cluster-nodes ${ODL_SYSTEM_1_IP} ${ODL_SYSTEM_2_IP} ${ODL_SYSTEM_3_IP} --${MONKEY_LOG_LEVEL}
${JOLOKIA_STATUS}        /jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-operational,type=DistributedOperationalDatastore


*** Test Cases ***
Execute Monkey Tests
    [Documentation]    Start monkey tests, wrapper around ofclustermonkey.py, check if there were any fault states in logfile
    [Timeout]    ${TIMEOUT} s    Script timeout reached
    ${monkey_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    SSHLibrary.Execute Command    rm -f ${MONKEY_LOG_FILE}
    ${monkey_stdout}    ${monkey_stderr}    ${monkey_rc}=    SSHLibrary.Execute Command    ${START_MONKEY_CMD}     return_stderr=True    return_rc=True
    Log    ${monkey_stdout}
    Log    ${monkey_stderr}
    Should Be Equal As Integers    ${monkey_rc}    0


Get Monkey Test Logs
    ${monkey_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    ${log_file_content}=    Download Monkey Log    ${MONKEY_LOG_FILE}
    ${dump_log_file_content}=    Download Monkey Log    ${MONKEY_DUMP_FILE}
    Log    ${log_file_content}
    Log    ${dump_log_file_content}
    Should Not Contain    ${log_file_content}    notok


*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword - copy monkey and dependent library scripts to remote machine and run mininet
    BuiltIn.Log    Start the test suite for Openflow monkey testing
    Utils.Install Package On Ubuntu System    python-pip python-dev gcc libffi-dev
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo pip install robotframework-sshlibrary    return_stdout=True    return_stderr=True    return_rc=True
    SSHLibrary.Put File    ${CURDIR}/../../../libraries/${MONKEY_SCRIPT_FILE}    .
    SSHLibrary.Put File    ${CURDIR}/../../../libraries/VsctlListParser.py    .
    SSHLibrary.Execute Command    sudo mn -c
    SSHLibrary.Write    ${START_CMD}
    SSHLibrary.Read Until    mininet>
    ${cntls_list}    BuiltIn.Create List    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    ${switch_list}    BuiltIn.Create List
    : FOR    ${i}    IN RANGE    0    ${SWITCHES}
    \    ${sid}=    BuiltIn.Evaluate    ${i}+1
    \    Collections.Append To List    ${switch_list}    s${sid}
    RequestsLibrary.Create Session    ${CTRL_REST_SESSION}    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}
    OvsManager.Setup Clustered Controller For Switches    ${switch_list}    ${cntls_list}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo
    BuiltIn.Wait Until Keyword Succeeds    10x    3s    OVSDB.Verify OVS Reports Connected
    BuiltIn.Wait Until Keyword Succeeds    10x    5s    Is Jolokia Available


Download Monkey Log
    [Arguments]    ${log_file}
    SSHLibrary.Get File    ${log_file}
    ${log_file_content}=    OperatingSystem.Get File    ${log_file}
    [Return]    ${log_file_content}


Is Jolokia Available
    [Documentation]    Checks whether jolokia apis are available
    RequestsLibrary.Create Session    n1    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}
    RequestsLibrary.Create Session    n2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}
    RequestsLibrary.Create Session    n3    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}
    : FOR    ${i}    IN RANGE    1    4
    \    ${resp_jolokia_status}=    RequestsLibrary.Get Request    n${i}    ${JOLOKIA_STATUS}
    \    Should Be Equal As Integers    ${resp_jolokia_status.status_code}    200


Are Switches Connected Topo
    [Documentation]    Checks whether switches are connected to controller
    ${resp}=    RequestsLibrary.Get Request    ${CTRL_REST_SESSION}    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    BuiltIn.Log    ${resp.content}
    ${count}=    XML.Get Element Count    ${resp.content}    xpath=node
    BuiltIn.Should Be Equal As Numbers    ${count}    ${SWITCHES}


Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections