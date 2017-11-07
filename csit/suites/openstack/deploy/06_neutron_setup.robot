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
    Create And Configure Neutron Db     ${OS_CONTROL_1_IP}      root    mysql     ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}        Create And Configure Neutron Db Other Nodes     ${OS_CONTROL_2_IP}      root     mysql     ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}        Create And Configure Neutron Db Other Nodes     ${OS_CONTROL_3_IP}      root     mysql     ${OS_CONTROL_3_HOSTNAME}
    Create Openstack Elements      ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Create Openstack Elements      ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Create Openstack Elements      ${OS_CONTROL_3_HOSTNAME}
    Install Configure Neutron     ${OS_CONTROL_1_IP}     ${OS_CONTROL_1_IP}     ${OS_CONTROL_1_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Install Configure Neutron    ${OS_CONTROL_2_IP}     ${OS_CONTROL_2_IP}    ${OS_CONTROL_2_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Install Configure Neutron    ${OS_CONTROL_3_IP}     ${OS_CONTROL_3_IP}    ${OS_CONTROL_3_HOSTNAME}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Generic HAProxy Entry      ${HAPROXY_IP}     ${HAPROXY_IP}     9696    neutron_server 
    Run Keyword If    1 > ${NUM_CONTROL_NODES}      Install Configure Neutron Compute      ${OS_CONTROL_1_IP}      ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}      Install Configure Neutron Compute      ${OS_COMPUTE_1_IP}      ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}      Install Configure Neutron Compute      ${OS_COMPUTE_2_IP}      ${OS_COMPUTE_2_IP}

*** Keywords ***
Create And Configure Neutron Db 
    [Arguments]    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     ${host_name}
    Create Database for Mysql    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     neutron
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     neutron.*     neutron    ${host_name}      neutron
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     neutron.*     neutron    localhost     neutron
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     neutron.*     neutron    ${HAPROXY_HOSTNAME}      neutron

Create And Configure Neutron Db Other Nodes
    [Arguments]    ${os_node_cxn}     ${mysql_user}     ${mysql_pass}     ${host_name}
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     neutron.*     ${db_user}    ${host_name}     ${mysql_pass}
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     neutron.*     ${db_user}    localhost    ${mysql_pass}
    Grant Privileges To Mysql Database     ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     neutron.*     neutron    ${HAPROXY_HOSTNAME}      neutron

Create Openstack Elements
    [Arguments]    ${host_name}
    Create User     neutron    default   neutron    rc_file=/tmp/stackrc
    Role Add     service     neutron   admin    rc_file=/tmp/stackrc
    Create Service    nova    "Networking service"       network       rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}     compute    public      9696     rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}     compute    internal    9696     rc_file=/tmp/stackrc
    Create Endpoint    RegionOne    ${host_name}     compute    admin       9696     rc_file=/tmp/stackrc

Install Configure Neutron
    [Arguments]    ${os_node_cxn}     ${host_ip}     ${host_name}
    Install Rpm Package      ${os_node_cxn}      openstack-neutron openstack-neutron-ml2 ebtables
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    DEFAULT     transport_url    "rabbit://openstack:rabbit@${OS_CONTROL_1_HOSTNAME},openstack:rabbit@${OS_CONTROL_2_HOSTNAME},openstack:rabbit@${OS_CONTROL_3_HOSTNAME}"
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    DEFAULT     transport_url    "rabbit://openstack:rabbit@${host_name}"
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf      DEFAULT     core_plugin     ml2
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    DEFAULT      allow_overlapping_ips     true
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    database    connection     "mysql+pymysql://neutron:neutron@${host_name}/neutron"
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    DEFAULT    auth_strategy     keystone
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    DEFAULT    notify_nova_on_port_status_changes     true
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    DEFAULT    notify_nova_on_port_data_changes     true
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    keystone_authtoken    auth_uri     http://${host_name}:5000
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    keystone_authtoken    auth_url     http://${host_name}:35357
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf     keystone_authtoken    memcached_servers      ${OS_CONTROL_1_IP}:11211,${OS_CONTROL_2_IP}:11211,${OS_CONTROL_3_IP}:11211
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf     keystone_authtoken    memcached_servers      ${host_name}:11211
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    keystone_authtoken    auth_type     password
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    keystone_authtoken    project_domain_name     default
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    keystone_authtoken    user_domain_name     default
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    keystone_authtoken    project_name     service
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    keystone_authtoken    username     neutron
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    keystone_authtoken    password    neutron
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    nova     auth_uri     http://${host_name}:5000
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    nova     auth_url     http://${host_name}:35357
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf     nova     memcached_servers      ${OS_CONTROL_1_IP}:11211,${OS_CONTROL_2_IP}:11211,${OS_CONTROL_3_IP}:11211
    Run Keyword If    2 > ${NUM_CONTROL_NODES}      Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf     nova     memcached_servers      ${host_name}:11211
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    nova     auth_type      password
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    nova     project_domain_name     default
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    nova     user_domain_name     default
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    nova     project_name    service
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    nova     username     nova
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    nova     password     nova
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    oslo_concurrency      lock_path      /var/lib/neutron/tmp
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf    OVS      ovsdb_connection      tcp:127.0.0.1:6641

    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2      type_drivers     "flat,vlan,vxlan"
    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2      tenant_network_types      vxlan
    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2_type_vxlan      vni_ranges     1:1000
    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2_type_vlan     network_vlan_ranges     datacenter

    Crudini Edit     ${os_node_cxn}       /etc/neutron/dhcp_agent.ini        DEFAULT     ovs_use_veth    True
    Crudini Edit     ${os_node_cxn}       /etc/neutron/dhcp_agent.ini        DEFAULT     interface_driver     openvswitch
    Crudini Edit     ${os_node_cxn}       /etc/neutron/dhcp_agent.ini        DEFAULT     enable_isolated_metadata      true
    Crudini Edit     ${os_node_cxn}       /etc/neutron/dhcp_agent.ini        OVS       ovsdb_connection      tcp:127.0.0.1:6641

    Crudini Edit     ${os_node_cxn}       /etc/neutron/metadata_agent.ini        DEFAULT      nova_metadata_ip     ${host_name}
    Crudini Edit     ${os_node_cxn}       /etc/neutron/metadata_agent.ini        DEFAULT      metadata_proxy_shared_secret     metadata


    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     url      http://${host_name}:9696
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     auth_url      http://${host_name}:35357
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     auth_type    password
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     project_domain_name    default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     user_domain_name    default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     region_name      RegionOne
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     project_name   service
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     username     neutron
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     password    neutron
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     service_metadata_proxy     true
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron     metadata_proxy_shared_secret     metadata

    Install Rpm Package      ${os_node_cxn}      python-networking-odl
    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2     mechanism_drivers     opendaylight_v2
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2_odl      url        http://${HAPROXY_IP}:8080/controller/nb/v2/neutron
    Run Keyword If    2 > ${NUM_CONTROL_NODES}       Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2_odl      url        http://${host_name}:8080/controller/nb/v2/neutron
    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2_odl      username    admin
    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2_odl      password    admin
    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      ml2_odl      port_binding_controller     pseudo-agentdb-binding
    Crudini Edit     ${os_node_cxn}       /etc/neutron/plugins/ml2/ml2_conf.ini      securitygroup     enable_security_group    true 
    Crudini Edit     ${os_node_cxn}       /etc/neutron/neutron.conf      DEFAULT     service_plugins      odl-router_v2
    Install OVS And Configure      ${os_node_cxn}       ${host_ip}

Install Configure Neutron Compute
    [Arguments]    ${os_node_cxn}     ${host_ip}     ${host_name}
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      auth_type     password
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      auth_url      http://${host_name}:35357
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      username    neutron
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      password    neutron
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      user_domain_name     Default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      project_domain_name     Default
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      project_name     service
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      auth_strategy     keystone
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      region_name    RegionOne
    Crudini Edit     ${os_node_cxn}       /etc/nova/nova.conf      neutron      url     http://${host_name}:9696
    Install OVS And Configure      ${os_node_cxn}       ${host_ip}
    
Install OVS And Configure
    [Arguments]    ${os_node_cxn}     ${host_ip}
    Install Rpm Package      ${os_node_cxn}      python-networking-odl openvswitch
    Start Service      ${os_node_cxn}      openvswitch
    Run Command      ${os_node_cxn}      neutron-odl-ovs-hostconfig --config-file=/etc/neutron/neutron.conf --debug --noovs_dpdk --bridge_mappings=${EXT_BRIDGE}:br-${EXT_BRIDGE}
    Run Command      ${os_node_cxn}      read ovstbl <<< $(sudo ovs-vsctl get Open_vSwitch . _uuid);sudo ovs-vsctl set Open_vSwitch $ovstbl other_config:provider_mappings=${EXT_BRIDGE}:br-${EXT_BRIDGE};sudo ovs-vsctl set Open_vSwitch $ovstbl other_config:local_ip=${host_ip}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}       Run Command      sudo ovs-vsctl set-manager tcp:${OS_CONTROL_1_IP}:6640 tcp:${OS_CONTROL_2_IP}:6640 tcp:${OS_CONTROL_3_IP}:6640
    Run Keyword If    2 > ${NUM_CONTROL_NODES}       Run Command      sudo ovs-vsctl set-manager tcp:${OS_CONTROL_1_IP}:6640
