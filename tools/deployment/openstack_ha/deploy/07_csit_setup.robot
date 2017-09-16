*** Settings ***
Documentation     Suite that configures the nodes to execute CSIT
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../csit/libraries/OpenStackInstallUtils.robot
Resource          ../../../../csit/libraries/OpenStackOperations.robot
Resource          ../../../../csit/libraries/SystemUtils.robot
Resource          ../../../../csit/libraries/Utils.robot

*** Test Cases ***
Create Jenkins User
    #Generate Ssh Keys For VMs
    #Local Install Rpm Package    sshpass
    #Create Keypair    vm_keys    /tmp/vm_key    rc_file=/tmp/stackrc
    #Run Keyword If    2 > ${NUM_CONTROL_NODES}    Create Csit User    ${OS_CONTROL_1_IP}    jenkins
    #Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create Csit User    ${OS_CONTROL_1_IP}    jenkins
    #Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create Csit User    ${OS_CONTROL_2_IP}    jenkins
    #Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create Csit User    ${OS_CONTROL_3_IP}    jenkins
    #Run Keyword If    3 < ${NUM_CONTROL_NODES}    Create Csit User    ${OS_CONTROL_4_IP}    jenkins
    #Run Keyword If    4 < ${NUM_CONTROL_NODES}    Create Csit User    ${OS_CONTROL_5_IP}    jenkins
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Create Csit User    ${OS_COMPUTE_1_IP}    jenkins
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Create Csit User    ${OS_COMPUTE_2_IP}    jenkins

Create Required Image and Flavor
    Run Command In Local Node    export https_proxy=${PROXY_TEST};wget https://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img -O /tmp/cirros35.img;unset https_proxy
    Create Image    cirros    /tmp/cirros35.img    rc_file=/tmp/stackrc
    Create Image    cirros-0.3.5-x86_64-disk    /tmp/cirros35.img    rc_file=/tmp/stackrc
    Create Flavor    cirros    128    0    rc_file=/tmp/stackrc
    Create Flavor    m1.nano    128    0    rc_file=/tmp/stackrc
    Run Command In Local Node    export https_proxy=${PROXY_TEST};export http_proxy=${PROXY_TEST};wget "https://download.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2" -O /tmp/fedora.qcow2;unset https_proxy;unset http_proxy
    Create Image    fedora    /tmp/fedora.qcow2    rc_file=/tmp/stackrc
    Create Flavor    fedora    2048    6    rc_file=/tmp/stackrc
    Install Rpm Package    ${OS_CONTROL_1_IP}    wget
    Download Scapy For Test    ${OS_CONTROL_1_IP}

*** Keywords ***
Set Password
    [Arguments]    ${os_node_cxn}    ${user_name}
    Switch Connection    ${os_node_cxn}
    Write Commands Until Expected Prompt    sudo passwd ${user_name}    d:    30s
    Write Commands Until Expected Prompt    ${user_name}    d:    30s
    Write Commands Until Expected Prompt    ${user_name}    ${OS_NODE_PROMPT}    30s

Set Required Prompt
    [Arguments]    ${os_node_cxn}    ${user_name}
    Append To File    ${os_node_cxn}    /home/${user_name}/.bashrc    'PS1="[\\u@\\h \\W]>"'

Create Csit User
    [Arguments]    ${os_node_cxn}    ${user_name}
    Run Command    ${os_node_cxn}    sudo useradd ${user_name} -d /home/${user_name}
    Run Command    ${os_node_cxn}    echo "${user_name} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${user_name}
    Set Password    ${os_node_cxn}    ${user_name}
    Set Required Prompt    ${os_node_cxn}    ${user_name}
    Setup Passwordless Ssh    jenkins    ${os_node_cxn}

Setup Passwordless Ssh
    [Arguments]    ${user_name}    ${node_ip}
    Run Command In Local Node    sshpass -p ${user_name} ssh-copy-id ${user_name}@${node_ip} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
    Run Command In Local Node    scp /tmp/vm_key ${user_name}@${node_ip}:~
    Run Command In Local Node    scp /tmp/vm_key.pub ${user_name}@${node_ip}:~

Generate Ssh Keys For Vms
    Run Command In Local Node    ssh-keygen -t rsa -N "" -f /tmp/vm_key

Download Scapy For Test
    [Arguments]    ${os_node_cxn}
    Run Command    ${os_node_cxn}    export https_proxy=${PROXY_TEST};export http_proxy=${PROXY_TEST};wget scapy.net -O /tmp/scapy-master.zip;unset https_proxy;unset http_proxy
    Install Rpm Package    ${os_node_cxn}    unzip
    Run Command    ${os_node_cxn}    cd /tmp;unzip /tmp/scapy-master.zip
