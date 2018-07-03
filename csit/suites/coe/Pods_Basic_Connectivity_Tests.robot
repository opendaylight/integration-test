*** Settings ***
Suite Setup       Coe.Start Suite
Suite Teardown
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
@{BB_NAMES}       busybox1    busybox2    busybox3    busybox4
@{BUSY_BOXES}     busy-box-1.yaml    busy-box-2.yaml    busy-box-3.yaml    busy-box-4.yaml

*** Test Cases ***
Verify L2 Connectivity Between Pods
    [Documentation]    This testcase verifies the connectivity between pods brought up on the same node.Pods are brought on the same node by using the same node selector in busybox.yaml files.
    Coe.Create Pods    ssd    ${BUSY_BOXES[0]}    ${BB_NAMES[0]}
    Coe.Create Pods    ssd    ${BUSY_BOXES[1]}    ${BB_NAMES[1]}
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status Is Running
    Coe.Collect Pod Names and Ping

Verify L3 Connectivity Between Pods
    [Documentation]    This testcase verifies the connectivity between pods brought up on different nodes.Nodes are given different labels(eg : ssd,ssl) through Coe.Label Nodes keyword.
    ...    These labels are also inlcuded as node selectors in busybox.yaml files ,thus the pods are placed on the desired nodes avoiding random allocation of pods.
    ...    For the pod to be eligible to run on a node, the node must have each of the indicated key-value pairs as labels.
    Coe.Create Pods    ssd    ${BUSY_BOXES[2]}    ${BB_NAMES[2]}
    Coe.Create Pods    ssl    ${BUSY_BOXES[3]}    ${BB_NAMES[3]}
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status Is Running
    Coe.Collect Pod Names and Ping
