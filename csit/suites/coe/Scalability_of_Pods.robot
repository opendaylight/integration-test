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
${NO_OF_PODS_PER_VM}    15

*** Test Cases ***
Verify Connectivity Between Pods
    : FOR    ${i}    IN RANGE    1    ${NO_OF_PODS_PER_VM}+1
    \    Coe.Create Pods    ssd    busybox${i}.yaml    busybox${i}
    \    Coe.Create Pods    ssl    pod${i}.yaml    pod${i}
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status Is Running
    Coe.Collect Pod Names and Ping
