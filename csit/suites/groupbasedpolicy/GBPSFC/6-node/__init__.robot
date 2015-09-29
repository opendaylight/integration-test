*** Settings ***
Documentation     Setup/teardown for GBPSFC 6-node topology
Suite Setup       Setup Everything
Suite Teardown    Teardown Everything
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py
Resource          Variables.robot


*** Variables ***
${timeout} =     10s


*** Keywords ***
Setup Everything
    Log    start_suite_in_6_node
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    ${stdout}=    SSHLibrary.Execute Command    pwd
    \    Log    ${stdout}
    \    SSHLibrary.Put Directory    ${CURDIR}/../../common_scripts    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}    mode=0755    recursive=True
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    ls -la    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cd ${VM_HOME_FOLDER}; ls -la    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cd ${VM_HOME_FOLDER}/scripts; ls -la    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    echo "export ODL=${CONTROLLER}" >> ${VM_HOME_FOLDER}/.profile    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    SSHLibrary.Close Connection

Teardown Everything
    Log    stop_suite_in_6_node
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    SSHLibrary.Execute Command    sudo rm -rf ${VM_SCRIPTS_FOLDER}
    \    SSHLibrary.Close Connection
