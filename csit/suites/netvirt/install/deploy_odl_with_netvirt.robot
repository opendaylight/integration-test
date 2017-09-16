*** Settings ***
Documentation     Test suite to install ODL with netvirt feature and ensure of services are up.
...               To Be used with the Deployer
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           OperatingSystem
Library           RequestsLibrary
Library           Xml
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackInstallUtils.robot
Resource          ../../../libraries/OpendaylightInstallUtils.robot
Resource          ../../../libraries/SystemUtils.robot

*** Test Cases ***
Get ODL
    [Documentation]    Get ODL from Nexus or Install from rpm
    Run Keyword If    '${ODL_INSTALL_MODE}' == 'RPM'    Install ODL From RPM In All ODL Nodes    ${ODL_RPM}
    Run Keyword If    '${ODL_INSTALL_MODE}' == 'ZIP'    Install ODL From ZIP In All ODL Nodes    ${ACTUAL_BUNDLE_URL}    ${BUNDLEFOLDER}

Configure Netvirt Feature as Boot
    [Documentation]    Install Netvirt feature
    Install ODL Feature In All ODL Nodes    odl-netvirt-openstack

Configure Clustering
    Run Keyword If    2 < ${NUM_ODL_NODES}    Configure ODL Clustering

Configure SNAT Mode
    [Documentation]    Configure SNAT Mode as Required
    Configure SNAT Mode In All ODL Nodes    ${ODL_NAME_MODE}

Start ODL In All Nodes
    [Documentation]    Start ODL Service
    Start ODL In All ODL Nodes

Check If Netvirt Is Up And Running
    [Documentation]    Check If ODL Is Running and Active
    Check If ODL Is Running In All Nodes    operational/network-topology:network-topology/topology/netvirt:1
    Print All Active Ports

*** Keywords ***
Set SNAT Mode
    [Arguments]    ${os_node_cxn}
    [Documentation]    Configure SNAT Mode for Netvirt
    Add Element    ${XML}    <natservice-config></natservice-config>
    Set Element Attribute    ${XML}    xmlns    urn:opendaylight:netvirt:natservice:config    xpath=natservice-config
    Add Element    ${XML}    <nat-mode></nat-mode>    xpath=natservice-config
    Set Element Text    ${XML}    ${ODL_SNAT_MODE}    xpath=nat-mode
    Save Xml    ${XML}    /tmp/netvirt-natservice-config.xml

Configure SNAT Mode In All ODL Nodes
    [Documentation]    Configure SNAT Mode for Netvirt In All ODL Nodes
    Set SNAT Mode    ${ODL_1_IP}
    Run Keyword If    1 < ${NUM_ODL_NODES}    Set SNAT Mode    ${ODL_2_IP}
    Run Keyword If    2 < ${NUM_ODL_NODES}    Set SNAT Mode    ${ODL_3_IP}
    Run Keyword If    3 < ${NUM_ODL_NODES}    Set SNAT Mode    ${ODL_4_IP}
    Run Keyword If    4 < ${NUM_ODL_NODES}    Set SNAT Mode    ${ODL_5_IP}
