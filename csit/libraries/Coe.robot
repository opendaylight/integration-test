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
${CONFIG_FILE}    /etc/cni/net.d/odlovs-cni.conf
${HOST_INVENTORY}    ${CURDIR}/../variables/coe/hosts.yaml
${CONFIG_FILE_TEMPLATE}    ${CURDIR}/../variables/coe/odlovs-cni.conf.j2
${PLAYBOOK}       ${CURDIR}/../variables/coe/coe_play.yaml
${NETVIRT_MODULES}    ${CURDIR}/../variables/netvirt/Modules.py
${WATCHER_COE}    ${CURDIR}/../variables/coe/coe.yaml

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword.
    Coe.Ansible Playbook
    Coe.Set Connection ids
    Coe.Verify Config Files
    Coe.Verify Watcher Is Running
    Coe.Verify Node Status
    Coe.Label Nodes
    Genius.Verify Tunnel Status as UP    default-transport-zone

Set Connection ids
    [Documentation]    Sets the connection ids for all the nodes
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
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_1_IP}    ${CONFIG_FILE}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_2_IP}    ${CONFIG_FILE}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_3_IP}    ${CONFIG_FILE}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_1_IP}    ${CNI_BINARY_FILE}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_2_IP}    ${CNI_BINARY_FILE}
    Utils.Verify File Exists On Remote System    ${TOOLS_SYSTEM_3_IP}    ${CNI_BINARY_FILE}

Verify Watcher Is Running
    [Documentation]    Checks if watcher is running in the background
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    ps -ef | grep watcher
    ${pid} =    BuiltIn.Should Match Regexp    ${lines}    .* watcher odl

Verify Node Status
    [Documentation]    Waits till the keyword \ node \ status \ succeeds implying that all nodes are ready
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    40s    2s    Coe.Check Node Status
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    kubectl get nodes    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}

Label Nodes
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
    [Documentation]    Test teardown to get dumpflows,ovsconfig,model dump,config files dump and to delete pods
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    ${BRIDGE}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_3}    ${BRIDGE}
    Coe.Data Models
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
    Coe.DumpConfig File
    Coe.Delete Pods

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

Check Node Status
    [Documentation]    Checks the status of nodes.This keyword is repeated until the status of all nodes is \ Ready
    ${nodes} =    Utils.Write Commands Until Expected Prompt    kubectl get nodes    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${count} =    String.Get Line Count    ${nodes}
    @{cluster} =    String.Split To Lines    ${nodes}    1    ${count-1}
    : FOR    ${node}    IN    @{cluster}
    \    BuiltIn.Should Match Regexp    ${node}    \\sReady
    SSHLibrary.Close Connection

Verify Pod Status
    [Documentation]    Waits till the keyword \ pod status succeeds implying that all pods are running
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    55s    2s    Coe.Check Pod Status
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}

Check Pod Status
    [Documentation]    Checks the status of pods.This keyword is repeated until the status of all pods is \ _Running_
    ${pods} =    Utils.Write Commands Until Expected Prompt    kubectl get pods -o wide    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${count} =    String.Get Line Count    ${pods}
    @{cluster} =    String.Split To Lines    ${pods}    1    ${count-1}
    : FOR    ${pod}    IN    @{cluster}
    \    BuiltIn.Should Match Regexp    ${pod}    \\sRunning
    SSHLibrary.Close Connection

Delete Pods
    [Documentation]    Waits till the keyword delete status succeeds implying that all pods created have been deleted
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl get pods -o wide
    @{lines} =    String.Split To Lines    ${lines}    1
    : FOR    ${status}    IN    @{lines}
    \    ${pod_name} =    BuiltIn.Should Match Regexp    ${status}    ^\\w+
    \    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kubectl delete pods ${pod_name}
    BuiltIn.Wait Until Keyword Succeeds    60s    3s    Coe.Check If Pods Are Terminated

Check If Pods Are Terminated
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
    Coe.Collect Watcher Log
    Coe.Collect Journalctl Log
    SSHLibrary.Close All Connections

Kube reset
    [Arguments]    ${system}    ${node_user}    ${node_password}
    [Documentation]    Reset K8s to clear up all stale entries
    ${kube} =    Utils.Run Command On Remote System And Log    ${system}    sudo kubeadm reset    ${node_user}    ${node_password}
    BuiltIn.Should Contain    ${kube}    Stopping the kubelet service.

Stop Watcher
    [Documentation]    Kill the watcher running at the background after completion of tests cases
    ${lines} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    ps -ef | grep watcher
    ${line}    ${pid} =    BuiltIn.Should Match Regexp    ${lines}    \\w+\\s+(\\d+).*watcher odl
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    kill -9 ${pid}

Ansible Playbook
    [Documentation]    Ansible playbook which does all basic installations for Kubernetes
    ${hosts} =    OperatingSystem.Get File    ${HOST_INVENTORY}
    ${hosts} =    String.Replace String    ${hosts}    master_ip    ${TOOLS_SYSTEM_IP}
    ${hosts} =    String.Replace String    ${hosts}    minion1_ip    ${TOOLS_SYSTEM_2_IP}
    ${hosts} =    String.Replace String    ${hosts}    minion2_ip    ${TOOLS_SYSTEM_3_IP}
    ${hosts} =    String.Replace String    ${hosts}    odl_ip    ${ODL_SYSTEM_IP}
    ${hosts} =    String.Replace String    ${hosts}    filepath    ${CONFIG_FILE_TEMPLATE}
    ${hosts} =    String.Replace String    ${hosts}    yamlpath    ${USER_HOME}/coe.yaml
    OperatingSystem.Create File    ${USER_HOME}/hosts.yaml    ${hosts}
    ${watcher} =    OperatingSystem.Get File    ${WATCHER_COE}
    ${watcher} =    String.Replace String    ${watcher}    odlip    ${ODL_SYSTEM_IP}
    OperatingSystem.Create File    ${WATCHER_COE}    ${watcher}
    SSHKeywords.Copy_File_To_Remote_System    ${TOOLS_SYSTEM_1_IP}    ${WATCHER_COE}    ${USER_HOME}
    OperatingSystem.Move File    ${PLAYBOOK}    ${USER_HOME}
    ${rc}    ${play_output} =    OperatingSystem.Run And Return Rc And Output    ansible-playbook ${USER_HOME}/coe_play.yaml -i ${USER_HOME}/hosts.yaml
    BuiltIn.Log    ${play_output}

Dump Config File
    [Documentation]    Logs the configuration files present in all nodes
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    cat ${CONFIG_FILE}
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_2_IP}    cat ${CONFIG_FILE}
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_3_IP}    cat ${CONFIG_FILE}

Collect Watcher Log
    [Documentation]    Watcher running in background logs into watcher.out which is copied to ${WORKSPACE}/archives/watcher.txt
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    SSHLibrary.Get File    /tmp/watcher.out    ${WORKSPACE}/archives/watcher.txt
    SSHLibrary.Get File    /tmp/watcher.out    ${USER_HOME}/watcher.txt
    SSHLibrary.Close Connection
    OperatingSystem.Copy File    ${USER_HOME}/watcher.txt    ${WORKSPACE}/archives/watcher1.txt

Collect Journalctl Log
    [Documentation]    Logs of the command journalctl -u kubelet is copied to ${WORKSPACE}/archives/journal.txt
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    sudo journalctl -u kubelet > ${USER_HOME}/journal.txt
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_1_IP}
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    SSHLibrary.Get File    ${USER_HOME}/journal.txt    ${WORKSPACE}/archives/journalctl.txt
    SSHLibrary.Close Connection
