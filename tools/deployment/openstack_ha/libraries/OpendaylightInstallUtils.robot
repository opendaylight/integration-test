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
Install Feature as Boot
    [Arguments]    ${os_node_cxn}    ${feature_name}
    [Documentation]    This Keyword will add the feature to karaf features boot and ensure boot happens
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo crudini --verbose --set --list --list-sep="," --inplace --verbose /opt/opendaylight/etc/org.apache.karaf.features.cfg "" featuresBoot ${feature_name}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Configure ODL Clustering
    [Arguments]    ${os_node_cxn}    ${index}
    Switch Connection    ${os_node_cxn}
    ${cmd}=    Set Variable If    4 > ${index}    sudo /opt/opendaylight/bin/configure_cluster.sh ${index} ${OS_CONTROL_1_IP},${OS_CONTROL_2_IP},${OS_CONTROL_3_IP}    sudo /opt/opendaylight/bin/configure_cluster.sh ${index} ${OS_CONTROL_1_IP},${OS_CONTROL_2_IP},${OS_CONTROL_3_IP},${OS_CONTROL_4_IP},${OS_CONTROL_5_IP}
    ${output}    ${rc}=    Execute Command    ${cmd}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    sed -ie 's/JAVA_MAX_MEM="2048m"/JAVA_MAX_MEM="6144m"/g' /opt/opendaylight/bin/setenv    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Install From Nexus
    [Arguments]    ${os_node_cxn}    ${nexus_url}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo wget ${ODL_ZIP_FROM_NEXUS} -O /tmp/ODL.zip
    Log    ${output}
    Should Not Be True    ${rc}
