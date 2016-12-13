*** Settings ***
Library           SSHLibrary    120 seconds
Resource          ../../../../libraries/GBP/ConnUtils.robot

*** Test Cases ***
Stop ODL
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}
    ConnUtils.Connect and Login    ${ODL_SYSTEM_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo pkill -f karaf

