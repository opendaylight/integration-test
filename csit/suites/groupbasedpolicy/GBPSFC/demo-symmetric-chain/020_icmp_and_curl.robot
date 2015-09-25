*** Settings ***
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../docker_utils.robot
 
*** Variables ***

@{docker_addresses}    10.0.35.2    10.0.36.4
 
*** Test Cases ***
Ping from h35_2
    Ping from Docker    ${MININET}    h35_2    ${docker_addresses}    user=${MININET_USER}    password=${MININET_PASSWORD}

Ping from h36_4
    Ping from Docker    ${MININET5}    h36_4    ${docker_addresses}    user=${MININET_USER}    password=${MININET_PASSWORD}
 
Start HTTP h36_4
    Start HTTP Service on Docker    ${MININET5}    h36_4    80    user=${MININET_USER}    password=${MININET_PASSWORD}
 
Curl h35_2 -> h36_4
    Curl from Docker    ${MININET}    h35_2    10.0.36.4    80    user=${MININET_USER}    password=${MININET_PASSWORD}

