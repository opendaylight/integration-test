*** Settings ***
Documentation       Resource for preparing various sets of Yang files to be used in testing.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 Keywords in this Resource assume there is an active SSH connection
...                 to system where a particular set of Yang files is to be created.
...                 The keywords will change current working directory used by SSHKeywords.
...
...                 The two repos used in this suite ${YANGMODELS_REPO} and ${OPENCONFIG_REPO}
...                 have been updated:
...                 11/11/2020
...

Resource            ${CURDIR}/SSHKeywords.robot


*** Variables ***
${YANGMODELS_REPO}                  https://github.com/YangModels/yang
${OPENCONFIG_REPO}                  https://github.com/openconfig/public
# TODO: update docs with new date when changing
${YANGMODELS_REPO_COMMIT_HASH}
...                                 cdd14114cdaf130be2b6bfce92538c05f6d7c07d
# TODO: update docs with new date when changing
${OPENCONFIG_REPO_COMMIT_HASH}
...                                 8062b1b45208b952598ad3c3aa9e5ebc4f03cc67
# ${YANG_MODEL_PATHS} is needed to explicitly tell which paths to find yang files to build dependencies from to validate
# the yang file being validated. There is an option (-r) to recursively parse so that you don't have to pass all of these
# paths with the -p argument, but the recursive option makes the tool so slow that it would not work when testing so
# many files
@{YANG_MODEL_PATHS}
...                                 /home/jenkins/src/main/yang/experimental/ietf-extracted-YANG-modules
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models
...                                 /home/jenkins/src/main/yang/standard/ietf/DRAFT
...                                 /home/jenkins/src/main/yang/standard/ietf/RFC
...                                 /home/jenkins/src/main/yang/experimental/ieee
...                                 /home/jenkins/src/main/yang/experimental/ieee/1588
...                                 /home/jenkins/src/main/yang/experimental/ieee/1906.1
...                                 /home/jenkins/src/main/yang/experimental/ietf
...                                 /home/jenkins/src/main/yang/experimental/mano-models
...                                 /home/jenkins/src/main/yang/experimental/odp
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/acl
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/aft
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/bfd
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/bgp
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/catalog
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/interfaces
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/isis
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/lacp
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/lldp
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/local-routing
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/macsec
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/mpls
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/multicast
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/network-instance
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/openflow
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/optical-transport
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/ospf
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/platform
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/policy
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/policy-forwarding
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/probes
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/qos
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/relay-agent
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/rib
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/segment-routing
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/stp
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/system
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/telemetry
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/types
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/vlan
...                                 /home/jenkins/src/main/yang/experimental/openconfig/release/models/wifi
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/802.1/ABcu
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/802.1/AEdk
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/802.1/CBcv
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/802.1/CBdb
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/802.1/Qcr
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/802.1/Qcw
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/802.1/Qcx
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/802.1/Qcz
...                                 /home/jenkins/src/main/yang/standard/ieee/draft/1906.1
...                                 /home/jenkins/src/main/yang/standard/ieee/published/802.1
...                                 /home/jenkins/src/main/yang/standard/ieee/published/802.3
...                                 /home/jenkins/src/main/yang/vendor/ciena
...                                 /home/jenkins/src/main/yang/vendor/fujitsu
...                                 /home/jenkins/src/main/yang/vendor/huawei
...                                 /home/jenkins/src/main/yang/vendor/nokia


*** Keywords ***
Static_Set_As_Src
    [Documentation]    Cleanup possibly leftover directories (src and target), clone git repos and remove unwanted paths.
    ...    YangModels/yang and openconfig/public repos should be updated from time to time, but they are frozen to
    ...    ${YANGMODELS_REPO_COMMIT_HASH} and ${OPENCONFIG_REPO_COMMIT_HASH} to prevent the chance that updates to those
    ...    repos with problems will cause ODL CSIT to fail. There are obvious failures in these repos already, and those
    ...    are addressed by removing those files/dirs with the Delete_Static_Paths keyword.
    [Arguments]    ${root_dir}=.
    SSHKeywords.Set_Cwd    ${root_dir}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf target src
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p src/main
    SSHKeywords.Set_Cwd    ${root_dir}/src/main
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone ${YANGMODELS_REPO}    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    git checkout -b ytest ${YANGMODELS_REPO_COMMIT_HASH}
    ...    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang/experimental
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf openconfig
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone ${OPENCONFIG_REPO}    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mv -v public openconfig
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang/experimental/openconfig
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    git checkout -b ytest ${OPENCONFIG_REPO_COMMIT_HASH}
    ...    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang

Delete_Static_Paths
    [Documentation]    Long list of "rm -vrf" commands.
    ...    All files/paths removed below are due to real issues in those files/paths as found with failures in
    ...    the yang-model-validator tool. We do not want OpenDaylight CSIT to fail because of problems with
    ...    external yangs.
    # Please keep below list in alpha order
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf .git
    ## wrong module name, by convention should be 'ieee1906-dot1-system', but is 'ieee-1906-dot1-system'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ieee/1906.1/ieee1906-dot1-system.yang
    ## DESCRIPTION is not valid substatement for OUTPUT, https://tools.ietf.org/html/rfc6020#section-7.13.3.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/@2015-03-09.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/l3-unicast-igp-topology@2015-06-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/abstract-topology@2014-07-01.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/alto-service-types@2015-03-22.yang (module alto-service-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/alto-service@2015-03-22.yang
    ## missing closing bracket '}' at the end of module
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/alto-service-types@2015-03-22.yang
    ## excluded depndency file cisco from test, (module SNMP-FRAMEWORK-MIB)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/BATTERY-MIB@2015-06-15.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/bfd.yang (module bfd)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/bfd-routing-app@2015-02-14.yang
    ## missing key-stmt separator after 'key' on line 707
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/bfd.yang
    ## REQUIRE_INSTANCE may be used with instance identifier https://tools.ietf.org/html/rfc6020#section-9.13.2
    ## was used with type leafref on line 415
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/bgp@2015-05-15.yang
    ## exluded dependency file from test experimental/ietf-extracted-YANG-modules/bgp@2015-05-15.yang, (module bgp)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/bgp-l3vpn@2015-10-15.yang
    ## REQUIRE_INSTANCE can be used only with instance identifier, https://tools.ietf.org/html/rfc6020#section-9.13.2
    ## was used with element type leafref on line 126
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/bgp-policy@2015-05-15.yang
    ## missing prefix acl definition, https://tools.ietf.org/html/rfc6020#section-6.4
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/cira-shg-mud@2019-07-08.yang
    ## missing dependency module ieee-types, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/dot1q-tag-types@2016-07-08.yang
    ## removed dependency file from test draft-gonzalez-netmod-5277-00@2016-03-20.yang, (module draft-gonzalez-netmod-5277-00)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/draft-gonzalez-netconf-5277bis-00@2016-03-20.yang
    ## xpath wrong comparison operator, used '==', should be '='
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/draft-gonzalez-netmod-5277-00@2016-03-20.yang
    ## wrong position of typedef dbm-t description, outside '{}' brackets
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/draft-ietf-ccamp-dwdm-if-param-yang-03@2020-03-09.yang
    ## Mount points may only be defined at either a container or a list, not case, lines 212,..
    ## https://tools.ietf.org/html/rfc8528#section-3.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/example-5g-core-network@2017-12-28.yang
    ## non existing augmention path "/rt:routing/rt:routing-tables/rt:routing-table..."
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/example-rip@2012-10-04.yang
    ## removed dependecy removed file from test experimental/ietf-extracted-YANG-modules/transitions@2016-03-15.yang (module transitions)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/finite-state-machine@2016-03-15.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/dot1q-tag-types@2016-07-08.yang (module dot1q-tag-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/flexible-encapsulation@2015-10-19.yang
    ## path is not allowed to contain new line character, https://tools.ietf.org/html/rfc6020#section-12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/flexi-grid-TED@2015-07-01.yang
    ## not ended type-stm (missing statend character), https://tools.ietf.org/html/rfc6020#section-12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/gen-oam@2014-10-23.yang
    ## missing dependecy yang-types, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/hardware-entities.yang
    ## on line 9, multistring contact, should be only single string https://tools.ietf.org/html/rfc6020#section-12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/huawei-dhcp@2014-12-18.yang
    ## missing namespace, https://tools.ietf.org/html/rfc6020#section-7.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/huawei-ipte@2014-08-13.yang
    ## missing stmtend character ';' after description on line 707
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/i2rs-rib@2015-04-03.yang
    ## missing stmtend at the end of descriptions, https://tools.ietf.org/html/rfc6020#section-12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/i2rs-service-topology@2015-07-07.yang
    ## removed dependecy file from test experimental/ietf-extracted-YANG-modules/ietf-location@2014-05-08.yang, (module ietf-location)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/iana-civic-address-type@2014-05-08.yang
    ## unescaped single quoate "'" character inside a quaoted text on line 59
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/iana-geo-uri-type@2014-05-08.yang
    ## wrong augment path node 'interfaces-state', not avaibale, used 'interfaces' inside eth-if
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ieee802-pse@2017-03-02.yang
    ## xpath wrong comparison operator, used '==', should be '='
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-5277-netmod@2016-06-15.yang
    ## dependency node access-control-list-ipv4-header-fields can not be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-acl@2015-03-04.yang
    ## newer revisions do not use access-list-entries node, only standard/ietf/DRAFT/ietf-access-control-list.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-acl-dnsname@2016-01-14.yang
    ## dependency node asymmetric-key-algorithm-t can not be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ambi@2019-08-25.yang
    ## missing dependency node 'lsps-state'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bfd-mpls-te@2018-08-01.yang
    ## missing dependency module ietf-bgp of revision 2016-01-06, avaibale only newer 2020-06-28
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-extensions@2016-07-08.yang
    ## augmenting idnetity 'bgp' instead of container 'bgp', both have same identifier
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-l3vpn@2018-04-17.yang
    ## missing depndency node 'policy-statements'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-policy@2020-06-28.yang
    ## uses missing grouping node 'bgp-extended-community-attr-state', https://tools.ietf.org/html/rfc6020#section-7.12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bgp-rib-shared-attributes@2019-03-21.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-connectionless-oam@2017-09-06.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bier-oam@2017-06-13.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-connectionless-oam-methods@2017-09-06.yang (module ietf-connectionless-oam-methods)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bier-rpcs@2018-08-28.yang
    ## can not be found dependency node 'pinned-domain-cert' in refine path
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-brski-possession@2018-10-11.yang
    ## Mount points may only be defined at either a container or a list, not anydata, line 790
    ## https://tools.ietf.org/html/rfc8528#section-3.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-connectionless-oam@2017-09-06.yang
    ## excluded dependency file from test standard/ietf/RFC/ietf-connectionless-oam@2019-04-16.yang (module ietf-connectionless-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-connectionless-oam-methods@2017-09-06.yang
    ## excluded dependecy file from test experimental/ietf-extracted-YANG-modules/ietf-notification-capabilities@2020-03-23.yang (module ietf-notification-capabilities)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-data-export-capabilities.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-diffserv-classifier@2015-04-07.yang (module ietf-diffserv-classifier)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-diffserv-action@2015-04-07.yang
    ## xpath wrong comparison operator, used '==', should be '=', line 288
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-diffserv-classifier@2015-04-07.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-diffserv-classifier@2015-04-07.yang (module ietf-diffserv-classifier)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-diffserv-policy@2015-04-07.yang
    ## Duplicate identity definition, both define event-type
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dmm-fpc-base@2017-03-08.yang
    ## missing module ietf-dmm-fpc of revision-date 2017-03-08, found only newer
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dmm-fpc-pmip@2017-03-08.yang
    ## missing module ietf-dmm-fpc of revision-date 2017-03-08, found only newer
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dmm-fpc-policyext@2017-03-08.yang
    ## missing module ietf-dmm-fpc of revision-date 2017-03-08, found only newer
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dmm-threegpp@2017-03-08.yang
    ## newer verions of ietf-access-control-list do not use node 'access-lists', augmented in this file
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dots-access-control-list@2017-11-29.yang
    ## sx:structure should be augmented by 'sx:augment-structure' not by oridnary 'augment'
    ## https://tools.ietf.org/html/rfc6020#section-7.15
    ## newer dependency ietf-dots-signal-channel uses sx:structure not container anymore
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dots-signal-call-home@2018-09-28.yang
    ## sx:structure should be augmented by 'sx:augment-structure' not by oridnary 'augment'
    ## https://tools.ietf.org/html/rfc6020#section-7.15
    ## newer dependency ietf-dots-signal-channel uses sx:structure not container anymore
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dots-signal-control@2019-05-13.yang
    ## sx:structure should be augmented by 'sx:augment-structure' not by oridnary 'augment'
    ## https://tools.ietf.org/html/rfc6020#section-7.15
    ## newer dependency ietf-dots-signal-channel uses sx:structure not container anymore
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-dots-signal-control-filter@2019-02-15.yang
    ## derived-from-or-self takes 2 arguments, https://tools.ietf.org/html/rfc7950#section-10.4.1
    ## used: derived-from-or-self(../class, "iana-entity", "sensor")
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-entity@2016-05-13.yang
    ## missing dependecy 'frequency-thz', cannot be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ext-xponder-wdm-if@2020-03-09.yang
    ## missing dependency module with proper revision 2016-09-29,
    ## found in experimental/ietf-extracted-YANG-modules/ietf-fabric-types@2017-11-29.yang
    ## but constains also newer revision 2017-11-29, https://tools.ietf.org/html/rfc6020#section-7.1.5.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fabric-capable-device@2016-09-29.yang
    ## missing dependency module with proper revision 2016-10-13,
    ## found in experimental/ietf-extracted-YANG-modules/ietf-fabric-types@2017-11-29.yang
    ## but constains also newer revision 2017-11-29, https://tools.ietf.org/html/rfc6020#section-7.1.5.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fabric-endpoint@2017-06-29.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-fabric-service-types@2017-08-30.yang (module ietf-fabric-service-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fabric-service@2017-08-30.yang
    ## missing dependency module with proper revision 2016-09-29,
    ## found in experimental/ietf-extracted-YANG-modules/ietf-fabric-types@2017-11-29.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fabric-service-types@2017-08-30.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-fb-rib-types@2017-03-13.yang (moduel ietf-fb-rib-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fb-rib@2017-03-13.yang
    ## missing dependency module ietf-access-control-lists, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-fb-rib-types@2017-03-13.yang
    ## wrong augment path, missing node sr:segment-routing, on line 265
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flex-algo@2019-04-26.yang
    ## Referenced base identity 'fec-type' doesn't exist in given scope module ietf-layer0-types
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flex-grid-media-channel@2018-10-22.yang
    ## missing dependency node 'layer0-node-type', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flex-grid-topology@2018-10-22.yang
    ## Referenced base identity 'fec-type' doesn't exist in given scope module ietf-layer0-types
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-flexi-grid-media-channel@2019-03-24.yang
    ## description for response list is put outside the scope of list, line 1141
    ## list is enclosed with closing bracket '}', comment should be put before it
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gen-oam@2015-04-09.yang
    ## missing ending quoate cahracter '"' at teh end of description on line 29
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gen-oam-ais@2016-06-25.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-gen-oam-ais@2016-06-25.yang (module ietf-gen-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gen-oam-pm@2015-01-07.yang
    ## xpath wrong comparison operator, used '==', should be '=', on line 70
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gre@2015-07-02.yang
    ## referenced element routing-instance-ref can be found only in cisco yangs, which are excluded from the test
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gre-tunnel@2015-10-13.yang
    ## missing dependecy node 'inline-address', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-http-subscribed-notifications@2018-06-11.yang
    ## unable to found dependency node 'ietf-routing:routing-instance-ref'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipipv4-tunnel-02@2015-10-15.yang
    ## referenced node routing-instance-ref can be found only in cisco yangs, which are excluded from test
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipipv4-tunnel@2015-10-14.yang
    ## missing base to type identityref on line 254, https://tools.ietf.org/html/rfc6020#section-9.10.2
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ip-tunnel@2016-06-20.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-ipv6-unicast-routing-2@2017-10-06.yang (module ietf-ipv6-unicast-routing-2 to which it belongs)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipv6-router-advertisements-2@2017-10-05.yang
    ## missing dependency submodule ietf-ipv6-router-advertisements-2, revision 2017-10-06
    ## found revision 2017-10-05
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ipv6-unicast-routing-2@2017-10-06.yang
    ## missing dependecy node 'ietf-routing:routing-instance', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-isis-bfd@2015-11-18.yang
    ## missing augment target "l2vpn:l2vpn-state" in only l2vpn module, experimental/ietf-extracted-YANG-modules/ietf-l2vpn@2019-05-28.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-l2vpn-igmp-mld-snooping@2017-03-13.yang
    ## excluded dependency file from test ietf-l3vpn-ntw@2020-10-16.yang, (module ietf-l3vpn-ntw)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-l3nm-te-service-mapping@2020-11-02.yang
    ## missing dependecy node 'ietf-routing:routing-instance', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-l3vpn@2015-10-09.yang
    ## choice cannot be substatement to choice, https://tools.ietf.org/html/rfc6020#section-7.9.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-l3vpn-ntw@2020-10-16.yang
    ## can not use 'uses' to reference container, only grouping on line 37, https://tools.ietf.org/html/rfc6020#section-7.12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-library-tags@2017-08-12.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-gen-oam@2015-04-09.yang, (module ietf-gen-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-lime-bfd-extension@2014-08-30.yang
    ## missing dependency node 'lisp-router-instances' to be augmented
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-lisp-petr@2016-06-30.yang
    ## missing dependency node 'lisp-router-instances' to be augmented
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-lisp-pitr@2016-06-30.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/iana-civic-address-type@2014-05-08.yang, (module iana-civic-address-type)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-location@2014-05-08.yang
    ## wrong augment path, missing node 'rt:control-plane-protocol', line 284
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-mldp@2018-10-22.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-mpls-mldp@2018-10-22.yang, (module ietf-mpls-mldp@2018-10-22.yang)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-mldp-extended@2018-10-22.yang
    ## multiline path-arg , https://tools.ietf.org/html/rfc6020#section-12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te@2014-11-06.yang
    ## multiline namespace, https://tools.ietf.org/html/rfc3986#appendix-A
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-global@2014-10-13.yang
    ## missing prefix for module ietf-mpls-te-link
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-links@2014-10-13.yang
    ## missing prefix for module ietf-mpls-te-lsps
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-lsps@2014-10-13.yang
    ## multiline namespace, https://tools.ietf.org/html/rfc3986#appendix-A
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-tunnel-ifs@2014-10-13.yang
    ## augment-arg node identifier can not contain new line character, https://tools.ietf.org/html/rfc6020#section-6.2
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-tp-topology@2019-03-11.yang
    ## missing dependency node 'path-computed-route-object', can not be found anywhere
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-tp-tunnel@2019-03-11.yang
    ## missing prefix acl definition, https://tools.ietf.org/html/rfc6020#section-6.4
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mud-quarantine@2019-12-27.yang
    ## used same identifier multiple times (frr on lines 276, 300 ), https://tools.ietf.org/html/rfc6020#section-6.2.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-multicast-service@2016-02-29.yang
    ## excluded depndency file from test experimental/ietf-extracted-YANG-modules/ietf-bgp-l3vpn@2018-04-17.yang (module ietf-bgp-l3vpn)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mvpn@2019-12-02.yang
    ## required dependency module yuma-netconf, could not be found anywhere
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-error-parameters@2013-07-11.yang
    ## missing ending bracket '}' for mudule definition
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-light@2012-01-12.yang
    ## depends on 'client-auth', which is missing in newer revision experimental/ietf-extracted-YANG-modules/ietf-tls-server@2020-08-20.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-server-new@2015-07-06.yang
    ## missing base elment inline-address, nowhere defined
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-subscribed-notifications@2018-08-03.yang
    ## can not perform refine of 'DEFAULT' for the target 'LEAF_LIST', refine of default can be performed only on leaf or choice, line 220
    ## https://tools.ietf.org/html/rfc6020#section-7.12.2
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-notification-capabilities@2020-03-23.yang
    ## excluded dependecy file from test, experimental/ietf-extracted-YANG-modules/ietf-bgp-l3vpn@2018-04-17.yang (module ietf-bgp-l3vpn)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-nvo3@2019-04-01.yang
    ## many excluded (deleted) dependencies from this test, for example cisco afi-safi
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-nvo3-base@2020-08-26.yang
    ## module ietf-te-topology does not contain node 'schedule'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-odu-topology@2016-07-07.yang
    ## excluded dependency file experimental/ietf-extracted-YANG-modules/ietf-OPSAWG-ute-tunnel.yang, (module ietf-OPSAWG-ute-tunnel)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-OPSAWG-te-tunnel.yang
    ## unquoted descriptions with included whitespaces, https://tools.ietf.org/html/rfc6020#section-6.1.3
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-OPSAWG-ute-tunnel.yang
    ## new line character inside identifier, https://tools.ietf.org/html/rfc6020#section-6.2
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-optical-impairment-topology@2019-05-22.yang
    ## incorrect path in augmentation, extra parameter instance
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ospf-bfd@2016-10-31.yang
    ## incorrect path in augmentation, twice repeted same node 'extended-prefix-tlvs'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ospf-ppr@2019-07-07.yang
    ## missing augment path target node 'state' on line 192
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-otn-service@2016-06-24.yang
    ## missing dependency node 'path-computed-route-object', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-otn-tunnel@2020-03-09.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ieee802-pse@2017-03-02.yang, (module ieee802-pse)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-poe-power-management@2017-03-09.yang
    ## MUST is not valid substatement for CASE, https://tools.ietf.org/html/rfc7950#section-7.9.2.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-qos@2016-10-20.yang
    ## excluded dependecy file from test experimental/ietf-extracted-YANG-modules/ietf-tpm-remote-attestation@2020-03-09.yang, (module ietf-tpm-remote-attestation)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rats-attestation-stream@2020-03-06.yang
    ## unable to find module ietf-restconf with revision-date 2015-01-30
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-restconf-collection@2015-01-30.yang
    ## multiline namespace name with end of line escaped with '\' character
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-restconf-list-pagination@2015-01-30.yang
    ## cannot find node 'client-auth' inside 'tls-server-grouping' in ietf-tls-server, line 337
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-restconf-server-new@2015-07-06.yang
    ## missing intermediary node 'key-chain' in augmention path on line 82
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rfc7210@2015-03-09.yang
    ## non unique identifire (repair-path used as grouping and also as container)
    ## https://tools.ietf.org/html/rfc6020#section-6.2.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rib-extension@2020-09-18.yang
    ## missing dependency node 'rsvp:session-attributes-state'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rsvp-te@2020-03-09.yang
    ## missing dependency node 'lsps-state'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rsvp-te-mpls@2020-03-09.yang
    ## augmenting identity rsvp instead of container, https://tools.ietf.org/html/rfc6020#section-7.15
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-rsvp-te-psc@2015-10-16.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-yang-packages@2020-01-21.yang, (module ietf-yang-packages)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-schema-selection@2020-02-29.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-yl-packages@2020-01-21.yang, (module ietf-yl-packages)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-schema-version-selection@2019-10-31.yang
    ## unpaired, extra end of myltiline comment '*/' without start
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sd-onos-service-l3vpn@2015-12-16.yang
    ## same identifier 'qos-if-car' used for list and also for container, identifiers must be unique, https://tools.ietf.org/html/rfc6020#section-6.2.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sd-onos-service-types@2015-12-16.yang
    ## excluded depndency file from test experimental/ieee/1906.1/ieee1906-dot1-system.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-service-pm@2020-07-13.yang
    ## excluded dependency file from test standard/ietf/RFC/ietf-connectionless-oam@2019-04-16.yang, (module ietf-connectionless-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sfc-oam@2016-11-21.yang
    ## multiline namespace, https://tools.ietf.org/html/rfc3986#appendix-A
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-abstracted-l3vpn@2015-05-04.yang
    ## missing closing bracket '}' for module
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-ddc@2014-12-25.yang
    ## missing statment end ';' after 'when' statment on line 170, https://tools.ietf.org/html/rfc6020#section-12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-l3vpn@2015-02-04.yang
    ## missing module eca-policy-0910, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-service-flow@2015-08-05.yang
    ## augmention path multiline, https://tools.ietf.org/html/rfc6020#section-6.2
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-service-flow-policy@2015-10-10.yang
    ## missing dependency node private-key-grouping, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-syslog@2018-03-15.yang
    ## CHOICE is not valid for YANG_DATA, should only contain container substatement, https://tools.ietf.org/html/rfc8040#section-8
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sztp-conveyed-info@2019-01-15.yang
    ## only a template file
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-template.yang
    ## missing augment target performance-metric-two-way, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-te-mpls-types@2018-12-21.yang
    ## uses missing node 'path-access-segment-info' from module ietf-te on line 519
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-te-path-computation@2019-03-11.yang
    ## augmention target 'te-link-event' is missing
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-te-topology-psc@2016-07-01.yang
    ## missing dependency node 'resource-pool-attributes', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-te-wson@2017-06-27.yang
    ## missing key node in list (key algo-registry-type not found in list), line 878
    ##https://tools.ietf.org/html/rfc6020#section-7.8.2
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-tpm-remote-attestation@2020-03-09.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-gen-oam-ais@2016-06-25.yang (module ietf-gen-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-trill-oam-pm@2015-01-11.yang
    ## missing refine node "cert", maybe should be used "cert-data"
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-trust-anchors@2019-04-29.yang
    ## missing dependency, module ieee-dot1Q-types, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-ucpe-ni-properties@2019-11-27.yang
    ## missing dependency module geo-location, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-uses-geo-location@2019-02-02.yang
    ## unable to find node 'routing-instance-ref' inside module 'ietf-routing'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-utunnel@2015-12-16.yang
    ## unable to find node 'bgp-parameters-grp' inside module 'ietf-evpn'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-vxlan@2018-08-29.yang
    ## missing dependency node 'path-computed-route-object', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-wson-tunnel@2019-09-11.yang
    ## missing type as substatement to annotation on line 66, https://tools.ietf.org/html/rfc7952#section-3
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-annotations@2014-11-28.yang
    ## missing ending quoatation mark '"' for contact statment argument, line 22
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-hash@2016-02-10.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-yang-package-types@2020-01-21.yang, (module ietf-yang-package-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-inst-data-pkg@2020-01-21.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-yang-package-types@2020-01-21.yang, (module ietf-yang-package-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-library-packages@2018-11-26.yang
    ## WHEN is not valid for ANNOTATION, https://tools.ietf.org/html/rfc7952#section-3
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-opstate-metadata@2016-07-06.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-yang-package-types@2020-01-21.yang, (module ietf-yang-package-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-package@2019-09-11.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-yang-package-types@2020-01-21.yang, (module ietf-yang-package-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-package-instance@2020-01-21.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-yang-package-types@2020-01-21.yang, (module ietf-yang-package-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-packages@2020-01-21.yang
    ## missing depndency node 'name-revision', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-package-types@2020-01-21.yang
    ## missing closing and opening quoates, used concat symbol '+' inside string not to concat strings, line 95
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-push-ext@2019-02-01.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-yang-packages@2020-01-21.yang, (module ietf-yang-packages)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yl-packages@2020-01-21.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/dot1q-tag-types@2016-07-08.yang, (module dot1q-tag-types)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/if-l3-vlan@2015-10-19.yang
    ## derived-from-or-self takes 2 arguments, https://tools.ietf.org/html/rfc7950#section-10.4.1
    ## used: derived-from(if:type, 'ietf-if-cmn', 'sub-interface'), line 353
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/interfaces-common@2015-10-19.yang
    ## incorrect prefix: prefix >"ct"y;< character 'y' after quatation, before stmtend on line 7
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ipfix-psamp.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/l3-unicast-igp-topology@2015-06-08.yang, (module l3-unicast-igp-topology)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/isis-topology@2015-06-08.yang
    ## skipped container node 'networks' in augmentation on line 247
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/l3-unicast-igp-topology@2015-06-08.yang
    ## exluded dependency file experimental/ietf-extracted-YANG-modules/bgp@2015-05-15.yang, (module bgp)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/l3vpn@2014-08-15.yang
    ##multiline path with '-' character at the end of first line
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/layer-one-topology@2015-02-11.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/ietf-gen-oam-ais@2016-06-25.yang (module ietf-gen-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/lime-bfd-extension@2014-08-30.yang
    ## unable to find type structural-mount
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/logical-network-element@2016-01-19.yang
    ## two string sperated by character ';' belonging to one contact statement
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/lora.yang
    ## whitespace in URI, are not allowed by ABNF for URI https://tools.ietf.org/html/rfc3986#page-49
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/media-channel@2014-06-05.yang
    ## excluded dependecy file from test experimental/ietf-extracted-YANG-modules/mpls-rsvp@2015-04-22.yang, (module mpls-rsvp)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/mpls@2014-12-12.yang
    ## excluded dependecy file from test experimental/ietf-extracted-YANG-modules/mpls-rsvp@2015-04-22.yang, (module mpls-rsvp)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-igp@2014-07-07.yang
    ## missing closing bracket '}' at the end of module
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-rsvp@2015-04-22.yang
    ## excluded dependecy file from test experimental/ietf-extracted-YANG-modules/mpls-rsvp@2015-04-22.yang, (module mpls-rsvp)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-static@2015-02-01.yang
    ## missing closing bracket '}' at the end of module, commented
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-te@2014-07-07.yang
    ## unable to find type structural-mount
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/networking-instance@2016-01-20.yang
    ## missiing type schema-mount, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/network-instance@2016-02-22.yang
    ## missing dependency module nodes, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/network-topology@2014-12-11.yang
    ## missing dependency file experimental/ietf-extracted-YANG-modules/gen-oam@2014-10-23.yang, (module gen-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/nvo3-oam@2014-04-24.yang
    ## REQUIRE_INSTANCE is not valid for TYPE, MAY be present if the type is
    ## "instance-identifier", https://tools.ietf.org/html/rfc6020#section-9.13.2
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls@2015-10-14.yang
    ## node 'igp-lsp-sr-setup' can not be found in module openconfig-mpls-sr from opencofig repository
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls-igp@2015-07-04.yang
    ## missing closing bracket '}' for module
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls-rsvp@2015-09-18.yang
    ## missing dependency node 'protection-type' cannot be found inside module 'openconfig-mpls-types'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls-te@2015-10-04.yang
    ## missing dependency node network-instance-type, newer version of opencofig, does not support it
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-network-instance@2015-10-18.yang
    ## wrong pattern on line 91, missing opening bracket '('
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-network-instance-types@2015-10-18.yang
    ## missing dependency node routing-instance-ref, can not be found inside module ietf-routing
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ospf@2014-09-17.yang
    ## excluded dependency file experimental/ietf-extracted-YANG-modules/l3-unicast-igp-topology@2015-06-08.yang, (module l3-unicast-igp-topology)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/ospf-topology@2015-06-08.yang
    ## TYPE is not valid for LIST, line 136
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/pbbevpn@2015-03-06.yang
    ## dependency module service-function-scheduler-type, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/rendered-service-path@2014-07-01.yang
    ## incorrect revision date format on line 38, https://tools.ietf.org/html/rfc6020#section-7.1.9
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/service-function@2014-29-04.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/service-function@2014-29-04.yang, (module service-function)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/service-function-chain@2014-07-01.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/service-function@2014-29-04.yang, (module service-function)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/service-function-description-monitor@2014-12-01.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/service-function@2014-29-04.yang, (module service-function)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/service-function-path@2014-07-01.yang
    ## excluded dependency file from test experimental/ietf-extracted-YANG-modules/service-function@2014-29-04.yang, (module service-function)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/service-node@2014-07-01.yang
    ## missing dependency file from test experimental/ietf-extracted-YANG-modules/gen-oam@2014-10-23.yang, (module gen-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/sfc-oam@2014-09-04.yang
    ## Maximal count of CONTACT for MODULE is 1, detected 2, https://tools.ietf.org/html/rfc6020#section-7.1.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/sff-topology.yang
    ## missing closing bracket '}', probably for 'leaf active'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/softwire@2014-12-14.yang
    ## missing dependency module inet-types, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/TCP-MIB@2005-02-18.yang
    ## unable to find node datatree-filter inside module ietf-yang-push
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/transitions@2016-03-15.yang
    ## missing dependency file experimental/ietf-extracted-YANG-modules/gen-oam@2014-10-23.yang, (module gen-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/trill-oam@2014-04-16.yang
    ## missing statment-end after comment on line 484, (missing ';' after comment)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/TUDA-V1-ATTESTATION-MIB@2017-10-30.yang
    ## exluded dependency file from test experimental/ietf-extracted-YANG-modules/bgp@2015-05-15.yang, (module bgp)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/tunnel-management@2015-01-12.yang
    ## missing module closing brackte '}'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/tunnel-policy@2018-09-15.yang
    ## missing dependency module yang-types, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/udmcore.yang
    ## referenced node routing-instance-ref can be found only in cisco yangs, which are excluded from test
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/utunnel@2015-07-05.yang
    ## empty path argument, https://tools.ietf.org/html/rfc6020#section-9.9.2
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/ietf-extracted-YANG-modules/virtualizer@2016-02-24.yang
    ## missing dependency node 'private-key-grouping', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf/SYSLOG-MODEL/ietf-syslog.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/config-bgp-listener-impl.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/opendaylight-md-sal-binding.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/opendaylight-md-sal-dom.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/shutdown-impl.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/shutdown.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/toaster-consumer-impl.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/toaster-consumer.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/toaster-provider-impl.yang
    ## missing dependency module config, nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/odp/toaster-provider.yang
    ## tries to deviate itself
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf experimental/openconfig/release/models/wifi/openconfig-ap-interfaces.yang
    ## dependency module Cisco-IOS-XR-types is avaible only in excluded cisco yangs
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/vendor/cisco/common/cisco-link-oam.yang
    ## excluded dependency file from test standard/ieee/draft/1906.1/ieee1906-dot1-properties.yang, (module ieee1906-dot1-properties)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-components.yang
    ## excluded depndency file from test standard/ieee/draft/1906.1/ieee1906-dot1-types.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-definitions.yang
    ## excluded depndency file from test experimental/ieee/1906.1/ieee1906-dot1-system.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-nanivid.yang
    ## excluded depndency file from test standard/ieee/draft/1906.1/ieee1906-dot1-types.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-nanosensor.yang
    ## excluded depndency file from test standard/ieee/draft/1906.1/ieee1906-dot1-types.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-neuron.yang
    ## require removed ieee1906-dot1-definitions
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-system.yang
    ## in newer revision changed nanoscale-communication feature -> identity, https://tools.ietf.org/html/rfc7950#section-11
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/1906.1/ieee1906-dot1-types.yang
    ##depends on specific node type-of-operation
    ## which most revision does not use, only Qcw version
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/Qcw/ieee802-dot1q-psfp.yang
    ##depends on specific node type-of-operation
    ## which most revision does not use, only Qcw version
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/Qcw/ieee802-dot1q-sched.yang
    ## incompatible with older revision, breaks other yangs
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ieee/draft/802.1/Qcw/ieee802-types.yang
    ## depends on a specific node dot1q-types:transmission-selection-algorithm
    ## which most revision does not use, only Qcz version
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf standard/ieee/draft/802.1/Qcz/ieee802-dot1q-lldp-dcbx-tlv.yang
    ## dependency node 'data-resource-identifier' can not be found in module ietf-restconf
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/example-jukebox.yang
    ## dependency node 'metadata' only avaible in older revision of module ietf-packet-fields
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-access-control-list.yang
    ## missing dependecy node 'ietf-routing:routing-instance', nowhere to be found
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-bfd.yang
    ## node routing-instance can not be found in module ietf-routing
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-isis.yang
    ## wrong augmentaion path, pim is augmentaion of routing not routing-state, line 218
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-bidir@2017-03-09.yang
    ## link to excluded file standard/ietf/DRAFT/ietf-pim-bidir@2017-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-bidir.yang
    ## wrong augmentaion path, pim is augmentaion of routing not routing-state, line 74
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-dm@2017-03-09.yang
    ## link to excluded file standard/ietf/DRAFT/ietf-pim-dm@2017-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-dm.yang
    ## type can be of derived or build-in, not identity, line 635
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-rp@2017-03-09.yang
    ## link to excluded file standard/ietf/DRAFT/ietf-pim-rp@2017-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-rp.yang
    ## wrong augment path, pim is augmentaion of routing not routing-state
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-sm@2017-03-09.yang
    ## link to excluded file standard/ietf/DRAFT/ietf-pim-sm@2017-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-pim-sm.yang
    ## missing version statment, action statment is only in yang 1.1
    ## yang version is mandatory in yang 1.1, https://tools.ietf.org/html/rfc7950#section-1.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/ietf-zerotouch-bootstrap-server.yang
    ## incorrect augmention path, missing some nodes in path like 'ietf-acl:access-lists'
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/DRAFT/newco-acl.yang
    ## Mount points may only be defined at either a container or a list, not anydata, lines 948
    ## https://tools.ietf.org/html/rfc8528#section-3.1
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-connectionless-oam@2019-04-16.yang
    ## removed depndency file from test standard/ietf/RFC/ietf-connectionless-oam@2019-04-16.yang (module ietf-connectionless-oam)
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    rm -vrf standard/ietf/RFC/ietf-connectionless-oam-methods@2019-04-16.yang
    ## removed dependecy file from test standard/ietf/RFC/ietf-connectionless-oam-methods@2019-04-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-connectionless-oam-methods.yang
    ## removed dependency file from test standard/ietf/RFC/ietf-connectionless-oam@2019-04-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-connectionless-oam.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-snmp*
    ## CHOICE is not valid for YANG_DATA, data-def-stmt in https://tools.ietf.org/html/rfc6020#section-12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-sztp-conveyed-info@2019-04-30.yang
    ## CHOICE is not valid for YANG_DATA, data-def-stmt in https://tools.ietf.org/html/rfc6020#section-12
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf standard/ietf/RFC/ietf-sztp-conveyed-info.yang
    ## Removing the cisco folder because there are over 30k yang files there and would increase the test time to something
    ## unmanageable.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco
    ## Removing entire juniper folder because it creates an OOM Crash with the validator tool.*** Keywords ***
    ## Unsure if the yang models are the problem or something in the tool. This is being tracked here:
    ## https://jira.opendaylight.org/browse/YANGTOOLS-1093
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/juniper
