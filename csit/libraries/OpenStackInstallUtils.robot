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
Setup Basic Ssh
    [Arguments]    ${node_ip}       ${user_name}      ${password}      ${prompt}
    [Documentation]    Open SSh Connection and disable selinux
    ${connection}=    Get Ssh Connection    ${node_ip}     ${user_name}    ${password}    ${prompt}
    Disable SeLinux Tempororily       ${connection}
    [Return]      ${connection}
    
Get All Ssh Connections
    [Documentation]    Open All SSH Connections.
    Run Keyword If    0 < ${NUM_CONTROL_NODES}    Setup Basic Ssh   ${OS_CONTROL_1_IP}    ${OS_USER}    ${OS_USER_PASSWORD}   ${OS_NODE_PROMPT}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup basic Ssh    ${OS_CONTROL_2_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup basic Ssh    ${OS_CONTROL_3_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Setup basic Ssh    ${HAPROXY_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Setup basic Ssh    ${OS_COMPUTE_1_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Setup basic Ssh    ${OS_COMPUTE_2_IP}    ${OS_USER}    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}
#    ${robot_vm}=    Get Ssh Connection    127.0.0.1    ${OS_USER}    ${OS_USER_PASSWORD}      ${OS_NODE_PROMPT}
  
