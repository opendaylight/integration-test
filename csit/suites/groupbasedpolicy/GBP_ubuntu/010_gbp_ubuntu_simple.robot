*** Settings ***
Library           SSHLibrary

*** Variables ***
${prompt}=     #
${timeout}=    3s
${host}=       localhost
${user}=       root
${password}=     cisco
${delay}=      1s

*** Test Cases ***
Dump Flows
    SSHLibrary.Open Connection    ${host}    prompt=${prompt}    timeout=${timeout}
    SSHLibrary.Login    ${user}    ${password}    delay=${delay}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    ovs-ofctl dump-flows s1 -O OpenFlow13    return_stderr=True
    Log    ${stdout}
    Log    ${stderr}
    Should Be Empty 	${stderr}
    SSHLibrary.Close Connection
