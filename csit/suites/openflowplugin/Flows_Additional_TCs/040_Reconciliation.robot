*** Settings ***
Documentation     Suite checks if StatMngr is able to collect flows correctly
Suite Setup       Create Http Session
Suite Teardown    Delete Http Session
Library           OperatingSystem
Library           XML
Library           SSHLibrary
Library           Collections
Variables         ../../../variables/Variables.py
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/ScaleClient.py
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../libraries/Tcpdump.robot

*** Variables ***
${switchid}       1
${start_cmd}      sudo mn --topo single --switch ovsk,protocols=OpenFlow13
${setcntl_cmd}    sudo ovs-vsctl set-controller s1 tcp:${CONTROLLER}
${setcntl_cmd}    sudo ovs-vsctl set-controller s1 tcp:${CONTROLLER}

*** Test Cases ***
Config Empty Switch Not Empty
    [Documentation]    It is expected that controller will remove all flows from the switch
    [Setup]     Start And Fill Switch And C
    Check Switch Not Connected     ${switchid}
    ${resp}=    RequestsLibrary.Delete    session    ${CONFIG}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    200
    Fill Switch With Flows
    
    
 ${notes}=    Generate New Flow Details    flows=${flnr}    switches=${swnr}    swspread=${swspread}    tabspread=${tabspread}
    Log    ${notes}
    ${starttime}=    Get Time    epoch
    ${res}=    Configure Flows Bulk    flow_details=${flows}    controllers=@{cntls}    nrthreads=${nrthreads}    fpr=${fpr}
    Log    ${res}
    Set Suite Variable    ${flows}
    ${http204ok}=    Create List    ${204}
    ${validation}=    Validate Responses    ${res}    ${http204ok}
    Should Be True    ${validation}
    [Teardown]    Save Setup Time    setuptime    ${starttime}

Config Not Empty Switch Not Empty
Wait Stats Collected
    [Documentation]    Waits till ${flnr} flows are initially collected
    Measure Setup Time    ${swnr}    ${flnr}    inittime
    [Teardown]    Wait Stats Collected Teardown

Stable State Monitoring
    [Documentation]    Inventory check if all ${flnr} flows are present for specified time frame
    Monitor Stable State    ${swnr}    ${flnr}
    [Teardown]    Log Switch Details

*** Keywords ***
Start Switch
    [Documentation]    Starts mininet with one switch but no controller set
    Log    Starting mininet with ${swnr} switches
    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=600
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start_cmd}
    Read Until    mininet>
    Verify Keyword Does Not Fail Within Timeout    10s    1s    Check Switch Not Connected     ${switchid}

Stop Switch
    [Documentation]    Stops mininet
    Log    Stopping mininet
    Read
    Write    exit
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Close Connection

Create Http Session
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

Delete Http Session
    Delete All Sessions

Clean Config
    ${resp}=    RequestsLibrary.Delete    session    ${CONFIG_INVENORY_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    200


Check Switch Connected
    [Documentation]    Checks wheather switch is connected to controller
    [Arguments]      ${switchid}
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_INVENORY_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    200

Check Switch Not Connected
    [Documentation]    Checks wheather switch is connected to controller
    [Arguments]      ${switchid}
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_INVENORY_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    404

Set Controller On Switch
    SSHLibrary    Write     sudo ovs-vsctl set-controller s${switchid} tcp:$CONTROLLER
    Wait Until Keyword Succeeds    10s    1s    Check Switch Connected     ${switchid}

Unset Controller On Switch
    SSHLibrary    Write     sudo ovs-vsctl set-controller s${switchid} tcp:$CONTROLLER
    Wait Until Keyword Succeeds    10s    1s    Check Switch Not Connected     ${switchid}

Log Switch Details
    Write    ${getf_cmd}
    ${log}=    Read Until    mininet>
    Log    ${log}
    Write    ${getr_cmd}
    ${log}=    Read Until    mininet>
    Log    ${log}

Start And Fill Switch And Clean Config
    Start Switch
    Fill Switch
    ${resp}=    RequestsLibrary.Delete    session    ${OPERATIONAL_INVENORY_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    200

Cl
Start And Fill Switch And Fill Config
    Start Switch
    Fill Switch
    ${resp}=    RequestsLibrary.Delete    session    ${OPERATIONAL_INVENORY_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    200

Stop Switch And Clean Config
    Stop Switch
    ${resp}=    RequestsLibrary.Delete    session    ${OPERATIONAL_INVENORY_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    200
