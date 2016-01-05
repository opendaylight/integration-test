*** Settings ***
Library           SSHLibrary
Resource          Variables.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py

*** Keywords ***
Setup Node
    [Arguments]    ${GBPSFC}    ${sw_index}    ${suite_dir}    ${timeout}=10s
    [Documentation]    Configures underlying infrastructure composed of Docker containers and OVS switches on remote VM.
    ...    Python and Bash scripts are used.
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    SSHLibrary.Put File    ${suite_dir}/*    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755
    ${stdout}    ${stderr}    ${rc}    Execute in VE    python ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py ${ODL} ${sw_index}    timeout=${timeout}
    Should Be Equal As Numbers    ${rc}    0
    ${stderr}    Set Variable
    # Flows for GBPSFC3 and GBPSFC5 have to be written manually.
    # GBPSFC2 is SFF for GBPSFC3 and GBPSFC4 is SFF for GBPSFC5
    Run Keyword If    "${GBPSFC}" == "${GBPSFC3}"    Write SF Flows    ${GBPSFC2}    ${stderr}
    ...    ELSE IF    "${GBPSFC}" == "${GBPSFC5}"    Write SF Flows    ${GBPSFC4}    ${stderr}
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

Write SF Flows
    [Arguments]    ${SFF}    ${stderr}
    [Documentation]    Writes flows to SF node. SFF for given SF has to be specified in arguments.
    ${stderr}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh ${SFF}    return_stderr=True    return_stdout=False

Teardown Node
    [Arguments]    ${GBPSFC}    ${suite_dir}    ${timeout}=3s
    [Documentation]    Clears underlying infrastructure composed of Docker containers and OVS switches from remote VM.
    ...    Python and Bash scripts are used.
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_config.py    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/clean-demo.sh    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

Setup Nodes
    [Arguments]    ${GBPSFCs}    ${init_scripts_dir}
    ${sw_index}    Set Variable    0
    : FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    Setup Node    ${GBPSFC}    ${sw_index}    ${init_scripts_dir}    timeout=10s
    \    ${sw_index}    Evaluate    ${sw_index} + 1
