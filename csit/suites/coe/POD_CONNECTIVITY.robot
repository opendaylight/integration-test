*** Settings ***
Suite Setup       Start_suite
Suite Teardown    Stop_Suite
Test Teardown
Library           BuiltIn
Library           SSHLibrary
Library           String
Resource          ../../libraries/Coe.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/SSHKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../variables/Variables.robot

*** Variables ***
${BUSY_BOX}       ${CURDIR}/../../variables/coe/busy-box.yaml
${VARIABLES_PATH}    ${CURDIR}/../../variables/coe
@{busyboxes}      busy-box-1.yaml    busy-box-2.yaml    busy-box-3.yaml    busy-box-4.yaml

*** Test Cases ***
Verify_L2_Connectivity_Between_Pods
    [Documentation]    This testcase verifies the connectivity between pods on the same node.
    Create_Pods    ${labels[0]}    ${busyboxes[0]}
    Create_Pods    ${labels[0]}    ${busyboxes[1]}
    ${output} =    Coe.Verify_Pod_Status
    Ping_Pods    ${output}
    [Teardown]    Coe_Tear_Down

Verify_L3_Connectivity_Between_Pods
    [Documentation]    This testcase verifies the connectivity between pods brought up on different nodes
    Create_Pods    ${labels[0]}    ${busyboxes[2]}
    Create_Pods    ${labels[1]}    ${busyboxes[3]}
    ${output} =    Coe.Verify_Pod_Status
    Ping_Pods    ${output}
    [Teardown]    Coe_Tear_Down

*** Keywords ***
Create_Pods
    [Arguments]    ${label}    ${yaml}
    ${file} =    OperatingSystem.Get File    ${BUSY_BOX}
    ${busybox} =    String.Replace String    ${file}    string    ${label}
    OperatingSystem.Create File    ${VARIABLES_PATH}/${yaml}    ${busybox}
    SSHKeywords.Move_file_To_Remote_System    ${K8s_MASTER_IP}    ${VARIABLES_PATH}/${yaml}    ${MASTER_HOME}
    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl create -f ${yaml}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}

Ping_Pods
    [Arguments]    ${pods}
    [Documentation]    Ping pods to check connectivity between them
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    ${pod_1} =    String.Get Line    ${lines}    1
    ${pod_1} =    Builtin.Should Match Regexp    ${pod_1}    ^\\w+
    @{lines} =    String.Split To Lines    ${lines}    2
    : FOR    ${status}    IN    @{lines}
    \    ${pod_ip} =    Builtin.Should Match Regexp    ${status}    ${IP_REGEX}
    \    ${ping} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl exec -it ${pod_1} -- ping -c 3 ${pod_ip}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    \    ...    ${DEFAULT_LINUX_PROMPT}
    \    Builtin.Should Match Regexp    ${ping}    ${PING_REGEXP}
