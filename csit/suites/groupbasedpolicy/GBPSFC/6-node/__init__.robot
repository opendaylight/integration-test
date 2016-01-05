*** Settings ***
Documentation     Setup/teardown for GBPSFC 6-node topology
Suite Setup       Setup Everything
Suite Teardown    Teardown Everything
Library           SSHLibrary
Library           RequestsLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Resource          Variables.robot
Variables         ../../../../variables/Variables.py

*** Variables ***
${timeout}        10s

*** Keywords ***
Setup Everything
    [Documentation]    Initial setup of remote VM. Copying of scripts and installation python packages to virtual env if missing.
    Create Session    session    http://${ODL}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Wait Until Keyword Succeeds    10x    30 s    Get Data From URI    session    ${OF_OVERLAY_CONFIG_PATH}    headers=${headers}
    Delete All Sessions
    : FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    # TODO if something extra needs to be installed, please do it in virt-env
    \    ${stderr}    SSHLibrary.Execute Command    virtualenv --system-site-packages ${VE_DIR}    return_stdout=False    return_stderr=True    return_rc=False
    \    Should Be Empty    ${stderr}
    \    SSHLibrary.Put File    ${CURDIR}/../../common_scripts/*    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755
    \    ${stdout}    ${stderr}    ${rc}    ConnUtils.Execute in VE    pip freeze | grep ipaddr -q || pip install ipaddr    timeout=${timeout}
    \    Should Be Equal As Numbers    ${rc}    0
    \    SSHLibrary.Close Connection
    Set ODL Variables

Teardown Everything
    [Documentation]    Clearing remote VM - removing copied scripts.
    Log    stop_suite_in_6_node
    : FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    SSHLibrary.Execute Command    sudo rm -rf ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}
    \    SSHLibrary.Close Connection
