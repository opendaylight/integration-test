*** Settings ***
Library           Collections
Library           SSHLibrary
Library           UtilLibrary.py
Resource          Utils.robot

*** Variables ***
${REST_VIEW_CHANNEL}    /restconf/operations/usc-channel:view-channel
${REST_ADD_CHANNEL}    /restconf/operations/usc-channel:add-channel
${REST_REMOVE_CHANNEL}    /restconf/operations/usc-channel:remove-channel
${REST_SEND_MESSAGE}    /restconf/operations/usc-channel:send-message
${NAV_USC_TOOLS}    cd ~/usc-tools
${CLONE_USC_TOOLS}    [ -f ~/usc-tools/UscAgent.jar ] && echo "The usc-tools does exist, done." || git clone https://github.com/victorxu99/usc-tools.git ~/usc-tools
${ECHO_SERVER_PORT}    2007
@{LIST_ECHO_SERVER_PORT}    2007    2008    2009
${TEST_MESSAGE}    This is a test message.
${NUM_OF_MESSAGES}    100
${AgentTcp}       java -jar UscAgent.jar -t true
${AgentUdp}       java -jar UscAgent.jar -t false
${AgentTcpCallhome}    java -jar UscAgent.jar -t true -c true -h
${AgentUdpCallhome}    java -jar UscAgent.jar -t false -c true -h
${EchoServerTcp}    java -jar EchoServer.jar -t true -p 2007
${EchoServerUdp}    java -jar EchoServer.jar -t false -p 2007

*** Keywords ***
Download Tools
    [Documentation]    Download UscAgent and EchoServer before any system
    ...    is run.
    Log    Download tools begin ...
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    ${CLONE_USC_TOOLS}    user=${TOOLS_SYSTEM_USER}    password=${TOOLS_SYSTEM_PASSWORD}    prompt_timeout=30s
    Log    Download tools ended.

Start TCP
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start USC test VM for TCP
    ${agent_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${agent_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${AgentTcp}
    Read
    ${echo_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${echo_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${EchoServerTcp}
    Read Until    initialized

Start UDP
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start USC test VM for UDP
    ${agent_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${agent_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${AgentUdp}
    Read
    ${echo_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${echo_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${EchoServerUdp}
    Read Until    initialized

Start CALLHOME_TCP
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start USC test VM for CALLHOME_TCP
    ${agent_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${agent_conn_id}
    ${callhomeCmd}=    Catenate    ${AgentTcpCallhome}    ${ODL_SYSTEM_IP}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${callhomeCmd}
    Read
    ${echo_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${echo_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${EchoServerTcp}
    Read Until    initialized

Start CALLHOME_UDP
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start USC test VM for CALLHOME_UDP
    ${agent_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${agent_conn_id}
    ${callhomeCmd}=    Catenate    ${AgentUdpCallhome}    ${ODL_SYSTEM_IP}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${callhomeCmd}
    Read
    ${echo_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${echo_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${EchoServerUdp}
    Read Until    initialized

Start Fallback_TCP
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start USC test VM for Fallback_TCP
    ${echo_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${echo_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${EchoServerTcp}
    Read Until    initialized

Start Fallback_UDP
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start USC test VM for Fallback_TCP
    ${echo_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${echo_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${EchoServerUdp}
    Read Until    initialized

Start Multiple_Sessions_TCP
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start USC test VM for Multiple_Sessions_TCP
    ${agent_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${agent_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${AgentTcp}
    Read
    ${L1}    Create List
    : FOR    ${port_index}    IN    @{LIST_ECHO_SERVER_PORT}
    \    Log    ${port_index}
    \    ${echo_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    \    Append To List    ${L1}    ${echo_conn_id}
    \    Flexible Mininet Login
    \    Write    ${NAV_USC_TOOLS}
    \    Write    java -jar EchoServer.jar -t true -p ${port_index}
    \    Read Until    initialized
    Set Suite Variable    ${L1}

Start Multiple_Sessions_UDP
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start USC test VM for Multiple_Sessions_UDP
    ${agent_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    Set Suite Variable    ${agent_conn_id}
    Flexible Mininet Login
    Write    ${NAV_USC_TOOLS}
    Write    ${AgentUdp}
    Read
    ${L1}    Create List
    : FOR    ${port_index}    IN    @{LIST_ECHO_SERVER_PORT}
    \    Log    ${port_index}
    \    ${echo_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    timeout=30s
    \    Append To List    ${L1}    ${echo_conn_id}
    \    Flexible Mininet Login
    \    Write    ${NAV_USC_TOOLS}
    \    Write    java -jar EchoServer.jar -t false -p ${port_index}
    \    Read Until    initialized
    Set Suite Variable    ${L1}

Stop Agent_Echo
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Log    Stop USC test VM for Agent_Echo
    Switch Connection    ${agent_conn_id}
    Read
    Write_Bare_Ctrl_C
    Write    exit
    Close Connection
    Switch Connection    ${echo_conn_id}
    Read
    Write_Bare_Ctrl_C
    Write    exit
    Close Connection

Stop Echo
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Log    Stop USC test VM for Echo
    Switch Connection    ${echo_conn_id}
    Read
    Write_Bare_Ctrl_C
    Write    exit
    Close Connection

Stop One_Agent_Multiple_Echo
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Log    Stop USC test VM for One_Agent_Multiple_Echo
    Switch Connection    ${agent_conn_id}
    Read
    Write_Bare_Ctrl_C
    Write    exit
    Close Connection
    : FOR    ${echo_conn_id}    IN    @{L1}
    \    Switch Connection    ${echo_conn_id}
    \    Read
    \    Write_Bare_Ctrl_C
    \    Write    exit
    \    Close Connection
