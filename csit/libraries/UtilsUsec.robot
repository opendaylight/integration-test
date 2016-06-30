*** Settings ***
Documentation     General Utils library. This library has broad scope, it can be used by any robot system tests.
Library           SSHLibrary
Library           String
Library           DateTime
Library           Process
Library           Collections
Library           RequestsLibrary
Library           ./UtilLibrary.py
Resource          KarafKeywords.robot
Variables         ../variables/Variables.py

*** Variables ***
${start}   sudo  mn --controller remote --mac

${SYSTEM_IP}    127.0.0.1
${timeout}    30s
${USER}    stack
${PASSWORD}    stack
${PROMPT}    $
${OVS}     sh ovs-ofctl add-flow s1 priority=1,actions=NORMAL
${PING}      h1 ping h2
${READ}      64 bytes from 10.0.0.2: icmp_seq=1 ttl=64
${IPERFT}    iperf h1 h2
${IPERFTVALUE}    *** Results: ['
${OVSC}    sh ovs-ofctl add-flow s1 priority=2,actions=CONTROLLER
${DUMP}    sh ovs-ofctl dump-flows s1
${DUMPT}    cookie=0x0
${IPERF}        h1 iperf -c 10.0.0.2

*** Keywords ***
Start Suite
    [Arguments]    ${system}=${SYSTEM_IP}    ${user}=${USER}    ${password}=${PASSWORD}    ${prompt}=${PROMPT}    ${timeout}=5s   
    [Documentation]    Basic setup
    Log    Start Suite
    
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Mininet Login    user=${user}    password=${password}
    Mininet Command    ${mininet_conn_id}    
    

Mininet Command
    [Arguments]    ${mininet_conn_id}    
    [Documentation]    Run mininet command
    Switch Connection    ${mininet_conn_id}
    Write    ${start}
    Read Until    mininet> 
    SSHLibrary.Write    ${OVS}  
    SSHLibrary.Write    ${OVSC} 
    SSHLibrary.Write    ${IPERF}
    Close Connection
          

Stop Suite
    [Arguments]    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Log    Stop Suite
    


Flexible SSH Login
    [Arguments]    ${user}    ${password}=${EMPTY}    ${delay}=0.5s
    [Documentation]    On active SSH session: if given non-empty password, do Login, else do Login With Public Key.
    ${pwd_length} =    BuiltIn.Get Length    ${password}
    # ${pwd_length} is guaranteed to be an integer, so we are safe to evaluate it as Python expression.
    BuiltIn.Run Keyword And Return If    ${pwd_length} > 0    SSHLibrary.Login    ${user}    ${password}    delay=${delay}
    BuiltIn.Run Keyword And Return    SSHLibrary.Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    ${KEYFILE_PASS}    delay=${delay}

Flexible Mininet Login
    [Arguments]    ${user}=${USER}    ${password}=${PASSWORD}    ${delay}=0.5s
    [Documentation]    Call Flexible SSH Login, but with default values suitable for Mininet machine.
    BuiltIn.Run Keyword And Return    Flexible SSH Login    user=${user}    password=${password}    delay=${delay}


