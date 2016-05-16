*** Settings ***
Documentation     Test for running openflow monkey test on ODL cluster
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
Resource          ../../../libraries/OVSDB.robot


*** Variables ***
${SWITCHES}              3
${MONKEY_COUNT}          2
${MONKEY_INTERVAL}       10
${RUN_TIME}              30
${MONKEY_LOG_FILE}       results-ofclustermonkey.log
${MONKEY_SCRIPT_FILE}    ofclustermonkey.py
${START_CMD}             sudo mn --controller 'remote,ip=${ODL_SYSTEM_1_IP},port=6633' --controller 'remote,ip=${ODL_SYSTEM_2_IP},port=6633' --controller 'remote,ip=${ODL_SYSTEM_3_IP},port=6633' --topo tree,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${START_MONKEY_CMD}      sudo python ${MONKEY_SCRIPT_FILE} --monkey-count ${MONKEY_COUNT} --interval ${MONKEY_INTERVAL} --run-time ${RUN_TIME} --logfile ${MONKEY_LOG_FILE} --cluster-nodes ${ODL_SYSTEM_1_IP} ${ODL_SYSTEM_2_IP} ${ODL_SYSTEM_3_IP}


*** Test Cases ***
Start Monkey Tests
    [Documentation]    Start monkey tests, wrapper around of-cluster-monkey.py, check if there were any fault states in logfile
    ${monkey_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    SSHLibrary.Execute Command    rm -f ${MONKEY_LOG_FILE}
    ${monkey_stdout}    ${monkey_stderr}    ${monkey_rc}=    SSHLibrary.Execute Command    ${START_MONKEY_CMD}     return_stderr=True    return_rc=True
    Log    ${monkey_stdout}
    Log    ${monkey_stderr}
    SSHLibrary.Get File    ${MONKEY_LOG_FILE}
    OperatingSystem.File Should Exist    ${MONKEY_LOG_FILE}
    ${log_file_content}=    OperatingSystem.Get File    ${MONKEY_LOG_FILE}
    Log    ${log_file_content}
    Should Be Equal As Integers    ${monkey_rc}    0
    Should Not Contain    ${log_file_content}    notok


*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword - copy monkey and dependent library scripts to remote machine and run mininet
    BuiltIn.Log    Start the test suite for Openflow monkey testing
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    SSHLibrary.Put File    ${CURDIR}/../../../libraries/${MONKEY_SCRIPT_FILE}    .
    SSHLibrary.Put File    ${CURDIR}/../../../libraries/VsctlListParser.py    .
    SSHLibrary.Execute Command    sudo mn -c
    SSHLibrary.Write    ${START_CMD}
    SSHLibrary.Read Until    mininet>
    Wait Until Keyword Succeeds    10x    3s    OVSDB.Verify OVS Reports Connected

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections