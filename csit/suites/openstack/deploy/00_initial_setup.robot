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

Disable SeLinux
    [Documentation]    Disable SeLinux in All nodes
    Disable SeLinux Tempororily    ${CONTROL1_NODE_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Disable SeLinux Tempororily    ${CONTROL2_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Disable SeLinux Tempororily    ${CONTROL3_NODE_IP}
    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Disable SeLinux Tempororily    ${HAPROXY_NODE_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Disable SeLinux Tempororily    ${COMPUTE1_NODE_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Disable SeLinux Tempororily    ${COMPUTE2_NODE_IP}

Stop Firewall
    [Documentation]    Stop Firewalld and disable
    Stop And Disable Firewall    ${CONTROL1_NODE_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Stop And Disable Firewall    ${CONTROL2_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Stop And Disable Firewall    ${CONTROL3_NODE_IP}
    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Stop And Disable Firewall    ${HAPROXY_NODE_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Stop And Disable Firewall    ${COMPUTE1_NODE_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Stop And Disable Firewall    ${COMPUTE2_NODE_IP}

Create Etc Hosts Entries
    [Documentation]     Create Etc Hosts Entries
    Create Etc Hosts    ${CONTROL1_NODE_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${CONTROL2_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create Etc Hosts    ${CONTROL3_NODE_IP}
    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Create Etc Hosts    ${HAPROXY_NODE_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Create Etc Hosts    ${COMPUTE1_NODE_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Create Etc Hosts    ${COMPUTE2_NODE_IP}

Update the Distro
    [Documentation]      Always Better to run yum update first :-)
    Update Packages    ${CONTROL1_NODE_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Update Packages     ${CONTROL2_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Update Packages     ${CONTROL3_NODE_IP}
    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Update Packages     ${HAPROXY_NODE_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Update Packages     ${COMPUTE1_NODE_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Update Packages     ${COMPUTE2_NODE_IP}

Get Chrony
    [Documentation]      Install Chrony
    Setup Chrony     ${CONTROL1_NODE_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Setup Chrony     ${CONTROL2_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup Chrony     ${CONTROL3_NODE_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Setup Chrony     ${COMPUTE1_NODE_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Setup Chrony     ${COMPUTE2_NODE_IP}

Install Openstack Base Repo
    [Documentation]      Install Openstack Release Repo
    Install Openstack Base Rpm     ${CONTROL1_NODE_IP}
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Openstack Base Rpm     ${CONTROL2_NODE_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Openstack Base Rpm     ${CONTROL3_NODE_IP}
    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Install Openstack Base Rpm     ${HAPROXY_NODE_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Install Openstack Base Rpm     ${COMPUTE1_NODE_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Install Openstack Base Rpm     ${COMPUTE2_NODE_IP}

Get Crudini
    Install Rpm Package    ${CONTROL1_NODE_IP}     crudini
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${CONTROL2_NODE_IP}    crudini
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${CONTROL3_NODE_IP}    crudini
    Run Keyword If    0 < ${NUM_HAPROXY_NODES}    Install Rpm Package     ${HAPROXY_NODE_IP}     crudini
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Install Rpm Package     ${COMPUTE1_NODE_IP}    crudini
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Install Rpm Package     ${COMPUTE2_NODE_IP}    crudini


Get MemCached
    Install Rpm Package    ${CONTROL1_NODE_IP}     memcached python-memcached
    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${CONTROL2_NODE_IP}    memcached python-memcached
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${CONTROL3_NODE_IP}    memcached python-memcached
   

Install HAProxy
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Rpm Package     ${HAPROXY_NODE_IP}    haproxy
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Move File     ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       /etc/haproxy/haproxy.cfg_bkp
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Touch File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Write To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       "global"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " chroot  /var/lib/haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " daemon"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " group haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " maxconn 4000"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " pidfile  /var/run/haproxy.pid"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " user  haproxy"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       $'\n'
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       "defaults"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " log global"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " maxconn 4000"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " option redispatch"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       " retries 3"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       "  timeout  http-request 10s"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       "  timeout  queue 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       "  timeout  connect 10s"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       "  timeout  client 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       "  timeout  server 1m"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Append To File    ${HAPROXY_NODE_IP}    /etc/haproxy/haproxy.cfg       "  timeout  check 10s"

    

*** Keywords ***
Create Etc Hosts
    [Arguments]    ${os_node_cxn}
    ${entry}=    Set Variable     "${CONTROL1_NODE_IP}   ${CONTROL1_HOSTNAME}"
    Write To File     ${os_node_cxn}     /etc/hosts      ${entry}
    ${entry}=     Run Keyword If    1 < ${NUM_CONTROL_NODES}     Set Variable     "${CONTROL2_NODE_IP}   ${CONTROL2_HOSTNAME}"
    Run Keyword If    1 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}
    ${entry}=     Run Keyword If    2 < ${NUM_CONTROL_NODES}     Set Variable     "${CONTROL3_NODE_IP}   ${CONTROL3_HOSTNAME}"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}
    ${entry}=     Run Keyword If    0 < ${NUM_HAPROXY_NODES}     Set Variable     "${HAPROXY_NODE_IP}   ${HAPROXY_HOSTNAME}"
    Run Keyword If    2 < ${NUM_CONTROL_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}
    ${entry}=     Run Keyword If    0 < ${NUM_COMPUTE_NODES}     Set Variable     "${COMPUTE1_NODE_IP}   ${COMPUTE1_HOSTNAME}"
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}
    ${entry}=     Run Keyword If    1 < ${NUM_COMPUTE_NODES}     Set Variable     "${COMPUTE2_NODE_IP}   ${COMPUTE2_HOSTNAME}"
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}      Append To File     ${os_node_cxn}      /etc/hosts    ${entry}

Setup Chrony
    [Arguments]    ${os_node_cxn}
    Install Rpm Package   ${os_node_cxn}    chrony 
    Append To File   ${os_node_cxn}     /etc/chrony.conf     "allow 0.0.0.0"
    Enable Service   ${os_node_cxn}    chronyd.service
    Start Service   ${os_node_cxn}    chronyd.service

Install Openstack Base Rpm
    [Arguments]    ${os_node_cxn}
    Run Keyword If     '${OPENSTACK_VERSION}' == 'ocata'      Install Rpm Package     ${os_node_cxn}     centos-release-openstack-ocata
    Run Keyword If     '${OPENSTACK_VERSION}' == 'pike'      Install Rpm Package     ${os_node_cxn}     centos-release-openstack-pike

