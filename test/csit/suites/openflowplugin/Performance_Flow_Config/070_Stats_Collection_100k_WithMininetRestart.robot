*** Settings ***
Documentation     Suite checks if StatMngr is able to collect flows correctly
Suite Setup       Create Http Session
Suite Teardown    Delete Http Session
Library           OperatingSystem
Library           Collections
Library           XML
Library           SSHLibrary
Variables         ../../../variables/Variables.py
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/ScaleClient.py
Resource          ../../../libraries/WaitForFailure.robot

*** Variables ***
${swnr}           63
${flnr}           100000
${fpr}            25
${swspread}       linear
${tabspread}      first
@{cntls}          ${CONTROLLER}
${linux_prompt}    >
${start_cmd}      sudo mn --controller=remote,ip=${CONTROLLER} --topo linear,${swnr} --switch ovsk,protocols=OpenFlow13
${iperiod}        30s
${imonitor}       600s
${ichange}        120s

*** Test Cases ***
Connect Mininet
    Connect Switches

Configure Flows
    [Documentation]    Configuration of ${flnr} flows into config datastore
    ${flows}    ${notes}=    Generate New Flow Details    flows=${flnr}    switches=${swnr}    swspread=${swspread}    tabspread=${tabspread}
    Log    ${notes}
    ${res}=    Configure Flows Bulk    flow_details=${flows}    controllers=@{cntls}    nrthreads=5    fpr=${fpr}
    Log    ${res}
    Set Suite Variable    ${flows}

Wait Stats Collected
    [Documentation]    Waits till ${flnr} flows are initially collected
    Inventory Change Reached    ${swnr}    ${flnr}

Stable State Monitoring
    [Documentation]    Inventory check if all ${flnr} flows are present for specified time frame
    Monitor Stable State    ${swnr}    ${flnr}

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
    Inventory Change Reached    ${swnr}    ${flnr}

Deconfigure Flows
    [Documentation]    Flows deconfiguration
    ${resp}=    Delete    session    ${CONFIG_NODES_API}
    Should Be Equal As Numbers    ${resp.status_code}    200

Check No Flows In Operational Last
    [Documentation]    Operational datastore to be without any flows
    Inventory Change Reached    ${swnr}    0

Stop Mininet End
    Stop Switches

*** Keywords ***
Connect Switches
    [Documentation]    Starts mininet with requested number of switches (${swnr})
    Log    Starting mininet with ${swnr} switches
    Open Connection    ${MININET}    prompt=${linux_prompt}    timeout=600
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start_cmd}
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

Create Http Session
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

Stop Switches
    [Documentation]    Stops mininet
    Log    Stopping mininet
    Read
    Write    exit
    Read Until    ${linux_prompt}
    Close Connection

Delete Http Session
    Delete All Sessions

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    Get    session    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    ${swnr}

Check Flows Inventory
    [Arguments]    ${rswitches}    ${rflows}
    [Documentation]    Checks in inventory has required state
    ${sw}    ${repf}    ${foundf}=    Flow Stats Collected    controller=${CONTROLLER}
    Should Be Equal As Numbers    ${rswitches}    ${sw}
    Should Be Equal As Numbers    ${rflows}    ${foundf}

Inventory Change Reached
    [Arguments]    ${rswitches}    ${rflows}
    [Documentation]    This keywordwaits till inventory reaches required state
    Wait Until Keyword Succeeds    ${ichange}    ${iperiod}    Check Flows Inventory    ${rswitches}    ${rflows}

Monitor Stable State
    [Arguments]    ${rswitches}    ${rflows}
    [Documentation]    This keywordwaits till inventory reaches required state
    Verify Keyword Does Not Fail Within Timeout    ${imonitor}    ${iperiod}    Check Flows Inventory    ${rswitches}    ${rflows}
