*** Settings ***
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBPSFC.robot

*** Variables ***
${prompt} =      >
${timeout} =     10s
${user} =        ${MININET_USER}
${password} =    ${MININET_PASSWORD}
${host} =        ${MININET}

*** Test Cases ***
Simple Dump Flows
    Open Connection    ${host}    prompt=${prompt}    timeout=${timeout}
    Log    010___
    Log    ${user}
    Log    ${password}
    Flexible Mininet Login    user=${user}    password=${password}
    ${stdout}    ${stderr}=    Execute Command    ovs-ofctl dump-flows sw1 -OOpenFlow13    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    Execute Command    docker ps    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    ${stdout}    ${stderr}=    Execute Command    sudo docker ps    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    # Should Be Empty 	${stderr}

    Close Connection
