*** Settings ***
Documentation     Test suite to deploy devstack with networking-odl
Suite Setup       Devstack Suite Setup
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot

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
${NETWORK1_NAME}    debuggingIsFun_network
${NETWORK2_NAME}    net2_network
${NETWORK3_NAME}    net3_network
${NETWORK4_NAME}    net4_network
${INSTANCE1_NAME}   MyFirstInstance
${INSTANCE2_NAME}   MySecondInstance
${INSTANCE3_NAME}   MyThirdInstance
${INSTANCE4_NAME}   MyFourthInstance

@{INSTANCE_ATTR}    10.0.0.3    20.0.0.3    30.0.0.3    40.0.0.3

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

Test neutron
    ${output}=    Write Commands Until Prompt    cd /opt/stack/new/devstack && cat localrc
    Log    ${output}
    ${output}=    Write Commands Until Prompt    source openrc admin admin
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v net-create ${NETWORK1_NAME}
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v net-create ${NETWORK2_NAME}
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v net-create ${NETWORK3_NAME}
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v net-create ${NETWORK4_NAME}
    Log    ${output}

Test subnet
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${NETWORK1_NAME} 10.0.0.0/24 --name subnet1
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${NETWORK2_NAME} 20.0.0.0/24 --name subnet2
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${NETWORK3_NAME} 30.0.0.0/24 --name subnet3
    Log    ${output}
    ${output}=    Write Commands Until Prompt    neutron -v subnet-create ${NETWORK4_NAME} 40.0.0.0/24 --name subnet4
    Log    ${output}

Test List Ports
    ${output}=   Write Commands Until Prompt     neutron -v port-list
    Log    ${output}

Test List Available Networks
    ${output}=   Write Commands Until Prompt     neutron -v net-list
    Log    ${output}
    ${output}=   Write Commands Until Prompt    neutron net-list -F id -F name -f json
    Log    ${output}

Test Tenant list
    ${output}=   Write Commands Until Prompt     keystone tenant-list
    Log    ${output}

Test novalist
    ${output}=   Write Commands Until Prompt     nova list
    Log    ${output}

Test imagelist
    ${output}=   Write Commands Until Prompt     nova image-list
    Log    ${output}

Test flavor list
    ${output}=   Write Commands Until Prompt     nova flavor-list
    Log    ${output}

Test instance using flavor and image names
    ${net_id1}=    Get Net Id    ${NETWORK1_NAME}
    ${output}=   Write Commands Until Prompt     nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic net-id=${net_id1} ${INSTANCE1_NAME}
    Log    ${output}
    ${net_id2}=    Get Net Id    ${NETWORK2_NAME}
    ${output}=   Write Commands Until Prompt     nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic net-id=${net_id2} ${INSTANCE2_NAME}
    Log    ${output}
    ${net_id3}=    Get Net Id    ${NETWORK3_NAME}
    ${output}=   Write Commands Until Prompt     nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic net-id=${net_id3} ${INSTANCE3_NAME}
    Log    ${output}
    ${net_id4}=    Get Net Id    ${NETWORK4_NAME}
    ${output}=   Write Commands Until Prompt     nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic net-id=${net_id4} ${INSTANCE4_NAME}
    Log    ${output}

Test Show details of instance
    ${output}=   Write Commands Until Prompt     nova show ${INSTANCE1_NAME}
    Log    ${output}
    ${output}=   Write Commands Until Prompt     nova show ${INSTANCE2_NAME}
    Log    ${output}
    ${output}=   Write Commands Until Prompt     nova show ${INSTANCE3_NAME}
    Log    ${output}
    ${output}=   Write Commands Until Prompt     nova show ${INSTANCE4_NAME}
    Log    ${output}

Verify Created Vm Instance In Dump Flow
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${InstanceElement}    IN    @{INSTANCE_ATTR}
    \    should Contain    ${output}    ${InstanceElement}

Delete Vm Instances
    ${instancenet_id1}=   Get Instance Id    ${INSTANCE1_NAME}
    ${output}=   Write Commands Until Prompt     nova delete ${instancenet_id1}
    Log    ${output}
    ${instancenet_id2}=   Get Instance Id    ${INSTANCE2_NAME}
    ${output}=   Write Commands Until Prompt     nova delete ${instancenet_id2}
    Log    ${output}
    ${instancenet_id3}=   Get Instance Id    ${INSTANCE3_NAME}
    ${output}=   Write Commands Until Prompt     nova delete ${instancenet_id3}
    Log    ${output}
    ${instancenet_id4}=   Get Instance Id    ${INSTANCE4_NAME}
    ${output}=   Write Commands Until Prompt     nova delete ${instancenet_id4}
    Log    ${output}


Verify Instance Removed For The Deleted Network
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    30.0.0.3

Delete Sub Networks
    ${output}=    Write Commands Until Prompt    neutron -v subnet-delete subnet3
    Log    ${output}

Delete Networks
    ${output}=    Write Commands Until Prompt    neutron -v net-delete ${NETWORK3_NAME}
    Log    ${output}

Verify Dhcp Removed For The Deleted Network
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    30.0.0.2

Verify Gateway Ip Removed For The Deleted Network
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    30.0.0.1

Verify No Presence Of Removed Network In Dump Flow
    ${output}=   Write Commands Until Prompt     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    Should Not Contain    ${output}    30.0.0.3

Test Create the Router
    ${output}=   Write Commands Until Prompt     neutron -v router-create router1
    Log    ${output}

*** Keywords ***
Run Tempest Tests
    [Arguments]    ${tempest_regex}    ${timeout}=600s
    Write Commands Until Prompt    cd /opt/stack/new/tempest
    Write Commands Until Prompt    sudo rm -rf /opt/stack/new/tempest/.testrepository
    Write Commands Until Prompt    sudo testr init
    ${results}=    Write Commands Until Prompt    sudo -E testr run ${tempest_regex} --subunit | subunit-trace --no-failure-debug -f    timeout=${timeout}
    Should Contain    ${results}    Failed: 0
    # TODO: also need to verify some non-zero pass count as well as other results are ok (e.g. skipped, etc)

Devstack Suite Setup
    SSHLibrary.Open Connection    ${DEVSTACK_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Utils.Flexible SSH Login    ${DEVSTACK_SYSTEM_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    Run Keyword If    ${CLEAN_DEVSTACK_HOST}    Clean DevStack Host In Case It Is Not Sterile
    Write Commands Until Prompt    export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin
    Write Commands Until Prompt    export ODL_VERSION=${ODL_VERSION}
    Write Commands Until Prompt    export OPENSTACK_BRANCH=${OPENSTACK_BRANCH}
    Write Commands Until Prompt    export TEMPEST_REGEX=${TEMPEST_REGEX}
    Write Commands Until Prompt    export ODL_BOOT_WAIT_URL=${ODL_BOOT_WAIT_URL}
    ${odl_version_to_install}=    Get Networking ODL Version Of Release    ${ODL_VERSION}
    Write Commands Until Prompt    export DEVSTACK_LOCAL_CONFIG="enable_plugin networking-odl https://git.openstack.org/openstack/networking-odl ${NETWORKING-ODL_BRANCH};"
    Write Commands Until Prompt    export DEVSTACK_LOCAL_CONFIG+="ODL_NETVIRT_DEBUG_LOGS=True;ODL_RELEASE=${odl_version_to_install};"
#    Write Commands Until Prompt    export DEVSTACK_LOCAL_CONFIG+=ODL_RELEASE="${odl_version_to_install};"
#    Write Commands Until Prompt    export DEVSTACK_LOCAL_CONFIG+=ODL_NETVIRT_KARAF_FEATURE=odl-groupbasedpolicy-base;
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
    Write Commands Until Prompt    git clone https://git.openstack.org/openstack-infra/devstack-gate    timeout=30s

Clean DevStack Host In Case It Is Not Sterile
    [Documentation]    In upstream CI, the expectation is that the devstack VM is fresh, sterile and ready
    ...    for any version of devstack, networking-odl, and OpenDaylight. During local test development,
    ...    it can be faster to just clean the needed packages, configurations, repos, files, etc. instead of
    ...    spinning up a new system. This keyword serves as a living list of those items needed to prep a
    ...    potentially non-sterile devstack system.
    Write Commands Until Prompt    pgrep python | awk '{print "sudo kill",$1}' | sh
    Write Commands Until Prompt    pgrep java | awk '{print "sudo kill",$1}' | sh
    Write Commands Until Prompt    rpm -qa | grep rdo
    Write Commands Until Prompt    sudo rpm -e $(sudo rpm -qa | grep rdo)
    Write Commands Until Prompt    sudo yum remove -y pyOpenSSL
    Write Commands Until Prompt    sudo -H pip uninstall -y virtualenv
    Write Commands Until Prompt    sudo rm -rf /tmp/ansible /opt/stack
    Write Commands Until Prompt    rm -rf ${devstack_workspace} ~/os-testr
    Write Commands Until Prompt    sudo ovs-vsctl del-br br-ex
    Write Commands Until Prompt    sudo ovs-vsctl del-br br-int
    Write Commands Until Prompt    sudo ovs-vsctl del-manager

Write Commands Until Prompt
    [Arguments]    ${cmd}    ${timeout}=${default_devstack_prompt_timeout}
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read Until Prompt
    [Return]    ${output}

Get Networking ODL Version Of Release
    [Arguments]    ${version}
    Return From Keyword If    "${version}" == "beryllium"    beryllium-snapshot-0.4.0
    Return From Keyword If    "${version}" == "lithium-latest"    lithium-snapshot-0.3.4
    Return From Keyword If    "${version}" == "lithium-SR3"    lithium-snapshot-0.3.3
    Return From Keyword If    "${version}" == "lithium-SR2"    lithium-snapshot-0.3.2
    Return From Keyword If    "${version}" == "lithium-SR1"    lithium-snapshot-0.3.1
    Return From Keyword If    "${version}" == "lithium"    lithium-snapshot-0.3.0
    Return From Keyword If    "${version}" == "helium"    helium

Show Devstack Debugs
    Write Commands Until Prompt    gunzip /opt/stack/logs/devstacklog.txt.gz
    Write Commands Until Prompt    tail -n2000 /opt/stack/logs/devstacklog.txt    timeout=600s
    Write Commands Until Prompt    grep 'distribution-karaf.*zip' /opt/stack/logs/devstacklog.txt

Get Net Id
    [Arguments]    ${network_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    ${output}=   Write Commands Until Prompt    neutron net-list | grep "${network_name}" | get_field 1
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    \
    ${net_id}=    Get from List    ${splitted_output}    0
    Log    ${net_id}
    [Return]    ${net_id}

Get Instance Id
    [Arguments]    ${instace_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    ${output}=   Write Commands Until Prompt    nova show ${instace_name} | grep " id " | get_field 2
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    \
    ${instancenet_id}=    Get from List    ${splitted_output}    0
    Log    ${instancenet_id}
    [Return]    ${instancenet_id}