*** Settings ***
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Variables         ../../../../variables/Variables.py


*** Variables ***
${timeout} =     10s
@{vm_ip_list} =    ${MININET}    ${MININET1}    ${MININET2}    ${MININET3}    ${MININET4}    ${MININET5}


*** Test Cases ***
Teardown Suite
    Log    Teardown suite in symetric-chain
    :FOR    ${ip}    IN    @{vm_ip_list}
    \    SSHLibrary.Open Connection    ${ip}    timeout=${timeout}
    \    Utils.Flexible Mininet Login
    \    SSHLibrary.Execute Command    sudo rm -rf init_scripts
    \    SSHLibrary.Close Connection
    
