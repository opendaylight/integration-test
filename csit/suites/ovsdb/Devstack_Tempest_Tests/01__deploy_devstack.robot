*** Settings ***
Documentation     Test suite to deploy devstack with networking-odl
Suite Setup       Devstack Suite Setup
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot

*** Variables ***
${PROJECT}             ovsdb
${ODL_VERSION}         lithium
${OPENSTACK_BRANCH}    stable/liberty
${TEMPEST_REGEX}       tempest.api.network
${ODL_BOOT_WAIT_URL}   restconf/operational/network-topology:network-topology/topology/netvirt:1
${DEVSTACK_LOCAL_CONFIG}    "ODL_NETVIRT_DEBUG_LOGS=True;ODL_JAVA_MIN_MEM=512m;ODL_JAVA_MAX_MEM=784m;ODL_JAVA_MAX_PERM_MEM=784m;"
${default_devstack_prompt_timeout}    10s
${devstack_workspace}  ~/ds_workspace

*** Test Cases ***
Setup Environment For DevStack Gate Script
    Write Commands Until Prompt    export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin
    Write Commands Until Prompt    export PROJECT=${PROJECT}
    Write Commands Until Prompt    export ODL_VERSION=${ODL_VERSION}
    Write Commands Until Prompt    export OPENSTACK_BRANCH=${OPENSTACK_BRANCH}
    Write Commands Until Prompt    export TEMPEST_REGEX=${TEMPEST_REGEX}
    Write Commands Until Prompt    export ODL_BOOT_WAIT_URL=${ODL_BOOT_WAIT_URL}
    Write Commands Until Prompt    export DEVSTACK_LOCAL_CONFIG=${DEVSTACK_LOCAL_CONFIG}
    ${odl_version_to_install}=     Get Networking ODL Version Of Release    ${ODL_VERSION}
    Write Commands Until Prompt    export DEVSTACK_LOCAL_CONFIG+=ODL_RELEASE="${odl_version_to_install};"
    Write Commands Until Prompt    export DEVSTACK_LOCAL_CONFIG+="enable_plugin networking-odl https://git.openstack.org/openstack/networking-odl"
    Write Commands Until Prompt    echo $DEVSTACK_LOCAL_CONFIG
    Write Commands Until Prompt    export OVERRIDE_ZUUL_BRANCH=${OPENSTACK_BRANCH}
    Write Commands Until Prompt    export PYTHONUNBUFFERED=true
    Write Commands Until Prompt    export DEVSTACK_GATE_TIMEOUT=120
    Write Commands Until Prompt    export DEVSTACK_GATE_TEMPEST=1
    Write Commands Until Prompt    export DEVSTACK_GATE_NEUTRON=1
    Write Commands Until Prompt    export KEEP_LOCALRC=1
    Write Commands Until Prompt    export PROJECTS="openstack/networking-odl $PROJECTS"
    Write Commands Until Prompt    export DEVSTACK_GATE_TEMPEST_REGEX=tempest.api.network.test_ports.PortsTestJSON.test_show_port
    Write Commands Until Prompt    sudo yum -y install redhat-lsb-core indent python-testrepository    timeout=120s
    Write Commands Until Prompt    sudo /usr/sbin/groupadd ${DEVSTACK_SYSTEM_USER}
    Write Commands Until Prompt    sudo mkdir -p /opt/stack/new
    Write Commands Until Prompt    sudo chown -R ${DEVSTACK_SYSTEM_USER}:${DEVSTACK_SYSTEM_USER} /opt/stack/new
    Write Commands Until Prompt    sudo bash -c 'echo "stack ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers'
    Write Commands Until Prompt    sudo mkdir -p /usr/local/${DEVSTACK_SYSTEM_USER}/slave_scripts
    Write Commands Until Prompt    git clone https://github.com/openstack/os-testr.git    timeout=30s
    Write Commands Until Prompt    cd os-testr/os_testr
    Write Commands Until Prompt    sudo cp subunit2html.py /usr/local/${DEVSTACK_SYSTEM_USER}/slave_scripts
    Write Commands Until Prompt    mkdir -p ${devstack_workspace}
    Write Commands Until Prompt    cd ${devstack_workspace}
    Write Commands Until Prompt    export WORKSPACE=${devstack_workspace}
    Write Commands Until Prompt    rm -rf devstack-gate
    Write Commands Until Prompt    git clone https://git.openstack.org/openstack-infra/devstack-gate

Run Devstack Gate Wrapper
    Write Commands Until Prompt    unset GIT_BASE
    Write Commands Until Prompt    env
    Write Commands Until Prompt    ./devstack-gate/devstack-vm-gate-wrap.sh    timeout=2700s  #30min

Run tempest.api.network Tests
    Write Commands Until Prompt    cd /opt/stack/new/tempest-lib
    Write Commands Until Prompt    sudo python setup.py install
    Write Commands Until Prompt    cd /opt/stack/new/tempest
    Write Commands Until Prompt    sudo rm -rf /opt/stack/new/tempest/.testrepository
    Write Commands Until Prompt    sudo testr init
    Write Commands Until Prompt    sudo -E testr run ${TEMPEST_REGEX} --subunit | subunit-trace --no-failure-debug -f    timeout=2400s

*** Keywords ***
Devstack Suite Setup
    SSHLibrary.Open Connection    ${DEVSTACK_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Utils.Flexible SSH Login    ${DEVSTACK_SYSTEM_USER}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}

Write Commands Until Prompt
    [Arguments]    ${cmd}    ${timeout}=${default_devstack_prompt_timeout}
    [Documentation]  quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Write    ${cmd}
    SSHLibrary.Read Until Prompt

Get Networking ODL Version Of Release
    [Arguments]    ${version}
    Return From Keyword If    "${version}" == "beryllium"    beryllium-snapshot-0.4.0
    Return From Keyword If    "${version}" == "lithium"    lithium-snapshot-0.3.1
    Return From Keyword If    "${version}" == "helium"    helium

#TODO:
#things to consider adding here to help sanitize any system this test is run against, although
#it should not matter for the sterile systems we should be getting from LF/Rackspace for each job
#rpm -qa | grep rdo, then rpm -e on the rdo package
#sudo rm -rf /tmp/ansible/ /opt/stack ~/ds_workspace/ ~/os-testr/
#not sure best way yet, but kill all python and java processes, if system reboot is not an option