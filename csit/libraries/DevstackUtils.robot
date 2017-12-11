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
Resource          ../variables/Variables.robot

*** Variables ***
${default_devstack_prompt_timeout}    10s
${DEVSTACK_SYSTEM_PASSWORD}    \    # set to empty, but provide for others to override if desired
${blacklist_file}    /tmp/blacklist.txt
@{stable/newton_exclusion_regexes}    ${EMPTY}
@{stable/ocata_exclusion_regexes}    ${EMPTY}
@{stable/pike_exclusion_regexes}    ${EMPTY}
@{master_exclusion_regexes}    ${EMPTY}
${tempest_dir}    /opt/stack/tempest
${tempest_config_file}    ${tempest_dir}/etc/tempest.conf
${external_physical_network}    physnet1
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${external_gateway}    10.10.10.250
${external_subnet_allocation_pool}    start=10.10.10.2,end=10.10.10.249
${external_subnet}    10.10.10.0/24
${TEMPEST_TIMEOUT}    420s
${OS_CNTL_CONN_ID}    None
${OS_CMP1_CONN_ID}    None
${OS_CMP2_CONN_ID}    None
${OS_CNTL_IP}     ${EMPTY}
${OS_CMP1_IP}     ${EMPTY}
${OS_CMP2_IP}     ${EMPTY}
@{OS_ALL_IPS}     @{EMPTY}
@{OS_CMP_IPS}     @{EMPTY}

*** Keywords ***
Run Tempest Tests
    [Arguments]    ${tempest_regex}    ${timeout}=${TEMPEST_TIMEOUT}    ${debug}=False
    Run Keyword If    "${debug}"=="False"    Run Tempest Tests Without Debug    ${tempest_regex}    timeout=${timeout}
    Run Keyword If    "${debug}"=="True"    Run Tempest Tests With Debug    ${tempest_regex}    timeout=${timeout}
    Run Keyword If    "${debug}"!="True" and "${debug}"!="False"    Fail    debug argument must be True or False

Run Tempest Tests Without Debug
    [Arguments]    ${tempest_regex}    ${tempest_directory}=${tempest_dir}    ${timeout}=${TEMPEST_TIMEOUT}
    [Documentation]    Using ostestr will allow us to (by default) run tests in paralllel.
    ...    Because of the parallel fashion, we must ensure there is no pause on teardown so that flag in tempest.conf is
    ...    explicitly set to False.
    Return From Keyword If    "skip_if_${OPENSTACK_BRANCH}" in @{TEST_TAGS}
    Return From Keyword If    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}
    ${tempest_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    cd ${tempest_directory}
    SSHLibrary.Read
    Tempest Conf Modify Pause On Test Teardown    False
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    # There are tons of deprecation error messages when we use ostestr in our CSIT environment (openstack via devstack)
    # The robot log files are very large and one culprit is all these deprecation warnings. If we redirect stderr to
    # /dev/null we should be able to ignore them. We will miss any other errors, however.
    ${output}=    Write Commands Until Prompt    ostestr --regex ${tempest_regex} 2>/dev/null    timeout=${timeout}
    Log    ${output}
    SSHLibrary.Close Connection
    Should Contain    ${output}    Failed: 0

Run Tempest Tests With Debug
    [Arguments]    ${tempest_regex}    ${tempest_directory}=${tempest_dir}    ${timeout}=${TEMPEST_TIMEOUT}
    [Documentation]    After setting pause_teardown=True in tempest.conf, use the python -m testtools.run module to execute
    ...    a single tempest test case. We need to run only one tempest test case at a time as there will
    ...    be potentional for an unkown number of debug pdb() prompts to catch and continue if we are running multiple
    ...    test cases with a single command. Essentially, this keyword only handles one breakpoint at a single teardown.
    Return From Keyword If    "skip_if_${OPENSTACK_BRANCH}" in @{TEST_TAGS}
    Return From Keyword If    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}
    ${tempest_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    cd ${tempest_directory}
    SSHLibrary.Read
    Tempest Conf Modify Pause On Test Teardown    True
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Write    python -m testtools.run ${tempest_regex}
    ${output}=    SSHLibrary.Read Until Regexp    ${DEFAULT_LINUX_PROMPT_STRICT}|pdb.set_trace()
    Log    ${output}
    Show Debugs
    Get Test Teardown Debugs
    SSHLibrary.Switch Connection    ${tempest_conn_id}
    SSHLibrary.Write    continue
    ${output}=    SSHLibrary.Read Until Regexp    ${DEFAULT_LINUX_PROMPT_STRICT}|pdb.set_trace()
    Log    ${output}
    SSHLibrary.Write    continue
    ${output}=    SSHLibrary.Read Until Prompt
    Log    ${output}
    SSHLibrary.Close Connection
    Should Contain    ${output}    OK
    Should Not Contain    ${output}    FAILED

Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    Log In To Tempest Executor And Setup Test Environment

Log In To Tempest Executor And Setup Test Environment
    [Documentation]    Initialize SetupUtils, open SSH connection to a devstack system and source the openstack
    ...    credentials needed to run the tempest tests. The (sometimes empty) tempest blacklist file will be created
    ...    and pushed to the tempest executor.
    Create Blacklist File
    # Tempest tests need an existing external network in order to create routers.
    Create Network    ${EXTERNAL_NET_NAME}    --external --default --provider-network-type flat --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK}
    Create Subnet    ${EXTERNAL_NET_NAME}    ${EXTERNAL_SUBNET_NAME}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    List Networks
    ${control_node_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    sudo rm -rf /opt/stack/tempest/.testrepository
    ${net_id}=    Get Net Id    ${external_net_name}
    Tempest Conf Add External Network And Floating Network Name    ${net_id}

Tempest Conf Add External Network And Floating Network Name
    [Arguments]    ${external_network_id}
    [Documentation]    Tempest will be run with a config file - this function will add the
    ...    given external network ID to the configuration file.
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    network    public_network_id    ${external_network_id}
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    DEFAULT    debug    False
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    DEFAULT    log_level    INFO
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    network    floating_network_name    ${external_net_name}
    Write Commands Until Prompt    sudo cat ${tempest_config_file}
    Write Commands Until Prompt    sudo chmod 777 ${tempest_config_file}

Tempest Conf Modify Pause On Test Teardown
    [Arguments]    ${pause_flag}
    [Documentation]    Sets the DEFAULT section flag for pausing the test teardown. If True the tempest test case
    ...    being executed will break to a pdb() debug shell when it hits it's teardown() function.
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    DEFAULT    pause_teardown    ${pause_flag}

Modify Config In File On Existing SSH Connection
    [Arguments]    ${config_file}    ${modifier}    ${config_section}    ${config_key}    ${config_value}=${EMPTY}
    [Documentation]    uses crudini to populate oslo cofg file.
    # this keyword is only one line so seems like extra overhead, but this may be a good candidate to move
    # to a library at some point, when/if other suites need to use it, so wanted to make it generic.
    Write Commands Until Prompt    sudo -E crudini --${modifier} ${config_file} ${config_section} ${config_key} ${config_value}

Create Blacklist File
    [Documentation]    For each exclusion regex in the required @{${OPENSTACK_BRANCH}_exclusion_regexes} list a new
    ...    line will be created in the required ${blacklist_file} location. This file is pushed to the OS_CONTROL_NODE
    ...    which is assumed to be the tempest executor.
    OperatingSystem.Create File    ${blacklist_file}
    : FOR    ${exclusion}    IN    @{${OPENSTACK_BRANCH}_exclusion_regexes}
    \    OperatingSystem.Append To File    ${blacklist_file}    ${exclusion}\n
    Log File    ${blacklist_file}
    SSHKeywords.Copy File To Remote System    ${OS_CONTROL_NODE_IP}    ${blacklist_file}    ${blacklist_file}

Open Connection
    [Arguments]    ${name}    ${ip}
    ${conn_id} =    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    BuiltIn.Set Suite Variable    \${${name}}    ${conn_id}
    [Return]    ${conn_id}

Devstack Suite Setup
    [Arguments]    ${odl_ip}=${ODL_SYSTEM_IP}
    [Documentation]    Open connections to the nodes
    Get DevStack Nodes Data
    Create Session    session    http://${odl_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    SSHLibrary.Set Default Configuration    timeout=${default_devstack_prompt_timeout}
    Run Keyword If    0 < ${NUM_OS_SYSTEM}    Open Connection    OS_CNTL_CONN_ID    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Open Connection    OS_CMP1_CONN_ID    ${OS_COMPUTE_1_IP}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Open Connection    OS_CMP2_CONN_ID    ${OS_COMPUTE_2_IP}

Write Commands Until Prompt
    [Arguments]    ${cmd}    ${timeout}=${default_devstack_prompt_timeout}
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    Log    ${cmd}
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Read
    SSHLibrary.Write    ${cmd};echo Command Returns $?
    ${output}=    SSHLibrary.Read Until Prompt
    [Return]    ${output}

Write Commands Until Prompt And Log
    [Arguments]    ${cmd}    ${timeout}=${default_devstack_prompt_timeout}
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    ${output} =    Write Commands Until Prompt    ${cmd}    ${timeout}
    Log    ${output}
    [Return]    ${output}

Log Devstack Nodes Data
    ${output} =    BuiltIn.Catenate    SEPARATOR=\n    OS_CNTL_HOSTNAME: ${OS_CNTL_HOSTNAME} - OS_CNTL_IP: ${OS_CNTL_IP} - OS_CONTROL_NODE_IP: ${OS_CONTROL_NODE_IP}    OS_CMP1_HOSTNAME: ${OS_CMP1_HOSTNAME} - OS_CMP1_IP: ${OS_CMP1_IP} - OS_COMPUTE_1_IP: ${OS_COMPUTE_1_IP}    OS_CMP2_HOSTNAME: ${OS_CMP2_HOSTNAME} - OS_CMP2_IP: ${OS_CMP2_IP} - OS_COMPUTE_2_IP: ${OS_COMPUTE_2_IP}    OS_ALL_IPS: @{OS_ALL_IPS}
    ...    OS_CMP_IPS: @{OS_CMP_IPS}
    BuiltIn.Log    DevStack Nodes Data:\n${output}

Get DevStack Hostnames
    [Documentation]    Assign hostname global variables for DevStack nodes
    ${OS_CNTL_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CNTL_IP}
    ${OS_CMP1_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CMP1_IP}
    ${OS_CMP2_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    ${OS_CNTL_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_CMP1_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_CMP2_HOSTNAME}

Set Node Data For Control And Compute Node Setup
    [Documentation]    Assign global variables for DevStack nodes where the control node is also the compute
    BuiltIn.Set Suite Variable    ${OS_CMP1_IP}    ${OS_CNTL_IP}
    BuiltIn.Set Suite Variable    ${OS_CMP2_IP}    ${OS_COMPUTE_1_IP}
    BuiltIn.Set Suite Variable    @{OS_ALL_IPS}    ${OS_CNTL_IP}    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    @{OS_CMP_IPS}    ${OS_CMP1_IP}    ${OS_CMP2_IP}

Set Node Data For Control Only Node Setup
    [Documentation]    Assign global variables for DevStack nodes where the control node is different than the compute
    BuiltIn.Set Suite Variable    ${OS_CMP1_IP}    ${OS_COMPUTE_1_IP}
    BuiltIn.Set Suite Variable    ${OS_CMP2_IP}    ${OS_COMPUTE_2_IP}
    BuiltIn.Set Suite Variable    @{OS_ALL_IPS}    ${OS_CNTL_IP}    ${OS_CMP1_IP}    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    @{OS_CMP_IPS}    ${OS_CMP1_IP}    ${OS_CMP2_IP}

Get DevStack Nodes Data
    [Documentation]    Assign global variables for DevStack nodes
    BuiltIn.Set Suite Variable    ${OS_CNTL_IP}    ${OS_CONTROL_NODE_IP}
    Run Keyword If    '${OS_COMPUTE_2_IP}' == '${EMPTY}'    Set Node Data For Control And Compute Node Setup
    ...    ELSE    Set Node Data For Control Only Node Setup
    Get DevStack Hostnames
    Log Devstack Nodes Data
