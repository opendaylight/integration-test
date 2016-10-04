





*** Settings ***
Library           SSHLibrary
Resource          Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/GBP/ConnUtils.robot
Variables         ../../../variables/Variables.py

*** Keywords ***
Setup Node
    [Arguments]    ${GBPVPP}    ${suite_dir}    ${timeout}=10s
    [Documentation]    Start honeycomb and VPP on remote VM.
    ConnUtils.Connect and Login    ${GBPVPP}    timeout=${timeout}
    SSHLibrary.Put File    ${suite_dir}/*    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/fix-perms.sh
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-prereqs.sh
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-java8.sh
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-vpp.sh
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/configure-vpp.sh
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-hc.sh
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Should Not Be Empty    ${out}
    Wait Until Keyword Succeeds    10x    10 sec    Check For Honeycomb Start
    SSHLibrary.Close Connection

Teardown Node
    [Arguments]    ${GBPVPP}    ${suite_dir}    ${timeout}=3s
    [Documentation]    Clears underlying infrastructure composed of Docker containers and OVS switches from remote VM.
    ...    Python and Bash scripts are used.
    ConnUtils.Connect and Login    ${GBPVPP}    timeout=${timeout}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/infrastructure_config.py    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    rm ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/sf-flows.sh    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    ${stderr}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/clean-demo.sh    return_stderr=True    return_stdout=False
    Should Be Empty    ${stderr}
    SSHLibrary.Close Connection

Setup Nodes
    [Arguments]    ${GBPVPPs}    ${init_scripts_dir}
    : FOR    ${GBPVPP}    IN    @{GBPVPPs}
    \    Setup Node    ${GBPVPP}    ${init_scripts_dir}    timeout=10s

Check For Honeycomb Start
    [Documentation]    Check for message in honeycomb log
    ${log}    SSHLibrary.Execute Command    cat ${HONEYCOMB_LOG}
    Should Contain    ${log}    Honeycomb started successfully
