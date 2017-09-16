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
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Add Openstack MQ      ${OS_CONTROL_1_IP}       openstack     rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Install RabbitMQ        ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Add Openstack MQ      ${OS_CONTROL_2_IP}       openstack     rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Install RabbitMQ        ${OS_CONTROL_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Add Openstack MQ      ${OS_CONTROL_3_IP}       openstack     rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Setup RabbitMQ Cluster     ${OS_CONTROL_1_IP}       ${OS_CONTROL_2_IP}       openstack      ${OS_CONTROL_2_HOSTNAME} 
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Setup RabbitMQ Cluster     ${OS_CONTROL_1_IP}       ${OS_CONTROL_3_IP}       openstack      ${OS_CONTROL_3_HOSTNAME} 

*** Keywords ***
Install RabbitMQ
    [Arguments]    ${os_node_cxn}
    Install Rpm Package      ${os_node_cxn}      rabbitmq-server
    Enable Service      ${os_node_cxn}       rabbitmq-server
    Start Service      ${os_node_cxn}       rabbitmq-server

Add Openstack MQ
    [Arguments]    ${os_node_cxn}     ${rabbit_user}      ${rabbit_pass}
    Add Rabbitmq User     ${os_node_cxn}      ${rabbit_user}     ${rabbit_pass}
    Enable Access to Rabbitmq vhost     ${os_node_cxn}      ${rabbit_user}

Setup RabbitMQ Cluster
    [Arguments]    ${os_node_src_cxn}     ${os_node_dst_cxn}      ${rabbit_user}      ${dst_hostname}
    Stop RabbitMQ     ${os_node_src_cxn}    
    Get RabbitMQ Cookie File     ${os_node_src_cxn}
    Stop RabbitMQ     ${os_node_dst_cxn}
    Copy RabbitMQ Cookie File       ${os_node_dst_cxn}       ${rabbit_user}      ${dst_hostname}
   
