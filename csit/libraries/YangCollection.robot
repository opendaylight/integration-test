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
...               The two repos used in this suite ${YANGMODELS_REPO} and ${OPENCONFIG_REPO}
...               have been updated:
...               04/07/2020
...
Resource          ${CURDIR}/SSHKeywords.robot

*** Variables ***
${YANGMODELS_REPO}    https://github.com/YangModels/yang
${OPENCONFIG_REPO}    https://github.com/openconfig/public
${YANGMODELS_REPO_COMMIT_HASH}    7351cec0c92d7fed74ae4a7c10f6bf4d32a95fa6    # TODO: update docs with new date when changing
${OPENCONFIG_REPO_COMMIT_HASH}    e3c0374ce6aa9d1230ea31a5f0f9a739ed0db308    # TODO: update docs with new date when changing
# ${PARSING_PATHS} is needed to explicitly tell which paths to find yang files to build dependencies from to validate the
# yang file being validated. There is an option (-r) to recursively parse so that you don't have to pass all of these
# paths with the -p argument, but the recursive option makes the tool so slow that it would not work when testing so
# many files
${PARSING_PATHS}    -p /home/jenkins/src/main/yang/experimental/ietf-extracted-YANG-modules -p /home/jenkins/src/main/yang/experimental/openconfig/release/models -p /home/jenkins/src/main/yang/standard/ietf/DRAFT -p /home/jenkins/src/main/yang/standard/ietf/RFC -p /home/jenkins/src/main/yang/experimental/ieee -p /home/jenkins/src/main/yang/experimental/ietf -p /home/jenkins/src/main/yang/experimental/mano-models -p /home/jenkins/src/main/yang/experimental/odp -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/acl -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/aft -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/bfd -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/bgp -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/catalog -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/interfaces -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/isis -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/lacp -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/lldp -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/local-routing -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/macsec -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/mpls -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/multicast -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/network-instance -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/openflow -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/optical-transport -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/ospf -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/platform -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/policy -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/policy-forwarding -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/probes -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/qos -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/relay-agent -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/rib -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/segment-routing -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/stp -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/system -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/telemetry -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/types -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/vlan -p /home/jenkins/src/main/yang/experimental/openconfig/release/models/wifi -p /home/jenkins/src/main/yang/standard/ieee/draft/802.1/ABcu -p /home/jenkins/src/main/yang/standard/ieee/draft/802.1/AEdk -p /home/jenkins/src/main/yang/standard/ieee/draft/802.1/CBdb -p /home/jenkins/src/main/yang/standard/ieee/draft/802.1/Qcr -p /home/jenkins/src/main/yang/standard/ieee/draft/802.1/Qcw -p /home/jenkins/src/main/yang/standard/ieee/draft/802.1/Qcw -p /home/jenkins/src/main/yang/standard/ieee/published/802.1 -p /home/jenkins/src/main/yang/vendor/ciena -p /home/jenkins/src/main/yang/vendor/fujitsu -p /home/jenkins/src/main/yang/vendor/huawei -p /home/jenkins/src/main/yang/vendor/nokia

*** Keywords ***
Static_Set_As_Src
    [Arguments]    ${root_dir}=.
    [Documentation]    Cleanup possibly leftover directories (src and target), clone git repos and remove unwanted paths.
    ...    YangModels/yang and openconfig/public repos should be updated from time to time, but they are frozen to
    ...    ${YANGMODELS_REPO_COMMIT_HASH} and ${OPENCONFIG_REPO_COMMIT_HASH} to prevent the chance that updates to those
    ...    repos with problems will cause ODL CSIT to fail. There are obvious failures in these repos already, and those
    ...    are addressed by removing those files/dirs with the Delete_Static_Paths keyword.
    SSHKeywords.Set_Cwd    ${root_dir}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf target src
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p src/main
    SSHKeywords.Set_Cwd    ${root_dir}/src/main
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone ${YANGMODELS_REPO}    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git checkout -b ytest ${YANGMODELS_REPO_COMMIT_HASH}    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang/experimental
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf openconfig
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone ${OPENCONFIG_REPO}    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mv -v public openconfig
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang/experimental/openconfig
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git checkout -b ytest ${OPENCONFIG_REPO_COMMIT_HASH}    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang

Delete_Static_Paths
    [Documentation]    Long list of "rm -vrf" commands.
    ...    All files/paths removed below are due to real issues in those files/paths as found with failures in
    ...    the yang-model-validator tool. We do not want OpenDaylight CSIT to fail because of problems with
    ...    external yangs.
    # Please keep below list in alpha order
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf .git
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-2015@2016-12-20.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-components.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-information.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-math.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-metrics.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-si-units.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-system.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-thermodynamics.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/802.1/ni-ieee802-dot1as.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/@2015-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/BATTERY-MIB@2015-06-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/TCP-MIB@2005-02-18.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/TUDA-V1-ATTESTATION-MIB@2017-10-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/abstract-topology@2014-07-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/alto-service-types@2015-03-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/alto-service@2015-03-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/bfd-routing-app@2015-02-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/bfd.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/bgp-l3vpn@2015-10-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/bgp-policy@2015-05-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/bgp@2015-05-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/cira-shg-mud@2019-07-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/dot1q-tag-types@2016-07-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/draft-gonzalez-netconf-5277bis-00@2016-03-20.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/draft-gonzalez-netmod-5277-00@2016-03-20.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/draft-ietf-ccamp-dwdm-if-param-yang-03@2020-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/example-5g-core-network@2017-12-28.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/example-5g-core-network@2017-12-28.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/example-rip@2012-10-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/finite-state-machine@2016-03-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/flexi-grid-TED@2015-07-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/flexible-encapsulation@2015-10-19.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/gen-oam@2014-10-23.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/hardware-entities.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/huawei-dhcp@2014-12-18.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/huawei-ipte@2014-08-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/i2rs-rib@2015-04-03.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/i2rs-service-topology@2015-07-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/iana-civic-address-type@2014-05-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/iana-geo-uri-type@2014-05-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-5277-netmod@2016-06-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-OPSAWG-te-tunnel.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-OPSAWG-ute-tunnel.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-acl-dnsname@2016-01-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-acl@2015-03-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ambi@2019-08-25.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-extensions@2016-07-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-l3vpn@2018-04-17.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-policy@2020-02-24.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-rib-shared-attributes@2019-03-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-sr@2018-06-26.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bier-oam@2017-06-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bier-rpcs@2018-08-28.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bier@2019-05-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-brski-possession@2018-10-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bulk-notification@2019-09-23.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-cfm@2017-03-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-connectionless-oam-methods@2017-09-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-connectionless-oam@2017-09-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-data-export-capabilities.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-diffserv-action@2015-04-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-diffserv-classifier@2015-04-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-diffserv-policy@2015-04-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dmm-fpc-base@2017-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dmm-fpc-pmip@2017-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dmm-fpc-policyext@2017-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dmm-threegpp@2017-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dots-access-control-list@2017-11-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-entity@2016-05-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fabric-capable-device@2016-09-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fabric-endpoint@2017-06-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fabric-service-types@2017-08-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fabric-service@2017-08-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fb-rib-types@2017-03-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fb-rib@2017-03-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flex-algo@2019-04-26.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flex-grid-media-channel@2018-10-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flex-grid-topology@2018-10-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flexi-grid-media-channel@2019-03-24.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flexi-grid-topology@2019-07-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gen-oam-ais@2016-06-25.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gen-oam-pm@2015-01-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gen-oam@2015-04-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gre-tunnel@2015-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gre@2015-07-02.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-http-client@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-http-subscribed-notifications@2018-06-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-https-notif@2020-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-i2nsf-policy-rule-for-nsf@2019-11-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ip-tunnel@2016-06-20.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipipv4-tunnel-02@2015-10-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipipv4-tunnel@2015-10-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipv6-router-advertisements-2@2017-10-05.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipv6-router-advertisements@2018-01-25.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipv6-unicast-routing-2@2017-10-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipv6-unicast-routing@2018-01-25.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-isis-bfd@2015-11-18.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-keystore@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-l2vpn-igmp-mld-snooping@2017-03-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-l3vpn@2015-10-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-library-tags@2017-08-12.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-lime-bfd-extension@2014-08-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-lisp-petr@2016-06-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-lisp-pitr@2016-06-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-location@2014-05-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-management-plane-security@2018-06-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-mldp-extended@2018-10-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-mldp@2018-10-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-global@2014-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-links@2014-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-lsps@2014-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-tunnel-ifs@2014-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te@2014-11-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-tp-topology@2019-03-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-tp-tunnel@2019-03-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mplstpoam@2017-10-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-multicast-service@2016-02-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mvpn@2019-12-02.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-nacm@2010-10-25.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-client@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-error-parameters@2013-07-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-light@2012-01-12.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-server-new@2015-07-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-server@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-subscribed-notifications@2018-08-03.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-notification-capabilities@2020-03-23.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-nvo3-base@2020-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-nvo3@2019-04-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-odu-topology@2016-07-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-optical-impairment-topology@2019-05-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ospf-bfd@2016-10-31.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ospf-bfd@2016-10-31.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ospf-ppr@2019-07-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-otn-service@2016-06-24.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-otn-tunnel@2020-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-pcep-srv6@2019-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-pcep-stats@2019-10-31.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-pcep@2019-10-31.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-qos@2016-10-20.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rats-attestation-stream@2020-03-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-restconf-client@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-restconf-collection@2015-01-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-restconf-server-new@2015-07-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-restconf-server@2019-10-18.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rfc7210@2015-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rib-extension@2020-03-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rsvp-te-psc@2015-10-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-schema-selection@2020-02-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-schema-version-selection@2019-10-31.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sd-onos-service-l3vpn@2015-12-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sd-onos-service-types@2015-12-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sfc-oam@2016-11-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-common@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-community@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-engine@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-notification@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-proxy@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-security@2018-10-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-ssh@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-target@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-tls@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-tsm@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-usm@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp-vacm@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-snmp@2014-05-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ssh-client@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ssh-server@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-abstracted-l3vpn@2015-05-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-ddc@2014-12-25.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-l3vpn@2015-02-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-service-flow-policy@2015-10-10.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-service-flow@2015-08-05.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-syslog@2018-03-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sztp-conveyed-info@2019-01-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-te-mpls-types@2018-12-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-te-path-computation@2019-03-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-te-topology-psc@2016-07-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-te-wson@2017-06-27.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-template.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-tls-client@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-tls-server@2020-03-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-tpm-remote-attestation@2020-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-trans-client-service@2019-11-03.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-trans-client-service@2019-11-03.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-trans-client-svc-pm@2019-11-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-trill-oam-pm@2015-01-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-trust-anchors@2019-04-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-trust-anchors@2019-04-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-twamp@2018-07-02.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-uses-geo-location@2019-02-02.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-utunnel@2015-12-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-vxlan@2018-08-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-wson-impairment-topology@2018-08-31.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-wson-topology@2019-11-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-wson-tunnel@2019-09-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-annotations@2014-11-28.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-hash@2016-02-10.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-inst-data-pkg@2020-01-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-library-packages@2018-11-26.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-opstate-metadata@2016-07-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-package-instance@2020-01-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-package-types@2020-01-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-package@2019-09-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-packages@2020-01-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-push-ext@2019-02-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yl-packages@2020-01-21.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-zerotouch-device@2017-10-19.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/if-l3-vlan@2015-10-19.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/interfaces-common@2015-10-19.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ipfix-psamp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/isis-topology@2015-06-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/l3-unicast-igp-topology@2015-06-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/l3vpn@2014-08-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/layer-one-topology@2015-02-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/lime-bfd-extension@2014-08-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/logical-network-element@2016-01-19.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/lora.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/media-channel@2014-06-05.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-igp@2014-07-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-rsvp@2015-04-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-static@2015-02-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-te@2014-07-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/mpls@2014-12-12.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/nacm@2010-09-02.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/network-instance@2016-02-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/network-instance@2016-02-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/network-topology@2014-12-11.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/networking-instance@2016-01-20.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/newco-acl@2015-03-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/nvo3-oam@2014-04-24.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls-igp@2015-07-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls-rsvp@2015-09-18.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls-te@2015-10-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls@2015-10-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-network-instance@2015-10-18.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ospf-topology@2015-06-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ospf@2014-09-17.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/pbbevpn@2015-03-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/rendered-service-path@2014-07-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/sd-onos-service-l3vpn@2015-10-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/service-function-chain@2014-07-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/service-function-description-monitor@2014-12-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/service-function-path@2014-07-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/service-function@2014-29-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/service-node@2014-07-01.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/sfc-oam@2014-09-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/sff-topology.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/softwire@2014-12-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/std-ext-route-filter@2015-02-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/transitions@2016-03-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/trill-oam@2014-04-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/tunnel-management@2015-01-12.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/tunnel-policy@2018-09-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/udmcore.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/utunnel@2015-07-05.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/virtualizer@2016-02-24.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-14.txt
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-14.xml
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-18.txt
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-18.xml
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-19.txt
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-19.xml
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-20.txt
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-20.xml
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-21.txt
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-21.xml
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-22.txt
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-22.xml
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-23.txt
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/draft-ietf-netmod-syslog-model-23.xml
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/ietf-syslog.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/ietf-syslog\[1\].yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/config-bgp-listener-impl.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/opendaylight-md-sal-binding.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/opendaylight-md-sal-dom.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/shutdown-impl.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/shutdown.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/toaster-consumer-impl.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/toaster-consumer.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/toaster-provider-impl.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/toaster-provider.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/wifi/access-points/openconfig-access-points.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/wifi/access-points/openconfig-ap-interfaces.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/wifi/ap-manager/openconfig-ap-manager.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/wifi/mac/openconfig-wifi-mac.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/openconfig/release/models/wifi/phy/openconfig-wifi-phy.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/vendor/cisco/common/cisco-link-oam.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf ietf/DRAFT/ietf-pim-dm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-2015@2016-12-20.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-components.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-information.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-math.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-metrics.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-si-units.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-system.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-thermodynamics.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/AEdk/ieee802-dot1ae.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/CBdb/ieee802-dot1cb-mask-and-match.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/Qcx/ieee802-dot1q-cfm-alarm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/Qcx/ieee802-dot1q-cfm-bridge.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/Qcx/ieee802-dot1q-cfm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/x/ieee802-dot1x.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/published/802.3/ieee802-ethernet-interface-half-duplex.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/example-jukebox.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-access-control-list.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-access-control-list.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-bfd.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-isis.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-bidir.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-bidir@2017-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-dm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-dm@2017-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-rp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-rp@2017-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-sm.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-sm@2017-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-twamp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-zerotouch-bootstrap-server.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/newco-acl.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/iana-routing-types.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/iana-routing-types@2018-10-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-connectionless-oam-methods.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-connectionless-oam-methods@2019-04-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-connectionless-oam.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-connectionless-oam@2019-04-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-ipv6-router-advertisements@2016-11-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-ipv6-unicast-routing@2016-11-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-routing.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-routing@2018-03-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp*
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-sztp-conveyed-info.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-sztp-conveyed-info@2019-04-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/ciena/ciena-sat.yang
    ## Removing the cisco folder because there are over 30k yang files there and would increase the test time to something
    ## unmanageable.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco
    ## Removing entire juniper folder because it creates an OOM Crash with the validator tool.*** Keywords ***
    ## Unsure if the yang models are the problem or something in the tool. This is being tracked here:
    ## https://jira.opendaylight.org/browse/YANGTOOLS-1093
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/juniper
