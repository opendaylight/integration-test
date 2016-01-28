*** Settings ***
Documentation     Start the controllers
Default Tags      3-node-cluster
Resource          ../../../libraries/ClusterKeywords.robot

*** Variables ***
@{controllers}    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}

*** Test Cases ***
Stop All Controllers
    [Documentation]    Stop all the controllers in the cluster
    Stop One Or More Controllers    @{controllers}

Clean All Journals
    [Documentation]    Clean the journals of all the controllers in the cluster
    Clean One Or More Journals    @{controllers}

Start All Controllers
    [Documentation]    Start all the controllers in the cluster
    Start One Or More Controllers    @{controllers}
