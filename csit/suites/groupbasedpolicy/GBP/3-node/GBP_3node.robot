*** Settings ***
Library           SSHLibrary
Resource          Variables.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py

*** Keywords ***
Setup Node
    [Arguments]    ${GBP}    ${suite_dir}    ${sw_index}    ${timeout}=10s
    ConnUtils.Connect and Login    ${GBP}    timeout=${timeout}
    SSHLibrary.Put File    ${suite_dir}/init_scripts/*    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755
    ${stdout}    ${stderr}    ${rc}    Execute in VE    python ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py ${ODL_SYSTEM_IP} ${sw_index}    timeout=${timeout}
    Should Be Equal As Numbers    ${rc}    0
    SSHLibrary.Close Connection

Teardown Node
    [Arguments]    ${GBP}    ${suite_dir}    ${timeout}=3s
    ConnUtils.Connect and Login    ${GBP}    timeout=${timeout}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_config.py    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/clean-demo.sh    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection
