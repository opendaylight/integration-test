*** Settings ***
Documentation     Start the controllers
Default Tags      3-node-cluster
Resource          ../../../libraries/ClusterKeywords.robot

*** Variables ***
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    300s

*** Test Cases ***
Stop All Controllers
    [Documentation]    Stop all the controllers in the cluster.
    Stop One Or More Controllers    @{controllers}
    Wait For Cluster Down    @{controllers}    ${STOP_TIMEOUT}

Clean All Journals
    [Documentation]    Clean the journals of all the controllers in the cluster
    Clean One Or More Journals    @{controllers}

Start All Controllers
    [Documentation]    Start all the controllers in the cluster
    Start One Or More Controllers    @{controllers}
    Wait For Cluster Sync    @{controllers}    ${START_TIMEOUT}
