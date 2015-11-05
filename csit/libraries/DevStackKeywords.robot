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
    SSHLibrary.Set Client Configuration   timeout=20s
    Write     git clone https://git.openstack.org/openstack-dev/devstack
    Read Until      ${DEFAULT_LINUX_PROMPT}
    SSHLibrary.Set Client Configuration   timeout=20s
    Write    cd devstack; git checkout stable/${os_version}
    Read Until      ${DEFAULT_LINUX_PROMPT}
    SSHLibrary.Put File    ${CURDIR}/local.conf
    Write    'cat ../local.conf' 
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write    'cp ../local.conf  .'
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write     'pwd'
    Read Until     ${DEFAULT_LINUX_PROMPT}
    Write     'ls'
    Read Until     ${DEFAULT_LINUX_PROMPT}
    Write      'cat local.conf'
    Read Until     ${DEFAULT_LINUX_PROMPT}
    SSHLibrary.Close_Connection

Stop Devstack
    SSHLibrary.Open_Connection    ${CONTROLLER}
    SSHLibrary.Login_With_Public_Key     ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Execute Command     cd devstack; ./unstack.sh
    SSHLibrary.Close_Connection
