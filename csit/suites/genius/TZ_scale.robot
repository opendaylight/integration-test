*** Settings ***
Documentation     Test Suite for IdManager
Suite Setup       Start Ovs Containers
#Suite Teardown    Delete All Sessions
#Test Teardown     Get Model Dump    ${ODL_SYSTEM_IP}    ${idmanager_data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/Genius.robot
Resource          ../../variables/Variables.robot

*** Variables ***
${NUM_NODES}        30

*** Test Cases ***
Test Nodes Get Teps

    : FOR    ${count}    IN RANGE     0     ${NUM_NODES}
    \    SSHLibrary.Execute Command    sudo docker exec container${count} ovs-vsctl -- set-manager tcp:${ODL_SYSTEM_IP}:6640 -- set-controller br-int tcp:${ODL_SYSTEM_IP}:6653
    BuiltIn.Sleep   1s

    BuiltIn.Sleep   60s
    ${expected_teps}=   Evaluate    ${NUM_NODES} - 1
    : FOR    ${count}    IN RANGE     0     ${NUM_NODES}
    \    ${show}=    SSHLibrary.Execute Command    docker exec container${count} ip a
    \    Log    ${show}
    \    ${show}=    SSHLibrary.Execute Command    docker exec container${count} ovs-ofctl show br-int
    \    Log    ${show}
    \    ${show}=    SSHLibrary.Execute Command    docker exec container${count} ovs-vsctl show
    \    Log    ${show}
    \    ${tuns}=       String.Get Lines Containing String     ${show}      Port "tun
    \    Log    ${tuns}
    \    ${num_teps}=   String.Get Line Count      ${tuns}
    \    Run Keyword And Continue On Failure        Should Be Equal      ${num_teps}     ${expected_teps}             Node did not receive all TEPs
    ${topo}=    OperatingSystem.Run     curl -u admin:admin http://${ODL_SYSTEM_IP}:8181/restconf/config/network-topology:network-topology
    Log     ${topo}

*** Keywords ***
Start Ovs Containers
    [Documentation]    Pull the image, start instances
    ${conn_id_1}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${conn_id_1}
    KarafKeywords.Setup_Karaf_Keywords
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius

    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    timeout=20s
    SSHKeywords.Flexible_Controller_Login
    SSHLibrary.Execute Command    sudo setenforce 0
    SSHLibrary.Execute Command    sudo modprobe openvswitch
    SSHLibrary.Execute Command    docker pull jhershbe/centos7-ovs-multimode    timeout=300s

    Log     ${NUM_NODES}
    : FOR    ${count}    IN RANGE     0     ${NUM_NODES}
    \    SSHLibrary.Execute Command    sudo docker run --name container${count} -e MODE=none -itd --cap-add ALL jhershbe/centos7-ovs-multimode

    BuiltIn.Sleep   15s

