*** Settings ***
Documentation     This suite covers daexim functionality with applications like ELAN,L3VPN etc
Suite Setup       Check_Cluster_Is_In_Sync    Create Setup With 20Vms
Suite Teardown    Delete All Sessions
Resource          ../../variables/daexim/DaeximVariables.robot
Resource          ../../libraries/DaeximKeywords.robot
Resource          ../../libraries/OpenStackOperations.robot

*** Test Cases ***
Elan-With-Daexim
    [Documentation]    Verifying the 20 Elan instances with Daexim. \
    log    <<Elan Functionality Verifications with 20VM Instances >>
    ELAN Functionality Verification
    Log    <<Data Export and Import and Comparing the backup Json Files>>
    Data Export Import Process
    log    <<Elan Functionality Verifications with 20VM Instances >>
    ELAN Functionality Verification
