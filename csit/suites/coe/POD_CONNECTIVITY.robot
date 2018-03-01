*** Settings ***
Suite Setup       Start_suite
Suite Teardown    Stop_Suite
Test Teardown
Library           SSHLibrary
Resource          ../../libraries/SSHKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Library           String
Library           BuiltIn
Resource          ../../libraries/Coe.robot
Resource          ../../libraries/DataModels.robot

*** Variables ***
${BUSY_BOX_1}     ${CURDIR}/../variables/coe/busy-box-1.yaml
${BUSY_BOX_2}     ${CURDIR}/../variables/coe/busy-box-2.yaml
${PING REGEX}     0% packet loss
${BUSY_BOX_3}     ${CURDIR}/../variables/coe/busy-box-3.yaml
${BUSY_BOX_4}     ${CURDIR}/../variables/coe/busy-box-4.yaml

*** Test Cases ***
Verify_L2_Connectivity_Between_Pods_on_Samenode
    Create_Pod_L2
    ${output}=    Verify_Pod_Status
    Ping_Pods    ${output}
    Delete_Pods
    [Teardown]    Coe_Tear_Down

Verify_L3_Connectivity_Between_Pods
    Create_Pod_L3
    ${ip}=    Verify_Pod_Status
    Ping_Pods    ${ip}
    Delete_Pods

*** Keywords ***
Create_Pod_L2
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_1}    ${MASTER_HOME}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_2}    ${MASTER_HOME}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-1.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-2.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}

Ping_Pods
    [Arguments]    ${pods}
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Write    kubectl get pods -o wide
    ${lines}=    Read Until Prompt
    ${count}=    Get Line Count    ${lines}
    ${pod_1}    Get Line    ${lines}    1
    ${pod_1}=    Should Match Regexp    ${pod_1}    ^\\w+
    @{lines}=    Split To Lines    ${lines}    2    ${count-1}
    : FOR    ${status}    IN    @{lines}
    \    ${pod_ip}=    Should Match Regexp    ${status}    \\d+.\\d+.\\d+.\\d+
    \    ${ping}=    Execute Command    kubectl exec -it ${pod_1} -- ping -c 3 ${pod_ip}
    \    Should Contain    ${ping}    ${PING REGEX}

Create_Pod_L3
    Tunnel_Creation    ${K8s_MASTER_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Tunnel_Creation    ${K8s_MINION1_IP}    ${MINION1_USER}    ${MINION1_PASSWORD}
    Tunnel_Creation    ${K8s_MINION2_IP}    ${MINION2_USER}    ${MINION2_PASSWORD}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_3}    ${MASTER_HOME}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_4}    ${MASTER_HOME}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-3.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-4.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}

Tunnel_Creation
    [Arguments]    ${NODE_IP}    ${NODE_USER}    ${NODE_PASSWORD}
    Open Connection    ${NODE_IP}
    Login    ${NODE_USER}    ${NODE_PASSWORD}
    Write    sudo ovs-vsctl \ \ \ set O . other_config:local_ip=${NODE_IP}
    Write    sudo ovs-vsctl \ \ \ set O . external_ids:br-name=br-int
    Write    sudo ovs-vsctl show
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    ${tunnels}=    Read Until Prompt
    log    ${tunnels}
    Close Connection
