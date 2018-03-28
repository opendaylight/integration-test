*** Settings ***
Documentation     Test suite to verify ControlNode Component StateTransit testing. The state transit component number is mentioned in the braces.
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
@{NETWORKS_NAME}    l2_network_1    external-net1
@{SUBNETS_NAME}    l2_subnet_1    external-subnet-1
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24    100.64.2.0/24
${external_gateway}    101.0.0.1
${external_subnet_allocation_pool}    start=100.64.2.18,end=100.64.2.248
${PROVIDER}       flat1

*** Test Cases ***
Kill ovs-vswitchd process in compute nodes(No:3)
    [Documentation]    Kill the process for testing
    #RelCompStateTransit_ComputeNode of related component: No. 3
    Kill ovs-vswitchd in compute node    ${OS_COMPUTE_1_IP}
    Kill ovs-vswitchd in compute node    ${OS_COMPUTE_2_IP}
    #Virtual LAN operations(DHCP: Enabled)Includes subnet settings

Create virtual LAN(No.3)
    [Documentation]    Create virtual LAN
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection

Refer list of virtual LANs.(No.3)
    [Documentation]    Refer list of virtual LANs.
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.3)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.3)
    [Documentation]    Update virtual LAN name.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.3)
    [Documentation]    Delete virtual LAN.
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
    #Router operations
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Create router.(No.3)
    [Documentation]    Create router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${router_list} =    Create List    router_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1

Refer list of routers.(No.3)
    [Documentation]    Refer list of routers.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Refer router.(No.3)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Delete the router.(No.3)
    [Documentation]    Delete the router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
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
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Check that you can connect to external network(No.3)
    [Documentation]    Create virtual LAN
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1

Check that you can disconnect to external network(No.3)
    [Documentation]    Check that you can disconnect to external network
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Delete Network    @{NETWORKS_NAME}[0]
    #Security group
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security group. (No.3)
    [Documentation]    Register security group.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
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

Delete the security group. (No.3)
    [Documentation]    Delete the security group.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
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
    #Security rule
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security rule. (No.3)
    [Documentation]    Register security rule.
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

Delete the security rule.(No.3)
    [Documentation]    Delete the security rule.
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
    #RelCompStateTransit_ComputeNode of related component: No. 8
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Kill ovsdb-server in compute nodes(No. 8)
    [Documentation]    Kill ovsdb-server in compute nodes
    Kill ovsdb-server in compute node    ${OS_COMPUTE_1_IP}
    Kill ovsdb-server in compute node    ${OS_COMPUTE_2_IP}
    #Virtual LAN operations(DHCP: Enabled)Includes subnet settings

Create virtual LAN(No.8)
    [Documentation]    Create virtual LAN
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(No.8)
    [Documentation]    Refer list of virtual LANs.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.8)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.8)
    [Documentation]    Update virtual LAN name.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.8)
    [Documentation]    Delete virtual LAN.
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
    #Router operations
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Create router.(No.8)
    [Documentation]    Create router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${router_list} =    Create List    router_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1

Refer list of routers.(No.8)
    [Documentation]    Refer list of routers.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Refer router.(No.8)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Delete the router.(No.8)
    [Documentation]    Delete the router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
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
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Check that you can connect to external network(No.8)
    [Documentation]    Create virtual LAN
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1

Check that you can disconnect to external network(No.8)
    [Documentation]    Check that you can disconnect to external network
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Delete Network    @{NETWORKS_NAME}[0]
    #Security group
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security group. (No.8)
    [Documentation]    Register security group.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
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

Delete the security group. (No.8)
    [Documentation]    Delete the security group.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    Clear L2_Network
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
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
    #Security rule
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security rule. (No.8)
    [Documentation]    Register security rule.
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

Delete the security rule.(No.8)
    [Documentation]    Delete the security rule.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Clear L2_Network
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}
    #RelCompStateTransit_ComputeNode of related component: No. 13
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Kill ovs-vswitchd process in compute nodes(No. 13)
    [Documentation]    Kill ovsdb-vswitchd in compute nodes
    Kill ovs-vswitchd in compute node    ${OS_COMPUTE_1_IP}
    Kill ovs-vswitchd in compute node    ${OS_COMPUTE_2_IP}
    #Virtual LAN operations(DHCP: Enabled)Includes subnet settings

Create virtual LAN(No.13)
    [Documentation]    Create virtual LAN
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(No.13)
    [Documentation]    Refer list of virtual LANs.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.13)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.13)
    [Documentation]    Update virtual LAN name.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.13)
    [Documentation]    Delete virtual LAN.
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
    #Router operations
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Create router.(No.13)
    [Documentation]    Create router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${router_list} =    Create List    router_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1

Refer list of routers.(No.13)
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Refer router.(No.13)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Delete the router.(No.13)
    [Documentation]    Delete the router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
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
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Check that you can connect to external network(No.13)
    [Documentation]    Create virtual LAN
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1

Check that you can disconnect to external network(No.13)
    [Documentation]    Check that you can disconnect to external network
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Delete Network    @{NETWORKS_NAME}[0]
    #Security group
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security group. (No.13)
    [Documentation]    Register security group.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
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

Delete the security group. (No.13)
    [Documentation]    Delete the security group.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    Clear L2_Network
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
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
    #Security rule
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security rule. (No.13)
    [Documentation]    Register security rule.
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

Delete the security rule.(No.13)
    [Documentation]    Delete the security rule.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Clear L2_Network
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}
    #RelCompStateTransit_ComputeNode of related component: No. 6
    #Virtual LAN operations(DHCP: Enabled)Includes subnet settings
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Create virtual LAN(No.6)
    [Documentation]    Create virtual LAN
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(No.6)
    [Documentation]    Refer list of virtual LANs.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.6)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.6)
    [Documentation]    Update virtual LAN name.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.6)
    [Documentation]    Delete virtual LAN.
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
    #Router operations
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Create router.(No.6)
    [Documentation]    Create router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${router_list} =    Create List    router_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1

Refer list of routers.(No.6)
    [Documentation]    Refer list of routers.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Refer router.(No.6)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Delete the router.(No.6)
    [Documentation]    Delete the router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
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
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Check that you can connect to external network(No.6)
    [Documentation]    Create virtual LAN
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1

Check that you can disconnect to external network(No.6)
    [Documentation]    Check that you can disconnect to external network
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Delete Network    @{NETWORKS_NAME}[0]
    #Security group
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security group. (No.6)
    [Documentation]    Register security group.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
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

Delete the security group. (No.6)
    [Documentation]    Delete the security group.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    Clear L2_Network
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
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
    #Security rule
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security rule. (No.6)
    [Documentation]    Register security rule.
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

Delete the security rule.(No.6)
    [Documentation]    Delete the security rule.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Clear L2_Network
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}
    #RelCompStateTransit_ComputeNode of related component: No. 4
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Kill ovsdb-server in compute nodes(No. 4)
    [Documentation]    Kill ovsdb-server in compute nodes
    Kill ovsdb-server in compute node    ${OS_COMPUTE_1_IP}
    Kill ovsdb-server in compute node    ${OS_COMPUTE_2_IP}
    #Virtual LAN operations(DHCP: Enabled)Includes subnet settings

Create virtual LAN(No.4)
    [Documentation]    Create virtual LAN
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(No.4)
    [Documentation]    Refer list of virtual LANs.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.4)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.4)
    [Documentation]    Update virtual LAN name.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.4)
    [Documentation]    Delete virtual LAN.
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
    #Router operations -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Create router.(No.4)
    [Documentation]    Create router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${router_list} =    Create List    router_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1

Refer list of routers.(No.4)
    [Documentation]    Refer list of routers.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Refer router.(No.4)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Delete the router.(No.4)
    [Documentation]    Delete the router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
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
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Check that you can connect to external network(No.4)
    [Documentation]    Create virtual LAN
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1

Check that you can disconnect to external network(No.4)
    [Documentation]    Check that you can disconnect to external network
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Delete Network    @{NETWORKS_NAME}[0]
    #Security group -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security group. (No.4)
    [Documentation]    Register security group.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
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

Delete the security group. (No.4)
    [Documentation]    Delete the security group.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    Clear L2_Network
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
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
    #Security rule -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security rule. (No.4)
    [Documentation]    Register security rule.
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

Delete the security rule.(No.4)
    [Documentation]    Delete the security rule.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Clear L2_Network
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}
    #RelCompStateTransit_ComputeNode of related component: No. 11
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Kill ovs-vswitchd in compute nodes(No. 11)
    [Documentation]    Kill ovsdb-vswitchd in compute nodes
    Kill ovs-vswitchd in compute node    ${OS_COMPUTE_1_IP}
    Kill ovs-vswitchd in compute node    ${OS_COMPUTE_2_IP}
    #Virtual LAN operations(DHCP: Enabled)Includes subnet settings -

Create virtual LAN(No.11)
    [Documentation]    Create virtual LAN
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(No.11)
    [Documentation]    Refer list of virtual LANs.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.11)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.11)
    [Documentation]    Update virtual LAN name.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.11)
    [Documentation]    Delete virtual LAN.
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
    #Router operations -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Create router.(No.11)
    [Documentation]    Create router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${router_list} =    Create List    router_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1

Refer list of routers.(No.11)
    [Documentation]    Refer list of routers.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Refer router.(No.11)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Delete the router.(No.11)
    [Documentation]    Delete the router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
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
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Check that you can connect to external network(No.11)
    [Documentation]    Create virtual LAN
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1

Check that you can disconnect to external network(No.11)
    [Documentation]    Check that you can disconnect to external network
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Delete Network    @{NETWORKS_NAME}[0]
    #Security group -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security group. (No.11)
    [Documentation]    Register security group.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
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

Delete the security group. (No.11)
    [Documentation]    Delete the security group.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    Clear L2_Network
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
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
    #Security rule -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security rule. (No.11)
    [Documentation]    Register security rule.
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

Delete the security rule.(No.11)
    [Documentation]    Delete the security rule.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Clear L2_Network
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}
    #RelCompStateTransit_ComputeNode of related component: No. 9
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Kill ovs-vswitchd in compute nodes(No. 9)
    [Documentation]    Kill ovsdb-vswitchd in compute nodes
    Kill ovs-vswitchd in compute node    ${OS_COMPUTE_1_IP}
    Kill ovs-vswitchd in compute node    ${OS_COMPUTE_2_IP}
    #Virtual LAN operations(DHCP: Enabled)Includes subnet settings -

Create virtual LAN(No.9)
    [Documentation]    Create virtual LAN
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    ${output}=    List Ports
    Should contain    ${output}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    @{NETWORKS_NAME}[0]
    Should contain    ${Output2}    30.0.0.2
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}

Refer list of virtual LANs.(No.9)
    [Documentation]    Refer list of virtual LANs.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${output}=    List Networks
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Refer virtual LAN.(No.9)
    [Documentation]    Refer virtual LAN.
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]

Update virtual LAN name.(No.9)
    [Documentation]    Update virtual LAN name.
    Update Network    @{NETWORKS_NAME}[0]    additional_args=--description Network_Update
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    Network_Update

Delete virtual LAN.(No.9)
    [Documentation]    Delete virtual LAN.
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
    #Router operations -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Create router.(No.9)
    [Documentation]    Create router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Create Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1
    ${router_list} =    Create List    router_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${Output2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output2}    router_1
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${Output3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/
    Should contain    ${Output3}    router_1

Refer list of routers.(No.9)
    [Documentation]    Refer list of routers.
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Contain    ${router_output}    router_1

Refer router.(No.9)
    [Documentation]    Refer router.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router show router_1
    Log    ${output}
    Should Contain    ${output}    router_1

Delete the router.(No.9)
    [Documentation]    Delete the router.
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Delete Router    router_1
    ${router_output} =    List Routers
    Log    ${router_output}
    Should Not Contain    ${router_output}    router_1
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
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
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Check that you can connect to external network(No.9)
    [Documentation]    Create virtual LAN
    Create Network    @{NETWORKS_NAME}[0]    additional_args=--external --provider-network-type=flat --provider-physical-network=public
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[2]    additional_args=--gateway 100.64.2.13 --allocation-pool start=100.64.2.18,end=100.64.2.248
    ${output}=    Show Network    @{NETWORKS_NAME}[0]
    Should contain    ${output}    @{NETWORKS_NAME}[0]
    ${net_id}=    Get Net Id    @{NETWORKS_NAME}[0]
    ${networkName} =    Create List    l2_network_1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}network/${net_id}/    ${networkName}
    Create Router    router_1
    Update Router    router_1    --external-gateway l2_network_1

Check that you can disconnect to external network(No.9)
    [Documentation]    Check that you can disconnect to external network
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${stdout}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    ${rc}    ${OutputList}=    Run And Return Rc And Output    openstack router unset --external-gateway router_1
    Log    ${OutputList}
    Should Not Be True    ${rc}
    SSHLibrary.Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | awk '{print $3 $6 $7 $8}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection
    Should Be Equal    ${stdout}    ${flows}
    Delete Network    @{NETWORKS_NAME}[0]
    #Security group -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security group. (No.9)
    [Documentation]    Register security group.
    Neutron Security Group Create    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list
    Log    ${sg_output}
    Should contain    ${sg_output}    ${SECURITY_GROUP}
    ${rc}    ${sg_output}=    Run And Return Rc And Output    openstack security group list -cID -fvalue
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

Delete the security group. (No.9)
    [Documentation]    Delete the security group.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete SecurityGroup    ${SECURITY_GROUP}
    Clear L2_Network
    ${rc}    ${output}=    Run And Return Rc And Output    openstack security group list
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
    #Security rule -
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Register security rule. (No.9)
    [Documentation]    Register security rule.
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

Delete the security rule.(No.9)
    [Documentation]    Delete the security rule.
    ${resp1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Clear L2_Network
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutron:neutron/security-rules
    Log    ${resp.content}
    Should Not Be Equal    ${resp.content}    ${resp1.content}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_2_IP}
    ${DEL_ODL2}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL2}    ${DEL_ODL2}
    Get ControlNode Connection By IP    ${ODL_SYSTEM_3_IP}
    ${DEL_ODL3}=    Write Commands Until Prompt    curl -v --user "admin":"admin" -H "Content-type: application/json" -X GET http://localhost:8181/restconf/config/neutron:neutron/security-rules
    Should Not Be Equal    ${ODL3}    ${DEL_ODL3}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network
