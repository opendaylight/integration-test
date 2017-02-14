@{ROUTERS}        ROUTER_1    ROUTER_2

*** Test Cases ***
Create Base Config
    [Documentation]    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/networks/    ${NETWORKS}

    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/subnets/    ${SUBNETS}

    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}

    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET10[1]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET20[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET20[1]}    ${OS_COMPUTE_2_IP}
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}

    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}

    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}

    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_INSTANCES_NET10[0]}    ping -c 3 ${VM_INSTANCES_NET10[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[1]    ${VM_INSTANCES_NET20[0]}    ping -c 3 ${VM_INSTANCES_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_INSTANCES_NET10[0]}    ping -c 3 ${VM_INSTANCES_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[1]    ${VM_INSTANCES_NET20[0]}    ping -c 3 ${VM_INSTANCES_NET10[1]}
    Should Contain    ${output}    64 bytes

Delete Base Config
    [Documentation]    Delete all the base config created
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}

    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}

    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}

    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}


