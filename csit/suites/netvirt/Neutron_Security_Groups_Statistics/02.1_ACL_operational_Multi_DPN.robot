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
${devstack_path}    /opt/stack/devstack
${sg_name}        Sg_rule1
@{direction}      ingress    egress    both
${flavour}        m1.tiny
@{port_name}      sg_port1    sg_port2    sg_port3
@{VM_list}        Sg_test_VM1    Sg_test_VM2    Sg_test_VM3
@{tables}         table=0    table=244    table=214    table=17    table=55    # port entery check , ingress table , egress table
${br_name}        br-int
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
${port}           23
@{bridge_ip}      35.10.10.11    35.10.10.12
${itm}            TZA
@{protocols}      icmp    tcp    udp

*** Test Cases ***
Verify flow stats request and response and drop packets count and bytes for direction Egress for no rule match data packet for single port and list of ports (In Multi-DPN)
    [Setup]    PreConfig
    Add Bridge On Dpns    ${TOOLS_SYSTEM_1_IP}    ${bridge_ip[0]}    $
    Add Bridge On Dpns    ${TOOLS_SYSTEM_2_IP}    ${bridge_ip[1]}    $
    ${Dpn_id_1}    Get Dpn Ids    ${TOOLS_SYSTEM_1_IP}    ${br_name}    ${stack_login[0]}    ${stack_login[1]}
    ${Dpn_id_2}    Get Dpn Ids    ${TOOLS_SYSTEM_2_IP}    ${br_name}    ${stack_login[0]}    ${stack_login[1]}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${substr}    Should Match Regexp    ${bridge_ip[0]}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    Create Vteps    ${bridge_ip[0]}    ${bridge_ip[1]}    ${vlan}    ${gateway-ip}    ${subnet}
    Wait Until Keyword Succeeds    10    5    Get Itm    ${itm}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${bridge_ip[0]}    ${Dpn_id_2}    ${bridge_ip[1]}
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    Set Global Variable    ${tunnel-1}
    ${tunnel-2}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    Set Global Variable    ${tunnel-2}
    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${TOOLS_SYSTEM_1_IP}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${tunnel-1}    $
    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${TOOLS_SYSTEM_2_IP}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${tunnel-2}    $
    Create Port    ${Networks[0]}    ${port_name[1]}    ${sg_name}
    Create Port    ${Networks[0]}    ${port_name[2]}    ${sg_name}
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[1]}
    should contain    ${port_output}    ${port_name[2]}
    ${h_name1}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    ${h_name2}    Get Host Name    ${TOOLS_SYSTEM_2_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[1]}    ${VM_list[0]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name1}
    Create Vm    ${TOOLS_SYSTEM_2_IP}    ${flavour}    ${port_name[2]}    ${VM_list[1]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name2}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_1_id}    Get Port Id    ${port_name[1]}    ${devstack_conn_id}
    ${port_2_id}    Get Port Id    ${port_name[2]}    ${devstack_conn_id}
    log    ${port_1_id}
    log    ${port_2_id}
    Set Global Variable    ${port_1_id}
    Set Global Variable    ${port_2_id}
    ${sub_port_id_1}    Get Sub Port Id    ${port_1_id}
    log    ${sub_port_id_1}
    ${sub_port_id_2}    Get Sub Port Id    ${port_2_id}
    log    ${sub_port_id_2}
    ${in_port_vm1}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_1}
    log    ${in_port_vm1}
    ${vm1_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm1}
    log    ${vm1_metadata}
    Set Global Variable    ${vm1_metadata}
    ${in_port_vm2}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_2_IP}    ${br_name}
    ...    ${sub_port_id_2}
    log    ${in_port_vm2}
    ${vm2_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm2}
    log    ${vm2_metadata}
    Set Global Variable    ${vm2_metadata}
    ${vm1_ip}    Get Vm Ip    ${VM_list[0]}    ${Networks[0]}
    ${vm2_ip}    Get Vm Ip    ${VM_list[1]}    ${Networks[0]}
    log    ${vm1_ip}
    log    ${vm2_ip}
    Set Global Variable    ${vm1_ip}
    Set Global Variable    ${vm2_ip}
    ${devstack_conn_id1}    Devstack Login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${devstack_conn_id2}    Devstack Login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Switch Connection    ${devstack_conn_id1}
    Check In Port    ${in_port_vm1}
    Switch Connection    ${devstack_conn_id2}
    Check In Port    ${in_port_vm2}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${rpc_output1}    Statistics Call    ${direction[2]}    ${port_1_id}
    log    ${rpc_output1}
    ${rpc_output2}    Statistics Call    ${direction[2]}    ${port_2_id}
    log    ${rpc_output2}
    ${delete_icmp_egress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[1]}
    ${command}    Set Variable    ping -c 4 ${vm2_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id1}    ${Networks[0]}    ${vm1_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    log    ${drops}
    ${packet_drop}    Get From List    ${drops}    0
    ${bytes}    get from list    ${drops}    1
    ${rpc_output}    Statistics Call    ${direction[1]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    Log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${bytes}
    ${command}    Set Variable    ping -c 4 ${vm1_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id2}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_2_IP}    ${tables[2]}    ${vm2_metadata}
    log    ${drops}
    ${packet_drop}    Get From List    ${drops}    0
    ${bytes}    get from list    ${drops}    1
    ${rpc_output}    Statistics Call    ${direction[1]}    ${port_2_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${bytes}
    [Teardown]    Clean

Verify flow stats request and response and drop packets count and bytes for direction Ingress for no rule match data packet for single port. (In Multi-DPN)
    [Setup]    PreConfig
    Create Port    ${Networks[0]}    ${port_name[1]}    ${sg_name}
    Create Port    ${Networks[0]}    ${port_name[2]}    ${sg_name}
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[1]}
    should contain    ${port_output}    ${port_name[2]}
    ${h_name1}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    ${h_name2}    Get Host Name    ${TOOLS_SYSTEM_2_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[1]}    ${VM_list[0]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name1}
    Create Vm    ${TOOLS_SYSTEM_2_IP}    ${flavour}    ${port_name[2]}    ${VM_list[1]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name2}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_1_id}    Get Port Id    ${port_name[1]}    ${devstack_conn_id}
    ${port_2_id}    Get Port Id    ${port_name[2]}    ${devstack_conn_id}
    log    ${port_1_id}
    log    ${port_2_id}
    Set Global Variable    ${port_1_id}
    Set Global Variable    ${port_2_id}
    ${sub_port_id_1}    Get Sub Port Id    ${port_1_id}
    log    ${sub_port_id_1}
    ${sub_port_id_2}    Get Sub Port Id    ${port_2_id}
    log    ${sub_port_id_2}
    ${in_port_vm1}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_1}
    log    ${in_port_vm1}
    ${vm1_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm1}
    log    ${vm1_metadata}
    Set Global Variable    ${vm1_metadata}
    ${in_port_vm2}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_2_IP}    ${br_name}
    ...    ${sub_port_id_2}
    log    ${in_port_vm2}
    ${vm2_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm2}
    log    ${vm2_metadata}
    Set Global Variable    ${vm2_metadata}
    ${vm1_ip}    Get Vm Ip    ${VM_list[0]}    ${Networks[0]}
    ${vm2_ip}    Get Vm Ip    ${VM_list[1]}    ${Networks[0]}
    log    ${vm1_ip}
    log    ${vm2_ip}
    Set Global Variable    ${vm1_ip}
    Set Global Variable    ${vm2_ip}
    ${devstack_conn_id1}    Devstack Login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${devstack_conn_id2}    Devstack Login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Switch Connection    ${devstack_conn_id1}
    Check In Port    ${in_port_vm1}
    Switch Connection    ${devstack_conn_id2}
    Check In Port    ${in_port_vm2}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${rpc_output}    Statistics Call    ${direction[2]}    ${port_1_id}
    log    ${rpc_output}
    ${rpc_output}    Statistics Call    ${direction[2]}    ${port_2_id}
    log    ${rpc_output}
    ${delete_icmp_ingress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[0]}
    ${delete_icmp_ingress}    Rule delete    ${TOOLS_SYSTEM_2_IP}    ${sg_name}    ${protocols[0]}    ${direction[0]}
    ${command}    Set Variable    ping -c 4 ${vm1_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id2}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    log    ${drops}
    ${packet_drop}    get from list    ${drops}    0
    ${bytes}    get from list    ${drops}    1
    ${rpc_output}    Statistics Call    ${direction[0]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${bytes}
    ${rpc_output}    Statistics Call    ${direction[1]}    ${port_1_id}
    log    ${rpc_output}
    ${rpc_output}    Statistics Call    ${direction[1]}    ${port_2_id}
    log    ${rpc_output}
    ${command}    Set Variable    ping -c 4 ${vm2_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id1}    ${Networks[0]}    ${vm1_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_2_IP}    ${tables[1]}    ${vm2_metadata}
    log    ${drops}
    ${packet_drop}    get from list    ${drops}    0
    ${bytes}    get from list    ${drops}    1
    ${packet_drop_ingress}    Set Variable    ${packet_drop}
    Log    ${packet_drop_ingress}
    ${bytes_ingress}    Set Variable    ${bytes}
    Log    ${bytes_ingress}
    ${rpc_output}    Statistics Call    ${direction[0]}    ${port_2_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${bytes}
    [Teardown]    Clean

Verify flow stats request and response for direction ingress port with no security group attached. \ (In Multi-DPN).
    [Setup]    PreConfig
    Create Port    ${Networks[0]}    ${port_name[1]}    ${sg_name}
    Create Neutron Port With Additional Params    ${Networks[0]}    ${port_name[2]}    --no-security-groups --port_security_enabled=false
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[1]}
    should contain    ${port_output}    ${port_name[2]}
    ${h_name1}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    ${h_name2}    Get Host Name    ${TOOLS_SYSTEM_2_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[1]}    ${VM_list[0]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name1}
    Create Vm    ${TOOLS_SYSTEM_2_IP}    ${flavour}    ${port_name[2]}    ${VM_list[1]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name2}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_1_id}    Get Port Id    ${port_name[1]}    ${devstack_conn_id}
    ${port_2_id}    Get Port Id    ${port_name[2]}    ${devstack_conn_id}
    log    ${port_1_id}
    log    ${port_2_id}
    Set Global Variable    ${port_1_id}
    Set Global Variable    ${port_2_id}
    ${sub_port_id_1}    Get Sub Port Id    ${port_1_id}
    log    ${sub_port_id_1}
    ${sub_port_id_2}    Get Sub Port Id    ${port_2_id}
    log    ${sub_port_id_2}
    ${in_port_vm1}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_1}
    log    ${in_port_vm1}
    ${vm1_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm1}
    log    ${vm1_metadata}
    Set Global Variable    ${vm1_metadata}
    ${in_port_vm2}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_2_IP}    ${br_name}
    ...    ${sub_port_id_2}
    log    ${in_port_vm2}
    ${vm2_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm2}
    log    ${vm2_metadata}
    Set Global Variable    ${vm2_metadata}
    ${vm1_ip}    Get Vm Ip    ${VM_list[0]}    ${Networks[0]}
    ${vm2_ip}    Get Vm Ip    ${VM_list[1]}    ${Networks[0]}
    log    ${vm1_ip}
    log    ${vm2_ip}
    Set Global Variable    ${vm1_ip}
    Set Global Variable    ${vm2_ip}
    ${devstack_conn_id1}    Devstack Login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${devstack_conn_id2}    Devstack Login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Switch Connection    ${devstack_conn_id1}
    Check In Port    ${in_port_vm1}
    Switch Connection    ${devstack_conn_id2}
    Check In Port    ${in_port_vm2}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${rpc_output}    Statistics Call    ${direction[2]}    ${port_1_id}
    log    ${rpc_output}
    ${rpc_output}    Statistics Call    ${direction[2]}    ${port_2_id}
    log    ${rpc_output}
    ${delete_icmp_ingress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[0]}
    ${command}    Set Variable    ping -c 4 ${vm1_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id2}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    log    ${drops}
    ${packet_drop}    get from list    ${drops}    0
    ${bytes}    get from list    ${drops}    1
    ${rpc_output}    Statistics Call    ${direction[0]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${bytes}
    ${rpc_output}    Statistics Call    ${direction[1]}    ${port_1_id}
    log    ${rpc_output}
    ${rpc_output}    Statistics Call    ${direction[1]}    ${port_2_id}
    log    ${rpc_output}
    [Teardown]    Clean

Verify flow stats request and response and drop packets count and bytes for direction ingress for invalid data packet for single port (Multi-DPN).
    [Setup]    PreConfig
    Create Port    ${Networks[0]}    ${port_name[1]}    ${sg_name}
    Create Port    ${Networks[0]}    ${port_name[2]}    ${sg_name}
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[1]}
    should contain    ${port_output}    ${port_name[2]}
    ${h_name1}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    ${h_name2}    Get Host Name    ${TOOLS_SYSTEM_2_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[1]}    ${VM_list[0]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name1}
    Create Vm    ${TOOLS_SYSTEM_2_IP}    ${flavour}    ${port_name[2]}    ${VM_list[1]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name2}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_1_id}    Get Port Id    ${port_name[1]}    ${devstack_conn_id}
    ${port_2_id}    Get Port Id    ${port_name[2]}    ${devstack_conn_id}
    log    ${port_1_id}
    log    ${port_2_id}
    Set Global Variable    ${port_1_id}
    Set Global Variable    ${port_2_id}
    ${sub_port_id_1}    Get Sub Port Id    ${port_1_id}
    log    ${sub_port_id_1}
    ${sub_port_id_2}    Get Sub Port Id    ${port_2_id}
    log    ${sub_port_id_2}
    ${in_port_vm1}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_1}
    log    ${in_port_vm1}
    ${vm1_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm1}
    log    ${vm1_metadata}
    Set Global Variable    ${vm1_metadata}
    ${in_port_vm2}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_2_IP}    ${br_name}
    ...    ${sub_port_id_2}
    log    ${in_port_vm2}
    ${vm2_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm2}
    log    ${vm2_metadata}
    Set Global Variable    ${vm2_metadata}
    ${vm1_ip}    Get Vm Ip    ${VM_list[0]}    ${Networks[0]}
    ${vm2_ip}    Get Vm Ip    ${VM_list[1]}    ${Networks[0]}
    log    ${vm1_ip}
    log    ${vm2_ip}
    Set Global Variable    ${vm1_ip}
    Set Global Variable    ${vm2_ip}
    ${devstack_conn_id1}    Devstack Login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${devstack_conn_id2}    Devstack Login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Switch Connection    ${devstack_conn_id1}
    Check In Port    ${in_port_vm1}
    Switch Connection    ${devstack_conn_id2}
    Check In Port    ${in_port_vm2}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${rpc_output}    Statistics Call    ${direction[2]}    ${port_1_id}
    log    ${rpc_output}
    ${rpc_output}    Statistics Call    ${direction[2]}    ${port_2_id}
    log    ${rpc_output}
    ${delete_icmp_ingress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[0]}
    ${delete_icmp_ingress}    Rule delete    ${TOOLS_SYSTEM_2_IP}    ${sg_name}    ${protocols[0]}    ${direction[0]}
    ${command}    Set Variable    ping -c 4 -s 9000 ${vm1_ip}
    ${ssh_output}    Ssh To Vm    ${devstack_conn_id2}    ${Networks[0]}    ${vm2_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[1]}    ${vm1_metadata}
    log    ${drops}
    ${packet_drop}    get from list    ${drops}    0
    ${bytes}    get from list    ${drops}    1
    ${rpc_output}    Statistics Call    ${direction[0]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[0]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${bytes}
    [Teardown]    Clean

Verify flow stats request and response and drop packets count and bytes for direction egress for invalid data packet for single port (Multi-DPN).
    [Setup]    PreConfig
    Create Port    ${Networks[0]}    ${port_name[1]}    ${sg_name}
    Create Port    ${Networks[0]}    ${port_name[2]}    ${sg_name}
    ${port_output}    List Ports
    should contain    ${port_output}    ${port_name[1]}
    should contain    ${port_output}    ${port_name[2]}
    ${h_name1}    Get Host Name    ${TOOLS_SYSTEM_1_IP}
    ${h_name2}    Get Host Name    ${TOOLS_SYSTEM_2_IP}
    Create Vm    ${TOOLS_SYSTEM_1_IP}    ${flavour}    ${port_name[1]}    ${VM_list[0]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name1}
    Create Vm    ${TOOLS_SYSTEM_2_IP}    ${flavour}    ${port_name[2]}    ${VM_list[1]}    ${stack_login[0]}    ${stack_login[1]}
    ...    ${h_name2}
    ${devstack_conn_id}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${port_1_id}    Get Port Id    ${port_name[1]}    ${devstack_conn_id}
    ${port_2_id}    Get Port Id    ${port_name[2]}    ${devstack_conn_id}
    log    ${port_1_id}
    log    ${port_2_id}
    Set Global Variable    ${port_1_id}
    Set Global Variable    ${port_2_id}
    ${sub_port_id_1}    Get Sub Port Id    ${port_1_id}
    log    ${sub_port_id_1}
    ${sub_port_id_2}    Get Sub Port Id    ${port_2_id}
    log    ${sub_port_id_2}
    ${in_port_vm1}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_1_IP}    ${br_name}
    ...    ${sub_port_id_1}
    log    ${in_port_vm1}
    ${vm1_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm1}
    log    ${vm1_metadata}
    Set Global Variable    ${vm1_metadata}
    ${in_port_vm2}    Wait Until Keyword Succeeds    10    2    Get Port Number    ${TOOLS_SYSTEM_2_IP}    ${br_name}
    ...    ${sub_port_id_2}
    log    ${in_port_vm2}
    ${vm2_metadata}    Get Metadata    ${devstack_conn_id}    ${in_port_vm2}
    log    ${vm2_metadata}
    Set Global Variable    ${vm2_metadata}
    ${vm1_ip}    Get Vm Ip    ${VM_list[0]}    ${Networks[0]}
    ${vm2_ip}    Get Vm Ip    ${VM_list[1]}    ${Networks[0]}
    log    ${vm1_ip}
    log    ${vm2_ip}
    Set Global Variable    ${vm1_ip}
    Set Global Variable    ${vm2_ip}
    ${devstack_conn_id1}    Devstack Login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${devstack_conn_id2}    Devstack Login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Switch Connection    ${devstack_conn_id1}
    Check In Port    ${in_port_vm1}
    Switch Connection    ${devstack_conn_id2}
    Check In Port    ${in_port_vm2}
    Dump Flows Before Drop    ${TOOLS_SYSTEM_1_IP}
    ${rpc_output1}    Statistics Call    ${direction[2]}    ${port_1_id}
    log    ${rpc_output1}
    ${rpc_output2}    Statistics Call    ${direction[2]}    ${port_2_id}
    log    ${rpc_output2}
    ${delete_icmp_egress}    Rule delete    ${TOOLS_SYSTEM_1_IP}    ${sg_name}    ${protocols[0]}    ${direction[1]}
    ${command}    Set Variable    ping -c 4 -s 9000 ${vm2_ip}
    ${ssh_output}    Ssh To Vm    ${dev_stack_conn_id}    ${Networks[0]}    ${vm1_ip}    ${command}
    should contain    ${ssh_output}    100%
    @{drops}    Check Flows    ${TOOLS_SYSTEM_1_IP}    ${tables[2]}    ${vm1_metadata}
    log    ${drops}
    ${packet_drop}    Get From List    ${drops}    0
    ${bytes}    get from list    ${drops}    1
    ${rpc_output}    Statistics Call    ${direction[1]}    ${port_1_id}
    log    ${rpc_output}
    ${regexp_pattern}    Set Variable    {"direction":"${direction[1]}","packets":{"invalid-drop-count":[0-9]+,"drop-count":[0-9]+}
    ${rpc_drop_1}    Should Match Regexp    ${rpc_output}    ${regexp_pattern}
    should contain    ${rpc_drop_1}    "drop-count":${packet_drop}
    ${regexp_pattern_bytes}    Set Variable    "bytes":{"invalid-drop-count":0,"drop-count":[0-9]+}}
    ${byte_drop}    Should Match Regexp    ${rpc_output}    ${regexp_pattern_bytes}
    Log    ${byte_drop}
    Should Contain    ${byte_drop}    "drop-count":${bytes}
    [Teardown]    Clean

*** Keywords ***
Devstack Login
    [Arguments]    ${ip}    ${username}    ${password}    ${devstack_path}    ${prompt}
    ${dev_stack_conn_id}=    SSHLibrary.Open Connection    ${ip}    prompt=${prompt}
    set suite variable    ${dev_stack_conn_id}
    log    ${username},${password}
    login    ${username}    ${password}
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
    Comment    @{dump}    re.split    \n    ${id_with_prompt}
    Comment    ${ret_id}    get from list    ${dump}    1
    Comment    log    ${ret_id}
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

Statistics Call
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
    ${ping}    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ping -c 4 ${vm_ip}    $
    log    ${ping}
    ${check_prompt}    Should Contain    ${ping}    , 0% packet loss
    Close Connection

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
    [Arguments]    ${ip}    ${table}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=${table} | grep actions=drop    30
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
    Neutron Security Group Rule Create    ${sg_name}    direction=${direction[1]}    protocol=${protocols[1]}    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=${direction[0]}    protocol=${protocols[1]}    remote_ip_prefix=0.0.0.0/0
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
    ${list_default_rules}    Write Commands Until Prompt    neutron security-group-rule-list | grep ${sg_name}| awk '{print$2}'
    log    ${list_default_rules}
    @{array}    split string    ${list_default_rules}    \n
    log    ${array}
    ${deleted}    Write Commands Until Prompt    neutron security-group-rule-delete ${array[0]}
    log    ${deleted}
    ${deleted_rule}    Write Commands Until Prompt    neutron security-group-rule-delete ${array[1]}
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
    Sleep    60

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

Check Fllows
    [Arguments]    ${ip}    ${table}    ${vm_metadata}
    ${devstack_conn_id}    Devstack Login    ${ip}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Log    >>>> Check ${table} flows <<<<<<
    ${output}    Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table} | grep ${vm_metadata}|grep actions=drop    30
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
