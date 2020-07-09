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
...               In case of failed test case, other tests are skipped (unless
...               this is overriden by [Setup]) to finish test run sooner.
...
...               Variables and test case names refer to Controller(ODL_SYSTEM) and Mininet
...               (TOOLS_SYSTEM), those are assumed to be separate remote VMs, one to host ODL,
...               other to host tools.
...               In case updater and pcc-mock are desired to run
...               from separate machines, their parameters use Mininet(TOOLS_SYSTEM)
...               values as default.
...               If both updater VM and pcc-mock VM parameters are specified,
...               Mininet(TOOLS_SYSTEM) parameters may be skipped.
...               Variable ${USE_TOOLS_SYSTEM} decides the pcc-mock running machine.
...
...               Some launch scripts put restrictions on how pybot options
...               can be specified, so there are utility variables to help with
...               copying Controller related value to apply fo updater of pccmock.
...               Having a tool co-located with ODL reduces network latency,
...               but puts more pressure on CPU and memory on Controller VM.
...
...               In some environments, issues with TIME-WAIT prevent high restconf rates,
...               so TCP reuse is temporarily allowed during the suite run, if possible
...               (and if not disabled by UPDATERVM_ENABLE_TCP_RW_REUSE option value).
...               See http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html
...               This suite ignores possible failures when changing reuse.
...
...               Similarly, in some environments, handling of requests.Session object matters
...               try changing RESTCONF_REUSE value to see if it helps.
...
...               Variables to override (only if needed) in pybot command:
...               (Look into Variables table to see the default values.)
...
...               FIRST_PCC_IP: Set in case bind address is different from public pcc-mock VM address.
...               LOG_NAME: Filename (without path) to save pcc-mock output into.
...               LOG_PATH: Override if not the same as pccmock VM workspace.
...               LSPS: Number of LSPs per PCC to simulate and test.
...               MOCK_FILE: Filename to use for mock-pcc executable instead of the timestamped one.
...               ODL_SYSTEM_IP: Numeric IP address of VM where ODL runs.
...               ODL_SYSTEM_USER: Username for ssh login to ODL VM.
...               ODL_SYSTEM_PASSWORD: Ssh password, empty means public keys are used instead.
...               ODL_SYSTEM_PROMPT: Substring to identify Linux prompt on ODL VM.
...               ODL_SYSTEM_WORKSPACE: Path to where files can be written on ODL VM.
...               PCCDOWNLOAD_HOSTHEADER: Download server may check checks this header before showing content.
...               PCCDOWNLOAD_URLBASE: URL to pcep-pcc-mock folder in Nexus (use numberic IP if DNS has problems).
...               PCCMOCK_COLOCATED: If True, set PCCMOCKVM* to mirror ODL_SYSTEM*
...               PCCMOCKVM_IP: Override TOOLS_SYSTEM for pcc-mock usage.
...               PCCMOCKVM_*: Override corresponding TOOLS_SYSTEM_* for pcc-mock usage.
...               PCCS: Number of PCCs to simulate and test.
...               PCEP_READY_VERIFY_TIMEOUT: Grace period for pcep-topology to appear. Lower if ODL is ready.
...               RESTCONF_*: USER, PASSWORD and SCOPE to authenticate with, REUSE session.
...               (Note: If SCOPE is not empty, token-based authentication is used.)
...               TOOLS_SYSTEM_IP: Numeric IP address of VM to run pcc-mock and updater from by default.
...               TOOLS_SYSTEM_PASSWORD: Linux password to go with the username (empty means keys).
...               TOOLS_SYSTEM_PROMPT: Substring to identify Linux prompt on TOOLS_SYSTEM VM.
...               TOOLS_SYSTEM_USER: Linux username to SSH to on TOOLS_SYSTEM VM.
...               TOOLS_SYSTEM_WORKSPACE: Path to where files may be created on TOOLS_SYSTEM VM.
...               UPDATER_COLOCATED: If True, overrides UPDATERVM_* parameters to point at ODL_SYSTEM
...               (The purpose is to provide an option without ability to unpack ODL_SYSTEM value.)
...               UPDATER_ODLADDRESS: Override if public ODL_SYSTEM address is not best fit.
...               UPDATER_REFRESH: Main updater thread may sleep this long. Balance precision with overhead.
...               UPDATER_TIMEOUT: If updater stops itself if running more than this time.
...               (Set this limit according to your performance target.)
...               UPDATERVM_ENABLE_TCP_RW_REUSE: Set to false if changing Linux configuration is not desired.
...               UPDATERVM_IP: Override TOOLS_SYSTEM for updater.py usage.
...               UPDATERVM_*: Override corresponding TOOLS_SYSTEM_* for updater.py usage.
Suite Setup       FailFast.Do_Not_Fail_Fast_From_Now_On
Suite Teardown    Disconnect
Test Setup        FailFast.Fail_This_Fast_On_Previous_Error
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Library           ${CURDIR}/../../../libraries/AuthStandalone.py
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot    # for Deploy_Artifact
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot    # for Require_* and Assure_*, Flexible_SSH_Login

*** Variables ***
# This Variable decides the pcc mock to run in ODL system or tools system.
${USE_TOOLS_SYSTEM}    False
# This table acts as an exhaustive list of variables users can modify on pybot invocation.
# It also contains commented-out lines for variables defined elswhere.
# Keep this list in alphabetical order.
${BLOCKING-THREAD}    1
${DELAY_TIME}     10
${FIRST_PCC_IP}    ${PCCMOCKVM_IP}
# ${LOG_FILE} is reserved for location of pybot-created log.html
${INIT_PCC_DEVICE_COUNT}    ${100}
${LOG_NAME}       throughpcep.log
${LOG_PATH}       ${PCCMOCKVM_WORKSPACE}
${LSPS}           65535
#Reduced max pcc device count to 100 for BGPCEP-901
${MAX_PCC_DEVICE_COUNT}    ${100}
${ODL_SYSTEM_WORKSPACE}    /tmp
${PARALLEL_ITERATION}    10
${PCC_DEVICE_INCREMENT}    ${50}
${PCCDOWNLOAD_HOSTHEADER}    nexus.opendaylight.org
${PCCDOWNLOAD_URLBASE}    http://${PCCDOWNLOAD_HOSTHEADER}/content/repositories/opendaylight.snapshot/org/opendaylight/bgpcep/pcep-pcc-mock/
${PCCMOCK_COLOCATED}    False
${PCCMOCKVM_IP}    ${TOOLS_SYSTEM_IP}
${PCCMOCKVM_PASSWORD}    ${TOOLS_SYSTEM_PASSWORD}
${PCCMOCKVM_PROMPT}    ${TOOLS_SYSTEM_PROMPT}
${PCCMOCKVM_USER}    ${TOOLS_SYSTEM_USER}
${PCCMOCKVM_WORKSPACE}    ${TOOLS_SYSTEM_WORKSPACE}
${PCCS}           1
${PCEP_READY_VERIFY_TIMEOUT}    300s
# Yes, the default timeout is 5 minutes, as this suite might be started eagerly just after ODL starts booting up.
${RESTCONF_PASSWORD}    ${PWD}    # from Variables.robot
${RESTCONF_REUSE}    True
${RESTCONF_SCOPE}    ${EMPTY}
${RESTCONF_USER}    ${USER}    # from Variables.robot
${SEQUENTIAL_ITERATION}    15
${TOOLS_SYSTEM_WORKSPACE}    /tmp
${UPDATER_COLOCATED}    False
${UPDATER_ODLADDRESS}    ${ODL_SYSTEM_IP}
${UPDATER_REFRESH}    0.1
# Updater timeout is overwritten in releng/builder
${UPDATER_TIMEOUT}    300
${UPDATERVM_ENABLE_TCP_RW_REUSE}    True
${UPDATERVM_IP}    ${TOOLS_SYSTEM_IP}
${UPDATERVM_PASSWORD}    ${TOOLS_SYSTEM_PASSWORD}
${UPDATERVM_PROMPT}    ${TOOLS_SYSTEM_PROMPT}
${UPDATERVM_USER}    ${TOOLS_SYSTEM_USER}
${UPDATERVM_WORKSPACE}    ${TOOLS_SYSTEM_WORKSPACE}

*** Test Cases ***
Download_Pcc_Mock
    [Documentation]    SSH login to pcc-mock VM, download latest pcc-mock executable from Nexus.
    [Setup]    Select_MOCK_Machine
    BuiltIn.Run_Keyword_If    ${PCCMOCK_COLOCATED}    Pccmock_From_Controller
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage    tools_system_connect=False
    SSHLibrary.Open_Connection    ${PCCMOCKVM_IP}    alias=pccmock
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${PCCMOCKVM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${PCCMOCKVM_USER}    ${PCCMOCKVM_PASSWORD}    delay=4s
    ${file_name} =    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${mock_location}    ${file_name}

Put_Updater
    [Documentation]    Open SSH session to updater VM, copy the utility there, including dependencies, also prepare direct http session.
    BuiltIn.Run_Keyword_If    ${UPDATER_COLOCATED}    Updater_From_Controller
    SSHLibrary.Open_Connection    ${UPDATERVM_IP}    alias=updater
    SSHLibrary.Set_Client_Configuration    timeout=20s
    SSHLibrary.Set_Client_Configuration    prompt=${UPDATERVM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${UPDATERVM_USER}    ${UPDATERVM_PASSWORD}    delay=4s
    SSHKeywords.Require_Python
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/pcep_updater/updater.py    ${UPDATERVM_WORKSPACE}/
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/AuthStandalone.py    ${UPDATERVM_WORKSPACE}/
    SSHKeywords.Assure_Library_Counter    target_dir=${UPDATERVM_WORKSPACE}
    SSHKeywords.Assure_Library_Ipaddr    target_dir=${UPDATERVM_WORKSPACE}
    # Done preparation of Updater VM, now use AuthStandalone to create session from robot VM too.
    BuiltIn.Log_Many    ${RESTCONF_USER}    ${RESTCONF_PASSWORD}    ${RESTCONF_SCOPE}    ${ODL_SYSTEM_IP}
    ${session} =    AuthStandalone.Init_Session    ${ODL_SYSTEM_IP}    ${RESTCONF_USER}    ${RESTCONF_PASSWORD}    ${RESTCONF_SCOPE}
    BuiltIn.Set_Suite_Variable    ${rest_session}    ${session}
    # TODO: Define http timeouts.

Save_And_Enable_Tcp_Rw_Reuse
    [Documentation]    If requested, temporarily enable TCP port reuse on Updater VM to allow for high rate of TCP connections. Do not start failing fast.
    BuiltIn.Pass_Execution_If    not ${UPDATERVM_ENABLE_TCP_RW_REUSE}    Manipulation of tcp_rw_reuse is not requested.
    ${old_value} =    SSHLibrary.Execute_Command    cat /proc/sys/net/ipv4/tcp_tw_reuse
    # The next line may be skipped if the previous line failed.
    BuiltIn.Set_Suite_Variable    ${tcp_rw_reuse}    ${old_value}
    ${out}    ${rc} =    SSHLibrary.Execute_Command    sudo bash -c "echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse"    return_rc=True
    BuiltIn.Should_Be_Equal    ${rc}    ${0}
    # Lack of sudo access should not prevent the rest of suite from trying without TCP reuse.
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Topology_Precondition
    [Documentation]    Verify that within timeout, PCEP topology is present, with no PCC connected.
    [Tags]    critical
    Set_Hop    0
    Builtin.Wait_Until_Keyword_Succeeds    ${PCEP_READY_VERIFY_TIMEOUT}    1s    Pcep_Off
    # Yes, timeout is 5 minutes, as this suite might be started eagerly just after ODL starts booting up.

Topology_Intercondition
    [Documentation]    Verify that within timeout, PCEP topology contains correct numbers of LSPs.
    [Tags]    critical
    [Setup]    Start_Pcc_Mock
    ${localsize} =    Evaluate    int(${PCCS})*int(${LSPS})
    Builtin.Set_Suite_Variable    ${size}    ${localsize}
    BuiltIn.Log    ${size}
    Builtin.Wait_Until_Keyword_Succeeds    120s    1s    Pcep_On
    # TODO: Make timeout value scale with ${size}?

Updater_1
    [Documentation]    Run updater tool to change hops, using 1 blocking http thread.
    [Tags]    critical
    Updater    1    1
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_1
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    1

Updater_2
    [Documentation]    Run updater tool to change hops again, using 2 blocking http threads.
    [Tags]    critical
    Updater    2    1
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_2
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    2

Updater_3
    [Documentation]    Run updater tool to change hops again, using 4 blocking http threads.
    [Tags]    critical
    Updater    3    4
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_3
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    3

Updater_4
    [Documentation]    Run updater tool to change hops again, using 8 blocking http threads.
    [Tags]    critical
    Updater    4    8
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_4
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    4

Updater_5
    [Documentation]    Run updater tool to change hops again, using 16 blocking http threads.
    [Tags]    critical
    Updater    5    16
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_5
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    5

Updater_6
    [Documentation]    Run updater tool to change hops again, using 32 blocking http threads.
    [Tags]    critical
    Updater    6    32
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_6
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    6

Updater_7
    [Documentation]    Run updater tool to change hops again, using 64 blocking http threads.
    [Tags]    critical
    Updater    7    64
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_7
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    7

Updater_8
    [Documentation]    Run updater tool to change hops again, using 128 blocking http threads.
    [Tags]    critical
    Updater    8    128
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_8
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    8

Updater_9
    [Documentation]    Run updater tool to change hops again, using 256 blocking http threads.
    [Tags]    critical
    Updater    9    256
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_9
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    9

Updater_10
    [Documentation]    Run updater tool to change hops again, using 512 blocking http threads.
    [Tags]    critical
    Updater    10    512
    [Teardown]    Do_Not_Start_Failing_If_This_Failed

Verify_10
    [Documentation]    Verify that within timeout, the correct number of new hops is in PCEP topology.
    [Tags]    critical
    Verify    10

Stop_Pcc_Mock
    [Documentation]    Send ctrl+c to pcc-mock, see prompt again within timeout.
    [Setup]    Run_Even_When_Failing_Fast
    SSHLibrary.Switch_Connection    pccmock
    BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt
    [Teardown]    Run Keywords    Kill all pcc mock simulator processes    AND    Builtin.Wait_Until_Keyword_Succeeds    ${PCEP_READY_VERIFY_TIMEOUT}    5s    Pcep_Off

PCEP Sessions Flapped with LSP updates
    [Documentation]    Flapping PCEP sessions and perform LSP updates within flapping
    Run Keyword If    '${USE_TOOLS_SYSTEM}' == 'True'    BuiltIn.Pass Execution    Pcc Mock should not run in ODL System
    FOR    ${devices}    IN RANGE    ${INIT_PCC_DEVICE_COUNT}    ${MAX_PCC_DEVICE_COUNT+1}    ${PCC_DEVICE_INCREMENT}
        Flap Pcc Mock sessions continuously with LSP updates    127.1.0.0    ${devices}    150
    END
    [Teardown]    Run Keywords    Kill all pcc mock simulator processes    AND    BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt

PCEP Sessions Flapped alongside LSP updates
    [Documentation]    Flapping PCEP sessions and perform LSP updates alongside flapping
    Run Keyword If    '${USE_TOOLS_SYSTEM}' == 'True'    BuiltIn.Pass Execution    Pcc Mock should not run in ODL System
    FOR    ${devices}    IN RANGE    ${INIT_PCC_DEVICE_COUNT}    ${MAX_PCC_DEVICE_COUNT+1}    ${PCC_DEVICE_INCREMENT}
        Flap Pcc Mock sessions parallelly with LSP updates    127.1.0.0    ${devices}    150
        BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt
    END
    [Teardown]    Run Keywords    Kill all pcc mock simulator processes    AND    BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt

Download_Pccmock_Log
    [Documentation]    Transfer pcc-mock output from pcc-mock VM to robot VM.
    [Setup]    Run_Even_When_Failing_Fast
    SSHLibrary.Execute Command    zip ${LOG_PATH}/mock_log.zip /tmp/throughpcep*
    SSHLibrary.Get_File    ${LOG_PATH}/mock_log.zip    mock_log.zip

Topology_Postcondition
    [Documentation]    Verify that within timeout, PCEP topology contains no PCCs again.
    [Tags]    critical
    [Setup]    Run_Even_When_Failing_Fast
    Builtin.Wait_Until_Keyword_Succeeds    90s    5s    Pcep_Off_Again

Restore_Tcp_Rw_Reuse
    [Documentation]    If requested, restore the old value if enabling TCP reuse was successful on Updater VM.
    [Setup]    Run_Even_When_Failing_Fast
    BuiltIn.Pass_Execution_If    not ${UPDATERVM_ENABLE_TCP_RW_REUSE}    Manipulation of tcp_rw_reuse is not requested.
    SSHLibrary.Switch_Connection    updater
    BuiltIn.Variable_Should_Exist    ${tcp_rw_reuse}
    ${out}    ${rc} =    SSHLibrary.Execute_Command    sudo bash -c "echo ${tcp_rw_reuse} > /proc/sys/net/ipv4/tcp_tw_reuse"    return_rc=True
    BuiltIn.Should_Be_Equal    ${rc}    ${0}

*** Keywords ***
Select_MOCK_Machine
    [Documentation]    Check the tools system variable and assigns the PCC Mock
    Run Keyword If    '${USE_TOOLS_SYSTEM}' == 'False'    Run Keywords    Pccmock_From_Odl_System    AND    Updater_From_Odl_System
    BuiltIn.Set_Suite_Variable    ${FIRST_PCC_IP}    ${PCCMOCKVM_IP}

Start_Pcc_Mock
    [Arguments]    ${mock-ip}=${FIRST_PCC_IP}    ${pccs}=${PCCS}    ${lsps}=${LSPS}    ${log_name}=${LOG_NAME}
    [Documentation]    Launch pcc-mock on background so simulated PCCs start connecting to controller.
    SSHLibrary.Switch_Connection    pccmock
    ${command} =    NexusKeywords.Compose_Full_Java_Command    -jar ${mock_location} --local-address ${mock-ip} --remote-address ${ODL_SYSTEM_IP} --pcc ${pccs} --lsp ${lsps} &> ${LOG_PATH}/${log_name}
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}
    # The pccmock SSH session is left alive, but no data will be exchanged for a while.
    # We need this connection to stay alive to send ctrl+c later.
    # SSHLibrary.Start_Command would not do that for us.

Pccmock_From_Odl_System
    [Documentation]    Copy Odl_System values to Pccmock VM variables.
    BuiltIn.Set_Suite_Variable    ${PCCMOCKVM_IP}    ${ODL_SYSTEM_IP}
    BuiltIn.Set_Suite_Variable    ${PCCMOCKVM_PASSWORD}    ${ODL_SYSTEM_PASSWORD}
    BuiltIn.Set_Suite_Variable    ${PCCMOCKVM_PROMPT}    ${ODL_SYSTEM_PROMPT}
    BuiltIn.Set_Suite_Variable    ${PCCMOCKVM_WORKSPACE}    ${ODL_SYSTEM_WORKSPACE}
    BuiltIn.Set_Suite_Variable    ${LOG_PATH}    ${ODL_SYSTEM_WORKSPACE}

Updater_From_Odl_System
    [Documentation]    Copy Odl_System values to Uprater VM variables.
    BuiltIn.Set_Suite_Variable    ${UPDATERVM_IP}    ${ODL_SYSTEM_IP}
    BuiltIn.Set_Suite_Variable    ${UPDATERVM_PASSWORD}    ${ODL_SYSTEM_PASSWORD}
    BuiltIn.Set_Suite_Variable    ${UPDATERVM_PROMPT}    ${ODL_SYSTEM_PROMPT}
    BuiltIn.Set_Suite_Variable    ${UPDATERVM_WORKSPACE}    ${ODL_SYSTEM_WORKSPACE}

Disconnect
    [Documentation]    Explicitly close all SSH connections.
    SSHLibrary.Close_All_Connections
    # TODO: Make AuthStandalone session object closable?

Get_Pcep_Topology_Data
    [Documentation]    Use session object to download PCEP topology JSON. Check status and return Response object.
    ${resp} =    AuthStandalone.Get_Using_Session    ${rest_session}    operational/network-topology:network-topology/topology/pcep-topology
    # Not Logging content, as it may be huge.
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
    # Used before topology had chance to grow huge. Be aware when creating a longevity suite from this.
    BuiltIn.Log    ${resp.text}
    BuiltIn.Should_Be_Equal    ${resp.text}    {"topology":[{"topology-id":"pcep-topology","topology-types":{"network-topology-pcep:topology-pcep":{}}}]}

Pcep_On
    [Documentation]    Get topology count of current hop, assert the number of matches.
    # Suite variables ${size} and ${hop} are set elsewhere.
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
    # Regular Expressions need a dot to be escaped to represent a dot.
    BuiltIn.Set_Suite_Variable    ${hop}    ${i}\.${i}\.${i}\.${i}/32
    BuiltIn.Log    ${hop}

Updater
    [Arguments]    ${iteration}    ${workers}    ${mock-ip}=${FIRST_PCC_IP}    ${pccs}=${PCCS}    ${lsps}=${LSPS}    ${parallel}=False
    [Documentation]    Compute number of workers, call updater.py, assert its response.
    SSHLibrary.Switch_Connection    pccmock
    # In some systems, inactive SSH sessions get severed.
    ${command} =    BuiltIn.Set_Variable    echo "still alive"
    ${output} =    SSHLibrary.Execute_Command    bash -c '${command}'
    # The previous line relies on a fact that Execute_Command spawns separate shels, so running pcc-mock is not affected.
    Set_Hop    ${iteration}
    SSHLibrary.Switch_Connection    updater
    ${response} =    SSHLibrary.Execute_Command    bash -c "cd ${UPDATERVM_WORKSPACE}; taskset 0x00000001 python updater.py --workers '${workers}' --odladdress '${UPDATER_ODLADDRESS}' --user '${RESTCONF_USER}' --password '${RESTCONF_PASSWORD}' --scope '${RESTCONF_SCOPE}' --pccaddress '${mock-ip}' --pccs '${pccs}' --lsps '${lsps}' --hop '${hop}' --timeout '${UPDATER_TIMEOUT}' --refresh '${UPDATER_REFRESH}' --reuse '${RESTCONF_REUSE}' 2>&1"
    Check Updater response    ${response}    ${parallel}

Check Updater response
    [Arguments]    ${response}    ${parallel}
    BuiltIn.Log    ${response}
    ${expected_value_continuous_execution} =    BuiltIn.Set_Variable    Counter({'pass': ${size}})
    ${not_expected_value_for_parallel_execution} =    BuiltIn.Set_Variable    Counter({'pass': 0})
    BuiltIn.Log    ${expected_value_continuous_execution}
    Run Keyword If    '${parallel}' == 'False'    BuiltIn.Should_Contain    ${response}    ${expected_value_continuous_execution}
    ...    ELSE    BuiltIn.Should_Not_Contain    ${response}    ${not_expected_value_for_parallel_execution}

Verify
    [Arguments]    ${iteration}
    [Documentation]    Set hop and verify that within timeout, all LSPs in topology are updated.
    Set_Hop    ${iteration}
    Builtin.Wait_Until_Keyword_Succeeds    30s    1s    Pcep_On

Flap Pcc Mock sessions continuously with LSP updates
    [Arguments]    ${mock-ip}=${FIRST_PCC_IP}    ${pccs}=${PCCS}    ${lsps}=${LSPS}
    ${localsize} =    Evaluate    int(${pccs})*int(${lsps})
    Builtin.Set_Suite_Variable    ${size}    ${localsize}
    ${workers} =    Set Variable    ${BLOCKING-THREAD}
    FOR    ${i}    IN RANGE    ${SEQUENTIAL_ITERATION}
        ${workers} =    Evaluate    ${workers}*${workers}
        Set_Hop    0
        Builtin.Wait_Until_Keyword_Succeeds    ${PCEP_READY_VERIFY_TIMEOUT}    5s    Pcep_Off
        Start_Pcc_Mock    ${mock-ip}    ${pccs}    ${lsps}    serial_execution.log
        Builtin.Wait_Until_Keyword_Succeeds    60s    5s    Pcep_On
        ${i} =    Evaluate    ${i}+1
        Updater    ${i}    ${workers}    127.1.0.0    ${pccs}    ${lsps}
        Verify    ${i}
        SSHLibrary.Switch_Connection    pccmock
        BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt
    END
    Check PCEP is stable

Flap Pcc Mock sessions parallelly with LSP updates
    [Arguments]    ${mock-ip}=${FIRST_PCC_IP}    ${pccs}=${PCCS}    ${lsps}=${LSPS}
    SSHLibrary.Switch_Connection    pccmock
    SSHLibrary.Put File    ${CURDIR}/../../../../tools/pcep_updater/mock.sh    /tmp/mock.sh
    Set_Hop    0
    Builtin.Wait_Until_Keyword_Succeeds    ${PCEP_READY_VERIFY_TIMEOUT}    5s    Pcep_Off
    SSHLibrary.Start Command    sh /tmp/mock.sh ${mock_location} ${mock-ip} ${ODL_SYSTEM_IP} ${pccs} ${lsps} parallel_Execution ${DELAY_TIME} &>1
    FOR    ${i}    IN RANGE    ${PARALLEL_ITERATION}
        ${pid} =    SSHLibrary.Execute Command    ps -fu ${ODL_SYSTEM_USER} | grep "/home/${ODL_SYSTEM_USER}/${mock_location}" | grep -v "grep" | awk '{print $2}'
        Run Keyword If    '${pid}'!= ""    Log    ${pid}
        ${i} =    Evaluate    ${i}+1
        Run Keyword If    '${pid}'!= ""    Updater    ${i}    1    127.1.0.0    ${pccs}    ${lsps}    True
    END
    BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt
    Kill all pcc mock simulator processes
    Check PCEP is stable

Check PCEP is stable
    [Documentation]    Check PCEP topology with default pcc and lsp values
    ${localsize} =    Evaluate    int(${PCCS})*int(${LSPS})
    Builtin.Set_Suite_Variable    ${size}    ${localsize}
    Builtin.Wait_Until_Keyword_Succeeds    90s    5s    Pcep_Off_Again
    Start_Pcc_Mock
    Builtin.Wait_Until_Keyword_Succeeds    60s    5s    Pcep_On
    Updater    2    1
    Verify    2
    SSHLibrary.Switch_Connection    pccmock
    BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt

Kill all pcc mock simulator processes
    SSHLibrary.Switch_Connection    pccmock
    ${mock_pid}    Get pid    /home/${ODL_SYSTEM_USER}/${mock_location}
    SSHLibrary.Execute_Command    kill -9 ${mock_pid}
    ${script_pid_1}    Get pid    bash -c sh /tmp/mock.sh
    SSHLibrary.Execute_Command    kill -9 ${script_pid_1}
    ${script_pid_2}    Get pid    sh /tmp/mock.sh
    SSHLibrary.Execute_Command    kill -9 ${script_pid_2}

Get pid
    [Arguments]    ${process_name}
    ${pid} =    SSHLibrary.Execute Command    ps -fu ${ODL_SYSTEM_USER} | grep "${process_name}" | grep -v "grep" | awk '{print $2}'
    [Return]    ${pid}
