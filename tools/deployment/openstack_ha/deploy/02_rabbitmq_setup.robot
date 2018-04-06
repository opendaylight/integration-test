*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../libraries/OpenStackInstallUtils.robot
Resource          ../libraries/SystemUtils.robot
Resource          ../libraries/Utils.robot

*** Test Cases ***
Setup RabbitMQ
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Install RabbitMQ    ${OS_CONTROL_1_IP}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Start RabbitMQ    ${OS_CONTROL_1_IP}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Add Openstack MQ    ${OS_CONTROL_1_IP}    openstack    rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install RabbitMQ    ${OS_CONTROL_1_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Start Stop And Copy Cookie File    ${OS_CONTROL_1_IP}    rabbit    rabbit
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install RabbitMQ    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install RabbitMQ    ${OS_CONTROL_3_IP}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Install RabbitMQ    ${OS_CONTROL_4_IP}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Install RabbitMQ    ${OS_CONTROL_5_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup RabbitMQ Cluster    ${OS_CONTROL_2_IP}    rabbit    ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup RabbitMQ Cluster    ${OS_CONTROL_3_IP}    rabbit    ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Setup RabbitMQ Cluster    ${OS_CONTROL_4_IP}    rabbit    ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Setup RabbitMQ Cluster    ${OS_CONTROL_5_IP}    rabbit    ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    5672    rabbitmq

*** Keywords ***
Install RabbitMQ
    [Arguments]    ${os_node_cxn}
    Run Keyword If    '${OS_APPS_PRE_INSTALLED}' == 'no'    Install Rpm Package    ${os_node_cxn}    rabbitmq-server
    Enable Service    ${os_node_cxn}    rabbitmq-server

Start RabbitMQ
    [Arguments]    ${os_node_cxn}
    Enable Service    ${os_node_cxn}    rabbitmq-server
    Start Service    ${os_node_cxn}    rabbitmq-server

Start Stop And Copy Cookie File
    [Arguments]    ${os_node_cxn}    ${rabbit_user}    ${rabbit_pass}
    Enable Service    ${os_node_cxn}    rabbitmq-server
    Start Service    ${os_node_cxn}    rabbitmq-server
    Add Openstack MQ    ${os_node_cxn}    openstack    rabbit
    Get RabbitMQ Cookie File    ${os_node_cxn}

Add Openstack MQ
    [Arguments]    ${os_node_cxn}    ${rabbit_user}    ${rabbit_pass}
    Add Rabbitmq User    ${os_node_cxn}    ${rabbit_user}    ${rabbit_pass}
    Enable Access to Rabbitmq vhost    ${os_node_cxn}    ${rabbit_user}

Setup RabbitMQ Cluster
    [Arguments]    ${os_node_cxn}    ${rabbit_user}    ${src_hostname}
    Copy RabbitMQ Cookie File    ${os_node_cxn}    ${rabbit_user}    ${src_hostname}

Add Rabbitmq User
    [Arguments]    ${os_node_cxn}    ${rabbit_user}    ${rabbit_pass}
    [Documentation]    Add a user to Rabbit MQ
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl add_user ${rabbit_user} ${rabbit_pass}    return_rc=True    return_stdout=True
    Log    ${output}
    #Should Not Be True    ${rc}
    [Return]    ${output}

Change Rabbitmq Password
    [Arguments]    ${os_node_cxn}    ${rabbit_user}    ${rabbit_pass}
    [Documentation]    Add a user to Rabbit MQ
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl change_password ${rabbit_user} ${rabbit_pass}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Enable Access to Rabbitmq vhost
    [Arguments]    ${os_node_cxn}    ${rabbit_user}
    [Documentation]    Add a user to Rabbit MQ
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl set_permissions ${rabbit_user} ".*" ".*" ".*"    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop RabbitMQ
    [Arguments]    ${os_node_cxn}
    [Documentation]    Stop the RabbitMQ user
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl stop_app    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Get RabbitMQ Cookie File
    [Arguments]    ${os_node_cxn}
    [Documentation]    Get the Cookie file from the primary node
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl stop_app    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    SSHLibrary.Get File    /var/lib/rabbitmq/.erlang.cookie    /tmp/
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl start_app    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl cluster_status    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Copy RabbitMQ Cookie File
    [Arguments]    ${os_node_cxn}    ${rabbit_user}    ${src_hostname}
    [Documentation]    Copy the rabbit cookie file to other servers to join the cluster
    Switch Connection    ${os_node_cxn}
    SSHLibrary.Put File    /tmp/.erlang.cookie    /var/lib/rabbitmq/.erlang.cookie
    ${output}    ${rc}=    Execute Command    sudo chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    sudo chmod 400 /var/lib/rabbitmq/.erlang.cookie    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    Enable Service    ${os_node_cxn}    rabbitmq-server
    Start Service    ${os_node_cxn}    rabbitmq-server
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl stop_app    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl join_cluster --ram ${rabbit_user}@${src_hostname}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl start_app    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl cluster_status    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    Run Command    ${os_node_cxn}    sudo rabbitmqctl set_policy ha-all '^(?!amq\.).*' '{"ha-mode": "all"}'
