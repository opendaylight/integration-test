*** Settings ***
Documentation     Setup/teardown for GBPSFC 6-node topology
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
    Log    start_suite_in_6_node
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    # TODO if something extra needs to be installed, please do it in virt-env
    #      (use Read/Write, b/c Execute Command always run in new shell where virt env is not activated.) see ConnUtils.robot
    \    ${stderr}    SSHLibrary.Execute Command    sudo virtualenv --system-site-packages ${VIRT_ENV_DIR}    return_stdout=False    return_stderr=True    return_rc=False
    \    Should Be Empty    ${stderr}
    \    SSHLibrary.Put Directory    ${CURDIR}/../../common_scripts    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}    mode=0755    recursive=True
    \    Should Be Empty    ${stderr}
    # seems we cannot setup vars this way due to paranoidal restrictions
    \    ${stderr}    SSHLibrary.Execute Command    grep ODL ${VM_HOME_FOLDER}/.profile -q || echo "export ODL=${CONTROLLER}" >> ${VM_HOME_FOLDER}/.profile
    \    ...    return_stderr=True    return_stdout=False    return_rc=False
    \    Should Be Empty    ${stderr}
    \    ${stderr}=    SSHLibrary.Execute Command    grep VIRT_ENV_PATH ${VM_HOME_FOLDER}/.profile -q || echo "export VIRT_ENV_PATH=${VIRT_ENV_DIR}" >> ${VM_HOME_FOLDER}/.profile
    \    ...    return_stderr=True    return_stdout=False    return_rc=False
    \    Should Be Empty    ${stderr}
    \    ${stderr}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/execute-in-ve.sh pip freeze | grep ipaddr -q || pip install ipaddr
    \    ...    return_stderr=True    return_stdout=False    return_rc=False
    \    Should Be Empty    ${stderr}
    \    SSHLibrary.Close Connection

Teardown Everything
    Log    stop_suite_in_6_node
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    SSHLibrary.Execute Command    sudo rm -rf ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}
    \    SSHLibrary.Close Connection
