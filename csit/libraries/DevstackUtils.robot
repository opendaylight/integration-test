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
Resource          SSHKeywords.robot
Variables         ../variables/Variables.py

*** Variables ***
${default_devstack_prompt_timeout}    10s
${DEVSTACK_SYSTEM_PASSWORD}    \    # set to empty, but provide for others to override if desired
${blacklist_file}    /tmp/blacklist.txt
@{stable/newton_exclusion_regexes}    ${EMPTY}
@{stable/ocata_exclusion_regexes}    ${EMPTY}
@{stable/pike_exclusion_regexes}    ${EMPTY}
@{master_exclusion_regexes}    ${EMPTY}
${tempest_config_file}    /opt/stack/tempest/etc/tempest.conf
${external_physical_network}    physnet1
${external_net_name}    external-net
${external_subnet_name}    external-subnet
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${external_gateway}    10.10.10.250
${external_subnet_allocation_pool}    start=10.10.10.2,end=10.10.10.249
${external_subnet}    10.10.10.0/24

*** Keywords ***
Run Tempest Tests
    [Arguments]    ${tempest_regex}    ${exclusion_file}=/dev/null    ${tempest_conf}=""    ${tempest_directory}=/opt/stack/tempest    ${timeout}=420s
    [Documentation]    Execute the tempest tests.
    Return From Keyword If    "skip_if_${OPENSTACK_BRANCH}" in @{TEST_TAGS}
    Return From Keyword If    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}
    ${tempest_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    # There seems to be a bug in the mitaka version of os-testr that does not allow --regex to work in conjunction
    # with a blacklist-file. Upgrading with pip should resolve this. This can probably go away once mitaka is no
    # longer tested in this environment. But, while it's being tested the mitaka devstack setup will be bringing
    # in this broken os-testr, so we manually upgrade here.
    # Write Commands Until Prompt    sudo pip install os-testr --upgrade    timeout=120s
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    cd ${tempest_directory}
    # From Ocata and moving forward, we can replace 'ostestr' with 'tempest run'
    Modify Config In File On Existing SSH Connection    ${tempest_conf}    set    DEFAULT    pause_teardown    True
    SSHLibrary.Read
    SSHLibrary.Set Client Configuration    timeout=300s
    SSHLibrary.Write    python -m testtools.run ${tempest_regex}
    ${output}=    SSHLibrary.Read Until Regexp    ${DEFAULT_LINUX_PROMPT_STRICT}|pdb.set_trace()
    Log    ${output}
    Show Debugs
    Get Test Teardown Debugs
    SSHLibrary.Switch Connection    ${tempest_conn_id}
    SSHLibrary.Write    continue
    ${results}=    SSHLibrary.Read Until Regexp    ${DEFAULT_LINUX_PROMPT_STRICT}|pdb.set_trace()
    Log    ${results}
    SSHLibrary.Write    continue
    ${output}=    SSHLibrary.Read Until Prompt
    Log    ${output}
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

Log In To Tempest Executor And Setup Test Environment
    [Documentation]    Initialize SetupUtils, open SSH connection to a devstack system and source the openstack
    ...    credentials needed to run the tempest tests. The (sometimes empty) tempest blacklist file will be created
    ...    and pushed to the tempest executor.
    Create Blacklist File
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    # source_pwd is expected to exist in the below Create Network, Create Subnet keywords.    Might be a bug.
    ${source_pwd}    Set Variable    yes
    Set Suite Variable    ${source_pwd}
    # Tempest tests need an existing external network in order to create routers.
    Create Network    ${external_net_name}    --external --default --provider-network-type flat --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK}
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    List Networks
    ${control_node_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    sudo rm -rf /opt/stack/tempest/.testrepository
    ${net_id}=    Get Net Id    ${external_net_name}    ${control_node_conn_id}
    Tempest Conf Add External Network    ${net_id}

Tempest Conf Add External Network
    [Arguments]    ${external_network_id}
    [Documentation]    Tempest will be run with a config file - this function will add the
    ...    given external network ID to the configuration file.
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    network    public_network_id    ${external_network_id}
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    DEFAULT    debug    False
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    DEFAULT    log_level    INFO
    Write Commands Until Prompt    sudo cat ${tempest_config_file}
    Write Commands Until Prompt    sudo chmod 777 ${tempest_config_file}

Modify Config In File On Existing SSH Connection
    [Arguments]    ${config_file}    ${modifier}    ${config_section}    ${config_key}    ${config_value}=${EMPTY}
    [Documentation]    uses crudini to populate oslo cofg file.
    # this keyword is only one line so seems like extra overhead, but this may be a good candidate to move
    # to a library at some point, when/if other suites need to use it, so wanted to make it generic.
    Write Commands Until Prompt    sudo -E crudini --${modifier} ${config_file} ${config_section} ${config_key} ${config_value}

Clean Up After Running Tempest
    [Documentation]    Clean up any extra leftovers that were created to allow tempest tests to run.
    Delete Network    ${external_net_name}
    List Networks
    Close All Connections

Create Blacklist File
    [Documentation]    For each exclusion regex in the required @{${OPENSTACK_BRANCH}_exclusion_regexes} list a new
    ...    line will be created in the required ${blacklist_file} location. This file is pushed to the OS_CONTROL_NODE
    ...    which is assumed to be the tempest executor.
    OperatingSystem.Create File    ${blacklist_file}
    : FOR    ${exclusion}    IN    @{${OPENSTACK_BRANCH}_exclusion_regexes}
    \    OperatingSystem.Append To File    ${blacklist_file}    ${exclusion}\n
    Log File    ${blacklist_file}
    SSHKeywords.Copy File To Remote System    ${OS_CONTROL_NODE_IP}    ${blacklist_file}    ${blacklist_file}

Devstack Suite Setup
    [Arguments]    ${source_pwd}=no    ${odl_ip}=${ODL_SYSTEM_IP}
    [Documentation]    Login to the Openstack Control Node to run tempest suite
    Create Session    session    http://${odl_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${devstack_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Set Suite Variable    ${devstack_conn_id}
    Set Suite Variable    ${source_pwd}
    Log    ${devstack_conn_id}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}

Write Commands Until Prompt
    [Arguments]    ${cmd}    ${timeout}=${default_devstack_prompt_timeout}
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    Log    ${cmd}
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Read
    SSHLibrary.Write    ${cmd};echo Command Returns $?
    ${output}=    SSHLibrary.Read Until Prompt
    [Return]    ${output}
