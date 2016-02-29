*** Settings ***
Documentation     Test suite to deploy devstack with networking-odl
Suite Setup       Devstack Suite Setup
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          Variables.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/DevstackUtils.robot

*** Variables ***
${ODL_VERSION}    lithium-SR3
${OPENSTACK_BRANCH}    stable/liberty
${NETWORKING-ODL_BRANCH}    ${OPENSTACK_BRANCH}
${TEMPEST_REGEX}    tempest.api.network
${ODL_BOOT_WAIT_URL}    restconf/operational/network-topology:network-topology/topology/netvirt:1
${default_devstack_prompt_timeout}    10s
${devstack_workspace}    ~/ds_workspace
${DEVSTACK_SYSTEM_PASSWORD}    \    # set to empty, but provide for others to override if desired
${CLEAN_DEVSTACK_HOST}    False
${HEADERS_YANG_JSON}    {'Content-Type': 'application/yang.data+json'}
${TENANTS_CONF_PATH}    restconf/config/policy:tenants

*** Test Cases ***
Check Firewall Things Before Devstacky stuff
    ${output}=    Write Commands Until Prompt    sudo iptables --list
    Log    ${output}
    ${output}=    Write Commands Until Prompt    sudo systemctl status firewalld
    Log    ${output}

Run Devstack Gate Wrapper
    Write Commands Until Prompt    unset GIT_BASE
    Write Commands Until Prompt    env
    ${output}=    Write Commands Until Prompt    ./devstack-gate/devstack-vm-gate-wrap.sh    timeout=3600s    #60min
    Log    ${output}
    Should Not Contain    ${output}    ERROR: the main setup script run by this job failed
    # workaround for https://bugs.launchpad.net/networking-odl/+bug/1512418
    Write Commands Until Prompt    cd /opt/stack/new/tempest-lib
    Write Commands Until Prompt    sudo python setup.py install
    [Teardown]    Show Devstack Debugs

Validate Neutron and Networking-ODL Versions
    ${output}=    Write Commands Until Prompt    cd /opt/stack/new/neutron; git branch;
    Should Contain    ${output}    * ${OPENSTACK_BRANCH}
    ${output}=    Write Commands Until Prompt    cd /opt/stack/new/networking-odl; git branch;
    Should Contain    ${output}    * ${NETWORKING-ODL_BRANCH}

tempest.api.network
    [Tags]    exclude
    Run Tempest Tests    ${TEST_NAME}

tempest
    [Tags]    exclude
    Run Tempest Tests    ${TEST_NAME}    900s

Poke Holes In Iptables
    # these two lines didn't work.  I was hoping to be more surgical instead of flushing all rules, but can't figure it out
    ${output}=    Write Commands Until Prompt    sudo iptables -A INPUT -j ACCEPT
    ${output}=    Write Commands Until Prompt    sudo iptables -A FORWARD -j ACCEPT
    ${output}=    Write Commands Until Prompt    sudo iptables -F
    Log    ${output}
    
Put GBP Goodness In To The Mix
    Set Client configuration    timeout=3600
    Install a Feature    odl-neutron-service    ${DEVSTACK_SYSTEM_IP}    timeout=3600
    Sleep    30s
    Set Client configuration    timeout=60
