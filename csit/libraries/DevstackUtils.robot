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

*** Keywords ***
Run Tempest Tests
    [Arguments]    ${tempest_regex}    ${exclusion_file}=/dev/null    ${tempest_conf}=""    ${tempest_directory}=/opt/stack/tempest    ${timeout}=600s
    [Documentation]    Execute the tempest tests.
    Return From Keyword If    "skip_if_${OPENSTACK_BRANCH}" in @{TEST_TAGS}
    Return From Keyword If    "skip_if_${SECURITY_GROUP_MODE}" in @{TEST_TAGS}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    # There seems to be a bug in the mitaka version of os-testr that does not allow --regex to work in conjunction
    # with a blacklist-file. Upgrading with pip should resolve this. This can probably go away once mitaka is no
    # longer tested in this environment. But, while it's being tested the mitaka devstack setup will be bringing
    # in this broken os-testr, so we manually upgrade here.
    Write Commands Until Prompt    sudo pip install os-testr --upgrade    timeout=120s
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    cd ${tempest_directory}
    # From Ocata and moving forward, we can replace 'ostestr' with 'tempest run'
    ${results}=    Write Commands Until Prompt    ostestr --regex ${tempest_regex} -b ${exclusion_file}    timeout=${timeout}
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
