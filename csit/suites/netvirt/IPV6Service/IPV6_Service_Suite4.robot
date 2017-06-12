*** Settings ***
Documentation     Test suite for OVS TOR Test cases for IPV6.
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Setup
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/IPV6_Service.robot
Resource          ../../../libraries/Genius.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../variables/IPV6Service_Variables.robot

*** Variables ***
@{Networks}       mynet1    mynet2    mynet3
@{Subnets}        ipv6s1    ipv6s2    ipv6s3    ipv6s4
@{VM_list}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
@{Routers}        router1    router2
@{Prefixes}       2001:db8:1234::    2001:db8:5678::    2001:db8:4321::    2001:db8:6789::
@{V4subnets}      13.0.0.0    14.0.0.0
@{V4subnet_names}    subnet1v4    subnet2v4
${ipv6securitygroups_config_dir}    ${CURDIR}/../../variables/ipv6securitygroups
@{login_credentials}    stack    stack    root    password
@{SG_name}        SG1    SG2    SG3    SG4    default
@{rule_list}      tcp    udp    icmpv6    10000    10500    IPV6    # protocol1, protocol2, protocol3, port_min, port_max, ether_type
@{direction}      ingress    egress    both
@{Image_Name}     cirros-0.3.4-x86_64-uec    ubuntu-sg
@{protocols}      tcp6    udp6    icmp6
@{remote_group}    SG1    prefix    any
@{remote_prefix}    ::0/0    2001:db8:1234::/64    2001:db8:4321::/64
@{logical_addr}    2001:db8:1234:0:1111:2343:3333:4444    2001:db8:1234:0:1111:2343:3333:5555
${br_name}        br-int
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
@{itm_created}    TZA
${Bridge-1}       br0
${Bridge-2}       br0
@{dpip}           20.0.0.9    20.0.0.10
${Interface-1}    eth1
${Interface-2}    eth1
@{flavour_list}    m1.nano    m1.tiny
@{Tables}         table=0    table=17    table=40    table=41    table=45    table=50    table=51
...               table=60    table=220    table=251    table=252
${invalid_Subnet_Value}    2001:db8:1234::/21
${genius_config_dir}    ${CURDIR}/../../../variables/genius
@{Ports}          tor1_port1    tor1_port2    tor2_port1    tor2_port2
@{tor_bridge}     br-tor    br-tor1
@{tor_tunnel_ip}    20.0.0.56    20.0.0.147
@{torvms}         tor1vm1    tor1vm2    tor2vm1    tor2vm2

*** Test Cases ***
Verify ping6 between VM on CSS and VM on TOR in same ELAN
    [Documentation]    Verify ping6 between VM on CSS and VM on TOR in same ELAN
    [Setup]    Create Topology
    PreSuiteSetUpForTOR
    fetch topology details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    Create Network    ${Networks[1]}
    Create Subnet    ${Networks[1]}    ${Subnets[2]}    ${Prefixes[2]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Router    ${Routers[1]}
    Add Router Interface    ${Routers[1]}    ${Subnets[2]}
    Switch Connection    ${conn_id_1}
    ${tor_ip_addr1}    ${tor_mac_1}    Create Neutron Port And Extract MAC And IP    ${Networks[0]}    ${Ports[0]}
    ${portid_1}    Get Port Id of instance    ${tor_mac_1}    ${conn_id_1}
    ${tor_ip_addr2}    ${tor_mac_2}    Create Neutron Port And Extract MAC And IP    ${Networks[1]}    ${Ports[1]}
    ${portid_2}    Get Port Id of instance    ${tor_mac_2}    ${conn_id_1}
    ${tor_ip_addr3}    ${tor_mac_3}    Create Neutron Port And Extract MAC And IP    ${Networks[0]}    ${Ports[2]}
    ${portid_3}    Get Port Id of instance    ${tor_mac_3}    ${conn_id_1}
    ${tor_ip_addr4}    ${tor_mac_4}    Create Neutron Port And Extract MAC And IP    ${Networks[1]}    ${Ports[3]}
    ${portid_4}    Get Port Id of instance    ${tor_mac_4}    ${conn_id_1}
    ${conn_id_3}    Tor Login    ${TOOLS_SYSTEM_3_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_3}
    Log    ${conn_id_3}
    ${conn_id_3_1}    Tor Login    ${TOOLS_SYSTEM_3_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_3_1}
    ${conn_id_3_2}    Tor Login    ${TOOLS_SYSTEM_3_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_3_2}
    Switch Connection    ${conn_id_3_1}
    ${output}    Write Commands Until Expected Prompt    screen -S ${torvms[0]}    \#    30
    ${output}    Write Commands Until Expected Prompt    echo $STY    \#    30
    Should Contain    ${output}    ${torvms[0]}
    ${output}    Write Commands Until Expected Prompt    sudo /usr/bin/qemu-system-x86_64 -name ${torvms[0]} -hda disk.raw -m 1024 -cdrom /root/ZeroShell-3.5.0.iso -boot d -net nic -netdev type=tap,id=hostnet1,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown,ifname=tap${portid_1} -device virtio-net-pci,netdev=hostnet1,id=net1,mac=${tor_mac_1},csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off -nographic    Select:    300
    Write Commands Until Expected Prompt    s    ~>    30
    Switch Connection    ${conn_id_3_2}
    ${output}    Write Commands Until Expected Prompt    screen -S ${torvms[1]}    \#    30
    ${output}    Write Commands Until Expected Prompt    echo $STY    \#    30
    Should Contain    ${output}    ${torvms[1]}
    ${output}    Write Commands Until Expected Prompt    sudo /usr/bin/qemu-system-x86_64 -name ${torvms[1]} -hda disk.raw -m 1024 -cdrom /root/ZeroShell-3.5.0.iso -boot d -net nic -netdev type=tap,id=hostnet1,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown,ifname=tap${portid_2} -device virtio-net-pci,netdev=hostnet1,id=net1,mac=${tor_mac_2},csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off -nographic    Select:    300
    Write Commands Until Expected Prompt    s    ~>    30
    Switch Connection    ${conn_id_1}
    ${ovs_output}    Write Commands Until Expected Prompt    sudo ovs-vsctl show    $
    log    ${ovs_output}
    ${conn_id_4}    Tor Login    ${TOOLS_SYSTEM_4_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_4}
    ${conn_id_4_1}    Tor Login    ${TOOLS_SYSTEM_4_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_4_1}
    ${conn_id_4_2}    Tor Login    ${TOOLS_SYSTEM_4_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_4_2}
    Switch Connection    ${conn_id_4_1}
    ${output}    Write Commands Until Expected Prompt    screen -S ${torvms[2]}    \#    30
    ${output}    Write Commands Until Expected Prompt    echo $STY    \#    30
    Should Contain    ${output}    ${torvms[2]}
    ${output}    Write Commands Until Expected Prompt    sudo /usr/bin/qemu-system-x86_64 -name ${torvms[2]} -hda disk.raw -m 1024 -cdrom /root/ZeroShell-3.5.0.iso -boot d -net nic -netdev type=tap,id=hostnet1,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown,ifname=tap${portid_3} -device virtio-net-pci,netdev=hostnet1,id=net1,mac=${tor_mac_3},csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off -nographic    Select:    600
    Write Commands Until Expected Prompt    s    ~>    30
    Switch Connection    ${conn_id_4_2}
    ${output}    Write Commands Until Expected Prompt    screen -S ${torvms[3]}    \#    30
    ${output}    Write Commands Until Expected Prompt    echo $STY    \#    30
    Should Contain    ${output}    ${torvms[3]}
    ${output}    Write Commands Until Expected Prompt    sudo /usr/bin/qemu-system-x86_64 -name ${torvms[3]} -hda disk.raw -m 1024 -cdrom /root/ZeroShell-3.5.0.iso -boot d -net nic -netdev type=tap,id=hostnet1,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown,ifname=tap${portid_4} -device virtio-net-pci,netdev=hostnet1,id=net1,mac=${tor_mac_4},csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off -nographic    Select:    600
    Write Commands Until Expected Prompt    s    ~>    30
    Switch Connection    ${conn_id_3_1}
    ${output}    Write Commands Until Expected Prompt    sudo ip -6 addr add ${tor_ip_addr1}/64 dev ETH00    ~>    30
    ${output}    Write Commands Until Expected Prompt    ifconfig ETH00    ~>    30
    log    ${output}
    close connection
    Switch Connection    ${conn_id_3_2}
    ${output}    Write Commands Until Expected Prompt    sudo ip -6 addr add ${tor_ip_addr2}/64 dev ETH00    ~>    30
    ${output}    Write Commands Until Expected Prompt    ifconfig ETH00    ~>    30
    log    ${output}
    Switch Connection    ${conn_id_4_1}
    ${output}    Write Commands Until Expected Prompt    sudo ip -6 addr add ${tor_ip_addr3}/64 dev ETH00    ~>    30
    ${output}    Write Commands Until Expected Prompt    ifconfig ETH00    ~>    30
    log    ${output}
    Switch Connection    ${conn_id_4_2}
    ${output}    Write Commands Until Expected Prompt    sudo ip -6 addr add ${tor_ip_addr4}/64 dev ETH00    ~>    30
    ${output}    Write Commands Until Expected Prompt    ifconfig ETH00    ~>    30
    log    ${output}
    Switch Connection    ${conn_id_1}
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-create --device name=${tor_bridge[0]},interface_names="tap${portid_1}" \ gw1    $    30
    Should Contain    ${output}    Created a new l2_gateway:
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-connection-create --default-segmentation-id 0 \ gw1 \ ${Networks[0]} \ \    $    30
    Should Contain    ${output}    Created a new l2_gateway_connection:
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-create --device name=${tor_bridge[0]},interface_names="tap${portid_2}" \ gw2    $    30
    Should Contain    ${output}    Created a new l2_gateway:
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-connection-create --default-segmentation-id 0 \ gw2 \ ${Networks[1]} \ \    $    30
    Should Contain    ${output}    Created a new l2_gateway_connection:
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-create --device name=${tor_bridge[1]},interface_names="tap${portid_3}" \ gw3    $    30
    Should Contain    ${output}    Created a new l2_gateway:
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-connection-create --default-segmentation-id 0 \ gw3 \ ${Networks[0]} \ \    $    30
    Should Contain    ${output}    Created a new l2_gateway_connection:
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-create --device name=${tor_bridge[1]},interface_names="tap${portid_4}" \ gw4    $    30
    Should Contain    ${output}    Created a new l2_gateway:
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-connection-create --default-segmentation-id 0 \ gw4 \ ${Networks[1]} \ \    $    30
    Should Contain    ${output}    Created a new l2_gateway_connection:
    @{array}    Create List    ${dpip[0]}    ${dpip[1]}    ${tor_tunnel_ip[0]}    ${tor_tunnel_ip[1]}
    Wait Until Keyword Succeeds    40 sec    10 sec    verify ovs    ${conn_id_1}    ${array}
    @{array}    Create List    ${dpip[0]}    ${dpip[1]}    ${tor_tunnel_ip[0]}    ${tor_tunnel_ip[1]}
    Wait Until Keyword Succeeds    40 sec    10 sec    verify ovs    ${conn_id_2}    ${array}
    Log    >>>TOR side validations>>>
    Switch Connection    ${conn_id_3}
    log    ${mac1}
    ${lowermac1}    Convert To Lowercase    ${mac1}
    @{array}    Create List    ${lowermac1}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Ucast_Macs_Remote table/ ,/#/p'    ${array}
    Wait Until Keyword Succeeds    40 sec    10 sec    ping from virsh console    ${virshid1}    ${tor_ip_addr1}    ${conn_id_1}
    ...    , 0% packet loss
    Switch Connection    ${conn_id_3}
    ${output}    Write Commands Until Expected Prompt    ovsdb-client dump hardware_vtep    \#    30
    Should Contain    ${output}    Ucast_Macs_Local table
    @{array}    Create List    ${tor_mac_1}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Ucast_Macs_Local table/ ,/Ucast_Macs_Remote table/p'    ${array}
    Should Contain    ${output}    Physical_Port table
    @{array}    Create List    ${portid_1}    ${portid_2}    {0=
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Physical_Port table/ ,/Physical_Switch table/p' | grep tap    ${array}
    ${net1_id}    Get Network Id    ${conn_id_1}    ${Networks[0]}
    ${net2_id}    Get Network Id    ${conn_id_1}    ${Networks[1]}
    ${net1_segmentation_id}    Get Network Segmetation Id    ${conn_id_1}    ${Networks[0]}
    ${net2_segmentation_id}    Get Network Segmetation Id    ${conn_id_1}    ${Networks[1]}
    @{array}    Create List    "${net1_id}" ${net1_segmentation_id}    "${net2_id}" ${net2_segmentation_id}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Logical_Switch table/ ,/Manager table/p'    ${array}
    @{array}    Create List    ${dpip[0]}    ${dpip[1]}    ${tor_tunnel_ip[0]}    ${tor_tunnel_ip[1]}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Physical_Locator table/ ,/Physical_Locator_Set table/p'    ${array}
    Switch Connection    ${conn_id_1}
    @{araay}    Create List    dl_dst=${tor_mac_1}
    Wait Until Keyword Succeeds    40 sec    10 sec    table check    ${conn_id_1}    ${br_name1}    table=51
    ...    ${araay}

Verify ping6 between two TOR VMs in same ELAN
    [Documentation]    Verify ping6 between two TOR VMs in same ELAN
    fetch topology details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    ${tor_ip_addr1}    ${tor_mac_1}    fetch mac and ip    ${Ports[0]}
    ${portid_1}    Get Port Id of instance    ${tor_mac_1}    ${conn_id_1}
    ${tor_ip_addr2}    ${tor_mac_2}    fetch mac and ip    ${Ports[1]}
    ${portid_2}    Get Port Id of instance    ${tor_mac_2}    ${conn_id_1}
    ${tor_ip_addr3}    ${tor_mac_3}    fetch mac and ip    ${Ports[2]}
    ${portid_3}    Get Port Id of instance    ${tor_mac_3}    ${conn_id_1}
    ${tor_ip_addr4}    ${tor_mac_4}    fetch mac and ip    ${Ports[3]}
    ${portid_4}    Get Port Id of instance    ${tor_mac_4}    ${conn_id_1}
    ${conn_id_3_1}    Tor Login    ${TOOLS_SYSTEM_3_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_3_1}
    Comment    Switch Connection    ${conn_id_3_1}
    ${output}    Write Commands Until Expected Prompt    ping6 -c 5 ${tor_ip_addr3}    >    30
    log    ${output}
    Should Contain    ${output}    , 0% packet loss
    close connection
    ${net1_id}    Get Network Id    ${conn_id_1}    ${Networks[0]}
    ${net2_id}    Get Network Id    ${conn_id_1}    ${Networks[1]}
    ${net1_segmentation_id}    Get Network Segmetation Id    ${conn_id_1}    ${Networks[0]}
    ${net2_segmentation_id}    Get Network Segmetation Id    ${conn_id_1}    ${Networks[1]}
    @{array}    Create List    "${net1_id}" ${net1_segmentation_id}    "${net2_id}" ${net2_segmentation_id}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Logical_Switch table/ ,/Manager table/p'    ${array}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_4}    sed -n '/Logical_Switch table/ ,/Manager table/p'    ${array}
    @{array}    Create List    ${dpip[0]}    ${dpip[1]}    ${tor_tunnel_ip[0]}    ${tor_tunnel_ip[1]}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Physical_Locator table/ ,/Physical_Locator_Set table/p'    ${array}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_4}    sed -n '/Physical_Locator table/ ,/Physical_Locator_Set table/p'    ${array}
    ${lowermac_tor2vm1}    Convert To Lowercase    ${tor_mac_3}
    @{array}    Create List    ${lowermac_tor2vm1}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Ucast_Macs_Remote table/ ,/#/p'    ${array}
    ${lowermac_tor1vm1}    Convert To Lowercase    ${tor_mac_1}
    @{array}    Create List    ${lowermac_tor1vm1}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_4}    sed -n '/Ucast_Macs_Remote table/ ,/#/p'    ${array}
    log    >>>validate local mac table>>>
    @{array}    Create List    ${lowermac_tor1vm1}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Ucast_Macs_Local table/ ,/Ucast_Macs_Remote table/p'    ${array}
    @{array}    Create List    ${lowermac_tor2vm1}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_4}    sed -n '/Ucast_Macs_Local table/ ,/Ucast_Macs_Remote table/p'    ${array}
    @{array}    Create List    ${portid_1}    ${portid_2}    {0=
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Physical_Port table/ ,/Physical_Switch table/p' | grep tap    ${array}
    @{array}    Create List    ${portid_3}    ${portid_4}    {0=
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_4}    sed -n '/Physical_Port table/ ,/Physical_Switch table/p' | grep tap    ${array}

Verify ping6 fails between two TOR VMs in different ELAN
    [Documentation]    Verify ping6 fails between two TOR VMs in different ELAN
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    Switch Connection    ${conn_id_1}
    ${tor_ip_addr4}    ${tor_mac_4}    fetch mac and ip    ${Ports[3]}
    ${conn_id_3_1}    Tor Login    ${TOOLS_SYSTEM_3_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_3_1}
    Comment    Switch Connection    ${conn_id_3_1}
    ${output}    Write Commands Until Expected Prompt    ping6 -c 5 ${tor_ip_addr4}    >    30
    log    ${output}
    Should Contain    ${output}    Network is unreachable
    Close Connection

Verify changes in ELAN mac table w.r.t BM or SR-IOV VMs is reflected in OVS destination mac table and the other TORs remote mac tables
    [Documentation]    Verify changes in ELAN mac table w.r.t BM or SR-IOV VMs is reflected in OVS destination mac table and the other TORs remote mac tables
    fetch topology details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    LOg    >>>Bring up the new vm in tor2>>>
    ${tor_ip_addr5}    ${tor_mac_5}    Create Neutron Port And Extract MAC And IP    ${Networks[0]}    ${Ports[4]}
    ${portid_5}    Get Port Id of instance    ${tor_mac_5}    ${conn_id_1}
    ${conn_id_4_3}    Tor Login    ${TOOLS_SYSTEM_4_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_4_3}
    Switch Connection    ${conn_id_4_3}
    ${output}    Write Commands Until Expected Prompt    screen -S ${torvms[4]}    \#    30
    ${output}    Write Commands Until Expected Prompt    echo $STY    \#    30
    Should Contain    ${output}    ${torvms[4]}
    Log    >>>Inside the screen of tor2vm3, execute the command>>>
    ${output}    Write Commands Until Expected Prompt    sudo /usr/bin/qemu-system-x86_64 -name ${torvms[4]} -hda disk.raw -m 1024 -cdrom /root/ZeroShell-3.5.0.iso -boot d -net nic -netdev type=tap,id=hostnet1,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown,ifname=tap${portid_5} -device virtio-net-pci,netdev=hostnet1,id=net1,mac=${tor_mac_5},csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off -nographic    Select:    600
    Write Commands Until Expected Prompt    s    ~>    30
    Switch Connection    ${conn_id_4_3}
    ${output}    Write Commands Until Expected Prompt    sudo ip -6 addr add ${tor_ip_addr5}/64 dev ETH00    ~>    30
    ${output}    Write Commands Until Expected Prompt    ifconfig ETH00    ~>    30
    log    ${output}
    Switch Connection    ${conn_id_1}
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-create --device name=${tor_bridge[1]},interface_names="tap${portid_5}" \ gw5    $    30
    Should Contain    ${output}    Created a new l2_gateway:
    ${output}    Write Commands Until Expected Prompt    neutron l2-gateway-connection-create --default-segmentation-id 0 gw5 \ ${Networks[0]}    $    30
    Should Contain    ${output}    Created a new l2_gateway_connection:
    ${lowermac5}    Convert To Lowercase    ${tor_mac_5}
    @{array}    Create List    ${lowermac5}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Ucast_Macs_Remote table/ ,/#/p'    ${array}

Verify macs sync happens separately for diff ELAN instance samong CSS/OVS VMs and VMs on TORs belonging to respective ELAN instances
    [Documentation]    Verify macs sync happens separately for diff ELAN instance samong CSS/OVS VMs and VMs on TORs belonging to respective ELAN instances
    fetch topology details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    ${net1_id}    Get Network Id    ${conn_id_1}    ${Networks[0]}
    Switch Connection    ${conn_id_3}
    ${match}    Set Variable    sed -n '/Logical_Switch table/ ,/Manager table/p'
    ${output}    Write Commands Until Expected Prompt    ovsdb-client dump \ hardware_vtep | ${match} | grep ${net1_id} | awk '{print$1}'    \#    30
    log    ${output}
    @{temp_list}    Split String    ${output}    \r\n
    ${uuid}    Get From List    ${temp_list}    0
    log    ${uuid}
    ${lowermac1}    Convert To Lowercase    ${mac1}
    @{array}    Create List    ${lowermac1}
    Wait Until Keyword Succeeds    40 sec    10 sec    hwvtep table check    ${conn_id_3}    sed -n '/Ucast_Macs_Remote table/ ,/#/p' | grep ${uuid}    ${array}

*** Keywords ***
Create Topology
    [Documentation]    Creating the Topology for the test cases.
    log    >>>creating ITM tunnel
    Create ITM Tunnel
    Log    >>>> Creating Network <<<<
    Switch Connection    ${conn_id_1}
    Create Network    ${Networks[0]}
    Create Subnet    ${Networks[0]}    ${Subnets[0]}    ${Prefixes[0]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Subnet    ${Networks[0]}    ${Subnets[1]}    ${Prefixes[1]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Router    ${Routers[0]}
    Add Router Interface    ${Routers[0]}    ${Subnets[0]}
    @{prefixlist}    Create List    ${Prefixes[0]}
    Add Router Interface    ${Routers[0]}    ${Subnets[1]}
    @{prefixlist}    Create List    ${Prefixes[0]}    ${Prefixes[1]}
    ${hostname1}    Get Vm Hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    Get Vm Hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[0]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[1]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${Image_Name[0]}    ${hostname2}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    ${virshid1}    Get Vm Instance    ${VM_list[0]}
    ${virshid2}    Get Vm Instance    ${VM_list[1]}
    Set Global Variable    ${virshid1}
    Set Global Variable    ${virshid2}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[0]}    ${Networks[0]}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    Set Global Variable    ${ip_list2}
    ${output1}    Virsh Output    ${virshid1}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output1}
    ${linkaddr1}    Extract Linklocal Addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${output2}    Virsh Output    ${virshid2}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output2}
    ${linkaddr2}    Extract Linklocal Addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output1}    ${prefixstr1}
    Should Contain    ${output1}    ${prefixstr2}
    Should Contain    ${output2}    ${prefixstr1}
    Should Contain    ${output2}    ${prefixstr2}
    Set Global Variable    ${ip_list1[0]}
    Set Global Variable    ${ip_list1[1]}
    Set Global Variable    ${ip_list2[0]}
    Set Global Variable    ${ip_list2[1]}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    Should Contain    ${output2}    ${ip_list2[0]}
    Should Contain    ${output2}    ${ip_list2[1]}
    ${mac1}    Extract_Mac_From_Ifconfig    ${output1}
    ${port_id1}    Get Port Id of instance    ${mac1}    ${conn_id_1}
    ${port1}    Get In Port Number For VM    ${br_name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    ${mac2}    Extract_Mac_From_Ifconfig    ${output2}
    ${port_id2}    Get Port Id of instance    ${mac2}    ${conn_id_1}
    ${port2}    Get In Port Number For VM    ${br_name}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
    ${virshid5}    Get Vm Instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${ip_list5}    Wait Until Keyword Succeeds    2 min    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    Switch Connection    ${conn_id_2}
    ${output5}    Virsh Output    ${virshid5}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output5}
    ${linkaddr5}    Extract Linklocal Addr    ${output5}
    Set Global Variable    ${linkaddr5}
    Should Contain    ${output5}    ${ip_list5[0]}
    Should Contain    ${output5}    ${ip_list5[1]}
    ${mac5}    Extract_Mac_From_Ifconfig    ${output5}
    ${port_id5}    Get Port Id of instance    ${mac5}    ${conn_id_2}
    ${port5}    Get In Port Number For VM    ${br_name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    Switch Connection    ${conn_id_1}

Delete Topology
    [Documentation]    Cleaning up the setup.
    Comment    @{VM_list}    Create List    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[2]}    ${VM_list[3]}
    ...    ${VM_list[4]}
    Comment    @{mac_list}    Create List    ${mac1}    ${mac2}    ${mac3}    ${mac4}
    ...    ${mac5}
    : FOR    ${list}    IN RANGE    0    4
    \    Wait Until Keyword Succeeds    60 sec    10 Sec    Delete Vm Instance    ${VM_list[${list}]}
    \    ${macvalue}    Evaluate    ${list} + 1
    \    log    ${macvalue}
    \    log    ${mac${macvalue}}
    \    Wait Until Keyword Succeeds    60 sec    10 sec    Verify Vm Deletion    ${VM_list[${list}]}    ${mac${macvalue}}
    \    ...    ${conn_id_1}    ${br_name1}
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    neutron security-group-delete \ ${SG_name[0]}    $    40
    ${command}    Set Variable    neutron port-list | grep P31 | awk '{print $2}'
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${port_list}    Split To Lines    ${output}
    ${port_list}    Get Slice From List    ${port_list}    \    -1
    : FOR    ${port}    IN    @{port_list}
    \    ${output}    Write Commands Until Expected Prompt    neutron port-delete ${port}    $    60
    ${command}    Set Variable    neutron port-list | grep P32 | awk '{print $2}'
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${port_list}    Split To Lines    ${output}
    ${port_list}    Get Slice From List    ${port_list}    \    -1
    : FOR    ${port}    IN    @{port_list}
    \    ${output}    Write Commands Until Expected Prompt    neutron port-delete ${port}    $    60
    ${EMPTY}
    Remove Interface    ${Routers[0]}    ${Subnets[0]}
    Remove Interface    ${Routers[0]}    ${Subnets[1]}
    Delete Subnet    ${Subnets[0]}
    Delete Subnet    ${Subnets[1]}
    Delete Router    ${Routers[0]}
    Delete Network    ${Networks[0]}
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-1}    $    10
    Switch Connection    ${conn_id_2}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-2}    $    10

PreSuiteSetUpForTOR
    [Documentation]    This keyword has TOR clean up and TOR emulator set up configurations.
    ${conn_id_3}    Tor Login    ${TOOLS_SYSTEM_3_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_3}
    ${conn_id_4}    Tor Login    ${TOOLS_SYSTEM_4_IP}    ${TOR_USER}    ${TOR_SYSTEM_PASSWORD}    ${TOR_DEPLOY_PATH}
    Set Global Variable    ${conn_id_4}
    Log    >>>TOR1>>>
    TOR Cleanup    ${conn_id_3}    ${tor_bridge[0]}
    TOR Vtep Creation    ${conn_id_3}    ${tor_bridge[0]}    ${tor_tunnel_ip[0]}    ${ODL_SYSTEM_IP}    ${TOR1_OVSDBSOCK}
    Log    >>>TOR2>>>
    TOR Cleanup    ${conn_id_4}    ${tor_bridge[1]}
    TOR Vtep Creation    ${conn_id_4}    ${tor_bridge[1]}    ${tor_tunnel_ip[1]}    ${ODL_SYSTEM_IP}    ${TOR2_OVSDBSOCK}
    Switch Connection    ${conn_id_3}
    Close Connection
    Switch Connection    ${conn_id_4}
    Close Connection

Tor Login
    [Arguments]    ${ip}    ${username}    ${password}    ${tor_path}
    [Documentation]    This keywords allows login to the TOR VM
    ${tor_conn_id}    Open Connection    ${ip}
    set suite variable    ${tor_conn_id}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${tor_path}    \#    30
    [Return]    ${tor_conn_id}

TOR Cleanup
    [Arguments]    ${conn_id}    ${tor_bridge}
    [Documentation]    This keyword cleans up the Existing TOR configurations.
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${tor_bridge}    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ovs-vtep    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ovs-vswitchd    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ovsdb-server    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ovs-master    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ${torvms[0]}    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ${torvms[1]}    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ${torvms[2]}    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ${torvms[3]}    \#    10
    Write Commands Until Expected Prompt    sudo service openvswitch-switch restart    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ovsdb-server    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ovs-vswitchd    \#    10
    Write Commands Until Expected Prompt    sudo killall -9 ovs-master    \#    10
    Write Commands Until Expected Prompt    sudo rm -rf /etc/openvswitch/vtep.db    \#    10
    Write Commands Until Expected Prompt    sudo rm -rf /etc/openvswitch/ovs.db    \#    10

TOR Vtep Creation
    [Arguments]    ${conn_id}    ${tor_bridge}    ${tor_tunnel_ip}    ${odl_ip}    ${ovsdbsock_path}    ${ovs_home}=/root/tor/ovs-master
    [Documentation]    This keyword creates virtual tep for TOR
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    sudo ovsdb-tool create /etc/openvswitch/ovs.db ${ovs_home}/vswitchd/vswitch.ovsschema    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo ovsdb-tool create /etc/openvswitch/vtep.db \ ${ovs_home}/vtep/vtep.ovsschema    \#    10
    Comment    sleep    5
    ${output}    Write Commands Until Expected Prompt    sudo ovsdb-server --pidfile --detach --log-file=/var/log/openvswitch/ovsdb-server.log --remote punix:${ovsdbsock_path}/openvswitch/db.sock --remote=db:hardware_vtep,Global,managers /etc/openvswitch/ovs.db /etc/openvswitch/vtep.db    \#    10
    Log    ${output}
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo ovs-vsctl --no-wait init    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo ovs-vswitchd --pidfile --detach    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-br ${tor_bridge}    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo ovs-vsctl show    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo vtep-ctl add-ps ${tor_bridge}    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo vtep-ctl set Physical_Switch \ ${tor_bridge} \ tunnel_ips=${tor_tunnel_ip}    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo ${ovs_home}/vtep/ovs-vtep --log-file=/var/log/openvswitch/ovs-vtep.log --pidfile=${ovsdbsock_path}/openvswitch/ovs-vtep.pid --detach ${tor_bridge}    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo ps -ef | grep ovs-vtep    \#    10
    Comment    sleep    5
    Write Commands Until Expected Prompt    sudo vtep-ctl set-manager tcp:${odl_ip}:6640    \#    10

Get Network Segmetation Id
    [Arguments]    ${conn_id}    ${network}
    [Documentation]    This keywords returns the network segmentation ID
    Switch Connection    ${conn_id}
    ${op}    Write Commands Until Expected Prompt    neutron net-show ${network} | grep segmentation_id | awk '{print$4}'    $    30
    ${splitted_op}    Split To Lines    ${op}
    ${segmentation_id}    Get From List    ${splitted_op}    0
    [Return]    ${segmentation_id}

Get Network Id
    [Arguments]    ${conn_id}    ${network}
    [Documentation]    THis keyword gets the network Id.
    Switch Connection    ${conn_id}
    ${op}    Write Commands Until Expected Prompt    neutron net-list | grep ${network} | awk '{print$2}'    $    30
    ${splitted_op}    Split To Lines    ${op}
    ${net_id}    Get From List    ${splitted_op}    0
    [Return]    ${net_id}

fetch mac and ip
    [Arguments]    ${port}
    [Documentation]    THis keyword fetches the MAC and IP of the neutron ports created.
    ${op}    Write Commands Until Expected Prompt    neutron port-show ${port} | grep fixed_ips | awk '{print $7}'    $    30
    ${templ1}    Split To Lines    ${op}
    ${str1}    Get From List    ${templ1}    0
    ${ip_addr}    Strip String    ${str1}
    ${ip_addr}    String.Remove String    ${ip_addr}    "    }
    ${op}    Write Commands Until Expected Prompt    neutron port-show ${port} |grep mac_address | awk '{print $4}'    $    30
    ${templ1}    Split To Lines    ${op}
    ${mac}    Get From List    ${templ1}    0
    [Return]    ${ip_addr}    ${mac}

check ip address in ifconfig output
    [Arguments]    ${virshid}    ${cmd}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    ...    ${DEVSTACK_DEPLOY_PATH}    ${username}    ${pwd}    ${vmprompt}
    ${output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    ${username}
    ...    ${pwd}    ${vmprompt}
    [Return]    ${output}

Create Neutron Port And Extract MAC And IP
    [Arguments]    ${network}    ${port}
    [Documentation]    THis keyword creates the neutron port and returns the mac and IP of the created neutron ports.
    ${output}    Create neutron port    ${network}    ${port}
    log    ${output}
    Comment    Should Contain    ${output}    Created a new port:
    ${op}    Write Commands Until Expected Prompt    neutron port-show ${port} | grep fixed_ips | awk '{print $7}'    $    30
    ${templ1}    Split To Lines    ${op}
    ${str1}    Get From List    ${templ1}    0
    ${ip_addr}    Strip String    ${str1}
    ${ip_addr}    String.Remove String    ${ip_addr}    "    }
    ${op}    Write Commands Until Expected Prompt    neutron port-show ${port} |grep mac_address | awk '{print $4}'    $    30
    ${templ1}    Split To Lines    ${op}
    ${mac}    Get From List    ${templ1}    0
    [Return]    ${ip_addr}    ${mac}

Create neutron port
    [Arguments]    ${network_name}    ${port_name}
    [Documentation]    This keyword creates the neutron port
    Switch Connection    ${conn_id_1}
    ${output}    Write Commands Until Expected Prompt    neutron port-create ${network_name} --name ${port_name}    $    30
    Log    ${output}
    Should Contain    ${output}    Created a new port
    [Return]    ${output}

verify ovs
    [Arguments]    ${conn_id}    ${remoteip_list}    ${pmt}=$
    [Documentation]    This keyword verifies the tunnel IPs on OVS.
    Switch Connection    ${conn_id}
    ${output}    Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${pmt}    30
    log    ${output}
    : FOR    ${elem}    IN    @{remoteip_list}
    \    Should Contain    ${output}    ${elem}

hwvtep table check
    [Arguments]    ${conn_id}    ${match}    ${validation_list}
    [Documentation]    This keyword checks the hardware vtep table for a specific table entries which is passed as an argument.
    Switch Connection    ${conn_id}
    ${output}    Write Commands Until Expected Prompt    ovsdb-client dump \ hardware_vtep | ${match}    \#    30
    log    ${output}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${output}    ${elem}
