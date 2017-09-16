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
Get Opendaylight From Url And Configure As Service
    [Arguments]    ${os_node_cxn}     ${url}
    [Documentation]    This Keyword can get ODL zip from URL, Unzip and add as service, but does not start it
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output     sudo wget --verbose ${url} -O /tmp/opendaylight.zip
    Log    ${output}
    Should Not Be True    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output     sudo unzip /tmp/opendaylight.zip  /opt/
    Log    ${output}
    Should Not Be True    ${rc}
