*** Settings ***
Documentation    Verify that Setup on VM done correctly
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot


*** Variables ***
${timeout} =     10s


*** Testcases ***

Simple Test Case
    ConnUtils.Connect and Login    ${GBPSFC3}    timeout=${timeout}
    Log    ${GBPSFC3}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cd ${VM_SCRIPTS_FOLDER}; ls -la    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cat .profile    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    echo $ODL    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    SSHLibrary.Close Connection
