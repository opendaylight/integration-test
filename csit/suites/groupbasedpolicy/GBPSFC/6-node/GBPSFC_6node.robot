*** Settings ***
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py
Resource          Variables.robot


*** Keywords ***

Setup Node
    [Arguments]    ${GBPSFC}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    SSHLibrary.Put Directory    ${EXECDIR}/init_scripts    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/
    ...    mode=0755    recursive=True
    SSHLibrary.Execute Command
    ...    mv ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts/* ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}
    SSHLibrary.Execute Command    rm -rf ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts/
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py
    ...    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/get-nsps.py
    ...    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    SSHLibrary.Close Connection

Teardown Node
    [Arguments]    ${GBPSFC}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py
    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/get-nsps.py
    SSHLibrary.Close Connection

