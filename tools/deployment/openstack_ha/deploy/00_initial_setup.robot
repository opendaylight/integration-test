*** Settings ***
Documentation       Test suite to verify packet flows between vm instances.

Library             SSHLibrary
Library             OperatingSystem
Resource            ../libraries/OpenStackInstallUtils.robot
Resource            ../libraries/SystemUtils.robot
Resource            ../libraries/OpendaylightInstallUtils.robot

Suite Setup         OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown      Close All Connections


*** Test Cases ***
Stop Firewall
    [Documentation]    Stop Firewalld and disable
    Stop And Disable Firewall    ${OS_CONTROL_1_IP}
    IF    1 < ${NUM_CONTROL_NODES}
        Stop And Disable Firewall    ${OS_CONTROL_2_IP}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Stop And Disable Firewall    ${OS_CONTROL_3_IP}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Stop And Disable Firewall    ${OS_CONTROL_4_IP}
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Stop And Disable Firewall    ${OS_CONTROL_5_IP}
    END
    IF    2 < ${NUM_CONTROL_NODES}    Stop And Disable Firewall    ${HAPROXY_IP}
    IF    0 < ${NUM_COMPUTE_NODES}
        Stop And Disable Firewall    ${OS_COMPUTE_1_IP}
    END
    IF    1 < ${NUM_COMPUTE_NODES}
        Stop And Disable Firewall    ${OS_COMPUTE_2_IP}
    END

Create Etc Hosts Entries
    [Documentation]    Create Etc Hosts Entries
    Create Etc Hosts    ${OS_CONTROL_1_IP}
    IF    1 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${OS_CONTROL_2_IP}
    IF    2 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${OS_CONTROL_3_IP}
    IF    3 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${OS_CONTROL_4_IP}
    IF    4 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${OS_CONTROL_5_IP}
    IF    2 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${HAPROXY_IP}
    IF    0 < ${NUM_COMPUTE_NODES}    Create Etc Hosts    ${OS_COMPUTE_1_IP}
    IF    1 < ${NUM_COMPUTE_NODES}    Create Etc Hosts    ${OS_COMPUTE_2_IP}
    Create Etc Hosts In RobotVM

Update the Distro
    [Documentation]    Always Better to run yum update first :-)
    Pass Execution If    '${UPGRADE_REQUIRED}' == 'no'    "No need to do yum update in CSIT"
    Update Packages    ${OS_CONTROL_1_IP}
    IF    1 < ${NUM_CONTROL_NODES}    Update Packages    ${OS_CONTROL_2_IP}
    IF    2 < ${NUM_CONTROL_NODES}    Update Packages    ${OS_CONTROL_3_IP}
    IF    3 < ${NUM_CONTROL_NODES}    Update Packages    ${OS_CONTROL_4_IP}
    IF    4 < ${NUM_CONTROL_NODES}    Update Packages    ${OS_CONTROL_5_IP}
    IF    2 < ${NUM_CONTROL_NODES}    Update Packages    ${HAPROXY_IP}
    IF    0 < ${NUM_COMPUTE_NODES}    Update Packages    ${OS_COMPUTE_1_IP}
    IF    1 < ${NUM_COMPUTE_NODES}    Update Packages    ${OS_COMPUTE_2_IP}

Get Package List
    [Documentation]    Get List of PAckages Installed
    Run Command    ${OS_CONTROL_1_IP}    sudo yum list installed
    Run Command    ${OS_COMPUTE_1_IP}    sudo yum list installed
    Run Command    ${OS_COMPUTE_2_IP}    sudo yum list installed

Get Chrony
    [Documentation]    Install Chrony
    Setup Chrony    ${OS_CONTROL_1_IP}
    IF    1 < ${NUM_CONTROL_NODES}    Setup Chrony    ${OS_CONTROL_2_IP}
    IF    2 < ${NUM_CONTROL_NODES}    Setup Chrony    ${OS_CONTROL_3_IP}
    IF    3 < ${NUM_CONTROL_NODES}    Setup Chrony    ${OS_CONTROL_4_IP}
    IF    4 < ${NUM_CONTROL_NODES}    Setup Chrony    ${OS_CONTROL_5_IP}
    IF    0 < ${NUM_COMPUTE_NODES}    Setup Chrony    ${OS_COMPUTE_1_IP}
    IF    1 < ${NUM_COMPUTE_NODES}    Setup Chrony    ${OS_COMPUTE_2_IP}

Install Openstack Base Repo
    [Documentation]    Install Openstack Release Repo
    Pass Execution If    '${OS_APPS_PRE_INSTALLED}' == 'yes'    "Already installed in Image"
    Install Openstack Base Rpm    ${OS_CONTROL_1_IP}
    IF    1 < ${NUM_CONTROL_NODES}
        Install Openstack Base Rpm    ${OS_CONTROL_2_IP}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Openstack Base Rpm    ${OS_CONTROL_3_IP}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Install Openstack Base Rpm    ${OS_CONTROL_4_IP}
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Install Openstack Base Rpm    ${OS_CONTROL_5_IP}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Openstack Base Rpm    ${HAPROXY_IP}
    END
    IF    0 < ${NUM_COMPUTE_NODES}
        Install Openstack Base Rpm    ${OS_COMPUTE_1_IP}
    END
    IF    1 < ${NUM_COMPUTE_NODES}
        Install Openstack Base Rpm    ${OS_COMPUTE_2_IP}
    END

Get Crudini
    [Documentation]    Install Crudini in all the Openstack nodes
    Pass Execution If    '${OS_APPS_PRE_INSTALLED}' == 'yes'    "Already Installed"
    Install Rpm Package    ${OS_CONTROL_1_IP}    crudini
    IF    1 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${OS_CONTROL_2_IP}    crudini
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${OS_CONTROL_3_IP}    crudini
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${OS_CONTROL_4_IP}    crudini
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${OS_CONTROL_5_IP}    crudini
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${HAPROXY_IP}    crudini
    END
    IF    0 < ${NUM_COMPUTE_NODES}
        Install Rpm Package    ${OS_COMPUTE_1_IP}    crudini
    END
    IF    1 < ${NUM_COMPUTE_NODES}
        Install Rpm Package    ${OS_COMPUTE_2_IP}    crudini
    END

Get MemCached
    [Documentation]    Install memcached in all Control Nodes
    IF    '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${OS_CONTROL_1_IP}    memcached python-memcached
    END
    Crudini Edit
    ...    ${OS_CONTROL_1_IP}
    ...    /etc/sysconfig/memcached
    ...    ''
    ...    OPTIONS
    ...    "-l127.0.0.1,::1,${OS_CONTROL_1_IP}"
    Enable Service    ${OS_CONTROL_1_IP}    memcached
    Start Service    ${OS_CONTROL_1_IP}    memcached
    IF    1 < ${NUM_CONTROL_NODES} and '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${OS_CONTROL_2_IP}    memcached python-memcached
    END
    IF    1 < ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${OS_CONTROL_2_IP}
        ...    /etc/sysconfig/memcached
        ...    ''
        ...    OPTIONS
        ...    "-l127.0.0.1,::1,${OS_CONTROL_2_IP}"
    END
    IF    1 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_2_IP}    memcached
    END
    IF    1 < ${NUM_CONTROL_NODES}
        Start Service    ${OS_CONTROL_2_IP}    memcached
    END
    IF    2 < ${NUM_CONTROL_NODES} and '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${OS_CONTROL_3_IP}    memcached python-memcached
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${OS_CONTROL_3_IP}
        ...    /etc/sysconfig/memcached
        ...    ''
        ...    OPTIONS
        ...    "-l127.0.0.1,::1,${OS_CONTROL_3_IP}"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_3_IP}    memcached
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Start Service    ${OS_CONTROL_3_IP}    memcached
    END
    IF    3 < ${NUM_CONTROL_NODES} and '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${OS_CONTROL_4_IP}    memcached python-memcached
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${OS_CONTROL_4_IP}
        ...    /etc/sysconfig/memcached
        ...    ''
        ...    OPTIONS
        ...    "-l127.0.0.1,::1,${OS_CONTROL_3_IP}"
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_4_IP}    memcached
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Start Service    ${OS_CONTROL_4_IP}    memcached
    END
    IF    4 < ${NUM_CONTROL_NODES} and '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${OS_CONTROL_5_IP}    memcached python-memcached
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Crudini Edit
        ...    ${OS_CONTROL_5_IP}
        ...    /etc/sysconfig/memcached
        ...    ''
        ...    OPTIONS
        ...    "-l127.0.0.1,::1,${OS_CONTROL_3_IP}"
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_5_IP}    memcached
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Start Service    ${OS_CONTROL_5_IP}    memcached
    END

Install HAProxy
    [Documentation]    Install HAProxy on a VM and configure the basic setting
    IF    2 < ${NUM_CONTROL_NODES} and '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${HAPROXY_IP}    haproxy
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Move File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    /etc/haproxy/haproxy.cfg_bkp
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Touch File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Write To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    "global"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " chroot /var/lib/haproxy"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " daemon"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " group haproxy"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " maxconn 4000"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " pidfile /var/run/haproxy.pid"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " user haproxy"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    $'\n'
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    "defaults"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " log global"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " maxconn 4000"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " option redispatch"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " retries 3"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " timeout http-request 10s"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " timeout queue 1m"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " timeout connect 10s"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " timeout client 1m"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " timeout server 1m"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg    " timeout check 10s"
    END
    IF    2 < ${NUM_CONTROL_NODES} and '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${HAPROXY_IP}    "nfs-utils"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Run Command    ${HAPROXY_IP}    sudo mkdir -p /images;sudo chmod -R 777 /images
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Run Command    ${HAPROXY_IP}    sudo mkdir -p /instances;sudo chmod -R 777 /instances
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Write To File    ${HAPROXY_IP}    /etc/exports    /images *\\(rw,no_root_squash\\)
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${HAPROXY_IP}    /etc/exports    /instances *\\(rw,no_root_squash\\)
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Enable Service    ${HAPROXY_IP}    rpcbind nfs-server
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Start Service    ${HAPROXY_IP}    rpcbind nfs-server
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Run Command    ${HAPROXY_IP}    sudo exportfs
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Restart Service    ${HAPROXY_IP}    rpcbind nfs-server
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Run Command    ${HAPROXY_IP}    sudo exportfs
    END

Create NFS Share for VM Live Migration Tests
    Pass Execution If    2 < ${NUM_CONTROL_NODES}    "Will Be Configured in HAProxy Node"
    Local Install Rpm Package    "nfs-utils"
    Run Command In Local Node    sudo mkdir -p /instances;sudo chmod -R 777 /instances
    Write To Local File    /etc/exports    /instances *\\(rw,no_root_squash\\)
    Run Command In Local Node    sudo systemctl enable rpcbind nfs-server
    Run Command In Local Node    sudo systemctl start rpcbind nfs-server
    Run Command In Local Node    sudo exportfs

Install OSC For Testing
    [Documentation]    Install Openstack Client for testing with Robot
    IF    '${OPENSTACK_VERSION}' == 'ocata'
        Local Install Rpm Package    centos-release-openstack-ocata
    END
    IF    '${OPENSTACK_VERSION}' == 'pike'
        Local Install Rpm Package    centos-release-openstack-pike
    END
    Local Install Rpm Package    python-openstackclient

Install ODL From CBS or Nexus
    Pass Execution If    '${ODL_INSTALL_LOCAL_RPM}' == 'yes'    "Do Not Download from Nexus or cbs"
    Install Rpm Package    ${OS_CONTROL_1_IP}    ${ODL_RPM}
    IF    1 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${OS_CONTROL_2_IP}    ${ODL_RPM}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${OS_CONTROL_3_IP}    ${ODL_RPM}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${OS_CONTROL_4_IP}    ${ODL_RPM}
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Install Rpm Package    ${OS_CONTROL_5_IP}    ${ODL_RPM}
    END
    Install Feature as Boot    ${OS_CONTROL_1_IP}    odl-netvirt-openstack
    IF    1 < ${NUM_CONTROL_NODES}
        Install Feature as Boot    ${OS_CONTROL_2_IP}    odl-netvirt-openstack
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Feature as Boot    ${OS_CONTROL_3_IP}    odl-netvirt-openstack
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Install Feature as Boot    ${OS_CONTROL_4_IP}    odl-netvirt-openstack
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Install Feature as Boot    ${OS_CONTROL_5_IP}    odl-netvirt-openstack
    END
    Configure SNAT MODE In Odl    ${OS_CONTROL_1_IP}
    IF    1 < ${NUM_CONTROL_NODES}
        Configure SNAT MODE In Odl    ${OS_CONTROL_2_IP}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Configure SNAT MODE In Odl    ${OS_CONTROL_3_IP}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Configure SNAT MODE In Odl    ${OS_CONTROL_4_IP}
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Configure SNAT MODE In Odl    ${OS_CONTROL_5_IP}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_1_IP}    1
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_2_IP}    2
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_3_IP}    3
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_4_IP}    4
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_5_IP}    5
    END
    Enable Service    ${OS_CONTROL_1_IP}    opendaylight
    Start Service    ${OS_CONTROL_1_IP}    opendaylight
    IF    1 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_2_IP}    opendaylight
    END
    IF    1 < ${NUM_CONTROL_NODES}
        Start Service    ${OS_CONTROL_2_IP}    opendaylight
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_3_IP}    opendaylight
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Start Service    ${OS_CONTROL_3_IP}    opendaylight
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_4_IP}    opendaylight
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_5_IP}    opendaylight
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    8181    odl_rest
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    8080    odl_neutron
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    8185    odl_websocket
    END

Install ODL From Local Rpm
    Pass Execution If    '${ODL_INSTALL_LOCAL_RPM}' == 'no'    "Installed from Cbs or Nexus"
    Install Local Rpm Package    ${OS_CONTROL_1_IP}    ${ODL_RPM}
    IF    1 < ${NUM_CONTROL_NODES}
        Install Local Rpm Package    ${OS_CONTROL_2_IP}    ${ODL_RPM}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Local Rpm Package    ${OS_CONTROL_3_IP}    ${ODL_RPM}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Install Local Rpm Package    ${OS_CONTROL_4_IP}    ${ODL_RPM}
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Install Local Rpm Package    ${OS_CONTROL_5_IP}    ${ODL_RPM}
    END
    Install Feature as Boot    ${OS_CONTROL_1_IP}    odl-netvirt-openstack
    IF    1 < ${NUM_CONTROL_NODES}
        Install Feature as Boot    ${OS_CONTROL_2_IP}    odl-netvirt-openstack
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Install Feature as Boot    ${OS_CONTROL_3_IP}    odl-netvirt-openstack
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Install Feature as Boot    ${OS_CONTROL_4_IP}    odl-netvirt-openstack
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Install Feature as Boot    ${OS_CONTROL_5_IP}    odl-netvirt-openstack
    END
    Configure SNAT MODE In Odl    ${OS_CONTROL_1_IP}
    IF    1 < ${NUM_CONTROL_NODES}
        Configure SNAT MODE In Odl    ${OS_CONTROL_2_IP}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Configure SNAT MODE In Odl    ${OS_CONTROL_3_IP}
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Configure SNAT MODE In Odl    ${OS_CONTROL_4_IP}
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Configure SNAT MODE In Odl    ${OS_CONTROL_5_IP}
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_1_IP}    1
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_2_IP}    2
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_3_IP}    3
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_4_IP}    4
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Configure ODL Clustering    ${OS_CONTROL_5_IP}    5
    END
    Enable Service    ${OS_CONTROL_1_IP}    opendaylight
    Start Service    ${OS_CONTROL_1_IP}    opendaylight
    IF    1 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_2_IP}    opendaylight
    END
    IF    1 < ${NUM_CONTROL_NODES}
        Start Service    ${OS_CONTROL_2_IP}    opendaylight
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_3_IP}    opendaylight
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Start Service    ${OS_CONTROL_3_IP}    opendaylight
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_4_IP}    opendaylight
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Enable Service    ${OS_CONTROL_5_IP}    opendaylight
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    8181    odl_rest
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    8080    odl_neutron
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Generic HAProxy Entry    ${HAPROXY_IP}    ${HAPROXY_IP}    8185    odl_websocket
    END


*** Keywords ***
Create Etc Hosts
    [Documentation]    Create a hosts file
    [Arguments]    ${os_node_cxn}
    Write To File    ${os_node_cxn}    /etc/hosts    "127.0.0.1 localhost"
    Append To File    ${os_node_cxn}    /etc/hosts    "${OS_CONTROL_1_IP} ${OS_CONTROL_1_HOSTNAME}"
    IF    1 < ${NUM_CONTROL_NODES}
        Append To File    ${os_node_cxn}    /etc/hosts    "${OS_CONTROL_2_IP} ${OS_CONTROL_2_HOSTNAME}"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${os_node_cxn}    /etc/hosts    "${OS_CONTROL_3_IP} ${OS_CONTROL_3_HOSTNAME}"
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Append To File    ${os_node_cxn}    /etc/hosts    "${OS_CONTROL_4_IP} ${OS_CONTROL_4_HOSTNAME}"
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Append To File    ${os_node_cxn}    /etc/hosts    "${OS_CONTROL_5_IP} ${OS_CONTROL_5_HOSTNAME}"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To File    ${os_node_cxn}    /etc/hosts    "${HAPROXY_IP} ${HAPROXY_HOSTNAME}"
    END
    IF    0 < ${NUM_COMPUTE_NODES}
        Append To File    ${os_node_cxn}    /etc/hosts    "${OS_COMPUTE_1_IP} ${OS_COMPUTE_1_HOSTNAME}"
    END
    IF    1 < ${NUM_COMPUTE_NODES}
        Append To File    ${os_node_cxn}    /etc/hosts    "${OS_COMPUTE_2_IP} ${OS_COMPUTE_2_HOSTNAME}"
    END

Create Etc Hosts In RobotVM
    [Documentation]    Create a hosts file
    Write To Local File    /etc/hosts    "127.0.0.1 localhost"
    Append To Local File    /etc/hosts    "${OS_CONTROL_1_IP} ${OS_CONTROL_1_HOSTNAME}"
    IF    1 < ${NUM_CONTROL_NODES}
        Append To Local File    /etc/hosts    "${OS_CONTROL_2_IP} ${OS_CONTROL_2_HOSTNAME}"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To Local File    /etc/hosts    "${OS_CONTROL_3_IP} ${OS_CONTROL_3_HOSTNAME}"
    END
    IF    3 < ${NUM_CONTROL_NODES}
        Append To Local File    /etc/hosts    "${OS_CONTROL_4_IP} ${OS_CONTROL_4_HOSTNAME}"
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Append To Local File    /etc/hosts    "${OS_CONTROL_5_IP} ${OS_CONTROL_5_HOSTNAME}"
    END
    IF    2 < ${NUM_CONTROL_NODES}
        Append To Local File    /etc/hosts    "${HAPROXY_IP} ${HAPROXY_HOSTNAME}"
    END
    IF    0 < ${NUM_COMPUTE_NODES}
        Append To Local File    /etc/hosts    "${OS_COMPUTE_1_IP} ${OS_COMPUTE_1_HOSTNAME}"
    END
    IF    1 < ${NUM_COMPUTE_NODES}
        Append To Local File    /etc/hosts    "${OS_COMPUTE_2_IP} ${OS_COMPUTE_2_HOSTNAME}"
    END

Setup Chrony
    [Documentation]    Install and configure chrony
    [Arguments]    ${os_node_cxn}
    IF    '${OS_APPS_PRE_INSTALLED}' == 'no'
        Install Rpm Package    ${os_node_cxn}    chrony
    END
    Append To File    ${os_node_cxn}    /etc/chrony.conf    "allow 0.0.0.0"
    Enable Service    ${os_node_cxn}    chronyd.service
    Start Service    ${os_node_cxn}    chronyd.service

Install Openstack Base Rpm
    [Documentation]    Install the Openstack release
    [Arguments]    ${os_node_cxn}
    Pass Execution If    '${OS_APPS_PRE_INSTALLED}' == 'yes'    "Already Installd"
    IF    '${OPENSTACK_VERSION}' == 'ocata'
        Install Rpm Package    ${os_node_cxn}    centos-release-openstack-ocata
    END
    IF    '${OPENSTACK_VERSION}' == 'pike'
        Install Rpm Package    ${os_node_cxn}    centos-release-openstack-pike
    END

Configure SNAT MODE In Odl
    [Arguments]    ${os_node_cxn}
    Run Command    ${os_node_cxn}    sudo mkdir -p /opt/opendaylight/etc/opendaylight/datastore/initial/config/
    Touch File
    ...    ${os_node_cxn}
    ...    /opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml
    Write To File
    ...    ${os_node_cxn}
    ...    /opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml
    ...    '<natservice-config xmlns="urn:opendaylight:netvirt:natservice:config">'
    Append To File
    ...    ${os_node_cxn}
    ...    /opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml
    ...    '<nat-mode>${ODL_NETVIRT_SNAT_MODE}</nat-mode>'
    Append To File
    ...    ${os_node_cxn}
    ...    /opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml
    ...    '</natservice-config>'
    Run Command    ${os_node_cxn}    sudo chown -R odl:odl /opt/opendaylight/
