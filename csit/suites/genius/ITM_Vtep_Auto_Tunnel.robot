*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       DevstackUtils.Devstack Suite Setup
Library           OperatingSystem
Library           DebugLibrary
Library           RequestsLibrary
Resource          /home/stack/test/csit/libraries/Utils.robot
Resource          /home/stack/test/csit/libraries/Genius.robot
Resource          /home/stack/test/csit/libraries/OpenStackOperations.robot
Resource          /home/stack/test/csit/libraries/DevstackUtils.robot
Resource          /home/stack/test/csit/libraries/VpnOperations.robot
Resource          /home/stack/test/csit/libraries/OVSDB.robot
Resource          /home/stack/test/csit/libraries/SetupUtils.robot
Resource          /home/stack/test/csit/variables/Variables.robot
Library           /home/stack/test/csit/variables/Variables.py
Resource          /home/stack/test/csit/libraries/KarafKeywords.robot

*** Variables ***
${SECURITY_GROUP}    vpn_sg
@{NETWORKS}       net_1    net_2    net_3    net_4
@{EXTERNAL_NETWORKS}    ext_1    ext_2
@{EXTERNAL_SUB_NETWORKS}    ext_sub_net_1    ext_sub_net_2
@{SUBNETS}        sub_net_1    sub_net_2    sub_net_3    sub_net_4
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24    40.1.1.0/24    50.1.1.0/24
@{EXT_SUBNET_CIDRS}    100.100.100.0/24    200.200.200.0/24
@{BOOL_VALUES}    true    false
${NETWORK_TYPE}    gre
@{PORTS}          port_1    port_2    port_3    port_4    port_5    port_6    port_7
...               port_8
@{NET_1_VMS}      vm_1    vm_2    vm_3    vm_4    vm_5    vm_6    vm_7
...               vm_8
${ROUTER}         router1
@{cmd_list}       clone_p_ntf_server    clone_p_node-monitor    #clone_p_ClusterMon    clone_p_sdnc-service    p_qbgp-service
@{COMPUTE-NODE-LIST}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_1_IP}
${GET_NETWORK_TOPOLOGY}    /restconf/operational/network-topology:network-topology/topology/ovsdb:1/
${TRANSPORT_ZONE}    TZA
@{LOCAL_IP}       192.168.113.222    192.168.113.223
${OS_CONTROL_NODE_IP}    192.168.56.101
${DEFAULT_TRANSPORT_ZONE}    default-transport-zone
${GET_DEFAULT_ZONE}    /restconf/config/itm:transport-zones/transport-zone/${DEFAULT_TRANSPORT_ZONE}
${TUNNEL_LIST}    /restconf/operational/itm-state:tunnel-list
${TUNNEL_CONF_LIST}    /restconf/config/itm-state:tunnel-list
${TEPNOTHOSTED_ZONE}    /restconf/config/itm:transport-zones/tepsNotHostedInTransportZone/${TRANSPORT_ZONE}
${TEP_SHOW}       tep:show
${JSON_DIR}       /opt/CSIT_sdnctest/integration/test/csit_community_2/variables/netvirt/itm_creation.json
${CREATE_TUNNEL_VXLAN}    curl --silent -u ${ODL_RESTCONF_USER}:${ODL_RESTCONF_PASSWORD} -X POST -H "Content-Type:application/json" -d @${JSON_DIR} "http://${OS_CONTROL_NODE_IP}:8181/restconf/config/itm:transport-zones/"
${OS_USER}        stack
${USER_HOME}      /home/stack
${TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan
${GET_TRANSPORT_ZONE}    /restconf/config/itm:transport-zones/transport-zone/${TRANSPORT_ZONE}
${ClusterManagement__index_to_ip_mapping}    1

*** Test Cases ***
TC01_7.1.2 & 7.1.8 & 7.1.15 verify TEP IP and transport zone in OVSDB table of CSS(v5) vSwitch
    [Documentation]    loging to all compuet nodes and Dump OVSDB tables,check for default TEP IP and Transport-zone name Verify ‘default-transport-zone’ zone name GET ‘/restconf/config/itm:transport-zones/’
    get ovs version    @{COMPUTE-NODE-LIST}
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
    #    Log    create vm's and ping between vms to verift default tunnel
    #    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    #    OpenStackOperations.Create Network    @{NETWORKS}[0]
    #    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    #    OpenStackOperations.Create Network    @{NETWORKS}[1]
    #    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    #    #Create Ext Network    @{EXTERNAL_NETWORKS}[0]    @{BOOL_VALUES}[0]    ${NETWORK_TYPE}
    #    #OpenStackOperations.Create SubNet    @{EXTERNAL_NETWORKS}[0]    @{EXTERNAL_SUB_NETWORKS}[0]    @{EXT_SUBNET_CIDRS}[0]
    #    Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}
    #    Create Port    @{NETWORKS}[0]    @{PORTS}[2]    sg=${SECURITY_GROUP}
    #    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    #    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_1_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    #    #OpenStackOperations.Create Router    ${ROUTER}
    #    #OpenStackOperations.Add Router Interface    ${ROUTER}    @{SUBNETS}[0]
    #    #OpenStackOperations.Add Router Interface    ${ROUTER}    @{SUBNETS}[1]
    #    ${vm1_ip}    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{NETWORKS}[0]
    ...    # @{NET_1_VMS}[0]
    #    ${vm2_ip}    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{NETWORKS}[0]
    ...    # @{NET_1_VMS}[0]
    #    sleep    40s
    #    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    #    should contain    ${output}    0% packet loss

C07_7.2.1 & TC09_7.3.3 & TC09_7.3.4 & 7.4.1 Verify TEPs with transport zone configured from CSS will be added to corresponding transport zone
    [Documentation]    Verify TEPs with transport zone configured from CSS will be added to corresponding transport zone, Verify mandatory parameters for TEP configuration on CSC as transport zone name and tunnel type
    ${status}    Run Keyword And Return Status    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    ${Match}    Convert To String    ${status}
    Should Be Equal    ${Match}    False
    Change Transpot Zone in CSS    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    ${ITM_DATA}    Get Csc Datastore    ${TEPNOTHOSTED_ZONE}
    should contain any    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${DPN1}
    Create tunnel    ${CREATE_TUNNEL_VXLAN}
    ${ITM_DATA}    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    should contain    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${DPN1}
    #Change Transpot Zone in CSS    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    Change Transpot Zone in CSS    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}
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
    \    Delete transport zone in css    ${node}
    Verify Tunnel with default zone
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
    Reconnect css with zone change    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}    ${IP1}
    Reconnect css with zone change    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}    ${IP2}
    ${csc-data}    Get Csc Datastore    ${TEPNOTHOSTED_ZONE}
    should contain any    ${csc-data}    ${TRANSPORT_ZONE}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}
    ${status}    Run Keyword And Return Status    Get Csc Datastore    ${TUNNEL_LIST}
    ${Match}    Convert To String    ${status}
    Should Be Equal    ${Match}    False
    #TC10_7.4.1 Verify auto mapping of CSS to corresponding transport zone group when TZ name is changed in one of the switch and full mesh tunnel formation
    #    [Documentation]    Verify auto mapping of CSS to corresponding transport zone group when TZ name is changed in one of the switch and full mesh tunnel formation
    #
    #
    #
    #TC11_7.4.2 Verify TEP local ip address delete will delete the tunnels
    #    Delete transport zone in css    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    #    ${ITM_DATA}    Get Csc Datastore    /restconf/config/itm-state:tunnel-list/default-transport-zone
    #    should contain    ${ITM_DATA}    ${IP1}
    #
    #TC13_7.6.1 Verify transport zone configured by CSS register with CSC but no tunnel formation
    #    [Documentation]    Verify transport zone configured by CSS register with CSC but no tunnel formation
    #    :FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    #    Run Command On Remote System    ${node}    ${css_tz_create}
    #    ${tep_nohosted}    Get Csc Datastore    ${TEPNOTHOSTED_ZONE}
    #    should contain    ${tep_nohosted}    ${IP1}
    #    should contain    ${tep_nohosted}    ${IP2}

C12_7.7.1 Verify the configuration and tunnel details are persist across multiple controller/CSS restarts
    [Documentation]    Verify transport zone configured by CSS register with CSC but no tunnel formation
    ${tunnels_pre_reebot}    Get Csc Datastore    ${TUNNEL_CONF_LIST}
    #    Restart_Karaf
    #${tunnels_post_reebot}    Get Csc Datastore    ${TUNNEL_CONF_LIST}
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Restart OVSDB    ${node}
    ${tunnels_post_reebot}    Get Csc Datastore    ${TUNNEL_CONF_LIST}
    Should Be Equal    ${tunnels_post_reebot}    ${tunnels_post_reebot}
    #    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    #    should contain    ${output}    0% packet loss

*** Keywords ***
Delete transport zone in css
    [Arguments]    ${compute_ip}
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl remove O . external_ids transport-zone

Create tunnel
    [Arguments]    ${cmd}
    [Documentation]    create tunnel with type vxlan
    ${output}    OperatingSystem.Run And Return Rc And Output    ${cmd}
    log    ${output}
    [Return]    ${output}

Verify Tunnel with default zone
    [Documentation]    Verify that the tunnels are UP
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${DEFAULT_TRANSPORT_ZONE}
    Should Not Contain    ${output}    ${TRANSPORT_ZONE}

Change Transpot Zone in CSS
    [Arguments]    ${compute_ip}    ${transport_zone}
    [Documentation]    Change transport zone in CSS
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl set O . external_ids:transport-zone=${transport_zone}
    Check Transport Zone    ${compute_ip}    ${transport_zone}

get ovs version
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

Reconnect css with zone change
    [Arguments]    ${compute_ip}    ${transport_zone}    ${local_ip}
    ${manager}    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl show | grep Manager | awk '{print $2}'
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl del-manager
    Remove Local Ip    ${compute_ip}
    Change Local Ip    ${compute_ip}    ${local_ip}
    Change Transpot Zone in CSS    ${compute_ip}    ${transport_zone}
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

Add External Network To Router
    [Arguments]    ${r_name}    ${ext_net_name}    ${additional_args}=${EMPTY}
    [Documentation]    Adds external network to router
    ${output} =    Write Commands Until Prompt    neutron router-gateway-set ${r_name} ${ext_net_name} ${additional_args}    30s
    Should Contain    ${output}    Set gateway for router
    [Return]    ${output}

Get External Ip From Router
    [Arguments]    ${router_name}
    [Documentation]    Gets external ip associated to router
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ip}=    Write Commands Until Prompt    openstack router show ${router_name} | grep ip_address | awk '{print $12}'    30s
    ${flt_ip}    Should Match Regexp    ${ip}    [0-9]\.+
    @{vm}    Split String    ${flt_ip}    "
    ${flt_out}    Set Variable    ${vm[0]}
    [Return]    ${flt_out}

Verify Telnet Status
    [Arguments]    ${net}    ${vm_ip1}    ${ip}    ${telnet_regx}
    [Documentation]    Telnet's from given vm to distined ip and check the status
    ${output}=    Wait Until Keyword Succeeds    180s    10s    OpenStackOperations.Execute Command on VM Instance    ${net}    ${vm_ip1}
    ...    telnet ${ip}
    Should Contain    ${output}    ${telnet_regx}
    [Return]    ${output}

Clear Router Gateway
    [Arguments]    ${router_name}    ${external_network_name}    ${additional_args}=${EMPTY}
    [Documentation]    Clear's gateway configuration from router
    ${output}=    Write Commands Until Prompt    neutron router-gateway-clear ${router_name} ${external_network_name} ${additional_args}    30s
    Should Contain    ${output}    Removed gateway from router
    [Return]    ${output}

Clean Config
    [Documentation]    Delete's all the configuration created by script.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    Delete vpns
    : FOR    ${vpn}    IN    @{VPN_NAMES}
    \    Run Keyword And Ignore Error    Delete L3vpn    ${vpn}
    Log    Delete the VM instances
    : FOR    ${VmInstance}    IN    @{NET_1_VMS}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VmInstance}
    Log    Delete Interface From Router
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Run Keyword And Ignore Error    Remove Interface    ${ROUTER}    ${Subnet}
    Log    Delete neutron ports
    : FOR    ${Port}    IN    @{PORTS}
    \    Run Keyword And Ignore Error    Delete Port    ${Port}
    Log    Delete Routers
    Delete Router    ${ROUTER}
    Log    Delete subnets
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${Subnet}
    Log    Delete External Subnets
    : FOR    ${ExtSubnet}    IN    @{EXTERNAL_SUB_NETWORKS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${ExtSubnet}
    Log    Delete networks
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${Network}
    Log    Delete external networks
    : FOR    ${Network}    IN    @{EXTERNAL_NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${Network}
    Delete SecurityGroup    ${SECURITY_GROUP}

Send Traffic Using Netcat
    [Arguments]    ${vm1_ip}    ${vm2_ip}    ${net1_name}    ${net2_name}    ${compute_1_conn_id}    ${compute_2_conn_id}
    ...    ${port_no}    ${verify_string}    ${protocol}=udp
    [Documentation]    Send traffic using netcat
    ${proto_arg}    Set Variable If    '${protocol}'=='udp'    nc -u    nc
    Log    >>>Logging into the vm1>>>
    Switch Connection    ${compute_1_conn_id}
    Login To VM Instance    ${net1_name}    ${vm1_ip}
    Write Until Expected Output    ${proto_arg} -s ${vm1_ip} -l -p ${port_no} -v\r    expected=listening    timeout=5s    retry_interval=1s
    Log    >>>Logging into the vm2>>>
    Switch Connection    ${compute_2_conn_id}
    Login To VM Instance    ${net2_name}    ${vm2_ip}
    Write Until Expected Output    ${proto_arg} ${vm1_ip} ${port_no} -v\r    expected=open    timeout=5s    retry_interval=1s
    Write    ${verify_string}
    Write    ${verify_string}
    Write    ${verify_string}
    Write    ${verify_string}
    Write_Bare_Ctrl_C
    Virsh Exit
    Switch Connection    ${compute_1_conn_id}
    ${cmdoutput}    Read
    Log    ${cmdoutput}
    Write_Bare_Ctrl_C
    Virsh Exit
    Should Contain    ${cmdoutput}    ${verify_string}

Login To VM Instance
    [Arguments]    ${net_name}    ${vm_ip}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network, executes a command inside the VM and returns the ouput.
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    ${net_name}    ${devstack_conn_id}
    Log    ${vm_ip}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    [Return]    ${output}

Security Group Rule To Allow All Traffic
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Ext Network
    [Arguments]    ${external_network}    ${ext_value}    ${type}    ${verbose}=TRUE
    ${command}    Set Variable If    "${verbose}" == "TRUE"    neutron net-create ${external_network} \ --router:external=${ext_value} \ --provider:network_type ${type}
    ${output}=    Write Commands Until Prompt    ${command}    30s
    Log    ${output}
    Should Contain    ${output}    Created a new network:

Verifying Primary switch ID
    [Arguments]    ${connection_id1}    ${connection_id2}
    ${dpnid1}    Get Dpn Ids    ${connection_id1}
    Set Global Variable    ${dpnid1}
    Log    ${dpnid1}
    ${dpnid2}    Get Dpn Ids    ${connection_id2}
    Set Global Variable    ${dpnid2}
    Log    ${dpnid2}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/odl-nat:napt-switches/
    Log To Console    ${resp.content}
    @{temp} =    Get Dictionary Items    ${resp.content}
    Log    ${temp[1]}
    @{temp1}    Split String    ${temp[1]}    :
    ${prid}    Should Match Regexp    @{temp1}[1]    [0-9]+
    Log ${prid}
    Run Keyword If    '${prid}' == "${dpnid1}"    Log To Console    "dpn1 is primary"
    Run Keyword If    '${prid}' == "${dpnid2}"    Log To Console    "dpn2 is primary"
    #Get Vm Ip
    #    [Arguments]    ${vm}    ${Net}
    #    ${devstack_conn_id}=    Get ControlNode Connection
    #    Switch Connection    ${devstack_conn_id}
    #    ${ip}=    Write Commands Until Prompt    nova show ${vm} | grep ${Net} | awk '{print$5}'    30s
    #    ${vms_ip}    Should Match Regexp    ${ip}    [0-9]\.+
    #    @{vm}    Split String    ${vms_ip}    \r
    #    ${vm_out}    Set Variable    ${vm[0]}
    #    [Return]    ${vm_out}
    #
    [Return]    ${prid}

Add Router Gateway
    [Arguments]    ${router_name}    ${external_network_name}    ${additional_args}=${EMPTY}
    Comment    ${cmd}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    neutron -v router-gateway-set ${router_name} ${external_network_name} \ ${additional_args}    openstack router set ${router_name} --external-gateway ${external_network_name}
    #    ${output}=    Write Commands Until Expected Prompt    neutron router-gateway-set ${router_name} ${external_network_name} \ ${additional_args}    ${DEFAULT_LINUX_PROMPT}
    ${rc}    ${output}=    OpenStackOperations.Run And Return Rc And Output    neutron router-gateway-set ${router_name} ${external_network_name} \ ${additional_args}
    Comment    ${rc}    ${output}=    OpenStackOperations..Run And Return Rc And Output    ${cmd}
    Comment    Should Not Be True    ${rc}
    Should Contain    ${output}    Set gateway for router

Get VM Ip Addresses
    [Arguments]    ${network_name}    @{vm_list}
    [Documentation]    Getting the ip address from VM
    ${ip_list}    Create List    @{EMPTY}
    : FOR    ${vm_name}    IN    @{vm_list}
    \    ${vm_ip_line}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    ${DEFAULT_LINUX_PROMPT}    30
    \    log    ${vm_ip_line}
    \    log    ${network_name}
    \    @{vm_ip}    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${vm_ip_length}    Get Length    ${vm_ip}
    \    Run Keyword If    ${vm_ip_length}>0    Append To List    ${ip_list}    @{vm_ip}[0]
    \    ...    ELSE    Append To List    ${ip_list}    None
    log    ${ip_list}
    [Return]    ${ip_list}
