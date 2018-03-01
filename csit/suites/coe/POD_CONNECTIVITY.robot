*** Settings ***
Suite Setup       Start_suite
Suite Teardown    Stop_Suite
Test Teardown
Library           SSH Library
Resource          ../../libraries/SSHKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Library           String
Library           BuiltIn
Resource          ../../libraries/Coe.robot
Resource          ../../variables/genius/Modules.py

*** Variables ***
${BUSY_BOX_1}     /home/mininet/test/csit/variables/coe/busy-box-1.yaml
${BUSY_BOX_2}     /home/mininet/test/csit/variables/coe/busy-box-2.yaml
${PING REGEX}     0% packet loss
${BUSY_BOX_3}     /home/mininet/test/csit/variables/coe/busy-box-3.yaml
${BUSY_BOX_4}     /home/mininet/test/csit/variables/coe/busy-box-4.yaml
${NO_OF_PODS}     2

*** Test Cases ***
Verify_L2_Connectivity_Between_Pods_on_Samenode
    Create_Pod_L2
    ${output}=    Verify_Pod_Status
    Ping_Pods    ${output}
    Delete_Pods

Verify_L3_Connectivity_Between_Pods
    Create_Pod_L3
    ${ip}=    Verify_Pod_Status
    Ping_Pods    ${ip}
    Delete_Pods

*** Keywords ***
Create_Pod_L2
    Comment    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_1}    ${MASTER_HOME}
    Comment    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_2}    ${MASTER_HOME}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-1.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-2.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    sleep    5s

Verify_Pod_Status
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    kubectl get pods -o wide
    Comment    ${pods}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    Comment    ${running}=    Get Lines Matching Regexp    ${pods}    \\sRunning    partial_match=true
    Comment    ${count}=    Get Line Count    ${running}
    Comment    Close Connection
    Comment    Run Keyword If    ${count}!=${NO_OF_PODS}    Verify_Pod_Status
    ${pods}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    Should Contain X Times    ${pods}=    Running    ${NO_OF_PODS}
    [Return]    ${pods}

Ping_Pods
    [Arguments]    ${pods}
    Set Client Configuration    prompt=$
    Write    kubectl get pods -o wide
    ${lines}=    Read Until Prompt
    ${count}=    Get Line Count    ${lines}
    ${pod_1}    Get Line    ${lines}    1
    ${pod_1}=    Should Match Regexp    ${pod_1}    ^\\w+
    @{lines}=    Split To Lines    ${lines}    2    ${count-1}
    : FOR    ${status}    IN    @{lines}
    \    ${pod_ip}=    Should Match Regexp    ${status}    \\d+.\\d+.\\d+.\\d+
    \    ${ping}=    Execute Command    kubectl exec -it ${pod_1} -- ping -c 3 ${pod_ip}
    \    Should Contain    ${ping}    0% packet loss

Create_Pod_L3
    Tunnel_Creation    ${K8s_MASTER_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Tunnel_Creation    ${K8s_MINION1_IP}    ${MINION1_USER}    ${MINION1_PASSWORD}
    Tunnel_Creation    ${K8s_MINION2_IP}    ${MINION2_USER}    ${MINION2_PASSWORD}
    Comment    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_3}    ${MASTER_HOME}
    Comment    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_4}    ${MASTER_HOME}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-3.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-4.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    sleep    5s

Tunnel_Creation
    [Arguments]    ${NODE_IP}    ${NODE_USER}    ${NODE_PASSWORD}
    Open Connection    ${NODE_IP}
    Login    ${NODE_USER}    ${NODE_PASSWORD}
    Write    sudo ovs-vsctl \ \ \ set O . other_config:local_ip=${NODE_IP}
    write    ${NODE_PASSWORD}
    Write    sudo ovs-vsctl \ \ \ set O . external_ids:br-name=ovsbrk8s
    Write    sudo ovs-vsctl show
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    ${tunnels}=    Read Until Prompt
    log    ${tunnels}
    Close Connection

Delete_Pods
    Set Client Configuration    prompt=$
    Write    kubectl get pods -o wide
    ${lines}=    Read Until Prompt
    ${count}=    Get Line Count    ${lines}
    @{lines}=    Split To Lines    ${lines}    1    ${count-1}
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name}=    Should Match Regexp    ${status}    ^\\w+
    \    Execute Command    kubectl delete pods ${pod_name}
    Write Until Expected Output    kubectl get pods -o wide    No resources    1 minute    2s
