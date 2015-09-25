*** Settings ***
Library           SSHLibrary
Resource          ./Utils.robot

*** Variables ***
${prompt} =      $
${timeout} =     10s
${user} =        ${MININET_USER}
${password} =    ${MININET_PASSWORD}
@{mininet3_list} =    ${MININET}    ${MININET1}    ${MININET2}
@{mininet6_list} =    ${MININET}    ${MININET1}    ${MININET2}    ${MININET3}    ${MININET4}    ${MININET5}

*** Keywords ***
Setup Demo On Mininet
    [Arguments]    ${host}
    Open Connection    ${host}    prompt=${prompt}    timeout=${timeout}
    Log    gbp_res_setup DEBUG
    Log    ${user}
    Log    ${password}
    Flexible Mininet Login    user=${user}    password=${password}

    Put Directory    ${EXECDIR}/../scripts    scripts/    mode=0755    recursive=True
    Put File    ${EXECDIR}/spinup/infrastructure_config.py    scripts/    mode=0755
    ${rc}=    Execute Command    test -f ${EXECDIR}/spinup/sf-config.sh    return_rc=True
    Run Keyword If    ${rc} == 0    Put File    ${EXECDIR}/spinup/sf-config.sh    scripts/    mode=0755

    Log    ${CONTROLLER} DEBUG
    Set Environment Variable    $ODL       ${CONTROLLER}
    Set Environment Variable    ODL       ${CONTROLLER}
    ${stdout}=    Execute Command    echo $ODL
    Log    ${stdout}
    ${stdout}=    Execute Command    sudo scripts/infrastructure_launch.py
    Log    ${stdout}
    Close Connection

Postconfig On Mininet
    [Arguments]    ${host}
    Open Connection    ${host}    prompt=${prompt}    timeout=${timeout}
    Log    gbp_res_postconfig DEBUG
    Log    ${user}
    Log    ${password}
    ${stdout}=    Execute Command    echo $ODL
    Log    ${stdout}
    Flexible Mininet Login    user=${user}    password=${password}
    Put File    ${EXECDIR}/spinup/get-nsps.py    scripts/
    Execute Command    echo 'export ODL="${CONTROLLER}"' >> /home/${MININET_USER}/.profile"
    ${stdout}=    Execute Command    sudo scripts/get-nsps.py
    Log    ${stdout}
    Close Connection

Setup Demo On Mininets
    [Arguments]    @{host_list}
    :FOR    ${host}    IN    @{host_list}
    \    Setup Demo On Mininet    ${host}
    ${stdout}=    Execute Command    echo $ODL
    Log    ${stdout}
    ${stdout}=    Run    ${EXECDIR}/rest.py
    Log    ${stdout}
    :FOR    ${host}    IN    @{host_list}
    \    Postconfig On Mininet    ${host}
