*** Settings ***
Documentation     Test suite for running rally tests. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
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

**** Test Cases ***
Run Rally
    [Arguments]    ${rally_directory}=/opt/stack/rally    ${timeout}=600s
    [Documentation]    Run Rally
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Write Commands Until Prompt    cd ${rally_directory}
    ${results}=    Write Commands Until Prompt    rally task start samples/tasks/scenarios/nova/boot-and-delete.json    timeout=${timeout}
    Log    ${results}
    Create File    rally_output.log    data=${results}
    Write Commands Until Prompt    rally task report --out=rally.html    timeout=${timeout}
