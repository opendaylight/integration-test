*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND      OpenstackInstallUtils.Open All Ssh Connections
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OpenStackInstallUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SystemUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Test Cases ***
Disable SeLinux
    [Documentation]    Disable SeLinux in All nodes
    Disable SeLinux Tempororily    ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Disable SeLinux Tempororily    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Disable SeLinux Tempororily    ${OS_CONTROL_3_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Disable SeLinux Tempororily    ${HAPROXY_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Disable SeLinux Tempororily    ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Disable SeLinux Tempororily    ${OS_COMPUTE_2_IP}

Stop Firewall
    [Documentation]    Stop Firewalld and disable
    Stop And Disable Firewall    ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Stop And Disable Firewall    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Stop And Disable Firewall    ${OS_CONTROL_3_IP}
    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Stop And Disable Firewall    ${HAPROXY_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Stop And Disable Firewall    ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Stop And Disable Firewall    ${OS_COMPUTE_2_IP}

Create Etc Hosts Entries
    [Documentation]     Create Etc Hosts Entries
    Create Etc Hosts    ${OS_CONTROL_1_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${OS_CONTROL_3_IP}
    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Create Etc Hosts    ${HAPROXY_IP}
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
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Install Rpm Package     ${OS_COMPUTE_1_IP}    crudini


Get MemCached
    [Documentation]      Install memcached in all Control Nodes
    Install Rpm Package    ${OS_CONTROL_1_IP}     memcached python-memcached
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${OS_CONTROL_2_IP}    memcached python-memcached
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${OS_CONTROL_3_IP}    memcached python-memcached
   

Install HAProxy
    [Documentation]      Install HAProxy on a VM and configure the basic setting
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${HAPROXY_IP}    haproxy
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Move File     ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       /etc/haproxy/haproxy.cfg_bkp
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Touch File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Write To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "global"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " chroot  /var/lib/haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " daemon"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " group haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " maxconn 4000"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " pidfile  /var/run/haproxy.pid"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " user  haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       $'\n'
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "defaults"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " log global"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " maxconn 4000"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " option redispatch"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       " retries 3"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "  timeout  http-request 10s"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "  timeout  queue 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "  timeout  connect 10s"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "  timeout  client 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "  timeout  server 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_IP}    /etc/haproxy/haproxy.cfg       "  timeout  check 10s"
    

*** Keywords ***
Create Etc Hosts
    [Arguments]    ${os_node_cxn}
    [Documentation]       Create a hosts file
    ${entry}=    Set Variable     "${OS_CONTROL_1_IP}   ${OS_CONTROL_1_HOSTNAME}"
    Write To File     ${os_node_cxn}     /etc/hosts      ${entry}
    ${entry}=     Run Keyword If    1 < ${NUM_CONTROL_NODES}     Set Variable     "${OS_CONTROL_2_IP}   ${OS_CONTROL_2_HOSTNAME}"
    Run Keyword If    1 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}
    ${entry}=     Run Keyword If    2 < ${NUM_CONTROL_NODES}     Set Variable     "${OS_CONTROL_3_IP}   ${OS_CONTROL_3_HOSTNAME}"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}
    ${entry}=     Run Keyword If    2 < ${NUM_CONTROL_NODES}     Set Variable     "${HAPROXY_IP}   ${HAPROXY_HOSTNAME}"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}
    ${entry}=     Run Keyword If    0 < ${NUM_COMPUTE_NODES}     Set Variable     "${OS_COMPUTE_1_IP}   ${OS_COMPUTE_1_HOSTNAME}"
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}
    ${entry}=     Run Keyword If    1 < ${NUM_COMPUTE_NODES}     Set Variable     "${OS_COMPUTE_2_IP}   ${OS_COMPUTE_1_HOSTNAME}"
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}

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

