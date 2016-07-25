*** Settings ***
Documentation     Test suite to Plot JVM Resources
Resource          ${CURDIR}/../../libraries/CheckJVMResource.robot
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot

*** Test Cases ***
Create JVM Plots
    ${is_cluster_env} =    Get Variable Value    \${ClusterManagement__has_setup_run}    False
    BuiltIn.Run_Keyword_If    ${is_cluster_env}    CheckJVMResource.Create JVM Plots Cluster    CheckJVMResource.Create JVM Plots
