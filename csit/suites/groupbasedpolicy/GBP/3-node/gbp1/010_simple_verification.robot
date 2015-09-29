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
    Log    gbp1 010 on ${GBPSFC3}
    ConnUtils.Connect and Login    ${GBPSFC3}    timeout=${timeout}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cd ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}; ls -la    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    cat ${VM_HOME_FOLDER}${/}.profile    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    echo $ODL    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    echo $CONTROLLER    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    echo $CONTROLLER0    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    SSHLibrary.Close Connection
