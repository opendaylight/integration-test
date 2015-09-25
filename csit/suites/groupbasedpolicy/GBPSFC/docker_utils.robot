*** Settings ***
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot

*** Keywords ***
Ping from Docker
    [Arguments]    ${mininet_address}    ${docker_name}    ${dest_addresses}    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}
    ${mininet_conn_id}=    Open Connection    ${mininet_address}
    Flexible SSH Login     ${user}    ${password}
    SSHLibrary.Write    sudo docker attach ${docker_name}
    SSHLibrary.Write    hostname
    ${output}=    Read Until   ${docker_name}
    :FOR    ${dest_address}    IN    @{dest_addresses}
    \    SSHLibrary.Write    ping ${dest_address} -c1
    \    ${output}=    Read Until   seq
    \    Should Contain    ${output}    seq

Start HTTP Service on Docker
    [Arguments]    ${mininet_address}    ${docker_name}    ${service_port}=80    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}
    ${mininet_conn_id}=    Open Connection    ${mininet_address}
    Flexible SSH Login     ${user}    ${password}
    SSHLibrary.Write    sudo docker attach ${docker_name}
    SSHLibrary.Write    hostname
    ${output}=    Read Until   ${docker_name}
    SSHLibrary.Write    python -m SimpleHTTPServer ${service_port} &
    Log    (${service_port})|(already)( )(in)( )(use)
    ${output}=    Read Until Regexp    (${service_port})|(already)( )(in)( )(use)
    SSHLibrary.Close Connection

Curl from Docker
    [Arguments]    ${mininet_address}    ${docker_name}    ${dest_addres}    ${service_port}=80    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}
    ${mininet_conn_id}=    Open Connection    ${mininet_address}
    Flexible SSH Login     ${user}    ${password}
    SSHLibrary.Write    sudo docker attach ${docker_name}
    SSHLibrary.Write    hostname
    ${output}=    Read Until   ${docker_name}
    SSHLibrary.Write    curl ${dest_addres}:${service_port}
    ${output}=    Read Until   HTML
    Log    ${output}
    Should Contain    ${output}    HTML
    [Return]    ${output}
