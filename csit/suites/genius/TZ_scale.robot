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

*** Test Cases ***
Test Nodes Get Teps

    : FOR    ${count}    IN RANGE     1     10
    \    SSHLibrary.Execute Command    sudo docker exec container${count} ovs-vsctl -- set-manager tcp:${ODL_SYSTEM_IP}:6640 -- set-controller br-int tcp:${ODL_SYSTEM_IP}:6653

    BuiltIn.Sleep   15s
    : FOR    ${count}    IN RANGE     1     10
    \    ${show}=    SSHLibrary.Execute Command    docker exec container${count} ovs-vsctl show
    \    Log    ${show}
    \    ${tuns}=       String.Get Lines Containing String     ${show}      "Port \"tun"
    \    Log    ${tuns}

*** Keywords ***
Start Ovs Containers
    [Documentation]    Pull the image, start instances
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    timeout=20s
    SSHKeywords.Flexible_Controller_Login
    SSHLibrary.Execute Command    sudo setenforce 0
    SSHLibrary.Execute Command    sudo modprobe openvswitch
    SSHLibrary.Execute Command    docker pull jhershbe/centos7-ovs-multimode    timeout=300s

    : FOR    ${count}    IN RANGE     1     10
    \    SSHLibrary.Execute Command    sudo docker run --name container${count} -e MODE=none -itd --cap-add ALL jhershbe/centos7-ovs-multimode

    BuiltIn.Sleep   15s

