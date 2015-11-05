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
    SSHLibrary.Open_Connection     ${CONTROLLER}
    Utils.Flexible SSH Login    ${CONTROLLER_USER}
    Write     git clone https://git.openstack.org/openstack-dev/devstack
    Write    cd devstack; git checkout stable/${os_version}
    SSHLibrary.Put_File    ${CURDIR}/local.conf   ~/devstack/local.conf
    Write     "pwd"
    Read Until     ${DEFAULT_LINUX_PROMPT}
    Write     "ls"
    Read Until     ${DEFAULT_LINUX_PROMPT}
    SSHLibrary.Execute Command      "cd devstack"
    Write      "ls"
    Read Until     ${DEFAULT_LINUX_PROMPT}
    Write      "cat devstack/local.conf"
    Read Until     ${DEFAULT_LINUX_PROMPT}
    Write      "cat local.conf"
    Read Until     ${DEFAULT_LINUX_PROMPT}
    SSHLibrary.Close_Connection

Stop Devstack
    SSHLibrary.Open_Connection    ${CONTROLLER}
    SSHLibrary.Login_With_Public_Key     ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Execute Command     cd devstack; ./unstack.sh
    SSHLibrary.Close_Connection
