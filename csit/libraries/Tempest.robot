*** Settings ***
Documentation     General Utils library. This library has broad scope, it can be used by any robot system tests.
Library           SSHLibrary
Resource          DevstackUtils.robot
Resource          OpenStackOperations.robot
Resource          SSHKeywords.robot
Resource          ../variables/Variables.robot

*** Variables ***
@{stable/ocata_EXCLUSION_REGEXES}    ${EMPTY}
@{stable/pike_EXCLUSION_REGEXES}    ${EMPTY}
@{stable/queens_EXCLUSION_REGEXES}    ${EMPTY}
@{master_EXCLUSION_REGEXES}    ${EMPTY}
${BLACKLIST_FILE}    /tmp/blacklist.txt
${TEMPEST_DIR}    /opt/stack/tempest
${TEMPEST_CONFIG_FILE}    ${TEMPEST_DIR}/etc/tempest.conf
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${TEMPEST_TIMEOUT}    420s

*** Keywords ***
Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    Tempest.Log In To Tempest Executor And Setup Test Environment

Run Tempest Tests
    [Arguments]    ${tempest_regex}    ${timeout}=${TEMPEST_TIMEOUT}    ${debug}=False
    BuiltIn.Run Keyword If    "${debug}" == "False"    Tempest.Run Tempest Tests Without Debug    ${tempest_regex}    timeout=${timeout}
    BuiltIn.Run Keyword If    "${debug}" == "True"    Tempest.Run Tempest Tests With Debug    ${tempest_regex}    timeout=${timeout}
    BuiltIn.Run Keyword If    "${debug}" != "True" and "${debug}" != "False"    Fail    debug argument must be True or False

Run Tempest Tests Without Debug
    [Arguments]    ${tempest_regex}    ${TEMPEST_DIRectory}=${TEMPEST_DIR}    ${timeout}=${TEMPEST_TIMEOUT}
    [Documentation]    Using ostestr will allow us to (by default) run tests in paralllel.
    ...    Because of the parallel fashion, we must ensure there is no pause on teardown so that flag in tempest.conf is
    ...    explicitly set to False.
    BuiltIn.Return From Keyword If    "skip_if_${OPENSTACK_BRANCH}" in @{TEST_TAGS}
    BuiltIn.Return From Keyword If    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}
    BuiltIn.Return From Keyword If    "skip_if_${ODL_SNAT_MODE}" in @{TEST_TAGS}
    ${tempest_conn_id} =    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    DevstackUtils.Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    DevstackUtils.Write Commands Until Prompt    cd ${TEMPEST_DIRectory}
    SSHLibrary.Read
    Tempest.Tempest Conf Modify Pause On Test Teardown    False
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    # There are tons of deprecation error messages when we use ostestr in our CSIT environment (openstack via devstack)
    # The robot log files are very large and one culprit is all these deprecation warnings. If we redirect stderr to
    # /dev/null we should be able to ignore them. We will miss any other errors, however.
    ${output} =    DevstackUtils.Write Commands Until Prompt And Log    ostestr --regex ${tempest_regex}    timeout=${timeout}
    SSHLibrary.Close Connection
    BuiltIn.Should Contain    ${output}    Failed: 0

Run Tempest Tests With Debug
    [Arguments]    ${tempest_regex}    ${TEMPEST_DIRectory}=${TEMPEST_DIR}    ${timeout}=${TEMPEST_TIMEOUT}
    [Documentation]    After setting pause_teardown=True in tempest.conf, use the python -m testtools.run module to execute
    ...    a single tempest test case. We need to run only one tempest test case at a time as there will
    ...    be potentional for an unkown number of debug pdb() prompts to catch and continue if we are running multiple
    ...    test cases with a single command. Essentially, this keyword only handles one breakpoint at a single teardown.
    BuiltIn.Return From Keyword If    "skip_if_${OPENSTACK_BRANCH}" in @{TEST_TAGS}
    BuiltIn.Return From Keyword If    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}
    BuiltIn.Return From Keyword If    "skip_if_${ODL_SNAT_MODE}" in @{TEST_TAGS}
    ${tempest_conn_id} =    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    DevstackUtils.Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    DevstackUtils.Write Commands Until Prompt    cd ${TEMPEST_DIRectory}
    SSHLibrary.Read
    Tempest Conf Modify Pause On Test Teardown    True
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Write    python -m testtools.run ${tempest_regex}
    ${output} =    SSHLibrary.Read Until Regexp    ${DEFAULT_LINUX_PROMPT_STRICT}|pdb.set_trace()
    BuiltIn.Log    ${output}
    OpenStackOperations.Show Debugs
    OpenStackOperations.Get Test Teardown Debugs
    SSHLibrary.Switch Connection    ${tempest_conn_id}
    SSHLibrary.Write    continue
    ${output} =    SSHLibrary.Read Until Regexp    ${DEFAULT_LINUX_PROMPT_STRICT}|pdb.set_trace()
    BuiltIn.Log    ${output}
    SSHLibrary.Write    continue
    ${output} =    SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${output}
    SSHLibrary.Close Connection
    BuiltIn.Should Contain    ${output}    OK
    BuiltIn.Should Not Contain    ${output}    FAILED

Log In To Tempest Executor And Setup Test Environment
    [Documentation]    Initialize SetupUtils, open SSH connection to a devstack system and source the openstack
    ...    credentials needed to run the tempest tests. The (sometimes empty) tempest blacklist file will be created
    ...    and pushed to the tempest executor.
    Tempest.Create Blacklist File
    # Tempest tests need an existing external network in order to create routers.
    OpenStackOperations.Create Network    ${EXTERNAL_NET_NAME}    --external --default --provider-network-type flat --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK}
    OpenStackOperations.Create Subnet    ${EXTERNAL_NET_NAME}    ${EXTERNAL_SUBNET_NAME}    ${EXTERNAL_SUBNET}    --gateway ${EXTERNAL_GATEWAY} --allocation-pool ${EXTERNAL_SUBNET_ALLOCATION_POOL}
    OpenStackOperations.List Networks
    ${control_node_conn_id} =    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}
    DevstackUtils.Write Commands Until Prompt And Log    sudo pip install -U --verbose pip    timeout=120s
    DevstackUtils.Write Commands Until Prompt And Log    sudo pip install -U --verbose os-testr>=1.0.0    timeout=120s
    DevstackUtils.Write Commands Until Prompt And Log    ostestr --version
    DevstackUtils.Write Commands Until Prompt And Log    testr init
    DevstackUtils.Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    DevstackUtils.Write Commands Until Prompt    sudo rm -rf /opt/stack/tempest/.testrepository
    ${net_id} =    OpenStackOperations.Get Net Id    ${EXTERNAL_NET_NAME}
    Tempest.Tempest Conf Add External Network And Floating Network Name    ${net_id}

Tempest Conf Add External Network And Floating Network Name
    [Arguments]    ${external_network_id}
    [Documentation]    Tempest will be run with a config file - this function will add the
    ...    given external network ID to the configuration file.
    Tempest.Modify Config In File On Existing SSH Connection    ${TEMPEST_CONFIG_FILE}    set    network    public_network_id    ${external_network_id}
    Tempest.Modify Config In File On Existing SSH Connection    ${TEMPEST_CONFIG_FILE}    set    DEFAULT    debug    False
    Tempest.Modify Config In File On Existing SSH Connection    ${TEMPEST_CONFIG_FILE}    set    DEFAULT    log_level    INFO
    Tempest.Modify Config In File On Existing SSH Connection    ${TEMPEST_CONFIG_FILE}    set    network    floating_network_name    ${EXTERNAL_NET_NAME}
    DevstackUtils.Write Commands Until Prompt    sudo cat ${TEMPEST_CONFIG_FILE}
    DevstackUtils.Write Commands Until Prompt    sudo chmod 777 ${TEMPEST_CONFIG_FILE}

Tempest Conf Modify Pause On Test Teardown
    [Arguments]    ${pause_flag}
    [Documentation]    Sets the DEFAULT section flag for pausing the test teardown. If True the tempest test case
    ...    being executed will break to a pdb() debug shell when it hits it's teardown() function.
    Tempest.Modify Config In File On Existing SSH Connection    ${TEMPEST_CONFIG_FILE}    set    DEFAULT    pause_teardown    ${pause_flag}

Modify Config In File On Existing SSH Connection
    [Arguments]    ${config_file}    ${modifier}    ${config_section}    ${config_key}    ${config_value}=${EMPTY}
    [Documentation]    uses crudini to populate oslo cofg file.
    # this keyword is only one line so seems like extra overhead, but this may be a good candidate to move
    # to a library at some point, when/if other suites need to use it, so wanted to make it generic.
    DevstackUtils.Write Commands Until Prompt    sudo -E crudini --${modifier} ${config_file} ${config_section} ${config_key} ${config_value}

Create Blacklist File
    [Documentation]    For each exclusion regex in the required @{${OPENSTACK_BRANCH}_EXCLUSION_REGEXES} list a new
    ...    line will be created in the required ${BLACKLIST_FILE} location. This file is pushed to the OS_CONTROL_NODE
    ...    which is assumed to be the tempest executor.
    OperatingSystem.Create File    ${BLACKLIST_FILE}
    : FOR    ${exclusion}    IN    @{${OPENSTACK_BRANCH}_EXCLUSION_REGEXES}
    \    OperatingSystem.Append To File    ${BLACKLIST_FILE}    ${exclusion}\n
    OperatingSystem.Log File    ${BLACKLIST_FILE}
    SSHKeywords.Copy File To Remote System    ${OS_CONTROL_NODE_IP}    ${BLACKLIST_FILE}    ${BLACKLIST_FILE}
