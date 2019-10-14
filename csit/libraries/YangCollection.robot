*** Settings ***
Documentation     Resource for preparing various sets of Yang files to be used in testing.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Keywords in this Resource assume there is an active SSH connection
...               to system where a particular set of Yang files is to be created.
...               The keywords will change current working directory used by SSHKeywords.
...
...               Currently only one set is supported, called Static.
...               The set will not change in future
...               and it does not include files which lead to binding v1 bugs.
...
...               TODO: Do we want to support Windoes path separators?
Resource          ${CURDIR}/SSHKeywords.robot

*** Keywords ***
Static_Set_As_Src
    [Arguments]    ${root_dir}=.
    [Documentation]    Cleanup possibly leftover directories (src and target), clone git repos and remove unwanted paths.
    SSHKeywords.Set_Cwd    ${root_dir}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf target src
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p src/main
    SSHKeywords.Set_Cwd    ${root_dir}/src/main
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone https://github.com/YangModels/yang    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf tools
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang/experimental
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf openconfig
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone https://github.com/openconfig/public    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mv -v public openconfig
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang/experimental/openconfig
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang
    Delete_Static_Paths

Delete_Static_Paths
    [Documentation]    Long list of "rm -vrf" commands.
    ...    TODO: Document exact reasons for each particular removed path.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/ACL-MODEL/filter_template.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/ACL-MODEL/filter.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/hncp-topology.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/IETF-ENTITY/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/IETF-TIME/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/ODL-PATHS/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/bgp/openconfig-bgp-policy.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/bgp/openconfig-bgp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/mpls/openconfig-mpls-igp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/mpls/openconfig-mpls-rsvp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/mpls/openconfig-mpls-static.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/mpls/openconfig-mpls-te.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/mpls/openconfig-mpls.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/network-instance/openconfig-network-instance.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/optical-transport/openconfig-optical-amplifier.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/optical-transport/openconfig-terminal-device.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/optical-transport/openconfig-transport-line-common.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/platform/openconfig-platform-transceiver.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/platform/openconfig-platform.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/rib/openconfig-rib-bgp-ext.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/rib/openconfig-rib-bgp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/rpc/openconfig-rpc.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/telemetry/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/vendor/cisco/common/cisco-link-oam.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/802.1/draft/ieee-dot1x.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-bfd.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-ipv4-unicast-routing.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-ipv6-unicast-routing.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-isis.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-keychain.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-netconf-server.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-restconf-server.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-routing.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-ssh-server.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-system-tls-auth.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-tls-server.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-zerotouch-bootstrap-server.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/newco-acl.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-inet-types/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-netconf-time@2016-01-26.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-common.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-community.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-engine.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-notification.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-proxy.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-ssh.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-target.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-tls.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-tsm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-usm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp-vacm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-x509-cert-to-name.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-yang-library@2016-06-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-yang-types/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-aaa.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-ag.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-arp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-bum-storm-control.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-cdp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-chassis.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-dhcp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-diagnostics.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-dot1x.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-eld.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-fabric-service.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-fcoe-ext.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-fcoe.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-hardware.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-hidden-cli.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-igmp-snooping.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-igmp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-interface-ext.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-interface.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-intf-loopback.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-ip-access-list.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-ip-config.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-ip-forward.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-ip-policy.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-ipv6-access-list.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-lacp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-lag.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-license.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-lldp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-mac-access-list.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-mac-address-table.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-ntp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-ospf.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-pim.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-policer.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-port-profile-ext.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-port-profile.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-qos.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-rmon.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-rtm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-sflow.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-span.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-trilloam.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-udld.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-vlan.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-vrrp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-vswitch.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-xstp-ext.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/brocade-xstp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/brocade/mpls.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/530/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/531/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/532/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/533/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/600/
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-aaa-tacacs-cfg.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-clns-isis-cfg.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-l2vpn-oper-sub1.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-l2vpn-oper-sub2.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-l2vpn-oper-sub3.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-l2vpn-oper-sub4.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-l2vpn-oper.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-lib-keychain-oper-sub1.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-lib-keychain-oper.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-lpts-pre-ifib-oper-sub1.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-lpts-pre-ifib-oper.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-mpls-te-cfg.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-platform-pifib-oper-sub1.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-platform-pifib-oper.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-watchd-cfg.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/Cisco-IOS-XR-wd-cfg.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/cisco-openconfig-mpls-devs.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/cisco-xr-bgp-deviations.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/cisco-xr-bgp-policy-deviations.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/601/cisco-xr-routing-policy-deviations.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/yumaworks/yangcli-pro.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/yumaworks/yumaworks-db-api.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/yumaworks/yumaworks-sil-sa.yang
