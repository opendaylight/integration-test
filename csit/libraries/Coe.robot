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
Resource          ToolsSystem.robot

*** Variables ***
${BUSY_BOX}       ${CURDIR}/../variables/coe/busy-box.yaml
${CNI_BINARY_FILE}    /opt/cni/bin/odlovs-cni
${CONFIG_FILE}    /etc/cni/net.d/odlovs-cni.conf
${CONFIG_FILE_TEMPLATE}    ${CURDIR}/../variables/coe/odlovs-cni.conf.j2
${HOST_INVENTORY}    ${CURDIR}/../variables/coe/hosts.yaml
${K8s_MASTER_IP}    ${TOOLS_SYSTEM_1_IP}
${HOSTS_FILE_TEMPLATE}    ${CURDIR}/../variables/coe/minions_template.yaml
${NODE_READY_STATUS}    \\sReady    # The check using this variable should not mess up with NotReady
${PLAYBOOK_FILE}    ${CURDIR}/../variables/coe/coe_play.yaml
${POD_RUNNING_STATUS}    \\sRunning
${VARIABLES_PATH}    ${CURDIR}/../variables/coe
${WATCHER_COE}    ${CURDIR}/../variables/coe/coe.yaml
@{COE_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    ELAN    OVSDB

*** Keywords ***
Coe Suite Setup
    [Documentation]    COE project requires start suite to be executed only for the first test suite.This keyword find the current suite,compares it with the stored first suite value and executes Coe.Start suite only if the cuurent suite is equal to the first suite.
    ToolsSystem.Get Tools System Nodes Data
    Coe.Set Connection ids and Bridge
    Coe.Derive Coe Data Models
    ${current suite}    ${suite names updated}    Extract current suite name
    ${first_suite} =    Set Variable    ${suite names updated[0]}
    ${status} =    BuiltIn.Evaluate    '${first_suite}' == '${current suite}'
    Run Keyword If    '${status}' == 'True'    Coe.Start Suite

Start Suite
    [Documentation]    Suite setup keyword.
    Coe.Configuration Playbook
    Coe.Verify Config Files
    Coe.Verify Watcher Is Running
    BuiltIn.Wait Until Keyword Succeeds    40s    2s    Coe.Check Node Status Is Ready
    Coe.Label Nodes
    BuiltIn.Wait Until Keyword Succeeds    60    2    ClusterManagement.Check Status Of Services Is OPERATIONAL    @{COE_DIAG_SERVICES}
    BuiltIn.Wait Until Keyword Succeeds    85    2    Genius.Verify Tunnel Status As Up

Set Connection ids and Bridge
    [Documentation]    Sets the connection ids for all the nodes and get the bridge from configuration file .
    FOR    ${conn_id}    IN    @{TOOLS_SYSTEM_ALL_CONN_IDS}
        SSHLibrary.Switch Connection    ${conn_id}
        SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    END
    ${file} =    OperatingSystem.Get File    ${CONFIG_FILE_TEMPLATE}
    ${ovs bridge output}    ${bridge} =    BuiltIn.Should Match Regexp    ${file}    "ovsBridge": "(\\w.*)"
    BuiltIn.Set Suite Variable    ${bridge}

Configuration Playbook
    [Documentation]    Ansible playbook which does all basic configuration for kubernetes nodes.
    ${playbook minions}    ${playbook hosts}    ${host file}    Modifying templates in playbook
    ${playbook} =    OperatingSystem.Get File    ${PLAYBOOK_FILE}
    ${playbook} =    String.Replace String    ${playbook}    coe-hosts    ${playbook hosts}
    ${playbook} =    String.Replace String    ${playbook}    coe-minions    ${playbook minions}
    OperatingSystem.Create File    ${PLAYBOOK_FILE}    ${playbook}
    OperatingSystem.Create File    ${USER_HOME}/hosts.yaml    ${host file}
    ${watcher} =    OperatingSystem.Get File    ${WATCHER_COE}
    ${watcher} =    String.Replace String    ${watcher}    odlip    ${ODL_SYSTEM_IP}
    ${watcher} =    String.Replace String    ${watcher}    port    ${RESTCONFPORT}
    OperatingSystem.Create File    ${WATCHER_COE}    ${watcher}
    SSHKeywords.Copy_File_To_Remote_System    ${K8s_MASTER_IP}    ${WATCHER_COE}    ${USER_HOME}
    OperatingSystem.Copy File    ${PLAYBOOK_FILE}    ${USER_HOME}
    ${branch_ref_spec} =    BuiltIn.Catenate    SEPARATOR=    refs/heads/    ${GERRIT_BRANCH}
    ${gerrit_ref_spec} =    BuiltIn.Set Variable If    '${GERRIT_PROJECT}' != 'coe'    ${branch_ref_spec}    ${GERRIT_REFSPEC}
    Run Coe Playbook    ${gerrit_ref_spec}

Run Coe Playbook
    [Arguments]    ${gerrit_ref_spec}
    ${play_output} =    OperatingSystem.Run    ansible-playbook -v ${USER_HOME}/coe_play.yaml -i ${USER_HOME}/hosts.yaml --extra-vars '{"gerrit_branch":"FETCH_HEAD","gerrit_refspec":"${gerrit_ref_spec}"}'
    BuiltIn.Log    ${play_output}

Modifying templates in playbook
    ${inventory} =    OperatingSystem.Get File    ${HOST_INVENTORY}
    ${template} =    OperatingSystem.Get File    ${HOSTS_FILE_TEMPLATE}
    ${template} =    String.Replace String    ${template}    minion_ip    ${TOOLS_SYSTEM_ALL_IPS[0]}
    @{minions}    Create List    coe-minion
    ${hosts}    Set Variable    coe-master:
    FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM}
        Append To List    ${minions}    coe-minion${i}
        ${hosts} =    Catenate    ${hosts}    coe-minion${i}:
    END
    ${hosts} =    Replace String Using Regexp    ${hosts}    :$    ${EMPTY}
    ${hosts} =    Remove Space on String    ${hosts}
    ${minion hosts} =    Replace String Using Regexp    ${hosts}    ^[\\w-]+:    ${EMPTY}
    FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM}
        ${j} =    Evaluate    ${i}+1
        ${template} =    String.Replace String    ${template}    ${minions[${i}-1]}    ${minions[${i}]}
        ${template} =    String.Replace String    ${template}    ${TOOLS_SYSTEM_ALL_IPS[${i}-1]}    ${TOOLS_SYSTEM_ALL_IPS[${i}]}
        ${template} =    String.Replace String    ${template}    192.168.50.1${i}    192.168.50.1${j}
        ${template} =    String.Replace String    ${template}    10.11.${i}.0/24    10.11.${j}.0/24
        ${template} =    String.Replace String    ${template}    10.11.${i}.1    10.11.${j}.1
        Append To File    ${HOST_INVENTORY}    ${template}
    END
    ${host file} =    OperatingSystem.Get File    ${HOST_INVENTORY}
    ${host file} =    String.Replace String    ${host file}    master_ip    ${TOOLS_SYSTEM_ALL_IPS[0]}
    ${host file} =    String.Replace String    ${host file}    odl_ip    ${ODL_SYSTEM_IP}
    ${host file} =    String.Replace String    ${host file}    mport    ${OVSDBPORT}
    ${host file} =    String.Replace String    ${host file}    cport    ${ODL_OF_PORT_6653}
    ${host file} =    String.Replace String    ${host file}    filepath    ${CONFIG_FILE_TEMPLATE}
    ${host file} =    String.Replace String    ${host file}    yamlpath    ${USER_HOME}/coe.yaml
    log    ${host file}
    [Return]    ${minion hosts}    ${hosts}    ${host file}

Verify Config Files
    [Documentation]    Checks if the configuration files are present in all nodes
    FOR    ${nodes}    IN    @{TOOLS_SYSTEM_ALL_IPS}
        Utils.Verify File Exists On Remote System    ${nodes}    ${CONFIG_FILE}
    END
    FOR    ${nodes}    IN    @{TOOLS_SYSTEM_ALL_IPS}
        Utils.Verify File Exists On Remote System    ${nodes}    ${CNI_BINARY_FILE}
    END

Verify Watcher Is Running
    [Documentation]    Checks if watcher is running in the background
    ${watcher status} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    ps -ef | grep watcher
    BuiltIn.Should Match Regexp    ${watcher status}    .* watcher odl

Check Node Status Is Ready
    [Documentation]    Checks the status of nodes.This keyword is repeated until the status of all nodes is Ready
    ${nodes} =    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get nodes    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${node_status} =    String.Get Lines Matching Regexp    ${nodes}    ${NODE_READY_STATUS}    partial_match=True
    ${lines_containing_ready} =    String.Get Line Count    ${node_status}
    BuiltIn.Should Be Equal As Strings    ${lines_containing_ready}    ${NUM_TOOLS_SYSTEM}

Label Nodes
    [Documentation]    Create labels for minions so that random allocation of pods to minions is avoided
    ${i} =    BuiltIn.Set Variable    1
    ${get nodes} =    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get nodes
    @{get nodes} =    String.Split To Lines    ${get nodes}    2
    FOR    ${status}    IN    @{get nodes}
        ${minion} =    BuiltIn.Should Match Regexp    ${status}    ^\\w+-.*-\\d+
        Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl label nodes ${minion} disktype=ss${i}
        ${i} =    BuiltIn.Evaluate    ${i}+1
    END
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get nodes --show-labels

Derive Coe Data Models
    [Documentation]    Data models is created by integrating netvirt and coe data models which is given as input to get the model dumps
    FOR    ${models}    IN    @{netvirt_data_models}
        Collections.Append To List    ${coe_data_models}    ${models}
    END

Check Pod Status Is Running
    [Documentation]    Checks the status of pods.This keyword is repeated until the status of all pods is Running
    ${pods} =    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{cluster} =    String.Split To Lines    ${pods}    1
    FOR    ${pod}    IN    @{cluster}
        BuiltIn.Should Match Regexp    ${pod}    ${POD_RUNNING_STATUS}
    END

Tear Down
    [Documentation]    Test teardown to get dumpflows,ovsconfig,model dump,node status,pod status and to dump config files \ and delete pods.
    FOR    ${conn_id}    IN    @{TOOLS_SYSTEM_ALL_CONN_IDS}
        OVSDB.Get DumpFlows And Ovsconfig    ${conn_id}    ${bridge}
    END
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${coe_data_models}
    Coe.DumpConfig File
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get nodes    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Coe.Delete Pods

Delete Pods
    [Documentation]    Waits till the keyword delete status succeeds implying that all pods created have been deleted
    ${get pods} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide
    @{get pods} =    String.Split To Lines    ${get pods}    1
    FOR    ${status}    IN    @{get pods}
        ${pod_name} =    BuiltIn.Should Match Regexp    ${status}    ^\\w+-\\w+
        Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl delete pods ${pod_name}
    END
    BuiltIn.Wait Until Keyword Succeeds    60s    3s    Coe.Check If Pods Are Terminated
    Coe.Check For Stale veth Ports

Check If Pods Are Terminated
    [Documentation]    Checks if the pods created have been terminated.The keyword is repeated until the pods are deleted
    ${status} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kubectl get pods -o wide    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ...    ${DEFAULT_TIMEOUT}    return_stdout=False    return_stderr=True
    BuiltIn.Should Contain    ${status}    No resources

Dump Config File
    [Documentation]    Logs the configuration files present in all nodes
    FOR    ${nodes}    IN    @{TOOLS_SYSTEM_ALL_IPS}
        Utils.Run Command On Remote System And Log    ${nodes}    cat ${CONFIG_FILE}
    END

Stop Suite
    [Documentation]    Suite teardown keyword
    Coe.Collect Watcher Log
    Coe.Collect Journalctl Log
    Coe.Stop_Watcher
    Coe.Kube_reset
    SSHLibrary.Close All Connections

Collect Watcher Log
    [Documentation]    Watcher running in background logs into watcher.out which is copied to ${JENKINS_WORKSPACE}/archives/watcher.log
    SSHLibrary.Switch Connection    ${TOOLS_SYSTEM_ALL_CONN_IDS[0]}
    SSHLibrary.Get File    /tmp/watcher.out    ${JENKINS_WORKSPACE}/archives/watcher.log

Collect Journalctl Log
    [Documentation]    Logs of the command journalctl -u kubelet is copied to ${JENKINS_WORKSPACE}/archives/journal.log
    Utils.Run Command On Remote System And Log    ${K8s_MASTER_IP}    sudo journalctl -u kubelet > ${USER_HOME}/journal.txt
    SSHLibrary.Switch Connection    ${TOOLS_SYSTEM_ALL_CONN_IDS[0]}
    SSHLibrary.Get File    ${USER_HOME}/journal.txt    ${JENKINS_WORKSPACE}/archives/journalctl.log

Stop Watcher
    [Documentation]    Kill the watcher running at the background after completion of tests cases
    ${watcher status} =    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    ps -ef | grep watcher
    ${watcher}    ${pid} =    BuiltIn.Should Match Regexp    ${watcher status}    \\w+\\s+(\\d+).*watcher odl
    Utils.Run Command On Remote System    ${K8s_MASTER_IP}    kill -9 ${pid}

Kube reset
    [Documentation]    Reset K8s to clear up all stale entries
    FOR    ${nodes}    IN    @{TOOLS_SYSTEM_ALL_IPS}
        ${kube} =    Utils.Run Command On Remote System And Log    ${nodes}    sudo kubeadm reset
        BuiltIn.Should Contain    ${kube}    Stopping the kubelet service.
    END

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
    SSHLibrary.Switch Connection    ${TOOLS_SYSTEM_ALL_CONN_IDS[0]}
    ${get pods} =    Write Commands Until Expected Prompt    kubectl get pods -o wide    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{pod ips} =    String.Get Regexp Matches    ${get pods}    \\d+\\.\\d+\\.\\d+\\.\\d+
    @{pod names} =    String.Get Regexp Matches    ${get pods}    ss\\w+-\\w+
    FOR    ${pod_name}    IN    @{pod names}
        ${logs} =    Log Statements    ${pod ips}    ${pod names}    ${pod_name}
        Ping Pods    ${pod_name}    ${pod ips}    ${logs}
    END

Log Statements
    [Arguments]    ${pod ips}    ${pod names}    ${pod_name}
    @{log statement} =    Create List
    ${i} =    Set Variable    0
    FOR    ${pod_ip}    IN    @{pod ips}
        ${ping statement}    Set Variable    Ping from ${pod_name} to ${pod names[${i}]} (${pod ip})
        Append To List    ${log statement}    ${ping statement}
        ${i} =    Evaluate    ${i}+1
    END
    [Return]    @{log statement}

Ping Pods
    [Arguments]    ${pod_name}    ${pod ips}    ${logs}
    ${i} =    Set Variable    0
    FOR    ${ping info}    IN    @{logs}
        ${ping} =    Write Commands Until Expected Prompt    kubectl exec -it ${pod_name} -- ping -c 3 ${pod ips[${i}]}    ${DEFAULT_LINUX_PROMPT_STRICT}
        BuiltIn.log    ${ping}
        BuiltIn.Should Contain    ${ping}    64 bytes
        ${i}    Evaluate    ${i}+1
    END

Coe Suite Teardown
    [Documentation]    COE project requires stop suite to be executed only for the last test suite.This keyword find the current suite,compares it with the stored last suite value and executes Coe.Stop suite only if the cuurent suite is equal to the last suite.
    ${current suite}    ${suite names updated}    Extract current suite name
    ${last_suite} =    Set Variable    ${suite names updated[-1]}
    ${status} =    BuiltIn.Evaluate    '${last_suite}' == '${current suite}'
    Run Keyword If    '${status}' == 'True'    Coe.Stop Suite

Extract current suite name
    [Documentation]    This keyword returns the name of current test suite.Appropriate replacement in text is done to make test suite names in SUITES and SUITE_NAME similar.
    BuiltIn.Log    SUITE_NAME: ${SUITE_NAME}
    BuiltIn.Log    SUITES: ${SUITES}
    @{suite_names}    Get Regexp Matches    ${SUITES}    coe\\/(\\w+).robot    1
    @{suite_names_updated}    Create List
    FOR    ${suite}    IN    @{suite_names}
        ${suite}    Replace String    ${suite}    _    ${SPACE}
        Append To List    ${suite_names_updated}    ${suite}
    END
    ${num_suites} =    BuiltIn.Get Length    ${suite_names_updated}
    ${suite line}    ${current_suite} =    BuiltIn.Run Keyword If    ${num_suites} > ${1}    Should Match Regexp    ${SUITE_NAME}    .txt.(\\w.*)
    ...    ELSE    BuiltIn.Set Variable    @{suite_names_updated}[0]    @{suite_names_updated}[0]
    [Return]    ${current_suite}    ${suite_names_updated}

Check For Stale veth Ports
    [Documentation]    Check on switches(except master) where pods were created and deleted to ensure there are no stale veth ports left behind.
    FOR    ${minion_index}    IN RANGE    2    ${NUM_TOOLS_SYSTEM}+1
        ${switch output} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_${minion_index}_IP}    sudo ovs-vsctl show
        BuiltIn.Should Not Contain    ${switch output}    veth
    END
