*** Settings ***
Documentation     Test suite to install ODL with netvirt feature and ensure of services are up.
...               To Be used with the Deployer
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           OperatingSystem
Library           RequestsLibrary
Library           Xml
Resource          ../libraries/Utils.robot
Resource          ../libraries/OpenStackInstallUtils.robot
Resource          ../libraries/OpendaylightInstallUtils.robot
Resource          ../libraries/SystemUtils.robot

*** Test Cases ***
Get ODL
    [Documentation]    Get ODL from Nexus or Install from rpm
    Install Rpm Package    ${OS_CONTROL_IP}    ${ODL_RPM}

Configure Netvirt Feature as Boot
    [Documentation]    Install Netvirt feature
     Install Feature as Boot    ${OS_CONTROL_1_IP}    odl-netvirt-openstack

Configure SNAT Mode
    [Documentation]    Configure SNAT Mode as Required
    Configure SNAT MODE In Odl    ${OS_CONTROL_1_IP}

Start ODL In All Nodes
    [Documentation]    Start ODL Service
    Start Service    ${OS_CONTROL_1_IP}    opendaylight

Check If Netvirt Is Up And Running
    [Documentation]    Check If ODL Is Running and Active
    

*** Keywords ***
Configure SNAT MODE In Odl
    [Arguments]    ${os_node_cxn}
    Run Command    ${os_node_cxn}    sudo mkdir -p /opt/opendaylight/etc/opendaylight/datastore/initial/config/
    Touch File    ${os_node_cxn}    /opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml
    Write To File    ${os_node_cxn}    /opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    '<natservice-config xmlns="urn:opendaylight:netvirt:natservice:config">'
    Append To File    ${os_node_cxn}    /opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    '<nat-mode>${ODL_NETVIRT_SNAT_MODE}</nat-mode>'
    Append To File    ${os_node_cxn}    /opt/opendaylight/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    '</natservice-config>'
    Run Command    ${os_node_cxn}    sudo chown -R odl:odl /opt/opendaylight/

Check If Ports Are Up
    [Arguments]    ${os_node_cxn}
    
