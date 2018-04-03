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
    OpenStackOperations.OpenStack Suite Teardown
    LiveMigration.UnSet Live Migrtion In Compute Nodes

Setup Live Migration In Compute Nodes
    [Documentation]    Set instances to be created in the shared directory.
    OpenStackOperations.Modify OpenStack Configuration File    ${OS_CMP1_CONN_ID}    ${NOVA_CPU_CONF}    DEFAULT    instances_path    ${CMP_INSTANCES_SHARED_PATH}
    OpenStackOperations.Modify OpenStack Configuration File    ${OS_CMP2_CONN_ID}    ${NOVA_CPU_CONF}    DEFAULT    instances_path    ${CMP_INSTANCES_SHARED_PATH}
    OpenStackOperations.Restart DevStack Service    ${OS_CMP1_CONN_ID}    ${NOVA_COMPUTE_SERVICE}
    OpenStackOperations.Restart DevStack Service    ${OS_CMP2_CONN_ID}    ${NOVA_COMPUTE_SERVICE}

UnSet Live Migration In Compute Nodes
    [Documentation]    Clear settings done for Live Migration
    OpenStackOperations.Modify OpenStack Configuration File    ${OS_CMP1_CONN_ID}    ${NOVA_CPU_CONF}    DEFAULT    instances_path    ${CMP_INSTANCES_DEFAULT_PATH}
    OpenStackOperations.Modify OpenStack Configuration File    ${OS_CMP2_CONN_ID}    ${NOVA_CPU_CONF}    DEFAULT    instances_path    ${CMP_INSTANCES_DEFAULT_PATH}
    OpenStackOperations.Restart DevStack Service    ${OS_CMP1_CONN_ID}    ${NOVA_COMPUTE_SERVICE}
    OpenStackOperations.Restart DevStack Service    ${OS_CMP2_CONN_ID}    ${NOVA_COMPUTE_SERVICE}
