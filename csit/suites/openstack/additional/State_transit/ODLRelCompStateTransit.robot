*** Settings ***
Documentation     Test suite to verify ODL State Transmit. The state transit component number is mentioned in the braces.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/DataModels.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/OpenStackOperations_legacy.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    sg-connectivity
@{NETWORKS_NAME}    l2_network_1    l2_network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_GRP_NAME}    NET1-VM
@{NET_2_VM_GRP_NAME}    NET2-VM
@{NET_1_VM_INSTANCES_MAX}    NET1-VM-1    NET1-VM-2
@{NET_1_VM_INSTANCES}    NET1-VM
@{NET_2_VM_INSTANCES}    NET2-VM
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    2001:db8:cafe:e::/64    100.64.2.0/24    192.168.90.0/24
@{port}           1111    2222    234    1234    6    17    50
...               51    132    136
@{VM_INSTANCES_FLOATING}    VmInstanceFloating1    VmInstanceFloating2
${external_gateway}    192.165.1.250
#${external_gateway}    101.0.0.250
${external_subnet}    101.0.0.0/24
${external_subnet_allocation_pool}    start=101.0.0.4,end=101.0.0.248
${external_net_name}    external-net
${external_subnet_name}    external-subnet
${PROVIDER}       flat1
@{ROUTERS}        router_1    router_2
@{networkName}    "name":"l2_network_1"
@{router_name}    "name":"router_1"

*** Test Cases ***
Create virtual LAN(ST1)
    [Documentation]    Create virtual LAN.Verify LAN updated in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    @{NETWORKS_NAME}[0]
    Should contain    ${Output3}    30.0.0.2
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(ST1)
    [Documentation]    Verify created network is listed.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(ST1)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(ST1)
    [Documentation]    Update virtual LAN name and verify LAN name is updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(ST1)
    [Documentation]    Delete virtual LAN. Verify LAN is deleted in dumpflows and config datastore.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should Not Contain    ${output}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    @{NETWORKS_NAME}[0]

Check that you can create VM.(ST1)
    [Documentation]    Create Network and VM's. Verify VM's are updated in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[4]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-1
    Should contain    ${output}    NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-2
    Should contain    ${output}    NET1-VM-2
    ${VM_list}=    Create List    ${NET1_VM_IPS}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${NET1_VM_IPS}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NET1_VM_IPS}[0]
    Should contain    ${Output2}    @{NET1_VM_IPS}[1]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    @{NET1_VM_IPS}[0]
    Should contain    ${Output3}    @{NET1_VM_IPS}[1]
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can list the VMs.(ST1)
    [Documentation]    Verify created VM's are listed.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should contain    ${output}    NET1-VM-1
    Should contain    ${output}    NET1-VM-2

Check that you can refer VM.(ST1)
    [Documentation]    Check that you can refer VM.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-1
    Should contain    ${output}    NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-2
    Should contain    ${output}    NET1-VM-2

Check that you can update the VM.(ST1)
    [Documentation]    Update VM's name and verify updated VM names.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server set --name VM_1 NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server set --name VM_2 NET1-VM-2
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show VM_1
    Should contain    ${output}    VM_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show VM_2
    Should contain    ${output}    VM_2

Check that you can delete the VM.(ST1)
    [Documentation]    Delete VM's. Verify VM's deleted in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Delete Vm Instance    VM_1
    Delete Vm Instance    VM_2
    Sleep    120s
    Delete SubNet    l2_subnet_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not Contain    ${output}    VM_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not Contain    ${output}    VM_2
    ${config}=    Create List    @{NETWORKS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete SecurityGroup    ${SECURITY_GROUP}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${Output1}    @{NET1_VM_IPS}[1]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${Output2}    @{NET1_VM_IPS}[1]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${Output3}    @{NET1_VM_IPS}[1]
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Router operations - Create router.(ST1)
    [Documentation]    Create router and Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router ID    @{ROUTERS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/router/${router_id}    ${router_name}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Router operations - Refer list of routers.(ST1)
    [Documentation]    Verify created router is listed.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Router operations - Refer router.(ST1)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Router operations - Delete the router.(ST1)
    [Documentation]    Delete router. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    router_1

Check that you can connect to external network(ST1)
    [Documentation]    Create external network and add router interfaces. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=${PROVIDER}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[3]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1
    #${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router set --external-gateway router_1
    #Log    ${OutputList}
    #Should Not Be True    ${rc}

Check that you can disconnect to external network(ST1)
    [Documentation]    Remove Interfaces from external network and Verify in dumpflows.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Router    router_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can connect to internal network.(ST1)
    [Documentation]    Create internal network and attach interfaces. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net1_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${net2_id}=    Get Net Id    @{NETWORKS_NAME}[1]
    Create Router    router_1
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    min=1    max=1    image=cirros    flavor=cirros
    ...    sg=@{sg_list}[0]
    Create Vm Instances    l2_network_2    ${NET_2_VM_GRP_NAME}    min=1    max=1    image=cirros    flavor=cirros
    ...    sg=@{sg_list}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[1]
    Should contain    ${output}    @{NETWORKS_NAME}[1]
    #${output}=    List Ports
    #Should contain    ${output}    30.0.0.1
    #Should contain    ${output}    40.0.0.1
    #${config}=    Create List    30.0.0.1    40.0.0.1
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/    ${config}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    ${net1_id}
    Should contain    ${Output2}    ${net2_id}
    #Should contain    ${Output2}    30.0.0.1
    #Should contain    ${Output2}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    ${net1_id}
    Should contain    ${Output3}    ${net2_id}
    #Should contain    ${Output3}    30.0.0.1
    #Should contain    ${Output3}    40.0.0.1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can disconnect from internal network.(ST1)
    [Documentation]    Remove interfaces form networks. Verify in dumpflows and config datastore.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net1_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${net2_id}=    Get Net Id    @{NETWORKS_NAME}[1]
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Remove Interface    router_1    ${interface}
    Delete Router    router_1
    Delete Vm Instance    @{NET_1_VM_GRP_NAME}[0]
    Delete Vm Instance    @{NET_2_VM_GRP_NAME}[0]
    ${output}=    List Ports
    #Should Not Contain    ${output}    30.0.0.1
    #Should Not Contain    ${output}    40.0.0.1
    Delete SubNet    l2_subnet_1
    Delete SubNet    l2_subnet_2
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
    Delete SecurityGroup    @{sg_list}[0]
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    ${net1_id}
    #Should Not Contain    ${Output1}    30.0.0.1
    #Should Not Contain    ${Output1}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    ${net1_id}
    #Should Not Contain    ${Output2}    30.0.0.1
    #Should Not Contain    ${Output2}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    ${net1_id}
    #Should Not Contain    ${Output3}    30.0.0.1
    #Should Not Contain    ${Output3}    40.0.0.1

Check that you can assign FIP to VM.(ST1)
    [Documentation]    Create internal and external network assocaiate floating ip. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    #Delete All Security Group Rules    @{sg_list}[0]
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Create Vm Instances    network_1    ${VM_INSTANCES_FLOATING}    sg=@{sg_list}[0]    image=cirros    flavor=cirros
    : FOR    ${vm}    IN    @{VM_INSTANCES_FLOATING}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_FLOATING}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VM_INSTANCES_FLOATING}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM_INSTANCES_FLOATING}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Create Network    ${external_net_name}    --provider-network-type flat --provider-physical-network ${PROVIDER}
    Update Network    ${external_net_name}    --external
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Gateway    ${ROUTERS[0]}    ${external_net_name}
    ${VM_FLOATING_IPS}    OpenStackOperations.Create And Associate Floating IPs    ${external_net_name}    @{VM_INSTANCES_FLOATING}
    ${floating_list} =    Create List    @{VM_FLOATING_IPS}[0]
    Wait Until Keyword Succeeds    20s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/    ${floating_list}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{VM_FLOATING_IPS}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    @{VM_FLOATING_IPS}[0]
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Set Suite Variable    ${VM_FLOATING_IPS}
    ${rc}    ${output}=    Run And Return Rc And Output    ping -c 15 @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should contain    ${output}    64 bytes
    #OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]

Check that you can delete FIP from VM.(ST1)
    [Documentation]    Delete associated flowating ip and Verify in config datastore.
    ${floating_list} =    Create List    @{VM_FLOATING_IPS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/    ${floating_list}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove floating ip @{VM_INSTANCES_FLOATING}[0] @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Set Suite Variable    ${VM_FLOATING_IPS}
    ${rc}    ${output}=    Run And Return Rc And Output    ping -c 5 @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip delete @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Be True    ${rc}
    #OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_FLOATING}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS[0]}
    Delete SecurityGroup    @{sg_list}[0]
    Delete SubNet    l2_subnet_1
    #Delete SubNet    ${external_subnet_name}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{VM_FLOATING_IPS}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{VM_FLOATING_IPS}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    @{VM_FLOATING_IPS}[0]
    Delete Network    l2_network_1
    Delete Network    ${external_net_name}

Security group - Register security group.(ST1)
    [Documentation]    Register security group adn Verify in config datastore.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list --project admin
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list --project admin -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    ${sg_id}=    Create List    @{sgs}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-rules    ${sg_id}
    : FOR    ${sg}    IN    @{sgs}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    \    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should contain    ${Output1}    ${sg}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    \    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should contain    ${Output2}    ${sg}

Security group - Delete the security group.(ST1)
    [Documentation]    Delete the security group and Verify in config datastore.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list --project admin
    Log    ${output}
    Should Not Contain    ${output}    ${SECURITY_GROUP}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}

Security rule - Register security rule.(ST1)
    [Documentation]    Register security rule and Verify in config datastore.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1
    Sleep    10s
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack security group rule list ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group rule list -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    ${sg_id}=    Create List    @{sgs}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-rules    ${sg_id}
    : FOR    ${sg}    IN    @{sgs}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    \    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should Contain    ${Output1}    ${sg}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    \    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should Contain    ${Output2}    ${sg}

Security rule - Delete the security rule.(ST1)
    [Documentation]    Delete the security rule and verify in config datastore.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}
    Delete SecurityGroup    ${SECURITY_GROUP}

Permit communication(ST1)
    [Documentation]    Create network and VM. Add security rule and permit communication from DHCP.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}

Deny communication(ST1)
    [Documentation]    Add security rule to VM and Deny communication.
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    TCP connection timed out    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SubNet    l2_subnet_1
    Delete Network    @{NETWORKS_NAME}[0]

Kill ODL1
    [Documentation]    Kill on of the ODLs.
    ${output}=    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    Log    ${output}
    ${Output}=    Write Commands Until Prompt    ifconfig
    ${Output}=    Write Commands Until Prompt    sudo systemctl stop opendaylight
    ${Output}=    Write Commands Until Prompt    sudo systemctl status opendaylight
    Should contain    ${Output}    inactive

Create virtual LAN(No.2)
    [Documentation]    Create virtual LAN.Verify LAN updated in dumpflows and config datastore
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(No.2)
    [Documentation]    Verify created network is listed.
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.2)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.2)
    [Documentation]    Update virtual LAN name and verify LAN name is updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.2)
    [Documentation]    Delete virtual LAN. Verify LAN is deleted in dumpflows and config datastore.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should Not Contain    ${output}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{NETWORKS_NAME}[0]

Check that you can create VM.(No.2)
    [Documentation]    Create Network and VM's. Verify VM's are updated in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[4]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-1
    Should contain    ${output}    NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-2
    Should contain    ${output}    NET1-VM-2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NET1_VM_IPS}[0]
    Should contain    ${Output2}    @{NET1_VM_IPS}[1]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NET1_VM_IPS}[0]
    Should contain    ${Output2}    @{NET1_VM_IPS}[1]
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can list the VMs.(No.2)
    [Documentation]    Verify created VM's are listed.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should contain    ${output}    NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should contain    ${output}    NET1-VM-2

Check that you can refer VM.(No.2)
    [Documentation]    Check that you can refer VM.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-1
    Should contain    ${output}    NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-2
    Should contain    ${output}    NET1-VM-2

Check that you can update the VM.(No.2)
    [Documentation]    Update VM's name and verify updated VM names.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server set --name VM_1 NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server set --name VM_2 NET1-VM-2
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show VM_1
    Should contain    ${output}    VM_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show VM_2
    Should contain    ${output}    VM_2

Check that you can delete the VM.(No.2)
    [Documentation]    Delete VM's. Verify VM's deleted in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Delete Vm Instance    VM_1
    Delete Vm Instance    VM_2
    Sleep    120s
    Delete SubNet    l2_subnet_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not Contain    ${output}    VM_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not Contain    ${output}    VM_2
    ${config}=    Create List    @{NETWORKS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete SecurityGroup    ${SECURITY_GROUP}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${Output1}    @{NET1_VM_IPS}[1]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${Output2}    @{NET1_VM_IPS}[1]
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Router operations - Create router.(No.2)
    [Documentation]    Create router and Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Router operations - Refer list of routers.(No.2)
    [Documentation]    Verify created router is listed.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Router operations - Refer router.(No.2)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Router operations - Delete the router.(No.2)
    [Documentation]    Delete router. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    router_1

Check that you can connect to external network(No.2)
    [Documentation]    Create external network and add router interfaces. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=${PROVIDER}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[3]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output1}    l2_network_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1
    #${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router set --external-gateway router_1
    #Log    ${OutputList}
    #Should Not Be True    ${rc}

Check that you can disconnect to external network(No.2)
    [Documentation]    Remove Interfaces from external network and Verify in dumpflows.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output1}    l2_network_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Router    router_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can connect to internal network.(No.2)
    [Documentation]    Create internal network and attach interfaces. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Create Router    router_1
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    min=1    max=1    image=cirros    flavor=cirros
    ...    sg=@{sg_list}[0]
    Create Vm Instances    l2_network_2    ${NET_2_VM_GRP_NAME}    min=1    max=1    image=cirros    flavor=cirros
    ...    sg=@{sg_list}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[1]
    Should contain    ${output}    @{NETWORKS_NAME}[1]
    #${output}=    List Ports
    #Should contain    ${output}    30.0.0.1
    #Should contain    ${output}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    @{NETWORKS_NAME}[1]
    #Should contain    ${Output2}    30.0.0.1
    #Should contain    ${Output2}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    @{NETWORKS_NAME}[1]
    #Should contain    ${Output2}    30.0.0.1
    #Should contain    ${Output2}    40.0.0.1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can disconnect from internal network.(No.2)
    [Documentation]    Remove interfaces form networks. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Remove Interface    router_1    ${interface}
    Delete Router    router_1
    Delete Vm Instance    @{NET_1_VM_GRP_NAME}[0]
    Delete Vm Instance    @{NET_2_VM_GRP_NAME}[0]
    #${output}=    List Ports
    #Should Not Contain    ${output}    30.0.0.1
    #Should Not Contain    ${output}    40.0.0.1
    Delete SubNet    l2_subnet_1
    Delete SubNet    l2_subnet_2
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
    Delete SecurityGroup    @{sg_list}[0]
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{NETWORKS_NAME}[0]
    #Should Not Contain    ${Output1}    30.0.0.1
    #Should Not Contain    ${Output1}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{NETWORKS_NAME}[0]
    #Should Not Contain    ${Output2}    30.0.0.1
    #Should Not Contain    ${Output2}    40.0.0.1

Check that you can assign FIP to VM.(No.2)
    [Documentation]    Create internal and external network assocaiate floating ip. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    #Delete All Security Group Rules    @{sg_list}[0]
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    network_1    ${VM_INSTANCES_FLOATING}    sg=@{sg_list}[0]    image=cirros    flavor=cirros
    : FOR    ${vm}    IN    @{VM_INSTANCES_FLOATING}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_FLOATING}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VM_INSTANCES_FLOATING}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM_INSTANCES_FLOATING}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Create Network    ${external_net_name}    --provider-network-type flat --provider-physical-network ${PROVIDER}
    Update Network    ${external_net_name}    --external
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Gateway    ${ROUTERS[0]}    ${external_net_name}
    ${VM_FLOATING_IPS}    OpenStackOperations.Create And Associate Floating IPs    ${external_net_name}    @{VM_INSTANCES_FLOATING}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{VM_FLOATING_IPS}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{VM_FLOATING_IPS}[0]
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Set Suite Variable    ${VM_FLOATING_IPS}
    ${rc}    ${output}=    Run And Return Rc And Output    ping -c 15 @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should contain    ${output}    64 bytes
    #OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]

Check that you can delete FIP from VM.(No.2)
    [Documentation]    Delete associated flowating ip and Verify in config datastore.
    ${floating_list} =    Create List    @{VM_FLOATING_IPS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/    ${floating_list}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove floating ip @{VM_INSTANCES_FLOATING}[0] @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Set Suite Variable    ${VM_FLOATING_IPS}
    ${rc}    ${output}=    Run And Return Rc And Output    ping -c 5 @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip delete @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Be True    ${rc}
    #OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_FLOATING}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS[0]}
    Delete SecurityGroup    @{sg_list}[0]
    Delete SubNet    l2_subnet_1
    #Delete SubNet    ${external_subnet_name}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{VM_FLOATING_IPS}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{VM_FLOATING_IPS}[0]
    Delete Network    l2_network_1
    Delete Network    ${external_net_name}

Security group - Register security group.(No.2)
    [Documentation]    Register security group adn Verify in config datastore.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list --project admin
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list --project admin -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    : FOR    ${sg}    IN    @{sgs}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    \    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should contain    ${Output1}    ${sg}
    : FOR    ${sg}    IN    @{sgs}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    \    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should contain    ${Output1}    ${sg}

Security group - Delete the security group.(No.2)
    [Documentation]    Delete the security group and Verify in config datastore.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list --project admin
    Log    ${output}
    Should Not Contain    ${output}    ${SECURITY_GROUP}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}

Security rule - Register security rule.(No.2)
    [Documentation]    Register security rule and Verify in config datastore.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack security group rule list ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group rule list -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    : FOR    ${sg}    IN    @{sgs}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    \    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should Contain    ${Output1}    ${sg}
    : FOR    ${sg}    IN    @{sgs}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    \    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should Contain    ${Output1}    ${sg}

Security rule - Delete the security rule.(No.2)
    [Documentation]    Delete the security rule and verify in config datastore.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}

Permit communication(No.2)
    [Documentation]    Create network and VM. Add security rule and permit communication from DHCP.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}

Deny communication(No.2)
    [Documentation]    Add security rule to VM and Deny communication.
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    TCP connection timed out    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SubNet    l2_subnet_1
    Delete Network    @{NETWORKS_NAME}[0]

Bring up ODL1
    [Documentation]    Bring up the ODL and Verify status active.
    ${output}=    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    Log    ${output}
    ${Output}=    Write Commands Until Prompt    ifconfig
    ${Output}=    Write Commands Until Prompt    sudo systemctl start opendaylight
    ${Output}=    Write Commands Until Prompt    sudo systemctl status opendaylight
    Should contain    ${Output}    active
    Sleep    300s
    ${Output}=    Write Commands Until Prompt    sudo netstat -tunpl | grep 66
    Log    ${Output}

Create virtual LAN(No.3)
    [Documentation]    Create virtual LAN.Verify LAN updated in dumpflows and config datastore
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    @{NETWORKS_NAME}[0]
    Should contain    ${Output3}    30.0.0.2
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(No.3)
    [Documentation]    Verify created network is listed.
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.3)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.3)
    [Documentation]    Update virtual LAN name and verify LAN name is updated.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.3)
    [Documentation]    Delete virtual LAN. Verify LAN is deleted in dumpflows and config datastore.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should Not Contain    ${output}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    @{NETWORKS_NAME}[0]

Check that you can create VM.(No.3)
    [Documentation]    Create Network and VM's. Verify VM's are updated in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    Test Netcat Operations Between Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    @{port}[4]
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-1
    Should contain    ${output}    NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-2
    Should contain    ${output}    NET1-VM-2
    ${VM_list}=    Create List    ${NET1_VM_IPS}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${NET1_VM_IPS}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NET1_VM_IPS}[0]
    Should contain    ${Output2}    @{NET1_VM_IPS}[1]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    @{NET1_VM_IPS}[0]
    Should contain    ${Output3}    @{NET1_VM_IPS}[1]
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can list the VMs.(No.3)
    [Documentation]    Verify created VM's are listed.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should contain    ${output}    NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should contain    ${output}    NET1-VM-2

Check that you can refer VM.(No.3)
    [Documentation]    Check that you can refer VM.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-1
    Should contain    ${output}    NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show NET1-VM-2
    Should contain    ${output}    NET1-VM-2

Check that you can update the VM.(No.3)
    [Documentation]    Update VM's name and verify updated VM names.
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server set --name VM_1 NET1-VM-1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server set --name VM_2 NET1-VM-2
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show VM_1
    Should contain    ${output}    VM_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server show VM_2
    Should contain    ${output}    VM_2

Check that you can delete the VM.(No.3)
    [Documentation]    Delete VM's. Verify VM's deleted in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Delete Vm Instance    VM_1
    Delete Vm Instance    VM_2
    Delete SubNet    l2_subnet_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not Contain    ${output}    VM_1
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server list
    Should Not Contain    ${output}    VM_2
    ${config}=    Create List    @{NETWORKS_NAME}[0]
    Delete Network    @{NETWORKS_NAME}[0]
    Delete SecurityGroup    ${SECURITY_GROUP}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${Output1}    @{NET1_VM_IPS}[1]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${Output2}    @{NET1_VM_IPS}[1]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    @{NET1_VM_IPS}[0]
    Should Not Contain    ${Output3}    @{NET1_VM_IPS}[1]
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Router operations - Create router.(No.3)
    [Documentation]    Create router and Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${router_list} =    Create List    router_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Router operations - Refer list of routers.(No.3)
    [Documentation]    Verify created router is listed.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Router operations - Refer router.(No.3)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Router operations - Delete the router.(No.3)
    [Documentation]    Delete router. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    router_1

Check that you can connect to external network(No.3)
    [Documentation]    Create external network and add router interfaces. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=${PROVIDER}
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[3]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1
    #${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router set --external-gateway router_1
    #Log    ${OutputList}
    #Should Not Be True    ${rc}

Check that you can disconnect to external network(No.3)
    [Documentation]    Remove Interfaces from external network and Verify in dumpflows.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output1}    l2_network_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    Delete Network    @{NETWORKS_NAME}[0]
    Delete Router    router_1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can connect to internal network.(No.3)
    [Documentation]    Create internal network and attach interfaces. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create Network    @{NETWORKS_NAME}[1]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    Create Router    router_1
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    min=1    max=1    image=cirros    flavor=cirros
    ...    sg=@{sg_list}[0]
    Create Vm Instances    l2_network_2    ${NET_2_VM_GRP_NAME}    min=1    max=1    image=cirros    flavor=cirros
    ...    sg=@{sg_list}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[1]
    Should contain    ${output}    @{NETWORKS_NAME}[1]
    #${output}=    List Ports
    #Should contain    ${output}    30.0.0.1
    #Should contain    ${output}    40.0.0.1
    #${config}=    Create List    30.0.0.1    40.0.0.1
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/    ${config}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    @{NETWORKS_NAME}[1]
    #Should contain    ${Output2}    30.0.0.1
    #Should contain    ${Output2}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    @{NETWORKS_NAME}[0]
    Should contain    ${Output3}    @{NETWORKS_NAME}[1]
    #Should contain    ${Output3}    30.0.0.1
    #Should contain    ${Output3}    40.0.0.1
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}

Check that you can disconnect from internal network.(No.3)
    [Documentation]    Remove interfaces form networks. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Remove Interface    router_1    ${interface}
    Delete Router    router_1
    Delete Vm Instance    @{NET_1_VM_GRP_NAME}[0]
    Delete Vm Instance    @{NET_2_VM_GRP_NAME}[0]
    #${output}=    List Ports
    #Should Not Contain    ${output}    30.0.0.1
    #Should Not Contain    ${output}    40.0.0.1
    Delete SubNet    l2_subnet_1
    Delete SubNet    l2_subnet_2
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
    Delete SecurityGroup    @{sg_list}[0]
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{NETWORKS_NAME}[0]
    #Should Not Contain    ${Output1}    30.0.0.1
    #Should Not Contain    ${Output1}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{NETWORKS_NAME}[0]
    #Should Not Contain    ${Output2}    30.0.0.1
    #Should Not Contain    ${Output2}    40.0.0.1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    @{NETWORKS_NAME}[0]
    #Should Not Contain    ${Output3}    30.0.0.1
    #Should Not Contain    ${Output3}    40.0.0.1

Check that you can assign FIP to VM.(No.3)
    [Documentation]    Create internal and external network assocaiate floating ip. Verify in dumpflows and config datastore.
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    #Delete All Security Group Rules    @{sg_list}[0]
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    network_1    ${VM_INSTANCES_FLOATING}    sg=@{sg_list}[0]    image=cirros    flavor=cirros
    : FOR    ${vm}    IN    @{VM_INSTANCES_FLOATING}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_FLOATING}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VM_INSTANCES_FLOATING}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM_INSTANCES_FLOATING}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Create Network    ${external_net_name}    --provider-network-type flat --provider-physical-network ${PROVIDER}
    Update Network    ${external_net_name}    --external
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    Add Router Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Add Router Gateway    ${ROUTERS[0]}    ${external_net_name}
    ${VM_FLOATING_IPS}    OpenStackOperations.Create And Associate Floating IPs    ${external_net_name}    @{VM_INSTANCES_FLOATING}
    ${floating_list} =    Create List    @{VM_FLOATING_IPS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/    ${floating_list}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{VM_FLOATING_IPS}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    @{VM_FLOATING_IPS}[0]
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Set Suite Variable    ${VM_FLOATING_IPS}
    ${rc}    ${output}=    Run And Return Rc And Output    ping -c 15 @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should contain    ${output}    64 bytes
    #OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]

Check that you can delete FIP from VM.(No.3)
    [Documentation]    Delete associated flowating ip and Verify in config datastore.
    ${floating_list} =    Create List    @{VM_FLOATING_IPS}[0]
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/    ${floating_list}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack server remove floating ip @{VM_INSTANCES_FLOATING}[0] @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Set Suite Variable    ${VM_FLOATING_IPS}
    ${rc}    ${output}=    Run And Return Rc And Output    ping -c 5 @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Contain    ${output}    64 bytes
    ${rc}    ${output}=    Run And Return Rc And Output    openstack floating ip delete @{VM_FLOATING_IPS}[0]
    Log    ${output}
    Should Not Be True    ${rc}
    #OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_FLOATING}
    \    Delete Vm Instance    ${VmElement}
    Remove Interface    ${ROUTERS[0]}    @{SUBNETS_NAME}[0]
    Delete Router    ${ROUTERS[0]}
    Delete SecurityGroup    @{sg_list}[0]
    Delete SubNet    l2_subnet_1
    #Delete SubNet    ${external_subnet_name}
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}    120s
    Close Connection
    Should Not Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_1_IP}
    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output1}    @{VM_FLOATING_IPS}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output2}    @{VM_FLOATING_IPS}[0]
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should Not Contain    ${Output3}    @{VM_FLOATING_IPS}[0]
    Delete Network    l2_network_1
    Delete Network    ${external_net_name}

Security group - Register security group.(No.3)
    [Documentation]    Register security group adn Verify in config datastore.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list --project admin
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list --project admin -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    ${sg_id}=    Create List    @{sgs}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-rules    ${sg_id}
    : FOR    ${sg}    IN    @{sgs}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    \    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should contain    ${Output1}    ${sg}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    \    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should contain    ${Output2}    ${sg}

Security group - Delete the security group.(No.3)
    [Documentation]    Delete the security group and Verify in config datastore.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list --project admin
    Log    ${output}
    Should Not Contain    ${output}    ${SECURITY_GROUP}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}

Security rule - Register security rule.(No.3)
    [Documentation]    Register security rule and Verify in config datastore.
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=1
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack security group rule list ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group rule list -cID -fvalue
    Log    ${sg_output}
    @{sgs}=    Split String    ${sg_output}    \n
    ${sg_id}=    Create List    @{sgs}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/security-rules    ${sg_id}
    : FOR    ${sg}    IN    @{sgs}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    \    ${Output1}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should Contain    ${Output1}    ${sg}
    \    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    \    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    \    Should Contain    ${Output2}    ${sg}

Security rule - Delete the security rule.(No.3)
    [Documentation]    Delete the security rule and verify in config datastore.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}

Permit communication(No.3)
    [Documentation]    Create network and VM. Add security rule and permit communication from DHCP.
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Create Vm Instances    l2_network_1    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2    image=cirros
    ...    flavor=cirros
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES_MAX}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES_MAX}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES_MAX}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}

Deny communication(No.3)
    [Documentation]    Add security rule to VM and Deny communication.
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    TCP connection timed out    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES_MAX}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete SubNet    l2_subnet_1
    Delete Network    @{NETWORKS_NAME}[0]
