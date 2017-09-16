*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackInstallUtils.robot
Resource          ../../../libraries/SystemUtils.robot
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
Setup RabbitMQ
    Run Keyword If    2 > ${NUM_CONTROL_NODES}       Install RabbitMQ        ${OS_CONTROL_1_IP}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}       Add Openstack MQ      ${OS_CONTROL_1_IP}       openstack     rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Install RabbitMQ        ${OS_CONTROL_1_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Start Stop And Copy Cookie File     ${OS_CONTROL_1_IP}      rabbit    rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Install RabbitMQ        ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Install RabbitMQ        ${OS_CONTROL_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Setup RabbitMQ Cluster     ${OS_CONTROL_2_IP}       rabbit     ${OS_CONTROL_1_HOSTNAME} 
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Setup RabbitMQ Cluster     ${OS_CONTROL_3_IP}       rabbit     ${OS_CONTROL_1_HOSTNAME} 
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Add HAProxy        ${HAPROXY_IP}    ${HAPROXY_IP}

*** Keywords ***
Install RabbitMQ
    [Arguments]    ${os_node_cxn}
    Install Rpm Package      ${os_node_cxn}      rabbitmq-server
    Enable Service      ${os_node_cxn}       rabbitmq-server

Start Stop And Copy Cookie File
    [Arguments]    ${os_node_cxn}     ${rabbit_user}      ${rabbit_pass}
    Start Service      ${os_node_cxn}       rabbitmq-server
    Add Openstack MQ     ${os_node_cxn}     openstack     rabbit
    Get RabbitMQ Cookie File     ${os_node_cxn}

Add Openstack MQ
    [Arguments]    ${os_node_cxn}     ${rabbit_user}      ${rabbit_pass}
    Add Rabbitmq User     ${os_node_cxn}      ${rabbit_user}     ${rabbit_pass}
    Enable Access to Rabbitmq vhost     ${os_node_cxn}      ${rabbit_user}

Setup RabbitMQ Cluster
    [Arguments]    ${os_node_cxn}     ${rabbit_user}      ${src_hostname}
    Copy RabbitMQ Cookie File       ${os_node_cxn}       ${rabbit_user}      ${src_hostname}

Add HAProxy 
    [Arguments]    ${os_node_cxn}     ${bind_ip}
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     $'\n'frontend rabbitmq-frontend 
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     " ${bind_ip}:5672"
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     " timeout 900m"
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     " default_backend rabbitmq-vms"
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     $'\n'backend rabbitmq-vms
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     " balance roundrobin"
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     " timeout server 900m"
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     " server rabbitmq-vm1 ${OS_CONTROL_1_IP}:5672 check inter 1s"
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     " server rabbitmq-vm2 ${OS_CONTROL_2_IP}:5672 check inter 1s"
    Append To File      ${os_node_cxn}     /etc/haproxy/haproxy.cfg     " server rabbitmq-vm3 ${OS_CONTROL_3_IP}:5672 check inter 1s"
    Retart Service     ${os_node_cxn}      haproxy
