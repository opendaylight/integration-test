*** Settings ***
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py
Resource          Variables.robot


*** Keywords ***

Setup Node
    [Arguments]    ${GBPSFC}    ${suite_dir}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    SSHLibrary.Put Directory    ${suite_dir}/init_scripts    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/
    ...    mode=0755    recursive=True
    SSHLibrary.Execute Command
    ...    mv ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts/* ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}
    SSHLibrary.Execute Command    rm -rf ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts/
    ${stderr}    SSHLibrary.Execute Command
    ...    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/execute-in-ve.sh python ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py ${CONTROLLER}
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    Run Keyword If    "${GBPSFC}" == "${GBPSFC3}"
    ...    Write SF Flows    ${GBPSFC2}    ${stderr}
    ...    ELSE IF    "${GBPSFC}" == "${GBPSFC5}"
    ...    Write SF Flows    ${GBPSFC4}    ${stderr}
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

Write SF Flows
    [Arguments]    ${SFF}    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh ${SFF}
    ...    return_stderr=True    return_stdout=False
    [Return]    ${stderr}

Teardown Node
    [Arguments]    ${GBPSFC}    ${suite_dir}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_config.py
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command
    ...    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/execute-in-ve.sh python ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/clean-demo.sh
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

