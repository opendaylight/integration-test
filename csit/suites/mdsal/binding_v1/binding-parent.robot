*** Settings ***
Documentation     Suite for testing performance of Java binding v1 using binding-parent.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite tests performance of binding-parent from Mdsal project.
...               It measures time (only as a test case duration) needed to create Java bindings (v1).
...               It uses large set of Yang modules, collected from YangModels and openconfig
...               github projects.
...               Some modules are removed prior to testing, as they either do not conform to RFC6020,
...               or they trigger known Bugs in ODL.
...               Known Bugs: 6125, 6135, 6141, 2323, 6150, 2360, 138, 6172, 6180, 6183, 5772, 6189.
...
...               The suite performs installation of Maven, optionally with building patched artifacts.
Suite Setup       Setup_Suite
Test Setup        FailFast.Fail_This_Fast_On_Previous_Error
Test Teardown     Teardown_Test
Default Tags      1node    binding_v1    critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${BRANCH}         ${EMPTY}
${MAVEN_OUTPUT_FILENAME}    maven.log
${PATCHES_TO_BUILD}    ${EMPTY}
${POM_FILENAME}    binding-parent-test.xml

*** Test Cases ***
Kill_Odl
    [Documentation]    The ODL instance consumes resources, kill it.
    ClusterManagement.Kill_Members_From_List_Or_All

Detect_Config_Version
    [Documentation]    Examine ODL installation to figure out which version of binding-parent should be used.
    ...    Parent poms are not present in Karaf installation, and NexusKeywords assumes we want an artifact ending with -impl,
    ...    so mdsal-binding-generator is given as a component version of which we are interested in.
    ${version}    ${location} =    NexusKeywords.NexusKeywords__Detect_Version_To_Pull    component=mdsal-binding-generator
    BuiltIn.Set_Suite_Variable    \${binding_parent_version}    ${version}

Install_Maven
    [Documentation]    Install Maven, optionally perform multipatch build.
    NexusKeywords.Install_Maven    branch=${BRANCH}    patches=${PATCHES_TO_BUILD}

Prepare_Yang_Files_To_Test
    [Documentation]    Cleanup possibly leftover directories, clone git repos and remove unwanted paths.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf target src
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p src/main
    SSHKeywords.Set_Cwd    src/main
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone https://github.com/YangModels/yang
    SSHKeywords.Set_Cwd    src/main/yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git checkout -b ytest f4b09f38ac4b794e4e9b2e8646f326eccf556fe5    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf tools
    SSHKeywords.Set_Cwd    src/main/yang/experimental
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf openconfig
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone https://github.com/openconfig/public
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mv -v public openconfig
    SSHKeywords.Set_Cwd    src/main/yang/experimental/openconfig
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git checkout -b ytest 8bd7aafde63785880fe192174e5b075105ab97cb    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    src/main/yang
    Delete_Paths

Run_Maven
    [Documentation]    Create pom file with correct version and run maven with some performance switches.
    ${final_pom} =    TemplatedRequests.Resolve_Text_From_Template_File    folder=${CURDIR}/../../../variables/mdsal/binding_v1/    file_name=binding_template.xml    mapping={"BINDING_PARENT_VERSION":"${binding_parent_version}"}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    echo '${final_pom}' > '${POM_FILENAME}'
    NexusKeywords.Run_Maven    pom_file=${POM_FILENAME}    log_file=${MAVEN_OUTPUT_FILENAME}
    # TODO: Figure out patters to identify various known Bug symptoms.

Collect_Filest_To_Archive
    [Documentation]    Download created files so Releng scripts would archive it. Size of maven log is usually under 7 megabytes.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    SSHKeywords.Open_Connection_To_ODL_System    # The original one may have timed out.
    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Get_File    ${MAVEN_DEFAULT_OUTPUT_FILENAME}    # only present if multipatch build happened
    SSHLibrary.Get_File    settings.xml
    SSHLibrary.Get_File    ${POM_FILENAME}
    SSHLibrary.Get_File    ${MAVEN_OUTPUT_FILENAME}

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage    tools_system_connect=False
    SSHKeywords.Open_Connection_To_ODL_System

Teardown_Test
    [Documentation]    Make sure CWD is set back to dot, then proceed with SetupUtils stuff.
    SSHKeywords.Set_Cwd    .
    SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed

Delete_Paths
    [Documentation]    Long list of "rm -vrf" commands.
    ...    TODO: Document exact reasons for each particular removed path.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/ACL-MODEL/filter_template.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/ACL-MODEL/filter.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/hncp-topology.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/IETF-ENTITY
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/IETF-TIME
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/ODL-PATHS
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
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/telemetry
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
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-inet-types
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
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-yang-types
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
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/530
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/531
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/532
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/533
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/600
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
