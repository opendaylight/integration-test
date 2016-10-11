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
    ${out}    SSHLibrary.Execute Command    sudo route -n
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo ifconfig
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo arp -a
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    ping -c 5 ${ODL_SYSTEM_IP}
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-prereqs.sh
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-vpp.sh
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/configure-vpp.sh
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    Should Contain    ${out}    local0
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/install-hc.sh
    Log    ${out}
    Wait Until Keyword Succeeds    10x    10 sec    Check For Honeycomb Start
    ${out}    SSHLibrary.Execute Command    sudo route -n
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo ifconfig
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo arp -a
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    ping -c 5 ${ODL_SYSTEM_IP}
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo netstat -an
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo iptables --list
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo systemctl status firewalld
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo cat /opt/honeycomb/config/honeycomb.json
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo cat ${HONEYCOMB_LOG}
    Log    ${out}
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
    ${log}    SSHLibrary.Execute Command    grep 'Honeycomb started successfully' ${HONEYCOMB_LOG}
    Should Not Be Empty    ${log}
