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
    Log    start_suite_in_6_node
    :FOR    ${ip}    IN    @{vm_ip_list}
    \    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${timeout}
    \    Utils.Flexible Mininet Login
    \    SSHLibrary.Put Directory    ${CURDIR}/../../common_scripts    common_scripts/    mode=0755    recursive=True
    \    SSHLibrary.Execute Command    echo 'export ODL="${CONTROLLER}"' >> /home/${MININET_USER}/.profile"
    \    SSHLibrary.Close Connection

Stop Suite
    Log    stop_suite_in_6_node
    :FOR    ${ip}    IN    @{vm_ip_list}
    \    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${timeout}
    \    Utils.Flexible Mininet Login
    \    SSHLibrary.Execute Command    sudo rm -rf common_scripts
    \    SSHLibrary.Close Connection

