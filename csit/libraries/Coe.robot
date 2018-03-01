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
Resource          Genius.robot

*** Variables ***
${BRIDGE}         br-int
${CNI_BINARY_FILE}    /opt/cni/bin/odlovs-cni
${COE_MODULES}    ${CURDIR}/../variables/coe/Modules.py
${CONFIG_FILES_PATH}    /etc/cni/net.d/odlovs-cni.conf
${HOST_INVENTORY}    ${CURDIR}/../variables/coe/hosts.yaml
${CONFIG_FILE}    ${CURDIR}/../variables/coe/odlovs-cni.conf.j2
${PLAYBOOK}       ${CURDIR}/../variables/coe/coe_play.yaml
${NETVIRT_MODULES}    ${CURDIR}/../variables/netvirt/Modules.py

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword.
    Coe.Ansible Playbook
    Coe.Get Connection ids
    Coe.Verify Config Files
    Coe.Check Watcher
    Coe.Verify Nodes Status
    Coe.Create Label

Get Connection ids
    [Documentation]    Gets the connection ids for all the nodes
    ${conn_id_1} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_1}
    ${conn_id_2} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_2_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_2}
    ${conn_id_3} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_3_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_3}

Verify Config Files
    [Documentation]    Checks if the configuration files are present in all nodes
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_1_IP}    ${CONFIG_FILES_PATH}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_2_IP}    ${CONFIG_FILES_PATH}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_3_IP}    ${CONFIG_FILES_PATH}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_1_IP}    ${CNI_BINARY_FILE}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_2_IP}    ${CNI_BINARY_FILE}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_3_IP}    ${CNI_BINARY_FILE}

Check Watcher
    [Documentation]    Checks if watcher is running in the background
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    ps -ef | grep watcher
    ${pid} =    BuiltIn.Should Match Regexp    ${lines}    .* watcher odl

Verify Nodes Status
    [Documentation]    Waits till the keyword _node _status_ succeeds implying that all nodes are ready
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    40s    2s    Coe.Node_Status
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    kubectl get nodes    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}

Create Label
    [Documentation]    Create labels for minions so that random allocation of pods to minions is avoided
    ${nodes} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl get nodes
    ${node_1} =    String.Get Line    ${nodes}    2
    ${minion_1} =    BuiltIn.Should Match Regexp    ${node_1}    ^\\w+-.*-\\d+
    ${node_2} =    String.Get Line    ${nodes}    3
    ${minion_2} =    BuiltIn.Should Match Regexp    ${node_2}    ^\\w+-.*-\\d+
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    kubectl label nodes ${minion_1} disktype=ssd
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    kubectl label nodes ${minion_2} disktype=ssl
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    kubectl get nodes --show-labels

Tear Down
    [Documentation]    Test teardown to get dumpflows,ovsconfig,model dump,node status and pod status
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_3}    ${BRIDGE}
    Coe.Data_Models
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
    Coe.Check Config File
    Genius.Verify Tunnel Status as UP
    Coe.Verify_Nodes_Status
    Coe.Verify_Pod_Status
    Coe.Delete_Pods
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    journalctl -u kubelet

Data Models
    [Documentation]    Data models created by integrating netvirt and coe data models which is given as input to get the model dumps
    ${file_1} =    OperatingSystem.Get File    ${NETVIRT_MODULES}
    ${file_2} =    OperatingSystem.Get File    ${COE_MODULES}
    ${netvirt_models} =    String.Split To Lines    ${file_1}    1    59
    ${coe_models}    String.Split To Lines    ${file_2}    1    3
    : FOR    ${module}    IN    @{coe_models}
    \    Collections.Append To List    ${netvirt_models}    ${module}
    ${data_models} =    BuiltIn.Create List
    : FOR    ${models}    IN    @{netvirt_models}
    \    ${models} =    BuiltIn.Should Match Regexp    ${models}    \\w.*\\w
    \    Collections.Append To List    ${data_models}    ${models}
    BuiltIn.Set Global Variable    ${data_models}

Node Status
    [Documentation]    Checks the status of nodes.This keyword is repeated until the status of all nodes is \ _Ready_
    ${nodes} =    Utils.Write Commands Until Expected Prompt    kubectl get nodes    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${count} =    String.Get Line Count    ${nodes}
    @{cluster} =    String.Split To Lines    ${nodes}    1    ${count-1}
    : FOR    ${node}    IN    @{cluster}
    \    BuiltIn.Should Match Regexp    ${node}    \\sReady
    SSHLibrary.Close Connection

Verify Pod Status
    [Documentation]    Waits till the keyword _pod _status_ succeeds implying that all pods are running
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Pod_Status
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}

Pod Status
    [Documentation]    Checks the status of pods.This keyword is repeated until the status of all pods is \ _Running_
    ${pods} =    Utils.Write Commands Until Expected Prompt    kubectl get pods -o wide    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${count} =    String.Get Line Count    ${pods}
    @{cluster} =    String.Split To Lines    ${pods}    1    ${count-1}
    : FOR    ${pod}    IN    @{cluster}
    \    BuiltIn.Should Match Regexp    ${pod}    \\sRunning
    SSHLibrary.Close Connection

Delete Pods
    [Documentation]    Waits till the keyword _delete _status_ succeeds implying that all pods created \ have been deleted
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl get pods -o wide
    @{lines} =    String.Split To Lines    ${lines}    1
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name} =    BuiltIn.Should Match Regexp    ${status}    ^\\w+
    \    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl delete pods ${pod_name}
    BuiltIn.Wait Until Keyword Succeeds    60s    3s    Coe.Delete_Status

Delete Status
    [Documentation]    Checks if the pods created have been terminated.The keyword is repeated until the pods are deleted
    ${status} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    \    ${EMPTY}
    ...    return_stdout=False    return_stderr=True
    BuiltIn.Should Contain    ${status}    No resources

Stop Suite
    [Documentation]    Suite teardown keyword
    Coe.Stop_Watcher
    Coe.Kube_reset    ${TOOLS_SYSTEM_1_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Coe.Kube_reset    ${TOOLS_SYSTEM_2_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Coe.Kube_reset    ${TOOLS_SYSTEM_3_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    SSHLibrary.Close All Connections

Kube reset
    [Arguments]    ${system}    ${node_user}    ${node_password}
    [Documentation]    Reset K8s to clear up all stale entries
    ${kube}    Utils.Run Command On Remote System And Log    ${system}    sudo kubeadm reset    ${node_user}    ${node_password}
    BuiltIn.Should Contain    ${kube}    Stopping the kubelet service.

Stop Watcher
    [Documentation]    Kill the watcher running at the background after completion of tests cases
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    ps -ef | grep watcher
    ${line}    ${pid}    BuiltIn.Should Match Regexp    ${lines}    \\w+\\s+(\\d+).*watcher odl
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kill -9 ${pid}

Ansible Playbook
    ${hosts}=    OperatingSystem.Get File    ${HOST_INVENTORY}
    ${hosts}=    String.Replace String    ${hosts}    master_ip    ${TOOLS_SYSTEM_IP}
    ${hosts}=    String.Replace String    ${hosts}    minion1_ip    ${TOOLS_SYSTEM_2_IP}
    ${hosts}=    String.Replace String    ${hosts}    minion2_ip    ${TOOLS_SYSTEM_3_IP}
    ${hosts}=    String.Replace String    ${hosts}    odl_ip    ${ODL_SYSTEM_IP}
    ${hosts}=    String.Replace String    ${hosts}    filepath    ${CONFIG_FILE}
    OperatingSystem.Create File    ${USER_HOME}/hosts.yaml    ${hosts}
    OperatingSystem.Move File    ${PLAYBOOK}    ${USER_HOME}
    ${rc}    ${play_output}    Run And Return Rc And Output    ansible-playbook ${USER_HOME}/coe_play.yaml -i ${USER_HOME}/hosts.yaml
    log    ${play_output}

Check Config File
    Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    cat /etc/cni/net.d/odlovs-cni.conf.j2
    Run Command On Remote System And Log    ${TOOLS_SYSTEM_2_IP}    cat /etc/cni/net.d/odlovs-cni.conf.j2
    Run Command On Remote System And Log    ${TOOLS_SYSTEM_3_IP}    cat /etc/cni/net.d/odlovs-cni.conf.j2
