*** Settings ***
Documentation     Test cleanup
Default Tags      3-node-cluster
Resource          ../../../libraries/ClusterKeywords.robot
Library           ../../../libraries/UtilLibrary.py
Variables         ../../../variables/Variables.py

*** Variables ***
@{controllers}    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_2_IP}    ${CONTROLLER2}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}

*** Test Cases ***
Kill All Controllers
    [Documentation]    Kill all the karaf processes in the cluster
    Kill One Or More Controllers    @{controllers}

Clean All Journals
    [Documentation]    Clean the journals of all the controllers in the cluster
    Clean One Or More Journals    @{controllers}
    Clean One Or More Snapshots    @{controllers}
