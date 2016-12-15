*** Settings ***
Library           SSHLibrary    120 seconds
Resource          ../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../libraries/KarafKeywords.robot

*** Test Cases ***
Stop ODL
    Run Keyword If    '${ODL_SYSTEM_1_IP}' != '${DOWN_MASTER_IP}'    Issue Command On Karaf Console    log:clear    controller=${ODL_SYSTEM_1_IP}
    Run Keyword If    '${ODL_SYSTEM_2_IP}' != '${DOWN_MASTER_IP}'    Issue Command On Karaf Console    log:clear    controller=${ODL_SYSTEM_2_IP}
    Run Keyword If    '${ODL_SYSTEM_3_IP}' != '${DOWN_MASTER_IP}'    Issue Command On Karaf Console    log:clear    controller=${ODL_SYSTEM_3_IP}
    ConnUtils.Connect and Login    ${ODL_SYSTEM_1_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo pkill -f karaf
    ConnUtils.Connect and Login    ${ODL_SYSTEM_2_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo pkill -f karaf
    ConnUtils.Connect and Login    ${ODL_SYSTEM_3_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo pkill -f karaf

Start ODL
    ConnUtils.Connect and Login    ${ODL_SYSTEM_1_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo ${WORKSPACE}/${BUNDLEFOLDER}/bin/start
    ConnUtils.Connect and Login    ${ODL_SYSTEM_2_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo ${WORKSPACE}/${BUNDLEFOLDER}/bin/start
    ConnUtils.Connect and Login    ${ODL_SYSTEM_3_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo ${WORKSPACE}/${BUNDLEFOLDER}/bin/start