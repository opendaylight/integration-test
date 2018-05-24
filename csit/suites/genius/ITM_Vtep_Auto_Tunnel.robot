*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       DevstackUtils.Devstack Suite Setup
Library           DebugLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../variables/Variables.py
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Resource          ../../libraries/VpnOperations.robot

*** Variables ***
@{COMPUTE-NODE-LIST}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
${CREATE_TUNNEL_VXLAN}    curl --silent -u ${ODL_RESTCONF_USER}:${ODL_RESTCONF_PASSWORD} -X POST -H "Content-Type:application/json" -d @${JSON_DIR} "http://${OS_CONTROL_NODE_IP}:8181/restconf/config/itm:transport-zones/"
${DEFAULT_TRANSPORT_ZONE}    default-transport-zone
@{EXTERNAL_NETWORKS}    itm_ext_1    itm_ext_2
@{EXTERNAL_SUB_NETWORKS}    itm_ext_sub_1    itm_ext_sub_2
@{EXT_SUBNET_CIDRS}    100.100.100.0/24    200.200.200.0/24
${GET_NETWORK_TOPOLOGY}    /restconf/operational/network-topology:network-topology/topology/ovsdb:1/
${GET_DEFAULT_ZONE}    /restconf/config/itm:transport-zones/transport-zone/${DEFAULT_TRANSPORT_ZONE}
${GET_TRANSPORT_ZONE}    /restconf/config/itm:transport-zones/transport-zone/${TRANSPORT_ZONE}
${JSON_DIR}       /opt/CSIT_sdnctest/integration/test/csit_community_2/variables/netvirt/itm_creation.json
@{LOCAL_IP}       192.168.113.222    192.168.113.223
@{NET_1_VMS}      itm_vm_1    itm_vm_2    itm_vm_3    itm_vm_4
@{NETWORKS}       itm_net_1    itm_net_2    itm_net_3    itm_net_4
#${OS_CONTROL_NODE_IP}    192.168.56.101
#${OS_USER}       stack
@{PORTS}          itm_port_1    itm_port_2    itm_port_3    itm_port_4
${SECURITY_GROUP}    itm_sg
@{SUBNETS}        itm_subnet_1    imt_subnet_2    itm_subnet_3
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24    40.1.1.0/24    50.1.1.0/24
${TEPNOTHOSTED_ZONE}    /restconf/config/itm:transport-zones/tepsNotHostedInTransportZone/${TRANSPORT_ZONE}
${TEP_SHOW}       tep:show
${TRANSPORT_ZONE}    TZA
${TUNNEL_LIST}    /restconf/operational/itm-state:tunnel-list
${TUNNEL_CONF_LIST}    /restconf/config/itm-state:tunnel-list
${TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan
@{BOOL_VALUES}    true    false
#${USER_HOME}     /home/stack

*** Test Cases ***
TC01_7.1.2 & 7.1.8 & 7.1.15 verify TEP IP and transport zone in OVSDB table of CSS(v5) vSwitch
    [Documentation]    loging to all compuet nodes and Dump OVSDB tables,check for default TEP IP and Transport-zone name Verify ‘default-transport-zone’ zone name GET ‘/restconf/config/itm:transport-zones/’
    Get Ovs Version    @{COMPUTE-NODE-LIST}
    Check Local Ip    @{COMPUTE-NODE-LIST}[0]
    Check Local Ip    @{COMPUTE-NODE-LIST}[1]
    ${DPN1}    Get Dpn Ids    ${OS_CMP1_CONN_ID}
    set suite variable    ${DPN1}
    ${DPN2}    Get Dpn Ids    ${OS_CMP2_CONN_ID}
    set suite variable    ${DPN2}
    Log    Verify ‘default-transport-zone’ zone name GET ‘/restconf/config/itm:transport-zones/’
    ${ITM-DATA}    ITM Get Tunnels
    #should contain    ${ITM-DATA}    ${DEFAULT_TRANSPORT_ZONE}
    Should Contain Any    ${ITM-DATA}    ${DEFAULT_TRANSPORT_ZONE}    ${DPN1}    ${DPN2}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}
    Create Port    @{NETWORKS}[0]    @{PORTS}[2]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${vm1_ip}    ${dhcp1}    ${console} =    Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Get VM IP
    ...    true    @{NET_1_VMS}[0]
    ${vm2_ip}    ${dhcp2}    ${console1} =    Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Get VM IP
    ...    true    @{NET_1_VMS}[1]
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    Should Contain    ${output}    ,0% packet loss

C07_7.2.1 & TC09_7.3.3 & TC09_7.3.4 & 7.4.1 Verify TEPs with transport zone configured from CSS will be added to corresponding transport zone
    [Documentation]    Verify TEPs with transport zone configured from CSS will be added to corresponding transport zone, Verify mandatory parameters for TEP configuration on CSC as transport zone name and tunnel type
    ${status}    Run Keyword And Return Status    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    ${Match}    Convert To String    ${status}
    Should Be Equal    ${Match}    False
    Change Transport Zone In Css    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    ${ITM_DATA}    Get Csc Datastore    ${TEPNOTHOSTED_ZONE}
    should contain any    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${DPN1}
    Create Tunnel    ${CREATE_TUNNEL_VXLAN}
    ${ITM_DATA}    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    should contain    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${DPN1}
    #Change Transport Zone In Css    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    Change Transport Zone In Css    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Check Local Ip    ${node}
    \    Check Transport Zone    ${node}    ${TRANSPORT_ZONE}
    ${IP1}    Get Local Ip    @{COMPUTE-NODE-LIST}[0]
    set suite variable    ${IP1}
    ${IP2}    Get Local Ip    @{COMPUTE-NODE-LIST}[1]
    set suite variable    ${IP2}
    #${ITM_DATA}    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    should contain any    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}

TC02_7.1.3 & 7.1.4 Verify other-config-key:local_ip and transport zone value in CSC operational datastore when CSS is connected to CSC
    [Documentation]    check and validate “/restconf/operational/network-topology:network-topology/topology/ovsdb:1/” for “local_ip” and transport-zone value from csc datastore
    ${csc-data}    Get Csc Datastore    ${GET_NETWORK_TOPOLOGY}
    # ${IP1}    Get Local Ip    @{COMPUTE-NODE-LIST}[0]
    # set suite variable    ${IP1}
    # ${IP2}    Get Local Ip    @{COMPUTE-NODE-LIST}[1]
    # set suite variable    ${IP2}
    should contain any    ${csc-data}    "other-config-value":"${IP1}"    "other-config-value":"${IP2}"    "external-id-value":"${TRANSPORT_ZONE}"

TC06_7.1.12 & TC08_7.3.2 Delete transport zone:TZA on CSS and check ovsdb update to CSC
    [Documentation]    To verify transport zone moves to tepsNotHostedInTransportZone after deleting in css
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Delete Transport Zone In Css    ${node}
    Verify With Default Zone
    ITM Delete Tunnel    ${TRANSPORT_ZONE}
    ${ITM_DATA}    Get Csc Datastore    ${GET_DEFAULT_ZONE}
    should not contain    ${ITM_DATA}    ${TRANSPORT_ZONE}
    should contain any    ${ITM_DATA}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}
    #    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    #    should contain    ${output}    0% packet loss

TC05_7.1.10 & 7.6.1 & 7.4.2 & 7.1.14 Update local_ip in CSS and reconnect
    [Documentation]    To verify local_ip in CSS after reconnect
    Change Local Ip    @{COMPUTE-NODE-LIST}[0]    @{LOCAL_IP}[0]
    Change Local Ip    @{COMPUTE-NODE-LIST}[1]    @{LOCAL_IP}[1]
    ${ITM_DATA}    Get Csc Datastore    ${GET_DEFAULT_ZONE}
    should contain any    ${ITM_DATA}    @{LOCAL_IP}[0]    @{LOCAL_IP}[1]    ${DPN1}    ${DPN2}
    Reconnect Css With Zone Change    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}    ${IP1}
    Reconnect Css With Zone Change    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}    ${IP2}
    ${csc-data}    Get Csc Datastore    ${TEPNOTHOSTED_ZONE}
    should contain any    ${csc-data}    ${TRANSPORT_ZONE}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}
    ${status}    Run Keyword And Return Status    Get Csc Datastore    ${TUNNEL_LIST}
    ${Match}    Convert To String    ${status}
    Should Be Equal    ${Match}    False

Verify the configuration and tunnel details are persist across multiple controller/CSS restarts
    [Documentation]    Verify transport zone configured by CSS register with CSC but no tunnel formation
    ${tunnels_pre_reebot}    Get Csc Datastore    ${TUNNEL_CONF_LIST}
    Restart_Karaf
    ${tunnels_post_reebot}    Get Csc Datastore    ${TUNNEL_CONF_LIST}
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Restart OVSDB    ${node}
    ${tunnels_post_reebot}    Get Csc Datastore    ${TUNNEL_CONF_LIST}
    Should Be Equal    ${tunnels_post_reebot}    ${tunnels_post_reebot}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    should contain    ${output}    0% packet loss

*** Keywords ***
Delete Transport Zone In Css
    [Arguments]    ${compute_ip}
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl remove O . external_ids transport-zone

Create Tunnel
    [Arguments]    ${cmd}
    [Documentation]    create tunnel with type vxlan
    ${output}    OperatingSystem.Run And Return Rc And Output    ${cmd}
    log    ${output}
    [Return]    ${output}

Verify With Default Zone
    [Documentation]    Verify that the tunnels are UP
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${DEFAULT_TRANSPORT_ZONE}
    Should Not Contain    ${output}    ${TRANSPORT_ZONE}

Change Transport Zone In Css
    [Arguments]    ${compute_ip}    ${transport_zone}
    [Documentation]    Change transport zone in CSS
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl set O . external_ids:transport-zone=${transport_zone}
    Check Transport Zone    ${compute_ip}    ${transport_zone}

Get Ovs Version
    [Arguments]    @{compute_nodes}
    : FOR    ${ ip}    IN    @{compute_nodes}
    \    ${output}    Run Command On Remote System    ${ip}    sudo ovs-vsctl show
    \    log    ${output}
    \    should contain    ${output}    ovs_version: "2.8.1"

Check Local Ip
    [Arguments]    ${compute_node}
    ${localip}    Get Local Ip    ${compute_node}
    ${output}    Run Command On Remote System    ${compute_node}    sudo ovsdb-client dump -f list Open_vSwitch | grep other_config
    should contain    ${output}    ${localip}
    log    ${output}

Remove Local Ip
    [Arguments]    ${compute_node}
    ${localip}    Get Local Ip    ${compute_node}
    ${output}    Run Command On Remote System    ${compute_node}    sudo ovs-vsctl remove O . other_config local_ip

Change Local Ip
    [Arguments]    ${compute_node}    ${local_ip}
    ${output}    Run Command On Remote System    ${compute_node}    sudo ovs-vsctl set O . other_config:local_ip=${local_ip}
    ${localip}    Get Local Ip    ${compute_node}
    Should Be Equal    ${localip}    ${local_ip}
    log    ${output}

Check Transport Zone
    [Arguments]    ${compute_node}    ${transport-zone}
    ${output}    Run Command On Remote System    ${compute_node}    sudo ovsdb-client dump -f list Open_vSwitch | grep external_ids
    log    ${output}
    should contain    ${output}    ${transport-zone}

Get Local Ip
    [Arguments]    ${ip}
    ${cmd-output}    Run Command On Remote System    ${ip}    sudo ovsdb-client dump -f list Open_vSwitch | grep local_ip | awk '{print $3}'
    ${localip}    Get Regexp Matches    ${cmd-output}    (\[0-9]+\.\[0-9]+\.\[0-9]+\.\[0-9]+)
    [Return]    ${localip[0]}

Get Csc Datastore
    [Arguments]    ${url}
    [Documentation]    Get all Tunnels and return the contents
    ${resp} =    RequestsLibrary.Get Request    session    ${url}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Reconnect Css With Zone Change
    [Arguments]    ${compute_ip}    ${transport_zone}    ${local_ip}
    ${manager}    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl show | grep Manager | awk '{print $2}'
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl del-manager
    Remove Local Ip    ${compute_ip}
    Change Local Ip    ${compute_ip}    ${local_ip}
    Change Transport Zone In Css    ${compute_ip}    ${transport_zone}
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl set-manager "tcp:${OS_CONTROL_NODE_IP}:6640"
    ${cmd-output1}    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl show | grep Manager | awk '{print $2}'
    should contain    ${cmd-output1}    ${OS_CONTROL_NODE_IP}

Migrate VM Instance
    [Arguments]    ${vm_name}
    [Documentation]    Show information of a given VM and grep for instance id. VM name should be sent as arguments.
    ${devstack_conn_id} =    Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    nova migrate --poll ${vm_name}    60s
    Sleep    60s
    ${output} =    Write Commands Until Prompt    nova resize-confirm ${vm_name}    30s
    SSHLibrary.Close Connection
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${vm_name}

Clean Config
    [Documentation]    Delete's all the configuration created by script.
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    : FOR    ${VmInstance}    IN    @{NET_1_VMS}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VmInstance}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Run Keyword And Ignore Error    Remove Interface    ${ROUTER}    ${Subnet}
    : FOR    ${Port}    IN    @{PORTS}
    \    Run Keyword And Ignore Error    Delete Port    ${Port}
    Delete Router    ${ROUTER}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${Subnet}
    : FOR    ${ExtSubnet}    IN    @{EXTERNAL_SUB_NETWORKS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${ExtSubnet}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${Network}
    : FOR    ${Network}    IN    @{EXTERNAL_NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${Network}
    Delete SecurityGroup    ${SECURITY_GROUP}
