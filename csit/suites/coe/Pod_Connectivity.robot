*** Settings ***
Suite Setup       Coe.Start Suite
Suite Teardown    Coe.Stop Suite
Test Teardown     Coe.Tear Down
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
@{BB_NAMES}       busybox1    busybox2    busybox3    busybox4
@{BUSY_BOXES}     busy-box-1.yaml    busy-box-2.yaml    busy-box-3.yaml    busy-box-4.yaml
${NO_OF_PODS}     10

*** Test Cases ***
Verify L2 Connectivity Between Pods
    [Documentation]    This testcase verifies the connectivity between pods brought up on the same node.Pods are brought on the same node by using the same node selector in busybox.yaml files.
    Create Pods    ssd    ${BUSY_BOXES[0]}    ${BB_NAMES[0]}
    Create Pods    ssd    ${BUSY_BOXES[1]}    ${BB_NAMES[1]}
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status Is Running
    Pod Matrix

Verify L3 Connectivity Between Pods
    [Documentation]    This testcase verifies the connectivity between pods brought up on different nodes.Nodes are given different labels(eg : ssd,ssl) through Coe.Label Nodes keyword.
    ...    These labels are also inlcuded as node selectors in busybox.yaml files ,thus the pods are placed on the desired nodes avoiding random allocation of pods.
    ...    For the pod to be eligible to run on a node, the node must have each of the indicated key-value pairs as labels.
    Create Pods    ssd    ${BUSY_BOXES[2]}    ${BB_NAMES[2]}
    Create Pods    ssl    ${BUSY_BOXES[3]}    ${BB_NAMES[3]}
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status Is Running
    Pod Matrix

Verify Connectivity Between n Pods
    : FOR    ${i}    INRANGE    1    ${NO_OF_PODS}+1
    \    Create Pods    ssd    busybox${i}.yaml    busybox${i}
    \    Create Pods    ssl    pod${i}.yaml    pod${i}
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status Is Running
    Pod Matrix

*** Keywords ***
Create Pods
    [Arguments]    ${label}    ${yaml}    ${name}
    [Documentation]    Creates pods using the labels of the nodes and busy box names passed as arguments.
    ${busybox} =    OperatingSystem.Get File    ${BUSY_BOX}
    ${busybox} =    String.Replace String    ${busybox}    string    ${label}
    ${busybox} =    String.Replace String    ${busybox}    busyboxname    ${name}
    OperatingSystem.Create File    ${VARIABLES_PATH}/${yaml}    ${busybox}
    SSHKeywords.Move_file_To_Remote_System    ${K8s_MASTER_IP}    ${VARIABLES_PATH}/${yaml}    ${USER_HOME}
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl create -f ${yaml}

Pod Matrix
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide
    @{lines} =    String.Split To Lines    ${lines}    1
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name} =    Builtin.Should Match Regexp    ${status}    ^\\w+
    \    Ping Pods    ${pod_name}     @{lines}

Ping Pods
    [Arguments]    ${pod_name}    @{lines}
    [Documentation]    Ping pods to check connectivity between them
    : FOR    ${status}    IN    @{lines}
    \    ${pod_ip} =    Builtin.Should Match Regexp    ${status}    \\d+.\\d+.\\d+.\\d+
    \    ${ping} =    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl exec -it ${pod_name} -- ping -c 3 ${pod_ip}
    \    Builtin.Should Match Regexp    ${ping}    ${PING_REGEXP}
