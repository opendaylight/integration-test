*** Settings ***
Library           SSHLibrary
Resource          vars.robot
Resource          ../../../libraries/GBP/ConnUtils.robot
Variables         ../../../variables/Variables.py

*** Keywords ***
Start VPP Nodes
    [Arguments]    ${VPP_NODES}    ${scripts_dir}
    [Documentation]    Install, configure and start honeycomb and VPP on remote VM
    : FOR    ${VPP_NODE}    IN    @{VPP_NODES}
    \   ConnUtils.Connect and Login    ${GBPVPP}    timeout=${timeout}
    \   SSHLibrary.Put File    ${suite_dir}/*    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/    mode=0755
    \   ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-prereqs.sh
    \   Log    ${out}
    \   ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-vpp.sh
    \   Log    ${out}
    \   ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/configure-vpp.sh
    \   Log    ${out}
    \   ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-hc.sh
    \   Log    ${out}
    \   Wait Until Keyword Succeeds    10x    10 sec    Check For Honeycomb Start
    \   Wait Until Keyword Succeeds    10x    5 sec    Check For Honeycomb Port    8283
    \   SSHLibrary.Close Connection

Check For Honeycomb Start
    [Documentation]    Check for start message in honeycomb log
    ${log}    SSHLibrary.Execute Command    cat ${HONEYCOMB_LOG}
    Log    ${log}
    ${log}    SSHLibrary.Execute Command    grep 'Honeycomb started successfully' ${HONEYCOMB_LOG}
    Should Not Be Empty    ${log}

Check For Honeycomb Port
    [Documentation]    Checks whether honeycomb restconf port is open
    [Arguments]    ${port}
    ${out}    SSHLibrary.Execute Command    sudo netstat -lnp | grep ${port}
    Should Not Be Empty    ${out}
