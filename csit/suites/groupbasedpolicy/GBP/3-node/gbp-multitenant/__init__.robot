*** Settings ***
Suite Setup       Start Suite
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP.robot
Variables         ../../../../variables/Variables.py


*** Variables ***
${prompt} =      ${DEFAULT_LINUX_PROMPT}
${timeout} =     3s
${user} =        ${MININET_USER}
${password} =    ${MININET_PASSWORD}
@{mininet_list} =    ${MININET}    ${MININET1}    ${MININET2}


*** Keywords ***
Start Suite
    Setup Demo On Vms    3-node/gbp1    @{mininet_list}
