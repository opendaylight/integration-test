*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Resource          DataModels.robot
Resource          Utils.robot
Resource          SSHKeywords.robot
Resource          L2GatewayOperations.robot
Resource          ../variables/Variables.robot

*** Keywords ***
Install Rpm Package
    [Arguments]    ${os_node_cxn}     ${package}
    [Documentation]    Install packages in a node
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo yum install -y ${package}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Crudini Edit
    [Arguments]    ${os_node_cxn}     ${conf_file}     ${section}     ${key}      ${value}
    [Documentation]     Crudini edit on a configuration file
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo crudini --verbose  --set --inplace ${conf_file} ${section} ${key} ${value}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Start Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Start a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl start ${service}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Enable Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Enable a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl enable ${service}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      stop a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl stop ${service}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Restart Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Restart a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl restart ${service}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop And Disable Firewall
    [Arguments]    ${os_node_cxn}     ${service}
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl stop firewalld
    Log    ${output}
    Log    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl disable firewalld
    Log    ${output}
    Log    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl stop iptables
    Log    ${output}
    Log    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl disable iptables
    Log    ${output}
    Log    ${rc}

