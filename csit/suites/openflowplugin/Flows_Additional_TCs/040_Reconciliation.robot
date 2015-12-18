*** Settings ***
Documentation     Suite checks if StatMngr is able to collect flows correctly
Suite Setup       Create Http Session
Suite Teardown    Delete Http Session
Library           SSHLibrary
Variables         ../../../variables/Variables.py
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/ScaleClient.py
Resource          ../../../libraries/WaitForFailure.robot

*** Variables ***
${switchid}       1    # this is also used as number of switches if needed
${start_cmd}      sudo mn --topo single --switch ovsk,protocols=OpenFlow13
${setcntl_cmd}    sh ovs-vsctl set-controller s1 tcp:${CONTROLLER}:6653
${delcntl_cmd}    sh ovs-vsctl del-controller s1
@{ovsflows}       priority=2,dl_dst=11:11:11:11:11:12,actions=drop     priority=3,dl_dst=11:11:11:11:11:13,actions=drop     priority=4,dl_dst=11:11:11:11:11:14,actions=drop
${nrconfigflows}    5
@{cntls}           ${CONTROLLER}

*** Test Cases ***
Config Empty Switch Not Empty
    [Documentation]    It is expected that controller will remove all flows from the switch
    [Setup]     Start And Fill Switch And Clean Config
    Set Controller On Switch
    Wait Until Keyword Succeeds    10s    1s    Empty Reconcil State Achieved
    [Teardown]    Stop Switch And Clean Config

Config Not Empty Switch Not Empty
    [Setup]      Start And Fill Switch And Fill Config
    Set Controller On Switch
    Wait Until Keyword Succeeds    10s    1s    Config Reconcil State Achieved  
    [Teardown]    Stop Switch And Clean Config



*** Keywords ***
Start Switch
    [Documentation]    Starts mininet with one switch but no controller set
    Log    Starting mininet with command ${start_cmd}
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
    ${resp}=    RequestsLibrary.Delete    session    ${CONFIG_NODES_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Pass Execution If 	'${resp.status_code}' == '404'   Nothiong to delete if nothing is there
    Should Be Equal As Numbers      ${resp.status_code}    200

Check Switch Connected
    [Documentation]    Checks wheather switch is connected to controller
    [Arguments]      ${switchid}
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    200

Check Switch Not Connected
    [Documentation]    Checks wheather switch is connected to controller
    [Arguments]      ${switchid}
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}/node/openflow:${switchid}
    Log      ${resp.content}
    Should Be Equal As Numbers      ${resp.status_code}    404

Set Controller On Switch
    SSHLibrary.Write    ${setcntl_cmd}
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    1s    Check Switch Connected     ${switchid}

Del Controller On Switch
    SSHLibrary    Write     ${delcntl_cmd}
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    1s    Check Switch Not Connected     ${switchid}

Log Switch Details
    Write    sh ovs-ofctl dump-flows s${switchid} -O OpenFlow13
    ${log}=    Read Until    mininet>
    Log    ${log}
    Write    sh ovs-vsctl show
    ${log}=    Read Until    mininet>
    Log    ${log}

Fill Switch
    : FOR    ${flow}    IN    @{ovsflows}
    \    SSHLibrary.Write     sh ovs-ofctl add-flow s${switchid} \"${flow}\" -O OpenFlow13
    [Teardown]    Log Switch Details

Start And Fill Switch And Clean Config
    Start Switch
    Fill Switch
    Clean Config

Start And Fill Switch And Fill Config
    Start Switch
    Fill Switch
    Configure Flows

Stop Switch And Clean Config
    Stop Switch
    Clean Config

Empty Reconcil State Achieved
    Reconcil Flows Count Achieved      expflows=0

Config Reconcil State Achieved
    Reconcil Flows Count Achieved      expflows=${nrconfigflows}

Reconcil Flows Count Achieved
    [Arguments]        ${expflows}
    [Documentation]    Checks if operational ds is as expected
    ${sw}    ${repf}    ${foundf}=    Flow Stats Collected    controller=${CONTROLLER}
    Should Be Equal As Numbers    ${switchid}    ${sw}
    Should Be Equal As Numbers    ${expflows}   ${foundf}

Configure Flows
    [Documentation]    Configuration of ${flnr} flows into config datastore
    ${cflows}    ${notes}=    Generate New Flow Details    flows=${nrconfigflows}    switches=${switchid}    
    Log    ${notes}
    ${res}=    Configure Flows Bulk    flow_details=${cflows}    controllers=@{cntls}
    Log    ${res}
    Set Suite Variable    ${cflows}
    ${http204ok}=    Create List    ${204}
    ${validation}=    Validate Responses    ${res}    ${http204ok}
    Should Be True    ${validation}

