*** Settings ***
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Variables         ../../../../variables/Variables.py


*** Variables ***
${timeout} =     10s
@{vm_ip_list} =    ${MININET}    ${MININET1}    ${MININET2}    ${MININET3}    ${MININET4}    ${MININET5}


*** Test Cases ***
Setup Suite
    Log    Setup suite in symetric-chain
    :FOR    ${ip}    IN    @{vm_ip_list}
    \    SSHLibrary.Open Connection    ${ip}    timeout=${timeout}
    \    Utils.Flexible Mininet Login
    \    SSHLibrary.Put Directory    ${CURDIR}/init_scripts    init_scripts/    mode=0755    recursive=True
    \    SSHLibrary.Execute Command    sudo init_scripts/infrastructure_launch.py
    \    SSHLibrary.Execute Command    sudo init_scripts/get-nsps.py
    \    SSHLibrary.Close Connection
