*** Settings ***
Documentation     Test Suite for verification of HWVTEP usecases
Suite Setup       Basic Suite Setup
Suite Teardown    Basic Suite Teardown
Test Teardown     Get L2gw Debug Info
Resource          ../../variables/l2gw/Variables.robot
Resource          ../../libraries/L2GatewayOperations.robot
Resource          ../../libraries/HwvtepEmuOperations.robot

*** Test Cases ***
TC00 Setup test case
    # Setup L2GW#1 initialize and create PhysicalSwitch
    Collections.Set To Dictionary    ${NS_PORT_INFO11}    conn_id    ${hwvtep_conn_id_1}
    Collections.Set To Dictionary    ${NS_PORT_INFO12}    conn_id    ${hwvtep_conn_id_1}
    Collections.Set To Dictionary    ${NS_PORT_INFO13}    conn_id    ${hwvtep_conn_id_1}
    Collections.Set To Dictionary    ${NS_PORT_INFO14}    conn_id    ${hwvtep_conn_id_1}
    Collections.Set To Dictionary    ${NS_PORT_INFO15}    conn_id    ${hwvtep_conn_id_1}
    Collections.Set To Dictionary    ${NS_PORT_INFO16}    conn_id    ${hwvtep_conn_id_1}
    Collections.Set To Dictionary    ${NS_PORT_INFO17}    conn_id    ${hwvtep_conn_id_1}
    Setup Hwvtep    ${ODL_IP}    ${hwvtep_conn_id_1}    ${HWVTEP_IP}    ${GW_DEV_NAME11}    @{GW_NS_PORTS11}
    # L2GW#1 LogicalSwitch Index
    Set Suite Variable    ${ls_index1}    ${0}
    # Setup L2GW#2 initialize and create PhysicalSwitch
    Collections.Set To Dictionary    ${NS_PORT_INFO21}    conn_id    ${hwvtep_conn_id_2}
    Collections.Set To Dictionary    ${NS_PORT_INFO22}    conn_id    ${hwvtep_conn_id_2}
    Setup Hwvtep    ${ODL_IP}    ${hwvtep_conn_id_2}    ${HWVTEP2_IP}    ${GW_DEV_NAME21}    @{GW_NS_PORTS21}
    # L2GW#2 LogicalSwitch Index
    Set Suite Variable    ${ls_index2}    ${0}

TC01 GATEWAY Configuration Pattern A(L2GW:1, 4KPOD:1) Pod Type:VLAN
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF11}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID11}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF11}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID11}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO11}
    Verify Traffic    ${NS_PORT_INFO11}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC02 GATEWAY Configuration Pattern A(L2GW:1, 4KPOD:1) Pod Type:Flat
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID12}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID12}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO12}
    Verify Traffic    ${NS_PORT_INFO12}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC03 GATEWAY Configuration Pattern B(L2GW:1, 4KPOD:2) Pod Type:VLAN GATEWAY:1
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    '${GW_DEV_IF13};${GW_DEV_IF14}'    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID13}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF13}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID13}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF14}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID13}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO13}
    Verify Traffic    ${NS_PORT_INFO13}    ${VM_INFO}
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO14}
    Verify Traffic    ${NS_PORT_INFO14}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC04 GATEWAY Configuration Pattern B(L2GW:1, 4KPOD:2) Pod Type:VLAN GATEWAY:2
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF13}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF14}    ${GW_NAME12}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID13}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME12}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID14}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF13}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID13}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF14}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID14}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO13}
    Verify Traffic    ${NS_PORT_INFO13}    ${VM_INFO}
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO14}
    Verify Traffic    ${NS_PORT_INFO14}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC05 GATEWAY Configuration Pattern B(L2GW:1, 4KPOD:2) Pod Type:VLAN and Flat
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF11}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${GW_NAME12}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID11}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME12}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID12}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF11}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID11}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID12}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO11}
    Verify Traffic    ${NS_PORT_INFO11}    ${VM_INFO}
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO12}
    Verify Traffic    ${NS_PORT_INFO12}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC06 GATEWAY Configuration Pattern B(L2GW:1, 4KPOD:2) Pod Type:Flat GATEWAY:1
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    '${GW_DEV_IF12};${GW_DEV_IF15}'    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID12}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID12}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF15}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID15}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO12}
    Verify Traffic    ${NS_PORT_INFO12}    ${VM_INFO}
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO15}
    Verify Traffic    ${NS_PORT_INFO15}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC07 GATEWAY Configuration Pattern B(L2GW:1, 4KPOD:2) Pod Type:Flat GATEWAY:2
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF15}    ${GW_NAME12}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID12}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME12}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID15}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID12}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF15}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID15}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO12}
    Verify Traffic    ${NS_PORT_INFO12}    ${VM_INFO}
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO15}
    Verify Traffic    ${NS_PORT_INFO15}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC08 GATEWAY Configuration Pattern C(L2GW:2, 4KPOD:1) Pod Type:VLAN
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF11}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME21}    ${GW_DEV_IF21}    ${GW_NAME21}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID11}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME21}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID21}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    Set Suite Variable    ${ls_index2}    ${ls_index2+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF11}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID11}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_2}    ${GW_DEV_NAME21}    ${GW_DEV_IF21}    ${ls_index2}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID21}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO11}
    Verify Traffic    ${NS_PORT_INFO11}    ${VM_INFO}
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO21}
    Verify Traffic    ${NS_PORT_INFO21}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC09 GATEWAY Configuration Pattern C(L2GW:2, 4KPOD:1) Pod Type:Flat
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME21}    ${GW_DEV_IF22}    ${GW_NAME21}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID12}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME21}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID22}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    Set Suite Variable    ${ls_index2}    ${ls_index2+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF12}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID12}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_2}    ${GW_DEV_NAME21}    ${GW_DEV_IF22}    ${ls_index2}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID22}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO12}
    Verify Traffic    ${NS_PORT_INFO12}    ${VM_INFO}
    Verify Traffic    ${VM_INFO}    ${NS_PORT_INFO22}
    Verify Traffic    ${NS_PORT_INFO22}    ${VM_INFO}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC10 GATEWAY Configuration Pattern C(L2GW:2, 4KPOD:2) Pod Type:VLAN
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO1}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    OpenStackOperations.Create Network    ${NET_NAME12}    ${NET_ADDT_ARG} ${NET_SEGID12}
    OpenStackOperations.Create Subnet    ${NET_NAME12}    ${SUBNET_NAME12}    ${SUBNET_RANGE_IP12}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME12}    ${VM_NAME12}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME12}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME12}    ${vm_ip}
    &{VM_INFO2}=    Create Dictionary    type=vm    net_name=${NET_NAME12}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF13}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF16}    ${GW_NAME12}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID13}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME12}    ${NET_NAME12}    --default-segmentation-id ${GW_CONN_SEGID_VID16}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF13}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID13}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF16}    ${ls_index1}    ${NET_SEGID12}    ${GW_CONN_SEGID_VID16}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO1}    ${NS_PORT_INFO13}
    Verify Traffic    ${NS_PORT_INFO13}    ${VM_INFO1}
    Verify Traffic    ${VM_INFO2}    ${NS_PORT_INFO16}
    Verify Traffic    ${NS_PORT_INFO16}    ${VM_INFO2}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO1}
    Close From Vm    ${VM_INFO2}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC11 GATEWAY Configuration Pattern C(L2GW:2, 4KPOD:2) Pod Type:Flat
    # Craete Network/Subnet/VM Instance
    OpenStackOperations.Create Network    ${NET_NAME11}    ${NET_ADDT_ARG} ${NET_SEGID11}
    OpenStackOperations.Create Subnet    ${NET_NAME11}    ${SUBNET_NAME11}    ${SUBNET_RANGE_IP11}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME11}    ${VM_NAME11}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME11}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME11}    ${vm_ip}
    &{VM_INFO1}=    Create Dictionary    type=vm    net_name=${NET_NAME11}    ip=${vm_ip}    conn_id=${vm_conn_id}
    OpenStackOperations.Create Network    ${NET_NAME12}    ${NET_ADDT_ARG} ${NET_SEGID12}
    OpenStackOperations.Create Subnet    ${NET_NAME12}    ${SUBNET_NAME12}    ${SUBNET_RANGE_IP12}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create Vm Instance    ${NET_NAME12}    ${VM_NAME12}
    ${vm_ip}=    Wait Until Keyword Succeeds    240s    4s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME12}
    Log    ${vm_ip}
    ${vm_conn_id}=    OpenStackOperations.Create VM Instance Session    ${NET_NAME12}    ${vm_ip}
    &{VM_INFO2}=    Create Dictionary    type=vm    net_name=${NET_NAME12}    ip=${vm_ip}    conn_id=${vm_conn_id}
    # Create L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF15}    ${GW_NAME11}
    L2GatewayOperations.Create Verify L2Gateway    ${GW_DEV_NAME11}    ${GW_DEV_IF17}    ${GW_NAME12}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME11}    ${NET_NAME11}    --default-segmentation-id ${GW_CONN_SEGID_VID15}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${GW_NAME12}    ${NET_NAME12}    --default-segmentation-id ${GW_CONN_SEGID_VID17}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF15}    ${ls_index1}    ${NET_SEGID11}    ${GW_CONN_SEGID_VID15}
    Set Suite Variable    ${ls_index1}    ${ls_index1+1}
    L2GatewayOperations.Verify L2GW Node    ${hwvtep_conn_id_1}    ${GW_DEV_NAME11}    ${GW_DEV_IF17}    ${ls_index1}    ${NET_SEGID12}    ${GW_CONN_SEGID_VID17}
    Collect All Ovs Information    ${ctrl_conn_id}    ${cn_conn_id}    ${hwvtep_conn_id_1}    ${hwvtep_conn_id_2}
    # Verify
    Verify Traffic    ${VM_INFO1}    ${NS_PORT_INFO15}
    Verify Traffic    ${NS_PORT_INFO15}    ${VM_INFO1}
    Verify Traffic    ${VM_INFO2}    ${NS_PORT_INFO17}
    Verify Traffic    ${NS_PORT_INFO17}    ${VM_INFO2}
    # Delete L2GW GATEWAY/CONNECTION
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    # Delete Network/VM Instance
    Close From Vm    ${VM_INFO1}
    Close From Vm    ${VM_INFO2}
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network

TC99 Cleanup test case
    L2GatewayOperations.Delete All L2Gateway Connection
    L2GatewayOperations.Delete All L2Gateway
    OpenStackOperations.Delete All Vm Instance
    OpenStackOperations.Delete All Network
    Del Hwvtep Namespace    ${hwvtep_conn_id_1}
    Del Hwvtep Namespace    ${hwvtep_conn_id_2}
    Cleanup Hwvtep    ${hwvtep_conn_id_1}
    Cleanup Hwvtep    ${hwvtep_conn_id_2}

*** Keywords ***
Ping From VM Instance
    [Arguments]    ${from}    ${to}    ${num}=5
    [Documentation]    Ping from VM:${from} to ${to} in the background.
    ${vm_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${output}=    OpenStackOperations.Execute Command on VM Instance Session    ${vm_conn_id}    sudo /bin/sh -c "arp -d ${to_ip};ping -c ${num} ${to_ip} > /tmp/ping.txt 2>&1 &"
    [Return]    ${output}

Ping Command Wait From VM Instance
    [Arguments]    ${from}    ${to}
    [Documentation]    Wait for the end of the ping sent from VM:${from}.
    ${vm_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    : FOR    ${index}    IN RANGE    60
    \    ${output}=    OpenStackOperations.Execute Command on VM Instance Session    ${vm_conn_id}    sudo /bin/sh -c "ps -eo pid,comm | grep [p]ing | wc -l"
    \    ${num}=    Get Line    ${output}    0
    \    Exit For Loop If    '${num}'=='0'
    \    Sleep    2s

Ping Read Result From VM Instance
    [Arguments]    ${from}    ${to}
    [Documentation]    Get the result of ping sent from VM:${from}.
    ${vm_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${output}=    OpenStackOperations.Execute Command on VM Instance Session    ${vm_conn_id}    sudo /bin/sh -c "cat /tmp/ping.txt ; rm -f /tmp/ping.txt"
    [Return]    ${output}

Ping From Namespace
    [Arguments]    ${from}    ${to}    ${num}=5
    [Documentation]    Ping from NS:${from} to ${to} in the background.
    ${from_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${ns_name}=    Collections.Get From Dictionary    ${from}    ns_name
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    Switch Connection    ${from_conn_id}
    ${output}=    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} sudo /bin/sh -c "arp -d ${to_ip};ping -c ${num} ${to_ip} > /tmp/ping.txt 2>&1 &"
    [Return]    ${output}

Ping Command Wait From Namespace
    [Arguments]    ${from}    ${to}
    [Documentation]    Wait for the end of the ping sent from NS:${from}.
    ${from_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    Switch Connection    ${from_conn_id}
    : FOR    ${index}    IN RANGE    60
    \    ${output}=    Write Commands Until Prompt    sudo /bin/sh -c "ps -eo pid,comm | grep [p]ing | wc -l"
    \    ${num}=    Get Line    ${output}    0
    \    Exit For Loop If    '${num}'=='0'
    \    Sleep    2s

Ping Read Result From Namespace
    [Arguments]    ${from}    ${to}
    [Documentation]    Get the result of ping sent from NS:${from}.
    ${from_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    Switch Connection    ${from_conn_id}
    ${output}=    Write Commands Until Prompt    sudo /bin/sh -c "cat /tmp/ping.txt ; rm -f /tmp/ping.txt"
    [Return]    ${output}

Ping From Other
    [Arguments]    ${from}    ${to}    ${num}=5
    [Documentation]    Ping from Other:${from} to ${to} in the background.
    ${from_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    Switch Connection    ${from_conn_id}
    ${output}=    Write Commands Until Prompt    sudo /bin/sh -c "arp -d ${to_ip};ping -c ${num} ${to_ip} > /tmp/ping.txt 2>&1 &"
    [Return]    ${output}

Ping Command Wait From Other
    [Arguments]    ${from}    ${to}
    [Documentation]    Wait for the end of the ping sent from Other:${from}.
    ${from_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    Switch Connection    ${from_conn_id}
    : FOR    ${index}    IN RANGE    60
    \    ${output}=    Write Commands Until Prompt    sudo /bin/sh -c "ps -eo pid,comm | grep [p]ing | wc -l"
    \    ${num}=    Get Line    ${output}    0
    \    Exit For Loop If    '${num}'=='0'
    \    Sleep    2s

Ping Read Result From Other
    [Arguments]    ${from}    ${to}
    [Documentation]    Get the result of ping sent from Other:${from}.
    ${from_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    Switch Connection    ${from_conn_id}
    ${output}=    Write Commands Until Prompt    sudo /bin/sh -c "cat /tmp/ping.txt ; rm -f /tmp/ping.txt"
    [Return]    ${output}

Verify Ping
    [Arguments]    ${from}    ${to}    ${num}=5
    [Documentation]    Ping from ${from} to ${to}.
    ${from_type}=    Collections.Get From Dictionary    ${from}    type
    # Start Ping
    ${output}=    Run Keyword If    '${from_type}'=='vm'    Ping From VM Instance    ${from}    ${to}    ${num}
    ...    ELSE IF    '${from_type}'=='ns'    Ping From Namespace    ${from}    ${to}    ${num}
    ...    ELSE IF    '${from_type}'=='other'    Ping From Other    ${from}    ${to}    ${num}
    Log    ${output}
    # Wait Ping End
    Run Keyword If    '${from_type}'=='vm'    Ping Command Wait From VM Instance    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='ns'    Ping Command Wait From Namespace    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='other'    Ping Command Wait From Other    ${from}    ${to}
    # Read Result Ping
    ${output}=    Run Keyword If    '${from_type}'=='vm'    Ping Read Result From VM Instance    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='ns'    Ping Read Result From Namespace    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='other'    Ping Read Result From Other    ${from}    ${to}
    Should Contain    ${output}    ping statistics
    Should Not Contain    ${output}    ${PACKET_LOSS}

Verify Failed Ping
    [Arguments]    ${from}    ${to}    ${num}=5
    [Documentation]    Ping from ${from} to ${to} failed.
    ${from_type}=    Collections.Get From Dictionary    ${from}    type
    # Start Ping
    ${output}=    Run Keyword If    '${from_type}'=='vm'    Ping From VM Instance    ${from}    ${to}    ${num}
    ...    ELSE IF    '${from_type}'=='ns'    Ping From Namespace    ${from}    ${to}    ${num}
    ...    ELSE IF    '${from_type}'=='other'    Ping From Other    ${from}    ${to}    ${num}
    Log    ${output}
    # Wait Ping End
    Run Keyword If    '${from_type}'=='vm'    Ping Command Wait From VM Instance    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='ns'    Ping Command Wait From Namespace    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='other'    Ping Command Wait From Other    ${from}    ${to}
    # Read Result Ping
    ${output}=    Run Keyword If    '${from_type}'=='vm'    Ping Read Result From VM Instance    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='ns'    Ping Read Result From Namespace    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='other'    Ping Read Result From Other    ${from}    ${to}
    Should Contain    ${output}    ping statistics
    Should Contain    ${output}    ${PACKET_LOSS}

Tcp Send VM Instance
    [Arguments]    ${from}    ${to}
    [Documentation]    Send TCP from VM:${from} to ${to}.
    ${net_name}=    Collections.Get From Dictionary    ${from}    net_name
    ${from_ip}=    Collections.Get From Dictionary    ${from}    ip
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${string}=    Set Variable    TEST TCP Packet From: ${from_ip} To: ${to_ip}
    ${output}=    Wait Until Keyword Succeeds    120s    10s    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${from_ip}
    ...    sudo echo ${string} | nc -w 1 ${to_ip} 18080
    [Return]    ${output}

Tcp Send Namespace
    [Arguments]    ${from}    ${to}
    [Documentation]    Send TCP from NS:${from} to ${to}.
    ${send_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${ns_name}=    Collections.Get From Dictionary    ${from}    ns_name
    ${from_ip}=    Collections.Get From Dictionary    ${from}    ip
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${string}=    Set Variable    TEST TCP Packet From: ${from_ip} To: ${to_ip}
    Switch Connection    ${send_conn_id}
    ${output}=    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} /bin/sh -c 'echo ${string} | nc -w 1 ${to_ip} 18080'
    [Return]    ${output}

Tcp Send Other
    [Arguments]    ${from}    ${to}
    [Documentation]    Send TCP from Other:${from} to ${to}.
    ${send_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${from_ip}=    Collections.Get From Dictionary    ${from}    ip
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${string}=    Set Variable    TEST TCP Packet From: ${from_ip} To: ${to_ip}
    Switch Connection    ${send_conn_id}
    ${output}=    Write Commands Until Prompt    /bin/sh -c 'echo ${string} | nc -w 1 ${to_ip} 18080'
    [Return]    ${output}

Tcp Recv VM Instance
    [Arguments]    ${from}    ${to}
    [Documentation]    Receive TCP with VM:${to}.
    ${net_name}=    Collections.Get From Dictionary    ${to}    net_name
    ${ip}=    Collections.Get From Dictionary    ${to}    ip
    ${output}=    Wait Until Keyword Succeeds    120s    10s    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${ip}
    ...    sudo /bin/sh -c "nc -l -p 18080 2>&1 >/tmp/tempfile &"
    [Return]    ${output}

Tcp Recv Namespace
    [Arguments]    ${from}    ${to}
    [Documentation]    Receive TCP with NS:${to}.
    ${recv_conn_id}=    Collections.Get From Dictionary    ${to}    conn_id
    ${ns_name}=    Collections.Get From Dictionary    ${to}    ns_name
    Switch Connection    ${recv_conn_id}
    ${output}=    Write Commands Until Expected Prompt    ${NETNS_EXEC} ${ns_name} nc -l -p 18080 2>&1 >/tmp/tempfile &    \]\> \
    [Return]    ${output}

Tcp Recv Other
    [Arguments]    ${from}    ${to}
    [Documentation]    Receive TCP with Other:${to}.
    ${recv_conn_id}=    Collections.Get From Dictionary    ${to}    conn_id
    Switch Connection    ${recv_conn_id}
    ${output}=    Write Commands Until Expected Prompt    nc -l -p 18080 2>&1 >/tmp/tempfile &    \]\> \
    [Return]    ${output}

Tcp Read VM Instance
    [Arguments]    ${from}    ${to}
    [Documentation]    Read TCP received with VM:${to}.
    ${net_name}=    Collections.Get From Dictionary    ${to}    net_name
    ${ip}=    Collections.Get From Dictionary    ${to}    ip
    ${output}=    Wait Until Keyword Succeeds    120s    10s    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${ip}
    ...    sudo /bin/sh -c "killall nc;cat /tmp/tempfile;rm -f /tmp/tempfile"
    Log    ${output}
    [Return]    ${output}

Tcp Read Namespace
    [Arguments]    ${from}    ${to}
    [Documentation]    Read TCP received with NS:${to}.
    ${read_conn_id}=    Collections.Get From Dictionary    ${to}    conn_id
    Switch Connection    ${read_conn_id}
    ${output}=    Write Commands Until Prompt    cat /tmp/tempfile;rm -f /tmp/tempfile
    Log    ${output}
    [Return]    ${output}

Tcp Read Other
    [Arguments]    ${from}    ${to}
    [Documentation]    Read TCP received with Other:${to}.
    ${read_conn_id}=    Collections.Get From Dictionary    ${to}    conn_id
    Switch Connection    ${read_conn_id}
    ${output}=    Write Commands Until Prompt    cat /tmp/tempfile;rm -f /tmp/tempfile
    Log    ${output}
    [Return]    ${output}

Verify Tcp
    [Arguments]    ${from}    ${to}
    [Documentation]    TCP packet from ${from} to ${to}.
    ${from_type}=    Collections.Get From Dictionary    ${from}    type
    ${to_type}=    Collections.Get From Dictionary    ${to}    type
    ### Recv ###
    ${output}=    Run Keyword If    '${to_type}'=='vm'    Tcp Recv VM Instance    ${from}    ${to}
    ...    ELSE IF    '${to_type}'=='ns'    Tcp Recv Namespace    ${from}    ${to}
    ...    ELSE IF    '${to_type}'=='other'    Tcp Recv Other    ${from}    ${to}
    Log    ${output}
    ### Send ###
    ${output}=    Run Keyword If    '${from_type}'=='vm'    Tcp Send VM Instance    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='ns'    Tcp Send Namespace    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='other'    Tcp Send Other    ${from}    ${to}
    Log    ${output}
    ### Read ###
    ${output}=    Run Keyword If    '${to_type}'=='vm'    Tcp Read VM Instance    ${from}    ${to}
    ...    ELSE IF    '${to_type}'=='ns'    Tcp Read Namespace    ${from}    ${to}
    ...    ELSE IF    '${to_type}'=='other'    Tcp Read Other    ${from}    ${to}
    Log    ${output}
    ${from_ip}=    Collections.Get From Dictionary    ${from}    ip
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${string}=    Set Variable    TEST TCP Packet From: ${from_ip} To: ${to_ip}
    Should Contain    ${output}    ${string}

Udp Send VM Instance
    [Arguments]    ${from}    ${to}
    [Documentation]    Send UDP from VM:${from} to ${to}.
    ${net_name}=    Collections.Get From Dictionary    ${from}    net_name
    ${from_ip}=    Collections.Get From Dictionary    ${from}    ip
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${string}=    Set Variable    TEST UDP Packet From: ${from_ip} To: ${to_ip}
    ${output}=    Wait Until Keyword Succeeds    120s    10s    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${from_ip}
    ...    sudo echo ${string} | nc -u -w 1 ${to_ip} 18081
    [Return]    ${output}

Udp Send Namespace
    [Arguments]    ${from}    ${to}
    [Documentation]    Send UDP from NS:${from} to ${to}.
    ${send_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${ns_name}=    Collections.Get From Dictionary    ${from}    ns_name
    ${from_ip}=    Collections.Get From Dictionary    ${from}    ip
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${string}=    Set Variable    TEST UDP Packet From: ${from_ip} To: ${to_ip}
    Switch Connection    ${send_conn_id}
    ${output}=    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} /bin/sh -c 'echo ${string} | nc -u -w 1 ${to_ip} 18081'
    [Return]    ${output}

Udp Send Other
    [Arguments]    ${from}    ${to}
    [Documentation]    Send UDP from Other:${from} to ${to}.
    ${send_conn_id}=    Collections.Get From Dictionary    ${from}    conn_id
    ${from_ip}=    Collections.Get From Dictionary    ${from}    ip
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${string}=    Set Variable    TEST UDP Packet From: ${from_ip} To: ${to_ip}
    Switch Connection    ${send_conn_id}
    ${output}=    Write Commands Until Prompt    /bin/sh -c 'echo ${string} | nc -u -w 1 ${to_ip} 18081'
    [Return]    ${output}

Udp Recv VM Instance
    [Arguments]    ${from}    ${to}
    [Documentation]    Receive UDP with VM:${to}.
    ${net_name}=    Collections.Get From Dictionary    ${to}    net_name
    ${ip}=    Collections.Get From Dictionary    ${to}    ip
    ${output}=    Wait Until Keyword Succeeds    120s    10s    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${ip}
    ...    sudo /bin/sh -c "nc -u -l -p 18081 2>&1 >/tmp/tempfile &"
    [Return]    ${output}

Udp Recv Namespace
    [Arguments]    ${from}    ${to}
    [Documentation]    Receive UDP with NS:${to}.
    ${recv_conn_id}=    Collections.Get From Dictionary    ${to}    conn_id
    ${ns_name}=    Collections.Get From Dictionary    ${to}    ns_name
    Switch Connection    ${recv_conn_id}
    ${output}=    Write Commands Until Expected Prompt    ${NETNS_EXEC} ${ns_name} nc -u -l -p 18081 2>&1 >/tmp/tempfile &    \]\> \
    [Return]    ${output}

Udp Recv Other
    [Arguments]    ${from}    ${to}
    [Documentation]    Receive UDP with Other:${to}.
    ${recv_conn_id}=    Collections.Get From Dictionary    ${to}    conn_id
    Switch Connection    ${recv_conn_id}
    ${output}=    Write Commands Until Expected Prompt    nc -u -l -p 18081 2>&1 >/tmp/tempfile &    \]\> \
    [Return]    ${output}

Udp Read VM Instance
    [Arguments]    ${from}    ${to}
    [Documentation]    Read UDP received with VM:${to}.
    ${net_name}=    Collections.Get From Dictionary    ${to}    net_name
    ${ip}=    Collections.Get From Dictionary    ${to}    ip
    ${output}=    Wait Until Keyword Succeeds    120s    10s    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${ip}
    ...    sudo /bin/sh -c "killall nc;cat /tmp/tempfile;rm -f /tmp/tempfile"
    Log    ${output}
    [Return]    ${output}

Udp Read Namespace
    [Arguments]    ${from}    ${to}
    [Documentation]    Read UDP received with NS:${to}.
    ${read_conn_id}=    Collections.Get From Dictionary    ${to}    conn_id
    Switch Connection    ${read_conn_id}
    ${output}=    Write Commands Until Prompt    cat /tmp/tempfile;rm -f /tmp/tempfile
    Log    ${output}
    [Return]    ${output}

Udp Read Other
    [Arguments]    ${from}    ${to}
    [Documentation]    Read UDP received with Other:${to}.
    ${read_conn_id}=    Collections.Get From Dictionary    ${to}    conn_id
    Switch Connection    ${read_conn_id}
    ${output}=    Write Commands Until Prompt    cat /tmp/tempfile;rm -f /tmp/tempfile
    Log    ${output}
    [Return]    ${output}

Verify Udp
    [Arguments]    ${from}    ${to}
    [Documentation]    UDP packet from ${from} to ${to}.
    ${from_type}=    Collections.Get From Dictionary    ${from}    type
    ${to_type}=    Collections.Get From Dictionary    ${to}    type
    ### Recv ###
    ${output}=    Run Keyword If    '${to_type}'=='vm'    Udp Recv VM Instance    ${from}    ${to}
    ...    ELSE IF    '${to_type}'=='ns'    Udp Recv Namespace    ${from}    ${to}
    ...    ELSE IF    '${to_type}'=='other'    Udp Recv Other    ${from}    ${to}
    Log    ${output}
    ### Send ###
    ${output}=    Run Keyword If    '${from_type}'=='vm'    Udp Send VM Instance    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='ns'    Udp Send Namespace    ${from}    ${to}
    ...    ELSE IF    '${from_type}'=='other'    Udp Send Other    ${from}    ${to}
    Log    ${output}
    ### Read ###
    ${output}=    Run Keyword If    '${to_type}'=='vm'    Udp Read VM Instance    ${from}    ${to}
    ...    ELSE IF    '${to_type}'=='ns'    Udp Read Namespace    ${from}    ${to}
    ...    ELSE IF    '${to_type}'=='other'    Udp Read Other    ${from}    ${to}
    Log    ${output}
    ${from_ip}=    Collections.Get From Dictionary    ${from}    ip
    ${to_ip}=    Collections.Get From Dictionary    ${to}    ip
    ${string}=    Set Variable    TEST UDP Packet From: ${from_ip} To: ${to_ip}
    Should Contain    ${output}    ${string}

Verify Traffic
    [Arguments]    ${from}    ${to}
    [Documentation]    Ping/TCP/UDP packet from ${from} to ${to}.
    Log    ${from}
    Log    ${to}
    Verify Ping    ${from}    ${to}
    Verify Tcp    ${from}    ${to}
    Verify Udp    ${from}    ${to}
    # Comment out the test code for Broadcast and Multicast as its specification is not clear
    #    Log    Verify Broadcast From VM Instance
    #    Log    Verify Uknown Unicast From VM Instance
    #    Log    Verify Multicast From VM Instance

Basic Suite Setup
    [Documentation]    Basic Suite Setup required for the HWVTEP Test Suite
    RequestsLibrary.Create Session    alias=session    url=http://${ODL_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${ctrl_conn_id}=    SSHLibrary.Open Connection    ${OS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${ctrl_conn_id}
    Set Suite Variable    ${ctrl_conn_id}
    Set Suite Variable    ${OS_CNTL_CONN_ID}    ${ctrl_conn_id}
    Log    ${OS_IP}
    Log    ${OS_USER}
    Log    ${OS_PASSWORD}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${OS_USER}    ${OS_PASSWORD}
    Write Commands Until Prompt    cd ~; source keystonerc_admin    30s
    ${hwvtep_conn_id_1}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${hwvtep_conn_id_1}
    Set Suite Variable    ${hwvtep_conn_id_1}
    Log    ${HWVTEP_IP}
    Log    ${DEFAULT_USER}
    Log    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${hwvtep_conn_id_2}=    SSHLibrary.Open Connection    ${HWVTEP2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${hwvtep_conn_id_2}
    Set Suite Variable    ${hwvtep_conn_id_2}
    Log    ${HWVTEP2_IP}
    Log    ${DEFAULT_USER}
    Log    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${cn_conn_id}=    SSHLibrary.Open Connection    ${OVS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${cn_conn_id}
    Set Suite Variable    ${cn_conn_id}
    Set Suite Variable    ${OS_CMP1_CONN_ID}    ${cn_conn_id}
    Log    ${OVS_IP}
    Log    ${DEFAULT_USER}
    Log    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}

Basic Suite Teardown
    [Documentation]    Remove the basic suite required for HWVTEP test suite
    Switch Connection    ${ctrl_conn_id}
    close connection
    Switch Connection    ${hwvtep_conn_id_1}
    close connection
    Switch Connection    ${hwvtep_conn_id_2}
    close connection
    Switch Connection    ${cn_conn_id}
    close connection

Add Hwvtep Namespace
    [Arguments]    ${conn_id}    ${ovs_bridge}    @{portdictlist}
    [Documentation]    Create an Namespace:@{portdictlist} in ${conn_id} and add it to ${ovs_bridge}.
    HwvtepEmuOperations.Port Setup Hwvtep    ${conn_id}    ${ovs_bridge}    @{portdictlist}
    : FOR    ${dict}    IN    @{portdictlist}
    \    Log    ${dict}
    \    ${tap_port_name}=    Collections.Get From Dictionary    ${dict}    ns_tap_name
    \    ${mac}=    Collections.Get From Dictionary    ${dict}    mac
    \    ${ip}=    Collections.Get From Dictionary    ${dict}    ip
    \    ${ns_name}=    Collections.Get From Dictionary    ${dict}    ns_name
    \    ${vlan}=    Get From Dictionary Present Default    ${dict}    vlan
    \    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${mac}    ${ns_name}    ${tap_port_name}    ${ip}    ${vlan}
    \    ...    ${conn_id}

Del Hwvtep Namespace
    [Arguments]    ${conn_id}
    [Documentation]    Delete Namespace of ${conn_id}.
    HwvtepEmuOperations.Port Cleanup All Hwvtep    ${conn_id}

Setup Hwvtep
    [Arguments]    ${odl_ip}    ${conn_id}    ${hwvtep_vtep}    ${ovs_bridge}    @{portdictlist}
    [Documentation]    Initialize HWVTEP of ${conn_id}, and create ${ovs_bridge} and @{portdictlist}.
    HwvtepEmuOperations.Hwvtep Setup    ${conn_id}    ${hwvtep_vtep}    ${ovs_bridge}
    HwvtepEmuOperations.Port Setup Hwvtep    ${conn_id}    ${ovs_bridge}    @{portdictlist}
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}    ${conn_id}
    : FOR    ${dict}    IN    @{portdictlist}
    \    Log    ${dict}
    \    ${tap_port_name}=    Collections.Get From Dictionary    ${dict}    ns_tap_name
    \    ${mac}=    Collections.Get From Dictionary    ${dict}    mac
    \    ${ip}=    Collections.Get From Dictionary    ${dict}    ip
    \    ${ns_name}=    Collections.Get From Dictionary    ${dict}    ns_name
    \    ${vlan}=    Get From Dictionary Present Default    ${dict}    vlan
    \    L2GatewayOperations.Attach Port To Hwvtep Namespace With IP And VLAN    ${mac}    ${ns_name}    ${tap_port_name}    ${ip}    ${vlan}
    \    ...    ${conn_id}

Cleanup Hwvtep
    [Arguments]    ${conn_id}
    [Documentation]    Terminate HWVTEP of ${conn_id}, delete ovs_bridge and namespace and port.
    HwvtepEmuOperations.Port Cleanup All Hwvtep    ${conn_id}
    HwvtepEmuOperations.Hwvtep Cleanup    ${conn_id}

Get From Dictionary Present Default
    [Arguments]    ${dict}    ${key}    ${default}=${EMPTY}
    [Documentation]    Get ${value} for ${key} from dictionary. If it does not exist, return ${default}.
    ${keys}=    Get Dictionary Keys    ${dict}
    ${index}=    Get Index From List    ${keys}    ${key}
    ${value}=    Run Keyword If    ${index}!=-1    Collections.Get From Dictionary    ${dict}    vlan
    ...    ELSE    Set Variable    ${default}
    [Return]    ${value}

Collect All Ovs Bridge Information
    [Arguments]    ${ovs_conn_id}
    [Documentation]    Get OVS Flow and Port and Group.
    Switch Connection    ${ovs_conn_id}
    @{bridge_list}=    Get Bridge List    ${ovs_conn_id}
    : FOR    ${bridge}    IN    @{bridge_list}
    \    ${stdout}=    Write Commands Until Prompt And Log    ${OVS_DUMP_FLOWS} ${bridge} -Oopenflow13    30s
    \    ${stdout}=    Write Commands Until Prompt And Log    ${OVS_OFSHOW} ${bridge} -Oopenflow13    30s
    \    ${stdout}=    Write Commands Until Prompt And Log    ${OVS_OFDUMP_GROUPS} ${bridge} -Oopenflow13    30s

Collect All Ovs Information
    [Arguments]    @{ovs_conn_id_list}
    [Documentation]    Get Flow and Port and Group from all OVS.
    : FOR    ${ovs_conn_id}    IN    @{ovs_conn_id_list}
    \    Switch Connection    ${ovs_conn_id}
    \    ${stdout}=    Write Commands Until Prompt And Log    ${OVS_SHOW}    30s
    \    Collect All Ovs Bridge Information    ${ovs_conn_id}

Get L2gw Debug Info
    Set Suite Variable    ${hwvtep_conn_id}    ${hwvtep_conn_id_1}
    L2GatewayOperations.GetL2gw Debug Info
    Set Suite Variable    ${hwvtep_conn_id}    ${hwvtep_conn_id_2}
    L2GatewayOperations.GetL2gw Debug Info

Close From Vm
    [Arguments]    ${vm_info}
    ${vm_conn_id}=    Collections.Get From Dictionary    ${vm_info}    conn_id
    Switch Connection    ${vm_conn_id}
    OpenStackOperations.Exit From Vm Console
    Close Connection
