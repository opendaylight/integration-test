*** Settings ***
Documentation     Test suite for running rally tests. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Report And Clean Up After Running Rally
Test Template     DevstackUtils.Run Rally Task
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${tasks_dir}    /opt/stack/rally/rally-jobs
${sample_tasks_dir}    /opt/stack/rally/samples/tasks/scenarios/neutron
${nodl_tasks_dir}    /opt/stack/networking-odl/rally-jobs
${neutron_tasks_dir}    /opt/stack/neutron/rally-jobs

*** Test Cases ***
odl.yaml
    ${nodl_tasks_dir}/${TEST_NAME}

neutron-neutron.yaml
    ${neutron_tasks_dir}/${TEST_NAME}

rally-neutron.yaml
    ${tasks_dir}/${TEST_NAME}

nova.yaml
    ${tasks_dir}/${TEST_NAME}

create-and-delete-floating-ips.yaml
    ${sample_tasks_dir}/${TEST_NAME}

create-and-delete-networks.yaml
    ${sample_tasks_dir}/${TEST_NAME}

*** Keywords ***
Report And Clean Up After Running Rally
    [Arguments]    ${rally_directory}=/opt/stack/rally    ${timeout}=600s
    [Documentation]    Generates a rally report and closes all connections
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Write Commands Until Prompt    cd ${rally_directory}
    ${results}=    Write Commands Until Prompt    rally task report --out=rally.html    timeout=${timeout}
    Log    ${results}
    Close All Connections
