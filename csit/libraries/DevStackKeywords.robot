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

*** Keywords ***
Start Devstack setup
    [Documentation]    stack up the devstack
    Log    Clone Devstack
    SSHLibrary.Open_Connection    ${CONTROLLER}
    Log    Controller
    SSHLibrary.Login_With_Public_Key    ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}
    Log    userkey
    SSHLibrary.Execute Command    git clone https://git.openstack.org/openstack-dev/devstack
    Log    Clone
    SSHLibrary.Execute Command    cd devstack
    SSHLibrary.Execute Command    ./tools/create-stack-user.sh
    SSHLibrary.Execute Command    su - stack
    SSHLibrary.Execute Command    git clone https://git.openstack.org/openstack-dev/devstack
    SSHLibrary.Execute Command    cd devstack;git checkout stable/liberty
    Log    liberty
    SSHLibrary.Put_File    ${CURDIR}/${CREATE_LOCALCONF_FILE}   ~/devstack/
    SSHLibrary.Set Client Configuration   timeout=600s
    Write      "devstack/stack.h"
    Log    create the stack setup
    Read Until    "Horizon is now available"
    Log    create the stack setup completed
    SSHLibrary.Close_Connection

Stop Devstack
   [Documentation]    Unstack the devstack
   SSHLibrary.Open_Connection    ${CONTROLLER}
   SSHLibrary.Login_With_Public_Key    ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY
   SSHLibrary.Execute Command    cd devstack; ./unstack.sh
   SSHLibrary.Close_Connection
