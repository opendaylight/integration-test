*** Settings ***
Documentation     General Utils library. This library has broad scope, it can be used by any robot system tests.
Library           SSHLibrary
Library           String
Library           DateTime
Library           Process
Library           Collections
Library           RequestsLibrary
Library           ./UtilLibrary.py
Resource          KarafKeywords.robot
Resource          OpenStackOperations.robot
Variables         ../variables/Variables.py

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

*** Keywords ***
Run Tempest Tests
    [Arguments]    ${tempest_regex}    ${tempest_exclusion_regex}=""    ${tempest_conf}=""    ${tempest_directory}=/opt/stack/tempest    ${timeout}=600s
    [Documentation]    Execute the tempest tests.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    cd ${tempest_directory}
    Write Commands Until Prompt    sudo testr list-tests | egrep ${tempest_regex} | egrep -v ${tempest_exclusion_regex} > tests_to_execute.txt
    ${tests_to_execute}=    Write Commands Until Prompt    sudo cat tests_to_execute.txt
    Log    ${tests_to_execute}
    # run_tempests.sh is a wrapper to testr, and we are providing the config file
    ${results}=    Write Commands Until Prompt    sudo -E ${tempest_directory}/run_tempest.sh -C ${tempest_conf} -N ${tempest_regex} -- --load-list tests_to_execute.txt    timeout=${timeout}
    Log    ${results}
    # Save stdout to file
    Create File    tempest_output_${tempest_regex}.log    data=${results}
    # output tempest generated log file which may have different debug levels than what stdout would show
    # FIXME: having the INFO level tempest logs is helpful as it gives details like the UUIDs of nouns used in the
    # the tests which can sometimes be tracked in ODL and Openstack logs when debugging. However, this "cat" step
    # does not even complete for the tempest.api.network tests in under 2min. We need a faster way to get this
    # info. Probably pulling the log file and storing it on the log server is best. Hopefully someone can get
    # to this. For now, commenting out this next debug step.
    # ${output}=    Write Commands Until Prompt    cat ${tempest_directory}/tempest.log    timeout=120s
    # Log    ${output}
    Should Contain    ${results}    Failed: 0
    # TODO: also need to verify some non-zero pass count as well as other results are ok (e.g. skipped, etc)

Devstack Suite Setup
    [Arguments]    ${source_pwd}=no    ${odl_ip}=${ODL_SYSTEM_IP}
    [Documentation]    Login to the Openstack Control Node to run tempest suite
    Create Session    session    http://${odl_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${devstack_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Set Suite Variable    ${devstack_conn_id}
    Set Suite Variable    ${source_pwd}
    Log    ${devstack_conn_id}
    Utils.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}

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
    [Documentation]    Get version of ODL to be installed
    # once Beryllium SR1 goes out, we can change beryllium-latest to use 0.4.2
    Return From Keyword If    "${version}" == "beryllium-latest"    beryllium-snapshot-0.4.2
    Return From Keyword If    "${version}" == "beryllium-SR1"    beryllium-snapshot-0.4.1
    Return From Keyword If    "${version}" == "beryllium"    beryllium-snapshot-0.4.0
    Return From Keyword If    "${version}" == "lithium-latest"    lithium-snapshot-0.3.5
    Return From Keyword If    "${version}" == "lithium-SR4"    lithium-snapshot-0.3.4
    Return From Keyword If    "${version}" == "lithium-SR3"    lithium-snapshot-0.3.3
    Return From Keyword If    "${version}" == "lithium-SR2"    lithium-snapshot-0.3.2
    Return From Keyword If    "${version}" == "lithium-SR1"    lithium-snapshot-0.3.1
    # FYI networking-odl no longer has this for some reason.
    Return From Keyword If    "${version}" == "lithium"    lithium-snapshot-0.3.0
    Return From Keyword If    "${version}" == "helium"    helium

Show Devstack Debugs
    [Documentation]    Collect the devstack logs to debug in case of failure
    Write Commands Until Prompt    gunzip /opt/stack/logs/devstacklog.txt.gz
    Write Commands Until Prompt    tail -n2000 /opt/stack/logs/devstacklog.txt    timeout=600s
    Write Commands Until Prompt    grep 'distribution-karaf.*zip' /opt/stack/logs/devstacklog.txt
