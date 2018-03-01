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
Resource          ../../variables/netvirt/Variables.robot

*** Variables ***
${BUSY_BOX_1}     ${CURDIR}/../../variables/coe/busy-box-1.yaml
${BUSY_BOX_2}     ${CURDIR}/../variables/coe/busy-box-2.yaml
${BUSY_BOX_3}     ${CURDIR}/../variables/coe/busy-box-3.yaml
${BUSY_BOX_4}     ${CURDIR}/../variables/coe/busy-box-4.yaml

*** Test Cases ***
Verify_L2_Connectivity_Between_Pods
    [Documentation]    This testcase verifies the connectivity between pods on the same node.
    ...
    ...    _Steps_:
    ...    - Create pods \ - Check for pod status
    ...    - Ping pods to check connectivity
    Create_Pod_L2
    ${output}=    Verify_Pod_Status
    Ping_Pods    ${output}
    [Teardown]    Coe_Tear_Down

Verify_L3_Connectivity_Between_Pods
    [Documentation]    This testcase verifies the connectivity between pods brought up on different nodes
    ...
    ...    _Steps_:
    ...    - Create pods \ - Bring up tunnles between nodes
    ...    - Check for pod status
    ...    - Ping pods to check connectivity
    Create_Pod_L3
    ${output}=    Verify_Pod_Status
    Ping_Pods    ${output}
    [Teardown]    Coe_Tear_Down

*** Keywords ***
Create_Pod_L2
    [Documentation]    Copies the necessary yaml files in master and creates pods
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_1}    ${MASTER_HOME}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_2}    ${MASTER_HOME}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-1.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-2.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}

Ping_Pods
    [Arguments]    ${pods}
    [Documentation]    Ping pods to check connectivity between them
    ${lines}=    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    ${pod_1}    Get Line    ${lines}    1
    ${pod_1}=    Should Match Regexp    ${pod_1}    ^\\w+
    @{lines}=    Split To Lines    ${lines}    2
    : FOR    ${status}    IN    @{lines}
    \    ${pod_ip}=    Should Match Regexp    ${status}    ${IP_REGEX}
    \    ${ping}=    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl exec -it ${pod_1} -- ping -c 3 ${pod_ip}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    \    ...    ${DEFAULT_LINUX_PROMPT}
    \    Should Match Regexp    ${ping}    ${PING_REGEXP}

Create_Pod_L3
    [Documentation]    Creates tunnels between the nodes.Copies the necessary yaml files in master and creates pods
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_3}    ${MASTER_HOME}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${BUSY_BOX_4}    ${MASTER_HOME}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-3.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f busy-box-4.yaml    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
