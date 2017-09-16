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
Setup MySql
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install MySQl Cluster    ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_IP}    openstack
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install MySQl Cluster    ${OS_CONTROL_2_IP}    ${OS_CONTROL_2_IP}    openstack
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install MySQl Cluster    ${OS_CONTROL_3_IP}    ${OS_CONTROL_3_IP}    openstack
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Install MySQl Cluster    ${OS_CONTROL_4_IP}    ${OS_CONTROL_4_IP}    openstack
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Install MySQl Cluster    ${OS_CONTROL_5_IP}    ${OS_CONTROL_5_IP}    openstack
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Configure Cluster Root Node    ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_HOSTNAME}    ${OS_USER}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Enable MySQL non-root nodes    ${OS_CONTROL_2_IP}    ${OS_CONTROL_2_HOSTNAME}    ${OS_USER}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Enable MySQL non-root nodes    ${OS_CONTROL_3_IP}    ${OS_CONTROL_2_HOSTNAME}    ${OS_USER}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Enable MySQL non-root nodes    ${OS_CONTROL_4_IP}    ${OS_CONTROL_4_HOSTNAME}    ${OS_USER}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Enable MySQL non-root nodes    ${OS_CONTROL_5_IP}    ${OS_CONTROL_5_HOSTNAME}    ${OS_USER}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Add HAPROXY Entry for DB    ${HAPROXY_IP}    ${HAPROXY_IP}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Install MySql    ${OS_CONTROL_1_IP}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Enable MySql    ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_HOSTNAME}    ${OS_USER}

*** Keywords ***
Install MySQl
    [Arguments]    ${os_node_cxn}
    Run Keyword If    '${OS_APPS_PRE_INSTALLED}' == 'no'    Install Rpm Package    ${os_node_cxn}    mariadb mariadb-server python2-PyMySQL
    Touch File    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    bind-address    0.0.0.0
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    default-storage-engine    innodb
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    innodb_file_per_table    innodb
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    max_connections    4096
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    collation-server    utf8_general_ci
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    character-set-server    utf8

Enable MySql
    [Arguments]    ${os_node_cxn}    ${hostname}    ${hostuser}
    Enable Service    ${os_node_cxn}    mariadb.service
    Start Service    ${os_node_cxn}    mariadb.service
    Create User Pass For Mysql    ${os_node_cxn}    root    mysql
    Grant Privileges To Mysql Database    ${os_node_cxn}    root    mysql    *.*    ${hostname}    ${hostuser}
    ...    mysql
    Grant Privileges To Mysql Database    ${os_node_cxn}    root    mysql    *.*    localhost    ${hostuser}
    ...    mysql

Install MySql Cluster
    [Arguments]    ${os_node_cxn}    ${bindaddress}    ${galera_cluster_name}
    Run Keyword If    '${OS_APPS_PRE_INSTALLED}' == 'no'    Install Rpm Package    ${os_node_cxn}    mariadb galera mariadb-galera-server python2-PyMySQL mariadb-libs
    Touch File    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    bind-address    0.0.0.0
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    datadir    /var/lib/mysql
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    socket    /var/lib/mysql/mysql.sock
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    user    mysql
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    binlog_format    ROW
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    default_storage_engine    innodb
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    innodb_autoinc_lock_mode    2
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    innodb_flush_log_at_trx_commit    0
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    innodb_buffer_pool_size    122M
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    wsrep_provider    /usr/lib64/galera/libgalera_smm.so
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    wsrep_provider_options    "pc.recovery=TRUE;gcache.size=300M"
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    wsrep_cluster_name    ${galera_cluster_name}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    wsrep_cluster_address
    ...    gcomm://${OS_CONTROL_1_IP},${OS_CONTROL_2_IP},${OS_CONTROL_3_IP},${OS_CONTROL_4_IP},${OS_CONTROL_5_IP}
    Run Keyword If    4 > ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    wsrep_cluster_address
    ...    gcomm://${OS_CONTROL_1_IP},${OS_CONTROL_2_IP},${OS_CONTROL_3_IP}
    Crudini Edit    ${os_node_cxn}    /etc/my.cnf.d/openstack.cnf    mysqld    wsrep_sst_method    rsync
    Crudini Delete    ${os_node_cxn}    /etc/my.cnf.d/auth_gssapi.cnf    mariadb    plugin-load-add
    #Configure Mysql Cluster Check    ${os_node_cxn}

Configure Cluster Root Node
    [Arguments]    ${os_node_cxn}    ${hostname}    ${hostuser}
    Enable Service    ${os_node_cxn}    mariadb.service
    Run Command    ${os_node_cxn}    sudo galera_new_cluster
    Create User Pass For Mysql    ${os_node_cxn}    root    mysql
    Grant Privileges To Mysql Database    ${os_node_cxn}    root    mysql    *.*    ${hostuser}    ${hostname}
    ...    mysql
    Grant Privileges To Mysql Database    ${os_node_cxn}    root    mysql    *.*    ${hostuser}    localhost
    ...    mysql
    Grant Privileges To Mysql Database    ${os_node_cxn}    root    mysql    *.*    ${hostuser}    ${HAPROXY_HOSTNAME}
    ...    mysql    #Grant Process To Mysql Database    ${os_node_cxn}    root    mysql    *.*
    ...    # clustercheck_user    localhost    # my_clustercheck_password
    Execute MySQL STATUS Query    ${os_node_cxn}    root    mysql    wsrep_cluster_size

Enable MySQL non-root nodes
    [Arguments]    ${os_node_cxn}    ${hostname}    ${hostuser}
    Enable Service    ${os_node_cxn}    mariadb.service
    Start Service    ${os_node_cxn}    mariadb.service
    Grant Privileges To Mysql Database    ${os_node_cxn}    root    mysql    *.*    ${hostuser}    ${hostname}
    ...    mysql
    Grant Privileges To Mysql Database    ${os_node_cxn}    root    mysql    *.*    ${hostuser}    localhost
    ...    mysql
    Grant Privileges To Mysql Database    ${os_node_cxn}    root    mysql    *.*    ${hostuser}    ${HAPROXY_HOSTNAME}
    ...    mysql    #Grant Process To Mysql Database    ${os_node_cxn}    root    mysql    *.*
    ...    # clustercheck_user    localhost    # my_clustercheck_password
    Execute MySQL STATUS Query    ${os_node_cxn}    root    mysql    wsrep_cluster_size

Add HAPROXY Entry for DB
    [Arguments]    ${os_node_cxn}    ${bind_ip}
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    $'\n'listen hadatabase
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " bind ${bind_ip}:3306"
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " timeout client 90s"
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " mode tcp"
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " option mysql-check user root"
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " balance roundrobin"
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " timeout server 90s"
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " server galera1 ${OS_CONTROL_1_IP}:3306"
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " server galera2 ${OS_CONTROL_2_IP}:3306"
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " server galera3 ${OS_CONTROL_3_IP}:3306"
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " server galera4 ${OS_CONTROL_4_IP}:3306"
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    " server galera4 ${OS_CONTROL_5_IP}:3306"
    Enable Service    ${os_node_cxn}    haproxy
    Restart Service    ${os_node_cxn}    haproxy

Configure Mysql Cluster Check
    [Arguments]    ${os_node_cxn}
    Touch File    ${os_node_cxn}    /etc/sysconfig/clustercheck
    Append To File    ${os_node_cxn}    /etc/sysconfig/clustercheck    MYSQL_USERNAME=clustercheck_user
    Append To File    ${os_node_cxn}    /etc/sysconfig/clustercheck    MYSQL_PASSWORD=my_clustercheck_password
    Append To File    ${os_node_cxn}    /etc/sysconfig/clustercheck    MYSQL_HOST=localhost
    Append To File    ${os_node_cxn}    /etc/sysconfig/clustercheck    MYSQL_PORT=3306
    Run Keyword If    '${OS_APPS_PRE_INSTALLED}' == 'no'    Install Rpm Package    ${os_node_cxn}    xinetd
    Touch File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    service galera-monitor
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    "{"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " port = 9200"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " disable = no"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " socket_type = stream"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " protocol = tcp"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " wait = no"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " user= root"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " group = root"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " groups = yes"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " server = /usr/bin/clustercheck"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " type = UNLISTED"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " per_source = UNLISTED"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " log_on_failure = HOST"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    " flags = REUSE"
    Append To File    ${os_node_cxn}    /etc/xinetd.d/galera-monitor    "}"
    Daemon Reload    ${os_node_cxn}
    Enable Service    ${os_node_cxn}    xinetd
    Start Service    ${os_node_cxn}    xinetd
