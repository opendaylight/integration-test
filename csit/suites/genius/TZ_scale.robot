*** Settings ***
Documentation     Test Suite for IdManager
#Suite Setup       Start Ovs Containers
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
Dumb Test0
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    timeout=20s
    SSHKeywords.Flexible_Controller_Login
    ${ss}=      SSHLibrary.Execute Command    netstat -pltn
    Log     ${ss}
    SSHLibrary.Execute Command      sudo yum install -y nc
    SSHLibrary.Execute Command      echo faham | nc ${ODL_SYSTEM_IP} 6653

Dumb Test1
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    timeout=20s
    SSHKeywords.Flexible_Controller_Login
    SSHLibrary.Execute Command    sudo setenforce 0
    ${log}=     SSHLibrary.Execute Command    sudo modinfo openvswitch
    Log    ${log}
    ${log}=     SSHLibrary.Execute Command    sudo yum install -y openvswitch
    Log    ${log}
    ${log}=     SSHLibrary.Execute Command    sudo modinfo openvswitch
    Log    ${log}

    SSHLibrary.Execute Command    docker pull jhershbe/centos7-ovs-multimode    timeout=300s

    : FOR    ${count}    IN RANGE     1     10
    \    SSHLibrary.Execute Command    sudo docker run --name container${count} -e MODE=none -itd --cap-add ALL jhershbe/centos7-ovs-multimode

    BuiltIn.Sleep   15s

    : FOR    ${count}    IN RANGE     1     10
    \    ${l}=      SSHLibrary.Execute Command    sudo docker exec container${count} modprobe openvswitch
    \    Log    ${l}
    \    SSHLibrary.Execute Command    sudo docker exec container${count} ovs-vsctl del-br br-int
    \    SSHLibrary.Execute Command    sudo docker exec container${count} ovs-vsctl add-br br-int
    \    SSHLibrary.Execute Command    sudo docker exec container${count} ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    \    SSHLibrary.Execute Command    sudo docker exec container${count} ovs-vsctl set-controller br-int tcp:${ODL_SYSTEM_IP}:6653

    BuiltIn.Sleep   15s
    : FOR    ${count}    IN RANGE     1     10
    \    ${out}=    SSHLibrary.Execute Command    docker exec container${count} ovs-vsctl show
    \    Log    ${out}
    \    ${logfile}=    SSHLibrary.Execute Command    docker exec container${count} bash -c "ls -1 /var/log/supervisor/ovs-vswitchd-stderr*"
    \    ${out}=        SSHLibrary.Execute Command    docker exec container${count} tail -n 100 ${logfile}
    \    Log    ${out}
    \    ${log}=     SSHLibrary.Execute Command    docker exec container${count} bash -c "lsmod"
    \    Log    ${out}

    SSHLibrary.Execute Command      sudo yum install -y nc
    SSHLibrary.Execute Command      echo faham | nc ${ODL_SYSTEM_IP} 6653

    Should Be Equal As Strings    ${TOOLS_SYSTEM_IP}    200

Dumb Test2
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    timeout=20s
    SSHKeywords.Flexible_Controller_Login
    ${ss}=      SSHLibrary.Execute Command    netstat -pltn
    Log     ${ss}

*** Keywords ***
#Start Ovs Containers
#    [Documentation]    Pull the image, start instances
#    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    timeout=20s
#    SSHKeywords.Flexible_Controller_Login
#    SSHLibrary.Execute Command    docker pull jhershbe/centos7-ovs-multimode    timeout=300s

