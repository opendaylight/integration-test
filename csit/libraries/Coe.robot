*** Settings ***
Library           BuiltIn
Library           SSHLibrary
Library           String
Resource          OVSDB.robot
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/netvirt/Variables.robot
Resource          ../variables/Variables.robot
Resource          VpnOperations.robot

*** Variables ***
${BRIDGE}         BR
${CNI_BINARY_PATH}    /opt/cni/bin/odlovs-cni
${COE_PATH}       ${CURDIR}/../variables/coe/Modules.py
${CONFIG_FILES_PATH}    /etc/cni/net.d/odlovs-cni.conf
${K8s_MASTER_IP}    192.168.33.11
${K8s_MINION1_IP}    192.168.33.12
${K8s_MINION2_IP}    192.168.33.13
${MASTER_HOME}    home
${MINION1_USER}    admin
${MINION2_USER}    admin
${MINION1_PASSWORD}    admin
${MINION2_PASSWORD}    admin
${NETVIRT_PATH}    ${CURDIR}/../variables/netvirt/Modules.py
@{labels}         ssd    ssl

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    Coe.Conn_id
    Coe.Verify_Config_Files
    Coe.Check_Watcher
    Coe.Verify_Nodes_Status
    VpnOperations.Verify Tunnel Status as UP
    Coe.Create_Label

Conn_id
    [Documentation]    Gets the connection ids for all the nodes
    ${conn_id_1} =    SSHLibrary.Open Connection    ${K8s_MASTER_IP}
    SSHLibrary.Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_1}
    ${conn_id_2} =    SSHLibrary.Open Connection    ${K8s_MINION1_IP}
    SSHLibrary.Login    ${MINION1_USER}    ${MINION1_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_2}
    ${conn_id_3} =    SSHLibrary.Open Connection    ${K8s_MINION2_IP}
    SSHLibrary.Login    ${MINION2_USER}    ${MINION2_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_3}

Verify_Config_Files
    [Documentation]    Checks if the configuration files are present in all nodes
    Utils.Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${CONFIG_FILES_PATH}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Utils.Verify File Exists On Remote System    ${K8s_MINION1_IP}    ${CONFIG_FILES_PATH}    ${MINION1_USER}    ${MINION1_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Utils.Verify File Exists On Remote System    ${K8s_MINION2_IP}    ${CONFIG_FILES_PATH}    ${MINION2_USER}    ${MINION2_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Utils.Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${CNI_BINARY_PATH}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}

Check_Watcher
    [Documentation]    Checks if watcher is running in the background
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    ps -ef | grep watcher    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${pid} =    BuiltIn.Should Match Regexp    ${lines}    .* watcher odl

Verify_Nodes_Status
    [Documentation]    Waits till the keyword _node _status_ succeeds implying that all nodes are ready
    SSHLibrary.Open Connection    ${K8s_MASTER_IP}
    SSHLibrary.Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    50s    2s    Coe.Node_Status

Create_Label
    [Documentation]    Create labels for minions so that random allocation of pods to minions is avoided
    ${nodes} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get nodes    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${node_1} =    String.Get Line    ${nodes}    2
    ${minion_1} =    BuiltIn.Should Match Regexp    ${node_1}    ^\\w+
    ${node_2} =    String.Get Line    ${nodes}    3
    ${minion_2} =    BuiltIn.Should Match Regexp    ${node_2}    ^\\w+
    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl label nodes ${minion_1} disktype=${labels[0]}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl label nodes ${minion_2} disktype=${labels[1]}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get nodes --show-labels    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}

Coe_Tear_Down
    [Documentation]    Test teardown to get dumpflows,ovsconfig,model dump,node status and pod status
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_3}    ${BRIDGE}
    Coe.Coe_Data_Models
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
    Coe.Verify_Nodes_Status
    Coe.Verify_Pod_Status
    Coe.Delete_Pods

Coe_Data_Models
    [Documentation]    Data models created by integrating netvirt and coe data models which is given as input to get the model dumps
    ${file_1} =    OperatingSystem.Get File    ${NETVIRT_PATH}
    ${file_2} =    OperatingSystem.Get File    ${COE_PATH}
    ${netvirt_models} =    String.Split To Lines    ${file_1}    1    59
    ${coe_models}    String.Split To Lines    ${file_2}    1    3
    : FOR    ${module}    IN    @{coe_models}
    \    Collections.Append To List    ${netvirt_models}    ${module}
    ${data_models} =    BuiltIn.Create List
    : FOR    ${models}    IN    @{netvirt_models}
    \    ${models} =    BuiltIn.Should Match Regexp    ${models}    \\w.*\\w
    \    Collections.Append To List    ${data_models}    ${models}
    BuiltIn.Set Global Variable    ${data_models}

Node_Status
    [Documentation]    Checks the status of nodes.This keyword is repeated until the status of all nodes is \ _Ready_
    ${nodes} =    Utils.Write Commands Until Expected Prompt    kubectl get nodes    ${DEFAULT_LINUX_PROMPT}
    ${count} =    String.Get Line Count    ${nodes}
    @{cluster} =    String.Split To Lines    ${nodes}    1    ${count-1}
    : FOR    ${node}    IN    @{cluster}
    \    BuiltIn.Should Match Regexp    ${node}    \\sReady
    SSHLibrary.Close Connection

Verify_Pod_Status
    [Documentation]    Waits till the keyword _pod _status_ succeeds implying that all pods are running
    SSHLibrary.Open Connection    ${K8s_MASTER_IP}
    SSHLibrary.Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    50s    2s    Coe.Pod_Status

Pod_Status
    [Documentation]    Checks the status of pods.This keyword is repeated until the status of all pods is \ _Running_
    ${pods} =    Utils.Write Commands Until Expected Prompt    kubectl get pods -o wide    ${DEFAULT_LINUX_PROMPT}
    ${count} =    String.Get Line Count    ${pods}
    @{cluster} =    String.Split To Lines    ${pods}    1    ${count-1}
    : FOR    ${pod}    IN    @{cluster}
    \    BuiltIn.Should Match Regexp    ${pod}    \\sRunning
    SSHLibrary.Close Connection

Delete_Pods
    [Documentation]    Waits till the keyword _delete _status_ succeeds implying that all pods created \ have been deleted
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    @{lines} =    String.Split To Lines    ${lines}    1
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name} =    BuiltIn.Should Match Regexp    ${status}    ^\\w+
    \    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl delete pods ${pod_name}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    60s    3s    Coe.Delete_Status

Delete_Status
    [Documentation]    Checks if the pods created have been terminated.The keyword is repeated until the pods are deleted
    ${status} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${EMPTY}
    ...    return_stdout=False    return_stderr=True
    BuiltIn.Should Contain    ${status}    No resources

Stop_Suite
    [Documentation]    Suite teardown keyword
    Coe.Stop_Watcher
    Coe.Kube_reset    ${K8s_MASTER_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Coe.Kube_reset    ${K8s_MINION1_IP}    ${MINION1_USER}    ${MINION1_PASSWORD}
    Coe.Kube_reset    ${K8s_MINION2_IP}    ${MINION2_USER}    ${MINION2_PASSWORD}
    SSHLibrary.Close All Connections

Kube_reset
    [Arguments]    ${SYSTEM}    ${NODE_USER}    ${NODE_PASSWORD}
    [Documentation]    Reset K8s to clear up all stale entries
    ${kube}    Utils.Run Command On Remote System    ${SYSTEM}    sudo kubeadm reset    ${NODE_USER}    ${NODE_PASSWORD}
    BuiltIn.Should Contain    ${kube}    Stopping the kubelet service.

Stop_Watcher
    [Documentation]    Kill the watcher running at the background after completion of tests cases
    ${lines} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    ps -ef | grep watcher    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${line}    ${pid}    BuiltIn.Should Match Regexp    ${lines}    \\w+\\s+(\\d+).*watcher odl
    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kill -9 ${pid}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
