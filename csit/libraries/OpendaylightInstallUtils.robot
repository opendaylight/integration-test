*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Resource          SystemUtils.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot
Variables         ../variables/netvirt/Modules.py


*** Keywords ***
Install Feature as Boot
    [Arguments]    ${os_node_cxn}     ${feature_name}
    [Documentation]    This Keyword will add the feature to karaf features boot and ensure boot happens
    Switch Connection     ${os_node_cxn}  
    ${rc}    ${output}=    Run And Return Rc And Output    sudo crudini --set --list --list-set="," --inplace --verbose  /opt/opendaylight/etc/org.apache.karaf.features.cfg     ""      featuresBoot      ${feature-name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Configure ODL Clustering
    [Arguments]    ${os_node_cxn}     ${index}
    Switch Connection     ${os_node_cxn}  
    ${rc}    ${output}=    Run And Return Rc And Output    sudo /opt/opendaylight/bin/configure_cluster.sh ${index} ${CONTROL1_NODE_IP},${CONTROL2_NODE_IP},${CONTROL3_NODE_IP}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}
