*** Settings ***
Documentation     Creating VMs
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Setup        Log Testcase Start To Controller Karaf
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/VpnServiceOperations.robot
Variables         ../../variables/Variables.py
Resource          ../../variables/vpnservice

*** Variables ***
@{NETWORKS}       NET1    NET2    NETWORK1    NETWORK2
@{SUBNETS}        SUB1    SUB2    SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24    40.1.1.0/24
@{PORT_LIST}      P1    P2    PORT1    PORT2
@{VM_INSTANCES}    VM1    VM2    VM3    VM4
@{VPN_INSTANCE_NAME}    4ae8cd92-48ca-49b5-94e1-b2921a2661c7    4ae8cd92-48ca-49b5-94e1-b2921a266112    4ae8cd92-48ca-49b5-94e1-b2921a2661c5
@{VPN_INSTANCE}    vpn1_instance.json    vpn2_instance.json    vpn3_instance.json
@{VPN_IDS}        vpn1id_instance.json    vpn2id_instance.json
${VPN_CONFIG_DIR}    ${CURDIR}/../../variables/vpnservice
${ROUTER}         router1

*** Test Cases ***
VMs are not reachable when brought up on VPNs
    [Documentation]    Attach VMs to VPNs and check reachability.
    [Setup]    Create Resources
    Given The VMs are active
    Then VMs are not reachable
    [Teardown]    Delete Resources

VMs are reachable when routes are imported/exported on same DPN
    [Documentation]    Import/Export routes between VPNs and check reachability on same DPN
    [Setup]    Create Resources
    Given The VMs are active
    When BGP Route is added between VPN1 and VPN2
    Then VMs are reachable
    [Teardown]    Delete Resources

VMs are reachable when routes are imported/exported on other DPN
    [Documentation]    Import/Export routes between VPNs and check reachability on other DPN
    [Setup]    Create Resources
    Given The VMs are active
    When Neighbouring route is added between VPN1 and VPN2
    Then VMs are reachable
    [Teardown]    Delete Resources

Subnet route is learnt for VPN1 and is shared across the other VPNs
    [Documentation]    Validate the route
    [Setup]    Create Resources
    Given the VMs are active
    Then subnet routes are verified
    [Teardown]    Delete Resources

Route is withdrawn from VPNs when Neutron port is deleted
    [Documentation]    Delete neutron port.
    [Setup]    Create Resources
    Given The VMs are active
    When Neutron port is deleted
    Then subnet routes are withdrawn
    [Teardown]    Delete Resources

VMs are reachable when their Networks are associated to VPNs
    [Documentation]    Create NETWORK1 and NETWORK2 . Associate the networks to VPN
    [Setup]    Create Resources
    Given The VMs are active
    When Networks are associated to VPN3
    Then VMs are reachable
    [Teardown]    Delete Resources

VMs are not reachable when the Network is disassociated from VPN
    [Documentation]    Disassociate Network2 from VPN3
    [Setup]    Create Resources
    Given Networks are associated to VPN3
    When Network2 is disassociated from VPN3
    Then VMs are not reachable
    [Teardown]    Delete Resources

Associate two interfaces to Router
    [Documentation]    Create router and associate interfaces
    When Router is created
    Then Interface is created and verified

VMs are reachable when VPNs are associated to Router
    [Documentation]    Associate VPN1 and VPN2 to Router
    [Setup]    Create Resources
    When Associate VPN to Router    ${ROUTER}    ${VPN_INSTANCE_NAME[0]}
    And Associate VPN to Router    ${ROUTER}    ${VPN_INSTANCE_NAME[1]}
    Then VMs are reachable
    [Teardown]    Delete Resources

Flows are reprogrammed when VMs are restarted
    [Documentation]    Restart VMs and verify the flows
    [Setup]    Create Resources
    When VMs are restarted
    And subnet routes are verified
    Then VMs are reachable
    [Teardown]    Delete Resources

*** Keywords ***
Create Resources
    [Documentation]    Creates required resources
    Create Networks Subnets and Ports
    Create VMs
    Create L3 VPN instances
    Create L3 VPN interfaces

Delete Resources
    [Documentation]    Deletes all the resources
    Delete Networks Subnets and Ports
    Delete VMs
    Delete L3 VPNs instances

Create Networks Subnets and Ports
    [Documentation]    Creates subnets and ports
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[1]}

Delete Networks Subnets and Ports
    [Documentation]    Dele subnets and ports
    Delete Network    ${NETWORKS[0]}
    Delete Network    ${NETWORKS[1]}
    Delete SubNet    ${SUBNETS[0]}
    Delete SubNet    ${SUBNETS[1]}
    Delete Port    ${PORT_LIST[1]}
    Delete Port    ${PORT_LIST[0]}

Create VMs
    [Documentation]    Creates VMs
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}

Delete VMs
    [Documentation]    Deletes VMs
    Delete Vm Instance    ${VM_INSTANCES[0]}
    Delete Vm Instance    ${VM_INSTANCES[1]}

The VMs are active
    [Documentation]    Check whether VMs are running
    ${rc}= Execute Command    nova list | grep ${VM_INSTANCES[0]} |    grep -i active    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    ${rc}= Execute Command    nova list | grep    ${VM_INSTANCES[1]} |    grep -i active    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

Create L3 VPN instances
    [Documentation]    Creates VPN instances
    Create L3 VPN instance    ${VPN_INSTANCE[0]}
    Create L3 VPN instance    ${VPN_INSTANCE[1]}

Create L3 VPNs interfaces
    [Documentation]    Creates VPN interfaces
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${vm1_id}=    Get VM_ID    ${VM_INSTANCES[0]}
    ${vm1_ip}=    Get VM_IP    ${VM_INSTANCES[0]}
    ${vm1_mac}=    Get VM_MAC    ${vm1_ip}
    ${vm2_id}=    Get VM_ID    ${VM_INSTANCES[1]}
    ${vm2_ip}=    Get VM_IP    ${VM_INSTANCES[1]}
    ${vm2_mac}=    Get VM_MAC    ${vm2_ip}
    Create L3 VPN interface    ${VPN_INSTANCE_NAME[0]}    ${vm1_id}    ${vm1_ip}    ${vm1_mac}
    Create L3 VPN interface    ${VPN_INSTANCE_NAME[1]}    ${vm2_id}    ${vm2_ip}    ${vm2_mac}
    Close Connection

Then VMs are reachable
    [Documentation]    Verifies VMs are reachable
    Check ping between VM1 and VM2    ${NETWORKS[0]}    ${VM_INSTANCES[0]}    ${VM_INSTANCES[1]}

Then VMs are not reachable
    [Documentation]    Verifies VMs are not reachable
    Run Keyword And Expect Error    100% packet loss    Check ping between VM1 and VM2    ${NETWORKS[0]}    ${VM_INSTANCES[0]}    ${VM_INSTANCES[1]}

BGP Route is added between VPN1 and VPN2
    [Documentation]    Creates BGP router
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/bgp_router_instance.json
    ${resp}    RequestsLibrary.Put Request    session    ${REST_CON}bgp:bgp-router/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Neighbouring routes is added between VPN1 and VPN2
    [Documentation]    Adding BGP neighbour
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/bgp_neighbor_instance.json
    ${resp}    RequestsLibrary.Put Request    session    ${REST_CON}bgp:bgp-neighbors/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

When Neutron port is deleted
    [Documentation]    Delete Neutron port
    Delete Port    ${PORT_LIST[0]}

Networks associated to VPN3
    [Documentation]    Associate Networks to VPN
    Create L3 VPN instance    ${VPN_INSTANCE[2]}
    ${devstack_conn_id}=    Get ControlNode Connection
    ${network1_id} = Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} = Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Associate Network to VPN    ${VPN_INSTANCE_NAME[2]}    ${network1_id}
    Associate Network to VPN    ${VPN_INSTANCE_NAME[2]}    ${network2_id}
    Close Connection

VMs are restarted
    [Documentation]    Restart VMs
    Restart VM    ${VM_INSTANCES[0]}
    Restart VM    ${VM_INSTANCES[1]}

Check ping between VM1 and VM2
    [Documentation]    Verifies VMs are reachable
    ${user}=cirros
    ${password}=cubswin:)
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${vm1_ip} = Get VM_IP    ${vm1}
    ${vm2_ip} = Get VM_IP    ${vm2}
    ${net_id}=    Get Net Id    ${network}    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id}    ssh    ${user}@${vm1_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no    d:
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Run Keyword If    ${rcode}    Check Ping    ${vm2_ip}
    Close Connection

Get VM_ID
    [Arguments]    ${VM_NAME}
    [Documentation]    Getting ID of VM
    ${output}    Execute Command    nova list | grep ${VM_NAME} | awk -F "|" '{print $2}'
    [Return]    ${output}

Get VM_IP
    [Arguments]    ${VM_NAME}
    [Documentation]    Getting VM Ip address
    ${output}    Execute Command    nova show    ${VM_NAME} | grep network | awk -F "|" '{print $3}'
    [Return]    ${output}

Get VM_MAC
    [Arguments]    ${VM_IP}
    [Documentation]    Getting VM's mac address
    ${output}    Execute Command    neutron port-list | grep ${VM_IP} | awk -F "|" '{print $4}'
    [Return]    ${output}

Subnet routes are verified
    [Documentation]    Verifies subnet routes
    ${flows1}= Get DumpFlows And Ovsconfig    ${OS_COMPUTE_1_IP}
    ${flows2}= Get DumpFlows And Ovsconfig    ${OS_COMPUTE_2_IP}
    ${ID1}= Get VM_ID    ${VM_INSTANCES[0]}
    ${ID2}= Get VM_ID    ${VM_INSTANCES[1]}
    ${IP1}= Get VM_IP    ${ID1}
    ${IP2}= Get VM_IP    ${ID2}
    ${Mac1}= Get VM_MAC    ${IP1}
    ${Mac2}= Get VM_MAC    ${IP2}
    Should Contain    ${Mac1}    ${flows1}
    Should Contain    ${Mac2}    ${flows1}
    Should Contain    ${Mac1}    ${flows2}
    Should Contain    ${Mac2}    ${flows2}

Subnet routes are withdrawn
    [Documentation]    Verifies subnets routes are withdrawn
    ${flows1}= Get DumpFlows And Ovsconfig    ${OS_COMPUTE_1_IP}
    ${flows2}= Get DumpFlows And Ovsconfig    ${OS_COMPUTE_2_IP}
    ${ID1}= Get VM_ID    ${VM_INSTANCES[0]}
    ${IP1}= Get VM_IP    ${ID1}
    ${Mac1}= Get VM_MAC    ${IP1}
    Should Not Contain    ${Mac1}    ${flows1}
    Should Not Contain    ${Mac1}    ${flows2}

Network2 is disassociated from VPN3
    [Documentation]    Disassociate Network from VPN
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_network.json
    ${devstack_conn_id}=    Get ControlNode Connection
    ${network2_id} = Get Net Id    ${NETWORKS[3]}    ${devstack_conn_id}
    Close Connection
    Disassociate Network from VPN    ${VPN_INSTANCE_NAME[2]}    ${network2_id}
    Subnet routes are withdrawn

Router is created
    [Documentation]    Creates router
    Create Router    ${ROUTER}

Interface is created and verified
    [Documentation]    Attach interfaces to Router
    Add Router Interface    ${ROUTER}    ${SUBNETS[0]}
    Add Router Interface    ${ROUTER}    ${SUBNETS[1]}
