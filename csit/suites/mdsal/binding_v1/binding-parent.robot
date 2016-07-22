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
...               Config-parent comes from controller project, but the majority of time is spent
...               on generating Java binding v1, so this is performance test for Mdsal project functionality.
...
...
...               Some Yang modules do not conform to RFC6020, some trigger known Bugs in ODL.
...               Known Bugs: 6125, 6135, 6141, 2323, 6150, 2360, 138, 6172, 6180, 6183, 5772, 6189.
Suite Setup       Setup_Suite    # ...    FIXME: Rewrite the rest of Documentation.    # ...    # ...    This suite kills the running (newer) ODL at its default location.    # ...
...               # It then installs (configurable) older ODL to an alternative location,    # ...    pushes large amount of car data, verifies and kills the older ODL.    # ...    The journal and snapshot files are transferred to the default location    # ...    and the newer ODL is started.
...               # ...    Then it verifies the config data is still present and matches what was seen before.    # ...    # ...    In principle, the suite should also work if "newer" ODL is in fact older.    # ...    The limiting factor is featuresBoot, the value should be applicable to both ODL versions.
...               # ...    # ...    Note that in order to create traffic large enough for snapshots to be created,    # ...    this suite also actis as a stress test for Restconf.    # ...    But as that is not a primary focus of this suite,
...               # ...    data seen on newer ODL is only compared to what was seen on the older ODL    # ...    (stored in ${data_before} suite variable).    # ...    # ...    As using Robotframework would be both too slow and too memory consuming,
...               # ...    this suite uses a specialized Python utility for pushing the data locally on ODL_SYSTEM.    # ...    The utility filename is configurable, as there may be changes in PATCH behavior in future.    # ...    # ...    This suite uses relatively new support for PATCH http method.
...               # ...    It repetitively replaces a segment of cars with moving IDs,    # ...    so that there is a lot of data in journal (both write and delete),    # ...    but the overall size of data stored remains limited.    # ...
...               # ...    This is 1-node suite, but it still uses ClusterManagement.Check_Cluster_Is_In_Sync    # ...    in order to detect the same sync condition as 3-node suite would do.    # ...    Jolokia feature is required for that.    # ...
...               # ...    Minimal set of features to be installed: odl-restconf, odl-jolokia, odl-clustering-test-app.
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     Teardown_Test
Default Tags      1node    binding_v1    critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${BINDING_TEMPLATE_FILEPATH}    ${CURDIR}/../../../variables/mdsal/binding_v1/binding_template.xml
${MAVEN_OUTPUT_FILENAME}    maven.log
${MAVEN_REPOSITORY_PATH}    /tmp/r
${MAVEN_SETTINGS_URL}    https://github.com/opendaylight/odlparent/blob/master/settings.xml
#${MAVEN_SETTINGS_URL}    https://git.opendaylight.org/gerrit/gitweb?p=odlparent.git;a=blob_plain;f=settings.xml;hb=refs/heads/master
${MAVEN_VERSION}    3.3.9
${POM_FILENAME}    binding-parent-test.xml

*** Test Cases ***
Kill_Odl
    [Documentation]    The ODL consumes resources, kill it.
    ClusterManagement.Kill_Members_From_List_Or_All

Detect_Config_Version
    [Documentation]    Examine ODL installation to figure out which version of config-parent should be used.
    ...    Parent poms are not present in Karaf installation, and NexusKeywords assumes we want artifact ending with -impl,
    ...    so mdsal-binding-generator is given as a component version of which we are interested in.
    ${version}    ${location}    NexusKeywords.NexusKeywords__Detect_Version_To_Pull    component=mdsal-binding-generator
    BuiltIn.Set_Suite_Variable    \${binding_parent_version}    ${version}

Install_Maven
    [Documentation]    Download and unpack Maven 3.3.9, prepare launch command with proper Java version.
    BuiltIn.Set_Suite_Variable    \${maven_directory}    apache-maven-${MAVEN_VERSION}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf '${maven_directory}'
    ${maven_archive_filename} =    BuiltIn.Set_Variable    ${maven_directory}-bin.tar.gz
    ${maven_download_url} =    BuiltIn.Set_Variable    http://www-us.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/${maven_archive_filename}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    wget -N '${maven_download_url}'    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    tar xf '${maven_archive_filename}'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    ls -l '${maven_directory}'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    ls -l '${maven_directory}/bin/mvn'
    ${java_home} =    NexusKeywords.Compose_Java_Home
    BuiltIn.Set_Suite_Variable    \${maven_bash_command}    export JAVA_HOME='${java_home}' && ./${maven_directory}/bin/mvn
    # TODO: Get settings files from Jenkins settings provider, somehow.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    wget '${MAVEN_SETTINGS_URL}' -O settings.xml    stderr_must_be_empty=False

Prepare_Yang_Files_To_Test
    [Documentation]    Cleanup possibly leftover directories, clone git repos and remove unwanted paths.
    ...    FIXME: Document exact reasons for each particular removed path.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf target src
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p src/main
    SSHKeywords.Set_Cwd    src/main
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf java yang
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
    [Documentation]    Create pom file with correct version.and run maven with some performance switches, redirect output to a file.
    ${final_pom} =    TemplatedRequests.Resolve_Text_From_Template_File    file_path=${BINDING_TEMPLATE_FILEPATH}    mapping={"BINDING_PARENT_VERSION":"${binding_parent_version}"}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    echo '${final_pom}' > '${POM_FILENAME}'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p '${MAVEN_REPOSITORY_PATH}'
#    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    cp -v 'settings.xml' '${MAVEN_REPOSITORY_PATH}'
    ${maven_options} =    BuiltIn.Set_Variable    -Dmaven.repo.local=${MAVEN_REPOSITORY_PATH} -Dorg.ops4j.pax.url.mvn.localRepository=${MAVEN_REPOSITORY_PATH} -DskipTests -Dcheckstyle.skip=true -Dmaven.javadoc.skip=true -Dmaven.site.skip=true -DgenerateReports=false
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    ${maven_bash_command} clean install dependency:tree -V -B -DoutputFile=dependency_tree.log -s './settings.xml' -f '${POM_FILENAME}' ${maven_options} > '${MAVEN_OUTPUT_FILENAME}'
    # TODO: Figure out patters to identify various known Bug symptoms.

Collect_Filest_To_Archive
    [Documentation]    Download log so Releng scripts would archive it. Size is usually under 7 megabytes.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    SSHLibrary.Get_File    settings.xml
    SSHLibrary.Get_File    ${POM_FILENAME}
    SSHLibrary.Get_File    ${MAVEN_OUTPUT_FILENAME}

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection, copy Python utility.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage    tools_system_connect=False
    ${connection} =    SSHKeywords.Open_Connection_To_ODL_System

Teardown_Test
    [Documentation]    Make sure CWD is set back to dot, then proceed with SetupUtils stuff.
    SSHKeywords.Set_Cwd    .
    SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed

Delete_Paths
    [Documentation]    Long list of "rm -vrf" commands.
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
