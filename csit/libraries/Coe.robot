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
${MASTER_CONFIG_PATH_L}    ${CURDIR}/../variables/coe/master.odlovs-cni.conf
${CONFIG_FILES_PATH}    /etc/cni/net.d
${CNI_BINARY_PATH}    /opt/cni/bin/odlovs-cni
${WATCHER_PATH}    $GOPATH/src/git.opendaylight.org/gerrit/p/coe.git/watcher
${MASTER_HOME}    home
${CNI_PATH_1}     $GOPATH/src/git.opendaylight.org/gerrit/p/coe.git/odlCNIPlugin/odlovs-cni/bin/odlovs-cni
${CNI_PATH_2}     /opt/cni/bin
${NETVIRT_PATH}    ${CURDIR}/../variables/netvirt/Modules.py
${COE_PATH}       ${CURDIR}/../variables/coe/Modules.py
${K8s_MASTER_IP}    192.168.33.11
${K8s_MINION1_IP}    192.168.33.12
${K8s_MINION2_IP}    192.168.33.13
${MINION1_USER}    admin
${MINION2_USER}    admin
${MINION1_PASSWORD}    admin
${MINION2_PASSWORD}    admin
${K8s_MASTER_PORT}    6443

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.This keywords brings up the K8s master and minions.
    ${conn_id_1}    ${bridge}    ${token}    Start_K8s_Master
    ${conn_id_2}    Start_K8s_Minion    ${WORKER1_CONFIG_PATH}    ${K8s_MINION1_IP}    ${MINION1_USER}    ${MINION1_PASSWORD}    ${token}
    ${conn_id_3}    Start_K8s_Minion    ${WORKER2_CONFIG_PATH}    ${K8s_MINION2_IP}    ${MINION2_USER}    ${MINION2_PASSWORD}    ${token}
    Verify_Nodes_Status
    Create_Label
    Set Global Variable    ${conn_id_1}
    Set Global Variable    ${conn_id_2}
    Set Global Variable    ${conn_id_3}
    Set Global Variable    ${bridge}

Start_K8s_Master
    [Documentation]    Brings up K8s master by copying the necessary config files and initialising K8s
    ${conn_id}=    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    @{opt_commands}=    Create List    sudo mkdir -p ${CNI_PATH_2}    sudo cp ${CNI_PATH_1} ${CNI_PATH_2}
    : FOR    ${cmd_1}    IN    @{opt_commands}
    \    Write Commands Until Expected Prompt    ${cmd_1}    ${DEFAULT_LINUX_PROMPT}
    @{etc_commands}=    Create List    cd /etc    sudo mkdir -m 777 cni    cd cni    sudo mkdir -m 755 net.d
    : FOR    ${cmd}    IN    @{etc_commands}
    \    Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT}
    ${file}=    OperatingSystem.Get File    ${MASTER_CONFIG_PATH_L}
    ${file}=    Replace String    ${file}    1.1.1.1    ${ODL_SYSTEM_IP}
    OperatingSystem.Create File    ${MASTER_CONFIG_PATH_L}    ${file}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${MASTER_CONFIG_PATH_L}    ${CONFIG_FILES_PATH}
    ${master}=    OperatingSystem.Get File    ${MASTER_CONFIG_PATH_L}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${MASTER_CONFIG_PATH_L}    ${CONFIG_FILES_PATH}
    ${line}    ${bridge}    Should Match Regexp    ${master}    "ovsBridge":"(\\w.*)"
    Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${CNI_BINARY_PATH}    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    ${token}=    Kube_init
    Start_Watcher
    [Return]    ${conn_id}    ${bridge}    ${token}

Kube_reset
    [Arguments]    ${SYSTEM}    ${NODE_USER}    ${NODE_PASSWORD}
    [Documentation]    Reset K8s to clear up all stale entries
    ${kube}    Run Command On Remote System    ${SYSTEM}    sudo kubeadm reset    ${NODE_USER}    ${NODE_PASSWORD}
    Should Contain    ${kube}    Stopping the kubelet service.

Kube_init
    [Documentation]    Initialise K8s on the master node and extract token needed to join the minions
    Run Command On Remote System    ${K8s_MASTER_IP}    sudo swapoff --a    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${init}=    Run Command On Remote System And Log    ${K8s_MASTER_IP}    sudo kubeadm init --apiserver-advertise-address=${K8s_MASTER_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${EMPTY}
    ...    70s
    ${join}=    Should Match Regexp    ${init}    kubeadm join.*
    Run Command On Remote System    ${K8s_MASTER_IP}    mkdir -p ${MASTER_HOME}/.kube    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    sudo cp -i /etc/kubernetes/admin.conf ${MASTER_HOME}/.kube/config
    Read Until Regexp    .*\?
    Write    y
    Close Connection
    Run Command On Remote System    ${K8s_MASTER_IP}    sudo chown $(id -u):$(id -g) ${MASTER_HOME}/.kube/config    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    [Return]    ${join}

Start_Watcher
    [Documentation]    Run watcher from the master node in background
    Run Command On Remote System    ${K8s_MASTER_IP}    cd ${WATCHER_PATH}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Run Command On Remote System    ${K8s_MASTER_IP}    nohup ./watcher odl &    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}

Start_K8s_Minion
    [Arguments]    ${WORKER_PATH}    ${MINION_IP}    ${MINION_USER}    ${MINION_PASSWORD}    ${token}
    [Documentation]    Join minions to master using the token generated during K8s initialisation
    ${conn_id}    Open Connection    ${MINION_IP}
    Login    ${MINION_USER}    ${MINION_PASSWORD}
    ${file}=    OperatingSystem.Get File    ${WORKER_PATH}
    ${file}=    Replace String    ${file}    1.1.1.1    ${ODL_SYSTEM_IP}
    OperatingSystem.Create File    ${WORKER_PATH}    ${file}
    Copy_File_To_Remote_System    ${MINION_IP}    ${WORKER_PATH}    ${CONFIG_FILES_PATH}    ${MINION_USER}    ${MINION_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Run Command On Remote System    ${MINION_IP}    sudo swapoff --a    ${MINION_USER}    ${MINION_PASSWORD}
    Run Command On Remote System And Log    ${MINION_IP}    sudo ${token}    ${MINION_USER}    ${MINION_PASSWORD}    \    55s
    [Return]    ${conn_id}

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
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    ${bridge}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    ${bridge}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_3}    ${bridge}
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
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
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
    ${count}=    Get Line Count    ${lines}
    @{lines}=    Split To Lines    ${lines}    1    ${count}
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name}=    Should Match Regexp    ${status}    ^\\w+
    \    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl delete pods ${pod_name}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    55 s    3s    Delete_Status

Delete_Status
    [Documentation]    Checks if the pods created have been terminated.The keyword is repeated until the pods are deleted
    ${status}=    Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${EMPTY}
    ...    return_stdout=False    return_stderr=True
    Should Contain    ${status}    No resources
