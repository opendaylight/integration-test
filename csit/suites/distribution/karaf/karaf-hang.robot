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
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot
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
    [Template]    Install with time limit
    odl-integration-comptible-with-all
    odl-aaa-authn
    odl-aaa-authz
    odl-aaa-shiro
    odl-aaa-netconf-plugin
    odl-aaa-sssd-plugin
    odl-bgpcep-bgp-all
    odl-bgpcep-bmp
    odl-bgpcep-pcep-all
    odl-bgpcep-rsvp
    odl-capwap-ac-rest
    odl-cardinal
    odl-didm-all
    odl-dlux-core
    odl-distribution-version
    odl-eman
    odl-eman-rest
    odl-eman-ui
    odl-lispflowmapping-msmr
    odl-lispflowmapping-ui
    odl-mdsal-benchmark
    odl-mdsal-broker
    odl-nemo-engine
    odl-nemo-engine-rest
    odl-nemo-engine-ui
    odl-netconf-connector-ssh
    odl-neutron-service
    odl-ocpplugin-all
    odl-openflowplugin-flow-services
    odl-openflowplugin-flow-services-rest
    odl-openflowplugin-flow-services-ui
    odl-openflowplugin-nxm-extensions
    odl-ovsdb-hwvtepsouthbound
    odl-ovsdb-library
    odl-ovsdb-southbound-impl
    odl-packetcable-policy-server-all
    odl-restconf-noauth
    odl-sdninterfaceapp-all
    odl-sfc-netconf
    odl-sfc-ovs
    odl-sfc-sb-rest
    odl-sfc-test-consumer
    odl-sfc-ui
    odl-sfclisp
    odl-sxp-controller
    odl-snmp-plugin
    odl-topoprocessing-i2rs
    odl-topoprocessing-inventory
    odl-topoprocessing-inventory-rendering
    odl-topoprocessing-mlmt
    odl-topoprocessing-network-topology
    odl-ttp-all
    odl-unimgr
    odl-usc-channel
    odl-usc-channel-rest
    odl-usc-channel-ui
    odl-usecplugin-aaa
    odl-usecplugin-openflow
    odl-alto-release
    odl-atrium-all
    odl-faas-base
    odl-genius-rest
    odl-groupbasedpolicy-faas
    odl-groupbasedpolicy-iovisor
    odl-groupbasedpolicy-neutronmapper
    odl-groupbasedpolicy-neutron-and-ofoverlay
    odl-groupbasedpolicy-neutron-vpp-mapper
    odl-groupbasedpolicy-ne-location-provider
    odl-groupbasedpolicy-ofoverlay
    odl-groupbasedpolicy-sxp-mapper
    odl-groupbasedpolicy-ui
    odl-groupbasedpolicy-vpp
    odl-integration-compatible-with-all
    odl-l2switch-switch
    odl-l2switch-switch-rest
    odl-l2switch-switch-ui
    odl-natapp
    odl-natapp-api
    odl-netvirt-openstack
    odl-netvirt-openstack-sfc-translator
    odl-of-config-all
    odl-ovsdb-openstack
    odl-ovsdb-sfc
    odl-snbi-all
    odl-sfc-openflow-renderer
    odl-vtn-manager-neutron
    odl-vtn-manager-rest
    odl-yangpush
    odl-yangpush-api

*** Keywords ***
Setup_karaf-hang
    [Documentation]    Stop Karaf launched by releng/builder scripts, start it by running "bin/karaf clean".
    cluster_reset.Kill_All_And_Get_Logs
    cluster_reset.Clean_Start_All_And_Sync
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Install with time limit
    [Arguments]    ${feature}
    [Documentation]    Template for ODL feature:install with the given timeout.
    KarafKeywords.Issue_Command_On_Karaf_Console    ${cmd}=feature:install    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    timeout=${KARAF_CHECK_TIMEOUT}    ${loglevel}=INFO
