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
${BRIDGE}         br-int
${CNI_BINARY_PATH}    /opt/cni/bin/odlovs-cni
${COE_PATH}       ${CURDIR}/../variables/coe/Modules.py
${CONFIG_FILES_PATH}    /etc/cni/net.d/odlovs-cni.conf
${INVENTORY_PATH}    ${CURDIR}/../variables/coe/hosts.yaml
${CONF_PATH}      ${CURDIR}/../variables/coe/odlovs-cni.conf.j2
${PLAYBOOK_PATH}    ${CURDIR}/../variables/coe/coe_play.yaml
${NETVIRT_PATH}    ${CURDIR}/../variables/netvirt/Modules.py

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    ${a} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    git --version
    log    ${a}
    ${b} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    sudo apt-get install git
    log    ${b}
    ${c} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo apt-get install git
    log    ${c}
    ${d} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_3_IP}    sudo apt-get install git
    log    ${d}
    Coe.Ansible_Playbook
    Coe.Get_Connection_ids
    Coe.Verify_Config_Files
    Coe.Check_Watcher
    Coe.Verify_Nodes_Status
    VpnOperations.Verify Tunnel Status as UP
    Coe.Create_Label

Get_Connection_ids
    [Documentation]    Gets the \ connection ids for all the nodes
    ${conn_id_1} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_1}
    ${a}    Write Commands Until Expected Prompt    git --version    ${DEFAULT_LINUX_PROMPT}
    log    ${a}
    ${conn_id_2} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_2_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_2}
    ${b}    Write Commands Until Expected Prompt    git --version    ${DEFAULT_LINUX_PROMPT}
    log    ${b}
    ${conn_id_3} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_3_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Global Variable    ${conn_id_3}
    ${c}    Write Commands Until Expected Prompt    git --version    ${DEFAULT_LINUX_PROMPT}
    log    ${c}

Verify_Config_Files
    [Documentation]    Checks if the configuration files are present in all nodes
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_1_IP}    ${CONFIG_FILES_PATH}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_2_IP}    ${CONFIG_FILES_PATH}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_3_IP}    ${CONFIG_FILES_PATH}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_1_IP}    ${CNI_BINARY_PATH}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_2_IP}    ${CNI_BINARY_PATH}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_3_IP}    ${CNI_BINARY_PATH}

Check_Watcher
    [Documentation]    Checks if watcher is running in the background
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    ps -ef | grep watcher
    ${pid} =    BuiltIn.Should Match Regexp    ${lines}    .* watcher odl

Verify_Nodes_Status
    [Documentation]    Waits till the keyword _node _status_ succeeds implying that all nodes are ready
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    50s    2s    Coe.Node_Status

Create_Label
    [Documentation]    Create labels for minions so that random allocation of pods to minions is avoided
    ${nodes} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl get nodes
    ${node_1} =    String.Get Line    ${nodes}    2
    ${minion_1} =    BuiltIn.Should Match Regexp    ${node_1}    ^\\w+
    ${node_2} =    String.Get Line    ${nodes}    3
    ${minion_2} =    BuiltIn.Should Match Regexp    ${node_2}    ^\\w+
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl label nodes ${minion_1} disktype=ssd
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl label nodes ${minion_2} disktype=ssl
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl get nodes --show-labels

Tear_Down
    [Documentation]    Test teardown to get dumpflows,ovsconfig,model dump,node status and pod status
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_3}    ${BRIDGE}
    Coe.Data_Models
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
    Coe.Verify_Nodes_Status
    Coe.Verify_Pod_Status
    Coe.Delete_Pods

Data_Models
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
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
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
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl get pods -o wide
    @{lines} =    String.Split To Lines    ${lines}    1
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name} =    BuiltIn.Should Match Regexp    ${status}    ^\\w+
    \    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl delete pods ${pod_name}
    BuiltIn.Wait Until Keyword Succeeds    60s    3s    Coe.Delete_Status

Delete_Status
    [Documentation]    Checks if the pods created have been terminated.The keyword is repeated until the pods are deleted
    ${status} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl get pods -o wide    \    \    ${EMPTY}
    ...    return_stdout=False    return_stderr=True
    BuiltIn.Should Contain    ${status}    No resources

Stop_Suite
    [Documentation]    Suite teardown keyword
    Coe.Stop_Watcher
    Coe.Kube_reset    ${TOOLS_SYSTEM_1_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Coe.Kube_reset    ${TOOLS_SYSTEM_2_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Coe.Kube_reset    ${TOOLS_SYSTEM_3_IP}    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    SSHLibrary.Close All Connections

Kube_reset
    [Arguments]    ${system}    ${node_user}    ${node_password}
    [Documentation]    Reset K8s to clear up all stale entries
    ${kube}    Utils.Run Command On Remote System    ${system}    sudo kubeadm reset    ${node_user}    ${node_password}
    BuiltIn.Should Contain    ${kube}    Stopping the kubelet service.

Stop_Watcher
    [Documentation]    Kill the watcher running at the background after completion of tests cases
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    ps -ef | grep watcher
    ${line}    ${pid}    BuiltIn.Should Match Regexp    ${lines}    \\w+\\s+(\\d+).*watcher odl
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kill -9 ${pid}

Ansible_Playbook
    ${hosts}=    OperatingSystem.Get File    ${INVENTORY_PATH}
    ${hosts}=    String.Replace String    ${hosts}    master_ip    ${TOOLS_SYSTEM_IP}
    ${hosts}=    String.Replace String    ${hosts}    minion1_ip    ${TOOLS_SYSTEM_2_IP}
    ${hosts}=    String.Replace String    ${hosts}    minion2_ip    ${TOOLS_SYSTEM_3_IP}
    ${hosts}=    String.Replace String    ${hosts}    odl_ip    ${ODL_SYSTEM_IP}
    ${hosts}=    String.Replace String    ${hosts}    filepath    ${CONF_PATH}
    OperatingSystem.Create File    ${USER_HOME}/hosts.yaml    ${hosts}
    OperatingSystem.Move File    ${PLAYBOOK_PATH}    ${USER_HOME}
    ${rc}    ${play_output}    Run And Return Rc And Output    ansible-playbook ${USER_HOME}/coe_play.yaml -i ${USER_HOME}/hosts.yaml
    log    ${play_output}
