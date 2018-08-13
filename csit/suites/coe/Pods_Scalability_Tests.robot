*** Settings ***
Suite Setup       Coe Suite Setup
Suite Teardown    Coe Suite Teardown
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
${NO_OF_PODS_PER_VM}    9

*** Test Cases ***
Verify Connectivity Between Pods
    [Documentation]    Verify ping between 'n' number of pods brought up per vm.Each pod should be able to ping other pod amounting to a total of 'y' pings where , \ y = "No of pods/minion * No of minions * Total no of pods".
    Assign Labels
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status Is Running
    Coe.Collect Pod Names and Ping

*** Keywords ***
Apply label and Create pods
    [Arguments]    ${label}
    [Documentation]    Create pods on each minion by passing the label assigned to minions,yaml file for creating a pod and the name of pod.The yaml file and pod name are assigned according to the label to easily identify the minion a particular pod belongs to.
    : FOR    ${i}    IN RANGE    1    ${NO_OF_PODS_PER_VM}+1
    \    Coe.Create Pods    ${label}    ${label}-busybox${i}.yaml    ${label}-busybox${i}

Assign Labels
    [Documentation]    Assign lables to minions as ss(n) where n stands for the nth minion in the cluster.
    : FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM}
    \    ${label} =    BuiltIn.Set Variable    ss${i}
    \    Apply label and Create pods    ${label}
