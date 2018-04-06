*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../libraries/OpenStackInstallUtils.robot
Resource          ../libraries/OpenStackOperations.robot
Resource          ../libraries/SystemUtils.robot
Resource          ../libraries/Utils.robot

*** Test Cases ***
Install Identity
    Create And Configure Keystone Db    ${OS_CONTROL_1_IP}    root    mysql    ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create And Configure Keystone Db Other Nodes    ${OS_CONTROL_2_IP}    root    mysql    ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create And Configure Keystone Db Other Nodes    ${OS_CONTROL_3_IP}    root    mysql    ${OS_CONTROL_3_HOSTNAME}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Create And Configure Keystone Db Other Nodes    ${OS_CONTROL_4_IP}    root    mysql    ${OS_CONTROL_4_HOSTNAME}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Create And Configure Keystone Db Other Nodes    ${OS_CONTROL_5_IP}    root    mysql    ${OS_CONTROL_5_HOSTNAME}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Install Configure Keystone    ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Configure Keystone    ${OS_CONTROL_1_IP}    ${HAPROXY_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Configure Keystone    ${OS_CONTROL_2_IP}    ${HAPROXY_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Configure Keystone    ${OS_CONTROL_3_IP}    ${HAPROXY_HOSTNAME}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Install Configure Keystone    ${OS_CONTROL_4_IP}    ${HAPROXY_HOSTNAME}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Install Configure Keystone    ${OS_CONTROL_5_IP}    ${HAPROXY_HOSTNAME}
    ${token}=    Run Command    ${OS_CONTROL_1_IP}    openssl rand -hex 10
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Set Admin Token    ${OS_CONTROL_1_IP}    ${token}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Set Admin Token    ${OS_CONTROL_2_IP}    ${token}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Set Admin Token    ${OS_CONTROL_3_IP}    ${token}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Set Admin Token    ${OS_CONTROL_4_IP}    ${token}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Set Admin Token    ${OS_CONTROL_5_IP}    ${token}
    Keystone Manage Setup    ${OS_CONTROL_1_IP}    keystone    keystone
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Copy Fernet Keys    ${OS_CONTROL_1_IP}    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Copy Fernet Keys    ${OS_CONTROL_1_IP}    ${OS_CONTROL_3_IP}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Copy Fernet Keys    ${OS_CONTROL_1_IP}    ${OS_CONTROL_4_IP}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Copy Fernet Keys    ${OS_CONTROL_1_IP}    ${OS_CONTROL_5_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Chown File    ${OS_CONTROL_2_IP}    /etc/keystone/fernet-keys    keystone    keystone
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Chown File    ${OS_CONTROL_3_IP}    /etc/keystone/fernet-keys    keystone    keystone
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Chown File    ${OS_CONTROL_4_IP}    /etc/keystone/fernet-keys    keystone    keystone
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Chown File    ${OS_CONTROL_5_IP}    /etc/keystone/fernet-keys    keystone    keystone
    Start Keystone    ${OS_CONTROL_1_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Start Keystone    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Start Keystone    ${OS_CONTROL_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    35357    keystone-admin
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    5000    keystone-public
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Create stackrc    ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create stackrc    ${HAPROXY_HOSTNAME}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Setup And Bootstrap    ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup And Bootstrap    ${OS_CONTROL_1_IP}    ${HAPROXY_HOSTNAME}
    Create Project Service

*** Keywords ***
Create And Configure Keystone Db
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${host_name}
    Create Database for Mysql    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    keystone
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    keystone.*    keystone    ${host_name}
    ...    keystone
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    keystone.*    keystone    localhost
    ...    keystone
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    keystone.*
    ...    keystone    ${HAPROXY_HOSTNAME}    keystone

Create And Configure Keystone Db Other Nodes
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${host_name}
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    keystone.*    keystone    ${host_name}
    ...    keystone
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    keystone.*    keystone    localhost
    ...    keystone
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    keystone.*    keystone    ${HAPROXY_HOSTNAME}
    ...    keystone

Install Configure Keystone
    [Arguments]    ${os_node_cxn}    ${host_name}
    Run Keyword If    '${OS_APPS_PRE_INSTALLED}' == 'no'    Install Rpm Package    ${os_node_cxn}    openstack-keystone httpd mod_wsgi rsync
    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    database    connection    "mysql+pymysql://keystone:keystone@${host_name}/keystone"
    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    token    provider    fernet
    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    catalog    driver    sql
    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    identity    driver    sql
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    DEFAULT    transport_url
    ...    "rabbit://openstack:rabbit@${OS_CONTROL_1_HOSTNAME},openstack:rabbit@${OS_CONTROL_2_HOSTNAME},openstack:rabbit@${OS_CONTROL_3_HOSTNAME}"
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    DEFAULT    transport_url
    ...    "rabbit://openstack:rabbit@${host_name}"
    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    oslo_messaging_rabbit    rabbit_max_retries    0
    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    oslo_messaging_rabbit    rabbit_ha_queues    true
    Create Softlink    ${os_node_cxn}    /usr/share/keystone/wsgi-keystone.conf    /etc/httpd/conf.d/

Start Keystone
    [Arguments]    ${os_node_cxn}
    Enable Service    ${os_node_cxn}    httpd
    Start Service    ${os_node_cxn}    httpd
    [Teardown]    Collect httpd logs for Debug     ${os_node_cxn}

Collect httpd logs for Debug
    [Arguments]    ${os_node_cxn}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo systemctl status httpd -l    return_rc=True    return_stdout=True
    ${output}    ${rc}=    Execute Command    sudo cat /var/log/httpd/httpd.log    return_rc=True    return_stdout=True
    ${output}    ${rc}=    Execute Command    sudo cat /var/log/keystone/keystone.log    return_rc=True    return_stdout=True

Set Admin Token
    [Arguments]    ${os_node_cxn}    ${token}
    Crudini Edit    ${os_node_cxn}    /etc/keystone/keystone.conf    DEFAULT    admin_token    ${token}

Copy Fernet Keys
    [Arguments]    ${os_node_cxn}    ${target_ip}
    Rsync Directory    ${os_node_cxn}    ${target_ip}    /etc/keystone/fernet-keys    /etc/keystone

Setup And Bootstrap
    [Arguments]    ${os_node_cxn}    ${host_name}
    Run Command As User    ${os_node_cxn}    "keystone-manage db_sync"    keystone
    Keystone Manage Bootstrap    ${os_node_cxn}    ${host_name}    RegionOne

Create stackrc
    [Arguments]    ${haproxy_ip}
    Create Local File    /tmp/stackrc
    Write To Local File    /tmp/stackrc    "export OS_USERNAME=admin"
    Append To Local File    /tmp/stackrc    "export OS_PASSWORD=admin"
    Append To Local File    /tmp/stackrc    "export OS_PROJECT_NAME=admin"
    Append To Local File    /tmp/stackrc    "export OS_USER_DOMAIN_NAME=Default"
    Append To Local File    /tmp/stackrc    "export OS_PROJECT_DOMAIN_NAME=Default"
    Append To Local File    /tmp/stackrc    "export OS_AUTH_URL=http://${haproxy_ip}:35357/v3"
    Append To Local File    /tmp/stackrc    "export OS_IDENTITY_API_VERSION=3"
    Append To Local File    /tmp/stackrc    "export OS_IMAGE_API_VERSION=2"
    Append To Local File    /tmp/stackrc    "unset OS_CLOUD"

Create Project Service
    Create Project    default    "ServiceProject"    service    rc_file=/tmp/stackrc

Keystone Manage Setup
    [Arguments]    ${os_node_cxn}    ${keystone_user}    ${keystone_password}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo keystone-manage fernet_setup --keystone-user ${keystone_user} --keystone-group ${keystone_password}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Keystone Manage Bootstrap
    [Arguments]    ${os_node_cxn}    ${host_name}    ${region_name}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo keystone-manage bootstrap --bootstrap-password admin --bootstrap-admin-url http://${host_name}:35357/v3/ --bootstrap-internal-url http://${host_name}:5000/v3/ --bootstrap-public-url http://${host_name}:5000/v3/ --bootstrap-region-id ${region_name}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
