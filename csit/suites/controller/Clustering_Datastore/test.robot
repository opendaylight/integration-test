*** Settings ***
Documentation     test out sync keywords
Resource          ../../../libraries/ClusterKeywords.robot

*** Variables ***
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}

*** Test Cases ***
One Sync
    [Documentation]    check one sync
    Check Controller Sync    ${CONTROLLER}
