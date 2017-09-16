*** Settings ***
Documentation     Test suite to destroy Openstack Deployment
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Resource          ../../../libraries/OpenStackInstallUtils.robot
Resource          ../../../libraries/SystemUtils.robot
Resource          ../../../libraries/OpendaylightInstallUtils.robot

*** Test Cases ***
Destroy Setup
    [Documentation]    Delete Openstack From All Nodes
    Destroy Openstack    ${OS_CONTROL_1_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Destroy Openstack    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Destroy Openstack    ${OS_CONTROL_3_IP}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Destroy Openstack    ${OS_CONTROL_4_IP}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Destroy Openstack    ${OS_CONTROL_5_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Destroy Openstack    ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Destroy Openstack    ${OS_COMPUTE_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Destroy Openstack    ${HAPROXY_IP}
    Run Command In Local Node      sudo ip netns delete flat1
    Run Command In Local Node      sudo ip netns delete flat2
    Run Command In Local Node      sudo ip netns delete physnet1
    Run Command In Local Node      sudo ip netns delete vlantest
    Run Command In Local Node      sudo yum remove -y openvswitch
    Run Command In Local Node      sudo rm -rf /etc/openvswitch

*** Keywords ***
Destroy Openstack
    [Arguments]    ${os_node_cxn}
    [Documentation]    Removes Packages and Openstack directories
    Run Command    ${os_node_cxn}    sudo yum remove -y nrpe "*nagios*" puppet "*ntp*" "*openstack*" "*libvirt*"
    Run Command    ${os_node_cxn}    sudo yum remove -y "*nova*" "*keystone*" "*glance*" "*cinder*" "*swift*" "*neutron*"
    Run Command    ${os_node_cxn}    sudo yum remove -y mysql mysql-server httpd "*memcache*" scsi-target-utils "*galera*"
    Run Command    ${os_node_cxn}    sudo yum remove -y iscsi-initiator-utils perl-DBI perl-DBD-MySQL openvswitch "*rabbit*" rsync
    Run Command    ${os_node_cxn}    sudo yum remove -y haproxy opendaylight
    Run Command    ${os_node_cxn}    sudo rm -rf /etc/nagios /etc/yum.repos.d/packstack_* /root/.my.cnf
    Run Command    ${os_node_cxn}    sudo rm -rf /etc/my.cnf.d /var/lib/mysql/ /var/lib/nova /etc/nova /etc/swift /etc/keystone /etc/haproxy /etc/openvswitch /etc/httpd /var/lib/rabbitmq /etc/neutron /var/lib/libvirt* /var/log/libvirt* /etc/libvirt*
    Run Command    ${os_node_cxn}    sudo rm -rf /var/log/nova /var/log/neutron /var/log/rabbitmq /var/log/mariadb
    Run Command    ${os_node_cxn}    sudo rm -rf /var/lib/mysql/ /var/lib/nova /etc/nova /etc/swift
    Run Command    ${os_node_cxn}    sudo rm -rf /srv/node/device*/* /var/lib/cinder/ /etc/rsync.d/frag*
    Run Command    ${os_node_cxn}    sudo rm -rf /var/cache/swift /var/log/keystone /var/log/cinder/ /var/log/nova/
    Run Command    ${os_node_cxn}    sudo rm -rf /var/log/httpd /var/log/glance/ /var/log/nagios/ /var/log/quantum/ /etc/openvswitch
    #Run Command    ${os_node_cxn}    sudo userdel jenkins
    Run Command    ${os_node_cxn}    sudo rm -rf /home/jenkins
    Run Command    ${os_node_cxn}    sudo shutdown -r
