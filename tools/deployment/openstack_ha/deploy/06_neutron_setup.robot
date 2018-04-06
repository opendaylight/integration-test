*** Settings ***
Documentation     Suite that Intalls Neutron and Configures Networking ODL
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
Install Neutron
    Create And Configure Neutron Db    ${OS_NEUTRON_1_IP}    root    mysql    ${OS_NEUTRON_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Create And Configure Neutron Db Other Nodes    ${OS_CONTROL_2_IP}    root    mysql    ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Create And Configure Neutron Db Other Nodes    ${OS_CONTROL_3_IP}    root    mysql    ${OS_CONTROL_3_HOSTNAME}
    Create Openstack Elements    ${HAPROXY_HOSTNAME}
    Install Configure Neutron    ${OS_NEUTRON_1_IP}    ${OS_NEUTRON_1_IP}    ${HAPROXY_HOSTNAME}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Install Configure Neutron    ${OS_NEUTRON_2_IP}    ${OS_NEUTRON_2_IP}    ${HAPROXY_HOSTNAME}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Install Configure Neutron    ${OS_NEUTRON_3_IP}    ${OS_NEUTRON_3_IP}    ${HAPROXY_HOSTNAME}
    Sync Db    ${OS_NEUTRON_1_IP}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Sync Db    ${OS_NEUTRON_2_IP}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Sync Db    ${OS_NEUTRON_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    9796    neutron_server    9696      ${OS_NEUTRON_1_IP}    ${OS_NEUTRON_2_IP}     ${OS_NEUTRON_3_IP}
    Add ODL As Ovs Manager    ${OS_NEUTRON_1_IP}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Add ODL As Ovs Manager    ${OS_NEUTRON_2_IP}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Add ODL As Ovs Manager    ${OS_NEUTRON_3_IP}
    Start Neutron Service    ${OS_NEUTRON_1_IP}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Start Neutron Service    ${OS_NEUTRON_2_IP}
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Start Neutron Service    ${OS_NEUTRON_3_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Install Configure Neutron Compute    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_1_IP}    ${HAPROXY_HOSTNAME}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Install Configure Neutron Compute    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_2_IP}    ${HAPROXY_HOSTNAME}

*** Keywords ***
Create And Configure Neutron Db
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${host_name}
    Create Database for Mysql    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    neutron
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    neutron.*    neutron    ${host_name}
    ...    neutron
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    neutron.*    neutron    localhost
    ...    neutron
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    neutron.*
    ...    neutron    ${HAPROXY_HOSTNAME}    neutron

Create And Configure Neutron Db Other Nodes
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${host_name}
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    neutron.*    neutron    ${host_name}
    ...    neutron
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    neutron.*    neutron    localhost
    ...    neutron
    Grant Privileges To Mysql Database    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    neutron.*    neutron    ${HAPROXY_HOSTNAME}
    ...    neutron

Create Openstack Elements
    [Arguments]    ${host_name}
    Create User    neutron    default    neutron    rc_file=/tmp/stackrc
    Role Add    service    neutron    admin    rc_file=/tmp/stackrc
    Create Service    neutron    "Networking service"    network    rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}    network    public    9696    rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}    network    internal    9696    rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}    network    admin    9696    rc_file=/tmp/stackrc

Install Configure Neutron
    [Arguments]    ${os_node_cxn}    ${host_ip}    ${host_name}
    Run Keyword If    '${OS_APPS_PRE_INSTALLED}' == 'no'    Install Rpm Package    ${os_node_cxn}    openstack-neutron openstack-neutron-ml2 ebtables
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    transport_url
    ...    "rabbit://openstack:rabbit@${OS_CONTROL_1_HOSTNAME},openstack:rabbit@${OS_CONTROL_2_HOSTNAME},openstack:rabbit@${OS_CONTROL_3_HOSTNAME}"
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    transport_url
    ...    "rabbit://openstack:rabbit@${host_name}"
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    core_plugin    ml2
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    allow_overlapping_ips    true
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    database    connection    "mysql+pymysql://neutron:neutron@${host_name}/neutron"
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    auth_strategy    keystone
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    notify_nova_on_port_status_changes    true
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    notify_nova_on_port_data_changes    true
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    dhcp_agents_per_network
    ...    3
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    auth_uri    http://${host_name}:5000
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    auth_url    http://${host_name}:35357
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    memcached_servers
    ...    ${OS_CONTROL_1_IP}:11211,${OS_CONTROL_2_IP}:11211,${OS_CONTROL_3_IP}:11211
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    memcached_servers
    ...    ${host_name}:11211
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    auth_type    password
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    project_domain_name    default
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    user_domain_name    default
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    project_name    service
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    username    neutron
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    keystone_authtoken    password    neutron
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    auth_uri    http://${host_name}:5000
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    auth_url    http://${host_name}:35357
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    memcached_servers
    ...    ${OS_CONTROL_1_IP}:11211,${OS_CONTROL_2_IP}:11211,${OS_CONTROL_3_IP}:11211
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    memcached_servers
    ...    ${host_name}:11211
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    auth_type    password
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    project_domain_name    default
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    user_domain_name    default
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    project_name    service
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    username    nova
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    nova    password    nova
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    oslo_concurrency    lock_path    /var/lib/neutron/tmp
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    OVS    ovsdb_connection    tcp:127.0.0.1:6641
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    oslo_messaging_rabbit    rabbit_max_retries    0
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    oslo_messaging_rabbit    rabbit_ha_queues    true
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2    type_drivers    "flat,vlan,vxlan"
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2    tenant_network_types    vxlan
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2_type_vxlan    vni_ranges    1:1000
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2_type_vlan    network_vlan_ranges    physnet1:1:4094
    Crudini Edit    ${os_node_cxn}    /etc/neutron/dhcp_agent.ini    DEFAULT    ovs_use_veth    True
    Crudini Edit    ${os_node_cxn}    /etc/neutron/dhcp_agent.ini    DEFAULT    interface_driver    openvswitch
    Crudini Edit    ${os_node_cxn}    /etc/neutron/dhcp_agent.ini    DEFAULT    enable_isolated_metadata    true
    Crudini Edit    ${os_node_cxn}    /etc/neutron/dhcp_agent.ini    OVS    ovsdb_connection    tcp:127.0.0.1:6641
    Crudini Edit    ${os_node_cxn}    /etc/neutron/metadata_agent.ini    DEFAULT    nova_metadata_ip    ${host_name}
    Crudini Edit    ${os_node_cxn}    /etc/neutron/metadata_agent.ini    DEFAULT    metadata_proxy_shared_secret    metadata
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    url    http://${host_name}:9696
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    auth_url    http://${host_name}:35357
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    auth_type    password
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    project_domain_name    default
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    user_domain_name    default
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    region_name    RegionOne
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    project_name    service
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    username    neutron
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    password    neutron
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    service_metadata_proxy    true
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    metadata_proxy_shared_secret    metadata
    Install Rpm Package    ${os_node_cxn}    python-networking-odl
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2    mechanism_drivers    opendaylight_v2
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2_odl    url    http://${host_name}:8080/controller/nb/v2/neutron
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2_odl    username    admin
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2_odl    password    admin
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2_odl    port_binding_controller    pseudo-agentdb-binding
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    securitygroup    enable_security_group    true
    Crudini Edit    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    ml2    extension_drivers    port_security
    Crudini Edit    ${os_node_cxn}    /etc/neutron/neutron.conf    DEFAULT    service_plugins    odl-router_v2
    Install OVS And Configure    ${os_node_cxn}    ${host_ip}

Sync Db
    [Arguments]    ${os_node_cxn}
    #Unlink File    ${os_node_cxn}    /etc/neutron/plugin.ini
    Create Softlink    ${os_node_cxn}    /etc/neutron/plugins/ml2/ml2_conf.ini    /etc/neutron/plugin.ini
    Run Command As User    ${os_node_cxn}    "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head"    neutron
    Enable Service    ${os_node_cxn}    neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service

Start Neutron Service
    [Arguments]    ${os_node_cxn}
    Restart Service    ${os_node_cxn}    openstack-nova-api.service
    Start Service    ${os_node_cxn}    neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service

Install Configure Neutron Compute
    [Arguments]    ${os_node_cxn}    ${host_ip}    ${host_name}
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    auth_type    password
    Run Keyword If    2 > ${NUM_CONTROL_NODES}    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    auth_url
    ...    http://${host_name}:35357
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    username    neutron
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    password    neutron
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    user_domain_name    Default
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    project_domain_name    Default
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    project_name    service
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    auth_strategy    keystone
    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    region_name    RegionOne
    Run Keyword If    2 > ${NUM_NEUTRON_NODES}    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    url
    ...    http://${host_name}:9696
    Run Keyword If    2 < ${NUM_NEUTRON_NODES}    Crudini Edit    ${os_node_cxn}    /etc/nova/nova.conf    neutron    url
    ...    http://${HAPROXY_HOSTNAME}:9696
    Restart Service    ${os_node_cxn}    libvirtd.service openstack-nova-compute.service
    Install OVS And Configure    ${os_node_cxn}    ${host_ip}
    Add ODL As Ovs Manager    ${os_node_cxn}

Install OVS And Configure
    [Arguments]    ${os_node_cxn}    ${host_ip}
    Run Keyword If    '${OS_APPS_PRE_INSTALLED}' == 'no'    Install Rpm Package    ${os_node_cxn}    openvswitch
    Install Rpm Package    ${os_node_cxn}    python-networking-odl
    Enable Service    ${os_node_cxn}    openvswitch
    Restart Service    ${os_node_cxn}    openvswitch
    Run Command    ${os_node_cxn}    sudo neutron-odl-ovs-hostconfig --config-file=/etc/neutron/neutron.conf --debug --noovs_dpdk --bridge_mappings="flat1:br-flat1,flat2:br-flat2,physnet1:br-physnet1" --local_ip ${host_ip}

Add ODL As Ovs Manager
    [Arguments]    ${os_node_cxn}
    Run Keyword If    2 < ${NUM_ODL_NODES}    Run Command    ${os_node_cxn}    sudo ovs-vsctl set-manager tcp:${OS_ODL_1_IP}:6640 tcp:${OS_ODL_2_IP}:6640 tcp:${OS_ODL_3_IP}:6640
    Run Keyword If    2 > ${NUM_ODL_NODES}    Run Command    ${os_node_cxn}    sudo ovs-vsctl set-manager tcp:${OS_ODL_1_IP}:6640
