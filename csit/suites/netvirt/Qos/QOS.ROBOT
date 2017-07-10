*** Settings ***
Documentation     Test Suite for Qos Policy in neutron ports and Network.

Suite Setup       BuiltIn.Run Keywords    DevstackUtils.Devstack Suite Setup
...               AND    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    CREATE SETUP
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs

Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot


*** Variables ***
@{NETWORKS}       NETWORK1    NETWORK2    NETWORK3    NETWORK4
@{SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4
@{SUBNET_CIDR}    11.1.1.0/24    21.1.1.0/24    31.1.1.0/24    41.1.1.0/24
@{PORT}           PORT1    PORT2    PORT3    PORT4    PORT5    PORT6    PORT7
...               PORT8
${PORT13}         SUBPORT13
${PORT14}         SUBPORT14
${Table_id}       90
${qos_name}       qos_policy
${qos_port}       qos
${qos}            q1
${max_kbps}       10000
${max_burst}      2000
${max_kbps_port7}    20000
${max_burst_port7}    4000
${max_kbps_new}    9000
${max_burst_new}    1800
${max_kbps_port}    14000
${max_burst_port}    2800
${max_kbps_net}    12000
${max_burst_net}    2400
${rate_limit}     8000
${rate_limit_port}    20000
${rate_limit_net}    10000
${rate_limiting_port}    12000
${dscp_mark}      20
${dscp_mark_value}    36
${dscp_mark_value_new}    30
${vid4}           4000
${PORT14_IP}      41.1.1.200
@{VM_INSTANCES_NET1}    VM1    VM2    VM7
@{VM_INSTANCES_NET2}    VM3    VM4    VM4
${VM_INSTANCES_NET3}    VM5
${VM_INSTANCES_NET4}    VM6    VM8
${ROUTER}         ROUTER1
${SGP}            ACL
${CONF}           /restconf/config/ebgp:bgp/
${Qos_CONF}       /restconf/config/neutron:neutron/qos-policies/
${LOG_FILE2}      tmp.txt
${SECURITY_GROUPS}    --security-group
${uri_sub}       /restconf/config/neutron:neutron/ports/
${uri}            /restconf/config/neutron:neutron/ports/port/
${trunk}          "neutron:neutron-port-ext:type": "neutron-port-ext:trunkport-type-trunkport"

*** Testcases ***
TC01 Verify Qos Policy Creation
    [Documentation]    This testcase verifies QOS Policy creation.
    [Tags]    Regression
    ${exp_result}    ConvertToInteger    0
    Log    "Verify that QoS policy is created through the OPENSTACK"
    Log    " Qos_Policy creation"
    ${output}    ${policy_id}    Neutron Qos_policy Creation    ${qos_name}
    Log    ${output}
    Log    ${policy_id}
    ${resp}    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Log    ${resp}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${policy_id}
    Log    "Verfiying Qos creation on openstack"
    ${resp}    Neutron Qos_policy List
    Should Contain    ${OUTPUT}    ${policy_id}

TC02 Verify Qos Policy Deletion
    [Documentation]    This testcase verifies QOS Policy deletion.
    [Tags]    Regression
    ${exp_result}    ConvertToInteger    0
    Log    "Verify that QoS policy deletion through the OPENSTACK"
    Log    "Qos_policy deletion"
    ${output}    Neutron Qos_policy deletion    ${qos_name}
    Log    ${output}
    Should Match Regexp    ${output}    Deleted qos_policy: ${qos_name}|Deleted qos_policy\\(s\\): ${qos_name}
    Log    "Verifying qos deletion in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${qos_name}

TC03 Verify Qos Policy Updation
    [Documentation]    This testcase verifies QOS Policy updation.
    [Tags]    Regression
    ${exp_result}    ConvertToInteger    0
    Log    "Creation of qos_policy creation"
    ${output}    ${policy_id}    Neutron Qos_policy Creation    ${qos_name}
    Log    ${output}
    Log    ${policy_id}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${policy_id}
    Log    "Verify that QoS policy updated through the OPENSTACK"
    Log    " Qos_policy updation"
    ${output}    Neutron Qos_policy updation    ${qos_name}    --shared
    Log    ${output}
    Should Contain    ${output}    Updated policy
    Log    "Verifying qos deletion in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${qos_name}
    Log    "Fetching the flows from DPN1 and DPN2"
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    [Teardown]    Neutron Qos_policy deletion    ${qos_name}

TC04 Verify Qos Policy With Bandwidth Creation ,Updation and Deletion
    [Documentation]    Verify Qos Policy With Bandwidth Creation ,Updation and Deletion
    
    Log    "Verify that able to create the bandwidth role through OPENSTACK command"
    Log    "Creation of qos_policy creation"
    ${output}    ${policy_id}    Neutron Qos_policy Creation    ${qos_name}
    Log    ${output}
    Log    ${policy_id}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${policy_id}
    Log    "Applying bandwidth in qos_policy"
    ${arg}    Catenate    --max-kbps ${max_kbps}    --max-burst-kbps ${max_burst}
    ${output}    ${bandwidth_id}    Neutron Qos_policy Bandwidth Rule Creation    ${policy_id}    ${arg}
    Log    ${output}
    Log    ${bandwidth_id}
    Log    "Verifying bandwidth rule is implentated on qos_policy"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${bandwidth_id}
    Log    "Verifying bandwidth updation"
    ${output}    Neutron Qos_policy Bandwidth Rule Updation    ${bandwidth_id}    ${policy_id}    --max-kbps ${max_kbps_new}
    Log    ${output}
    Log    "Verifying bandwidth rule is implentated on qos_policy"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${max_kbps_new}
    Log    "Verifying bandwidth deletion"
    ${resp}    Neutron Qos_policy Bandwidth Rule Deletion    ${bandwidth_id}    ${qos_name}
    Log    ${resp}
    Log    "Verifying bandwidth rule is implentated on qos_policy"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${bandwidth_id}

TC06 Verify DSCP Marking Rule Creation And Updation
    [Documentation]    Verify DSCP Marking Rule Creation And Updation
   
    Log    "Verify that DSCP marking rules should be created/updated/deleted by OPENSTACK"
    Log    "Creating qos_policy"
    ${output}    ${policy_id}    Neutron Qos_policy Creation    ${qos_name}
    Log    ${output}
    Log    ${policy_id}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${policy_id}
    Log    "Appying dscp marking rule in qos"
    ${output}    ${dscp_id}    Neutron Qos_dscp_marking Rule Creation    ${policy_id}    --dscp-mark ${dscp_mark_value}
    Log    ${output}
    Log    ${dscp_id}
    Log    "verifying dscp_rule applied in qos_policy"
    ${out}    Neutron Qos_policy Show    ${qos_name}
    Log    ${out}
    Should Contain    ${out}    ${dscp_id}
    Log    "Verifying dscp_mark creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${dscp_id}
    Log    "Removing dscp marking rule in qos"
    ${output}    Neutron Qos_dscp_marking Rule Deletion    ${dscp_id}    ${policy_id}
    Log    ${output}
    Log    "verifying dscp_rule removed from qos_policy"
    ${out}    Neutron Qos_policy Show    ${qos_name}
    Log    ${out}
    Should Not Contain    ${out}    ${dscp_id}
    [Teardown]    Neutron Qos_policy deletion    ${qos_name}

TC07 Verify that removing one rule won`t affect other rule
    [Documentation]    Verify that removing one rule won`t affect other rule
    
    Log    "Verify that removing one rule won`t affect other rule"
    Log    "Creation of qos_policy"
    ${output}    ${policy_id}    Neutron Qos_policy Creation    ${qos_name}
    Log    ${output}
    Log    ${policy_id}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${policy_id}
    Log    "Applying bandwidth in qos_policy"
    ${arg}    Catenate    --max-kbps ${max_kbps}    --max-burst-kbps ${max_burst}
    ${output}    ${bandwidth_id}    Neutron Qos_policy Bandwidth Rule Creation    ${policy_id}    ${arg}
    Log    ${output}
    Log    ${bandwidth_id}
    Log    "Applying dscp_marking rule in qos_policy"
    ${output}    ${dscp_id}    Neutron Qos_dscp_marking Rule Creation    ${policy_id}    --dscp-mark ${dscp_mark_value}
    Log    ${output}
    Log    ${dscp_id}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${dscp_id}
    Should Contain    ${resp.content}    ${bandwidth_id}
    Log    "Removing bandwidth-policy from qos-policy"
    ${resp}    Neutron Qos_policy Bandwidth Rule Deletion    ${bandwidth_id}    ${qos_name}
    Log    ${resp}
    Log    "Verifying bandwidth rule is implentated on qos_policy"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${bandwidth_id}
    Should Contain    ${resp.content}    ${dscp_id}
    Log    "Again creation bandwidth rule"
    ${arg}    Catenate    --max-kbps ${max_kbps_new}    --max-burst-kbps ${max_burst_new}
    ${output}    ${bandwidth_id1}    Neutron Qos_policy Bandwidth Rule Creation    ${policy_id}    ${arg}
    Log    ${output}
    Log    ${bandwidth_id1}
    Log    "now deletind dscp_rule from qos_policy
    ${output}    Neutron Qos_dscp_marking Rule Deletion    ${dscp_id}    ${policy_id}
    Log    ${output}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${dscp_id}
    Should Contain    ${resp.content}    ${bandwidth_id1}
    [Teardown]    Neutron Qos_policy deletion    ${qos_name}

TC08 Verifying association of qos_policy in port
    [Documentation]    Verifying association of qos_policy in port
    Log    "Creation of qos_policy"
    ${output}    ${policy_id}    Neutron Qos_policy Creation    ${qos_name}
    Log    ${output}
    Log    ${policy_id}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${policy_id}
    Log    "Applying bandwidth in qos_policy"
    ${arg}    Catenate    --max-kbps ${max_kbps}    --max-burst-kbps ${max_burst}
    ${output}    ${bandwidth_id}    Neutron Qos_policy Bandwidth Rule Creation    ${policy_id}    ${arg}
    Log    ${output}
    Log    ${bandwidth_id}
    Log    "Applying dscp_marking rule in qos_policy"
    ${output}    ${dscp_id}    Neutron Qos_dscp_marking Rule Creation    ${policy_id}    --dscp-mark ${dscp_mark_value}
    Log    ${output}
    Log    ${dscp_id}
    Log    "Verify bandwidth and dscp rule in policy"
    ${resp}    Neutron Qos_policy Show    ${policy_id}
    Should Contain    ${resp}    ${bandwidth_id}
    Should Contain    ${resp}    ${dscp_id}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${dscp_mark_value}
    Log    "Applying Qos_policy on port"
    Log    "Association of Qos_policy in port"
    ${resp}    Neutron Port Update    ${PORT[0]}    --qos-policy ${qos_name}
    Should Contain    ${resp}    Updated
    Log    ${resp}
    Log    "Fetching the flows from DPN1 and DPN2"
    ${flows}    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Log    ${flows}
    Log    "Verifying table90 in flows"
    ${table90_flows}    Get Flows With Table_id    ${OS_COMPUTE_1_IP}    ${Table_id}
    Log    ${table90_flows}
    Should Match Regexp    ${table90_flows}    ${dscp_mark_value}->ip_dscp
    Log    "verifying that qos policy is removed"
    ${resp}    Get Vhu Interface Info    ${PORT[0]}    ${OS_COMPUTE_1_IP}
    Should Match Regexp    ${resp}    ingress_policing_burst: ${max_burst}
    Should Match Regexp    ${resp}    ingress_policing_rate: ${max_kbps}    
#    [Teardown]    Run Keywords    Neutron Port Update
    ...    # ${PORT[0]}    --no-qos-policy    #    ...    # AND    Neutron Qos_policy deletion
    ...    # ${qos_name}

TC09 Verify dissociation of qos_policy from port
    [Documentation]    Verify Disassociation of QoS policy to ports
 
    Log    "Dissociation of qos_policy from port"
    ${resp}    Neutron Port Update    ${PORT[0]}    --no-qos-policy
    Should Contain    ${resp}    Updated
    Log    ${resp}
    SLEEP    30
    Log    "Verifying table90 in flows"
    ${table90_flows}    Get Flows With Table_id    ${OS_COMPUTE_1_IP}    ${Table_id}
    Log    ${table90_flows}
    Should Not Contain    ${table90_flows}    ${dscp_mark_value}->ip_dscp
    Log    "verifying that qos policy is removed"
    ${resp}    Get Vhu Interface Info    ${PORT[0]}    ${OS_COMPUTE_1_IP}
    Should Not Match Regexp    ${resp}    ingress_policing_burst: ${max_burst}
    Should Not Match Regexp    ${resp}    ingress_policing_rate: ${max_kbps}
    [Teardown]    Neutron Qos_policy deletion    ${qos_name}

TC10 Verify Association of Qos_policy to network
    [Documentation]    Verify Association of QoS policy to network
    
    Log    "creation of qos_policy"
    ${output}    ${policy_id}    Neutron Qos_policy Creation    ${qos_name}
    Log    ${output}
    Log    ${policy_id}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${policy_id}
    Log    "Applying bandwidth in qos_policy"
    ${args}    Catenate    --max-kbps ${max_kbps}    --max-burst-kbps ${max_burst}
    ${output}    ${bandwidth_id}    Neutron Qos_policy Bandwidth Rule Creation    ${policy_id}    ${args}
    Log    ${output}
    Log    ${bandwidth_id}
    Log    "Applying dscp_marking rule in qos_policy"
    ${output}    ${dscp_id}    Neutron Qos_dscp_marking Rule Creation    ${policy_id}    --dscp-mark ${dscp_mark_value}
    Log    ${output}
    Log    ${dscp_id}
    Log    "Applying Qos_policy on network"
    Log    "Association of Qos_policy in network"
    ${resp}    Neutron Network Update    ${NETWORKS[0]}    --qos-policy ${qos_name}
    Log    ${resp}
    Log    "Verifying qos creation in rest"
    ${resp}    RequestsLibrary.Get Request    session    ${Qos_CONF}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${dscp_id}
    Should Contain    ${resp.content}    ${bandwidth_id}
    Log    "verifying dscp rule in flows"
    ${table90_flows}    Get Flows With Table_id    ${OS_COMPUTE_1_IP}    ${Table_id}
    Log    ${table90_flows}
    Should Contain    ${table90_flows}    ${dscp_mark_value}->ip_dscp
    ${count}    Get Count    ${table90_flows}    ${dscp_mark_value}->ip_dscp
    Should Be True    0 < ${count} < 3


*** keyword ***
Basic Vpnservice Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    CREATE SETUP    

Basic Vpnservice Suite Teardown
    Delete SecurityGroup    ${SGP}
    Close All Connections

Neutron Qos_policy Creation
    [Arguments]    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Policy Creation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    #neutron qos-policy-create qos_policy --shared
    ${cmd}=    Set Variable    neutron qos-policy-create ${qos_policy_name} ${additional_args}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    Should Contain    ${OUTPUT}    Created a new policy
    ${policy_id}    Should Match Regexp    ${OUTPUT}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${policy_id}
    Close Connection
    [Return]    ${OUTPUT}    ${policy_id}

Neutron Qos_policy Show
    [Arguments]    ${qos_name/qos_id}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Policy show
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-policy-show ${qos_name} ${additional_args}=${EMPTY}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    5s
    Log    ${OUTPUT}
    Close Connection
    [Return]    ${OUTPUT}

Neutron Qos_policy List
    [Arguments]    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Policy list
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-policy-list
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    5s
    Log    ${OUTPUT}
    Close Connection
    [Return]    ${OUTPUT}

Neutron Qos_policy Updation
    [Arguments]    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Policy updation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-policy-update ${qos_policy_name} ${additional_args}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    5s
    Log    ${OUTPUT}
    Close Connection
    [Return]    ${OUTPUT}

Neutron Qos_policy deletion
    [Arguments]    ${qos_policy_name}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Policy Creation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    #neutron qos-policy-delete qos_policy
    ${cmd}=    Set Variable    neutron qos-policy-delete ${qos_policy_name}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    5s
    Log    ${OUTPUT}
    Should Match Regexp    ${output}    Deleted qos_policy: ${qos_policy_name}|Deleted qos_policy\\(s\\): ${qos_policy_name}
    Close Connection
    [Return]    ${OUTPUT}

Neutron Qos_policy Bandwidth Rule Creation
    [Arguments]    ${qos_id}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Bandwidth creation max-kbps and max-burst_rate should be given combinely
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-bandwidth-limit-rule-create ${qos_id} ${additional_args}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    5s
    Log    ${OUTPUT}
    Should Contain    ${OUTPUT}    Created a new bandwidth_limit_rule
    ${bandwidth_id}    Should Match Regexp    ${OUTPUT}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${bandwidth_id}
    Close Connection
    [Return]    ${OUTPUT}    ${bandwidth_id}

Neutron Qos_policy Bandwidth Rule Deletion
    [Arguments]    ${qos_name}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron bandwidth rule deletion
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-bandwidth-limit-rule-delete ${qos_name} ${additional_args}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    5s
    Log    ${OUTPUT}
    Close Connection
    [Return]    ${OUTPUT}

Neutron Qos_policy Bandwidth Rule Updation
    [Arguments]    ${bandwidth_id}    ${qos_name}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Policy Creation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-bandwidth-limit-rule-update ${bandwidth_id} ${qos_name} ${additional_args}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    5s
    ${resp}    Should Match Regexp    ${OUTPUT}    Updated bandwidth_limit_rule: ${bandwidth_id}
    Log    ${OUTPUT}
    Close Connection
    [Return]    ${OUTPUT}

Neutron Qos_dscp_marking Rule Creation
    [Arguments]    ${policy_id}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Policy Creation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-dscp-marking-rule-create ${policy_id} ${additional_args}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    ${dscp_id}    Should Match Regexp    ${OUTPUT}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${dscp_id}
    Close Connection
    [Return]    ${OUTPUT}    ${dscp_id}

Neutron Qos_dscp_marking Rule Update
    [Arguments]    ${dscp_id}    ${policy_id}    ${dcsp_value}
    [Documentation]    Neutron Qos Policy Creation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-dscp-marking-rule-update <dscp_id> <policy-id> - dscp_mark <dscp_value>
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    #    ${dscp_id}    Should Match Regexp    ${OUTPUT}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    #    Log    ${dcsp_id}
    Close Connection
    [Return]    ${OUTPUT}    ${dcsp_id}

Neutron Qos_dscp_marking Rule Deletion
    [Arguments]    ${dscp_id}    ${policy_id}    ${additional_args}=${EMPTY}
    [Documentation]    Neutron Qos Policy Creation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron qos-dscp-marking-rule-delete ${dscp_id} ${policy_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    Close Connection
    [Return]    ${OUTPUT}

Neutron Network Update
    [Arguments]    ${NetworkName}    ${additional_args}=${EMPTY}
    [Documentation]    Updating the network configuration that belong to a given tenant
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron net-update ${NetworkName} ${additional_args}
    Log    ${cmd}
    ${output}=    Write Commands Until Prompt    ${cmd}    8s
    Log    ${output}
    Close Connection
    [Return]    ${output}

Neutron Port Update
    [Arguments]    ${port_name}    ${additional_args}=${EMPTY}
    [Documentation]    Updating the port configuration that belong to a given tenant
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron port-update ${port_name} ${additional_args}
    Log    ${cmd}
    ${output}=    Write Commands Until Prompt    ${cmd}    8s
    Log    ${output}
    Close Connection
    [Return]    ${output}

Get Flows
    [Arguments]    ${{OS_COMPUTE_1_IP}    ${{OS_COMPUTE_2_IP}
    [Documentation]    Get the Flows from DPN1 and DPN2
    Log    "Fetching the flows from DPN1"
    ${resp}=    Run Command On Remote System    ${{OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    Log    ${resp}
    Log    "Fetching the Groups from DPN1"
    ${resp}=    Run Command On Remote System    ${{OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-groups br-int -OOpenflow13
    Log    ${resp}
    Log    "Fetching the flows from DPN2"
    ${resp}=    Run Command On Remote System    ${{OS_COMPUTE_2_IP}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    Log    ${resp}
    Log    "Fetching the Groups from DPN2"
    ${resp}=    Run Command On Remote System    ${{OS_COMPUTE_2_IP}    sudo ovs-ofctl dump-groups br-int -OOpenflow13
    Log    ${resp}

Get Flows With Table_id
    [Arguments]    ${MININET}    ${table_id}
    [Documentation]    Get the Flows from DPN1 and DPN2
    Log    "Fetching the flows from DPN1"
    ${resp}=    Run Command On Remote System    ${MININET}    sudo ovs-ofctl dump-flows br-int table=${table_id} -O OpenFlow13
    Log    ${resp}
    [Return]    ${resp}

Get Vhu Interface Info
    [Arguments]    ${port_name}    ${Server_IP}
    [Documentation]    Retrieve the port id for the given port name
    Log    "fetching port-id for vhu "
    ${devstack_conn_id}=    Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${resp}    Get Port Id    ${port_name}    ${devstack_conn_id}
    ${vhu-id}    Should Match Regexp    ${resp}    [0-9a-f]{8}-[0-9a-f]{2}
    ${vhu_name}    Catenate    vhu${vhu-id}
    Log    ${vhu_name}
    Log    ${vhu_name}
    Log    "Fetching the flows from DPN1"
    ${resp}=    Run Command On Remote System    ${Server_IP}    ovs-vsctl list interface ${vhu_name}
    Log    ${resp}
    SSHLibrary.Close Connection
    [Return]    ${resp}

Get Vm ID
    [Arguments]    ${vm_ name}
    [Documentation]    Neutron Qos Policy Creation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    nova list | grep ${vm_name} | awk '{print $2}'
    #    ${VM_ID}=    Write Commands Until Prompt    ${cmd}    30s
    ${resp}=    Write Commands Until Prompt    ${cmd}    30s
    ${splitted_output}=    Split String    ${resp}    ${EMPTY}
    ${VM_ID}=    Get from List    ${splitted_output}    0
    Log    ${VM_ID}
    Close Connection
    [Return]    ${VM_ID}

Get VM IP
    [Arguments]    ${VM_Name}    ${additional_args}=${EMPTY}
    [Documentation]    Extracting the VM IP
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    nova show ${VM_Name} ${additional_args}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    ${output}    ${VM_IP}    Should Match Regexp    ${OUTPUT}    \\snetwork\\s+\\|\\s+(\\d+\\.\\d+\\.\\d+\\.\\d+)
    Log    ${VM_IP}
    Close Connection
    [Return]    ${VM_IP}

CREATE SUBPORT
    [Arguments]    ${uri}    ${port_id}    ${subport_id}    ${port_name}    ${subport_name}    ${net_id}
    ...    ${subport_net_id}    ${subnet_id}    ${ip}    ${subport_subnet_id}    ${subport_ip}    ${vid}
    [Documentation]    creating subport via Rest
    Log    "Retreiving trunkport"
    ${res}    RequestsLibrary.Get Request    session    ${uri}${port_id}
    Log    ${res.content}
    ${data_to_put}=    Replace String    ${res.content}    "uuid":"${port_id}",    "uuid":"${subport_id}",
    Log    ${data_to_put}
    ${data_to_name}=    Replace String    ${data_to_put}    "name":"${port_name}",    "name":"${subport_name}",
    Log    ${data_to_name}
    ${data_to_net}=    Replace String    ${data_to_name}    "network-id":"${net_id}",    "network-id": "${subport_net_id}",
    Log    ${data_to_net}
    ${data_to_subnet}    Replace String    ${data_to_net}    "subnet-id":"${subnet_id}","ip-address":"${ip}"}    "subnet-id":"${subport_subnet_id}","ip-address":"${subport_ip}"}
    Log    ${data_to_subnet}
    Log    ${data_to_subnet}
    ${data_to_subport}    Replace String    ${data_to_subnet}    "neutron-port-ext:type":"neutron-port-ext:trunkport-type-trunkport",    "neutron-port-ext:parent-id":"${port_id}",\n"neutron-port-ext:vid":${vid},\n"neutron-port-ext:type":"neutron-port-ext:trunkport-type-subport",
    Log    ${data_to_subport}
    ${resp}    TemplatedRequests.Post_As_Json_To_Uri    ${uri_sub}    ${data_to_subport}    session
    Log    ${resp}
    [Return]    ${resp}

Update Port As Trunkport
    [Arguments]    ${uri}    ${port_id}
    [Documentation]    creating subport via Rest
    Log    "Retreiving trunkport"
    ${res}    RequestsLibrary.Get Request    session    ${uri}${port_id}
    #    Log    ${res.content}
    Log    ${res.content}
    ##    ${data_to_put}=    Replace String    ${res.content}    "uuid":"${port}",    "uuid":"${port}",\n${trunk},
    ${data_to_put}=    Replace String    ${res.content}    "uuid":"${port}",    "uuid":"${port}",\n"neutron:neutron-port-ext:type": "neutron-port-ext:trunkport-type-trunkport",
    Log    ${data_to_put}
    Log    ${data_to_put}
    ${resp}    TemplatedRequests.Put_As_Json_To_Uri    ${uri}${port}    ${data_to_put}    session
    Log    ${resp}
    [Return]    ${resp}

CREATE SETUP
    [Documentation]    initial setup
    Log    "bringing up common topology"
    Log    "Creating customised security Group"
    ${OUTPUT}    ${SGP_ID}    OpenStackOperations.Neutron Security Group Create    ${SGP}
    Set Global Variable    ${SGP_ID}
    Log    ${OUTPUT}
    Log    ${SGP_ID}
    Log    "Creating the rules for ingress direction"
    ${OUTPUT1}    ${RULE_ID1}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=icmp
    ${OUTPUT2}    ${RULE_ID2}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=tcp
    ${OUTPUT3}    ${RULE_ID3}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=udp
    Log    "Creating the rules for egress direction"
    ${OUTPUT4}    ${RULE_ID4}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=icmp
    ${OUTPUT5}    ${RULE_ID5}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=tcp
    ${OUTPUT6}    ${RULE_ID6}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=udp
    Log    "Forming Additional args command"
    ${ADD_ARGMS}    Catenate    ${SECURITY_GROUPS} ${SGP_ID}
    Log    ${ADD_ARGMS}
    Log    "Creating networks"
    ${net_id1}    Create Network    ${NETWORKS[0]}
    Log    ${net_id1}
    Set Global Variable    ${net_id1}
    SLEEP    5
    Log    "Creating 2nd networks"
    ${net_id2}    Create Network    ${NETWORKS[1]}
    Log    ${net_id2}
    Set Global Variable    ${net_id2}
    SLEEP    5
    ${net_id3}    Create Network    ${NETWORKS[2]}
    Log    ${net_id3}
    Set Global Variable    ${net_id3}
    SLEEP    5
    Log    "Creating 4th networks"
    ${net_id4}    Create Network    ${NETWORKS[3]}
    Log    ${net_id4}
    Set Global Variable    ${net_id4}
    SLEEP    5
    Log    "Creating subnets"
    ${subnet_id1}    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Log    ${subnet_id1}
    Set Global Variable    ${subnet_id1}
    SLEEP    5
    Log    "Creating 2nd subnets"
    Log    "Creating 2nd subnets"
    ${subnet_id2}    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Log    ${subnet_id2}
    Set Global Variable    ${subnet_id2}
    SLEEP    5
    Log    "Creating 3rd subnets"
    ${subnet_id3}    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    Log    ${subnet_id3}
    Set Global Variable    ${subnet_id3}
    SLEEP    5
    Log    "Creating 4th subnets"
    Log    "Creating 4th subnets"
    ${subnet_id4}    Create SubNet    ${NETWORKS[3]}    ${SUBNETS[3]}    ${SUBNET_CIDR[3]}
    Log    ${subnet_id4}
    Set Global Variable    ${subnet_id4}
    SLEEP    5
    Log    "Creating Port"
    Create Port    ${NETWORKS[0]}    ${PORT[0]}    sg=${SGP}
    Create Port    ${NETWORKS[0]}    ${PORT[1]}    sg=${SGP}
    Create Port    ${NETWORKS[1]}    ${PORT[2]}    sg=${SGP}
    Create Port    ${NETWORKS[1]}    ${PORT[3]}    sg=${SGP}
    Create Port    ${NETWORKS[3]}    ${PORT[4]}    sg=${SGP}
    Create Port    ${NETWORKS[4]}    ${PORT[5]}    sg=${SGP}
    Create Port    ${NETWORKS[0]}    ${PORT[6]}    sg=${SGP}
    Create Port    ${NETWORKS[4]}    ${PORT[7]}    sg=${SGP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT}
    
    Log    "Spawing VM_INSTNACES"
    Create Vm Instance With Port On Compute Node    ${PORT[0]}    ${VM_INSTANCES_NET1[0]}    ${OS_COMPUTE_1_IP}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.medium    sg=${SGP}
    Create Vm Instance With Port On Compute Node    ${PORT[1]}    ${VM_INSTANCES_NET1[1]}    ${OS_COMPUTE_1_IP}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.medium    sg=${SGP}
    Create Vm Instance With Port On Compute Node    ${PORT[2]}    ${VM_INSTANCES_NET2[0]}    ${OS_COMPUTE_1_IP}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.medium    sg=${SGP}
    Create Vm Instance With Port On Compute Node    ${PORT[3]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_1_IP}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.medium    sg=${SGP}
    Create Vm Instance With Port On Compute Node    ${PORT[4]}    ${VM_INSTANCES_NET3[0]}    ${OS_COMPUTE_1_IP}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.medium    sg=${SGP}
    Create Vm Instance With Port On Compute Node    ${PORT[5]}    ${VM_INSTANCES_NET4[0]}    ${OS_COMPUTE_2_IP}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.medium    sg=${SGP}
    Create Vm Instance With Port On Compute Node    ${PORT[6]}    ${VM_INSTANCES_NET1[2]}    ${OS_COMPUTE_2_IP}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.medium    sg=${SGP}
    Create Vm Instance With Port On Compute Node    ${PORT[7]}    ${VM_INSTANCES_NET4[1]}    ${OS_COMPUTE_1_IP}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.medium    sg=${SGP}

    Log    "Router Creation"
    Create Router    ${ROUTER}
    Log    "Associate Subnets to Routers"
    Add Router Interface    ${ROUTER}    @{SUBNETS}[0]
    Add Router Interface    ${ROUTER}    @{SUBNETS}[1]

