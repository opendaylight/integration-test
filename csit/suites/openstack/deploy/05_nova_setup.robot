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
Install Nova
    Create And Configure Nova Db     ${OS_CONTROL_1_IP}      root    mysql     ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}        Create And Configure Nova Db Other Nodes     ${OS_CONTROL_2_IP}      root     mysql     ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}        Create And Configure Nova Db Other Nodes     ${OS_CONTROL_3_IP}      root     mysql     ${OS_CONTROL_3_HOSTNAME}
    Create Openstack Elements      ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Create Openstack Elements      ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Create Openstack Elements      ${OS_CONTROL_3_HOSTNAME}
    Install Configure Nova API     ${OS_CONTROL_1_IP}     ${OS_CONTROL_1_IP}     ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Install Configure Nova API    ${OS_CONTROL_2_IP}     ${OS_CONTROL_2_IP}    ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Install Configure Nova API    ${OS_CONTROL_3_IP}     ${OS_CONTROL_3_IP}    ${OS_CONTROL_3_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Generic HAProxy Entry      ${HAPROXY_IP}     ${HAPROXY_IP}     8773     nova_ec2_api_cluster
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Generic HAProxy Entry      ${HAPROXY_IP}     ${HAPROXY_IP}     8774     nova_compute_api_cluster
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Generic HAProxy Entry      ${HAPROXY_IP}     ${HAPROXY_IP}     8775     nova_metadata_api_cluster
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Generic HAProxy Entry      ${HAPROXY_IP}     ${HAPROXY_IP}     8775     nova_metadata_api_cluster
    Run Keyword If    1 > ${NUM_CONTROL_NODES}      Install Configure Nova Compute      ${OS_CONTROL_1_IP}      ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}      Install Configure Nova Compute      ${OS_COMPUTE_1_IP}      ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}      Install Configure Nova Compute      ${OS_COMPUTE_2_IP}      ${OS_COMPUTE_2_IP}

*** Keywords ***
Create And Configure Nova Db 
    [Arguments]    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     ${host_name}
    Create Database for Mysql    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova.*     nova    ${host_name}     nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova.*     nova    localhost     nova
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova.*     nova    ${HAPROXY_HOSTNAME}    nova
    Create Database for Mysql    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     nova_api
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_api.*     nova    ${host_name}      nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_api.*     nova    localhost     nova
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_api.*     nova    ${HAPROXY_HOSTNAME}    nova
    Create Database for Mysql    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     nova_cell0
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_cell0.*     nova    ${host_name}     nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_cell0.*     nova    localhost     nova
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_cell0.*     nova    ${HAPROXY_HOSTNAME}    nova

Create And Configure Nova Db Other Nodes
    [Arguments]    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     ${host_name}
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova.*     nova    ${host_name}     nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova.*     nova    localhost     nova
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova.*     nova    ${HAPROXY_HOSTNAME}    nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_api.*     nova    ${host_name}     nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_api.*     nova    localhost    nova
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_api.*     nova    ${HAPROXY_HOSTNAME}    nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_cell0.*     nova    ${host_name}     nova
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_cell0.*     nova    localhost    nova
    Run Keyword If    2 < ${NUM_CONTROL_NODES}     Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     nova_cell0.*     nova    ${HAPROXY_HOSTNAME}    nova

Create Openstack Elements
    [Arguments]    ${host_name}
    Source Local File 
    Create User     nova    default   nova    
    Role Add     service     nova     admin
    Create Service    nova    "Compute service"       compute
    Create Endpoint    RegionOne    ${host_name}     compute    public      8774/v2.1
    Create Endpoint    RegionOne    ${host_name}     compute    internal    8774/v2.1
    Create Endpoint    RegionOne    ${host_name}     compute    admin      8774/v2.1 
    Create User     placement    default    placement
    Role Add     service     placement    admin
    Create Service    placement   "Plaement API"       placement
    Create Endpoint    RegionOne    ${host_name}     placement    public      8778
    Create Endpoint    RegionOne    ${host_name}     placement    internal    8778
    Create Endpoint    RegionOne    ${host_name}     placement    admin      8778

Install Configure Nova API
    [Arguments]    ${os_node_cxn}     ${host_ip}     ${host_name}
    Install Rpm Package      ${os_node_cxn}      openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     enabled_apis     "osapi_compute,metadata"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     transport_url    "rabbit://openstack:rabbit@${OS_CONTROL_1_HOSTNAME},openstack:rabbit@${OS_CONTROL_2_HOSTNAME},openstack:rabbit@${OS_CONTROL_3_HOSTNAME}"
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     transport_url    "rabbit://openstack:rabbit@${host_name}"
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      DEFAULT     my_ip      ${host_ip} 
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     use_neutron    True
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     firewall_driver     nova.virt.firewall.NoopFirewallDriver
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    api_database    connection     "mysql+pymysql://nova:nova@${host_name}/nova_api"
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    database    connection     "mysql+pymysql://nova:nova@${host_name}/nova"
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    api    auth_strategy     keystone
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    auth_uri     http://${host_name}:5000
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    auth_url     http://${host_name}:35357
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf     keystone_authtoken    memcached_servers      ${OS_CONTROL_1_IP}:11211,${OS_CONTROL_2_IP}:11211,${OS_CONTROL_3_IP}:11211
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf     keystone_authtoken    memcached_servers      ${host_name}:11211
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    auth_type     password
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    project_domain_name     default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    user_domain_name     default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    project_name     service
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    username     nova
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    password    nova
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    vnc     enabled     false
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    glance    api_servers     http://${host_name}:9292
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    oslo_concurrency    lock_path     /var/lib/nova/tmp

    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     os_region_name     RegionOne 
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     project_domain_name     Default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     user_domain_name     Default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     project_name     service
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     auth_type    password
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     auth_url    http://${host_name}:35357/v3
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     username    placement
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     password    placement
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    scheduler    discover_hosts_in_cells_interval    40
    ${entry}=    Set Variable      "<Directory /usr/bin>"
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}
    ${entry}=    Set Variable      "  <IfVersion >= 2.4>"
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}
    ${entry}=    Set Variable      "    Require all granted" 
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}
    ${entry}=    Set Variable      "  </IfVersion>"
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}
    ${entry}=    Set Variable      "  <IfVersion < 2.4>"
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}
    ${entry}=    Set Variable      "    Order allow,deny" 
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}
    ${entry}=    Set Variable      "    Allow from all" 
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}
    ${entry}=    Set Variable      "  </IfVersion>"
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}
    ${entry}=    Set Variable      "</Directory>"
    Append To File     ${os_node_cxn}     /etc/httpd/conf.d/00-nova-placement-api.conf     ${entry}

    Restart Service     ${os_node_cxn}    httpd
    Run Command As User    ${os_node_cxn}     "nova-manage api_db sync"    nova
    Run Command As User    ${os_node_cxn}     "nova-manage cell_v2 map_cell0"    nova
    Run Command As User    ${os_node_cxn}     "nova-manage cell_v2 create_cell --name=cell1 --verbose"    nova
    Run Command As User    ${os_node_cxn}     "nova-manage db sync"    nova
    Run Command As User    ${os_node_cxn}     "nova-manage cell_v2 list_cells"    nova
    
    Enable Service     ${os_node_cxn}     openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
    Start Service     ${os_node_cxn}     openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service


Install Configure Nova Compute
    [Arguments]    ${os_node_cxn}     ${host_ip}
    Install Rpm Package      ${os_node_cxn}      openstack-nova-compute
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     enabled_apis     "osapi_compute,metadata"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     transport_url    "rabbit://openstack:rabbit@${OS_CONTROL_1_HOSTNAME},openstack:rabbit@${OS_CONTROL_2_HOSTNAME},openstack:rabbit@${OS_CONTROL_3_HOSTNAME}"
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     transport_url    "rabbit://openstack:rabbit@${host_name}"
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      DEFAULT     my_ip      ${host_ip} 
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     use_neutron    True
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    DEFAULT     firewall_driver     nova.virt.firewall.NoopFirewallDriver
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    api    auth_strategy     keystone
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    auth_uri     http://${OS_CONTROL_1_HOSTNAME}:5000
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    auth_uri     http://${HAPROXY_HOSTNAME}:5000
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    auth_url     http://${OS_CONTROL_1_HOSTNAME}:35357
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    auth_url     http://${HAPROXY_HOSTNAME}:35357
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf     keystone_authtoken    memcached_servers      ${OS_CONTROL_1_IP}:11211,${OS_CONTROL_2_IP}:11211,${OS_CONTROL_3_IP}:11211
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf     keystone_authtoken    memcached_servers      ${host_name}:11211
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    auth_type     password
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    project_domain_name     default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    user_domain_name     default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    project_name     service
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    username     nova
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    keystone_authtoken    password    nova
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    vnc     enabled     false
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    glance     api_servers    http://${HAPROXY_HOSTNAME}:9292
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    glance     api_servers    http://${OS_CONTROL_1_HOSTNAME}:9292
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    oslo_concurrency    lock_path     /var/lib/nova/tmp

    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     os_region_name     RegionOne 
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     project_domain_name     Default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     user_domain_name     Default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     project_name     service
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     auth_type    password
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     auth_url     http://${OS_CONTROL_1_HOSTNAME}:35357/v3
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     auth_url     http://${HAPROXY_HOSTNAME}:35357/v3
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     username    placement
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf    placement     password    placement
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf     libvirt     virt_type     qemu
    Enable Service   ${os_node_cxn}     openstack-nova-compute    libvirtd
    Start Service   ${os_node_cxn}     openstack-nova-compute     libvirtd
