*** Settings ***
Documentation     Setup/teardown for GBP 3-node topology
Suite Setup       Setup Everything
Suite Teardown    Teardown Everything
Library           SSHLibrary
Library           RequestsLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py
Resource          Variables.robot

*** Variables ***
${timeout}        10s

*** Keywords ***
Setup Everything
    Log    start_suite_in_3_node
    Create Session    session    http://${ODL}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Wait Until Keyword Succeeds    10x    30 s    Get Data From URI    session    ${OF_OVERLAY_CONFIG_PATH}    headers=${headers}
    Delete All Sessions
    : FOR    ${GBP}    IN    @{GBPs}
    \    ConnUtils.Connect and Login    ${GBP}    timeout=${timeout}
    \    ${stderr}    SSHLibrary.Execute Command    virtualenv --system-site-packages ${VE_DIR}    return_stdout=False    return_stderr=True    return_rc=False
    \    Should Be Empty    ${stderr}
    \    SSHLibrary.Put File    ${CURDIR}/../../common_scripts/*    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755
    \    ${stdout}    ${stderr}    ${rc}    ConnUtils.Execute in VE    pip freeze | grep ipaddr -q || pip install ipaddr    timeout=${timeout}
    \    Should Be Equal As Numbers    ${rc}    0
    \    SSHLibrary.Close Connection
    Init Variables

Teardown Everything
    Log    stop_suite_in_3_node
    : FOR    ${GBP}    IN    @{GBPs}
    \    ConnUtils.Connect and Login    ${GBP}    timeout=${timeout}
    \    SSHLibrary.Execute Command    sudo rm -rf ${VM_SCRIPTS_FOLDER}
    \    SSHLibrary.Close Connection
