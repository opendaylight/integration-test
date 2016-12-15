*** Settings ***
Library           SSHLibrary    120 seconds
Resource          ../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../libraries/KarafKeywords.robot

*** Test Cases ***
Stop ODL
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}
    Issue Command On Karaf Console    log:clear    controller=${ODL_SYSTEM_1_IP}
    Issue Command On Karaf Console    log:clear    controller=${ODL_SYSTEM_2_IP}
    Issue Command On Karaf Console    log:clear    controller=${ODL_SYSTEM_3_IP}
    ConnUtils.Connect and Login    ${ODL_SYSTEM_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo pkill -f karaf
    Log    ${out}
    Set Global Variable    ${DOWN_MASTER_IP}    ${ODL_SYSTEM_IP}

