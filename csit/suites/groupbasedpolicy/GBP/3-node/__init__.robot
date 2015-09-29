*** Settings ***
Documentation     Setup/teardown for GBP 3-node topology
Suite Setup       Setup Everything
Suite Teardown    Teardown Everything
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py
Resource          Variables.robot


*** Variables ***
${timeout} =     10s


*** Keywords ***
Setup Everything
    Log    start_suite_in_3_node
    :FOR    ${GBP}    IN    @{GBPs}
    \    ConnUtils.Connect and Login    ${GBP}    timeout=${timeout}
    \    ${stderr}    SSHLibrary.Execute Command    virtualenv --system-site-packages ${VE_DIR}    return_stdout=False    return_stderr=True    return_rc=False
    \    Should Be Empty    ${stderr}
    \    SSHLibrary.Put File    ${CURDIR}/../../common_scripts/*    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755
    \    ${stdout}    ${stderr}    ${rc}    ConnUtils.Execute in VE    pip freeze | grep ipaddr -q || pip install ipaddr    timeout=${timeout}
    \    Should Be Equal As Numbers    ${rc}    0
    \    SSHLibrary.Close Connection

Teardown Everything
    Log    stop_suite_in_3_node
    :FOR    ${GBP}    IN    @{GBPs}
    \    ConnUtils.Connect and Login    ${GBP}    timeout=${timeout}
    \    SSHLibrary.Execute Command    sudo rm -rf ${VM_SCRIPTS_FOLDER}
    \    SSHLibrary.Close Connection
