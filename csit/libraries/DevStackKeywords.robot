*** Settings ***
Library           SSHLibrary
Library           String
Library           DateTime
Library           RequestsLibrary
Library           json
Library           SSHLibrary
Library           Collections
Library           XML
Variables         ../variables/Variables.py
Resource          ./Utils.robot

*** variable ***

*** Keywords ***
Setup Devstack
    [Arguments]    ${os_version}  ${local_conf}
    [Documentation]    Clone the devstack
    Log    Clone Devstack
    SSHLibrary.Open_Connection    ${CONTROLLER}
    SSHLibrary.Login_With_Public_Key    ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Execute Command    git clone https://git.openstack.org/openstack-dev/devstack
    SSHLibrary.Execute Command    cd devstack; git checkout stable/${os_version}
    SSHLibrary.Put_File    suites/vtn/${local_conf}  ~/devstack/
    Write      "./stack.sh"
    Read Until      "Horizon is now available"
    SSHLibrary.Close_Connection

Stop Devstack
    SSHLibrary.Open_Connection    ${CONTROLLER}
    SSHLibrary.Login_With_Public_Key    ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Execute Command    cd devstack; ./unstack.sh
    SSHLibrary.Close_Connection
