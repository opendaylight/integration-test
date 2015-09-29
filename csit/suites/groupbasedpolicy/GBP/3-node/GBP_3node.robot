*** Settings ***
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py
Resource          Variables.robot


*** Keywords ***

Setup Node
    [Arguments]    ${GBP}    ${suite_dir}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBP}    timeout=${timeout}
    SSHLibrary.Put Directory    ${suite_dir}/init_scripts    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/
    ...    mode=0755    recursive=True
    SSHLibrary.Execute Command
    ...    mv ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts/* ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}
    SSHLibrary.Execute Command    rm -rf ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts/
    ${stderr}    Execute in VE    python ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py ${CONTROLLER}
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

Teardown Node
    [Arguments]    ${GBPSFC}    ${suite_dir}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_config.py
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/clean-demo.sh
    ...    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

