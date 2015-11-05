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
    Write    sudo yum -y install epel-release
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write    sudo yum -y install https://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
    Read Until      ${DEFAULT_LINUX_PROMPT}
    Write    sudo yum -y install openstack-packstack
    Read Until      ${DEFAULT_LINUX_PROMPT}
    SSHLibrary.Set Client Configuration   timeout=700s
    Write    sudo packstack --allinone --provision-demo=n --provision-all-in-one-ovs-bridge=n --os-swift-install=n
    Read Until      "Horizon started"
    SSHLibrary.Close_Connection

Stop Packstack
    SSHLibrary.Open_Connection    ${CONTROLLER}
    Utils.Flexible Controller Login     ${CONTROLLER_USER}
    SSHLibrary.Close_Connection
