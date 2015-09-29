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
    ${stderr}    SSHLibrary.Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py
    ...    return_stderr=True    return_stdout=False
    Run Keyword If    "${GBPSFC}" == "${GBPSFC3}"   Return From Keyword    ${stderr}
    ...    Run Keywords    ${stderr}    SSHLibrary.Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh ${GBPSFC2}
    ...    return_stderr=True    return_stdout=False    AND    Log    ${stderr}
    ...    ELSE IF    "${GBPSFC}" == "${GBPSFC5}"    Return From Keyword    ${stderr}
    ...    ${stderr}    SSHLibrary.Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh ${GBPSFC4}
    ...    return_stderr=True    return_stdout=False    AND    Log    ${stderr}
    SSHLibrary.Close Connection

Teardown Node
    [Arguments]    ${GBPSFC}    ${suite_dir}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

