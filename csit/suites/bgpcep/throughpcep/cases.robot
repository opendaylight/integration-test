*** Settings ***
Documentation     PCEP performance suite, uses restconf with configurable authentication.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               General Overview:
...
...               This is a suite which has both scale and performance aspects.
...               Given scale target, suite reports failures if functional error
...               is detected, or if various time limits expire.
...               For passing test cases, their duration is the performance metric.
...
...               ODL acts as a translation layer between PCEP capable devices
...               and users employing RESTCONF.
...               Performance measurement focuses on two different workflows.
...
...               The first workflow is initial synchronization, when ODL learns
...               the state of PCEP topology as devices connect to it,
...               while restconf user reads the state repeatedly.
...               The second workflow is mass update, when restconf users issue RPCs
...               to updale Layer Switched Paths on Path Computation Clients.
...
...               This suite uses pcc-mock (downloaded from Nexus) to simulate PCCs.
...               It needs segment of bindable IP addresses,
...               one for each simulated PCC; so running pcc-mock from remote machine
...               is only viable when just single PCC is simulated.
...               Testing with multiple PCCs works best when pcc-mock
...               runs on the same VM as ODL, so 127.0.0.0/8 subnet can be used.
...
...               Library AuthStandalone is used directly for restconf reads
...               in the first workflow. That library transparently handles several
...               http authentication methods, based on credentials and pybot arguments.
...
...               In the second workflow, updater.py utility is used for issuing
...               rapid restconf requests. It can use multiple worker threads,
...               as http requests are blocking.
...               Due to CPython interpreter itself being single threaded,
...               amounts of threads above 8-16 are actually slightly slower
...               (which may roughly correspond to network traffic
...               being more limiting factor than CPU).
...               This suite starts updater utility bound to single CPU,
...               as this setup was the most performant in other tests.
...
...               In some environments, issues with TIME-WAIT prevent high restconf rates,
...               so TCP reuse is temporarily allowed during the suite run, if possible.
...               See http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html
...
...               Variables and test case names refer to Controller and Mininet,
...               those are assumed to be separate remote VMs, one to host ODL,
...               other to host tools.
...               In case updater and pcc-mock are desired to run
...               from separate machines, their parameters use Mininet
...               values as default.
...               If both updater VM and pcc-mock VM parameters are specified,
...               Mininet parameters may be skipped.
...
...               In case of failed test case, other tests are skipped (unless
...               this is overriden by [Setup]) to free environment sooner.
...
...               Variables to override in pybot command:
...               (Look into Variables table to see the default values.)
...
...               CONTROLLER: Numeric IP address of VM where ODL runs.
...               FIRST_PCC_IP: Set in case bind address is different from public pcc-mock VM address
...               LOG_NAME: Filename (without path) to save pcc-mock output into.
...               LOG_PATH: Override if not the same as pcc-mock location.
...               LSPS: Number of LSPs per PCC to simulate and test.
...               MININET: Numeric IP address of VM to run pcc-mock and updater from by default
...               MININET_USER: Linux username to SSH to on Mininet VM.
...               MININET_PASSWORD: Linux password to go with the username.
...               MININET_PROMPT: Substring to identify linux prompt on Mininet VM.
...               MININET_WORKSPACE: Path to where files may be created on Mininet VM.
...               MOCK_FILE: Filename to use for mock-pcc executable instead of the timestamped one.
...               PCCDOWNLOAD_HOSTHEADER: Download server may check checks this header before showing content.
...               PCCDOWNLOAD_URLBASE: URL to pcep-pcc-mock folder in Nexus (use numberic IP if DNS has problems).
...               PCCMOCKVM_IP: Override MININET for pcc-mock usage.
...               PCCMOCKVM_*: Override corresponding MININET_* for pcc-mock usage.
...               PCCS: Number of PCCs to simulate and test.
...               RESTCONF_*: USER, PASSWORD and SCOPE to authenticate with.
...               (Note: If SCOPE is not empty, token-based authentication is used.)
...               UPDATER_COLOCATED: If True, overrides UPDATERVM_* parameters to point at Controller
...               The purpose is to provide an option without ability to unpack CONTROLLER value.
...               UPDATERVM_IP: Override MININET for updater.py usage.
...               UPDATERVM_*: Override corresponding MININET_* for updater.py usage.
Suite Setup       FailFast.Do_Not_Fail_Fast_From_Now_On
Suite Teardown    Disconnect
Test Setup        FailFast.Fail_This_Fast_On_Previous_Error
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Variables         ${CURDIR}/../../../variables/Variables.py
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Library           ${CURDIR}/../../../libraries/AuthStandalone.py
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot

*** Variables ***
# In alphabetical order.
${CONTROLLER}     127.0.0.1
${CONTROLLER_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${CONTROLLER_WORKSPACE}    /tmp
${FIRST_PCC_IP}    ${PCCMOCKVM_IP}
# ${LOG_FILE}     # is reserved for location of pybot-created log.html
${LOG_NAME}       throughpcep.log
${LOG_PATH}       ${PCCMOCKVM_WORKSPACE}
${LSPS}           65535
${MININET}        127.0.0.1
# ${MININET_PASSWORD} is inherited from Variables.py
${MININET_PROMPT}    ${DEFAULT_LINUX_PROMPT}    # from Variables.py
${MININET_USER}    mininet
${MININET_WORKSPACE}    /tmp
${MOCK_FILE}      pcc-mock-ecexutable.jar
${PCCDOWNLOAD_HOSTHEADER}    nexus.opendaylight.org
${PCCDOWNLOAD_URLBASE}    http://${PCCDOWNLOAD_HOSTHEADER}/content/repositories/opendaylight.snapshot/org/opendaylight/bgpcep/pcep-pcc-mock/
${PCCMOCK_COLOCATED}    False
${PCCMOCKVM_IP}    ${MININET}
${PCCMOCKVM_PASSWORD}    ${MININET_PASSWORD}
${PCCMOCKVM_PROMPT}    ${MININET_PROMPT}
${PCCMOCKVM_USER}    ${MININET_USER}
${PCCMOCKVM_WORKSPACE}    ${MININET_WORKSPACE}
${PCCS}           1
${RESTCONF_PASSWORD}    ${PWD}    # from Variables.py
${RESTCONF_REUSE}    True
${RESTCONF_SCOPE}    ${EMPTY}
${RESTCONF_USER}    ${USER}    # from Variables.py
${UPDATER_COLOCATED}    False
${UPDATER_ODLADDRESS}    ${CONTROLLER}
${UPDATER_REFRESH}    0.1
${UPDATER_TIMEOUT}    300
${UPDATERVM_IP}    ${MININET}
${UPDATERVM_PASSWORD}    ${MININET_PASSWORD}
${UPDATERVM_PROMPT}    ${MININET_PROMPT}
${UPDATERVM_USER}    ${MININET_USER}
${UPDATERVM_WORKSPACE}    ${MININET_WORKSPACE}

*** TestCases ***
Connect_To_Pccmock_VM
    [Documentation]    SSH log in to pcc-mock VM, configure timeout and prompt.
    BuiltIn.Run_Keyword_If    ${PCCMOCK_COLOCATED}    Pccmock_From_Controller
    SSHLibrary.Open_Connection    ${PCCMOCKVM_IP}    alias=pccmock
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${PCCMOCKVM_PROMPT}
    Utils.Flexible_SSH_Login    ${PCCMOCKVM_USER}    ${PCCMOCKVM_PASSWORD}    delay=4s

Download_Pcc_Mock
    [Documentation]    On pcc-mock VM, download latest pcc-mock executable from Nexus.
    ${urlbase} =    BuiltIn.Set_Variable    ${PCCDOWNLOAD_URLBASE}
    ${host} =    BuiltIn.Set_Variable    ${PCCDOWNLOAD_HOSTHEADER}
    ${version} =    SSHLibrary.Execute_Command    curl -s -H "Host:${host}" ${urlbase}/maven-metadata.xml \| grep latest \| cut -d '>' -f 2 \| cut -d '<' -f 1
    BuiltIn.Log    ${version}
    ${namepart} =    SSHLibrary.Execute_Command    curl -s -H "Host:${host}" ${urlbase}/${version}/maven-metadata.xml \| grep value \| head -n 1 \| cut -d '>' -f 2 \| cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    BuiltIn.Set_Suite_Variable    ${filename}    pcep-pcc-mock-${namepart}-executable.jar
    BuiltIn.Log    ${filename}
    BuiltIn.Set_Suite_Variable    ${mocklocation}    ${PCCMOCKVM_WORKSPACE}/${MOCK_FILE}
    # TODO: Debug to make wget -N work
    ${response}    ${err}    ${return_code} =    SSHLibrary.Execute_Command    curl -s -H "Host:${host}" ${urlbase}/${version}/${filename} > ${mocklocation}    return_rc=True    return_stderr=True
    BuiltIn.Log    ${err}
    BuiltIn.Should_Be_Equal    ${return_code}    ${0}

Put_Updater
    [Documentation]    Open SSH session to updater VM, copy the utility there, including dependencies.
    BuiltIn.Run_Keyword_If    ${UPDATER_COLOCATED}    Updater_From_Controller
    SSHLibrary.Open_Connection    ${UPDATERVM_IP}    alias=updater
    SSHLibrary.Set_Client_Configuration    timeout=20s
    SSHLibrary.Set_Client_Configuration    prompt=${UPDATERVM_PROMPT}
    Utils.Flexible_SSH_Login    ${UPDATERVM_USER}    ${UPDATERVM_PASSWORD}    delay=4s
    Require_Python
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/pcep_updater/updater.py    ${UPDATERVM_WORKSPACE}/
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/AuthStandalone.py    ${UPDATERVM_WORKSPACE}/
    Assure_Library_Counter    workspace=${UPDATERVM_WORKSPACE}
    Assure_Library_Ipaddr    workspace=${UPDATERVM_WORKSPACE}

Http_Session
    [Documentation]    Create session for restconf requests against controller VM, using AuthStandalone library.
    BuiltIn.Log_Many    ${RESTCONF_USER}    ${RESTCONF_PASSWORD}    ${RESTCONF_SCOPE}    ${CONTROLLER}
    ${session} =    AuthStandalone.Init_Session    ${CONTROLLER}    ${RESTCONF_USER}    ${RESTCONF_PASSWORD}    ${RESTCONF_SCOPE}
    BuiltIn.Set_Suite_Variable    ${rest_session}    ${session}
    # TODO: Define http timeouts.

Topology_Precondition
    [Documentation]    Verify that within timeout, PCEP topology is present, with no PCC connected.
    [Tags]    critical
    Set_Hop    0
    Builtin.Wait_Until_Keyword_Succeeds    300s    1s    Pcep_Off
    # Yes, timeout is 5 minutes, as this suite might be started eagerly just after ODL starts booting up.

Start_Pcc_Mock
    [Documentation]    Launch pcc-mock on background so simulated PCCs start connecting to controller.
    SSHLibrary.Switch_Connection    pccmock
    ${command} =    BuiltIn.Set_Variable    java -jar ${mocklocation} --local-address ${FIRST_PCC_IP} --remote-address ${CONTROLLER} --pcc ${PCCS} --lsp ${LSPS} &> ${LOG_PATH}/${LOG_NAME}
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}
    # The pccmock SSH session is left alive, but no data will be exchanged for a while.
    # We need the connection to stay alive to send ctrl+c later.
    # SSHLibrary.Start_Command will not do that for us.

Topology_Intercondition
    [Documentation]    Verify that within timeout, PCEP topology contains correct numbers of LSPs.
    [Tags]    critical
    ${localsize} =    Evaluate    int(${PCCS})*int(${LSPS})
    Builtin.Set_Suite_Variable    ${size}    ${localsize}
    BuiltIn.Log    ${size}
    Builtin.Wait_Until_Keyword_Succeeds    120s    1s    Pcep_On
    # TODO: Make timeout value scale with ${size}?

Updater_1
    [Documentation]    Run updater tool to change hops, using 1 blocking http thread.
    [Tags]    critical
    Updater    1
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_1
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    1

Updater_2
    [Documentation]    Run updater tool to change hops again, using 2 blocking http threads.
    [Tags]    critical
    Updater    2
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_2
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    2

Updater_3
    [Documentation]    Run updater tool to change hops again, using 4 blocking http threads.
    [Tags]    critical
    Updater    3
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_3
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    3

Updater_4
    [Documentation]    Run updater tool to change hops again, using 8 blocking http threads.
    [Tags]    critical
    Updater    4
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_4
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    4

Updater_5
    [Documentation]    Run updater tool to change hops again, using 16 blocking http threads.
    [Tags]    critical
    Updater    5
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_5
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    5

Updater_6
    [Documentation]    Run updater tool to change hops again, using 32 blocking http threads.
    [Tags]    critical
    Updater    6
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_6
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    6

Updater_7
    [Documentation]    Run updater tool to change hops again, using 64 blocking http threads.
    [Tags]    critical
    Updater    7
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_7
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    7

Updater_8
    [Documentation]    Run updater tool to change hops again, using 128 blocking http threads.
    [Tags]    critical
    Updater    8
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_8
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    8

Updater_9
    [Documentation]    Run updater tool to change hops again, using 256 blocking http threads.
    [Tags]    critical
    Updater    9
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_9
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    9

Updater_10
    [Documentation]    Run updater tool to change hops again, using 512 blocking http threads.
    [Tags]    critical
    Updater    10
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_10
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    10

Stop_Pcc_Mock
    [Documentation]    Send ctrl+c to pcc-mock, see prompt again within timeout.
    [Setup]    Run_Even_When_Failing_Fast
    SSHLibrary.Switch_Connection    pccmock
    # FIXME: send_ctrl should be in some library.
    ${command} =    BuiltIn.Evaluate    chr(int(3))
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}
    ${response} =    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${response}

Download_Pccmock_Log
    [Documentation]    Transfer pcc-mock output from pcc-mock VM to robot VM.
    [Setup]    Run_Even_When_Failing_Fast
    SSHLibrary.Get_File    ${LOG_PATH}/${LOG_NAME}    ${CURDIR}/${LOG_NAME}

Topology_Postcondition
    [Documentation]    Verify that within timeout, PCEP topology contains no PCCs again.
    [Tags]    critical
    [Setup]    Run_Even_When_Failing_Fast
    Builtin.Wait_Until_Keyword_Succeeds    30s    1s    Pcep_Off_Again

*** Keywords ***
Pccmock_From_Controller
    [Documentation]    Copy Controller values to PccmockVM variables.
    ...    Job definition may allow additional pybot options, but may not allow acces to bash variables.
    BuiltIn.Set_Suite_Variable    ${PCCMOCKVM_IP}    ${CONTROLLER}
    BuiltIn.Set_Suite_Variable    ${PCCMOCKVM_PASSWORD}    ${CONTROLLER_PASSWORD}
    BuiltIn.Set_Suite_Variable    ${PCCMOCKVM_PROMPT}    ${CONTROLLER_PROMPT}
    BuiltIn.Set_Suite_Variable    ${PCCMOCKVM_WORKSPACE}    ${CONTROLLER_WORKSPACE}
    BuiltIn.Set_Suite_Variable    ${LOG_PATH}    ${CONTROLLER_WORKSPACE}

Updater_From_Controller
    [Documentation]    Copy Controller values to UpraterVM variables.
    ...    Job definition may allow additional pybot options, but may not allow acces to bash variables.
    BuiltIn.Set_Suite_Variable    ${UPDATERVM_IP}    ${CONTROLLER}
    BuiltIn.Set_Suite_Variable    ${UPDATERVM_PASSWORD}    ${CONTROLLER_PASSWORD}
    BuiltIn.Set_Suite_Variable    ${UPDATERVM_PROMPT}    ${CONTROLLER_PROMPT}
    BuiltIn.Set_Suite_Variable    ${UPDATERVM_WORKSPACE}    ${CONTROLLER_WORKSPACE}

Require_Python
    [Documentation]    Verify current SSH connection leads to machine with python working. Fatal fail otherwise.
    ${passed} =    Execute_Command_Passes    python --help
    BuiltIn.Return_From_Keyword_If    ${passed}
    BuiltIn.Fatal_Error    Python is not installed!

Assure_Library_Counter
    [Arguments]    ${workspace}=/tmp
    [Documentation]    Tests whether Counter is present in collections on ssh-connected machine, Puts Counter.py to workspace if not.
    ${passed} =    Execute_Command_Passes    bash -c 'cd "${workspace}" && python -c "from collections import Counter"'
    # TODO: Move the bash-cd wrapper to separate keyword?
    BuiltIn.Return_From_Keyword_If    ${passed}
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/Counter.py    ${workspace}/

Assure_Library_Ipaddr
    [Arguments]    ${workspace}=/tmp
    [Documentation]    Tests whether ipaddr module is present on ssh-connected machine, Puts ipaddr.py to workspace if not.
    ${passed} =    Execute_Command_Passes    bash -c 'cd "${workspace}" && python -c "import ipaddr"'
    BuiltIn.Return_From_Keyword_If    ${passed}
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/ipaddr.py    ${workspace}/

Execute_Command_Passes
    [Arguments]    ${command}
    [Documentation]    Execute command via SSH. If RC is nonzero, log everything. Retrun bool of command success.
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command    ${command}    return_stderr=True    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    True
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    BuiltIn.Log    ${rc}
    [Return]    False

Disconnect
    [Documentation]    Explicitly close all SSH connections.
    SSHLibrary.Close_All_Connections
    # Http Session does not need to be closed.

Get_Pcep_Topology_Data
    [Documentation]    Use Http session to download PCEP topology JSON. Check status and return Response object.
    ${resp} =    AuthStandalone.Get_Using_Session    ${rest_session}    operational/network-topology:network-topology/topology/pcep-topology
    BuiltIn.Log    ${resp}    # Not Logging content, as it may be huge.
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    [Return]    ${resp}

Get_Pcep_Topology_Count
    [Arguments]    ${pattern}
    [Documentation]    Get topology data, return number of pattern matches.
    ${resp} =    Get_Pcep_Topology_Data
    # BuiltIn.Log    ${resp.text}
    ${count} =    BuiltIn.Evaluate    len(re.findall('${pattern}', '''${resp.text}'''))    modules=re
    BuiltIn.Log    ${count}
    [Return]    ${count}

Pcep_Off
    [Documentation]    Get topology data, Log content and assert the exact JSON of empty topology.
    ${resp} =    Get_Pcep_Topology_Data
    BuiltIn.Log    ${resp.text}
    Should_Be_Equal    ${resp.text}    {"topology":[{"topology-id":"pcep-topology","topology-types":{"network-topology-pcep:topology-pcep":{}}}]}

Pcep_On
    [Documentation]    Get topology count of current hop, assert the number of matches.
    # ${size} and ${hop} are set below
    ${resp} =    Get_Pcep_Topology_Count    ${hop}
    BuiltIn.Should_Be_Equal    ${resp}    ${size}

Pcep_Off_Again
    [Documentation]    Get topology count of final hop, assert there is none.
    ...    This is more log friendly than Pcep_Off keyword, as it does not Log possibly large content.
    Set_Hop    0
    ${resp} =    Get_Pcep_Topology_Count    ${hop}
    BuiltIn.Should_Be_Equal    ${resp}    ${0}

Set_Hop
    [Arguments]    ${iteration}
    [Documentation]    Set pattern to match the currently expected hop.
    ${i} =    BuiltIn.Evaluate    str(1 + int(${iteration}))
    BuiltIn.Set_Suite_Variable    ${hop}    ${i}\.${i}\.${i}\.${i}/32    # Regular Expressions need dot to be escaped to represent dot.
    BuiltIn.Log    ${hop}

Updater
    [Arguments]    ${iteration}
    [Documentation]    Compute number of workers, call updater.py, assert its response.
    SSHLibrary.Switch_Connection    pccmock
    # In some systems, inactive SSH sessions get severed.
    ${command} =    BuiltIn.Set_Variable    echo "still alive"
    ${output} =    SSHLibrary.Execute_Command    python -c '${command}'
    # The previous line relies on a fact that Execute_Command spawns separate shels, so running pcc-mock is not affected.
    ${workers} =    Evaluate    2**int(${iteration} - 1)
    # TODO: Provide ${workers} explicitly as an argument to avoid math?
    BuiltIn.Log    ${workers}
    Set_Hop    ${iteration}
    SSHLibrary.Switch_Connection    updater
    ${response} =    SSHLibrary.Execute_Command    bash -c "cd ${UPDATERVM_WORKSPACE}; taskset 0x00000001 python updater.py --workers '${workers}' --odladdress '${UPDATER_ODLADDRESS}' --user '${RESTCONF_USER}' --password '${RESTCONF_PASSWORD}' --scope '${RESTCONF_SCOPE}' --pccaddress '${FIRST_PCC_IP}' --pccs '${PCCS}' --lsps '${LSPS}' --hop '${hop}' --timeout '${UPDATER_TIMEOUT}' --refresh '${UPDATER_REFRESH}' --reuse '${RESTCONF_REUSE}' 2>&1"
    BuiltIn.Log    ${response}
    ${expected} =    BuiltIn.Set_Variable    Counter({'pass': ${size}})
    BuiltIn.Log    ${expected}
    BuiltIn.Should_Contain    ${response}    ${expected}

Verify
    [Arguments]    ${iteration}
    [Documentation]    Set hop and verify that within timeout, all LSPs in topology are updated.
    Set_Hop    ${iteration}
    Builtin.Wait_Until_Keyword_Succeeds    30s    1s    Pcep_On
