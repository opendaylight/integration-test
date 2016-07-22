*** Settings ***
Documentation     Test suite for RPC
Library           Process
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource           ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${cmd}              log:set DEBUG org.opendaylight.aaa.shiro.filters

${controller}       ${ODL_SYSTEM_IP}
${karaf_port}       ${KARAF_SHELL_PORT}
${timeout}          5




*** Test case ***

Issue Command On Karaf Console 
  
   
    [Documentation]    Will execute the given ${cmd} by ssh'ing to the karaf console running on ${ODL_SYSTEM_IP}
    ...    Note that this keyword will open&close new SSH connection, without switching back to previously current  session.
    Open Connection    ${controller}    port=${karaf_port}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    ${cmd}
    ${output}    Read 
    Close Connection
    Log    ${output}
   


