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
Setup Packstack
    [Documentation]    Clone the devstack
    Log    Clone Devstack
    SSHLibrary.Open_Connection     ${CONTROLLER}
    Utils.Flexible Controller Login     ${CONTROLLER_USER}
    SSHLibrary.Set Client Configuration   timeout=20s
    Write    sudo systemctl stop NetworkManager
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write    sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write     sudo groupadd stack
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write     useradd -g stack -s /bin/bash -d $DEST -m stack
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write     sudo umask 226
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write     sudo echo "stack ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write     sudo su - stack
    Read Until      stack@
    SSHLibrary.Set Client Configuration   timeout=60s
    Write    sudo yum -y install https://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
    Read Until      Complete!
    Write    sudo yum -y install openstack-packstack
    Read Until      Complete!
    SSHLibrary.Set Client Configuration   timeout=700s
    Write    sudo packstack --allinone --provision-demo=n --provision-all-in-one-ovs-bridge=n --keystone-admin-passwd=test_pass
    Read Until      To access the OpenStack Dashboard
    Write     sudo systemctl status openstack-nova-api.service
    Read Until      stack@
    SSHLibrary.Close_Connection


Stop Packstack
    SSHLibrary.Open_Connection    ${CONTROLLER}
    Utils.Flexible Controller Login     ${CONTROLLER_USER}
    SSHLibrary.Close_Connection
