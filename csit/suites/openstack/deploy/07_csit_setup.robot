*** Settings ***
Documentation     Suite that configures the nodes to execute CSIT
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackInstallUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SystemUtils.robot
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
Create Jenkins User
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Create Csit User       ${OS_CONTROL_1_IP}      jenkins
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Create Csit User       ${OS_CONTROL_1_IP}      jenkins
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Create Csit User       ${OS_CONTROL_2_IP}      jenkins
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Create Csit User       ${OS_CONTROL_3_IP}      jenkins
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Create Csit User       ${HAPROXY_IP}      jenkins
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}      Create Csit User       ${OS_COMPUTE_1_IP}      jenkins
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}      Create Csit User       ${OS_COMPUTE_2_IP}      jenkins

Create Required Image and Flavor
    Run Command    127.0.0.1     export http_proxy=${PROXY_TEST};wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img -O /tmp/cirros35.img;unset http_proxy
    Run Command    127.0.0.1     export https_proxy=${PROXY_TEST};wget https://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img -O /tmp/cirros35.img;unset https_proxy
    Create Image   cirros     /tmp/cirros35.img     rc_file=/tmp/stackrc
    Create Image   cirros-0.3.5-x86_64-disk     /tmp/cirros35.img     rc_file=/tmp/stackrc
    Create Flavor    cirros    128    0     rc_file=/tmp/stackrc
    Create Flavor    m1.nano   128    0     rc_file=/tmp/stackrc

*** Keywords ***
Set Password 
    [Arguments]    ${os_node_cxn}     ${user_name}
    Switch Connection     ${os_node_cxn}
    Write Commands Until Expected Prompt     sudo passwd ${user_name}      d:     30s
    Write Commands Until Expected Prompt     ${user_name}      d:     30s
    Write Commands Until Expected Prompt     ${user_name}      ${OS_NODE_PROMPT}     30s

Set Required Prompt
    [Arguments]    ${os_node_cxn}     ${user_name}
    Append To File     ${os_node_cxn}     /home/${user_name}/.bashrc        'PS1="[\\u@\\h \\W]>"'
    
Create Csit User
    [Arguments]    ${os_node_cxn}     ${user_name}
    Run Command     ${os_node_cxn}     sudo useradd ${user_name} -d /home/${user_name}
    Run Command     ${os_node_cxn}     echo "${user_name} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${user_name}
    Set Password    ${os_node_cxn}     ${user_name}
    Set Required Prompt     ${os_node_cxn}     ${user_name}
    Setup Passwordless Ssh      127.0.0.1     jenkins       ${os_node_cxn}

Setup Passwordless Ssh
    [Arguments]    ${os_node_cxn}     ${user_name}      ${node_ip}
    Switch Connection     ${os_node_cxn}
    Write Commands Until Expected Prompt     ssh-copy-id ${user_name}@${node_ip} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null     word:     30s
    Write Commands Until Expected Prompt     ${user_name}      ${OS_NODE_PROMPT}     30s
