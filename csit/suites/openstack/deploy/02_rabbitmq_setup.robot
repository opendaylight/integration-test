*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SystemUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Test Cases ***
Open All SSH Connections For Install
    [Documentation]    Open All SSH Connections.
    ${control_1}=    Run Keyword If    0 < ${NUM_CONTROL_NODES}    Get Ssh Connection    ${CONTROL1_NODE_IP}    ${CONTROL1_NODE_USER}    ${CONTROL1_NODE_PASS}
    ...    ${CONTROL1_NODE_PROMPT}
    Set Suite Variable    ${control_1}
    ${control_2}=    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Get Ssh Connection    ${CONTROL2_NODE_IP}    ${CONTROL2_NODE_USER}    ${CONTROL2_NODE_PASS}
    ...    ${CONTROL2_NODE_PROMPT}
    Set Suite Variable    ${control_2}
    ${control_3}=    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Get Ssh Connection    ${CONTROL3_NODE_IP}    ${CONTROL3_NODE_USER}    ${CONTROL3_NODE_PASS}
    ...    ${CONTROL3_NODE_PROMPT}
    Set Suite Variable    ${control_3}
    ${haproxy}=    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Get Ssh Connection    ${HAPROXY_NODE_IP}    ${HAPROXY_NODE_USER}    ${HAPROXY_NODE_PASS}
    ...    ${HAPROXY_NODE_PROMPT}
    Set Suite Variable    ${haproxy}
    ${compute_1}=    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Get Ssh Connection    ${COMPUTE1_NODE_IP}    ${COMPUTE1_NODE_USER}    ${COMPUTE1_NODE_PASS}
    ...    ${COMPUTE1_NODE_PROMPT}
    Set Suite Variable    ${compute_1}
    ${compute_2}=    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Get Ssh Connection    ${COMPUTE2_NODE_IP}    ${COMPUTE2_NODE_USER}    ${COMPUTE2_NODE_PASS}
    ...    ${COMPUTE2_NODE_PROMPT}
    Set Suite Variable    ${compute_2}


Setup RabbitMQ
    Run Keyword If    2 > ${NUM_CONTROL_NODES}       Install RabbitMQ        ${CONTROL1_NODE_IP}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}       Add Openstack MQ      ${CONTROL1_NODE_IP}       openstack     rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Install RabbitMQ        ${CONTROL1_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Add Openstack MQ      ${CONTROL1_NODE_IP}       openstack     rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Install RabbitMQ        ${CONTROL2_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Install RabbitMQ        ${CONTROL3_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Setup RabbitMQ Cluster     ${CONTROL1_NODE_IP}       ${CONTROL2_NODE_IP}       openstack      ${CONTROL2_HOST_NAME} 
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Setup RabbitMQ Cluster     ${CONTROL1_NODE_IP}       ${CONTROL3_NODE_IP}       openstack      ${CONTROL3_HOST_NAME} 
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
   
