*** Settings ***
Suite Setup       Start Suite
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBPSFC.robot


*** Variables ***
${prompt} =      $
${timeout} =     3s
${user} =        ${MININET_USER}
${password} =    ${MININET_PASSWORD}
@{mininet_list} =    @{mininet3_list}

*** Keywords ***
Start Suite
    Setup Demo On Mininets    @{mininet_list}
