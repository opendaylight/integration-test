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

Run Tempest Tests In Groups A
    Run Tempest Tests    tempest.api.network.admin
# Run Tempest Tests In Groups B
#     Run Tempest Tests    tempest.api.network.test_allowed_address_pair
Run Tempest Tests In Groups B1
    Run Tempest Tests    tempest.api.network.test_allowed_address_pair.AllowedAddressPairTestJSON
# Run Tempest Tests In Groups C
#     Run Tempest Tests    tempest.api.network.test_dhcp_ipv6
Run Tempest Tests In Groups D
    Run Tempest Tests    tempest.api.network.test_extensions
# Run Tempest Tests In Groups E
#     Run Tempest Tests    tempest.api.network.test_extra_dhcp_options
Run Tempest Tests In Groups E1
    Run Tempest Tests    tempest.api.network.test_extra_dhcp_options.ExtraDHCPOptionsTestJSON
Run Tempest Tests In Groups F
    Run Tempest Tests    tempest.api.network.test_floating_ips
Run Tempest Tests In Groups G
    Run Tempest Tests    tempest.api.network.test_floating_ips_negative
# Run Tempest Tests In Groups H
#     Run Tempest Tests    tempest.api.network.test_metering_extensions
Run Tempest Tests In Groups H1
    Run Tempest Tests    tempest.api.network.test_metering_extensions.MeteringTestJSON
# Run Tempest Tests In Groups I
#     Run Tempest Tests    tempest.api.network.test_networks
Run Tempest Tests In Groups I1
    Run Tempest Tests    tempest.api.network.test_networks.BulkNetworkOpsTestJSON
    Run Tempest Tests    tempest.api.network.test_networks.NetworksTest
Run Tempest Tests In Groups J
    Run Tempest Tests    tempest.api.network.test_networks_negative
# Run Tempest Tests In Groups K
#     Run Tempest Tests    tempest.api.network.test_ports
Run Tempest Tests In Groups J1
    Run Tempest Tests    tempest.api.network.test_ports.PortsTestJSON
# Run Tempest Tests In Groups L
#     Run Tempest Tests    tempest.api.network.test_routers
Run Tempest Tests In Groups L1
    Run Tempest Tests    tempest.api.network.test_routers.DvrRoutersTest
    Run Tempest Tests    tempest.api.network.test_routers.RoutersTest
# Run Tempest Tests In Groups M
#     Run Tempest Tests    tempest.api.network.test_routers_negative
Run Tempest Tests In Groups M1
    Run Tempest Tests    tempest.api.network.test_routers_negative.DvrRoutersNegativeTest
    Run Tempest Tests    tempest.api.network.test_routers_negative.RoutersNegativeTest
# Run Tempest Tests In Groups N
#     Run Tempest Tests    tempest.api.network.test_security_groups
Run Tempest Tests In Groups N1
    Run Tempest Tests    tempest.api.network.test_security_groups.SecGroupTest
# Run Tempest Tests In Groups O
#     Run Tempest Tests    tempest.api.network.test_security_groups_negative
Run Tempest Tests In Groups 01
    Run Tempest Tests    tempest.api.network.test_security_groups_negative.NegativeSecGroupTest
Run Tempest Tests In Groups P
    Run Tempest Tests    tempest.api.network.test_service_type_management
Run Tempest Tests In Groups Q
    Run Tempest Tests    tempest.api.network.test_subnetpools_extensions

*** Keywords ***
Run Tempest Tests
    [Arguments]    ${tempest_regex}
    Write Commands Until Prompt    cd /opt/stack/new/tempest-lib
    Write Commands Until Prompt    sudo python setup.py install
    Write Commands Until Prompt    cd /opt/stack/new/tempest
    Write Commands Until Prompt    sudo rm -rf /opt/stack/new/tempest/.testrepository
    Write Commands Until Prompt    sudo testr init
    Write Commands Until Prompt    sudo -E testr run ${tempest_regex} --subunit | subunit-trace --no-failure-debug -f    timeout=1200s

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