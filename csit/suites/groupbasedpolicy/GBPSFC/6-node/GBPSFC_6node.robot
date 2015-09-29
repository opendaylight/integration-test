*** Settings ***
Library           SSHLibrary
Resource          Variables.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py

*** Variables ****
${ODL}    ${CONTROLLER}

*** Keywords ***

Setup Node
    [Arguments]    ${GBPSFC}    ${sw_index}    ${suite_dir}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    SSHLibrary.Put File    ${suite_dir}/init_scripts/*    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755
    ${stdout}    ${stderr}    ${rc}    Execute in VE    python ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py ${ODL} ${sw_index}
    Should Be Equal As Numbers    ${rc}    0
    ${stderr}    Set Variable
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

Teardown Node
    [Arguments]    ${GBPSFC}    ${suite_dir}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_config.py
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/clean-demo.sh
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

