*** Settings ***
Documentation     Test suite to deploy devstack with networking-odl
Suite Setup       Devstack Suite Setup
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../libraries/Utils.robot
Resource          Variables.robot
Variables         ../../../../variables/Variables.py

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

*** Test Cases ***
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
    Run Tempest Tests    ${TEST_NAME}

tempest
    [Tags]    exclude
    Run Tempest Tests    ${TEST_NAME}    1800s

Neutron exploration
    ${output}  ${stderr}  ${rc}  Execute Command  neutron --version  return_stderr=True  return_stdout=TRUE  return_rc=TRUE
    Log    ${output}
    Log    ${stderr}
    Log    ${rc}
    ${results}    Write Commands Until Prompt    ls /opt/stack/
    Log    ${results}
    ${results}    Write Commands Until Prompt    ls /opt/stack/new
    Log    ${results}
    ${results}    Write Commands Until Prompt    cd /opt/stack/new/devstack
    Log    ${results}
    ${results}    Write Commands Until Prompt    source openrc admin admin
    Log    ${results}
    ${results}    Write Commands Until Prompt    neutron net-list
    Log    ${results}
    ${results}    Write Commands Until Prompt    neutron net-create net_test_gbp_1
    Log    ${results}
    ${results}    Write Commands Until Prompt    neutron net-delete net_test_gbp_1
    Log    ${results}
    ${results}    Write Commands Until Prompt    sudo ovs-vsctl show
    Log    ${results}

Test2
    ${results}    Write Commands Until Prompt    cd /opt/stack/new/devstack
    Log    ${results}
    ${results}    Write Commands Until Prompt    ls
    Log    ${results}
    ${file}    OperatingSystem.Get File    localrc
    Log    ${file}
    ${results}    Write Commands Until Prompt    source openrc admin admin
    Log    ${results}
    ${results}    Write Commands Until Prompt    neutron net-create net_test_gbp_1
    Log    ${results}
    ${results}    Write Commands Until Prompt    neutron net-delete net_test_gbp_1
    Log    ${results}

Neutron exploration
    Create Session    session    http://${ODL_SYSTEM_IP}:${8181}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
    Wait Until Keyword Succeeds    20x    5 s    Get Data From URI    session    ${TUNNELS_PATH}    headers=${headers}
    Suite Teardown    Delete All Sessions

*** Keywords ***
Run Tempest Tests
    [Arguments]    ${tempest_regex}    ${timeout}=600s
    Write Commands Until Prompt    cd /opt/stack/new/tempest
    Write Commands Until Prompt    sudo rm -rf /opt/stack/new/tempest/.testrepository
    Write Commands Until Prompt    sudo testr init
    ${results}=    Write Commands Until Prompt    sudo -E testr run ${tempest_regex} --subunit | subunit-trace --no-failure-debug -f    timeout=600s
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
    Write Commands Until Prompt    export DEVSTACK_LOCAL_CONFIG+=ODL_NETVIRT_DEBUG_LOGS=True;ODL_RELEASE="${odl_version_to_install};"
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
    Write Commands Until Prompt    tail -n1000 /opt/stack/logs/devstacklog.txt    timeout=600s
