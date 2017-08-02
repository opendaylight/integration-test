*** Settings ***
Documentation     Test Suite for Operational Improvements of ACL
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Resource          ../../../libraries/Utils.robot
Library           Collections
Library           string
Resource          ../../../libraries/KarafKeywords.robot
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
@{stack_login}    stack    stack
${devstack_path}    /opt/stack/devstack
@{Networks}       SG_Net_1    SG_Net_2
@{Subnet}         SG_Sub_1    SG_Sub_2
@{prefix_list}    30.20.20.0/24
${sg_name}        Sg_rule1
@{direction}      ingress    egress    both
${protocol}       tcp
${flavour}        m1.tiny
@{port_name}      sg_port1    sg_port2    sg_port3    sg_port4
@{VM_list}        Sg_test_VM1    Sg_test_VM2    Sg_test_VM3    Sg_test_VM4
@{protocols}      icmp    tcp    udp
${itm}            TZA

*** Keywords ***
Start Suite
    [Documentation]    Start suite for Pre-configs done prior executing the testcases.

${EMPTY}

Devstack Login
    [Arguments]    ${ip}    ${username}    ${password}    ${devstack_path}    ${prompt}
    [Documentation]    This keyword does a login to devstack.
    ${dev_stack_conn_id}=    SSHLibrary.Open Connection    ${ip}    prompt=${prompt}
    set suite variable    ${dev_stack_conn_id}
    log    ${username},${password}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${devstack_path}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

Delete Default Rules
    [Documentation]    This keyword deletes the default Egress rules when custom security group is created
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${list_default_rules}    Write Commands Until Prompt    neutron security-group-rule-list | grep ${sg_name}| awk '{print$2}'
    log    ${list_default_rules}
    @{array}    split string    ${list_default_rules}    \n
    log    ${array}
    ${deleted}    Write Commands Until Prompt    neutron security-group-rule-delete ${array[0]}
    log    ${deleted}
    ${deleted_rule}    Write Commands Until Prompt    neutron security-group-rule-delete ${array[1]}
    log    ${deleted_rule}
    Close Connection

flavour create
    [Arguments]    ${flavour}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${flavour_create}    Write Commands Until Prompt    nova flavor-create ${flavour} 101 2048 6 2    30
    ${memory_allocate}    Write Commands Until Prompt    nova flavor-key ${flavour} set hw:mem_page_size=1048576    30

check establishment
    [Arguments]    ${conn_id}    ${port}
    [Documentation]    Checks the establisment status for port 6640 and 6633
    Switch Connection    ${conn_id}
    ${check_establishment}    Execute Command    netstat -anp | grep ${port}
    Should contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Stop Suite
    [Documentation]    Stop suite does a suite tear down at the end
    log    closing the session
