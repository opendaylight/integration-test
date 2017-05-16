*** Settings ***
Documentation     This test suite involves Priority1 test cases \ for the sanity. This covers test areas such as, IPV6 assignment in SLAAC Mode, Traffic flow when VMs are brought up with security rules for different protocols(tcp, udp, icmp), Allowed address pair test cases.
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{Networks}       NET10    NET20
@{VM_List}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
@{Routers}        router1
@{V4subnets}      10.10.10.0    20.20.20.0
@{V4subnet_Names}    subnet1v4    subnet2v4
${Br_Name}        br-int
@{Login_Credentials}    stack    stack    root    password
${Devstack_Path}    /opt/stack/devstack
@{SG_Name}        SG1    SG2    SG3    SG4    default
@{Rule_List}      tcp    udp    icmpv6    10000    10500    IPV6    # protocol1, protocol2, protocol3, port_min, port_max, ether_type
@{Direction}      ingress    egress    both
@{Image_Name}     cirros-0.3.4-x86_64-uec    ubuntu-sg
@{Protocols}      tcp6    udp6    icmp6
@{Remote_Group}    SG1    prefix    any
@{Remote_Prefix}    ::0/0    2001:db8:1234::/64    2001:db8:4321::/64
@{Logical_Addr}    2001:db8:1234:0:1111:2343:3333:4444    2001:db8:1266::6
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
@{dpip}           192.168.78.101    192.168.78.103
${Itm_Created}    TZA
@{Bridge_names}    BR1    BR1
${Flavor_Name}    myhuge
@{Tables}         table=0    table=17    table=40    table=41    table=45    table=50    table=51
...               table=60    table=220    table=251    table=252
${image}          cirros-0.3.4-x86_64-uec
${Flavor_Name1}    m1.tiny

*** Test Cases ***
Test Host Configuration
    [Documentation]    Validate host config and pseudoagentportbinding feature implemented by ODL Neutron.
    Switch Connection    ${root_conn_id_1}
    Log    >>> Get UUID <<<
    ${uuid1}    Write Commands Until Expected Prompt    export OVSUUID=$(ovs-vsctl get Open_vSwitch . _uuid)    \#    20
    ${output}    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch $OVSUUID external_ids    \#    20
    log    ${output}
    Switch Connection    ${root_conn_id_2}
    ${uuid2}    Write Commands Until Expected Prompt    export OVSUUID=$(ovs-vsctl get Open_vSwitch . _uuid)    \#    20
    ${output}    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch $OVSUUID external_ids    \#    20
    log    ${output}
    Log    >>>> Get Hostname <<<<
    ${hostname1}    Get Hostname    ${conn_id_1}
    Log    ${hostname1}
    Switch Connection    ${root_conn_id_1}
    Log    >>>> Configure Host Config on OVS1 <<<
    ${allowed_network_types}    Set Variable    \\"allowed_network_types\\":[\\"local\\",\\"vlan\\",\\"vxlan\\",\\"gre\\"]
    ${bridge_mappings}    Set Variable    \\"bridge_mappings\\"={\\"default\\":\\"br-int\\"}
    ${datapath_type}    Set Variable    \\"datapath_type\\":\\"netdev\\"
    ${vif_type}    Set Variable    \\"vif_type\\":\\"vhostuser\\"
    ${vnic_type}    Set Variable    \\"vnic_type\\":\\"normal\\"
    ${has_datapath_type_netdev}    Set Variable    \\"has_datapath_type_netdev\\":\\"true\\"
    ${port_prefix}    Set Variable    \\"port_prefix\\":\\"vhu\\"
    ${vhostuser_socket}    Set Variable    \\"vhostuser_socket\\":\\"/var/run/openvswitch/vhu\\\$PORT_ID\\"
    ${uuid}    Set Variable    \\"uuid\\":\\"${output}\\"
    ${vhostuser_socket_dir}    Set Variable    \\"vhostuser_socket_dir\\":\\"/var/run/openvswitch\\"
    ${support_vhost_user}    Set Variable    \\"support_vhost_user\\":\\"true\\"
    ${vhostuser_ovs_plug}    Set Variable    \\"vhostuser_ovs_plug\\":\\"true\\"
    ${host_addresses}    Set Variable    \\"host_addresses\\":\\"[${hostname1}]\\"
    ${vhostuser_mode}    Set Variable    \\"vhostuser_mode\\":\\"client\\"
    Set Vhost Configuration    ${hostname1}    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${port_prefix}    ${vhostuser_socket}    ${vhostuser_socket_dir}    ${support_vhost_user}    ${vhostuser_ovs_plug}
    ...    ${host_addresses}    ${vhostuser_mode}
    Log    >>>> Check Operational Data in ODL for HostConfig For OVS1 <<<
    ${uri}    Set Variable    ${OPERATIONAL_API}/neutron:neutron/hostconfigs/hostconfig/${hostname1}/ODL%20L2/
    @{host_config_elements}    Create List    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${port_prefix}    ${vhostuser_socket}    ${vhostuser_socket_dir}    ${support_vhost_user}    ${vhostuser_ovs_plug}
    ...    ${host_addresses}    ${vhostuser_mode}
    Check For Elements At URI    ${OPERATIONAL_API}/neutron:neutron/hostconfigs/    ${host_config_elements}
    Log    >>>> Get Hostname <<<<
    ${hostname2}    Get Hostname    ${conn_id_2}
    Log    ${hostname2}
    Switch Connection    ${root_conn_id_2}
    Log    >>>> Configure Host Config on OVS2 <<<
    ${allowed_network_types}    Set Variable    \\"allowed_network_types\\":[\\"local\\",\\"vlan\\",\\"vxlan\\",\\"gre\\"]
    ${bridge_mappings}    Set Variable    \\"bridge_mappings\\"={\\"default\\":\\"br-int\\"}
    ${datapath_type}    Set Variable    \\"datapath_type\\":\\"system\\"
    ${vif_type}    Set Variable    \\"vif_type\\":\\"ovs\\"
    ${vnic_type}    Set Variable    \\"vnic_type\\":\\"normal\\"
    ${has_datapath_type_netdev}    Set Variable    \\"has_datapath_type_netdev\\":\\"false\\"
    ${support_vhost_user}    Set Variable    \\"support_vhost_user\\":\\"false\\"
    ${host_addresses}    Set Variable    \\"host_addresses\\":\\"[${hostname2}]\\"
    Set OVS Host Configuration    ${hostname2}    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${support_vhost_user}    ${host_addresses}
    Log    >>>> Check Operational Data in ODL for HostConfig For OVS2 <<<
    ${uri}    Set Variable    ${OPERATIONAL_API}/neutron:neutron/hostconfigs/hostconfig/${hostname2}/ODL%20L2/
    @{host_config_elements}    Create List    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${support_vhost_user}    ${host_addresses}
    Check For Elements At URI    ${OPERATIONAL_API}/neutron:neutron/hostconfigs/    ${host_config_elements}
    create ITM Tunnel
    Create Network    ${Networks[0]}    --port-security-enabled=False
    Create Network    ${Networks[1]}    --port-security-enabled=False
    Create Subnet    ${Networks[0]}    ${V4subnet_Names[0]}    ${V4subnets[0]}/24
    Create Subnet    ${Networks[1]}    ${V4subnet_Names[1]}    ${V4subnets[1]}/24
    Create Router    ${Routers[0]}
    Add Router Interface    ${Routers[0]}    ${V4subnet_Names[0]}
    Add Router Interface    ${Routers[0]}    ${V4subnet_Names[1]}
    Remove All Elements If Exist    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/
    Post Elements To URI From File    ${CONFIG_API}/    ${netvirt_config_dir}/enable_dhcp.json
    @{list}=    Create List    "controller-dhcp-enabled"    true
    Check For Elements At URI    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/    ${list}
    Switch Connection    ${conn_id_1}
    Create Flavor    ${Flavor_Name}
    ${hostname1}    Get Hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    ${hostname2}    Get Hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[0]}    ${VM_list[0]}    ${image}    ${hostname1}    ${Flavor_Name}
    Sleep    60
    ${output2}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-ports-desc br-int -OOpenflow13    $    20
    log    ${output2}
    Spawn Vm    ${Networks[0]}    ${VM_list[1]}    ${image}    ${hostname2}    ${Flavor_Name}
    Switch Connection    ${conn_id_2}
    Sleep    40
    ${output2}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-ports-desc br-int -OOpenflow13    $    20
    log    ${output2}
    Log    >>>> Boot VM3 in DPN2 <<<
    Spawn Vm    ${Networks[1]}    ${VM_list[2]}    ${image}    ${hostname2}    ${Flavor_Name}
    Sleep    40
    ${output2}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-ports-desc br-int -OOpenflow13    $    20
    log    ${output2}
    ${virshid1}    Get Vm Instance    ${VM_list[0]}
    ${virshid2}    Get Vm Instance    ${VM_list[1]}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    ${vm1output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid1}
    ...    ifconfig eth0
    ${vm2output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid2}
    ...    ifconfig eth0
    ${vm3output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid3}
    ...    ifconfig eth0
    Switch Connection    ${conn_id_1}
    ${vm1ip}    get network specific ip address    ${VM_list[0]}    ${Networks[0]}
    ${vm2ip}    get network specific ip address    ${VM_list[1]}    ${Networks[0]}
    ${vm3ip}    get network specific ip address    ${VM_list[2]}    ${Networks[1]}
    Should Contain    ${vm1output}    ${vm1ip}
    Should Contain    ${vm2output}    ${vm2ip}
    Should Contain    ${vm3output}    ${vm3ip}
    Ping From Virsh Console    ${virshid1}    ${vm2ip}    ${conn_id_1}    , 0% packet loss
    Ping From Virsh Console    ${virshid1}    ${vm3ip}    ${conn_id_1}    , 0% packet loss
    Testcase Cleanup

*** Keywords ***
Virsh Output
    [Arguments]    ${conn_id}    ${virshid1}    ${cmd}    ${user}=cirros    ${pwd}=cubswin:)    ${vm_prompt}=$
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    virsh console ${virshid1}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    300
    Write Commands Until Expected Prompt    ${user}    Password:    300
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30
    ${output}    Write Commands Until Expected Prompt    ${cmd}    ${vm_prompt}    30
    log    ${output}
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}
    ${pwd_output}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd_output}
    Close All Connections
    ${conn_id_1}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_1}
    ${conn_id_2}    devstack login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_2}
    Switch Connection    ${conn_id_1}
    [Return]    ${output}

Virsh Login
    [Arguments]    ${virshid}    ${user}=cirros    ${pwd}=cubswin:)    ${vm_prompt}=$
    Write Commands Until Expected Prompt    virsh console ${virshid}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    30
    Write Commands Until Expected Prompt    ${user}    Password:    30
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30

Virsh Exit
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}

Get Vm Instance
    [Arguments]    ${vm_name}
    ${instance_name}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep OS-EXT-SRV-ATTR:instance_name | awk '{print$4}'    $    60
    log    ${instance_name}
    [Return]    ${instance_name}

Ping From Virsh Console
    [Arguments]    ${virshid}    ${dest_ip}    ${connection_id}    ${string_tobe_verified}    ${user}=cirros    ${pwd}=cubswin:)
    ...    ${vm_prompt}=$
    Switch Connection    ${connection_id}
    Write Commands Until Expected Prompt    virsh console ${virshid}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    30
    Write Commands Until Expected Prompt    ${user}    Password:    30
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30
    ${output}=    Write Commands Until Expected Prompt    ping -c 5 ${dest_ip}    ${vm_prompt}
    Log    ${output}
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}
    ${pwd_output}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd_output}
    Should Contain    ${output}    ${string_tobe_verified}

Spawn Vm
    [Arguments]    ${net_name}    ${vm_name}    ${image_name}    ${host_name}    ${flavor_name}    ${additional_args}=${EMPTY}
    [Documentation]    This keyword spawns the vm on DPN.
    log    ${vm_name},${net_name}
    ${vm_spawn}    Write Commands Until Expected Prompt    nova boot --flavor ${flavor_name} --image ${image_name} --availability-zone nova:${host_name} --nic net-name=${net_name} ${vm_name} \ ${additional_args}    $    420
    log    ${vm_spawn}
    should contain    ${vm_spawn}    ${vm_name}
    Wait Until Keyword Succeeds    120 sec    10 sec    Verify Vm Creation    ${vm_name}

Get Vm Ipv6 Addr
    [Arguments]    ${vm_name}    ${network_name}
    [Documentation]    This Keyword gets the IPV6 address of the VM which is assigned to it dynamically when spawned.
    ${op}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    30
    log    ${op}
    ${m}=    Get Regexp Matches    ${op}    ${network_name}=(\.\*)    1
    log    ${m}
    ${elem1}    Get From List    ${m}    0
    log    ${elem1}
    ${ip1}    Get Substring    ${elem1}    \    -2
    log    ${ip1}
    ${ip}=    Strip String    ${ip1}
    log    ${ip}
    [Return]    ${ip}

Extract Mac
    [Arguments]    ${op}
    [Documentation]    This Keyword extracts the mac of the VM.
    ${m}    Get Regexp Matches    ${op}    HWaddr \[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]\
    log    ${m}
    ${x}    Get From List    ${m}    0
    log    ${x}
    ${mac}=    Get Substring    ${x}    -17
    log    ${mac}
    [Return]    ${mac}

Table 0 Check
    [Arguments]    ${br_name}    ${conn_id}    ${port}
    [Documentation]    This Keyword Checks the table 0 entry for every VM spawned.
    Switch Connection    ${conn_id}
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0 | grep in_port=${port}
    log    ${cmd}
    Should Contain    ${cmd}    in_port=${port}
    ${metadatamatch}    Get Regexp Matches    ${cmd}    :0x(\.\*)/    1
    ${metavalue}    Get From List    ${metadatamatch}    0
    log    ${metavalue}
    [Return]    ${metavalue}

Extract Port
    [Arguments]    ${op}
    [Documentation]    This Keyword extarcts the port numbers to which the VM is attached.
    ${m}    Get Regexp Matches    ${op}    ([0-9]+)\.\*: addr    1
    log    ${m}
    ${port}    Get From List    ${m}    0
    log    ${port}
    [Return]    ${port}

Create Invalid Subnet
    [Arguments]    ${network}    ${invalid_subnet}
    [Documentation]    This Keyword creates a invalid subnet to test the negative scenario.
    ${command}    Set Variable    neutron subnet-create ${network} 2001:db8:1234::/21 --name ${invalid_subnet} --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    ${subnet}=    Write Commands Until Expected Prompt    ${command}    $    30
    log    ${subnet}
    log    ${command}
    Should Contain    ${subnet}    Invalid input for operation: Invalid CIDR

Devstack Login
    [Arguments]    ${ip}    ${username}    ${password}    ${devstack_path}
    [Documentation]    This Keyword logs into the devstack on different OVS.
    ${dev_stack_conn_id}    Open Connection    ${ip}
    set suite variable    ${dev_stack_conn_id}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${devstack_path}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

Get Port Number
    [Arguments]    ${br_name}    ${pid}
    [Documentation]    This Keyword gets the port number specific to the VM.
    ${num}    Write Commands Until Expected Prompt    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pid} |awk '{print$1}'    $    30
    log    ${num}
    @{portNum}    Get Regexp Matches    ${num}    [0-9]+
    log    ${portNum}
    ${port_number}    Set Variable    ${portNum[0]}
    log    ${port_number}
    [Return]    ${port_number}

Extract Linklocal Addr
    [Arguments]    ${ifconfigoutput}
    [Documentation]    This keyword extracts the Link local address of the VMs
    ${output1}    Get Lines Containing String    ${ifconfigoutput}    Scope:Link
    ${linklocaliplist}    Get Regexp Matches    ${output1}    [0-9a-f]+::[0-9a-f]+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+
    ${link_addr}    Get From List    ${linklocaliplist}    0
    [Return]    ${link_addr}

Table Check
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    This keyword checks the parameters of a specific table number passed as an input argument.
    Switch Connection    ${connection_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

Get Hostname
    [Arguments]    ${conn_id}
    [Documentation]    This keyword gets the hostname of a particular host it logs into.
    Switch Connection    ${conn_id}
    ${hostname}    Write Commands Until Expected Prompt    hostname    $    30
    @{host}    Split String    ${hostname}    \r\n
    log    ${host}
    ${h}    get from list    ${host}    0
    [Return]    ${h}

Table Check With Negative Scenario
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    This keyword validates the parameters which should not be there in a specific table.
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Not Contain    ${cmd}    ${elem}

Get Security Group Id
    [Arguments]    ${sg}
    [Documentation]    This keyword gets the security group Id and returns the id.
    Log    >>>Extract the SG for admin project>>>
    ${cmd}    Write Commands Until Expected Prompt    neutron net-show ${networks[0]} | grep tenant_id | awk '{print$4}'    $    30
    log    ${cmd}
    ${templ1}    Split To Lines    ${cmd}
    ${str1}    Get From List    ${templ1}    0
    ${tenantid}    Strip String    ${str1}
    ${op}    Write Commands Until Expected Prompt    neutron security-group-list | grep ${sg} | awk '{print$2}'    $    30
    log    ${op}
    ${templ1}    Split To Lines    ${op}
    ${str1}    Get From List    ${templ1}    0
    ${id}    Strip String    ${str1}
    [Return]    ${id}

Get Port Id
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    This keyword returns the port id for the port passed as input.
    Switch Connection    ${conn_id}
    ${mac_lower}=    Convert To Lowercase    ${mac}
    ${port_id_command}    Write Commands Until Expected Prompt    neutron port-list | grep '${mac_lower}' | awk '{print$2}'    $    30
    @{port_array}    Split String    ${port_id_command}    -
    log    ${port_array}
    ${first_set}    get from list    ${port_array}    0
    ${second_set}    get from list    ${port_array}    1
    ${sub_str}    Get Substring    ${second_set}    0    2
    log    ${sub_str}
    ${id}    catenate    ${first_set}-${sub_str}
    log    ${id}
    [Return]    ${id}

Get Neutron Port
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    This keyword gets the neutron port specific to the vm.
    Switch Connection    ${conn_id}
    ${mac_lower}=    Convert To Lowercase    ${mac}
    ${op}    Write Commands Until Expected Prompt    neutron port-list | grep '${mac_lower}' | awk '{print$2}'    $    30
    log    ${op}
    ${templ1}    Split To Lines    ${op}
    ${str1}=    Get From List    ${templ1}    0
    ${id}=    Strip String    ${str1}
    [Return]    ${id}

Data Store Validation
    [Arguments]    ${port_id}    ${different_remote_group}=no    ${remote_group_id}=${EMPTY}
    [Documentation]    This keyword checks the config data store for security group, remote prefix for different ports.
    ${op}    Write Commands Until Expected Prompt    neutron port-show ${port_id} | grep security_groups | awk '{print$4}'    $    30
    log    ${op}
    ${templ1}    Split To Lines    ${op}
    ${str1}    Get From List    ${templ1}    0
    ${sg_id}    Strip String    ${str1}
    ${remote_id}    Set Variable If    '${different_remote_group}'=='yes'    ${remote_group_id}    ${sg_id}
    ${json}    Get Data From URI    session    ${CONFIG_API}/neutron:neutron/security-rules/
    ${object}    Evaluate    json.loads('''${json}''')    json
    log    ${object}
    ${obj1}    Set Variable    ${object["security-rules"]["security-rule"]}
    log    ${obj1}
    : FOR    ${i}    IN    @{obj1}
    \    log    ${i["uuid"]}
    \    log    ${i}
    \    Run Keyword If    '${i["direction"]}'=='neutron-constants:direction-ingress' and '${i["security-group-id"]}'=='${sg_id}'    Should Be Equal    ${remote_id}    ${i["remote-group-id"]}

Get Rule Id List
    [Arguments]    ${sg}
    [Documentation]    This keyword gets the list of rule UUIds for a specific Security group passed as input.
    ${op}    Write Commands Until Expected Prompt    neutron security-group-rule-list | grep ${sg} | awk '{print$2}'    $    30
    log    ${op}
    ${templ1}    Split To Lines    ${op}
    ${rule_list}    Get Slice From List    ${templ1}    \    -1
    [Return]    ${rule_list}

Get Rule Id List With Remote
    [Arguments]    ${sg}    ${remote_sg}
    [Documentation]    This keyword returns the list of rules uuids for a specific Security group and for a specific remote security group.
    ${var}    Set Variable If    '${remote_sg}'=='${default}'    '${remote_sg} group'    ${remote_sg}
    ${op}    Write Commands Until Expected Prompt    neutron security-group-list | grep ${sg} | grep ${var} | awk '{print$2}'    $    30
    log    ${op}
    ${templ1}    Split To Lines    ${op}
    ${rule_list}    Get Slice From List    ${templ1}    \    -1

Check Remote Prefix
    [Arguments]    ${rule_list}    ${remoteprefix}
    [Documentation]    This keyword checks the remote prefix for a rule list.
    @{array}    Create List    @{remoteprefix}
    : FOR    ${rule_id}    IN    @{rule_list}
    \    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-rules/security-rule/${rule_id}    ${array}

Get Dpn Ids
    [Arguments]    ${connection_id}    ${br_name}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Switch connection    ${connection_id}
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${br_name} | head -1 | awk -F "dpid:" '{ print $2 }'
    log    ${output1}
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    log    ${Dpn_id}
    [Return]    ${Dpn_id}

Set Json
    [Arguments]    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}    ${subnet}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${netvirt_config_dir}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id": 101    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id": 102    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${ip1}"
    ${body}    replace string    ${body}    "ip-address": "3.3.3.3"    "ip-address": "${ip2}"
    ${body}    replace string    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Create Vteps
    [Arguments]    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${netvirt_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${ip1}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    Set Json    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}    ${subnet}
    log    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

Get ITM
    [Arguments]    ${Itm_Created}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${ip1}    ${Dpn_id_2}
    ...    ${ip2}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${Itm_Created},${subnet}, ${vlan}, ${Dpn_id_1},${ip1}, ${Dpn_id_2}, ${ip2}
    @{Itm-no-vlan}    Create List    ${Itm_Created}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${ip1}
    ...    ${Dpn_id_2}    ${ip2}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${Itm_Created}    ${Itm-no-vlan}

Create ITM Tunnel
    [Documentation]    This keyword creates a new ITM tunnel between 2 OVS.
    Remove All Elements If Exist    ${CONFIG_API}/itm:transport-zones/transport-zone/${Itm_Created}
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge_names[0]}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-br ${Bridge_names[0]} -- set bridge ${Bridge_names[0]} \ datapath_type=netdev    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-port ${Bridge_names[0]} dpdk0 -- set Interface dpdk0 type=dpdk    $    10
    Comment    Write Commands Until Expected Prompt    sudo ovs-vsctl add-port ${Bridge_names[0]} eth2    $    10
    Write Commands Until Expected Prompt    sudo ifconfig ${Bridge_names[0]} \ ${dpip[0]}/24 up    $    10
    Switch Connection    ${conn_id_2}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge_names[1]}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-br ${Bridge_names[1]} -- set bridge ${Bridge_names[1]} \ datapath_type=netdev    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-port ${Bridge_names[1]} dpdk0 -- set Interface dpdk0 type=dpdk    $    10
    Comment    Write Commands Until Expected Prompt    sudo ovs-vsctl add-port ${Bridge_names[1]} eth2    $    10
    Write Commands Until Expected Prompt    sudo ifconfig ${Bridge_names[1]} \ ${dpip[1]}/24 up    $    10
    ${Dpn_id_1}    Get Dpn Ids    ${conn_id_1}    ${Br_Name}
    ${Dpn_id_2}    Get Dpn Ids    ${conn_id_2}    ${Br_Name}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}    Set Variable    0.0.0.0
    ${ip1}    Set Variable    ${dpip[0]}
    ${ip2}    Set Variable    ${dpip[1]}
    Create Vteps    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${Itm_Created}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${ip1}    ${Dpn_id_2}    ${ip2}

Create Flavor
    [Arguments]    ${flavor_name}
    [Documentation]    This keyword creates a flavor.
    ${flavour_create}    Write Commands Until Expected Prompt    nova flavor-create ${flavor_name} 101 2048 6 2    $    30
    ${memory_allocate}    Write Commands Until Expected Prompt    nova flavor-key ${flavor_name} set hw:mem_page_size=1048576    $    30

Delete Topology
    [Documentation]    This keyword deletes the basic topology created at the beginning of the suite.
    Delete Vm Instance    ${VM_list[0]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[0]}    ${mac1}    ${conn_id_1}
    Delete Vm Instance    ${VM_list[1]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[1]}    ${mac2}    ${conn_id_1}
    Delete Vm Instance    ${VM_list[4]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[4]}    ${mac5}    ${conn_id_2}
    Remove Interface    ${Routers[0]}    ${Subnets[0]}
    Remove Interface    ${Routers[0]}    ${Subnets[1]}
    Delete Subnet    ${Subnets[0]}
    Delete Subnet    ${Subnets[1]}
    Delete Router    ${Routers[0]}
    Delete Network    ${Networks[0]}

Verify Vm Creation
    [Arguments]    ${vm_name}
    [Documentation]    This keyword verifies the VM creation.
    ${novaverify}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    60
    Should Contain    ${novaverify}    ACTIVE
    Should Contain    ${novaverify}    Running

Get Ip List Specific To Prefixes
    [Arguments]    ${vm_name}    ${network_name}    ${prefix1}    ${prefix2}
    [Documentation]    This keyword returns the list of IPs specific to the list of subnets passed.
    ${op}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    20
    Should Contain    ${op}    ${prefix1}
    Should Contain    ${op}    ${prefix2}
    ${match}    Get Regexp Matches    ${op}    ${network_name}=(\.\*)    1
    log    ${match}
    @{temp_list}    Split String    ${match[0]}    ,
    log    ${temp_list}
    @{ip_list}    Create List
    : FOR    ${i}    IN    @{temp_list}
    \    log    ${i}
    \    ${check}    Check Substring    ${i}    ${prefix1}
    \    ${ip}    Remove String    ${i}    |
    \    ${ip}    Strip String    ${ip}
    \    Run Keyword If    '${check}'=='True'    Append To List    ${ip_list}    ${ip}
    \    log    ${ip_list}
    \    ${check}    Check Substring    ${i}    ${prefix2}
    \    ${ip}    Remove String    ${i}    |
    \    ${ip}    Strip String    ${ip}
    \    Run Keyword If    '${check}'=='True'    Append To List    ${ip_list}    ${ip}
    \    log    ${ip_list}
    log    ${ip_list}
    [Return]    ${ip_list}

Check Substring
    [Arguments]    ${s1}    ${s2}
    [Documentation]    This keyword checks whether S2 is a substring of S1.
    log    ${s1}
    log    ${s2}
    ${match}    Get Regexp Matches    ${s1}    (${s2})    1
    log    ${match}
    ${len}    Get Length    ${match}
    ${return}    Set Variable If    ${len}>0    True    False
    [Return]    ${return}

Get Subnet Specific Ip
    [Arguments]    ${ip_list}    ${prefix}
    [Documentation]    This keyword returns an IP specific to a subnet passed.
    ${prefix}    Remove String    ${prefix}    ::
    ${check}    Check Substring    ${ip_list[0]}    ${prefix}
    ${ip}    Set Variable If    '${check}'=='True'    ${ip_list[0]}    ${ip_list[1]}
    [Return]    ${ip}

Validate Router Config Datastore
    [Arguments]    ${prefix_list}
    [Documentation]    This keyword validates prefix in the config datastore for the router interfaces.
    ${json}    Get Data From URI    session    ${CONFIG_API}/l3vpn:vpn-interfaces/
    ${object}    Evaluate    json.loads('''${json}''')    json
    log    ${object}
    ${obj1}    Set Variable    ${object["vpn-interfaces"]["vpn-interface"]}
    log    ${obj1}
    ${var}    Set Variable    1
    : FOR    ${i}    IN    @{obj1}
    \    ${var}    Set Variable If    '${i["is-router-interface"]}'=='True'    ${i["odl-l3vpn:adjacency"]}    ${var}
    log    ${var}
    ${adj}    Evaluate    json.dumps(${var})    json
    log    ${adj}
    : FOR    ${prefix}    IN    @{prefix_list}
    \    Should Contain    ${adj}    ${prefix}

Verify Vm Deletion
    [Arguments]    ${vm}    ${mac}    ${conn_id}
    [Documentation]    This keyword checks whether the VM passed as an argument is deleted or not.
    ${vm_list}    List Nova VMs
    Should Not Contain    ${vm_list}    ${vm}
    Switch Connection    ${conn_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${Br_Name} | grep table=40
    Log    ${cmd}
    ${lower_mac}    Convert To Lowercase    ${mac}
    Should Not Contain    ${cmd}    ${lower_mac}

Create SG Rule IPV6
    [Arguments]    ${direction}    ${protocol}    ${min_port}    ${max_port}    ${ether_type}    ${sg_name}
    ...    ${remote_param}    ${remote_type}=prefix
    [Documentation]    This keyword creates a rules for Security group.
    ${cmd}    Set Variable If    '${remote_type}'=='SG'    neutron security-group-rule-create --direction ${direction} --ethertype ${ether_type} --protocol ${protocol} --port-range-min ${min_port} --port-range-max ${max_port} --remote-group-id ${remote_param} ${sg_name}    neutron security-group-rule-create --direction ${direction} --ethertype ${ether_type} --protocol ${protocol} --port-range-min ${min_port} --port-range-max ${max_port} --remote-ip-prefix ${remote_param} ${sg_name}
    ${output}=    Write Commands Until Expected Prompt    ${cmd}    $    10
    log    ${output}

Fetch Topology Details
    [Documentation]    This keyword fetches the basic topology details.
    Log    >>>Just for the run purpose>>>
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[0]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${vm1ip}    Get Subnet Specific Ip    ${ip_list1}    ${Prefixes[0]}
    Set Global Variable    ${vm1ip}
    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm1ip}    ${conn_id_1}    ${Networks[0]}
    ${output1}    Wait Until Keyword Succeeds    300 sec    20 sec    Execute Command On VM    ${conn_id_1}    ${Networks[0]}
    ...    ${vm1ip}    ifconfig eth0
    log    ${output1}
    ${linkaddr1}    extract linklocal addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${mac1}    Extract Mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    Get Port Number    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    Log    >>>Details of vm2>>>
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${vm2ip}    Get Subnet Specific Ip    ${ip_list2}    ${Prefixes[0]}
    Set Global Variable    ${vm2ip}
    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm2ip}    ${conn_id_1}    ${Networks[0]}
    ${output2}    Wait Until Keyword Succeeds    300 sec    20 sec    Execute Command On VM    ${conn_id_1}    ${Networks[0]}
    ...    ${vm2ip}    ifconfig eth0
    Set Global Variable    ${ip_list2}
    log    ${output2}
    ${linkaddr2}    extract linklocal addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${mac2}    Extract Mac    ${output2}
    ${port_id2}    get port id    ${mac2}    ${conn_id_1}
    ${port2}    Get Port Number    ${Br_Name}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output1}    ${prefixstr1}
    Should Contain    ${output1}    ${prefixstr2}
    Should Contain    ${output2}    ${prefixstr1}
    Should Contain    ${output2}    ${prefixstr2}
    Set Global Variable    ${ip_list1[0]}
    Set Global Variable    ${ip_list1[1]}
    Set Global Variable    ${ip_list2[0]}
    Set Global Variable    ${ip_list2[1]}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    Should Contain    ${output2}    ${ip_list2[0]}
    Should Contain    ${output2}    ${ip_list2[1]}
    Comment    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${image}    ${SG_name[4]}    ${hostname2}
    Log    >>>Details of VM5>>>
    ${ip_list5}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    ${vm5ip}    Get Subnet Specific Ip    ${ip_list5}    ${Prefixes[0]}
    Set Global Variable    ${vm5ip}
    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm5ip}    ${conn_id_1}    ${Networks[0]}
    ${output5}    Wait Until Keyword Succeeds    300 sec    20 sec    Execute Command On VM    ${conn_id_1}    ${Networks[0]}
    ...    ${vm5ip}    ifconfig eth0
    log    ${output5}
    ${linkaddr5}    extract linklocal addr    ${output5}
    Set Global Variable    ${linkaddr5}
    ${mac5}    Extract Mac    ${output5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_1}
    ${port5}    Get Port Number    ${Br_Name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_2}
    ${port5}    Get Port Number    ${Br_Name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    Set Global Variable    ${metadata1}
    ${metadata5}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
    ...    ${port5}
    Set Global Variable    ${metadata5}

fetch all info
    Log    >>>Adding part of create topology for the global variables, just for the debugging purpose>>>
    Switch Connection    ${conn_id_1}
    ${hostname1}    get hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    get hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${virshid1}    Get Vm Instance    ${VM_list[0]}
    ${virshid2}    Get Vm Instance    ${VM_list[1]}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid1}
    Set Global Variable    ${virshid2}
    Set Global Variable    ${virshid3}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[0]}    ${Networks[0]}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[1]}    ${Networks[0]}
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[2]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    Set Global Variable    ${ip_list2}
    Set Global Variable    ${ip_list3}
    ${output1}    Virsh Output    ${virshid1}    ifconfig eth0
    log    ${output1}
    ${linkaddr1}    extract linklocal addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${output2}    Virsh Output    ${virshid2}    ifconfig eth0
    log    ${output2}
    ${linkaddr2}    extract linklocal addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${output3}    Virsh Output    ${virshid3}    ifconfig eth0
    log    ${output3}
    ${linkaddr3}    extract linklocal addr    ${output3}
    Set Global Variable    ${linkaddr3}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output1}    ${prefixstr1}
    Should Contain    ${output1}    ${prefixstr2}
    Should Contain    ${output2}    ${prefixstr1}
    Should Contain    ${output2}    ${prefixstr2}
    Set Global Variable    ${ip_list1[0]}
    Set Global Variable    ${ip_list1[1]}
    Set Global Variable    ${ip_list2[0]}
    Set Global Variable    ${ip_list2[1]}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    Should Contain    ${output2}    ${ip_list2[0]}
    Should Contain    ${output2}    ${ip_list2[1]}
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    ${mac1}    Extract Mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    Get Port Number    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    ${mac2}    Extract Mac    ${output2}
    ${port_id2}    get port id    ${mac2}    ${conn_id_1}
    ${port2}    Get Port Number    ${Br_Name}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Comment    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${image}    ${SG_name[4]}    ${hostname2}
    ${virshid5}    Get Vm Instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${ip_list5}    Wait Until Keyword Succeeds    2 min    10 sec    Get IPV6 Ips    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    ${virshid4}    Get Vm Instance    ${VM_list[3]}
    Set Global Variable    ${virshid4}
    ${ip_list4}    Wait Until Keyword Succeeds    2 min    10 sec    Get IPV6 Ips    ${VM_list[3]}    ${Networks[0]}
    Set Global Variable    ${ip_list4}
    Switch Connection    ${conn_id_2}
    ${output5}    Virsh Output    ${virshid5}    ifconfig eth0
    log    ${output5}
    ${linkaddr5}    extract linklocal addr    ${output5}
    Set Global Variable    ${linkaddr5}
    Should Contain    ${output5}    ${ip_list5[0]}
    Should Contain    ${output5}    ${ip_list5[1]}
    ${mac5}    Extract Mac    ${output5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_2}
    ${port5}    Get Port Number    ${Br_Name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    ${output4}    Virsh Output    ${virshid4}    ifconfig eth0
    log    ${output4}
    ${linkaddr4}    extract linklocal addr    ${output4}
    Set Global Variable    ${linkaddr4}
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    ${mac4}    Extract Mac    ${output4}
    ${port_id4}    get port id    ${mac4}    ${conn_id_2}
    ${port4}    Get Port Number    ${Br_Name}    ${port_id4}
    Set Global Variable    ${mac4}
    log    ${port4}
    Set Global Variable    ${port4}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    Set Global Variable    ${metadata1}
    ${metadata2}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port2}
    Set Global Variable    ${metadata2}
    ${metadata3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    Set Global Variable    ${metadata3}
    ${metadata4}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
    ...    ${port4}
    Set Global Variable    ${metadata4}
    ${metadata5}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
    ...    ${port5}
    Set Global Variable    ${metadata5}

Get Network Id
    [Arguments]    ${conn_id}    ${network}
    [Documentation]    This keyword returns the network id for a network name passed.
    Switch Connection    ${conn_id}
    ${op}    Write Commands Until Expected Prompt    neutron net-list | grep ${network} | awk '{print$2}'    $    30
    ${splitted_op}    Split To Lines    ${op}
    ${net_id}    Get From List    ${splitted_op}    0
    [Return]    ${net_id}

Create Topology
    [Arguments]    ${image}
    [Documentation]    Creates the required topology for the test cases to be run.
    log    >>>creating ITM tunnel
    Create ITM Tunnel
    Log    >>>> Creating Network <<<<
    Switch Connection    ${conn_id_1}
    Comment    Create Flavor    ${Flavor_Name}
    Create Network    ${Networks[0]}
    Create Subnet    ${Networks[0]}    ${Subnets[0]}    ${Prefixes[0]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Subnet    ${Networks[0]}    ${Subnets[1]}    ${Prefixes[1]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Router    ${Routers[0]}
    Add Router Interface    ${Routers[0]}    ${Subnets[0]}
    @{prefixlist}    Create List    ${Prefixes[0]}
    Wait Until Keyword Succeeds    60 sec    10 sec    Validate Router Config Datastore    ${prefixlist}
    Add Router Interface    ${Routers[0]}    ${Subnets[1]}
    @{prefixlist}    Create List    ${Prefixes[0]}    ${Prefixes[1]}
    Wait Until Keyword Succeeds    60 sec    10 sec    Validate Router Config Datastore    ${prefixlist}
    ${hostname1}    get hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    get hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[0]}    ${image}    ${hostname1}    ${Flavor_Name}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[1]}    ${image}    ${hostname1}    ${Flavor_Name}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${image}    ${hostname2}    ${Flavor_Name}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[0]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${vm1ip}    Get Subnet Specific Ip    ${ip_list1}    ${Prefixes[0]}
    Set Global Variable    ${vm1ip}
    Comment    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm1ip}    ${conn_id_1}
    ...    ${Networks[0]}
    ${virshid1}    Get Vm Instance    ${VM_list[0]}
    Set Global Variable    ${virshid1}
    ${output1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid1}
    ...    ifconfig eth0
    log    ${output1}
    ${linkaddr1}    extract linklocal addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${mac1}    Extract Mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    Get Port Number    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    Log    >>>Details of vm2>>>
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${vm2ip}    Get Subnet Specific Ip    ${ip_list2}    ${Prefixes[0]}
    Set Global Variable    ${vm2ip}
    Comment    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm2ip}    ${conn_id_1}
    ...    ${Networks[0]}
    ${virshid2}    Get Vm Instance    ${VM_list[1]}
    Set Global Variable    ${virshid2}
    ${output2}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid2}
    ...    ifconfig eth0
    Set Global Variable    ${ip_list2}
    log    ${output2}
    ${linkaddr2}    extract linklocal addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${mac2}    Extract Mac    ${output2}
    ${port_id2}    get port id    ${mac2}    ${conn_id_1}
    ${port2}    Get Port Number    ${Br_Name}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output1}    ${prefixstr1}
    Should Contain    ${output1}    ${prefixstr2}
    Should Contain    ${output2}    ${prefixstr1}
    Should Contain    ${output2}    ${prefixstr2}
    Set Global Variable    ${ip_list1[0]}
    Set Global Variable    ${ip_list1[1]}
    Set Global Variable    ${ip_list2[0]}
    Set Global Variable    ${ip_list2[1]}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    Should Contain    ${output2}    ${ip_list2[0]}
    Should Contain    ${output2}    ${ip_list2[1]}
    Comment    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${image}    ${SG_name[4]}    ${hostname2}
    Log    >>>Details of VM5>>>
    ${ip_list5}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    ${vm5ip}    Get Subnet Specific Ip    ${ip_list5}    ${Prefixes[0]}
    Set Global Variable    ${vm5ip}
    Comment    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm5ip}    ${conn_id_1}
    ...    ${Networks[0]}
    ${virshid5}    Get Vm Instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${output5}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid5}
    ...    ifconfig eth0
    log    ${output5}
    ${linkaddr5}    extract linklocal addr    ${output5}
    Set Global Variable    ${linkaddr5}
    ${mac5}    Extract Mac    ${output5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_2}
    ${port5}    Get Port Number    ${Br_Name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    Comment    Switch Connection    ${conn_id_1}

Ping
    [Arguments]    ${conn_id}    ${network}    ${vm_ip}    ${cmd}    ${string_tobe_verified}
    [Documentation]    This keyword executes the ping command logging into the VM.
    Switch Connection    ${conn_id}
    ${ping_output}    Wait Until Keyword Succeeds    30 sec    10 sec    Execute Command On VM    ${conn_id}    ${network}
    ...    ${vm_ip}    ${cmd}
    Log    ${ping_output}
    Should Contain    ${ping_output}    ${string_tobe_verified}

Execute Command On VM
    [Arguments]    ${conn_id}    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    This keyword executes the command passed to it on a VM.
    Switch Connection    ${conn_id}
    ${net_id}    get network id    ${conn_id}    ${net_name}
    Log    ${vm_ip}
    ${output}    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no \r    password:    90
    Log    ${output}
    ${output}    Write Commands Until Expected Prompt    ${password}    $    30
    Log    ${output}
    ${rcode}    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    $
    Write Commands Until Expected Prompt    exit    $    10
    [Teardown]
    [Return]    ${output}

Ping Check
    [Arguments]    ${ip_address}    ${conn_id}    ${network}    ${address_family}=ipv6
    [Documentation]    This keyword does the ping check for a specific VM to know whether VM is up before logging into it.
    ${netid}    get network id    ${conn_id}    ${network}
    ${cmd}    Set Variable If    '${address_family}'=='ipv6'    sudo ip netns exec qdhcp-${netid} ping6 -c 3 ${ip_address}    sudo ip netns exec qdhcp-${netid} ping -c 3 ${ip_address}
    ${output}    Write Commands Until Expected Prompt    ${cmd}    $
    Should Contain    ${output}    64 bytes
    Comment    Write_Bare_Ctrl_C

Vm Login
    [Arguments]    ${conn_id}    ${net_name}    ${vm_ip}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    This keyword does the VM login using namespace.
    Switch Connection    ${conn_id}
    ${net_id}    get network id    ${conn_id}    ${net_name}
    Log    ${vm_ip}
    ${output}    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no \r    password:    90
    Log    ${output}
    ${output}    Write Commands Until Expected Prompt    ${password}    $    30
    Log    ${output}
    ${rcode}    Run Keyword And Return Status    Check If Console Is VmInstance
    [Return]    ${output}

Vm Exit
    [Arguments]    ${conn_id}
    [Documentation]    This keyword exits the VM console.
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    exit    $    10

nova reboot
    [Arguments]    ${vm_name}
    ${output}    Write Commands Until Expected Prompt    nova reboot ${vm_name}    $    30
    Should Contain    ${output}    accepted
    Wait Until Keyword Succeeds    30 sec    10 sec    verify vm creation    ${vm_name}

check ip on vm
    [Arguments]    ${conn_id}    ${virshid}    ${cmd}    ${target_ip}
    ${output1}    Virsh Output    ${conn_id}    ${virshid}    ${cmd}
    log    ${output1}
    Should Contain    ${output1}    ${target_ip}

get both ip
    [Arguments]    ${vm_name}    ${network1}
    ${ip1_temp}=    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network1} | awk '{print$5}'    $    30
    log    ${ip1_temp}
    ${templ1}    Split To Lines    ${ip1_temp}
    ${str1}=    Get From List    ${templ1}    0
    ${str1}=    Remove String    ${str1}    ,
    ${ip1}=    Strip String    ${str1}
    log    ${ip1}
    ${ip2_temp}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network1} | awk '{print$6}'    $    30
    log    ${ip2_temp}
    ${templ2}    Split To Lines    ${ip2_temp}
    ${str2}=    Get From List    ${templ2}    0
    ${str2}=    Remove String    ${str2}    ,
    ${ip2}=    Strip String    ${str2}
    log    ${ip2}
    Should Not Contain    ${ip2}    |
    @{lst}    Create List    ${ip1}    ${ip2}
    [Return]    ${lst}

attach network to vm
    [Arguments]    ${conn_id}    ${network_name}    ${vm_name}
    ${netid}    get net id    ${network_name}    ${conn_id}
    Write Commands Until Expected Prompt    nova interface-attach --net-id \ \ ${netid} ${vm_name}    $    30

get network specific ip address
    [Arguments]    ${vm_name}    ${network}
    ${ip1_temp}=    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network} | awk '{print$5}'    $    30
    log    ${ip1_temp}
    ${templ1}    Split To Lines    ${ip1_temp}
    ${str1}=    Get From List    ${templ1}    0
    ${ip1}=    Strip String    ${str1}
    log    ${ip1}
    [Return]    ${ip1}

check ips on nova show
    [Arguments]    ${vm_name}    ${network1}    ${prefix1}    ${prefix2}
    ${op}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network1}    $    30
    log    ${op}
    ${prefix1} =    Remove String    ${prefix1}    ::
    ${prefix2} =    Remove String    ${prefix2}    ::
    log    ${prefix1}
    log    ${prefix2}
    Should Contain    ${op}    ${prefix1}
    Should Contain    ${op}    ${prefix2}

Set Vhost Configuration
    [Arguments]    ${hostname}    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${port_prefix}    ${vhostuser_socket}    ${vhostuser_socket_dir}    ${support_vhost_user}    ${vhostuser_ovs_plug}
    ...    ${host_addresses}    ${vhostuser_mode}
    Log    >>>> Get ovs uuid <<<<
    ${ovs_uuid}    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch . _uuid    \#    20
    ${templ1}    Split To Lines    ${ovs_uuid}
    ${str1}=    Get From List    ${templ1}    0
    ${ovs_uuid}=    Strip String    ${str1}
    Log    ${ovs_uuid}
    Log    >>>> Set odl_os_hostconfig_hostid <<<<
    Write Commands Until Expected Prompt    ovs-vsctl set Open_vSwitch ${ovs_uuid} external_ids:odl_os_hostconfig_hostid=${hostname}    \#    20
    ${odl_os_hostconfig_odl_l2}    Set Variable    ovs-vsctl set Open_vSwitch ${ovs_uuid} external_ids:odl_os_hostconfig_config_odl_l2="{${allowed_network_types},${bridge_mappings},${datapath_type},"supported_vnic_types":[{${vif_type},${vnic_type},${has_datapath_type_netdev},${port_prefix},${vhostuser_socket},${vhostuser_socket_dir},${support_vhost_user},${vhostuser_ovs_plug},${host_addresses},${vhostuser_mode}}]}"
    Write Commands Until Expected Prompt    ${odl_os_hostconfig_odl_l2}    \#    20
    Comment    Log    >>> Restart the switch <<<
    Comment    Write Commands Until Expected Prompt    sudo service openvswitch-switch restart    \#    20
    Log    >>> Get the external ids<<<<
    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch ${ovs_uuid} \ external_ids    \#    20

Set OVS Host Configuration
    [Arguments]    ${hostname}    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${support_vhost_user}    ${host_addresses}
    Log    >>>> Get ovs uuid <<<<
    ${ovs_uuid}    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch . _uuid    \#    20
    ${templ1}    Split To Lines    ${ovs_uuid}
    ${str1}=    Get From List    ${templ1}    0
    ${ovs_uuid}=    Strip String    ${str1}
    Log    ${ovs_uuid}
    ${ovs_uuid1}    Set Variable    \\"uuid\\":\\"${ovs_uuid}\\"
    Log    >>>> Set odl_os_hostconfig_hostid <<<<
    Write Commands Until Expected Prompt    ovs-vsctl set Open_vSwitch ${ovs_uuid} \ external_ids:odl_os_hostconfig_hostid=${hostname}    \#    20
    ${odl_os_hostconfig_odl_l2}    Set Variable    ovs-vsctl set Open_vSwitch ${ovs_uuid} external_ids:odl_os_hostconfig_config_odl_l2="{${allowed_network_types},${bridge_mappings},${datapath_type},"supported_vnic_types":[{${vif_type},${vnic_type},${has_datapath_type_netdev},${ovs_uuid1},${support_vhost_user},${host_addresses}}]}"
    Write Commands Until Expected Prompt    ${odl_os_hostconfig_odl_l2}    \#    20
    Comment    Log    >>> Restart the switch <<<
    Comment    Write Commands Until Expected Prompt    sudo service openvswitch-switch restart    \#    20
    Log    >>> Get the external ids<<<<
    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch ${ovs_uuid} \ external_ids    \#    20

Testcase Cleanup
    [Documentation]    Cleanup
    Log \ \ \    >>>Delete Vms with IPv4 address>>>
    \ \ \ Switch Connection \ \ \    ${conn_id_1}
    Delete Vm Instance    ${vm1ip}
    Delete Vm Instance    ${vm2ip}
    Delete Vm Instance    ${vm3ip}
    Delete SubNet    ${V4subnet_Names[0]}
    Remove Interface    ${Routers[0]}    ${V4subnet_Names[0]}
    Delete SubNet    ${V4subnet_Names[1]}
    Remove Interface    ${Routers[0]}    ${V4subnet_Names[1]}
    Delete Router    ${Routers[0]}
    Delete Network    ${Networks[0]}
    Delete Network    ${Networks[1]}
