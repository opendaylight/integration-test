*** Settings ***
Documentation     A resource file containing all global Yangman GUI variables
...               to help Yangman GUI and functional testing.
Resource          IPV6Service_Variables.robot

*** Variables ***
@{Networks}       mynet1    mynet2    mynet3
@{Subnets}        ipv6s1    ipv6s2    ipv6s3    ipv6s4
@{VM_list}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
@{Routers}        router1    router2
@{Prefixes}       2001:db8:1234::    2001:db8:5678::    2001:db8:4321::    2001:db8:6789::
@{V4subnets}      13.0.0.0    14.0.0.0
@{V4subnet_names}    subnet1v4    subnet2v4
@{login_credentials}    stack    stack    root    password
${ipv6securitygroups_config_dir}    ${CURDIR}/../../variables/ipv6securitygroups
@{SG_name}        SG1    SG2    SG3    SG4    default
@{rule_list}      tcp    udp    icmpv6    10000    10500    IPV6    # protocol1, protocol2, protocol3, port_min, port_max, ether_type
@{direction}      ingress    egress    both
@{Image_Name}     cirros-0.3.4-x86_64-uec    ubuntu-sg
@{protocols}      tcp6    udp6    icmp6
@{remote_group}    SG1    prefix    any
@{remote_prefix}    ::0/0    2001:db8:1234::/64    2001:db8:4321::/64
@{logical_addr}    2001:db8:1234:0:1111:2343:3333:4444    2001:db8:1234:0:1111:2343:3333:5555
@{flavour_list}    m1.nano    m1.tiny
@{itm_created}    TZA
${br_name}        br-int
${Bridge-1}       br0
${Bridge-2}       br0
@{dpip}           20.0.0.9    20.0.0.10
${Interface-1}    eth1
${Interface-2}    eth1
@{Tables}         table=0    table=17    table=40    table=41    table=45    table=50    table=51
...               table=60    table=220    table=251    table=252
${invalid_Subnet_Value}    2001:db8:1234::/21
@{Ports}          tor1_port1    tor1_port2    tor2_port1    tor2_port2
@{tor_bridge}     br-tor    br-tor1
@{tor_tunnel_ip}    20.0.0.56    20.0.0.147
@{torvms}         tor1vm1    tor1vm2    tor2vm1    tor2vm2
