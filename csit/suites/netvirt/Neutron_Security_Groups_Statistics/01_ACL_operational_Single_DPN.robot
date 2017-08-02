*** Settings ***
Documentation     Test Suite for Operational Improvements of ACL
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Setup
Test Teardown     Suite teardown
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py
Library           Collections
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Library           String
Library           OperatingSystem
Library           SSHLibrary

*** Variable ***
@{prefix_list}    30.20.20.0/24
${sg_name}        Sg_rule1
${protocol}       tcp
${flavour}        m1.tiny
@{protocols}      icmp    tcp    udp
${itm}            TZA
@{Networks}       SG_Net_1    SG_Net_2
@{Subnet}         SG_Sub_1    SG_Sub_2
@{prefix_list}    30.20.20.0/24    30.20.20.100/24
@{stack_login}    stack    stack
${devstack_path}    /home/stack/devstack
${sg_name}        Sg_rule1
@{direction}      ingress    egress    both
${flavour}        m1.tiny
@{port_name}      sg_port1    sg_port2    sg_port3    sg_port4    sg_port5    port_test    sg_port6
...               sg_port7    sg_port8    sg_port9    sg_port10    sg_port11    sg_port12    sg_port13
...               sg_port14    sg_port15    sg_port16    sg_port17
@{VM_list}        Sg_test_VM1    Sg_test_VM2    Sg_test_VM3    Sg_test_VM4    Sg_test_VM5    Sg_test_VM6    Sg_test_VM7
...               Sg_test_VM8    Sg_test_VM9    Sg_test_VM10    Sg_test_VM11    Sg_test_VM12    Sg_test_VM13    Sg_test_VM14
...               Sg_test_VM15    Sg_test_VM16    Sg_test_VM17    Sg_test_VM18
@{tables}         table=0    table=244    table=214    table=17    table=55    # port entery check , ingress table , egress table
${br_name}        br-int
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
${port}           23
@{bridge_ip}      35.10.10.11    35.10.10.12
${itm}            TZA
@{protocols}      icmp    tcp    udp
${ping_packet_count}    4
${sg_name1}       Sg_rule2

*** Test Cases ***
Single DPN Egress No Sg:Verify Flow stats at egress for port with no security group attached single port
    [Documentation]    Verify Flow stats at egress for port with no security group attached single port
    [Setup]    PreConfig
    Create Port    ${Networks[0]}    ${port_name[0]}    ${sg_name}
    Create Neutron Port With Additional Params    ${Networks[0]}    ${port_name[1]}    --no-security-groups --port_security_enabled=false
    Create Port    ${Networks[0]}    ${port_name[2]}    ${sg_name}
    ${port_output}    List Ports
    Should Contain    ${port_output}    ${port_name[0]}
    should contain    ${port_output}    ${port_name[1]}
    should contain    ${port_output}    ${port_name[2]}
    ${h_name}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[0]}    ${VM_list[0]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[1]}    ${VM_list[1]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[2]}    ${VM_list[2]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${log}    Write Commands Until Prompt    neutron security-group-list
    ${port_1_id}    Get Port Id    ${port_name[0]}    ${devstack_conn_id}
    ${port_2_id}    Get Port Id    ${port_name[1]}    ${devstack_conn_id}
    ${port_3_id}    Get Port Id    ${port_name[2]}    ${devstack_conn_id}
    Set Global Variable    ${port_1_id}
    Set Global Variable    ${port_2_id}
    Set Global Variable    ${port_3_id}
    ${sub_port_id_1}    Get Sub Port Id    ${port_1_id}
    ${sub_port_id_2}    Get Sub Port Id    ${port_2_id}
    ${sub_port_id_3}    Get Sub Port Id    ${port_3_id}
    ${in_port_vm1}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_1}
    log    ${in_port_vm1}
    ${vm1_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm1}
    log    ${vm1_metadata}
    Set Global Variable    ${vm1_metadata}
    ${in_port_vm2}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_2}
    log    ${in_port_vm2}
    ${vm2_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm2}
    log    ${vm2_metadata}
    Set Global Variable    ${vm2_metadata}
    ${in_port_vm3}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_3}
    log    ${in_port_vm3}
    ${vm3_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm3}
    log    ${vm3_metadata}
    Set Global Variable    ${vm3_metadata}
    ${vm1_ip}    Get Vm Ip    ${VM_list[0]}    ${Networks[0]}
    ${vm2_ip}    Get Vm Ip    ${VM_list[1]}    ${Networks[0]}
    ${vm3_ip}    Get Vm Ip    ${VM_list[2]}    ${Networks[0]}
    log    ${vm1_ip}
    log    ${vm2_ip}
    log    ${vm3_ip}
    Set Global Variable    ${vm1_ip}
    Set Global Variable    ${vm2_ip}
    Set Global Variable    ${vm3_ip}
    Check In Port    ${in_port_vm1}
    Check In Port    ${in_port_vm2}
    Check In Port    ${in_port_vm3}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${Count_1}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    ${pcount_before_ssh}    get from list    ${Count_1}    0
    log    ${pcount_before_ssh}
    ${delete_icmp_egress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[1]}
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm2_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm1_ip}    ${command}
    should contain    ${ssh_output}    100%
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    log    ${drops}
    ${eg_packet_drop}    get from list    ${drops}    0
    Set Global Variable    ${eg_packet_drop}
    ${eg_bytes}    get from list    ${drops}    1
    ${check_status}    Check packet count    ${eg_packet_drop}    ${pcount_before_ssh}
    evaluate    "${check_status}"=="True"
    ${rpc_output}    Get Acl Port Statistics    ${direction[1]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${egress_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${egress_drop}    "drop-count":${eg_packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${eg_bytes}
    Set Global Variable    ${eg_packet_drop}
    Set Global Variable    ${eg_bytes}
    Log    <<< Testcase - 7.1.35 >>>
    ${inpid}    Set Variable    oght3456-w3e4-t4y6-abc123fgh456
    ${rpc_out}    Get Acl Port Statistics    ${direction[1]}    ${inpid}
    Log    ${rpc_out}

Single DPN Ingress No Sg:Verify Flow stats at Ingress for port with no security group attached single port
    [Documentation]    Verify Flow stats at ingress for port with no security group attached single port and list of ports
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${Count_2}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    ${pcount_before_ssh}    get from list    ${Count_2}    0
    log    ${pcount_before_ssh}
    ${delete_icmp_ingress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[0]}
    Neutron Security Group Rule Create    ${sg_name}    direction=${direction[1]}    protocol=${protocols[0]}    remote_ip_prefix=0.0.0.0/0
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm1_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    log    ${drops}
    ${ing_packet_drop}    get from list    ${drops}    0
    Set Global Variable    ${ing_packet_drop}
    ${ing_bytes}    get from list    ${drops}    1
    Set Global Variable    ${ing_bytes}
    ${check_status}    Check packet count    ${ing_packet_drop}    ${pcount_before_ssh}
    evaluate    "${check_status}"=="True"
    ${rpc_output}    Get Acl Port Statistics    ${direction[0]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${ing_packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${ing_bytes}

Single DPN Both No Sg :Verify Flow stats for both ingress and egress for no security group single port
    [Documentation]    Verify Flow stats for both ingress and egress for no security group single port and list of ports
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${Count_3}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    ${pcount_before_ssh_eg}    get from list    ${Count_3}    0
    log    ${pcount_before_ssh_eg}
    ${Count_4}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    ${pcount_before_ssh_ing}    get from list    ${Count_4}    0
    log    ${pcount_before_ssh_ing}
    ${delete_icmp_egress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[1]}
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm2_ip}
    ${ssh_output_egress}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm1_ip}    ${command}
    should contain    ${ssh_output_egress}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    log    ${drops}
    ${eg_packet}    get from list    ${drops}    0
    ${eg_byte}    get from list    ${drops}    1
    ${check_status}    Check packet count    ${eg_packet}    ${pcount_before_ssh_eg}
    evaluate    "${check_status}"=="True"
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm1_ip}
    ${ssh_output_ingress}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output_ingress}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    log    ${drops}
    ${ing_packet}    get from list    ${drops}    0
    ${ing_byte}    get from list    ${drops}    1
    log    ${ing_byte}
    ${check_status}    Check packet count    ${ing_packet}    ${pcount_before_ssh_ing}
    evaluate    "${check_status}"=="True"
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    ${rpc_output}    Get Acl Port Statistics    ${direction[2]}    ${port_1_id}
    log    ${rpc_output}
    ${egress_regex}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+},"bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}
    ${eg_drop}    Should Match Regexp    ${rpc_output}    ${egress_regex}
    log    ${eg_drop}
    Should Contain    ${eg_drop}    "drop-count":${eg_packet}
    Should Contain    ${eg_drop}    "drop-count":${eg_byte}
    ${ingress_regex}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+},"bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}
    ${ing_drop}    Should Match Regexp    ${rpc_output}    ${ingress_regex}
    log    ${ing_drop}
    Should Contain    ${ing_drop}    "drop-count":${ing_packet}
    Should Contain    ${ing_drop}    "drop-count":${ing_byte}
    ${rpc_output}    Get Acl Port Statistics    ${direction[2]}    ${port_2_id}
    log    ${rpc_output}
    ${no_port_statistics}    Should Match Regexp    ${rpc_output}    "error-message":"Unable to retrieve drop counts as interface is not configured for statistics collection."
    log    ${no_port_statistics}

Single DPN Ingress between SG and No Sg :Verify flow stats request and response and drop packets count and bytes for direction ingress for no rule match data packet for list of ports
    [Documentation]    Verify flow stats request and response and drop packets count and bytes for direction ingress for no rule match data packet for list of ports
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${Count_5}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    ${pcount_bfr_ping_vm1}    get from list    ${Count_5}    0
    log    ${pcount_bfr_ping_vm1}
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm2_metadata}
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm1_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    log    ${drops}
    ${ing_packet_drop_1}    get from list    ${drops}    0
    Set Global Variable    ${ing_packet_drop_1}
    ${ing_bytes_1}    get from list    ${drops}    1
    Set Global Variable    ${ing_bytes_1}
    ${check_status}    Check packet count    ${ing_packet_drop_1}    ${pcount_bfr_ping_vm1}
    evaluate    "${check_status}"=="True"
    ${rpc_output}    Get Acl Port Statistics    ${direction[0]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${ing_packet_drop_1}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${ing_bytes_1}
    ${Count_6}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm3_metadata}
    ${pcount_bfr_ping_vm3}    get from list    ${Count_6}    0
    log    ${pcount_bfr_ping_vm3}
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm3_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm3_metadata}
    log    ${drops}
    ${ing_packet_drop_3}    get from list    ${drops}    0
    Set Global Variable    ${ing_packet_drop_3}
    ${ing_bytes_2}    get from list    ${drops}    1
    Set Global Variable    ${ing_bytes_2}
    ${check_status}    Check packet count    ${ing_packet_drop_3}    ${pcount_bfr_ping_vm3}
    evaluate    "${check_status}"=="True"
    ${rpc_output}    Get Acl Port Statistics    ${direction[0]}    ${port_3_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_3}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_3}    "drop-count":${ing_packet_drop_3}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${ing_bytes_2}

Single DPN : Create port with No Security Group, Launch VM and verify the traffic
    [Documentation]    Create port with No Security Group, Launch VM and verify the traffic
    ${port_created}    Create Neutron Port With Additional Params    ${Networks[0]}    ${port_name[3]}    --no-security-groups
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_4_id}    Get Port Id    ${port_name[3]}    ${devstack_conn_id}
    Set Global Variable    ${port_4_id}
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[3]}
    ${port_odl_status}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/ports/port/${port_4_id}/
    log    ${port_odl_status}
    ${status}    Should Match Regexp    ${port_odl_status}    neutron-portsecurity:port-security-enabled":[a-zA-Z]+
    log    ${status}
    should contain    ${status}    true
    ${h_name}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[3]}    ${VM_list[3]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    ${sub_port_id_4}    Get Sub Port Id    ${port_4_id}
    ${in_port_vm4}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_4}
    log    ${in_port_vm4}
    ${vm4_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm4}
    log    ${vm4_metadata}
    Set Global Variable    ${vm4_metadata}
    ${vm4_ip}    Get Vm Ip    ${VM_list[3]}    ${Networks[0]}
    log    ${vm4_ip}
    Set Global Variable    ${vm4_ip}
    Port update    ${TOOLS_SYSTEM_1_IP}    ${port_name[3]}    port_security_enabled=false
    ${port_odl_status}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/ports/port/${port_4_id}/
    log    ${port_odl_status}
    ${status}    Should Match Regexp    ${port_odl_status}    neutron-portsecurity:port-security-enabled":[a-zA-Z]+
    log    ${status}
    should contain    ${status}    false
    ${ping to vm}    Wait Until Keyword Succeeds    30s    10s    Check Ping To Vm After Spawnning    ${TOOLS_SYSTEM_1_IP}    ${Networks[0]}
    ...    ${vm4_ip}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm2_ip}
    ${ssh_output}    Ssh To Vm    ${dev_stack_conn_id}    ${Networks[0]}    ${vm4_ip}    ${command}
    should contain    ${ssh_output}    0%
    ${output}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${tables[2]} | grep ${vm4_metadata}    30s
    log    ${output}
    should not contain    ${output}    ${vm4_metadata}
    ${rpc_output}    Get Acl Port Statistics    ${direction[2]}    ${port_4_id}
    log    ${rpc_output}
    ${no_port_statistics}    Should Match Regexp    ${rpc_output}    "error-message":"Unable to retrieve drop counts as interface is not configured for statistics collection."
    log    ${no_port_statistics}
    ${rpc_output}    Get Acl Port Statistics    ${direction[2]}    ${port_4_id}
    log    ${rpc_output}
    ${no_port_statistics}    Should Match Regexp    ${rpc_output}    "error-message":"Unable to retrieve drop counts as interface is not configured for statistics collection."
    log    ${no_port_statistics}

Verify packet drop when one VM with NO SG (port_security_enable=False) and another VM with Default SG and ping between
    [Setup]
    Create Neutron Port With Additional Params    ${Networks[0]}    ${port_name[4]}    --no-security-groups --port_security_enabled=false
    Create Neutron Port With Default Securitygrp    ${Networks[0]}    ${port_name[5]}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_5_id}    Get Port Id    ${port_name[4]}    ${devstack_conn_id}
    Set Global Variable    ${port_name[4]}
    ${port_6_id}    Get Port Id    ${port_name[5]}    ${devstack_conn_id}
    Set Global Variable    ${port_6_id}
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[4]}
    should contain    ${port_output}    ${port_name[5]}
    ${port_odl_status1}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/ports/port/${port_5_id}/
    log    ${port_odl_status1}
    ${status}    Should Match Regexp    ${port_odl_status1}    neutron-portsecurity:port-security-enabled":[a-zA-Z]+
    log    ${status}
    should contain    ${status}    false
    ${port_odl_status1}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/ports/port/${port_6_id}/
    log    ${port_odl_status1}
    ${status}    Should Match Regexp    ${port_odl_status1}    neutron-portsecurity:port-security-enabled":[a-zA-Z]+
    log    ${status}
    should contain    ${status}    true
    ${h_name}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[4]}    ${VM_list[4]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    ${sub_port_id_5}    Get Sub Port Id    ${port_5_id}
    ${in_port_vm5}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_5}
    log    ${in_port_vm5}
    ${vm5_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm5}
    log    ${vm5_metadata}
    Set Global Variable    ${vm5_metadata}
    ${vm5_ip}    Get Vm Ip    ${VM_list[4]}    ${Networks[0]}
    log    ${vm5_ip}
    Set Global Variable    ${vm5_ip}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[5]}    ${VM_list[5]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    ${sub_port_id_6}    Get Sub Port Id    ${port_6_id}
    ${in_port_vm6}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_6}
    log    ${in_port_vm6}
    ${vm6_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm6}
    log    ${vm6_metadata}
    Set Global Variable    ${vm6_metadata}
    ${vm6_ip}    Get Vm Ip    ${VM_list[5]}    ${Networks[0]}
    log    ${vm6_ip}
    Set Global Variable    ${vm6_ip}
    Wait Until Keyword Succeeds    50s    10s    Check Ping To Vm After Spawnning    ${TOOLS_SYSTEM_1_IP}    ${Networks[0]}    ${vm5_ip}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm6_ip}
    ${ssh_output}    Ssh To Vm    ${dev_stack_conn_id}    ${Networks[0]}    ${vm5_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm6_metadata}
    log    ${drops}
    ${ing_packet_drop}    get from list    ${drops}    0
    Set Global Variable    ${ing_packet_drop}
    ${ing_bytes}    get from list    ${drops}    1
    Set Global Variable    ${ing_bytes}
    ${rpc_output}    Get Acl Port Statistics    ${direction[0]}    ${port_6_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${ing_packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${ing_bytes}

Launch VM with Multiple Security group and verify the dropped traffic.
    [Documentation]    This testcase validates the RPC call by sending invalid port id .
    [Setup]
    Create Neutron Port With Additional Params    ${Networks[0]}    ${port_name[9]}    --security-group ${sg_name}
    Create Neutron Port With Additional Params    ${Networks[0]}    ${port_name[10]}    --security-group ${sg_name}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_9_id}    Get Port Id    ${port_name[9]}    ${devstack_conn_id}
    Set Global Variable    ${port_name[9]}
    ${port_10_id}    Get Port Id    ${port_name[10]}    ${devstack_conn_id}
    Set Global Variable    ${port_10_id}
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[9]}
    should contain    ${port_output}    ${port_name[10]}
    ${port_odl_status1}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/ports/port/${port_9_id}/
    log    ${port_odl_status1}
    ${status}    Should Match Regexp    ${port_odl_status1}    neutron-portsecurity:port-security-enabled":[a-zA-Z]+
    log    ${status}
    should contain    ${status}    true
    ${port_odl_status2}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/ports/port/${port_10_id}/
    log    ${port_odl_status2}
    ${status}    Should Match Regexp    ${port_odl_status2}    neutron-portsecurity:port-security-enabled":[a-zA-Z]+
    log    ${status}
    should contain    ${status}    true
    ${h_name}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[9]}    ${VM_list[8]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    Wait Until Keyword Succeeds    10s    5s    OpenStackOperations.Verify VM Is ACTIVE    ${VM_list[8]}
    ${sub_port_id_9}    Get Sub Port Id    ${port_9_id}
    ${in_port_vm9}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_9}
    log    ${in_port_vm9}
    ${vm9_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm9}
    log    ${vm9_metadata}
    Set Global Variable    ${vm9_metadata}
    ${vm9_ip}    Get Vm Ip    ${VM_list[8]}    ${Networks[0]}
    log    ${vm9_ip}
    Set Global Variable    ${vm9_ip}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[10]}    ${VM_list[9]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    Wait Until Keyword Succeeds    10s    5s    OpenStackOperations.Verify VM Is ACTIVE    ${VM_list[9]}
    ${sub_port_id_10}    Get Sub Port Id    ${port_10_id}
    ${in_port_vm10}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_10}
    log    ${in_port_vm10}
    ${vm10_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm10}
    log    ${vm10_metadata}
    Set Global Variable    ${vm10_metadata}
    ${vm10_ip}    Get Vm Ip    ${VM_list[9]}    ${Networks[0]}
    log    ${vm10_ip}
    Set Global Variable    ${vm10_ip}
    Check In Port    ${in_port_vm9}
    Check In Port    ${in_port_vm10}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${Count_1}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm9_metadata}
    ${pcount_before_ssh}    get from list    ${Count_1}    0
    log    ${pcount_before_ssh}
    ${delete_icmp_egress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[1]}
    ${command}    Set Variable    ping -c ${ping_packet_count} ${vm10_ip}
    ${ssh_output}    Ssh To Vm    ${dev_stack_conn_id}    ${Networks[0]}    ${vm9_ip}    ${command}
    should contain    ${ssh_output}    100%
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm9_metadata}
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm9_metadata}
    log    ${drops}
    ${eg_packet_drop}    get from list    ${drops}    0
    Set Global Variable    ${eg_packet_drop}
    ${eg_bytes}    get from list    ${drops}    1
    ${check_status}    Check packet count    ${eg_packet_drop}    ${pcount_before_ssh}
    evaluate    "${check_status}"=="True"
    ${rpc_output}    Get Acl Port Statistics    ${direction[1]}    ${port_9_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${egress_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${egress_drop}    "drop-count":${eg_packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${eg_bytes}
    Set Global Variable    ${eg_packet_drop}
    Set Global Variable    ${eg_bytes}

Verify the ACL flows are getting deleted after deleting the VM
    [Documentation]    This testcase validates the RPC call by sending invalid port id .
    [Setup]    PreConfig
    Create Neutron Port With Additional Params    ${Networks[0]}    ${port_name[11]}    --security-group ${sg_name}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_11_id}    Get Port Id    ${port_name[11]}    ${devstack_conn_id}
    Set Global Variable    ${port_name[10]}
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[11]}
    ${port_odl_status1}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/ports/port/${port_11_id}/
    log    ${port_odl_status1}
    ${status}    Should Match Regexp    ${port_odl_status1}    neutron-portsecurity:port-security-enabled":[a-zA-Z]+
    log    ${status}
    should contain    ${status}    true
    ${h_name}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[11]}    ${VM_list[10]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    Wait Until Keyword Succeeds    10s    5s    OpenStackOperations.Verify VM Is ACTIVE    ${VM_list[10]}
    ${sub_port_id_11}    Get Sub Port Id    ${port_11_id}
    ${in_port_vm11}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_11}
    log    ${in_port_vm11}
    ${vm11_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm11}
    log    ${vm11_metadata}
    Set Global Variable    ${vm11_metadata}
    ${vm11_ip}    Get Vm Ip    ${VM_list[10]}    ${Networks[0]}
    log    ${vm11_ip}
    Set Global Variable    ${vm11_ip}
    Wait Until Keyword Succeeds    30s    10s    Check Ping To Vm After Spawnning    ${TOOLS_SYSTEM_1_IP}    ${Networks[0]}    ${vm11_ip}
    ${Connection_1}    Establish SSH    ${Networks[0]}    ${vm11_ip}    ifconfig
    ${port_odl_status}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/ports/port/${port_11_id}/
    log    ${port_odl_status}
    ${status}    Should Match Regexp    ${port_odl_status}    neutron-portsecurity:port-security-enabled":[a-zA-Z]+
    log    ${status}
    should contain    ${status}    true
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${devstack_conn_id}    Devstack Login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${vm11_metadata}
    log    ${output}
    ${loutput}    Split To Lines    ${output}
    ${lcount}    Get Length    ${loutput}
    Log    ${lcount}
    Delete Vm Instance    ${VM_list[10]}
    Delete Port    ${port_name[11]}
    ${devstack_conn_id}    Devstack Login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${output1}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${vm11_metadata}
    Log    ${output1}
    ${outputlog}    Should Not Be Equal    ${output}    ${output1}
    log    ${outputlog}
    [Teardown]    Clean

Verify flow stats request and response and drop packets count and bytes for direction ingress for invalid data packet for single port.
    [Documentation]    Verify Flow stats at egress for port with no security group attached single port
    [Setup]    PreConfig
    Create Port    ${Networks[0]}    ${port_name[0]}    ${sg_name}
    Create Neutron Port With Additional Params    ${Networks[0]}    ${port_name[1]}    --no-security-groups --port_security_enabled=false
    Create Port    ${Networks[0]}    ${port_name[2]}    ${sg_name}
    ${port_output}    List Ports
    Should Contain    ${port_output}    ${port_name[0]}
    should contain    ${port_output}    ${port_name[1]}
    should contain    ${port_output}    ${port_name[2]}
    ${h_name}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[0]}    ${VM_list[0]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[1]}    ${VM_list[1]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[2]}    ${VM_list[2]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${log}    Write Commands Until Prompt    neutron security-group-list
    ${port_1_id}    Get Port Id    ${port_name[0]}    ${devstack_conn_id}
    ${port_2_id}    Get Port Id    ${port_name[1]}    ${devstack_conn_id}
    ${port_3_id}    Get Port Id    ${port_name[2]}    ${devstack_conn_id}
    Set Global Variable    ${port_1_id}
    Set Global Variable    ${port_2_id}
    Set Global Variable    ${port_3_id}
    ${sub_port_id_1}    Get Sub Port Id    ${port_1_id}
    ${sub_port_id_2}    Get Sub Port Id    ${port_2_id}
    ${sub_port_id_3}    Get Sub Port Id    ${port_3_id}
    ${in_port_vm1}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_1}
    log    ${in_port_vm1}
    ${vm1_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm1}
    log    ${vm1_metadata}
    Set Global Variable    ${vm1_metadata}
    ${in_port_vm2}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_2}
    log    ${in_port_vm2}
    ${vm2_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm2}
    log    ${vm2_metadata}
    Set Global Variable    ${vm2_metadata}
    ${in_port_vm3}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_3}
    log    ${in_port_vm3}
    ${vm3_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm3}
    log    ${vm3_metadata}
    Set Global Variable    ${vm3_metadata}
    ${vm1_ip}    Get Vm Ip    ${VM_list[0]}    ${Networks[0]}
    ${vm2_ip}    Get Vm Ip    ${VM_list[1]}    ${Networks[0]}
    ${vm3_ip}    Get Vm Ip    ${VM_list[2]}    ${Networks[0]}
    log    ${vm1_ip}
    log    ${vm2_ip}
    log    ${vm3_ip}
    Set Global Variable    ${vm1_ip}
    Set Global Variable    ${vm2_ip}
    Set Global Variable    ${vm3_ip}
    Check In Port    ${in_port_vm1}
    Check In Port    ${in_port_vm2}
    Check In Port    ${in_port_vm3}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${Count_1}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    ${pcount_before_ssh}    get from list    ${Count_1}    0
    log    ${pcount_before_ssh}
    ${delete_icmp_egress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[1]}
    ${command}    Set Variable    ping -c ${ping_packet_count} -s 9000 ${vm2_ip}
    ${ssh_output}    Ssh To Vm    ${dev_stack_conn_id}    ${Networks[0]}    ${vm1_ip}    ${command}
    should contain    ${ssh_output}    100%
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    log    ${drops}
    ${eg_packet_drop}    get from list    ${drops}    0
    Set Global Variable    ${eg_packet_drop}
    ${eg_bytes}    get from list    ${drops}    1
    ${check_status}    Check packet count    ${eg_packet_drop}    ${pcount_before_ssh}
    evaluate    "${check_status}"=="True"
    ${rpc_output}    Get Acl Port Statistics    ${direction[1]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${egress_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${egress_drop}    "drop-count":${eg_packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${eg_bytes}
    Set Global Variable    ${eg_packet_drop}
    Set Global Variable    ${eg_bytes}

Verify flow stats request and response and drop packets count and bytes for direction egress for invalid data packet for single port.
    [Documentation]    Verify Flow stats at ingress for port with no security group attached single port and list of ports
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${Count_2}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    ${pcount_before_ssh}    get from list    ${Count_2}    0
    log    ${pcount_before_ssh}
    ${delete_icmp_ingress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[0]}
    Neutron Security Group Rule Create    ${sg_name}    direction=${direction[1]}    protocol=${protocols[0]}    remote_ip_prefix=0.0.0.0/0
    ${command}    Set Variable    ping -c ${ping_packet_count} -s 9000 ${vm1_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    log    ${drops}
    ${ing_packet_drop}    get from list    ${drops}    0
    Set Global Variable    ${ing_packet_drop}
    ${ing_bytes}    get from list    ${drops}    1
    Set Global Variable    ${ing_bytes}
    ${check_status}    Check packet count    ${ing_packet_drop}    ${pcount_before_ssh}
    evaluate    "${check_status}"=="True"
    ${rpc_output}    Get Acl Port Statistics    ${direction[0]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${ing_packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${ing_bytes}

Verify flow stats request and response and drop packets count and bytes for direction both for invalid data packet for single port.
    [Documentation]    Verify Flow stats for both ingress and egress for no security group single port and list of ports
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${Count_3}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    ${pcount_before_ssh_eg}    get from list    ${Count_3}    0
    log    ${pcount_before_ssh_eg}
    ${Count_4}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    ${pcount_before_ssh_ing}    get from list    ${Count_4}    0
    log    ${pcount_before_ssh_ing}
    ${delete_icmp_egress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[1]}
    ${command}    Set Variable    ping -c ${ping_packet_count} -s 9000 ${vm2_ip}
    ${ssh_output_egress}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm1_ip}    ${command}
    should contain    ${ssh_output_egress}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    log    ${drops}
    ${eg_packet}    get from list    ${drops}    0
    ${eg_byte}    get from list    ${drops}    1
    ${check_status}    Check packet count    ${eg_packet}    ${pcount_before_ssh_eg}
    evaluate    "${check_status}"=="True"
    ${command}    Set Variable    ping -c ${ping_packet_count} -s 9000 ${vm1_ip}
    ${ssh_output_ingress}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output_ingress}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    log    ${drops}
    ${ing_packet}    get from list    ${drops}    0
    ${ing_byte}    get from list    ${drops}    1
    log    ${ing_byte}
    ${check_status}    Check packet count    ${ing_packet}    ${pcount_before_ssh_ing}
    evaluate    "${check_status}"=="True"
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    ${rpc_output}    Get Acl Port Statistics    ${direction[2]}    ${port_1_id}
    log    ${rpc_output}
    ${egress_regex}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+},"bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}
    ${eg_drop}    Should Match Regexp    ${rpc_output}    ${egress_regex}
    log    ${eg_drop}
    Should Contain    ${eg_drop}    "drop-count":${eg_packet}
    Should Contain    ${eg_drop}    "drop-count":${eg_byte}
    ${ingress_regex}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+},"bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}
    ${ing_drop}    Should Match Regexp    ${rpc_output}    ${ingress_regex}
    log    ${ing_drop}
    Should Contain    ${ing_drop}    "drop-count":${ing_packet}
    Should Contain    ${ing_drop}    "drop-count":${ing_byte}
    ${rpc_output}    Get Acl Port Statistics    ${direction[2]}    ${port_2_id}
    log    ${rpc_output}
    ${no_port_statistics}    Should Match Regexp    ${rpc_output}    "error-message":"Unable to retrieve drop counts as interface is not configured for statistics collection."
    log    ${no_port_statistics}
    [Teardown]    Clean

Verify packet drop when user pings for non-existing IP in Different Subnet ( port_security_enable=True)
    [Documentation]    Verify Flow stats at ingress for port with no security group attached single port and list of ports
    [Setup]    PreConfig
    Create Port    ${Networks[0]}    ${port_name[0]}    ${sg_name}
    ${port_output}    List Ports
    Should Contain    ${port_output}    ${port_name[0]}
    ${h_name}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[0]}    ${VM_list[0]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_1_id}    Get Port Id    ${port_name[0]}    ${devstack_conn_id}
    Set Global Variable    ${port_1_id}
    ${sub_port_id_1}    Get Sub Port Id    ${port_1_id}
    ${in_port_vm1}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_1}
    ${vm1_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm1}
    log    ${vm1_metadata}
    Set Global Variable    ${vm1_metadata}
    ${vm1_ip}    Get Vm Ip    ${VM_list[0]}    ${Networks[0]}
    log    ${vm1_ip}
    Set Global Variable    ${vm1_ip}
    Check In Port    ${in_port_vm1}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${Count_1}    check flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    ${pcount_before_ssh}    get from list    ${Count_1}    0
    ${snetip}    Set Variable    70.70.70.70
    ${command}    Set Variable    ping -c ${ping_packet_count} ${snetip}
    Neutron Security Group Rule Create    ${sg_name}    direction=${direction[1]}    protocol=${protocols[1]}    remote_ip_prefix=0.0.0.0/0
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id}    ${Networks[0]}    ${vm1_ip}    ${command}
    should contain    ${ssh_output}    100%
    Dump Flows For Tables    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    log    ${drops}
    ${eg_packet_drop}    get from list    ${drops}    0
    Set Global Variable    ${eg_packet_drop}
    ${eg_bytes}    get from list    ${drops}    1
    ${check_status}    Check packet count    ${eg_packet_drop}    ${pcount_before_ssh}
    evaluate    "${check_status}"=="True"
    ${rpc_output}    Get Acl Port Statistics    ${direction[1]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${egress_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${egress_drop}    "drop-count":${eg_packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${eg_bytes}
    Set Global Variable    ${eg_packet_drop}
    Set Global Variable    ${eg_bytes}
    [Teardown]    Clean

*** Keywords ***
Devstack Login
    [Arguments]    ${ip}    ${username}    ${password}    ${devstack_path}    ${prompt}
    ${dev_stack_conn_id}=    SSHLibrary.Open Connection    ${ip}    prompt=${prompt}
    Set Suite Variable    ${dev_stack_conn_id}
    log    ${username},${password}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${devstack_path}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

Get Sub Port Id
    [Arguments]    ${port_id}
    @{port_array}    String.Split String    ${port_id}    -
    log    ${port_array}
    ${first_set}    get from list    ${port_array}    0
    ${second_set}    get from list    ${port_array}    1
    ${sub_str}    Get Substring    ${second_set}    \    2
    log    ${sub_str}
    ${ret_id}    catenate    ${first_set}-${sub_str}
    log    ${ret_id}
    [Return]    ${ret_id}

Get Port Number
    [Arguments]    ${ip}    ${br_name}    ${pnum}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Set Global Variable    ${devstack_conn_id}
    ${command_1}    Set Variable    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pnum} | awk '{print$1}'
    log    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pnum} | awk '{print$1}'
    ${num}    Write Commands Until Prompt    ${command_1}    30
    log    ${num}
    should contain    ${num}    tap
    ${port_number}    Should Match Regexp    ${num}    [0-9]+
    log    ${port_number}
    [Return]    ${port_number}

Get Metadata
    [Arguments]    ${conn_id}    ${port}
    Switch Connection    ${conn_id}
    ${grep_metadata}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name}| grep table=0 | grep in_port=${port} | awk '{print$7}'    30
    @{metadata}    Split string    ${grep_metadata}    ,
    ${index1}    get from list    ${metadata}    0
    @{complete_meta}    Split string    ${index1}    :
    ${m_data}    get from list    ${complete_meta}    1
    log    ${m_data}
    @{split_meta}    Split string    ${m_data}    /
    ${only_meta}    get from list    ${split_meta}    0
    log    ${only_meta}
    [Return]    ${only_meta}

Create Vm
    [Arguments]    ${ip}    ${flavour}    ${port_name}    ${vm_name}    ${username}    ${password}
    ...    ${host_name}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${vm_spawn}    Write Commands Until Prompt    nova boot --flavor ${flavour} --image cirros-0.3.4-x86_64-uec --nic port-id=$(neutron port-list | grep '${port_name}' | awk '{print $2}') ${vm_name} --availability-zone nova:${host_name}    60
    log    ${vm_spawn}
    should contain    ${vm_spawn}    ${vm_name}
    sleep    10
    Close Connection

Get Acl Port Statistics
    [Arguments]    ${directn}    ${port_id}
    log    ${directn} | ${port_id}
    ${body}    OperatingSystem.Get File    ${netvirt_config_dir}/acl_rpc.json
    ${body}    Replace String    ${body}    1    ${directn}
    ${body}    replace string    ${body}    2    ${port_id}
    log    ${body}
    ${resp}    RequestsLibrary.Post Request    session    /restconf/operations/acl-live-statistics:get-acl-port-statistics    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Get Vm Ip
    [Arguments]    ${vm}    ${Net}
    ${ip}    Write Commands Until Prompt    nova show ${vm} | grep ${Net} | awk '{print$5}'    30
    ${vms_ip}    Should Match Regexp    ${ip}    [0-9]\.+
    log    ${vms_ip}
    [Return]    ${vms_ip}

Check In Port
    [Arguments]    ${port}
    ${output}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0    $    30
    log    ${output}
    should contain    ${output}    in_port=${port}

Ssh To Vm
    [Arguments]    ${conn_id}    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    ${net_name}    ${devstack_conn_id}
    Log    ${vm_ip}
    ${ssh}    SSHLibrary.Write    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip}
    ${output}    SSHLibrary.Read    delay=30s
    log    ${output}
    ${check_prompt}    Check Output    ${output}    yes/no
    log    ${check_prompt}
    Run Keyword If    '${check_prompt}'=='True'    Login To Vm    {cmd}
    ${check_prompt_2}    Check Output    ${output}    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED
    Run Keyword If    '${check_prompt_2}'=='True'    Ssh Fail    ${vm_ip}    ${net_id}
    ${output} =    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}    timeout=60s
    Log    ${output}
    ${rcode} =    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output} =    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}    90
    Write Commands Until Expected Prompt    exit    $    30
    [Return]    ${output}

Check Flows
    [Arguments]    ${ip}    ${table}    ${vm_metadata}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Log    >>>> Check ${table} flows <<<<<<
    ${output}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table} | grep ${vm_metadata}|grep actions=drop|grep ct_state=+new+trk    30
    log    ${output}
    should contain    ${output}    ${vm_metadata}
    ${n_packets}    Should Match Regexp    ${output}    n_packets=[0-9]+
    log    ${n_packets}
    ${packet_drop_count}    Should Match Regexp    ${n_packets}    [0-9]+
    log    ${packet_drop_count}
    Should Contain    ${output}    metadata=${vm_metadata}
    should contain    ${output}    ct_state=+new+trk
    should contain    ${output}    actions=drop
    ${n_bytes}    Should Match Regexp    ${output}    n_bytes=[0-9]+
    log    ${n_bytes}
    ${bytes}    Should Match Regexp    ${n_bytes}    [0-9]+
    log    ${bytes}
    Close Connection
    [Return]    ${packet_drop_count}    ${bytes}

Dump Flows Before Drop
    [Arguments]    ${ip}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name}    30
    log    ${output}
    Close Connection

Ssh Fail
    [Arguments]    ${vm_ip}    ${net_id}    ${user}=cirros
    ${remove_sshKey}    Set Variable    sudo ssh-keygen -f "/root/.ssh/known_hosts" -R ${vm_ip}
    ${rem_key}    Write Commands Until Expected Prompt    ${remove_sshKey}    $    60
    Log    ${rem_key}
    ${retry_ssh} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip}    ?    60
    Log    ${retry_ssh}
    ${yes}    Write Commands Until Expected Prompt    yes    d:    30
    log    ${yes}

Check Output
    [Arguments]    ${s1}    ${s2}
    log    ${s1}
    log    ${s2}
    ${match}    Get Regexp Matches    ${s1}    (${s2})    1
    log    ${match}
    ${len}    Get Length    ${match}
    ${return}    Set Variable If    ${len}>0    True    False
    [Return]    ${return}

Login To Vm
    [Arguments]    ${cmd}    ${password}=cubswin:)
    ${yes_login}    Write Commands Until Expected Prompt    yes    d:
    Log    ${yes_login}
    ${login} =    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${login}
    ${rcode} =    Run Keyword And Return Status    Check If Console Is VmInstance
    ${ssh_output} =    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}

Get Dpn Ids
    [Arguments]    ${ip}    ${Bridgename1}    ${username}    ${password}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    ${dev_stack_conn_id}=    SSHLibrary.Open Connection    ${ip}    $
    set suite variable    ${dev_stack_conn_id}
    Utils.Flexible SSH Login    ${username}    ${password}    delay=10s
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${Bridgename1} | head -1 | awk -F "dpid:" '{ print $2 }'
    log    ${output1}
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    log    ${Dpn_id}
    Close All Connections
    [Return]    ${Dpn_id}

Get Itm
    [Arguments]    ${itm}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${dp_ip_1}    ${Dpn_id_2}
    ...    ${dp_ip_2}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    @{Itm-no-vlan}    Create List    ${itm}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${dp_ip_1}
    ...    ${dp_ip_2}    ${Dpn_id_2}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm}    ${Itm-no-vlan}

Set Json
    [Arguments]    ${dp_ip_1}    ${dp_ip_2}    ${vlan}    ${gateway-ip}    ${subnet}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${netvirt_config_dir}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id":1    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id":2    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address":"2.2.2.2"    "ip-address": "${dp_ip_1}"
    ${body}    replace string    ${body}    "ip-address":"3.3.3.3"    "ip-address": "${dp_ip_2}"
    ${body}    replace string    ${body}    "vlan-id":0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip":"0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Create Vteps
    [Arguments]    ${dp_ip_1}    ${dp_ip_2}    ${vlan}    ${gateway-ip}    ${subnet}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${netvirt_config_dir}/Itm_creation_no_vlan.json
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    Set Json    ${dp_ip_1}    ${dp_ip_2}    ${vlan}    ${gateway-ip}    ${subnet}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

Add Bridge On Dpns
    [Arguments]    ${ip}    ${bridge_ip}    ${prompt}= $
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Execute Command    sudo ovs-vsctl add-br br0
    Execute Command    sudo ifconfig br0 ${bridge_ip} up
    Execute Command    sudo ovs-vsctl add-port br0 eth1
    ${show}    Execute Command    sudo ovs-vsctl show
    log    ${show}
    Should Contain    ${show}    br0
    Close All Connections

Get Tunnel
    [Arguments]    ${src}    ${dst}    ${type}
    [Documentation]    This Keyword Gets the Tunnel /Interface name which has been created between 2 DPNS by passing source , destination DPN Ids along with the type of tunnel which is configured.
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/${type}/
    Log    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${tunnel_match}    Get Regexp Matches    ${resp.content}    tun[0-9a-zA-Z]+
    ${tunnel}    get from list    ${tunnel_match}    3
    log    ${tunnel}
    [Return]    ${tunnel}

Ovs Verification 2 Dpn
    [Arguments]    ${ip}    ${username}    ${password}    ${tunnel}    ${prompt}
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    ${dev_stack_conn_id}=    SSHLibrary.Open Connection    ${ip}    prompt=${prompt}
    set suite variable    ${dev_stack_conn_id}
    Utils.Flexible SSH Login    ${username}    ${password}    delay=10s
    ${check}    Execute Command    sudo ovs-vsctl show
    Log    ${check}
    Should Contain    ${check}    ${tunnel}
    Close All Connections

Get Host Name
    [Arguments]    ${ip}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Set Global Variable    ${devstack_conn_id}
    ${hostname}    Write Commands Until Prompt    hostname    30
    @{host}    Split String    ${hostname}    \r\n
    log    ${host}
    ${host_name}    get from list    ${host}    0
    log    ${host_name}
    [Return]    ${host_name}

Rule delete
    [Arguments]    ${ip}    ${sgname}    ${proto}    ${dir}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${rule_id}    Write Commands Until Prompt    neutron security-group-rule-list | grep ${sgname} | grep ${proto} | grep ${dir} | awk {'print$2'}
    ${delete_rule}    Write Commands Until Prompt    neutron security-group-rule-delete ${rule_id}
    log    ${delete_rule}

Port update
    [Arguments]    ${ip}    ${portname}    ${command}
    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}    Write Commands Until Expected Prompt    neutron port-update ${portname} --${command}    $    30s
    log    ${output}
    should contain    ${output}    Updated port: ${portname}

Check Ping To Vm After Spawnning
    [Arguments]    ${ip}    ${net_name}    ${vm_ip}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${net_id} =    Get Net Id    ${net_name}    ${devstack_conn_id}
    Log    ${vm_ip}
    ${ping}    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping -c ${ping_packet_count} ${vm_ip}    $
    log    ${ping}
    ${check_prompt}    Should Contain    ${ping}    , 0% packet loss
    [Return]    ${devstack_conn_id}

Create Neutron Port With Default Securitygrp
    [Arguments]    ${net}    ${port}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron -v port-create ${net} --name ${port}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    Should Contain    ${OUTPUT}    Created a new port
    ${port_id}=    Should Match Regexp    ${OUTPUT}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${port_id}
    Close Connection
    [Return]    ${port_id}

Check packet Drop
    [Arguments]    ${table}    ${vm_metadata}
    Log    >>>> Check ${table} flows <<<<<<
    ${output}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table} | grep ${vm_metadata}    30
    log    ${output}
    should contain    ${output}    ${vm_metadata}
    ${n_packets}    Should Match Regexp    ${output}    n_packets=[0-9]+
    log    ${n_packets}
    ${packet_drop_count}    Should Match Regexp    ${n_packets}    [0-9]+
    log    ${packet_drop_count}
    ${n_bytes}    Should Match Regexp    ${output}    n_bytes=[0-9]+
    log    ${n_bytes}
    ${bytes}    Should Match Regexp    ${n_bytes}    [0-9]+
    log    ${bytes}
    [Return]    ${packet_drop_count}    ${bytes}

Dump Flows For Tables
    [Arguments]    ${ip}    ${table}    ${metadata}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table} |grep ct_state=+new+trk |grep metadata=${metadata}| grep actions=drop    30
    log    ${output}
    Close Connection

PreConfig
    [Documentation]    Start suite for Pre-configs done prior executing the testcases.
    ${devstack_conn_id}    Devstack Login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Set Global Variable    ${devstack_conn_id}
    ${check_1}    Wait Until Keyword Succeeds    30    10    check establishment    ${devstack_conn_id}    6653
    log    ${check_1}
    ${check_2}    Wait Until Keyword Succeeds    30    10    check establishment    ${devstack_conn_id}    6640
    log    ${check_2}
    ${sg_id}    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Show    ${sg_name}
    log    >>>> Deleting Default sg grps <<<<<
    Delete Default Rules
    Log    >>>> rule for icmp <<<
    Neutron Security Group Rule Create    ${sg_name}    direction=${direction[1]}    protocol=${protocols[0]}    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=${direction[0]}    protocol=${protocols[0]}    remote_ip_prefix=0.0.0.0/0
    Log    >>>> rule for ssh to vms <<<<
    OpenStackOperations.Neutron Security Group Rule Create    ${sg_name}    direction=${direction[0]}    port_range_min= 22    protocol=${protocol}    port_range_max= 23
    Create Network    ${Networks[0]}
    Create Subnet    ${Networks[0]}    ${Subnet[0]}    ${prefix_list[0]}    additional_args= --enable-dhcp
    ${net_output}    List Networks
    Should Contain    ${net_output}    ${Networks[0]}
    ${subnet_output}    List Subnets
    Should Contain    ${subnet_output}    ${Subnet[0]}

Delete Default Rules
    [Documentation]    This keyword deletes the default Egress rules when custom security group is created
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${list_default_rules}    Write Commands Until Prompt    neutron security-group-rule-list | grep ${sg_name}| awk '{print$2}'    30s
    log    ${list_default_rules}
    @{array}    split string    ${list_default_rules}    \n
    log    ${array}
    ${deleted}    Write Commands Until Prompt    neutron security-group-rule-delete ${array[0]}    30s
    log    ${deleted}
    ${deleted_rule}    Write Commands Until Prompt    neutron security-group-rule-delete ${array[1]}    30s
    log    ${deleted_rule}
    Close Connection

check establishment
    [Arguments]    ${conn_id}    ${port}
    [Documentation]    Checks the establisment status for port 6640 and 6633
    Switch Connection    ${conn_id}
    ${check_establishment}    Execute Command    netstat -anp | grep ${port}
    Should contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Suite teardown
    [Documentation]    Stop suite does a suite tear down at the end
    log    closing the session

Check Ping In Existing Connection
    [Arguments]    ${eth_ip}    ${command}
    ${ip}    Write Commands Until Prompt    ifconfig    30
    should contain    ${ip}    ${eth_ip}
    ${ping_test}    Write Commands Until Prompt    ${command}    90
    should contain    ${ping_test}    100%

Establish SSH
    [Arguments]    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    ${net_name}    ${devstack_conn_id}
    Log    ${vm_ip}
    ${ssh}    SSHLibrary.Write    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip}
    ${output}    SSHLibrary.Read    delay=30s
    log    ${output}
    ${check_prompt}    Check Output    ${output}    yes/no
    log    ${check_prompt}
    Run Keyword If    '${check_prompt}'=='True'    Login To Vm    {cmd}
    ${check_prompt_2}    Check Output    ${output}    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED
    Run Keyword If    '${check_prompt_2}'=='True'    Ssh Fail    ${vm_ip}    ${net_id}
    ${output} =    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}    timeout=60s
    Log    ${output}
    ${rcode} =    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output} =    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}    90
    [Return]    ${devstack_conn_id}

Check packet count
    [Arguments]    ${count_1}    ${count_2}
    ${first_count}    Set Variable    ${count_1}
    ${second_count}    Set Variable    ${count_2}
    ${final_count}    evaluate    ${first_count}-${second_count}
    log    ${final_count}
    ${status}    Evaluate    ${final_count}==${ping_packet_count}
    log    ${status}
    [Return]    ${status}

Delete Security Group
    [Arguments]    ${Name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron security-group-delete ${Name}
    Log    ${cmd}
    ${output1}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${output1}
    ${cmd}=    Set Variable    neutron security-group-list
    Log    ${cmd}
    ${output2}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${output2}
    Should Not Contain    ${output2}    ${Name}

get security group id for admin default
    ${command}    Set Variable    neutron security-group-list | grep default | awk '{print$2}'
    ${templist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${sg_id_list}    Split To Lines    ${templist}
    ${SGlist}    Get Slice From List    ${sg_id_list}    \    -1
    ${project_id_temp}    Write Commands Until Expected Prompt    openstack project list | grep '| admin' | awk '{print$2}'    $    60
    @{projectlist}    Split String    ${project_id_temp}    \r\n
    ${project_id}    Get From List    ${projectlist}    0
    : FOR    ${id}    IN    @{SGlist}
    \    ${tenant_id_temp}    Write Commands Until Expected Prompt    neutron security-group-show ${id} | grep '| tenant_id' | awk '{print$4}'    $    60
    \    @{tenantlist}    Split String    ${tenant_id_temp}    \r\n
    \    ${tenant_id}    Get From List    ${tenantlist}    0
    \    Run Keyword If    '${project_id}'=='${tenant_id}'    Return From Keyword    ${id}

Clean
    : FOR    ${vm}    IN    @{VM_list}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${vm}
    \    Log    ${vm}
    : FOR    ${prt}    IN    @{port_name}
    \    Run Keyword And Ignore Error    Delete Port    ${prt}
    \    Log    ${prt}
    : FOR    ${nt}    IN    @{Networks}
    \    Run Keyword And Ignore Error    Delete Network    ${nt}
    \    Log    ${nt}
    Run Keyword And Ignore Error    Delete Default Rules
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${rule}    Write Commands Until Prompt    neutron security-group-delete ${sg_name}
    Log    ${rule}
    ${defid}    get security group id for admin default
    ${rule}    Write Commands Until Prompt    neutron security-group-delete ${defid}
    Log    ${rule}
