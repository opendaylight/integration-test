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


Setup MySql
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Install MySQl Cluster     ${CONTROL1_NODE_IP}    ${CONTROL1_NODE_IP}     galera1
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Install MySQl Cluster     ${CONTROL2_NODE_IP}    ${CONTROL2_NODE_IP}     galera2
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Install MySQl Cluster     ${CONTROL3_NODE_IP}    ${CONTROL3_NODE_IP}     galera3
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Configure Cluster Root Node     ${CONTROL1_NODE_IP}     ${CONTROL1_HOST_NAME}    ${CONTROL1_NODE_USER}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Enable MySQL non-root nodes     ${CONTROL2_NODE_IP}     ${CONTROL2_HOST_NAME}    ${CONTROL2_NODE_USER}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Enable MySQL non-root nodes     ${CONTROL3_NODE_IP}     ${CONTROL3_HOST_NAME}    ${CONTROL3_NODE_USER}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Add HAPROXY Entry for DB     ${HAPROXY_NODE_IP}     ${HAPROXY_NODE_IP}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}     Install MySql     ${CONTROL1_NODE_IP}     ${CONTROL1_HOST_NAME}      ${CONTROL1_NODE_USER}
    Run Keyword If    2 > ${NUM_CONTROL_NODES}     Enable MySql     ${CONTROL1_NODE_IP}     ${CONTROL1_HOST_NAME}      ${CONTROL1_NODE_USER}

*** Keywords ***
Install MySQl
    [Arguments]    ${os_node_cxn}
    Install Rpm Package    ${os_node_cxn}    mariadb mariadb-server python2-PyMySQL
    Touch File     ${os_node_cxn}      /etc/my.cnf.d/openstack.cnf
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     bind-address     0.0.0.0
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     default-storage-engine     innodb
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     innodb_file_per_table      innodb
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     max_connections     4096
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     collation-server    utf8_general_ci
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     character-set-server     utf8

Enable MySql
    [Arguments]    ${os_node_cxn}     ${hostname}     ${hostuser}
    Enable Service    ${os_node_cxn}    mariadb.service
    Start Service    ${os_node_cxn}    mariadb.service
    Create User Pass For Mysql     ${os_node_cxn}     root     mysql
    Grant Privileges To Mysql Database      ${os_node_cxn}    root     mysql    "*.*"      ${hostname}      ${hostuser}
    Grant Privileges To Mysql Database      ${os_node_cxn}    root     mysql    "*.*"      localhost      ${hostuser}

Install MySql Cluster
    [Arguments]    ${os_node_cxn}     ${bindaddress}    ${galera_cluster_name}
    Install Rpm Package    ${os_node_cxn}     mariadb galera mariadb-galera-server python2-PyMySQL mariadb-libs
    Touch File     ${os_node_cxn}      /etc/my.cnf.d/openstack.cnf
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     bind-address      ${bindaddress}
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     datadir        /var/lib/mysql
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     socket       /var/lib/mysql/mysql.sock
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     user       mysql
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     binlog_format    ROW
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     default_storage_engine     innodb
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     innodb_autoinc_lock_mode    2
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     innodb_flush_log_at_trx_commit     0
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     innodb_buffer_pool_size    122M
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     wsrep_provider     /usr/lib64/libgalera_smm.so
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     wsrep_provider_options     "pc.recovery=TRUE;gcache.size=300M"
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     wsrep_cluster_name     ${galera_cluster_name}
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     wsrep_cluster_address     gcomm://${CONTROL1_NODE_IP},${CONTROL2_NODE_IP},${CONTROL3_NODE_IP}
    Crudini Edit    ${os_node_cxn}     /etc/my.cnf.d/openstack.cnf     mysqld     wsrep_sst_method     rsync
    

Configure Cluster Root Node
    [Arguments]    ${os_node_cxn}     ${hostname}    ${hostuser}
    Run Command    ${os_node_cxn}    galera_new_cluster 
    Execute MySQL STATUS Query     ${os_node_cxn}    root     mysql     wsrep_cluster_size
    Create User Pass For Mysql     ${os_node_cxn}     root     mysql
    Grant Privileges To Mysql Database      ${os_node_cxn}    root     mysql    "*.*"      ${hostname}      ${hostuser}
    Grant Privileges To Mysql Database      ${os_node_cxn}    root     mysql    "*.*"      localhost      ${hostuser}

Enable MySQL non-root nodes
    [Arguments]    ${os_node_cxn}       ${hostname}     ${hostuser}
    Enable Service    ${os_node_cxn}    mariadb.service
    Start Service    ${os_node_cxn}    mariadb.service
    Execute MySQL STATUS Query     ${os_node_cxn}    root     mysql     wsrep_cluster_size
    Grant Privileges To Mysql Database      ${os_node_cxn}    root     mysql    "*.*"      ${hostname}      ${hostuser}
    Grant Privileges To Mysql Database      ${os_node_cxn}    root     mysql    "*.*"      localhost      ${hostuser}

Add HAPROXY Entry for DB
    [Arguments]    ${os_node_cxn}     ${bind_ip}
    Append To File     ${os_node_cxn}      /etc/haproxy/haproxy.cfg      listen galera_cluster
    Append To File     ${os_node_cxn}      /etc/haproxy/haproxy.cfg      " bind ${bind_ip}:3306"
    Append To File     ${os_node_cxn}      /etc/haproxy/haproxy.cfg      " balance source"
    Append To File     ${os_node_cxn}      /etc/haproxy/haproxy.cfg      " option mysql-check"
    Append To File     ${os_node_cxn}      /etc/haproxy/haproxy.cfg      " server galera1 ${CONTROL1_NODE_IP}:3306 check inter 2000 rise 2 fall 5"
    Append To File     ${os_node_cxn}      /etc/haproxy/haproxy.cfg      " server galera2 ${CONTROL2_NODE_IP}:3306 backup check inter 2000 rise 2 fall 5"
    Append To File     ${os_node_cxn}      /etc/haproxy/haproxy.cfg      " server galera3 ${CONTROL3_NODE_IP}:3306 backup check inter 2000 rise 2 fall 5"
    Enable Serive      ${os_node_cxn}      haproxy
    Start Service      ${os_node_cxn}      haproxy
