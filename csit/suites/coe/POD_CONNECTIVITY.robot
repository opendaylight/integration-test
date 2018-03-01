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
${BUSY_BOX_1}     ${CURDIR}/test/csit/variables/coe/busy-box-1.yaml
${BUSY_BOX_2}     ${CURDIR}/test/csit/variables/coe/busy-box-2.yaml
${PING REGEX}     0% packet loss

*** Test Cases ***
Verify_L2_Connectivity_Between_Pods_on_Samenode
    Create_Pod
    ${output}=    Verify_Pod_Creation
    Ping_Pods    ${output}

*** Keywords ***
Create_Pod
    Run Command On Remote System    ${K8s_MINION1_IP}    kubectl create -f ${BUSY_BOX_1}    ${MINION1_USER}    ${MINION1_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Run Command On Remote System    ${K8s_MINION2_IP}    kubectl create -f ${BUSY_BOX_2}    ${MINION2_USER}    ${MINION2_PASSWORD}    ${DEFAULT_LINUX_PROMPT}

Verify_Pod_Creation
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    kubectl get pods -o wide
    ${pods}=    Read Until Prompt
    Should Contain X Times    ${pods}    Running    2
    [Return]    ${pods}

Ping_Pods
    [Arguments]    ${pods}
    ${pod_line}=    Get Line    ${pods}    2
    ${POD2_IP}=    Should Match Regexp    ${pod_line}=    \\d+.\\d+.\\d+.\\d+
    ${ping}=    Execute Command    kubectl exec -it busybox1 -- ping -c 3 ${POD2_IP}
    Should Contain    ${ping}    ${PING REGEX}
