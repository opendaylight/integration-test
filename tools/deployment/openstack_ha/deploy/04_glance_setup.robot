*** Settings ***
Documentation       Test suite to verify packet flows between vm instances.

Library             SSHLibrary
Library             OperatingSystem
Library             RequestsLibrary
Resource            ../libraries/OpenStackInstallUtils.robot
Resource            ../libraries/OpenStackOperations.robot
Resource            ../libraries/SystemUtils.robot
Resource            ../libraries/Utils.robot

Suite Setup         OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown      Close All Connections


*** Test Cases ***
Install Glance
    Create And Configure Glance Db    ${OS_CONTROL_1_IP}    root    mysql    ${OS_CONTROL_1_HOSTNAME}
    IF    2 < ${NUM_CONTROL_NODES}
        Create And Configure Glance Db Other Nodes    ${OS_CONTROL_2_IP}    root    mysql    ${OS_CONTROL_2_HOSTNAME}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Create And Configure Glance Db Other Nodes    ${OS_CONTROL_3_IP}    root    mysql    ${OS_CONTROL_3_HOSTNAME}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Create And Configure Glance Db Other Nodes    ${OS_CONTROL_4_IP}    root    mysql    ${OS_CONTROL_4_HOSTNAME}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Create And Configure Glance Db Other Nodes    ${OS_CONTROL_5_IP}    root    mysql    ${OS_CONTROL_5_HOSTNAME}
    END
    IF    2 > ${NUM_CONTROL_NODES}
        Create Openstack Elements    ${OS_CONTROL_1_HOSTNAME}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Create Openstack Elements    ${HAPROXY_HOSTNAME}
    END
    IF    2 > ${NUM_CONTROL_NODES}
        Install Configure Glance    ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_HOSTNAME}
    END
    IF    2 > ${NUM_CONTROL_NODES}    Start Glance    ${OS_CONTROL_1_IP}
    IF    2 < ${NUM_CONTROL_NODES}
        Install Configure Glance    ${OS_CONTROL_1_IP}    ${HAPROXY_HOSTNAME}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Configure Glance    ${OS_CONTROL_2_IP}    ${HAPROXY_HOSTNAME}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Configure Glance    ${OS_CONTROL_3_IP}    ${HAPROXY_HOSTNAME}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Install Configure Glance    ${OS_CONTROL_4_IP}    ${HAPROXY_HOSTNAME}
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Install Configure Glance    ${OS_CONTROL_5_IP}    ${HAPROXY_HOSTNAME}
    END
    IF    2 < ${NUM_CONTROL_NODES}    Start Glance    ${OS_CONTROL_1_IP}
    IF    2 < ${NUM_CONTROL_NODES}    Start Glance    ${OS_CONTROL_2_IP}
    IF    2 < ${NUM_CONTROL_NODES}    Start Glance    ${OS_CONTROL_3_IP}
    IF    2 < ${NUM_CONTROL_NODES}
        Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    9292    glance_api
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    9191    glance_registry
    END


*** Keywords ***
Create And Configure Glance Db
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${host_name}
    Create Database for Mysql    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    glance
    Grant Privileges To Mysql Database
    ...    ${os_node_cxn}
    ...    ${mysql_user}
    ...    ${mysql_pass}
    ...    glance.*
    ...    glance
    ...    ${host_name}
    ...    glance
    Grant Privileges To Mysql Database
    ...    ${os_node_cxn}
    ...    ${mysql_user}
    ...    ${mysql_pass}
    ...    glance.*
    ...    glance
    ...    localhost
    ...    glance
    IF    2 < ${NUM_CONTROL_NODES}
        Grant Privileges To Mysql Database
        ...    ${os_node_cxn}
        ...    ${mysql_user}
        ...    ${mysql_pass}
        ...    glance.*
        ...    glance
        ...    ${HAPROXY_HOSTNAME}
        ...    glance
    END

Create And Configure Glance Db Other Nodes
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${host_name}
    Grant Privileges To Mysql Database
    ...    ${os_node_cxn}
    ...    ${mysql_user}
    ...    ${mysql_pass}
    ...    glance.*
    ...    glance
    ...    ${host_name}
    ...    glance
    Grant Privileges To Mysql Database
    ...    ${os_node_cxn}
    ...    ${mysql_user}
    ...    ${mysql_pass}
    ...    glance.*
    ...    glance
    ...    localhost
    ...    glance
    IF    2 < ${NUM_CONTROL_NODES}
        Grant Privileges To Mysql Database
        ...    ${os_node_cxn}
        ...    ${mysql_user}
        ...    ${mysql_pass}
        ...    glance.*
        ...    glance
        ...    ${HAPROXY_HOSTNAME}
        ...    glance
    END

Create Openstack Elements
    [Arguments]    ${host_name}
    Source Local File    /tmp/stackrc
    Create User    glance    default    glance    rc_file=/tmp/stackrc
    Role Add    service    glance    admin    rc_file=/tmp/stackrc
    Create Service    glance    "Image Service"    image    rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}    image    public    9292    rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}    image    internal    9292    rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}    image    admin    9292    rc_file=/tmp/stackrc

Install Configure Glance
    [Arguments]    ${os_node_cxn}    ${host_name}
    IF    '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${os_node_cxn}    openstack-glance
    END
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    DEFAULT    bind_host    "0.0.0.0"
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    DEFAULT    notification_driver    "noop"
    IF    2 < ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${os_node_cxn}
        ...    /etc/glance/glance-api.conf
        ...    DEFAULT
        ...    transport_url
        ...    "rabbit://openstack:rabbit@${OS_CONTROL_1_HOSTNAME},openstack:rabbit@${OS_CONTROL_2_HOSTNAME},openstack:rabbit@${OS_CONTROL_3_HOSTNAME}"
    END
    IF    2 > ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${os_node_cxn}
        ...    /etc/glance/glance-api.conf
        ...    DEFAULT
        ...    transport_url
        ...    "rabbit://openstack:rabbit@${host_name}"
    END
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    oslo_messaging_rabbit    rabbit_max_retries    0
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    oslo_messaging_rabbit    rabbit_ha_queues    true
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-api.conf
    ...    database
    ...    connection
    ...    "mysql+pymysql://glance:glance@${host_name}/glance"
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-api.conf
    ...    keystone_authtoken
    ...    auth_uri
    ...    http://${host_name}:5000
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-api.conf
    ...    keystone_authtoken
    ...    auth_url
    ...    http://${host_name}:35357
    IF    2 < ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${os_node_cxn}
        ...    /etc/glance/glance-api.conf
        ...    keystone_authtoken
        ...    memcached_servers
        ...    ${OS_CONTROL_1_IP}:11211,${OS_CONTROL_2_IP}:11211,${OS_CONTROL_3_IP}:11211
    END
    IF    2 > ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${os_node_cxn}
        ...    /etc/glance/glance-api.conf
        ...    keystone_authtoken
        ...    memcached_servers
        ...    ${host_name}:11211
    END
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    keystone_authtoken    auth_type    password
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-api.conf
    ...    keystone_authtoken
    ...    project_domain_name
    ...    default
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    keystone_authtoken    user_domain_name    default
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    keystone_authtoken    project_name    service
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    keystone_authtoken    username    glance
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    keystone_authtoken    password    glance
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    paste_deploy    flavor    keystone
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    glance_store    stores    "file,http"
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-api.conf    glance_store    default_store    file
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-api.conf
    ...    glance_store
    ...    filesystem_store_datadir
    ...    /var/lib/glance/images/
    Chmod File    ${os_node_cxn}    /etc/glance/glance-api.conf    640
    Chown File    ${os_node_cxn}    /etc/glance/glance-api.conf    root    glance
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-registry.conf    DEFAULT    bind_host    "0.0.0.0"
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-registry.conf    DEFAULT    notification_driver    "noop"
    IF    2 < ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${os_node_cxn}
        ...    /etc/glance/glance-registry.conf
        ...    DEFAULT
        ...    transport_url
        ...    "rabbit://openstack:rabbit@${OS_CONTROL_1_HOSTNAME},openstack:rabbit@${OS_CONTROL_2_HOSTNAME},openstack:rabbit@${OS_CONTROL_3_HOSTNAME}"
    END
    IF    2 > ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${os_node_cxn}
        ...    /etc/glance/glance-registry.conf
        ...    DEFAULT
        ...    transport_url
        ...    "rabbit://openstack:rabbit@${host_name}"
    END
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-registry.conf
    ...    oslo_messaging_rabbit
    ...    rabbit_max_retries
    ...    0
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-registry.conf
    ...    oslo_messaging_rabbit
    ...    rabbit_ha_queues
    ...    true
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-registry.conf
    ...    database
    ...    connection
    ...    "mysql+pymysql://glance:glance@${host_name}/glance"
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-registry.conf
    ...    keystone_authtoken
    ...    auth_uri
    ...    http://${host_name}:5000
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-registry.conf
    ...    keystone_authtoken
    ...    auth_url
    ...    http://${host_name}:35357
    IF    2 < ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${os_node_cxn}
        ...    /etc/glance/glance-registry.conf
        ...    keystone_authtoken
        ...    memcached_servers
        ...    ${OS_CONTROL_1_IP}:11211,${OS_CONTROL_2_IP}:11211,${OS_CONTROL_3_IP}:11211
    END
    IF    2 > ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${os_node_cxn}
        ...    /etc/glance/glance-registry.conf
        ...    keystone_authtoken
        ...    memcached_servers
        ...    ${host_name}:11211
    END
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-registry.conf    keystone_authtoken    auth_type    password
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-registry.conf
    ...    keystone_authtoken
    ...    project_domain_name
    ...    default
    Crudini Edit
    ...    ${os_node_cxn}
    ...    /etc/glance/glance-registry.conf
    ...    keystone_authtoken
    ...    user_domain_name
    ...    default
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-registry.conf    keystone_authtoken    project_name    service
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-registry.conf    keystone_authtoken    username    glance
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-registry.conf    keystone_authtoken    password    glance
    Crudini Edit    ${os_node_cxn}    /etc/glance/glance-registry.conf    paste_deploy    flavor    keystone
    IF    2 < ${NUM_CONTROL_NODES} and '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${os_node_cxn}    nfs-utils
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Enable Service    ${os_node_cxn}    rpcbind
    END
    IF    2 < ${NUM_CONTROL_NODES}    Start Service    ${os_node_cxn}    rpcbind
    IF    2 < ${NUM_CONTROL_NODES}
        Run Command    ${os_node_cxn}    sudo mkdir -p /var/lib/glance/images
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Run Command    ${os_node_cxn}    sudo mount -t nfs ${HAPROXY_IP}:/images /var/lib/glance/images
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Run Command    ${os_node_cxn}    sudo mount
    END
    Run Command As User    ${os_node_cxn}    "glance-manage db_sync"    glance
    Enable Service    ${os_node_cxn}    openstack-glance-api
    Enable Service    ${os_node_cxn}    openstack-glance-registry

Start Glance
    [Arguments]    ${os_node_cxn}
    Start Service    ${os_node_cxn}    openstack-glance-api
    Start Service    ${os_node_cxn}    openstack-glance-registry
