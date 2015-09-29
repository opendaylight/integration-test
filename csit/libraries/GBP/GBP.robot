*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot
Variables         ../../variables/Variables.py

*** Variables ***
${timeout} =     10s
${user} =        ${MININET_USER}
${password} =    ${MININET_PASSWORD}

*** Keywords ***
Setup Demo On Vm
    [Arguments]    ${ip}    ${path}
    Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${timeout}
    Log    gbp_res_setup DEBUG
    Log    ${user}
    Log    ${password}
    Flexible Mininet Login    user=${user}    password=${password}

    Put Directory    ${CURDIR}/../../suites/groupbasedpolicy/scripts    scripts/    mode=0755    recursive=True
    Put File    ${EXECDIR}/${path}/spinup/infrastructure_config.py    scripts/    mode=0755
#    ${rc}=    Execute Command    test -f ${EXECDIR}/${path}/spinup/sf-config.sh    return_rc=True
#    Run Keyword If    ${rc} == 0    Put File    ${EXECDIR}/${path}/spinup/sf-config.sh    scripts/    mode=0755

    Log    ${CONTROLLER} DEBUG
    Execute Command    echo 'export ODL="${CONTROLLER}"' >> /home/${MININET_USER}/.profile"
    Write    export ODL="${CONTROLLER}"
    Log    ${MININET_USER}    DEBUG
    Write    echo $ODL
    ${output}=    Read
    Log    ${output}    DEBUG
    ${stdout}=    Execute Command    sudo scripts/infrastructure_launch.py
    Log    ${stdout}    DEBUG
    Close Connection

Postconfig On Vm
    [Arguments]    ${ip}
    Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${timeout}
    Log    gbp_res_postconfig    DEBUG
    Log    ${user}    DEBUG
    Log    ${password}    DEBUG
    ${stdout}=    Execute Command    echo $ODL
    Log    ${stdout}    DEBUG
    Flexible Mininet Login    user=${user}    password=${password}
    Put File    ${EXECDIR}/${path}/spinup/get-nsps.py    scripts/
#    Execute Command    echo 'export ODL="${CONTROLLER}"' >> /home/${MININET_USER}/.profile"
    ${stdout}=    Execute Command    sudo scripts/get-nsps.py
    Log    ${stdout}
    Close Connection

Setup Demo On Vms
    [Arguments]    ${path}    @{ip_list}
    :FOR    ${ip}    IN    @{ip_list}
    \    Setup Demo On Vm    ${ip}    ${path}
#    ${stdout}=    Run    ${EXECDIR}/rest.py
#    Log    ${stdout}
#    :FOR    ${ip}    IN    @{ip_list}
#    \    Postconfig On Vm    ${ip}
