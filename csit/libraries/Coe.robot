*** Settings ***
Library           SSHLibrary
Library           BuiltIn
Library           String
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot

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

*** Keywords ***
Start_Suite
    ${token}=    Start_K8s_Master
    Start_K8s_Minion    ${WORKER1_CONFIG_PATH}    ${K8s_MINION1_IP}    ${MINION1_USER}    ${MINION1_PASSWORD}    ${token}
    Start_K8s_Minion    ${WORKER2_CONFIG_PATH}    ${K8s_MINION2_IP}    ${MINION2_USER}    ${MINION2_PASSWORD}    ${token}
    ${node}=    Verify_Nodes_Status
    Create_Label    ${node}

Start_K8s_Master
    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${file}=    OperatingSystem.Get File    ${MASTER_CONFIG_PATH_L}
    ${file}=    Replace String    ${file}    1.1.1.1    ${ODL_SYSTEM_IP}
    OperatingSystem.Create File    ${MASTER_CONFIG_PATH_L}    ${file}
    Comment    Write    sudo mkdir -p ${CONFIG_FILES_PATH}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${MASTER_CONFIG_PATH_L}    ${CONFIG_FILES_PATH}
    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Comment    Write    sudo cp ${CNI_PATH_1} ${CNI_PATH_2}
    Comment    Write    ${DEFAULT_PASSWORD}
    Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${CNI_BINARY_PATH}    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    ${token}=    Kube_init
    Start_Watcher
    [Return]    ${token}

Kube_reset
    Write    sudo kubeadm reset
    Write    ${DEFAULT_PASSWORD}
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    ${kube}=    Read Until Prompt
    Should Contain    ${kube}    Stopping the kubelet service.

Kube_init
    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    sudo swapoff --a
    Write    ${DEFAULT_PASSWORD}
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Read Until Prompt
    Write    sudo kubeadm init --apiserver-advertise-address=192.168.56.100
    ${init}=    Wait Until Keyword Succeeds    50s    5s    Read Until Regexp    .*@.*:
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
    Open Connection    ${MINION_IP}
    Login    ${MINION_USER}    ${MINION_PASSWORD}
    Kube_reset
    ${file}=    OperatingSystem.Get File    ${WORKER_PATH}
    ${file}=    Replace String    ${file}    1.1.1.1    ${ODL_SYSTEM_IP}
    OperatingSystem.Create File    ${WORKER_PATH}    ${file}
    Copy_File_To_Remote_System    ${MINION_IP}    ${WORKER_PATH}    ${CONFIG_FILES_PATH}    ${MINION_USER}    ${MINION_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Open Connection    ${MINION_IP}
    Login    ${MINION_USER}    ${MINION_PASSWORD}
    Write    sudo swapoff --a
    Write    ${MINION_PASSWORD}
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Read Until Prompt
    Write    sudo ${token}
    ${init}=    Wait Until Keyword Succeeds    50s    5s    Read Until Regexp    .*@.*:
    log    {init}
    Close Connection

Verify_Nodes_Status
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    kubectl get nodes
    ${pods}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    ${ready}=    Get Lines Matching Regexp    ${pods}    \\sReady    partial_match=true
    ${count}=    Get Line Count    ${ready}
    Close Connection
    Run Keyword If    ${count}!=3    Verify_Nodes_Status
    [Return]    ${pods}

Create_Label
    [Arguments]    ${nodes}
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${node_1}    Get Line    ${nodes}    2
    ${minion_1}=    Should Match Regexp    ${node_1}=    ^\\w+
    ${node_2}    Get Line    ${nodes}    3
    ${minion_2}=    Should Match Regexp    ${node_2}=    ^\\w+
    Write    kubectl label nodes ${minion_1} disktype=ssd
    Set Client Configuration    prompt=${DEFAULT_LINUX_PROMPT}
    Read Until Prompt
    Write    kubectl label nodes minion2 disktype=ssl
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

Stop_Suite
    Stop_Watcher
    Kube_reset
    Close All Connections
