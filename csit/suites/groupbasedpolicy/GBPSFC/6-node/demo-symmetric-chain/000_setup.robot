*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot


*** Variables ***
${timeout} =     10s


*** Test Cases ***
Setup Suite
    Log    Setup suite in symetric-chain
    # TODO identical to asymetric-chain, could be unificated?
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    SSHLibrary.Put Directory    ${CURDIR}/init_scripts    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755    recursive=True
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cd ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}; ls -la    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cd ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts; ls -la    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    mv ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts/* ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cd ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}; ls -la    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    rm -rf ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/init_scripts/    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cd ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}; ls -la    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    # TODO 'cat'->'sudo' x2
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cat ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_launch.py    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cat ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/get-nsps.py    return_stderr=True
    \    Log    ${stdout}
    \    Log    ${stderr}
    \    SSHLibrary.Close Connection
