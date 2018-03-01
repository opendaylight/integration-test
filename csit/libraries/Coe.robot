*** Settings ***
Library           SSHLibrary
Library           BuiltIn
Library           String
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot
Resource          OVSDB.robot

*** Variables ***
${WORKER1_CONFIG_PATH}    ${CURDIR}/../variables/coe/worker1.odlovs-cni.conf
${WORKER2_CONFIG_PATH}    ${CURDIR}/../variables/coe/worker2.odlovs-cni.conf
${K8s_MINION1_IP}    192.168.33.12
${K8s_MINION2_IP}    192.168.33.13
${MINION1_USER}    admin
${MINION1_PASSWORD}    admin
${MINION2_USER}    admin
${MINION2_PASSWORD}    admin
${K8s_MASTER_IP}    192.168.33.11
${MASTER_CONFIG_PATH_L}    ${CURDIR}/../variables/coe/master.odlovs-cni.conf
${CONFIG_FILES_PATH}    /etc/cni/net.d
${CNI_BINARY_PATH}    /opt/cni/bin/odlovs-cni
${WATCHER_PATH}    go/src/git.opendaylight.org/gerrit/p/coe.git/watcher
${MASTER_HOME}    home
${K8s_MASTER_PORT}    6443
${CNI_PATH_1}     $GOPATH/src/git.opendaylight.org/gerrit/p/coe.git/odlCNIPlugin/odlovs-cni/bin/odlovs-cni
${CNI_PATH_2}     /opt/cni/bin
${NETVIRT_PATH}    ${CURDIR}/../../variables/netvirt/Modules.py
${COE_PATH}       ${CURDIR}/../../variables/coe/Modules.py

*** Keywords ***
Start_Suite
    ${conn_id_1}    ${token}    ${bridge}    Start_K8s_Master
    ${conn_id_2}=    Start_K8s_Minion    ${WORKER1_CONFIG_PATH}    ${K8s_MINION1_IP}    ${MINION1_USER}    ${MINION1_PASSWORD}    ${token}
    ${conn_id_3}=    Start_K8s_Minion    ${WORKER2_CONFIG_PATH}    ${K8s_MINION2_IP}    ${MINION2_USER}    ${MINION2_PASSWORD}    ${token}
    Verify_Nodes_Status
    Create_Label
    Set Global Variable    ${conn_id_1}
    Set Global Variable    ${conn_id_2}
    Set Global Variable    ${conn_id_3}
    Set Global Variable    ${bridge}

Start_K8s_Master
    ${conn_id_1}=    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${file}=    OperatingSystem.Get File    ${MASTER_CONFIG_PATH_L}
    ${file}=    Replace String    ${file}    1.1.1.1    ${ODL_SYSTEM_IP}
    OperatingSystem.Create File    ${MASTER_CONFIG_PATH_L}    ${file}
    Write    sudo mkdir -p ${CONFIG_FILES_PATH}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${MASTER_CONFIG_PATH_L}    ${CONFIG_FILES_PATH}
    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Execute Command    ${CONFIG_FILES_PATH}
    ${master}=    OperatingSystem.Get File    ${MASTER_CONFIG_PATH_L}
    ${line}    ${bridge}    Should Match Regexp    ${master}    "ovsBridge":"(\\w.*)"
    Write    sudo cp ${CNI_PATH_1} ${CNI_PATH_2}
    Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${CNI_BINARY_PATH}    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    ${token}=    Kube_init
    Start_Watcher
    [Return]    ${conn_id_1}    ${token}    ${bridge}

Kube_reset
    Write    sudo kubeadm reset
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    ${kube}=    Read Until Prompt
    Should Contain    ${kube}    Stopping the kubelet service.

Kube_init
    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    sudo swapoff --a
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Set Client Configuration    timeout=5s
    Read Until Prompt
    Write    sudo kubeadm init --apiserver-advertise-address=192.168.56.100
    ${init}=    Wait Until Keyword Succeeds    70s    5s    Read Until Regexp    .*@.*:
    ${join}=    Should Match Regexp    ${init}    kubeadm join.*
    Write    mkdir -p ${MASTER_HOME}/.kube
    Write    sudo cp -i /etc/kubernetes/admin.conf ${MASTER_HOME}/.kube/config
    Read Until Regexp    .*\?
    Write    y
    Comment    ${status}=    Run Keyword And Return Status    Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${MASTER_HOME}/.kube/config    ${TOOLS_SYSTEM_USER}
    ...    ${TOOLS_SYSTEM_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Comment    Run Keyword If    '${status}' == 'False'    Write    sudo cp -i /etc/kubernetes/admin.conf ${MASTER_HOME}/.kube/config
    Write    sudo chown $(id -u):$(id -g) ${MASTER_HOME}/.kube/config
    [Return]    ${join}

Start_Watcher
    Write    cd
    Write    cd ${WATCHER_PATH}
    Write    nohup ./watcher odl &

Start_K8s_Minion
    [Arguments]    ${WORKER_PATH}    ${MINION_IP}    ${MINION_USER}    ${MINION_PASSWORD}    ${token}
    ${conn_id}=    Open Connection    ${MINION_IP}
    Login    ${MINION_USER}    ${MINION_PASSWORD}
    Kube_reset
    ${file}=    OperatingSystem.Get File    ${WORKER_PATH}
    ${file}=    Replace String    ${file}    1.1.1.1    ${ODL_SYSTEM_IP}
    OperatingSystem.Create File    ${WORKER_PATH}    ${file}
    Copy_File_To_Remote_System    ${MINION_IP}    ${WORKER_PATH}    ${CONFIG_FILES_PATH}    ${MINION_USER}    ${MINION_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Open Connection    ${MINION_IP}
    Login    ${MINION_USER}    ${MINION_PASSWORD}
    Write    sudo swapoff --a
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Read Until Prompt
    Write    sudo ${token}
    ${init}=    Wait Until Keyword Succeeds    50s    5s    Read Until Regexp    .*@.*:
    log    {init}
    Close Connection
    [Return]    ${conn_id}

Create_Label
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    kubectl get nodes
    ${nodes}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    ${node_1}    Get Line    ${nodes}    2
    ${minion_1}=    Should Match Regexp    ${node_1}=    ^\\w+
    ${node_2}    Get Line    ${nodes}    3
    ${minion_2}=    Should Match Regexp    ${node_2}=    ^\\w+
    Write    kubectl label nodes ${minion_1} disktype=ssd
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Read Until Prompt
    Write    kubectl label nodes ${minion_2} disktype=ssl
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Read Until Prompt
    Write    kubectl get nodes --show-labels
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    ${label}=    Read Until Prompt
    log    ${label}
    Close Connection

Stop_Watcher
    Write    ps -ef | grep watcher
    ${lines}=    Read Until Prompt
    ${pid}=    Should Match Regexp    ${lines}=    \\s\\d+\\s
    Write    kill -9 ${pid}
    Read Until    ${DEFAULT_LINUX_PROMPT}

Stop_Suite
    Stop_Watcher
    Kube_reset
    Close All Connections

Coe_Tear_down
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    ${bridge}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    ${bridge}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_3}    ${bridge}
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
    Verify_Nodes_Status
    Verify_Pod_Status

Coe_Data_Models
    Open Connection    ${K8s_MASTER_IP}
    login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${file_1}=    OperatingSystem.Get File    ${NETVIRT_PATH}
    ${file_2}=    OperatingSystem.Get File    ${COE_PATH}
    ${model_netvirt}=    Split To Lines    ${file_1}=    1    30
    ${model_coe}=    Split To Lines    ${file_2}=    1    3
    : FOR    ${module}    IN    @{model_coe}=
    \    Append To List    ${model_netvirt}    ${module}
    ${data_models}=    Create List
    : FOR    ${models}    IN    @{model_netvirt}
    \    ${models}=    Should Match Regexp    ${models}    \\w.*\\w
    \    Append To List    ${data_models}    ${models}
    Set Global Variable    ${data_models}

Verify_Nodes_Status
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    50s    2s    Node_Status

Node_Status
    Write    kubectl get nodes
    ${nodes}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    ${count}=    Get Line Count    ${nodes}
    @{cluster}=    Split To Lines    ${nodes}=    1    ${count-1}
    : FOR    ${node}    IN    @{cluster}
    \    Should Match Regexp    ${node}    \\sReady

Pod_Status
    Write    kubectl get pods -o wide
    ${pods}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    ${count}=    Get Line Count    ${pods}
    @{cluster}=    Split To Lines    ${pods}    1    ${count-1}
    : FOR    ${pod}    IN    @{cluster}
    \    Should Match Regexp    ${pod}    \\sRunning

Verify_Pod_Status
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    50s    2s    Pod_Status

Delete_Pods
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Write    kubectl get pods -o wide
    ${lines}=    Read Until Prompt
    ${count}=    Get Line Count    ${lines}
    @{lines}=    Split To Lines    ${lines}    1    ${count-1}
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name}=    Should Match Regexp    ${status}    ^\\w+
    \    Execute Command    kubectl delete pods ${pod_name}
    Wait Until Keyword Succeeds    50s    2s    Delete_Status

Delete_Status
    Write    kubectl get pods -o wide
    ${status}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    log    ${status}
    Should Contain    ${status}    No resources
