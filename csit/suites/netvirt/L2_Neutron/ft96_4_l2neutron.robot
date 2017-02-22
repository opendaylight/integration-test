*** Settings ***
Documentation     Test suite to validate FT_96.4 functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
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
Resource          ../../../variables/Variables.robot

*** Variables ***
@{NETWORKS}       NET10    NET20    NET30    NET40    NET50    NET60
@{SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24    40.1.1.0/24    50.1.1.0/24    60.1.1.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4    PORT5    PORT6    PORT7    PORT8    PORT9    PORT10    PORT11    PORT12    PORT13
@{VM_INSTANCES_DPN1}    VM11    VM21    VM31    VM41    VM51    VM61
@{VM_INSTANCES_DPN2}    VM12    VM22    VM32    VM42    VM52    VM62
@{ROUTERS}        ROUTER_1
@{ROUTER_SUBNETS}        SUBNET1    SUBNET2

*** Test Cases ***
Create FT Config
    [Documentation]    Creating basic config to test FT 96.4
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    Create Network    ${NETWORKS[2]}
    Create Network    ${NETWORKS[3]}
    Create Network    ${NETWORKS[4]}
    Create Network    ${NETWORKS[5]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Should Contain    ${NET_LIST}    ${NETWORKS[2]}
    Should Contain    ${NET_LIST}    ${NETWORKS[3]}
    Should Contain    ${NET_LIST}    ${NETWORKS[4]}
    Should Contain    ${NET_LIST}    ${NETWORKS[5]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/networks/    ${NETWORKS}

    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    Create SubNet    ${NETWORKS[3]}    ${SUBNETS[3]}    ${SUBNET_CIDR[3]}
    Create SubNet    ${NETWORKS[4]}    ${SUBNETS[4]}    ${SUBNET_CIDR[4]}
    Create SubNet    ${NETWORKS[5]}    ${SUBNETS[5]}    ${SUBNET_CIDR[5]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[2]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[3]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[4]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[5]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/subnets/    ${SUBNETS}

    Create Port    ${NETWORKS[6]}    ${PORT_LIST[0]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[1]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[4]}
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[5]}
    Create Port    ${NETWORKS[3]}    ${PORT_LIST[6]}
    Create Port    ${NETWORKS[3]}    ${PORT_LIST[7]}
    Create Port    ${NETWORKS[4]}    ${PORT_LIST[8]}
    Create Port    ${NETWORKS[4]}    ${PORT_LIST[9]}
    Create Port    ${NETWORKS[5]}    ${PORT_LIST[10]}
    Create Port    ${NETWORKS[5]}    ${PORT_LIST[11]}
    Create Port    ${NETWORKS[6]}    ${PORT_LIST[12]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}

    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_DPN2[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_DPN1[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_DPN1[1]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_INSTANCES_DPN2[1]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_INSTANCES_DPN1[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[6]}    ${VM_INSTANCES_DPN2[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[7]}    ${VM_INSTANCES_DPN2[3]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[8]}    ${VM_INSTANCES_DPN1[3]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[9]}    ${VM_INSTANCES_DPN1[4]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[10]}    ${VM_INSTANCES_DPN2[4]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[11]}    ${VM_INSTANCES_DPN1[5]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[12]}    ${VM_INSTANCES_DPN2[5]}    ${OS_COMPUTE_2_IP}


    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}

    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}

    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{ROUTER_SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{ROUTER_SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}

    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_INSTANCES_DPN1[0]}    ping -c 3 ${VM_INSTANCES_DPN2[0]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_INSTANCES_DPN2[0]}    ping -c 3 ${VM_INSTANCES_DPN1[0]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[1]    ${VM_INSTANCES_DPN1[1]}    ping -c 3 ${VM_INSTANCES_DPN2[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[1]    ${VM_INSTANCES_DPN2[1]}    ping -c 3 ${VM_INSTANCES_DPN1[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[2]    ${VM_INSTANCES_DPN1[2]}    ping -c 3 ${VM_INSTANCES_DPN2[2]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[2]    ${VM_INSTANCES_DPN2[2]}    ping -c 3 ${VM_INSTANCES_DPN1[2]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[3]    ${VM_INSTANCES_DPN1[3]}    ping -c 3 ${VM_INSTANCES_DPN2[3]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[3]    ${VM_INSTANCES_DPN2[3]}    ping -c 3 ${VM_INSTANCES_DPN1[3]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[4]    ${VM_INSTANCES_DPN1[4]}    ping -c 3 ${VM_INSTANCES_DPN2[4]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[4]    ${VM_INSTANCES_DPN2[4]}    ping -c 3 ${VM_INSTANCES_DPN1[4]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[5]    ${VM_INSTANCES_DPN1[5]}    ping -c 3 ${VM_INSTANCES_DPN2[5]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[5]    ${VM_INSTANCES_DPN2[5]}    ping -c 3 ${VM_INSTANCES_DPN1[5]}
    Should Contain    ${output}    64 bytes

Delete FT Config
    [Documentation]    Delete all the FT config created
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}

    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}

    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}

    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
