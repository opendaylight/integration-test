*** Settings ***
Documentation     Suite checks if StatMngr is able to collect flows lineary spread over the switches but in one table on the switch
Suite Setup       Connect Switches
Suite Teardown    Stop Switches
Library           OperatingSystem
Library           Collections
Library           XML
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../../csit/libraries/Common.py
Library           ../../../../csit/libraries/ScaleClient.py
Variables         ../../../../csit/variables/Variables.py
Resource          ../../../../csit/variables/openflowplugin/Variables.robot

*** Variables ***
${swnr}           17
${flnr}           17000
${swspread}       linear
${tabspread}      first
@{cntls}          ${ODL_SYSTEM_IP}

*** Test Cases ***
Configure Flows
    ${flows}    ${notes}=    Generate New Flow Details    flows=${flnr}    switches=${swnr}    swspread=${swspread}    tabspread=${tabspread}
    Log    ${notes}
    ${res}=    Configure Flows    flow_details=${flows}    controllers=@{cntls}    nrthreads=5
    Log    ${res}
    Set Suite Variable    ${flows}

Check Configured Are Operational
    Wait Until Keyword Succeeds    110s    20s    Check Flows Inventory    ${flows}    ${ODL_SYSTEM_IP}

Deconfigure Flows
    ${res}=    Deconfigure Flows    flow_details=${flows}    controllers=@{cntls}    nrthreads=5
    Log    ${res}

Check No Flows In Operational
    ${noflows}=    Create List
    Wait Until Keyword Succeeds    110s    20s    Check Flows Inventory    ${noflows}    ${ODL_SYSTEM_IP}

*** Keywords ***
Connect Switches
    [Documentation]    Starts mininet with requested number of switches (${swnr})
    Log    Starting mininet with ${swnr} switches
    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=600
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo linear,${swnr} --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

Stop Switches
    [Documentation]    Stops mininet
    Log    Stopping mininet
    Delete All Sessions
    Read
    Write    exit
    Read Until    ${TOOLS_SYSTEM_PROMPT}
    Close Connection

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    Get Request    session    ${RFC8040_OPERATIONAL_TOPO_FLOW1_API}    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    ${swnr}

Check Flows Inventory
    [Arguments]    ${fldets}    ${cntl}
    ${res}=    Flow Stats Collected    flow_details=${fldets}    controller=${cntl}
    Should Be True    ${res}
