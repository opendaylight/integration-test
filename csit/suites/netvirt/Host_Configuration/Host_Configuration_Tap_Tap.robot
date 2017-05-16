*** Settings ***
Documentation     This test suite involves Priority1 test cases \ for the sanity. This covers test areas such as, IPV6 assignment in SLAAC Mode, Traffic flow when VMs are brought up with security rules for different protocols(tcp, udp, icmp), Allowed address pair test cases.
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{Networks}       NET10    NET20
@{VM_List}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
@{Routers}        router1
@{V4subnets}      10.10.10.0    20.20.20.0
@{V4subnet_Names}    subnet1v4    subnet2v4
${Br_Name}        br-int
@{Login_Credentials}    stack    stack    root    password
${Devstack_Path}    /opt/stack/devstack
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
${Itm_Created}    TZA
@{Bridge_names}    BR1    BR1
${Flavor_Name}    myhuge
@{Tables}         table=0    table=17    table=40    table=41    table=45    table=50    table=51
...               table=60    table=220    table=251    table=252
${image}          cirros-0.3.4-x86_64-uec
${Flavor_Name1}    m1.tiny

*** Test Cases ***
Test Host Configuration
    [Documentation]    Validate host config and pseudoagentportbinding feature implemented by ODL Neutron.
    Switch Connection    ${root_conn_id_1}
    Log    >>> Get UUID <<<
    ${uuid1}    Write Commands Until Expected Prompt    export OVSUUID=$(ovs-vsctl get Open_vSwitch . _uuid)    \#    20
    ${output}    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch $OVSUUID external_ids    \#    20
    log    ${output}
    Switch Connection    ${root_conn_id_2}
    ${uuid2}    Write Commands Until Expected Prompt    export OVSUUID=$(ovs-vsctl get Open_vSwitch . _uuid)    \#    20
    ${output}    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch $OVSUUID external_ids    \#    20
    log    ${output}
    Log    >>>> Get Hostname <<<<
    ${hostname1}    Get Hostname    ${conn_id_1}
    Log    ${hostname1}
    Switch Connection    ${root_conn_id_1}
    Log    >>>> Configure Host Config on OVS1 <<<
    ${allowed_network_types}    Set Variable    \\"allowed_network_types\\":[\\"local\\",\\"vlan\\",\\"vxlan\\",\\"gre\\"]
    ${bridge_mappings}    Set Variable    \\"bridge_mappings\\"={\\"default\\":\\"br-int\\"}
    ${datapath_type}    Set Variable    \\"datapath_type\\":\\"system\\"
    ${vif_type}    Set Variable    \\"vif_type\\":\\"ovs\\"
    ${vnic_type}    Set Variable    \\"vnic_type\\":\\"normal\\"
    ${has_datapath_type_netdev}    Set Variable    \\"has_datapath_type_netdev\\":\\"false\\"
    ${support_vhost_user}    Set Variable    \\"support_vhost_user\\":\\"false\\"
    ${host_addresses}    Set Variable    \\"host_addresses\\":\\"[${hostname1}]\\"
    Log    ${host_addresses}
    Set OVS Host Configuration    ${hostname1}    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${support_vhost_user}    ${host_addresses}
    Log    >>>> Check Operational Data in ODL for HostConfig For OVS1 <<<
    ${uri}    Set Variable    ${OPERATIONAL_API}/neutron:neutron/hostconfigs/hostconfig/${hostname1}/ODL%20L2/
    @{host_config_elements}    Create List    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${support_vhost_user}    ${host_addresses}
    Check For Elements At URI    ${OPERATIONAL_API}/neutron:neutron/hostconfigs/    ${host_config_elements}
    Log    >>>> Get Hostname <<<<
    ${hostname2}    Get Hostname    ${conn_id_2}
    Log    ${hostname2}
    Switch Connection    ${root_conn_id_2}
    Log    >>>> Configure Host Config on OVS2 <<<
    ${allowed_network_types}    Set Variable    \\"allowed_network_types\\":[\\"local\\",\\"vlan\\",\\"vxlan\\",\\"gre\\"]
    ${bridge_mappings}    Set Variable    \\"bridge_mappings\\"={\\"default\\":\\"br-int\\"}
    ${datapath_type}    Set Variable    \\"datapath_type\\":\\"system\\"
    ${vif_type}    Set Variable    \\"vif_type\\":\\"ovs\\"
    ${vnic_type}    Set Variable    \\"vnic_type\\":\\"normal\\"
    ${has_datapath_type_netdev}    Set Variable    \\"has_datapath_type_netdev\\":\\"false\\"
    ${support_vhost_user}    Set Variable    \\"support_vhost_user\\":\\"false\\"
    ${host_addresses}    Set Variable    \\"host_addresses\\":\\"[${hostname2}]\\"
    Log    ${host_addresses}
    Set OVS Host Configuration    ${hostname2}    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${support_vhost_user}    ${host_addresses}
    Log    >>>> Check Operational Data in ODL for HostConfig For OVS2 <<<
    ${uri}    Set Variable    ${OPERATIONAL_API}/neutron:neutron/hostconfigs/hostconfig/${hostname2}/ODL%20L2/
    @{host_config_elements}    Create List    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${support_vhost_user}    ${host_addresses}
    Check For Elements At URI    ${OPERATIONAL_API}/neutron:neutron/hostconfigs/    ${host_config_elements}
    create ITM Tunnel
    Create Network    ${Networks[0]}    --port-security-enabled=False
    Create Network    ${Networks[1]}    --port-security-enabled=False
    Create Subnet    ${Networks[0]}    ${V4subnet_Names[0]}    ${V4subnets[0]}/24
    Create Subnet    ${Networks[1]}    ${V4subnet_Names[1]}    ${V4subnets[1]}/24
    Create Router    ${Routers[0]}
    Add Router Interface    ${Routers[0]}    ${V4subnet_Names[0]}
    Add Router Interface    ${Routers[0]}    ${V4subnet_Names[1]}
    Remove All Elements If Exist    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/
    Post Elements To URI From File    ${CONFIG_API}/    ${netvirt_config_dir}/enable_dhcp.json
    @{list}=    Create List    "controller-dhcp-enabled"    true
    Check For Elements At URI    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/    ${list}
    Switch Connection    ${conn_id_1}
    Create Flavor    ${Flavor_Name}
    ${hostname1}    Get Hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    ${hostname2}    Get Hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[0]}    ${VM_list[0]}    ${image}    ${hostname1}    ${Flavor_Name}
    Sleep    60
    ${output2}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-ports-desc br-int -OOpenflow13    $    20
    log    ${output2}
    Spawn Vm    ${Networks[0]}    ${VM_list[1]}    ${image}    ${hostname2}    ${Flavor_Name}
    Switch Connection    ${conn_id_2}
    Sleep    40
    ${output2}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-ports-desc br-int -OOpenflow13    $    20
    log    ${output2}
    Log    >>>> Boot VM3 in DPN2 <<<
    Spawn Vm    ${Networks[1]}    ${VM_list[2]}    ${image}    ${hostname2}    ${Flavor_Name}
    Sleep    40
    ${output2}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-ports-desc br-int -OOpenflow13    $    20
    log    ${output2}
    ${virshid1}    Get Vm Instance    ${VM_list[0]}
    ${virshid2}    Get Vm Instance    ${VM_list[1]}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    ${vm1output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid1}
    ...    ifconfig eth0
    ${vm2output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid2}
    ...    ifconfig eth0
    ${vm3output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid3}
    ...    ifconfig eth0
    Switch Connection    ${conn_id_1}
    ${vm1ip}    get network specific ip address    ${VM_list[0]}    ${Networks[0]}
    ${vm2ip}    get network specific ip address    ${VM_list[1]}    ${Networks[0]}
    ${vm3ip}    get network specific ip address    ${VM_list[2]}    ${Networks[1]}
    Should Contain    ${vm1output}    ${vm1ip}
    Should Contain    ${vm2output}    ${vm2ip}
    Should Contain    ${vm3output}    ${vm3ip}
    Ping From Virsh Console    ${virshid1}    ${vm2ip}    ${conn_id_1}    , 0% packet loss
    Ping From Virsh Console    ${virshid1}    ${vm3ip}    ${conn_id_1}    , 0% packet loss
    Testcase Cleanup

*** Keywords ***
Get Hostname
    [Arguments]    ${conn_id}
    Switch Connection    ${conn_id}
    ${hostname}    Write Commands Until Expected Prompt    hostname    $    30
    @{host}    Split String    ${hostname}    \r\n
    log    ${host}
    ${h}    get from list    ${host}    0
    Comment    log    ${h}
    [Return]    ${h}

Set OVS Host Configuration
    [Arguments]    ${hostname}    ${allowed_network_types}    ${bridge_mappings}    ${datapath_type}    ${vif_type}    ${vnic_type}
    ...    ${has_datapath_type_netdev}    ${support_vhost_user}    ${host_addresses}
    Log    >>>> Get ovs uuid <<<<
    ${ovs_uuid}    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch . _uuid    \#    20
    ${templ1}    Split To Lines    ${ovs_uuid}
    ${str1}=    Get From List    ${templ1}    0
    ${ovs_uuid}=    Strip String    ${str1}
    Log    ${ovs_uuid}
    ${ovs_uuid1}    Set Variable    \\"uuid\\":\\"${ovs_uuid}\\"
    Log    >>>> Set odl_os_hostconfig_hostid <<<<
    Write Commands Until Expected Prompt    ovs-vsctl set Open_vSwitch ${ovs_uuid} \ external_ids:odl_os_hostconfig_hostid=${hostname}    \#    20
    ${odl_os_hostconfig_odl_l2}    Set Variable    ovs-vsctl set Open_vSwitch ${ovs_uuid} external_ids:odl_os_hostconfig_config_odl_l2="{${allowed_network_types},${bridge_mappings},${datapath_type},"supported_vnic_types":[{${vif_type},${vnic_type},${has_datapath_type_netdev},${ovs_uuid1},${support_vhost_user},${host_addresses}}]}"
    Write Commands Until Expected Prompt    ${odl_os_hostconfig_odl_l2}    \#    20
    Comment    Log    >>> Restart the switch <<<
    Comment    Write Commands Until Expected Prompt    sudo service openvswitch-switch restart    \#    20
    Log    >>> Get the external ids<<<<
    Write Commands Until Expected Prompt    ovs-vsctl get Open_vSwitch ${ovs_uuid} \ external_ids    \#    20

