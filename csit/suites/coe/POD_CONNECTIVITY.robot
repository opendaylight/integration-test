*** Settings ***
Suite Setup       Start_suite
Suite Teardown    Close All Connections
Library           SSH Library
Resource          ../../libraries/SSHKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Library           String
Library           BuiltIn
Resource          ../../libraries/Coe.robot

*** Variables ***
${BUSY_BOX_1}     /home/mininet/test/csit/variables/coe/busy-box-1.yaml
${BUSY_BOX_2}     /home/mininet/test/csit/variables/coe/busy-box-2.yaml
${PING REGEX}     0% packet loss

*** Test Cases ***
Verify_L2_Connectivity_Between_Pods_on_Samenode
    Create_Pod
    ${output}=    Verify_Pod_Creation
    Ping_Pods    ${output}

*** Keywords ***
Create_Pod
    Comment    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f ${BUSY_BOX_1}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Comment    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f ${BUSY_BOX_2}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Comment    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_1}    ${MASTER_HOME}
    Comment    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_2}    ${MASTER_HOME}
    Write    kubectl create -f busy-box.yaml
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Read Until Prompt
    Write    kubectl create -f busy-box-2.yaml
    sleep     5s
    Close Connection

Verify_Pod_Creation
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Comment    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Comment    Read Until Prompt
    Write    kubectl get pods -o wide
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    ${pods}=    Read Until Prompt
    Should Contain X Times    ${pods}    Running    2
    [Return]    ${pods}

Ping_Pods
    [Arguments]    ${pods}
    ${pod_line}=    Get Line    ${pods}    2
    ${POD2_IP}=    Should Match Regexp    ${pod_line}=    \\d+.\\d+.\\d+.\\d+
    ${ping}=    Execute Command    kubectl exec -it busybox1 -- ping -c 3 ${POD2_IP}
    Should Contain    ${ping}    ${PING REGEX}
