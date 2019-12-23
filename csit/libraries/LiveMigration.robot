*** Settings ***
Documentation     Live Migration Library, This can be used by Live Migration tests.
Library           SSHLibrary
Resource          DevstackUtils.robot
Resource          OpenStackOperations.robot
Resource          SSHKeywords.robot
Resource          ../variables/Variables.robot

*** Variables ***
${NOVA_CPU_CONF}    /etc/nova/nova-cpu.conf
${NOVA_COMPUTE_SERVICE}    n-cpu
${CMP_INSTANCES_DEFAULT_PATH}    /opt/stack/data/nova/instances

*** Keywords ***
Live Migration Suite Setup
    [Documentation]    Suite Setup For Live Migration Tests
    OpenStackOperations.OpenStack Suite Setup
    LiveMigration.Setup Live Migration In Compute Nodes

Live Migration Suite Teardown
    [Documentation]    Suite Teardown for Live Migration Tests
    LiveMigration.UnSet Live Migration In Compute Nodes
    OpenStackOperations.OpenStack Suite Teardown

Setup Live Migration In Compute Nodes
    [Documentation]    Set instances to be created in the shared directory.
    FOR    ${conn_id}    IN    @{OS_CMP_CONN_IDS}
        OpenStackOperations.Modify OpenStack Configuration File    ${conn_id}    ${NOVA_CPU_CONF}    DEFAULT    instances_path    ${CMP_INSTANCES_SHARED_PATH}
        OpenStackOperations.Restart DevStack Service    ${conn_id}    ${NOVA_COMPUTE_SERVICE}
    END

UnSet Live Migration In Compute Nodes
    [Documentation]    Clear settings done for Live Migration
    FOR    ${conn_id}    IN    @{OS_CMP_CONN_IDS}
        OpenStackOperations.Modify OpenStack Configuration File    ${conn_id}    ${NOVA_CPU_CONF}    DEFAULT    instances_path    ${CMP_INSTANCES_DEFAULT_PATH}
        OpenStackOperations.Restart DevStack Service    ${conn_id}    ${NOVA_COMPUTE_SERVICE}
    END
