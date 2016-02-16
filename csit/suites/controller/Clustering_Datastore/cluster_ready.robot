*** Settings ***
Documentation     This test waits until cluster appears to be ready.
...               Intended use is at a start of testplan so that suites can assume cluster works.
Default Tags      3-node-cluster    critical
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot

*** Variables ***
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    300s

*** Test Cases ***
Wait_For_Sync
    [Documentation]    Repeatedly check for cluster sync status, pass if sync within timeout.
    ClusterManagement.Check_Cluster_Is_In_Sync
