*** Settings ***
Documentation     Test cleanup
Default Tags      3-node-cluster
Resource          ../../../libraries/ClusterKeywords.txt
Library           ../../../libraries/UtilLibrary.py
Variables         ../../../variables/Variables.py

*** Variables ***
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}

*** Test Cases ***
Kill All Controllers
    [Documentation]    Kill all the karaf processes in the cluster
    Kill One Or More Controllers    @{controllers}

Clean All Journals
    [Documentation]    Clean the journals of all the controllers in the cluster
    Clean One Or More Journals    @{controllers}
