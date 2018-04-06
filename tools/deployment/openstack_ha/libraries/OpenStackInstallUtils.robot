*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Resource          SystemUtils.robot
Resource          ../../../../csit/variables/Variables.robot
Resource          ../../../../csit/variables/netvirt/Variables.robot
Variables         ../../../../csit/variables/netvirt/Modules.py

*** Keywords ***
Setup Basic Ssh
    [Arguments]    ${node_ip}    ${user_name}    ${password}    ${prompt}
    [Documentation]    Open SSh Connection and disable selinux
    ${connection}=    Get Ssh Connection    ${node_ip}    ${user_name}    ${password}    ${prompt}
    Disable SeLinux Tempororily    ${connection}
    [Return]    ${connection}

Get All Ssh Connections
    [Documentation]    Open All SSH Connections.
    Run Keyword If    0 < ${NUM_CONTROL_NODES}    Setup Basic Ssh    ${OS_CONTROL_1_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup basic Ssh    ${OS_CONTROL_2_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup basic Ssh    ${OS_CONTROL_3_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Setup basic Ssh    ${OS_CONTROL_4_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Setup basic Ssh    ${OS_CONTROL_5_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup basic Ssh    ${HAPROXY_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Setup basic Ssh    ${OS_COMPUTE_1_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Setup basic Ssh    ${OS_COMPUTE_2_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}

Enable Live Migration In A Node
    [Arguments]    ${compute_cxn}
    Switch Connection    ${compute_cxn}
    Crudini Edit    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    listen_tls    0
    Crudini Edit    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    listen_tcp    0
    Crudini Edit    ${compute_cxn}    /etc/libvirt/libvirtd.conf    ''    auth_tcp    '"none"'
    Crudini Edit    ${compute_cxn}    /etc/nova/nova.conf    DEFAULT    instances_path    '/var/lib/nova/instances_live_migration'
    Restart Service    ${compute_cxn}    openstack-nova-compute libvirtd

Enable Live Migration In All Compute Nodes
    [Documentation]    Enables Live Migration in all computes
    ${compute_1_cxn}=    Setup Basic Ssh    ${OS_COMPUTE_1_IP}    jenkins    ''    '>'
    Enable Live Migration In A Node    ${compute_1_cxn}
    ${compute_2_cxn}=    Setup Basic Ssh    ${OS_COMPUTE_2_IP}    jenkins    ''    '>'
    Enable Live Migration In A Node    ${compute_2_cxn}

Activate Control Node
    [Arguments]    ${control_node_cxn}
    Enable Service    ${control_node_cxn}    httpd
    Start Service    ${control_node_cxn}    httpd
    Start Service    ${control_node_cxn}    openstack-glance-api openstack-glance-registry
    Start Service    ${control_node_cxn}    openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.servi    ce openstack-nova-novncproxy.service
    Run Command    ${os_node_cxn}    sudo ovs-vsctl set-manager tcp:${OS_CONTROL_1_IP}:6640 tcp:${OS_CONTROL_2_IP}:6640 tcp:${OS_CONTROL_3_IP}:6640 tcp:${OS_CONTROL_4_IP}:6640 tcp:${OS_CONTROL_5_IP}:6640
    Start Service    ${control_node_cxn}    neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service
