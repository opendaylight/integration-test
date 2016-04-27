*** Settings ***
Documentation     Bug 4462 test suite.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Try to detect whether Karaf hangs when trying to install
...               "odl-integration-compatible-with-all".
Suite Setup       Setup_karaf-hang
Resource          ${CURDIR}/../../../libraries/Setup.Utils.robot    #Suite Teardown    Teardown_Everything    #Library    RequestsLibrary
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/cluster_reset.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${KARAF_CHECK_TIMEOUT}    3m

*** Testcases ***
Try_To_Install_Compatible_With_All
    [Documentation]    Try to install current list of compatible features and check whether Karaf hangs on it or not (bug 4462).
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-integration-comptible-with-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-aaa-authn    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-aaa-authz    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-aaa-shiro    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-aaa-netconf-plugin    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-aaa-sssd-plugin    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-bgpcep-bgp-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-bgpcep-bmp    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-bgpcep-pcep-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-bgpcep-rsvp    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-capwap-ac-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-cardinal    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-didm-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-dlux-core    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-distribution-version    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-eman    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-eman-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-eman-ui    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-lispflowmapping-msmr    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-lispflowmapping-ui    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-mdsal-benchmark    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-mdsal-broker    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-nemo-engine    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-nemo-engine-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-nemo-engine-ui    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-netconf-connector-ssh    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-neutron-service    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-ocpplugin-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-openflowplugin-flow-services    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-openflowplugin-flow-services-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-openflowplugin-flow-services-ui    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-openflowplugin-nxm-extensions    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-ovsdb-hwvtepsouthbound    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-ovsdb-library    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-ovsdb-southbound-impl    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-packetcable-policy-server-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-restconf-noauth    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sdninterfaceapp-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sfc-netconf    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sfc-ovs    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sfc-sb-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sfc-test-consumer    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sfc-ui    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sfclisp    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sxp-controller    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-snmp-plugin    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-topoprocessing-i2rs    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-topoprocessing-inventory    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-topoprocessing-inventory-rendering    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-topoprocessing-mlmt    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-topoprocessing-network-topology    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-ttp-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-unimgr    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-usc-channel    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-usc-channel-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-usc-channel-ui    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-usecplugin-aaa    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-usecplugin-openflow    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-alto-release    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-atrium-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-faas-base    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-genius-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-faas    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-iovisor    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-neutronmapper    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-neutron-and-ofoverlay    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-neutron-vpp-mapper    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-ne-location-provider    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-ofoverlay    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-sxp-mapper    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-ui    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-groupbasedpolicy-vpp    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-integration-compatible-with-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-l2switch-switch    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-l2switch-switch-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-l2switch-switch-ui    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-natapp    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-natapp-api    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-netvirt-openstack    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-netvirt-openstack-sfc-translator    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-of-config-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-ovsdb-openstack    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-ovsdb-sfc    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-snbi-all    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-sfc-openflow-renderer    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-vtn-manager-neutron    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-vtn-manager-rest    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-yangpush    timeout=${KARAF_CHECK_TIMEOUT}
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-yangpush-api    timeout=${KARAF_CHECK_TIMEOUT}

*** Keywords ***
Setup_karaf-hang
    [Documentation]    Stop Karaf launched by releng/builder scripts, start it by running "bin/karaf clean". 
    cluster_reset.Kill_All_And_Get_Logs
    cluster_reset.Clean_Start_All_And_Sync
    SetupUtils.Setup_Utils_For_Setup_And_Teardown