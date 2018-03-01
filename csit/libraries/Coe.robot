*** Settings ***
Library           SSHLibrary
Library           BuiltIn
Library           String
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot

*** Variables ***
${WORKER1_CONFIG_PATH}    ${CURDIR}/test/csit/variables/coe/worker1.odlovs-cni.conf
${WORKER2_CONFIG_PATH}    ${CURDIR}/test/csit/variables/coe/worker2.odlovs-cni.conf
${K8s_MINION1_IP}    192.168.33.12
${K8s_MINION2_IP}    192.168.33.13
${MINION1_USER}    admin
${MINION1_PASSWORD}    admin
${MINION2_USER}    admin
${MINION2_PASSWORD}    admin
${K8s_MASTER_IP}    192.168.33.11
${MASTER_CONFIG_PATH_L}    ${CURDIR}/test/csit/variables/coe/master.odlovs-cni.conf
${CONFIG_FILES_PATH}    /etc/cni/net.d
${CNI_BINARY_PATH}    /opt/cni/bin/odlovs-cni
${WATCHER_PATH}    go/src/git.opendaylight.org/gerrit/p/coe.git/watcher
${MASTER_HOME}    ${CURDIR}
${K8s_MASTER_PORT}    6443
${CNI_PATH_1}     $GOPATH/src/git.opendaylight.org/gerrit/p/coe.git/odlCNIPlugin/odlovs-cni/bin/odlovs-cni
${CNI_PATH_2}     /opt/cni/bin

*** Keywords ***
Start_Suite
    Start_K8s_Master
    Write    sudo kubeadm token list
    ${init_token}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    ${TOKEN}=    Should Match Regexp    ${init_token}    [\\d\\w]{6}.[\\d\\w]{16}
    Start_K8s_Minion    ${WORKER1_CONFIG_PATH}    ${K8s_MINION1_IP}    ${MINION1_USER}    ${MINION1_PASSWORD}    ${TOKEN}
    Start_K8s_Minion    ${WORKER2_CONFIG_PATH}    ${K8s_MINION2_IP}    ${MINION2_USER}    ${MINION2_PASSWORD}    ${TOKEN}
    Verify_Nodes_Status

Start_K8s_Master
    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Kube_reset
    ${file}=    OperatingSystem.Get File    ${MASTER_CONFIG_PATH_L}
    ${file}=    Replace String    ${file}    1.1.1.1    ${ODL_SYSTEM_IP}
    Append To File    ${MASTER_CONFIG_PATH_L}    ${file}
    Write    sudo mkdir -p ${CONFIG_FILES_PATH}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${MASTER_CONFIG_PATH_L}    ${CONFIG_FILES_PATH}
    Open Connection    ${K8s_MASTER_IP}
    Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    sudo cp ${CNI_PATH_1} ${CNI_PATH_2}
    Write    ${DEFAULT_PASSWORD}
    Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${CNI_BINARY_PATH}    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}    ${DEFAULT_LINUX_PROMPT}
    Kube_init
    Start_Watcher

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
    Write    sudo kubeadm init --apiserver-advertise-address=${K8s_MASTER_IP}
    Wait Until Keyword Succeeds    50s    5s    Read Until Regexp    .*@.*:
    Write    mkdir -p ${MASTER_HOME}/.kube
    ${status}=    Run Keyword And Return Status    Verify File Exists On Remote System    ${K8s_MASTER_IP}    ${MASTER_HOME}/.kube/config    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}
    ...    ${DEFAULT_LINUX_PROMPT}
    Run Keyword If    '${status}' == 'False'    Write    sudo cp -i /etc/kubernetes/admin.conf ${MASTER_HOME}/.kube/config
    Write    sudo chown $(id -u):$(id -g) ${MASTER_HOME}/.kube/config

Start_Watcher
    Write    cd
    Write    cd ${WATCHER_PATH}
    Write    nohup ./watcher odl &

Start_K8s_Minion
    ${file}=    OperatingSystem.Get File    ${WORKER_PATH}
    ${file}=    Replace String    ${file}    1.1.1.1    ${ODL_SYSTEM_IP}
    Append To File    ${WORKER_PATH}    ${file}
    Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${WORKER_PATH}    ${CONFIG_FILES_PATH}
    Open Connection    ${MINION_IP}
    Login    ${MINION_USER}    ${MINION_PASSWORD}
    Write    sudo kubeadm join --token ${TOKEN} ${K8s_MASTER_IP}:${K8s_MASTER_PORT}
    Write    ${MINION_PASSWORD}

Verify_Nodes_Status
    Open Connection    ${K8s_MASTER_IP}
    Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Write    kubectl get nodes
    ${pods}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    Should Contain X Times    ${pods}    Ready    3
