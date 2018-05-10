*** Settings ***
Documentation     Test Suite for QoS marking and rate limiting
Suite Setup       Create Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

${QOS_POLICY_NAME}   qos_policy1 
${QOS_URL}    ${CONFIG_API}/neutron:neutron/qos-policies/
${MAX_KBPS}    10000
${MAX_BURST}    1000
${MAX_KBPS_NEW}    20000
${DSCP_MARK_VALUE}    38

*** Testcases ***

Verify Qos Policy Creation
    [Documentation]    Creating QoS Policy via CLI and verifying in Controller and Openstack.
    ${policy_id}    Create Qos Policy    ${QOS_POLICY_NAME}
    ${elements}    Create List     ${policy_id}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    List Qos Policy    ${policy_id}

Verify Qos Policy Updation (Updating --share attribute)
    Update Qos Policy    ${QOS_POLICY_NAME}    --share
    ${elements}    Create List     ${QOS_POLICY_NAME}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    List Qos Policy    ${QOS_POLICY_NAME}

Verify Qos Policy Deletion
    [Documentation]    Deleting QoS Policy via CLI and verifying in Controller and Openstack.
    Delete Qos Policy    ${QOS_POLICY_NAME}
    ${elements}    Create List     ${QOS_POLICY_NAME}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements Not At URI    ${QOS_URL}    ${elements}
    No Qos Policy In List    ${QOS_POLICY_NAME}

Verify Qos Policy With Bandwidth Rule Create ,Update and Delete
    [Documentation]    Creating QoS policy with Bandwidth rule create, update and delete.
    ...    Verifying in CONTROLLER and OPENSTACK.
    ${policy_id}    Create Qos Policy    ${QOS_POLICY_NAME}
    ${elements}    Create List     ${policy_id}
    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    List Qos Policy    ${policy_id}
    ${arg}    Catenate    --max-kbps ${max_kbps}    --max-burst-kbits ${max_burst}
    ${bandwidth_id}    Create Qos Bandwidth Rule    ${QOS_POLICY_NAME}    ${arg}
    ${elements}    Create List     ${bandwidth_id}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    Update Qos Bandwidth Rule    ${bandwidth_id}    ${policy_id}    --max-kbps ${MAX_KBPS_NEW}
    ${elements}    Create List    ${bandwidth_id}    ${MAX_KBPS_NEW}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    List Qos Bandwidth Rule    ${QOS_POLICY_NAME}    ${bandwidth_id}
    Delete Qos Bandwidth Rule    ${QOS_POLICY_NAME}    ${bandwidth_id}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements Not At URI    ${QOS_URL}    ${elements}
    No Bandwidth Rule In List    ${QOS_POLICY_NAME}    ${bandwidth_id}
    Delete Qos Policy    ${QOS_POLICY_NAME}

Verify DSCP Marking Rule Create, Update and Delete
    [Documentation]    Creating QoS policy with DSCP mark rule create, update and delete.
    ...    Verifying in CONTROLLER and OPENSTACK.
    ${policy_id}    Create Qos Policy    ${QOS_POLICY_NAME}
    ${elements}    Create List     ${policy_id}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    List Qos Policy    ${policy_id}
    ${dscp_id}    Create Qos Dscp Rule    ${policy_id}    --dscp-mark ${DSCP_MARK_VALUE}
    ${elements}    Create List     ${dscp_id}    ${policy_id}    ${DSCP_MARK_VALUE}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    Show Qos Policy    ${QOS_POLICY_NAME}    ${dscp_id}    ${policy_id}
    Update Qos Dscp Rule    ${dscp_id}    ${policy_id}    --dscp-mark 36
    ${elements}    Create List     ${dscp_id}    ${policy_id}    36
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    Show Qos Policy    ${QOS_POLICY_NAME}    ${dscp_id}    ${policy_id}
    Delete Qos Dscp Rule    ${dscp_id}    ${policy_id}
    ${elements}    Create List     ${dscp_id}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements Not At URI    ${QOS_URL}    ${elements}
    No Bandwidth Rule In List    ${QOS_POLICY_NAME}    ${dscp_id}
    Delete Qos Policy    ${QOS_POLICY_NAME}

Verifying variation In Configuring Bandwidth Rule In Qos_policy
    [Documentation]    Creating bandwidth rule with and updating rule with another value and verifying in OPENSTACK and CONTROLLER.
    ${policy_id}    Create Qos Policy    ${QOS_POLICY_NAME}
    ${elements}    Create List     ${policy_id}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    List Qos Policy    ${policy_id}
    ${arg}    Catenate    --max-kbps ${max_kbps}    --max-burst-kbits ${max_burst}
    ${bandwidth_id}    Create Qos Bandwidth Rule    ${QOS_POLICY_NAME}    ${arg}
    ${elements}    Create List     ${bandwidth_id}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    Update Qos Bandwidth Rule    ${bandwidth_id}    ${policy_id}    --max-kbps ${MAX_KBPS_NEW}
    ${elements}    Create List    ${bandwidth_id}    ${MAX_KBPS_NEW}
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    List Qos Bandwidth Rule    ${QOS_POLICY_NAME}    ${bandwidth_id}
    Update Qos Bandwidth Rule    ${bandwidth_id}    ${policy_id}    --max-kbps    50000
    ${elements}    Create List    ${bandwidth_id}    50000
    Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${QOS_URL}    ${elements}
    List Qos Bandwidth Rule    ${QOS_POLICY_NAME}    ${bandwidth_id}
    Delete Qos Policy    ${QOS_POLICY_NAME}

*** Keywords ***

Create Setup
    [Documentation]    Creates initial setup.
    VpnOperations.Basic Suite Setup

Create Qos Policy
    [Arguments]    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Creates neutron qos-policy with neutron request.
    ...    QoS Policy name should be sent as argument
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos policy create ${qos_policy_name} ${additional_args}
    ${policy_id}    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    [Return]    ${policy_id}

List Qos Policy
    [Arguments]    @{elements}
    [Documentation]    Lists all neutron qos policies with neutron request.
    ...    QoS Policy name should be sent as argument
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos policy list
    : FOR    ${element}    IN    @{elements}
    \    Should Contain    ${output}    ${element}

No Qos Policy In List
    [Arguments]    ${qos_policy_name}
    [Documentation]    Lists all neutron qos policies with neutron request.
    ...    QoS Policy name should be sent as argument
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos policy list
    Should Not Contain    ${output}    ${qos_policy_name}

Update Qos Policy
    [Arguments]    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Updates neutron qos-policy with neutron request.
    ...    QoS Policy name should be sent as argument
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos policy set ${qos_policy_name} ${additional_args}

Delete Qos Policy
    [Arguments]    ${qos_policy_name}
    [Documentation]    Deletes neutron qos-policy with neutron request.
    ...    QoS Policy name should be sent as argument
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos policy delete ${qos_policy_name}

Create Qos Bandwidth Rule
    [Arguments]    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Creates a neutron QoS bandwidth rule with neutron request.
    ...    QoS policy id needs to be sent as argument.
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos rule create --type bandwidth-limit ${additional_args} ${qos_policy_name}
    ${bandwidth_id}    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    [Return]    ${bandwidth_id}

Update Qos Bandwidth Rule
    [Arguments]    ${bandwidth_id}    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Updates a neutron QoS bandwidth rule with neutron request.
    ...    QoS policy id needs to be sent as arguments.
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos rule set ${additional_args} ${qos_policy_name} ${bandwidth_id}

Delete Qos Bandwidth Rule
    [Arguments]    ${qos_policy_name}    ${bandwidth_id}
    [Documentation]    Deletes a neutron QoS bandwidth rule with neutron request.
    ...    QoS policy id needs to be sent as arguments.
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos rule delete ${qos_policy_name} ${bandwidth_id}

List Qos Bandwidth Rule
    [Arguments]    ${qos_policy_name}    ${bandwidth_id}    ${additional_args}=${EMPTY}
    [Documentation]    Lists Bandwidth rule list for a given qos policy.
    ...    QoS Policy ID and bandwidth ID needs to be sent as arguments.
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos rule list ${qos_policy_name}
    Should Contain    ${output}    ${bandwidth_id}

No Bandwidth Rule In List
    [Arguments]    ${qos_policy_name}    ${bandwidth_id}    ${additional_args}=${EMPTY}
    [Documentation]    Lists Bandwidth rule list for a given qos policy.
    ...    QoS Policy ID and bandwidth ID needs to be sent as arguments.
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos rule list ${qos_policy_name}
    Should Not Contain    ${output}    ${bandwidth_id}

Create Qos Dscp Rule
    [Arguments]    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Creates a neutron QoS dscp rule with neutron request.
    ...    QoS policy id needs to be sent as argument.
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos rule create --type dscp-marking ${additional_args} ${qos_policy_name}
    ${dscp_id}    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    [Return]    ${dscp_id}

Update Qos Dscp Rule
    [Arguments]    ${dscp_id}    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Updates QoS dscp rule with neutron request.
    ...    QoS policy id needs to be sent as arguments.
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos rule set ${additional_args} ${qos_policy_name} ${dscp_id}

Delete Qos Dscp Rule
    [Arguments]    ${qos_policy_name}    ${dscp_id}
    [Documentation]    Deletes dscp rule with neutron request.
    ...    QoS policy id needs to be sent as arguments.
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos rule delete ${dscp_id} ${qos_policy_name}

Show Qos Policy
    [Arguments]    ${qos_policy_name}    @{elements}
    [Documentation]    Displays a given qos-policy data with neutron request.
    ...    QoS Policy name should be sent as argument
    ${output}    OpenStackOperations.OpenStack CLI    openstack network qos policy show ${qos_policy_name}
    : FOR    ${element}    IN    @{elements}
    \    Should Contain    ${output}    ${element}
