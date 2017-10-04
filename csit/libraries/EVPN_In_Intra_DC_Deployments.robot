*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Resource          Utils.robot
Resource          TemplatedRequests.robot
Resource          DevstackUtils.robot
Resource          SSHKeywords.robot
Resource          KarafKeywords.robot
Resource          VpnOperations.robot
Resource          BgpOperations.robot
Resource          OpenStackOperations.robot
Resource          OVSDB.robot
Resource          ../variables/Variables.robot
Resource          ../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
Library           String
Library           OperatingSystem

*** Variables ***

*** Keywords ***
Validation_OpenFlow_Node_Inventory_BGP
    Log    "Validate Open Flow channel is established between VSwitches and CSC"
    Verify Tunnel Status as UP
    Log    "Restart OVSDB"
    Restart OVSDB    ${OS_COMPUTE_1_IP}
    Restart OVSDB    ${OS_COMPUTE_2_IP}
    ${output}    Issue Command on Dpn    ${OS_COMPUTE_1_IP}    sudo ovsdb-client dump -f list Open_vSwitch Controller | grep state
    Log    ${output}
    Log    "Validate CSC inventory shows them in the node inventory"
    ${output}    Get Inventory Nodes    session
    Log    ${output}
    Log    "Validate L3VPNoVXLAN should display the L3VNI along with RD, RTs"
    ${Req_no_of_L3VPN} =    Evaluate    1
    Verify L3VPN    ${Req_no_of_L3VPN}
    Log    "Validate BGP neighbour ship is established between CSC and ASR"
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${index}    IN RANGE    0    1
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${network_id}

Verify L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*

Issue Command on Dpn
    [Arguments]    ${serverip}    ${cmd}
    [Documentation]    Get DpnId from server and return
    ${control_conn_id}=    SSHLibrary.Open Connection    ${serverip}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=30s
    ${output}    Write Commands Until Prompt    ${cmd}    30
    log    ${output}
    SSHLibrary.Close Connection
    [Return]    ${output}

Get Inventory Nodes
    [Arguments]    ${session}
    [Documentation]    Get Inventory Nodes using rest
    ${resp}    RequestsLibrary.Get Request    ${session}    /restconf/operational/opendaylight-inventory:nodes
    Log    ${resp.content}
    [Return]    ${resp.content}

VM Creation Quota Update
    [Arguments]    ${num_instances}
    [Documentation]    Update VM Creation Quota
    ${rc}    ${output}=    Run And Return Rc And Output    openstack project list
    Log    ${output}
    Should Not Be True    ${rc}
    ${split_output}=    Split String    ${output}
    ${index} =    Get Index From List    ${split_output}    admin
    ${rc}    ${output}=    Run And Return Rc And Output    openstack quota set --instances ${num_instances} ${split_output[${index-2}]}
    Log    ${output}
