*** Settings ***
Documentation     Install the basic packages for Openstack
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Resource          ../../../libraries/OpenStackInstallUtils.robot
Resource          ../../../libraries/SystemUtils.robot
Resource          ../../../libraries/OpendaylightInstallUtils.robot

*** Test Cases ***
Stop Firewall
    [Documentation]    Stop Firewalld and disable
    Stop And Disable Firewall    ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Stop And Disable Firewall    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Stop And Disable Firewall    ${OS_CONTROL_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Stop And Disable Firewall    ${HAPROXY_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Stop And Disable Firewall    ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Stop And Disable Firewall    ${OS_COMPUTE_2_IP}

Create Etc Hosts Entries
    [Documentation]     Create Etc Hosts Entries
    Create Etc Hosts    ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${OS_CONTROL_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${HAPROXY_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Create Etc Hosts    ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Create Etc Hosts    ${OS_COMPUTE_2_IP}

Update the Distro
    [Documentation]      Always Better to run yum update first :-)
    Update Packages    ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Update Packages     ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Update Packages     ${OS_CONTROL_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Update Packages     ${HAPROXY_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Update Packages     ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Update Packages     ${OS_COMPUTE_2_IP}

Get Chrony
    [Documentation]      Install Chrony
    Setup Chrony     ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Setup Chrony     ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup Chrony     ${OS_CONTROL_3_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Setup Chrony     ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Setup Chrony     ${OS_COMPUTE_2_IP}

Install Openstack Base Repo
    [Documentation]      Install Openstack Release Repo
    Install Openstack Base Rpm     ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Openstack Base Rpm     ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Openstack Base Rpm     ${OS_CONTROL_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Openstack Base Rpm     ${HAPROXY_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Install Openstack Base Rpm     ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Install Openstack Base Rpm     ${OS_COMPUTE_2_IP}

Get Crudini
    [Documentation]      Install Crudini in all the Openstack nodes
    Install Rpm Package    ${OS_CONTROL_1_IP}     crudini
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${OS_CONTROL_2_IP}    crudini
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${OS_CONTROL_3_IP}    crudini
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${HAPROXY_IP}     crudini
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Install Rpm Package     ${OS_COMPUTE_1_IP}    crudini
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Install Rpm Package     ${OS_COMPUTE_2_IP}    crudini

Get MemCached
    [Documentation]      Install memcached in all Control Nodes
    Install Rpm Package    ${OS_CONTROL_1_IP}     memcached python-memcached
    Crudini Edit     ${OS_CONTROL_1_IP}    /etc/sysconfig/memcached      ''      OPTIONS     "-l127.0.0.1,::1,${OS_CONTROL_1_IP}"
    Enable Service     ${OS_CONTROL_1_IP}     memcached
    Start Service     ${OS_CONTROL_1_IP}     memcached
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${OS_CONTROL_2_IP}    memcached python-memcached
    Crudini Edit     ${OS_CONTROL_2_IP}    /etc/sysconfig/memcached      ''      OPTIONS     "-l127.0.0.1,::1,${OS_CONTROL_2_IP}"
    Enable Service     ${OS_CONTROL_2_IP}     memcached
    Start Service     ${OS_CONTROL_2_IP}     memcached
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${OS_CONTROL_3_IP}    memcached python-memcached
    Crudini Edit     ${OS_CONTROL_3_IP}    /etc/sysconfig/memcached      ''      OPTIONS     "-l127.0.0.1,::1,${OS_CONTROL_3_IP}"
    Enable Service     ${OS_CONTROL_3_IP}     memcached
    Start Service     ${OS_CONTROL_3_IP}     memcached
   
Install HAProxy
    [Documentation]      Install HAProxy on a VM and configure the basic setting
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${HAPROXY_IP}    haproxy
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Move File     ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       /etc/haproxy/haproxy.cfg_bkp
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Touch File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Write To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "global"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " chroot /var/lib/haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " daemon"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " group haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " maxconn 4000"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " pidfile /var/run/haproxy.pid"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " user haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       $'\n'
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "defaults"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " log global"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " maxconn 4000"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " option redispatch"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " retries 3"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " timeout http-request 10s"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " timeout queue 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " timeout connect 10s"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " timeout client 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " timeout server 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " timeout check 10s"

Install OSC For Testing
    [Documentation]      Install Openstack Client for testing with Robot
    Run Keyword If     '${OPENSTACK_VERSION}' == 'ocata'      Local Install Rpm Package         centos-release-openstack-ocata
    Run Keyword If     '${OPENSTACK_VERSION}' == 'pike'      Local Install Rpm Package          centos-release-openstack-pike
    Local Install Rpm Package          python-openstackclient
    
Install ODL
    Install Rpm Package     ${OS_CONTROL_1_IP}    ${ODL_RPM}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${OS_CONTROL_2_IP}    ${ODL_RPM} 
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${OS_CONTROL_3_IP}    ${ODL_RPM} 
    Install Feature as Boot     ${OS_CONTROL_1_IP}     odl-netvirt-openstack
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Feature as Boot      ${OS_CONTROL_2_IP}     odl-netvirt-openstack
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Feature as Boot      ${OS_CONTROL_3_IP}     odl-netvirt-openstack
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Configure ODL Clustering     ${OS_CONTROL_1_IP}     1
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Configure ODL Clustering     ${OS_CONTROL_2_IP}     2
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Configure ODL Clustering     ${OS_CONTROL_3_IP}     3
    Enable Service    ${OS_CONTROL_1_IP}     opendaylight
    Start Service    ${OS_CONTROL_1_IP}     opendaylight
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Enable Service    ${OS_CONTROL_2_IP}     opendaylight
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Start Service    ${OS_CONTROL_2_IP}     opendaylight
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Enable Service    ${OS_CONTROL_3_IP}     opendaylight
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Start Service    ${OS_CONTROL_3_IP}     opendaylight
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Generic HAProxy Entry      ${HAPROXY_IP}     ${HAPROXY_IP}    8181     odl_rest 
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Generic HAProxy Entry      ${HAPROXY_IP}     ${HAPROXY_IP}    8080     odl_neutron 

*** Keywords ***
Create Etc Hosts
    [Arguments]    ${os_node_cxn}
    [Documentation]       Create a hosts file
    Write To File     ${os_node_cxn}     /etc/hosts      "127.0.0.1 localhost" 
    Append To File     ${os_node_cxn}     /etc/hosts      "${OS_CONTROL_1_IP} ${OS_CONTROL_1_HOSTNAME}"
    Run Keyword If    1 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    "${OS_CONTROL_2_IP} ${OS_CONTROL_2_HOSTNAME}"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    "${OS_CONTROL_3_IP} ${OS_CONTROL_3_HOSTNAME}"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    "${HAPROXY_IP} ${HAPROXY_HOSTNAME}"
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    "${OS_COMPUTE_1_IP} ${OS_COMPUTE_1_HOSTNAME}" 
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    "${OS_COMPUTE_2_IP} ${OS_COMPUTE_2_HOSTNAME}" 

Setup Chrony
    [Arguments]    ${os_node_cxn}
    [Documentation]       Install and configure chrony
    Install Rpm Package   ${os_node_cxn}    chrony 
    Append To File   ${os_node_cxn}     /etc/chrony.conf     "allow 0.0.0.0"
    Enable Service   ${os_node_cxn}    chronyd.service
    Start Service   ${os_node_cxn}    chronyd.service

Install Openstack Base Rpm
    [Arguments]    ${os_node_cxn}
    [Documentation]       Install the Openstack release
    Run Keyword If     '${OPENSTACK_VERSION}' == 'ocata'      Install Rpm Package     ${os_node_cxn}     centos-release-openstack-ocata
    Run Keyword If     '${OPENSTACK_VERSION}' == 'pike'      Install Rpm Package     ${os_node_cxn}     centos-release-openstack-pike
