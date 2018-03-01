*** Settings ***
Library           SSHLibrary
Library           BuiltIn
Library           String
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot
Resource          OVSDB.robot
Resource          VpnOperations.robot
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
${CONFIG_FILES_PATH}    /etc/cni/net.d/odlovs-cni.conf
${CNI_BINARY_PATH}    /opt/cni/bin/odlovs-cni
${NETVIRT_PATH}    ${CURDIR}/../variables/netvirt/Modules.py
${COE_PATH}       ${CURDIR}/../variables/coe/Modules.py
${K8s_MASTER_IP}    192.168.33.11
${K8s_MINION1_IP}    192.168.33.12
${K8s_MINION2_IP}    192.168.33.13
${MINION1_USER}    admin
${MINION2_USER}    admin
${MINION1_PASSWORD}    admin
${MINION2_PASSWORD}    admin
${BRIDGE}         BR
${MASTER_HOME}    home

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    Conn_id
    Verify_Config_Files
    Check_Watcher
    Verify_Nodes_Status
    Verify Tunnel Status as UP
    Create_Label

Kube_reset
    [Arguments]    ${SYSTEM}    ${NODE_USER}    ${NODE_PASSWORD}
    [Documentation]    Reset K8s to clear up all stale entries
    ${kube}    Run Command On Remote System    ${SYSTEM}    sudo kubeadm reset    ${NODE_USER}    ${NODE_PASSWORD}
    Should Contain    ${kube}    Stopping the kubelet service.

Create_Label
    [Documentation]    Create labels for minions so that random allocation of pods to minions is avoided
    ${nodes}=    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get nodes    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${node_1}    Get Line    ${nodes}    2
    ${minion_1}=    Should Match Regexp    ${node_1}=    ^\\w+
    ${node_2}    Get Line    ${nodes}    3
    ${minion_2}=    Should Match Regexp    ${node_2}=    ^\\w+
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl label nodes ${minion_1} disktype=ssd    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl label nodes ${minion_2} disktype=ssl    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get nodes --show-labels    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}

Stop_Watcher
    [Documentation]    Kill the watcher running at the background after completion of tests cases
    ${lines}=    Run Command On Remote System    ${K8s_MASTER_IP}    ps -ef | grep watcher    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${pid}=    Should Match Regexp    ${lines}=    \\s\\d+\\s
    Run Command On Remote System    ${K8s_MASTER_IP}    kill -9 ${pid}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}

Stop_Suite
    [Documentation]    Suite teardown keyword
    Stop_Watcher
    Kube_reset    ${K8s_MASTER_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Kube_reset    ${K8s_MINION1_IP}    ${MINION1_USER}    ${MINION1_PASSWORD}
    Kube_reset    ${K8s_MINION2_IP}    ${MINION2_USER}    ${MINION2_PASSWORD}
    Close All Connections

Coe_Tear_Down
    [Documentation]    Test teardown to get dumpflows,ovsconfig,model dump,node status and pod status
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_3}    ${BRIDGE}
    Coe_Data_Models
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
    Verify_Nodes_Status
    Verify_Pod_Status
    Delete_Pods

Coe_Data_Models
    [Documentation]    Data models created by integrating netvirt and coe data models which is given as input to get the model dumps
    ${file_1}=    OperatingSystem.Get File    ${NETVIRT_PATH}
    ${file_2}=    OperatingSystem.Get File    ${COE_PATH}
    ${netvirt_models}=    Split To Lines    ${file_1}    1    59
    ${coe_models}    Split To Lines    ${file_2}=    1    3
    : FOR    ${module}    IN    @{coe_models}
    \    Append To List    ${netvirt_models}    ${module}
    ${data_models}=    Create List
    : FOR    ${models}    IN    @{netvirt_models}
    \    ${models}=    Should Match Regexp    ${models}    \\w.*\\w
    \    Append To List    ${data_models}    ${models}
    Set Global Variable    ${data_models}

Verify_Nodes_Status
    [Documentation]    Waits till the keyword _node _status_ succeeds implying that all nodes are ready
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    50s    2s    Node_Status

Node_Status
    [Documentation]    Checks the status of nodes.This keyword is repeated until the status of all nodes is \ _Ready_
    ${nodes}=    Write Commands Until Expected Prompt    kubectl get nodes    ${DEFAULT_LINUX_PROMPT}
    ${count}=    Get Line Count    ${nodes}
    @{cluster}=    Split To Lines    ${nodes}=    1    ${count-1}
    : FOR    ${node}    IN    @{cluster}
    \    Should Match Regexp    ${node}    \\sReady
    Close Connection

Verify_Pod_Status
    [Documentation]    Waits till the keyword _pod _status_ succeeds implying that all pods are running
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    50s    2s    Pod_Status

Pod_Status
    [Documentation]    Checks the status of pods.This keyword is repeated until the status of all pods is \ _Running_
    ${pods}=    Write Commands Until Expected Prompt    kubectl get pods -o wide    ${DEFAULT_LINUX_PROMPT}
    ${count}=    Get Line Count    ${pods}
    @{cluster}=    Split To Lines    ${pods}    1    ${count-1}
    : FOR    ${pod}    IN    @{cluster}
    \    Should Match Regexp    ${pod}    \\sRunning
    Close Connection

Delete_Pods
    [Documentation]    Waits till the keyword _delete _status_ succeeds implying that all pods created \ have been deleted
    ${lines}=    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    @{lines}=    Split To Lines    ${lines}    1
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name}=    Should Match Regexp    ${status}    ^\\w+
    \    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl delete pods ${pod_name}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    60s    3s    Delete_Status

Delete_Status
    [Documentation]    Checks if the pods created have been terminated.The keyword is repeated until the pods are deleted
    ${status}=    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${EMPTY}
    ...    return_stdout=False    return_stderr=True
    Should Contain    ${status}    No resources

Conn_id
    [Documentation]    Gets the connection ids for all the nodes
    ${conn_id_1}=    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Set Global Variable    ${conn_id_1}
    ${conn_id_2}    Open Connection    ${K8s_MINION1_IP}
    Login    ${MINION1_USER}    ${MINION1_PASSWORD}
    Set Global Variable    ${conn_id_2}
    ${conn_id_3}    Open Connection    ${K8s_MINION2_IP}
    Login    ${MINION2_USER}    ${MINION2_PASSWORD}
    Set Global Variable    ${conn_id_3}

Verify_Config_Files
    [Documentation]    Checks if the configuration files are present in all nodes
    Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${CONFIG_FILES_PATH}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Verify File Exists On Remote System    ${K8s_MINION1_IP}    ${CONFIG_FILES_PATH}    ${MINION1_USER}    ${MINION1_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Verify File Exists On Remote System    ${K8s_MINION2_IP}    ${CONFIG_FILES_PATH}    ${MINION2_USER}    ${MINION2_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${CNI_BINARY_PATH}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT}

Check_Watcher
    [Documentation]    Checks if watcher is running in the background
    ${lines}=    Run Command On Remote System    ${K8s_MASTER_IP}    ps -ef | grep watcher    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${pid}=    Should Match Regexp    ${lines}    .* watcher odl
