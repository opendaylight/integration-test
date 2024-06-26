*** Settings ***
Documentation       Suite checks if StatMngr is able to collect flows correctly

Library             OperatingSystem
Library             XML
Library             SSHLibrary
Library             Collections
Variables           ../../../variables/Variables.py
Library             RequestsLibrary
Library             ../../../libraries/Common.py
Library             ../../../libraries/ScaleClient.py
Resource            ../../../libraries/WaitForFailure.robot
Resource            ../../../variables/openflowplugin/Variables.robot

Suite Setup         Create Http Session And Upload Files
Suite Teardown      Delete Http Session And Store Plot Data


*** Variables ***
${swnr}             32
${flnr}             100000
${fpr}              200
${nrthreads}        5
${swspread}         linear
${tabspread}        first
@{cntls}            ${ODL_SYSTEM_IP}
${start_cmd}
...                 sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo linear,${swnr} --switch ovsk,protocols=OpenFlow13
${getf_cmd}         sh ./get-total-found.sh
${getr_cmd}         sh ./get-total-reported.sh
${iperiod}          1s
${imonitor}         60s
${ichange}          450s
${ratefile}         stats_rate.csv
${timefile}         stats_time.csv
${setuptime}        0
${inittime}         0
${restarttime}      0


*** Test Cases ***
Connect Mininet
    Connect Switches

Configure Flows
    [Documentation]    Configuration of ${flnr} flows into config datastore
    ${flows}    ${notes}=    Generate New Flow Details
    ...    flows=${flnr}
    ...    switches=${swnr}
    ...    swspread=${swspread}
    ...    tabspread=${tabspread}
    Log    ${notes}
    ${starttime}=    Get Time    epoch
    ${res}=    Configure Flows Bulk
    ...    flow_details=${flows}
    ...    controllers=@{cntls}
    ...    nrthreads=${nrthreads}
    ...    fpr=${fpr}
    Log    ${res}
    Set Suite Variable    ${flows}
    ${http201ok}=    Create List    ${201}
    ${validation}=    Validate Responses    ${res}    ${http201ok}
    Should Be True    ${validation}
    [Teardown]    Save Setup Time    setuptime    ${starttime}

Wait Stats Collected
    [Documentation]    Waits till ${flnr} flows are initially collected
    Measure Setup Time    ${swnr}    ${flnr}    inittime
    [Teardown]    Log Switch Details

Stable State Monitoring
    [Documentation]    Inventory check if all ${flnr} flows are present for specified time frame
    Monitor Stable State    ${swnr}    ${flnr}
    [Teardown]    Log Switch Details

Stop Mininet
    [Documentation]    Disconnect/Stop mininet
    Stop Switches

Check No Flows In Operational After Disconnect
    [Documentation]    With mininet stopped no switches in operational datastore sould be found
    Inventory Change Reached    0    0

Connect Mininet Again
    [Documentation]    Reconnection of the mininet
    Connect Switches

Check Flows Are Operational Again
    [Documentation]    All ${flnr} slows should be present in the operational datastore after mininet reconnection
    Measure Setup Time    ${swnr}    ${flnr}    restarttime
    [Teardown]    Log Switch Details

Deconfigure Flows
    [Documentation]    Flows deconfiguration
    ${resp}=    DELETE On Session    session    url=${RFC8040_NODES_API}    expected_status=204

Check No Flows In Operational Last
    [Documentation]    Operational datastore to be without any flows
    Inventory Change Reached    ${swnr}    0
    [Teardown]    Log Switch Details

Stop Mininet End
    Stop Switches


*** Keywords ***
Connect Switches
    [Documentation]    Starts mininet with requested number of switches (${swnr})
    Log    Starting mininet with ${swnr} switches
    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=600
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start_cmd}
    Read Until    mininet>
    Comment    Below line disables switch echos
    Write
    ...    sh x=`sudo ovs-vsctl --columns=_uuid list Controller | awk '{print $NF}'`; for i in $x; do sudo ovs-vsctl set Controller $i inactivity_probe=0; done
    Read Until    mininet>
    Wait Until Keyword Succeeds    20s    1s    Are Switches Connected Topo

Create Http Session And Upload Files
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=600
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Put File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/clustering-performance-test/ovs-scripts/*    ./
    Close Connection

Stop Switches
    [Documentation]    Stops mininet
    Log    Stopping mininet
    Read
    Write    exit
    Read Until    ${TOOLS_SYSTEM_PROMPT}
    Close Connection

Delete Http Session And Store Plot Data
    Delete All Sessions
    ${initrate}=    Evaluate    (${flnr}/${inittime})
    ${restartrate}=    Evaluate    (${flnr}/${restarttime})
    Append To File    ${ratefile}    Initial,AfterMininetRestart\n
    Append To File    ${ratefile}    ${initrate},${restartrate}\n
    Append To File    ${timefile}    Initial,AfterMininetRestart\n
    Append To File    ${timefile}    ${inittime},${restarttime}\n

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    GET On Session    session    url=${RFC8040_OPERATIONAL_TOPO_FLOW1_API}    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    ${swnr}

Check Flows Inventory
    [Documentation]    Checks in inventory has required state
    [Arguments]    ${rswitches}    ${rflows}
    ${sw}    ${repf}    ${foundf}=    Flow Stats Collected    controller=${ODL_SYSTEM_IP}
    Should Be Equal As Numbers    ${rswitches}    ${sw}
    Should Be Equal As Numbers    ${rflows}    ${foundf}

Measure Setup Time
    [Documentation]    This keyword is dedicated to save measured time for plotting
    [Arguments]    ${rswitches}    ${rflows}    ${note}
    ${starttime}=    Get Time    epoch
    Log    Starting stats collection at time ${starttime}
    Inventory Change Reached    ${rswitches}    ${rflows}
    [Teardown]    Save Setup Time    ${note}    ${starttime}

Save Setup Time
    [Documentation]    Count the difference and stores it
    [Arguments]    ${note}    ${starttime}
    ${endtime}=    Get Time    epoch
    Log    Stats collection finished at time ${endtime}
    ${res}=    Evaluate    int(${endtime})-int(${starttime})
    ${inittime}=    Set Variable If    "${note}"=="inittime"    ${res}    ${inittime}
    ${restarttime}=    Set Variable If    "${note}"=="restarttime"    ${res}    ${restarttime}
    ${setuptime}=    Set Variable If    "${note}"=="setuptime"    ${res}    ${setuptime}
    Set Suite Variable    ${inittime}
    Set Suite Variable    ${restarttime}
    Set Suite Variable    ${setuptime}

Inventory Change Reached
    [Documentation]    This keywordwaits till inventory reaches required state
    [Arguments]    ${rswitches}    ${rflows}
    Wait Until Keyword Succeeds    ${ichange}    ${iperiod}    Check Flows Inventory    ${rswitches}    ${rflows}

Monitor Stable State
    [Documentation]    This keywordwaits till inventory reaches required state
    [Arguments]    ${rswitches}    ${rflows}
    Verify Keyword Does Not Fail Within Timeout
    ...    ${imonitor}
    ...    ${iperiod}
    ...    Check Flows Inventory
    ...    ${rswitches}
    ...    ${rflows}

Log Switch Details
    Write    ${getf_cmd}
    ${log}=    Read Until    mininet>
    Log    ${log}
    Write    ${getr_cmd}
    ${log}=    Read Until    mininet>
    Log    ${log}
