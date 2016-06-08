*** Settings ***
Documentation     Test Suite for veirfication of ODL Neutron functions
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions

Library           OperatingSystem
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Library           ../../../libraries/UtilLibrary.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/ClusterKeywords.robot
Variables         ../../../variables/vpnservice/neutron_service.py
Variables         ../../../variables/vpnservice_openstack/vpnservice_variables.py
Library           ../../../libraries/VpnUtils.py    ${CONTROLLER}    WITH NAME    vpn

*** Variables ***
${BRIDGE1}    br-int
${BRIDGE2}    br-int
${OVSPWD}    mininet
${swdumpflows}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
${swdumpgrps}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
${ovs-show}    sudo ovs-vsctl show
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${GET_RESP_CODE}    200
${STK_UNAME}    admin
${STK_PWD}    admin
${DEFAULT_PASSWORD}    admin
${source_openrc}    source openrc admin admin
${DEFAULT_STACK_PROMPT}    $
${CMD}    virsh list
#${CMD}    ls
#${VM_INDX1}    0
#${VM_INDX2}    1
${PING_IP1}    ping 10.1.1.2 -c 3
${PING_IP2}    ping 10.1.1.3 -c 3
${PING_IP3}    ping 20.1.1.2 -c 3
${PING_IP4}    ping 20.1.1.3 -c 3
#${EXP_STR}    round-trip
${EXP_STR}    loss
${EXP_STR_IFCONFIG}    $
${STOP_CMD}    sudo service openvswitch-switch stop
${START_CMD}    sudo service openvswitch-switch start
${PING_EXTRA_ROUTE_IP1}    ping 40.1.1.2 -c 3
${PING_EXTRA_ROUTE_IP2}    ping 50.1.1.2 -c 3
${CONFIG_EXTRA_ROUTE_IP1}    sudo ifconfig eth0:1 40.1.1.2/24 up
${CONFIG_EXTRA_ROUTE_IP2}    sudo ifconfig eth0:1 50.1.1.2/24 up
@{vpn_int_values}    10.1.1.2    10.1.1.3    20.1.1.2    20.1.1.3

*** Test Cases ***
TC01 Verify TUNNEL creation
    [Documentation]   Verify Tunnel creation 
    ${exp_result}    ConvertToInteger    0
    [Tags]    Post 
    Log    "Get the dpn ids"
    ${resp}    vpn.Create Tunnel   srcip=${OS_COMPUTE_1_IP}    dstip=${OS_COMPUTE_2_IP}    ovs_pwd=${OVSPWD}
    Log    ${resp}
    Should Be Equal    ${resp}    ${exp_result}

TC02 Create Neutron Networks
    [Documentation]    Verify neutron network creation
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_NET1}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_NET2}
    Log    ${resp}
	
TC03 Verify fetching available network
    [Documentation]    Verify fetching available  network
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get
    ${result}      ConvertToInteger    1
    Log    "Fetching Network Inmformation"
    ${resp}    vpn.Get Networks
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC04 Create Neutron Subnet
    [Documentation]    Verify neutron subnet creation
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_SUBNET1}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_SUBNET2}
    Log    ${resp}

TC05 Verify fetching available subnet
    [Documentation]    Verify fetching available subnet
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get
    Log    "Fetching Subnet Information"
    ${resp}    vpn.Get Subnets
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC06 Create Neutron Ports
    [Documentation]    Verify neutron port creation
    [Tags]    Post 
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_PORT11}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_PORT12}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_PORT21}
    Log    ${resp}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_PORT22}
    Log    ${resp}
    Log    "BOOT_VMs"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${EXPORT_IMAGE}
    Log    ${resp}
    
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${BOOT_VM11}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${BOOT_VM12}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${BOOT_VM21}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${BOOT_VM22}
    Log    ${resp}

TC07 Verify fetching available ports
    [Documentation]    Verify fetching available ports
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get 
    Log    "Verify fetching available ports"
    ${resp}    vpn.Get Ports
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC08 Verify E2E ELAN connectivity across DPNs with VxLAN
    [Documentation]   Verify E2E ELAN connectivity across DPNs with VxLAN    
    [Tags]    ELAN Datapath across DPNs
    ${resp}    Sleep    ${DELAY_BEFORE_PING}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX2}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

TC09 Verify vpn service creation 
    [Documentation]   Verify vpn service creation   
    [Tags]    Post
    ${exp_result}    ConvertToInteger    0
    Log    "Creating L3vpn"
    ${result}    vpn.Create L3vpn    ${L3VPN}    ${RD}    ${IMPORT_RT}    ${EXPORT_RT}
    Log    ${result}

TC10 Verify/fetch vpn service from DB
    [Documentation]   Verify/fetch vpn service from DB   
    [Tags]    Get
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "L3vpn created is found  in DB"
    : FOR    ${value}    IN    @{vpn_values}
    \    Should Contain    ${resp}    ${value}
    Log    "L3vpn details are found in DB"

TC11 Verify Associate network to vpn service and check from DB 
    [Documentation]   Verify Association of network to vpn service and check from DB   
    [Tags]    Associate
    Log    "Associate network"
    ${netid2}    vpn.Associate Network    ${NETWORK1}   ${L3VPN}
    ${netid3}    vpn.Associate Network    ${NETWORK2}   ${L3VPN}
    Log    ${netid2}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}

    Log    "check if uuid of associated network is found in DB"
    Should Contain    ${resp}    ${netid2}
    Should Contain    ${resp}    ${netid3}
    Log    "Associated network found in DB"

TC12 Verify end to end data path within same network and from one network to the other 
    [Documentation]   Verify end to end data path within same network and from one network to the other    
    [Tags]    Datapath
    ${resp}    Sleep    ${DELAY_2_BEFORE_PING}

    Log    "Verify FIB entries"
    @{fib_elements}    Create List    ${vpn_int_values[0]}    ${vpn_int_values[1]}    ${vpn_int_values[2]}    ${vpn_int_values[3]}
    Wait Until Keyword Succeeds    5s    1s    Ensure The Fib Entry Is Present    ${fib_elements}

    Log    "Validation Flows"
    Verify Flows Are Present    ${OS_COMPUTE_1_IP}    ${swdumpflows}
    Verify Flows Are Present    ${OS_COMPUTE_2_IP}    ${swdumpflows}

    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Verify FIB entries"
    @{fib_elements}    Create List    ${vpn_int_values[0]}    ${vpn_int_values[1]}    ${vpn_int_values[2]}    ${vpn_int_values[3]}
    Wait Until Keyword Succeeds    5s    1s    Ensure The Fib Entry Is Present    ${fib_elements}

    Log    "Validation Flows"
    Verify Flows Are Present    ${OS_COMPUTE_1_IP}    ${swdumpflows}
    Verify Flows Are Present    ${OS_COMPUTE_2_IP}    ${swdumpflows}

TC13 Verify Dissociate Network from VPN instance
    [Documentation]   Dissociate Network from VPN instance 
    [Tags]    Dissociate
    ${netid2}    vpn.Dissociate Network    ${NETWORK1}   ${L3VPN}
    Log    ${netid2}
    ${netid3}    vpn.Dissociate Network    ${NETWORK2}   ${L3VPN}
    Log    ${netid3}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}
    Log    "check if uuid of dissociated network is not found in DB"
    Should Not Contain    ${resp}    ${netid3}
    Log    "dissociated network not found in DB"

TC14 Verify Deletion of vpn instance
    [Documentation]   Delete VPN instance 
    [Tags]    Delete
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "Deleting vpn instance"  
    ${resp}    vpn.DeleteL3vpn    ${L3VPN}
    Log    "vpn instance deleted"  

    Log    "Verify FIB entry after delete"
    Sleep    30
    @{fib_elements}    Create List    ${vpn_int_values[0]}    ${vpn_int_values[1]}    ${vpn_int_values[2]}    ${vpn_int_values[3]}
    Wait Until Keyword Succeeds    5s    1s    Ensure The Fib Entry Is Removed    ${fib_elements}

    Log    "Validation Flows After Deleting VPN"
    Sleep    180
    Wait Until Keyword Succeeds    12s    2s    Verify Flows Are Removed    ${OS_COMPUTE_1_IP}    ${swdumpflows}
    Wait Until Keyword Succeeds    12s    2s    Verify Flows Are Removed    ${OS_COMPUTE_2_IP}    ${swdumpflows}

TC41 Deletion of L3vPN where network already associated with vpn 
    [Documentation]   Verify deletion of L3vPN where network already associated with vpn
    [Tags]    Delete
    ${exp_result}    ConvertToInteger    0
    Log    "Creating L3vpn"
    ${result}    vpn.Create L3vpn    ${L3VPN}    ${RD}    ${IMPORT_RT}    ${EXPORT_RT}
    Log    ${result}

    Log    "Associate network - to check "
    ${netid2}    vpn.Associate Network    ${NETWORK1}   ${L3VPN}
    ${netid3}    vpn.Associate Network    ${NETWORK2}   ${L3VPN}
    Log    ${netid2}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}

    Log    "Deleting vpn instance"  
    ${resp}    vpn.DeleteL3vpn    ${L3VPN}
    Log    "vpn instance deleted"  
    Log    ${resp}
 
TC15 Create Neutron Router
    [Documentation]    Verify neutron router creation
    ${exp_result}    ConvertToInteger    0
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC16 Add Interface to the Router
    [Documentation]    Verify router interface creation
    ${exp_result}    ConvertToInteger    0
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER_IF1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER_IF2}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    Log    "Verify E2E Datapath_Subnets_Associated to Router"
    ${resp}    Sleep    ${DELAY_2_BEFORE_PING}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

TC17 Delete Interface from Router
    [Documentation]    Verify router interface deletion
    ${exp_result}    ConvertToInteger    0
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER_IF1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER_IF2}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC18 Delete and recreate Interface on Router and check the datapath
    [Documentation]    Verify recreation of router interface
    ${exp_result}    ConvertToInteger    0
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER_IF1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER_IF2}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    Log    "Verify E2E Datapath_Subnets_Associated to Router"
    ${resp}    Sleep    ${DELAY_2_BEFORE_PING}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

TC29 Add Multiple Extra Routes and check Data path before L3VPN Creation
    [Documentation]    Verify adding extra route and check the datapath
    ${exp_result}    ConvertToInteger    0
   ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${ADD_EXTRA_ROUTES}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    Log    "Configure extra route ip on VM11 - extra route host-1"
    ${output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${CONFIG_EXTRA_ROUTE_IP1}    ${EXP_STR_IFCONFIG}
    Log    ${output}

    Log    "Configure extra route ip on VM22 - extra route host-2"
    ${output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_2_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX2}    ${CONFIG_EXTRA_ROUTE_IP2}    ${EXP_STR_IFCONFIG}
    Log    ${output}

    Log    "Verify datapath - extra route host-1"
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX2}    ${PING_EXTRA_ROUTE_IP1}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_2_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_EXTRA_ROUTE_IP1}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Verify datapath - extra route host-2"
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX2}    ${PING_EXTRA_ROUTE_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_2_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_EXTRA_ROUTE_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

TC30 Delete Extra Routes
    [Documentation]    Verify deletion of extra route
    ${exp_result}    ConvertToInteger    0
    Log    "Deleting the Extra Route"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DEL_EXTRA_ROUTE}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC31 Delete and Recreate Extra Route and check Datapath
    [Documentation]    Verify deletion and recreation of extra route and check the datapath
    ${exp_result}    ConvertToInteger    0
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${ADD_EXTRA_ROUTE1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    Log    "Configure the extra route ip on VM11"
    ${output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${CONFIG_EXTRA_ROUTE_IP1}    ${EXP_STR_IFCONFIG}
    Log    ${output}
    Log    "Verify datapath after adding extra route"
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX2}    ${PING_EXTRA_ROUTE_IP1}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_2_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_EXTRA_ROUTE_IP1}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Deleting the Extra Route"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DEL_EXTRA_ROUTE}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC19 Associate Router to L3VPN and check datapath
    [Tags]    Associate
    Log    "Creating L3vpn"
    ${vpnid-1}    vpn.Create L3vpn    ${L3VPN}    ${RD}    ${IMPORT_RT}    ${EXPORT_RT}
    Set Global Variable    ${vpnid-1}
    Log    ${vpnid-1}

    Log    "Verify/fetch vpn service from DB"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "L3vpn created is found  in DB"
    : FOR    ${value}    IN    @{vpn_values}
    \    Should Contain    ${resp}    ${value}
    Log    "L3vpn details are found in DB"

    ${router_id}    Get Router Ids
    Set Global Variable    ${router_id}
    Log    ${router_id}

    Log    "Associate router"
    ${routerid1}    vpn.Associate Router    ${router_id[0]}   ${vpnid-1} 
    Log    ${routerid1}

    Log    "Verify E2E Datapath_Subnets_Associated to Router"
    ${resp}    Sleep    ${DELAY_2_BEFORE_PING}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

TC32 Add multiple Extra Routes and check data path after L3VPN creation
    [Documentation]    Verify adding extra route and check the datapath
    ${exp_result}    ConvertToInteger    0
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${ADD_EXTRA_ROUTES}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    Log    "Verify datapath - extra route host-1"
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX2}    ${PING_EXTRA_ROUTE_IP1}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_2_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_EXTRA_ROUTE_IP1}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Verify datapath - extra route host-2"
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX2}    ${PING_EXTRA_ROUTE_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_2_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_EXTRA_ROUTE_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Deleting the Extra Routes"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DEL_EXTRA_ROUTE}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC20 Dissociate Router from L3VPN
    [Documentation]   Dissociate Router from VPN instance
    [Tags]    Dissociate
    ${exp_result}    ConvertToInteger    0
    ${routerid1}    vpn.Dissociate Router    ${router_id[0]}   ${vpnid-1}
    Log    ${routerid1}

    Log    "Verify Deletion of vpn instance"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "Deleting vpn instance"
    ${resp}    vpn.DeleteL3vpn    ${L3VPN}
    Log    "vpn instance deleted"


    Log    "Deleting the Extra Routes"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DEL_EXTRA_ROUTE}
    Log    ${resp}

    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER_IF1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER_IF2}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC21 Delete Neutron Router
    [Documentation]    Verify neutron router deletion
    ${exp_result}    ConvertToInteger    0

    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC22 Verify data path after delete and re-create VPN 
    [Documentation]   Verify data path after delete and re-create VPN
    [Tags]    Datapath
    Log    "Creating L3vpn"
    ${result}    vpn.Create L3vpn    ${L3VPN}    ${RD}    ${IMPORT_RT}    ${EXPORT_RT}
    Log    ${result}

    Log    "Verify/fetch vpn service from DB"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "L3vpn created is found  in DB"
    : FOR    ${value}    IN    @{vpn_values}
    \    Should Contain    ${resp}    ${value}
    Log    "L3vpn details are found in DB"

    Log    "Verify Association of network to vpn service and check from DB"
    Log    "Associate network"
    ${netid2}    vpn.Associate Network    ${NETWORK1}   ${L3VPN}
    ${netid3}    vpn.Associate Network    ${NETWORK2}   ${L3VPN}
    Log    ${netid2}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}

    Log    "check if uuid of associated network is found in DB"
    Should Contain    ${resp}    ${netid2}
    Should Contain    ${resp}    ${netid3}
    Log    "Associated network found in DB"

    ${resp}    Sleep    ${DELAY_2_BEFORE_PING}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Validation Flows"
    Verify Flows Are Present    ${OS_COMPUTE_1_IP}    ${swdumpflows}
    Verify Flows Are Present    ${OS_COMPUTE_2_IP}    ${swdumpflows}


TC23 Verify E2E Datapath after restart of OVS
    [Documentation]   Verify end to end data path within same network and from one network to the other    
    [Tags]    RestartOVS
    Log    "Restarting OVS1 and OVS2"
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_1_IP}    ${STOP_CMD}
    Log    ${output}
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_2_IP}    ${STOP_CMD}
    Log    ${output}
    Sleep    5
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_1_IP}    ${START_CMD}
    Log    ${output}
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_2_IP}    ${START_CMD}
    Log    ${output}
    Sleep    90
    Log    "Checking the OVS state and Flows after restart"
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_1_IP}    ${ovs-show}
    Log    ${output}
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_2_IP}    ${ovs-show}
    Log    ${output}
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_1_IP}    ${swdumpflows}
    Log    ${output}
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_2_IP}    ${swdumpflows}
    Log    ${output}
    
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Checking the OVS state and Flows after restart"
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_1_IP}    ${ovs-show}
    Log    ${output}
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_2_IP}    ${ovs-show}
    Log    ${output}
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_1_IP}    ${swdumpflows}
    Log    ${output}
    ${output}    vpn.Remotevmexec    ${OS_COMPUTE_2_IP}    ${swdumpflows}
    Log    ${output}
 

TC33_Association of router and network with same VPN
    [Documentation]    Verify Association of Router and Network with Same VPN
    ${exp_result}    ConvertToInteger    0
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER1}
    Log    ${resp}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER_IF1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER_IF2}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    ${router_id}    Get Router Ids
    Set Global Variable    ${router_id}
    Log    ${router_id}

    Log    "Associate router"
    ${routerid1}    vpn.Associate Router    ${router_id[0]}   ${L3VPN} 
    Log    ${routerid1}

TC34 Internal VPN Creation after deleting VPN where router associated with the VPN
    [Documentation]    Verify internal VPN creates successfully after deletion VPN where router and network associated with VPN
    ${exp_result}    ConvertToInteger    0
    Log    "Dissociate Network from VPN instance" 
    ${netid2}    vpn.Dissociate Network    ${NETWORK1}   ${L3VPN}
    Log    ${netid2}
    ${netid3}    vpn.Dissociate Network    ${NETWORK2}   ${L3VPN}
    Log    ${netid3}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}
    Log    "check if uuid of dissociated network is not found in DB"
    Should Not Contain    ${resp}    ${netid3}
    Log    "dissociated network not found in DB"

    Log    "Delete VPN instance"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "Deleting vpn instance"  
    ${resp}    vpn.DeleteL3vpn    ${L3VPN}
    Log    "vpn instance deleted"  

    Log    "Verify Datapath after deletion VPN where router and network associated with VPN"
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Validation Flows"
    Verify Flows Are Present    ${OS_COMPUTE_1_IP}    ${swdumpflows}
    Verify Flows Are Present    ${OS_COMPUTE_2_IP}    ${swdumpflows}

    Log    "Verify router interface deletion"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER_IF1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER_IF2}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    Log    "Deleting the router after delting the vpn instance"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER1}
    Log    ${resp}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC35 Verify Creation of multiple VPN 
    [Documentation]   Verify Creation of multiple VPN   
    [Tags]    Post
    ${exp_result}    ConvertToInteger    0
    Log    "Creating 1st L3vpn"
    ${result}    vpn.Create L3vpn    ${L3VPN}    ${RD}    ${IMPORT_RT}    ${EXPORT_RT}
    Log    ${result}
    Log    "Creating 2nd L3vpn"
    ${result}    vpn.Create L3vpn    ${L3VPN2}    ${RD2}    ${IMPORT_RT2}    ${EXPORT_RT2}
    Log    ${result}

TC36 Data path between multi vpn with Network Attached
    [Documentation]   Verify data path between multi vpn with Network Attached   
    [Tags]    Post
    ${exp_result}    ConvertToInteger    0
    Log    "Verify Association of network to vpn service and check from DB"
    Log    "Associate network"
    ${netid2}    vpn.Associate Network    ${NETWORK1}   ${L3VPN}
    ${netid3}    vpn.Associate Network    ${NETWORK2}   ${L3VPN}
    #${netid3}    vpn.Associate Network    ${NETWORK2}   ${L3VPN2}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}

    Log    "check if uuid of associated network is found in DB"
    Should Contain    ${resp}    ${netid2}
    Should Contain    ${resp}    ${netid3}
    Log    "Associated network found in DB"

    Log    "Checking data path after NW association"
    ${resp}    Sleep    ${DELAY_2_BEFORE_PING}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Dissociate Networks"
    ${netid2}    vpn.Dissociate Network    ${NETWORK1}   ${L3VPN}
    Log    ${netid2}
    ${netid3}    vpn.Dissociate Network    ${NETWORK2}   ${L3VPN}
    Log    ${netid3}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}
    Log    "check if uuid of dissociated network is not found in DB"
    Should Not Contain    ${resp}    ${netid3}
    Log    "dissociated network not found in DB"

TC37 Verify data path between multi vpn with Router Attached 
    [Documentation]   Verify data path between multi vpn with Router Attached   
    [Tags]    Post

    ${exp_result}    ConvertToInteger    0
    Log    "Creating router"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    Log    "Verify router interface creation"
    ${exp_result}    ConvertToInteger    0
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER_IF1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${CREATE_ROUTER_IF2}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    ${router_id}    Get Router Ids
    Set Global Variable    ${router_id}
    Log    ${router_id}

    Log    "Associate router"
    ${routerid1}    vpn.Associate Router    ${router_id[0]}   ${L3VPN} 
    Log    ${routerid1}

    Log    "Checking data path after router association"
    ${resp}    Sleep    ${DELAY_2_BEFORE_PING}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Dissociate router"
    ${routerid1}    vpn.Dissociate Router    ${router_id[0]}   ${L3VPN}
    Log    ${routerid1}

TC38 Data path between multi vpn with Networks And Router Attached
    [Documentation]   Verify data path between multi vpn with Networks And Router Attached   
    [Tags]    Post
    Log    "Verify Association of network to vpn service and check from DB"
    Log    "Associate network"
    ${netid2}    vpn.Associate Network    ${NETWORK1}   ${L3VPN}
    ${netid3}    vpn.Associate Network    ${NETWORK2}   ${L3VPN}
    #${netid3}    vpn.Associate Network    ${NETWORK2}   ${L3VPN2}
    Log    ${netid2}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}

    Log    "Associate router"
    ${routerid1}    vpn.Associate Router    ${router_id[0]}   ${L3VPN} 
    Log    ${routerid1}

    Log    "Checking data path after router association"
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP3}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    Log    "Dissociate Networks"
    ${netid2}    vpn.Dissociate Network    ${NETWORK1}   ${L3VPN}
    Log    ${netid2}
    ${netid3}    vpn.Dissociate Network    ${NETWORK2}   ${L3VPN}
    #${netid3}    vpn.Dissociate Network    ${NETWORK2}   ${L3VPN2}
    Log    ${netid3}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}
    Log    "check if uuid of dissociated network is not found in DB"
    Should Not Contain    ${resp}    ${netid3}
    Log    "dissociated network not found in DB"

TC39 Deletion of L3vPN where Router already associated with it
    [Documentation]    Verify deletion of L3vPN where Router already associated with it 
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete 

    Log    "Verify Deletion of vpn instance"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "Deleting vpn instance"
    ${resp}    vpn.DeleteL3vpn    ${L3VPN}
    Log    ${resp}
    Log    "vpn instance deleted"

    ${resp}    vpn.DeleteL3vpn    ${L3VPN2}
    Log    ${resp}
    Log    "vpn instance deleted"


TC40 Co-existance of l3vpn and ELAN service across DPN with Vxlan 
    [Documentation]    Verify Co-existance of l3vpn and ELAN service across  DPN with Vxlan 
    ${exp_result}    ConvertToInteger    0
    #[Tags]    
    Log    "Check traffic after deletion of VPN and verify that it takes ELAN path"
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX1}    ${PING_IP2}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}
    ${ping_output}    vpn.Run Command Nova Vm    ${OS_COMPUTE_1_IP}    ${DEFAULT_PASSWORD}    ${VM_INDX2}    ${PING_IP4}    ${EXP_STR}
    Log    ${ping_output}
    Should Match Regexp    ${ping_output}    ${PING_REGEX}

    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER_IF1}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER_IF2}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_ROUTER1}
    Log    ${resp}
    Log    ${resp}
    Should Not Be Equal    ${resp}    ${exp_result}

TC24 Verify neutron Port Deletion
    [Documentation]    Verify neutron Port Deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Delete Port"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_VM11}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_VM21}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_VM12}
    Log    ${resp}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_VM22}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_PORT11}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_PORT21}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_PORT12}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_PORT22}
    Log    ${resp}

    Log    "Get available ports"
    ${resp}    vpn.Get Ports
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}


TC25 Verify neutron Subnet Deletion
    [Documentation]    Verify neutron Subnet Deletion
    [Tags]    Delete
    Log    "Delete Subnet Netowrk"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_SUBNET1}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_SUBNET2}
    Log    ${resp}
    Log    "Get available Subnets"
    ${resp}    vpn.Get Subnets
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}


TC26 Verify neutron network Deletion
    [Documentation]    Verify neutron network Deletion
    #${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Delete Netowrk"
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_NET1}
    Log    ${resp}
    ${resp}    Create_OpenStack_Entity    ${OS_CONTROL_NODE_IP}    ${STK_UNAME}    ${STK_PWD}    ${DELETE_NET2}
    Log    ${resp}
    Log    "Get available Networks"
    ${resp}    vpn.Get Networks
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}

TC27 Verify fetching TUNNELS
    [Documentation]   Verify fetching Tunnels 
    ${exp_result}    ConvertToInteger   200 
    [Tags]    Get
    Log    "Fetching the tunnels"
    ${resp}    vpn.Get All Tunnels
    Log    ${resp}
    Should Be Equal    ${resp.status_code}    ${exp_result}

TC28 Verify TUNNEL deletion
    [Documentation]   Verify Tunnel deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Deleting the tunnel"
    ${resp}    vpn.Delete All Tunnels
    Log    ${resp}
    Should Be Equal    ${resp}    ${exp_result}
    Sleep    3

*** Keywords ***
Create_OpenStack_Entity
    [Arguments]    ${HOST}    ${USERNAME}    ${PASSWORD}    ${CMD}
    ${connection_handle}=    SSHLibrary.Open Connection    ${HOST}
    Set Client Configuration    prompt=$
    SSHLibrary.Login    ${USERNAME}    ${PASSWORD}
    SSHLibrary.Write    cd devstack
    Set Client Configuration    prompt=$
    SSHLibrary.Write    source openrc admin admin 
    Sleep    2
    Set Client Configuration    prompt=$
    SSHLibrary.Write    ${CMD}
    Sleep    14
    Set Client Configuration    prompt=$
    ${output}=    SSHLibrary.Read Until Prompt
    Close Connection
    [Return]    ${output}

Verify Flows Are Present
    [Arguments]    ${HOST}    ${CMD}
    [Documentation]    Succeeds if the flows for vpn service are present
    ${output}    vpn.Remotevmexec    ${HOST}    ${CMD}
    Log    ${output}
    ${resp}    Should Match Regexp    ${output}    ${TABLE17_TO_21_REGEX}
    Log    ${resp}
    ${resp}    Should Match Regexp    ${output}    ${TABLE20_REGEX}
    Log    ${resp}
    ${resp}    Should Match Regexp    ${output}    ${TABLE21_REGEX_1}
    Log    ${resp}
    ${resp}    Should Match Regexp    ${output}    ${TABLE21_REGEX_2}
    Log    ${resp}
    ${resp}    Should Match Regexp    ${output}    ${TABLE21_REGEX_3}
    Log    ${resp}
    ${resp}    Should Match Regexp    ${output}    ${TABLE21_REGEX_4}
    Log    ${resp}

Verify Flows Are Removed
    [Arguments]    ${HOST}    ${CMD}
    [Documentation]    Succeeds if the flows for vpn service are present
    ${output}    vpn.Remotevmexec    ${HOST}    ${CMD}
    Log    ${output}
    Should Not Match Regexp    ${output}    ${TABLE20_REGEX}
    Should Not Match Regexp    ${output}    ${TABLE21_REGEX_1}
    Should Not Match Regexp    ${output}    ${TABLE21_REGEX_2}
    Should Not Match Regexp    ${output}    ${TABLE21_REGEX_3}
    Should Not Match Regexp    ${output}    ${TABLE21_REGEX_4}

Ensure The Fib Entry Is Present
    [Arguments]    ${prefixes}
    [Documentation]    Will succeed if the fib entry is present for the vpn
    ${resp}    RequestsLibrary.Get    session    /restconf/config/odl-fib:fibEntries/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    #Should Contain    ${resp.content}    ${prefixes}
    : FOR    ${i}    IN    @{prefixes}
    \    Should Contain    ${resp.content}    ${i}
    Should Contain    ${resp.content}    label

Ensure the Fib Entry Is Removed
    [Arguments]    ${prefixes}
    [Documentation]    Will succeed if the fib entry is removed for the vpn
    ${resp}    RequestsLibrary.Get    session    /restconf/config/odl-fib:fibEntries/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    #Should Not Contain    ${resp.content}    ${prefixes}
    : FOR    ${i}    IN    @{prefixes}
    \    Should Not Contain    ${resp.content}    ${i}
