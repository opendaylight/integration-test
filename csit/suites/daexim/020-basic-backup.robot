*** Settings ***
Documentation     Test suite for backing up data and models
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Library           String
Library           DateTime
Resource          ../../variables/Variables.robot
Resource          ../../variables/daexim/DaeximVariables.robot
Resource          ../../libraries/DaeximKeywords.robot
Resource          ../../libraries/ClusterOpenFlow.robot
Variables         ../../variables/Variables.py

*** Test Cases ***
Create and Verify Backup
    [Documentation]     schedule and verify backup of a cluster
    [Tags]    backup
    #Mount Netconf Devices    ${MOUNT_EP1}    ${ENDPOINT_1}
    Schedule Backup    1    ${CONTROLLER}
    Wait Until Keyword Succeeds    20 sec    5 sec    Verify Backup Status    complete    1
    Verify Backup Files
    Copy Backup Directory To Test VM
