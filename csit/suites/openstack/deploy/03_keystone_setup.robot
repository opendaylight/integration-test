*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
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
Install Identity
    Create And Configure Keystone Db      ${OS_CONTROL_1_IP}     root     mysql     ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Create And Configure Keystone Db Other Nodes     ${OS_CONTROL_2_IP}     root     mysql     ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Create And Configure Keystone Db Other Nodes     ${OS_CONTROL_3_IP}     root     mysql     ${OS_CONTROL_3_HOSTNAME}
    Install Configure Keystone     ${OS_CONTROL_1_IP}      ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Install Configure Keystone     ${OS_CONTROL_2_IP}      ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Install Configure Keystone     ${OS_CONTROL_3_IP}      ${OS_CONTROL_3_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Configure HAProxy     ${HAPROXY_IP}      ${HAPROXY_IP}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Create stackrc     ${OS_CONTROL_1_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Create stackrc     ${HAPROXY_IP}
    Create Project Service

*** Keywords ***
Create And Configure Keystone Db 
    [Arguments]    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     ${host_name}
    Create Database for Mysql    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}    keystone
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     keystone.*     keystone    ${host_name}    keystone
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     keystone.*     keystone    localhost    keystone

Create And Configure Keystone Db Other Nodes
    [Arguments]    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     ${host_name}
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     keystone.*     keystone    ${host_name}      keystone
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     keystone.*     keystone    localhost     keystone

Install Configure Keystone
    [Arguments]    ${os_node_cxn}          ${host_name}
    Install Rpm Package      ${os_node_cxn}       openstack-keystone httpd mod_wsgi
    Crudini Edit      ${os_node_cxn}      /etc/keystone/keystone.conf       database     connection     "mysql+pymysql://keystone:keystone@${host_name}/keystone"
    Crudini Edit      ${os_node_cxn}      /etc/keystone/keystone.conf       token       provider     fernet
    Crudini Edit      ${os_node_cxn}      /etc/keystone/keystone.conf       catalog     driver     sql
    Crudini Edit      ${os_node_cxn}      /etc/keystone/keystone.conf       identity    driver     sql
    Run Command As User     ${os_node_cxn}      "keystone-manage db_sync"    keystone
    Keystone Manage Setup      ${os_node_cxn}    keystone     keystone
    Keystone Manage Bootstrap    ${os_node_cxn}   ${host_name}     RegionOne
    Append To File     ${os_node_cxn}     /etc/httpd/conf/httpd.conf      "ServerName ${host_name}"
    Create Softlink    ${os_node_cxn}     /usr/share/keystone/wsgi-keystone.conf      /etc/httpd/conf.d/
    Enable Service     ${os_node_cxn}     httpd
    Start Service     ${os_node_cxn}     httpd

Configure HAProxy
    [Arguments]    ${os_node_cxn}          ${haproxy_ip}
    Generic HAProxy Entry      ${os_node_cxn}     ${haproxy_ip}     35357     keystone_admin_cluster
    Generic HAProxy Entry      ${os_node_cxn}     ${haproxy_ip}     5000      public_internal_cluster
    
Create stackrc
    [Arguments]    ${haproxy_ip}
    Create Local File     /tmp/stackrc
    Append To Local File    /tmp/stackrc    "export OS_USERNAME=admin"
    Append To Local File    /tmp/stackrc    "export OS_PASSWORD=admin"
    Append To Local File    /tmp/stackrc    "export OS_PROJECT_NAME=admin"
    Append To Local File    /tmp/stackrc    "export OS_USER_DOMAIN_NAME=Default"
    Append To Local File    /tmp/stackrc    "export OS_PROJECT_DOMAIN_NAME=Default"
    Append To Local File    /tmp/stackrc    "export OS_AUTH_URL=http://${haproxy_ip}:35357/v3"
    Append To Local File    /tmp/stackrc    "export OS_IDENTITY_API_VERSION=3"
    Append To Local File    /tmp/stackrc    "export OS_IMAGE_API_VERSION=2"

Create Project Service
    Source Local File     /tmp/stackrc
    Create Project     default     "ServiceProject"    service
