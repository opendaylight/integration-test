*** Settings ***
Library           BuiltIn
Library           SSHLibrary
Library           String
Resource          DataModels.robot
Resource          Genius.robot
Resource          OVSDB.robot
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/netvirt/Variables.robot
Resource          ../variables/Variables.robot
Resource          VpnOperations.robot
Variables         ../variables/coe/Modules.py
Variables         ../variables/netvirt/Modules.py

*** Variables ***
${BUSY_BOX}       ${CURDIR}/../variables/coe/busy-box.yaml
${CNI_BINARY_FILE}    /opt/cni/bin/odlovs-cni
${CONFIG_FILE}    /etc/cni/net.d/odlovs-cni.conf
${CONFIG_FILE_TEMPLATE}    ${CURDIR}/../variables/coe/odlovs-cni.conf.j2
${HOST_INVENTORY}    ${CURDIR}/../variables/coe/hosts.yaml
${K8s_MASTER_IP}    ${TOOLS_SYSTEM_1_IP}
${K8s_MINION1_IP}    ${TOOLS_SYSTEM_2_IP}
${K8s_MINION2_IP}    ${TOOLS_SYSTEM_3_IP}
${K8s_MINION3_IP}    ${TOOLS_SYSTEM_4_IP}
${K8s_MINION4_IP}    ${TOOLS_SYSTEM_5_IP}
${NODE_READY_STATUS}    \\sReady
${PLAYBOOK}       ${CURDIR}/../variables/coe/coe_play.yaml
${POD_RUNNING_STATUS}    \\sRunning
${WATCHER_COE}    ${CURDIR}/../variables/coe/coe.yaml
@{NODE_IPs}       ${K8s_MASTER_IP}    ${K8s_MINION1_IP}    ${K8s_MINION2_IP}    ${K8s_MINION3_IP}    ${K8s_MINION4_IP}
@{COE_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    ELAN    OVSDB
${VARIABLES_PATH}    ${CURDIR}/../variables/coe

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword.
    Coe.Configuration Playbook
    Coe.Set Connection ids and Bridge
    Coe.Verify Config Files
    Coe.Verify Watcher Is Running
    BuiltIn.Wait Until Keyword Succeeds    40s    2s    Coe.Check Node Status Is Ready
    Coe.Label Nodes
    BuiltIn.Wait Until Keyword Succeeds    60    2    ClusterManagement.Check Status Of Services Is OPERATIONAL    @{COE_DIAG_SERVICES}
    BuiltIn.Wait Until Keyword Succeeds    85    2    Genius.Verify Tunnel Status as UP    default-transport-zone
    Coe.Derive Coe Data Models

Configuration Playbook
    [Documentation]    Ansible playbook which does all basic configuration for kubernetes nodes.
    ${hosts} =    OperatingSystem.Get File    ${HOST_INVENTORY}
    ${hosts} =    String.Replace String    ${hosts}    master_ip    ${K8s_MASTER_IP}
    ${hosts} =    String.Replace String    ${hosts}    minion1_ip    ${K8s_MINION1_IP}
    ${hosts} =    String.Replace String    ${hosts}    minion2_ip    ${K8s_MINION2_IP}
    ${hosts} =    String.Replace String    ${hosts}    minion3_ip    ${K8s_MINION3_IP}
    ${hosts} =    String.Replace String    ${hosts}    minion4_ip    ${K8s_MINION4_IP}
    ${hosts} =    String.Replace String    ${hosts}    odl_ip    ${ODL_SYSTEM_IP}
    ${hosts} =    String.Replace String    ${hosts}    mport    ${OVSDBPORT}
    ${hosts} =    String.Replace String    ${hosts}    cport    ${ODL_OF_PORT_6653}
    ${hosts} =    String.Replace String    ${hosts}    filepath    ${CONFIG_FILE_TEMPLATE}
    ${hosts} =    String.Replace String    ${hosts}    yamlpath    ${USER_HOME}/coe.yaml
    OperatingSystem.Create File    ${USER_HOME}/hosts.yaml    ${hosts}
    ${watcher} =    OperatingSystem.Get File    ${WATCHER_COE}
    ${watcher} =    String.Replace String    ${watcher}    odlip    ${ODL_SYSTEM_IP}
    ${watcher} =    String.Replace String    ${watcher}    port    ${RESTCONFPORT}
    OperatingSystem.Create File    ${WATCHER_COE}    ${watcher}
    SSHKeywords.Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${WATCHER_COE}    ${USER_HOME}
    OperatingSystem.Copy File    ${PLAYBOOK}    ${USER_HOME}
    ${play_output} =    OperatingSystem.Run    ansible-playbook ${USER_HOME}/coe_play.yaml -i ${USER_HOME}/hosts.yaml
    BuiltIn.Log    ${play_output}

Set Connection ids and Bridge
    [Documentation]    Sets the connection ids for all the nodes and get the bridge from configuration file .
    ${conn_id_1} =    SSHLibrary.Open Connection    ${K8s_MASTER_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_1}
    ${conn_id_2} =    SSHLibrary.Open Connection    ${K8s_MINION1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_2}
    ${conn_id_3} =    SSHLibrary.Open Connection    ${K8s_MINION2_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_3}
    ${conn_id_4} =    SSHLibrary.Open Connection    ${K8s_MINION3_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_4}
    ${conn_id_5} =    SSHLibrary.Open Connection    ${K8s_MINION4_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_5}
    ${file} =    OperatingSystem.Get File    ${CONFIG_FILE_TEMPLATE}
    ${line}    ${bridge} =    Should Match Regexp    ${file}    "ovsBridge": "(\\w.*)"
    BuiltIn.Set Global Variable    ${bridge}

Verify Config Files
    [Documentation]    Checks if the configuration files are present in all nodes
    : FOR    ${nodes}    IN    @{NODE_IPs}
    \    Utils.Verify File Exists On Remote System    ${nodes}    ${CONFIG_FILE}
    : FOR    ${nodes}    IN    @{NODE_IPs}
    \    Utils.Verify File Exists On Remote System    ${nodes}    ${CNI_BINARY_FILE}

Verify Watcher Is Running
    [Documentation]    Checks if watcher is running in the background
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    ps -ef | grep watcher
    BuiltIn.Should Match Regexp    ${lines}    .* watcher odl

Check Node Status Is Ready
    [Documentation]    Checks the status of nodes.This keyword is repeated until the status of all nodes is Ready
    ${nodes} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get nodes    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{cluster} =    String.Split To Lines    ${nodes}    1
    : FOR    ${node}    IN    @{cluster}
    \    BuiltIn.Should Match Regexp    ${node}    ${NODE_READY_STATUS}

Label Nodes
    [Documentation]    Create labels for minions so that random allocation of pods to minions is avoided
    ${i} =    BuiltIn.Set Variable    1
    ${lines} =    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get nodes
    @{lines} =    String.Split To Lines    ${lines}    2
    : FOR    ${status}    IN    @{lines}
    \    ${minion} =    BuiltIn.Should Match Regexp    ${status}    ^\\w+-.*-\\d+
    \    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl label nodes ${minion} disktype=ss${i}
    \    ${i} =    BuiltIn.Evaluate    ${i}+1
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get nodes --show-labels

Derive Coe Data Models
    [Documentation]    Data models is created by integrating netvirt and coe data models which is given as input to get the model dumps
    : FOR    ${models}    IN    @{netvirt_data_models}
    \    Collections.Append To List    ${coe_data_models}    ${models}

Check Pod Status Is Running
    [Documentation]    Checks the status of pods.This keyword is repeated until the status of all pods is Running
    ${pods} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{cluster} =    String.Split To Lines    ${pods}    1
    : FOR    ${pod}    IN    @{cluster}
    \    BuiltIn.Should Match Regexp    ${pod}    ${POD_RUNNING_STATUS}

Tear Down
    [Documentation]    Test teardown to get dumpflows,ovsconfig,model dump,node status,pod status and to dump config files \ and delete pods.
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    ${bridge}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    ${bridge}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_3}    ${bridge}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_4}    ${bridge}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_5}    ${bridge}
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${coe_data_models}
    Coe.DumpConfig File
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get nodes    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Coe.Delete Pods

Delete Pods
    [Documentation]    Waits till the keyword delete status succeeds implying that all pods created have been deleted
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide
    @{lines} =    String.Split To Lines    ${lines}    1
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name} =    BuiltIn.Should Match Regexp    ${status}    ^\\w+-\\w+
    \    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl delete pods ${pod_name}
    BuiltIn.Wait Until Keyword Succeeds    60s    3s    Coe.Check If Pods Are Terminated

Check If Pods Are Terminated
    [Documentation]    Checks if the pods created have been terminated.The keyword is repeated until the pods are deleted
    ${status} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ...    ${DEFAULT_TIMEOUT}    return_stdout=False    return_stderr=True
    BuiltIn.Should Contain    ${status}    No resources

Dump Config File
    [Documentation]    Logs the configuration files present in all nodes
    : FOR    ${nodes}    IN    @{NODE_IPs}
    \    Utils.Run Command On Remote System And Log    ${nodes}    cat ${CONFIG_FILE}

Stop Suite
    [Documentation]    Suite teardown keyword
    Coe.Collect Watcher Log
    Coe.Collect Journalctl Log
    Coe.Stop_Watcher
    Coe.Kube_reset
    SSHLibrary.Close All Connections

Collect Watcher Log
    [Documentation]    Watcher running in background logs into watcher.out which is copied to ${JENKINS_WORKSPACE}/archives/watcher.log
    SSHLibrary.Open Connection    ${K8s_MASTER_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    SSHLibrary.Get File    /tmp/watcher.out    ${JENKINS_WORKSPACE}/archives/watcher.log
    SSHLibrary.Close Connection

Collect Journalctl Log
    [Documentation]    Logs of the command journalctl -u kubelet is copied to ${JENKINS_WORKSPACE}/archives/journal.log
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    sudo journalctl -u kubelet > ${USER_HOME}/journal.txt
    SSHLibrary.Open Connection    ${K8s_MASTER_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    SSHLibrary.Get File    ${USER_HOME}/journal.txt    ${JENKINS_WORKSPACE}/archives/journalctl.log
    SSHLibrary.Close Connection

Stop Watcher
    [Documentation]    Kill the watcher running at the background after completion of tests cases
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    ps -ef | grep watcher
    ${line}    ${pid} =    BuiltIn.Should Match Regexp    ${lines}    \\w+\\s+(\\d+).*watcher odl
    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kill -9 ${pid}

Kube reset
    [Documentation]    Reset K8s to clear up all stale entries
    : FOR    ${nodes}    IN    @{NODE_IPs}
    \    ${kube} =    Utils.Run Command On Remote System And Log    ${nodes}    sudo kubeadm reset
    \    BuiltIn.Should Contain    ${kube}    Stopping the kubelet service.

Create Pods
    [Arguments]    ${label}    ${yaml}    ${name}
    [Documentation]    Creates pods using the labels of the nodes and busy box names passed as arguments.
    ${busybox} =    OperatingSystem.Get File    ${BUSY_BOX}
    ${busybox} =    String.Replace String    ${busybox}    string    ${label}
    ${busybox} =    String.Replace String    ${busybox}    busyboxname    ${name}
    OperatingSystem.Create File    ${VARIABLES_PATH}/${yaml}    ${busybox}
    SSHKeywords.Move_file_To_Remote_System    ${K8s_MASTER_IP}    ${VARIABLES_PATH}/${yaml}    ${USER_HOME}
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl create -f ${yaml}

Collect Pod Names and Ping
    [Documentation]    This keyword collects the pod names and checks connectivity between each and every pod with respect to one another.
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide
    @{pods}=    String.Get Regexp Matches    ${lines}    ss\\w+-\\w+
    : FOR    ${pod_name}    IN    @{pods}
    \    Ping Pods    ${pod_name}    ${lines}

Log Statements
    [Arguments]    ${pod ips}    ${pod names}    ${pod_name}
    @{log statement}    Create List
    ${i}    Set Variable    0
    : FOR    ${pod ip}    IN    @{pod ips}
    \    ${line}    Set Variable    Ping ${pod_name} and ${pod names[${i}]} : ${pod ip}
    \    Append To List    ${log statement}    ${line}
    \    ${i} =    Evaluate    ${i}+1
    [Return]    @{log statement}

Ping Pods
    [Arguments]    ${pod_name}    ${lines}
    [Documentation]    Ping pods to check connectivity between them
    SSHLibrary.Open Connection    ${K8s_MASTER_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${i} =    Set Variable    0
    @{pod ips}=    String.Get Regexp Matches    ${lines}    \\d+\\.\\d+\\.\\d+\\.\\d+
    @{pod names}=    String.Get Regexp Matches    ${lines}    ss\\w+-\\w+
    ${logs} =    Log Statements    ${pod ips}    ${pod names}    ${pod_name}
    :FOR    ${ping info}    IN    @{logs}
    \    ${ping} =    Write Commands Until Expected Prompt    kubectl exec -it ${pod_name} -- ping -c 3 ${pod ips[${i}]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    \    BuiltIn.log    ${ping}
    \    Builtin.Should Match Regexp    ${ping}    ${PING_REGEXP}
    \    ${i}    Evaluate    ${i}+1
    SSHLibrary.Close Connection

Coe Suite Setup
    @{suite names}    Get Regexp Matches    ${SUITES}    coe\\/(\\w+).robot    1
    @{suite names updated}    Create List
    : FOR    ${suites}    IN    @{suite names}
    \    ${suites}    Replace String    ${suites}    _    ${SPACE}
    \    Append To List    ${suite names updated}    ${suites}
    ${first suite} =    Set Variable    ${suite names updated[0]}
    ${line}    ${current suite}    Should Match Regexp    ${SUITE_NAME}    .txt.(\\w.*)
    ${status} =    BuiltIn.Evaluate    '${first suite}' == '${current suite}'
    Run Keyword If    '${status}' == 'True'    Coe.Start Suite

Coe Suite Teardown
    @{suite names}    Get Regexp Matches    ${SUITES}    coe\\/(\\w+).robot    1
    @{suite names updated}    Create List
    : FOR    ${suites}    IN    @{suite names}
    \    ${suites}    Replace String    ${suites}    _    ${SPACE}
    \    Append To List    ${suite names updated}    ${suites}
    ${last suite} =    Set Variable    ${suite names updated[-1]}
    ${line}    ${current suite}    Should Match Regexp    ${SUITE_NAME}    .txt.(\\w.*)
    ${status} =    BuiltIn.Evaluate    '${last suite}' == '${current suite}'
    Run Keyword If    '${status}' == 'True'    Coe.Stop Suite
