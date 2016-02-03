*** Settings ***
Documentation     Restart all ODLs removing persisted data
Default Tags      3-node-cluster
Suite Setup       ClusterManagement.ClusterManagement_Setup
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot

*** Variables ***
${START_TIMEOUT}    300s

*** Test Cases ***
Kill_All_Members
    [Documentation]    Stop all the controllers in the cluster.
    ClusterManagement.Kill_Members_From_List_Or_All

Clear_Persisted_Data
    [Documentation]    Clean the journals and snapshots of all the controllers in the cluster.
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All

Start_All_Members
    [Documentation]    Start all the controllers in the cluster.
    ClusterManagement.Start_Members_From_List_Or_All    timeout=${START_TIMEOUT}
