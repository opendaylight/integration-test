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
Get All Ssh Connections
    [Documentation]    Open All SSH Connections.
    ${control_1}=    Run Keyword If    0 < ${NUM_CONTROL_NODES}    Get Ssh Connection    ${OS_CONTROL_1_IP}    ${OS_USER}    ${OS_USER_PASSWORD}
    ...    ${OS_NODE_PROMPT}
    Set Suite Variable    ${control_1}
    Disable SeLinux Tempororily       ${control_1}
    ${control_2}=    Run Keyword If    1 < ${NUM_CONTROL_NODES}    Get Ssh Connection    ${OS_CONTROL_2_IP}    ${OS_USER}    ${OS_USER_PASSWORD}
    ...    ${OS_NODE_PROMPT}
    Set Suite Variable    ${control_2}
    Disable SeLinux Tempororily       ${control_2}
    ${control_3}=    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Get Ssh Connection    ${OS_CONTROL_3_IP}    ${OS_USER}    ${OS_USER_PASSWORD}
    ...    ${OS_NODE_PROMPT}
    Set Suite Variable    ${control_3}
    Disable SeLinux Tempororily       ${control_3}
    ${haproxy}=    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Get Ssh Connection    ${HAPROXY_IP}    ${OS_USER}    ${OS_USER_PASSWORD}
    ...    ${OS_NODE_PROMPT}
    Set Suite Variable    ${haproxy}
    Disable SeLinux Tempororily       ${haproxy}
    ${compute_1}=    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Get Ssh Connection    ${OS_COMPUTE_1_IP}    ${OS_USER}    ${OS_USER_PASSWORD}
    ...    ${OS_NODE_PROMPT}
    Set Suite Variable    ${compute_1}
    Disable SeLinux Tempororily       ${compute_1}
    ${compute_2}=    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Get Ssh Connection    ${OS_COMPUTE_2_IP}    ${OS_USER}    ${OS_USER_PASSWORD}
    ...    ${OS_NODE_PROMPT}
    Set Suite Variable    ${compute_2}
    Disable SeLinux Tempororily       ${compute_2}
  
