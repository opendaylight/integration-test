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
    Assign Labels
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status Is Running
    Coe.Collect Pod Names and Ping

*** Keywords ***
Apply label and Create pods
    [Arguments]    ${label}
    FOR    ${i}    IN RANGE    1    ${NO_OF_PODS_PER_VM}+1
        Coe.Create Pods    ${label}    ${label}-busybox${i}.yaml    ${label}-busybox${i}
    END

Assign Labels
    FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM}
        ${label} =    BuiltIn.Set Variable    ss${i}
        Apply label and Create pods    ${label}
    END
