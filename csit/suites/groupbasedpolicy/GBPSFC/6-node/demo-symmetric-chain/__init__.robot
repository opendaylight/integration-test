*** Settings ***
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Variables         ../../../../variables/Variables.py


*** Variables ***
${timeout} =     10s
@{vm_ip_list} =    ${MININET}    ${MININET1}    ${MININET2}    ${MININET3}    ${MININET4}    ${MININET5}


*** Keywords ***
Start Suite
    Log    start_suite_in_symetric-chain
    :FOR    ${ip}    IN    @{vm_ip_list}
    \    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${timeout}
    \    Utils.Flexible Mininet Login
    \    SSHLibrary.Put Directory    ${CURDIR}/init_scripts    init_scripts/    mode=0755    recursive=True
    \    SSHLibrary.Execute Command    sudo init_scripts/infrastructure_launch.py
    \    SSHLibrary.Execute Command    sudo init_scripts/get-nsps.py
    \    SSHLibrary.Close Connection

Stop Suite
    Log    stop_suite_in_symetric-chain
    :FOR    ${ip}    IN    @{vm_ip_list}
    \    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${timeout}
    \    Utils.Flexible Mininet Login
    \    SSHLibrary.Execute Command    sudo rm -rf init_scripts
    \    SSHLibrary.Close Connection
    
