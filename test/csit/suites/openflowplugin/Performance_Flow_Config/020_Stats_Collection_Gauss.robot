*** Settings ***
Documentation     Suite checks if StatMngr is able to collect flows with gaussian spread over the switches and gaussian spread over tables within the switch
Suite Setup       Connect Switches
Suite Teardown    Stop Switches
Library           OperatingSystem
Library           Collections
Library           XML
Library           SSHLibrary
Variables         ../../../../csit/variables/Variables.py
Library           ../../../../csit/libraries/RequestsLibrary.py
Library           ../../../../csit/libraries/Common.py
Library           ../../../../csit/libraries/ScaleClient.py

*** Variables ***
${swnr}           17
${flnr}           17000
${swspread}       gauss
${tabspread}      gauss
${topourl}        /restconf/operational/network-topology:network-topology/topology/flow:1
${invurl}         /restconf/operational/opendaylight-inventory:nodes
@{cntls}          ${CONTROLLER}
${linux_prompt}   >

*** Test Cases ***
Configure Flows
    ${flows}    ${notes}=    Generate New Flow Details    flows=${flnr}    switches=${swnr}    swspread=${swspread}    tabspread=${tabspread}
    Log    ${notes}
    ${res}=    Configure Flows    flow_details=${flows}    controllers=@{cntls}    nrthreads=5
    Log    ${res}
    Set Suite Variable    ${flows}

Check Configured Are Operational
    Wait Until Keyword Succeeds    110s    20s    Check Flows Inventory    ${flows}    ${CONTROLLER}

Deconfigure Flows
    ${res}=    Deconfigure Flows    flow_details=${flows}    controllers=@{cntls}    nrthreads=5
    Log    ${res}

Check No Flows In Operational
    ${noflows}=    Create List
    Wait Until Keyword Succeeds    110s    20s    Check Flows Inventory    ${noflows}    ${CONTROLLER}

*** Keywords ***
Connect Switches
    [Documentation]    Starts mininet with requested number of switches (${swnr})
    Log    Starting mininet with ${swnr} switches
    Open Connection    ${MININET}    prompt=${linux_prompt}    timeout=600
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    sudo ovs-vsctl set-manager ptcp:6644
    Write    sudo mn -c
    Read Until    ${linux_prompt}
    Write    sudo mn --controller=remote,ip=${CONTROLLER} --topo linear,${swnr} --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>
    Sleep    10s
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Are Switches Connected Topo

Stop Switches
    [Documentation]    Stops mininet
    Log    Stopping mininet
    Delete All Sessions
    Read
    Write    exit
    Read Until    ${linux_prompt}
    Close Connection

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    Get    session    /restconf/operational/network-topology:network-topology/topology/flow:1    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    ${swnr}

Check Flows Inventory
    [Arguments]    ${fldets}    ${cntl}
    ${res}=    Flow Stats Collected    flow_details=${fldets}    controller=${cntl}
    Should Be True    ${res}
