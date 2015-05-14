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

*** Variables ***
${swnr}           16
${flnr}           16000
${swspread}       linear
${tabspread}      linear
@{cntls}          ${CONTROLLER}
${linux_prompt}    >
${start_cmd}      sudo mn --controller=remote,ip=${CONTROLLER} --topo linear,${swnr} --switch ovsk,protocols=OpenFlow13

*** Test Cases ***
Connect Mininet
    Connect Switches

Configure Flows
    [Documentation]    Configuration of 16k flows into config datastore
    ${flows}    ${notes}=    Generate New Flow Details    flows=${flnr}    switches=${swnr}    swspread=${swspread}    tabspread=${tabspread}
    Log    ${notes}
    ${res}=    Configure Flows    flow_details=${flows}    controllers=@{cntls}    nrthreads=5
    Log    ${res}
    Set Suite Variable    ${flows}

Are Flows Operational
    [Documentation]    Operational datastore check if all flows are present there
    Wait Until Keyword Succeeds    110s    5s    Check Flows Inventory    ${flows}    ${CONTROLLER}

Deconfigure Flows
    [Documentation]    Removal of 16k flows from config datastore
    ${res}=    Deconfigure Flows    flow_details=${flows}    controllers=@{cntls}    nrthreads=5
    Log    ${res}

Check No Flows In Operational
    [Documentation]    Operational datastore to be without any flows
    ${noflows}=    Create List
    Wait Until Keyword Succeeds    110s    5s    Check Flows Inventory    ${noflows}    ${CONTROLLER}

Configure Flows Again
    [Documentation]    Configuration of 16k flows into config datastore again
    ${res}=    Configure Flows    flow_details=${flows}    controllers=@{cntls}    nrthreads=5
    Log    ${res}

Are Flows Operational Again
    [Documentation]    Operational datastore check if all flows are present there
    Wait Until Keyword Succeeds    110s    5s    Check Flows Inventory    ${flows}    ${CONTROLLER}

Stop Mininet
    [Documentation]    Disconnect/Stop mininet
    Stop Switches

Check No Flows In Operational After Disconnect
    [Documentation]    With mininet stopped no switches in operational datastore sould be found
    Wait Until Keyword Succeeds    110s    5s    Check No Switches Inventory

Connect Mininet Again
    [Documentation]    Reconnection of the mininet
    Connect Switches

Check Flows Are Operational Again
    [Documentation]    All 16k switches should be present in the operational datastore after mininet reconnection
    Wait Until Keyword Succeeds    110s    5s    Check Flows Inventory    ${flows}    ${CONTROLLER}

Deconfigure Flows End
    [Documentation]    Flows deconfiguration
    ${res}=    Deconfigure Flows    flow_details=${flows}    controllers=@{cntls}    nrthreads=5
    Log    ${res}

Check No Flows In Operational Last
    [Documentation]    Operational datastore to be without any flows
    ${noflows}=    Create List
    Wait Until Keyword Succeeds    110s    5s    Check Flows Inventory    ${noflows}    ${CONTROLLER}

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
    [Arguments]    ${fldets}    ${cntl}
    ${res}=    Flow Stats Collected    flow_details=${fldets}    controller=${cntl}
    Should Be True    ${res}

Check No Switches Inventory
    ${resp}=    Get    session    ${OPERATIONAL_NODES_API}
    Log    ${resp.content}
    Should Be Equal As Strings    '${resp.content}'    '{"nodes":{}}'
