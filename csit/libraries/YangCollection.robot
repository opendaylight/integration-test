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
...               04/01/2020
...
Resource          ${CURDIR}/SSHKeywords.robot

*** Variables ***
${YANGMODELS_REPO}    https://github.com/YangModels/yang
${OPENCONFIG_REPO}    https://github.com/openconfig/public
${YANGMODELS_REPO_COMMIT_HASH}    7351cec0c92d7fed74ae4a7c10f6bf4d32a95fa6    # TODO: update docs with new date when changing
${OPENCONFIG_REPO_COMMIT_HASH}    e3c0374ce6aa9d1230ea31a5f0f9a739ed0db308    # TODO: update docs with new date when changing

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
    ${full_cwd} =    SSHLibrary.Execute_Command    pwd
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang
    [Return]    ${full_cwd}/src/main/yang

Delete_Static_Paths
    [Documentation]    Long list of "rm -vrf" commands.
    ...    All files/paths removed below are due to real issues in those files/paths as found with failures in
    ...    the yang-model-validator tool. We do not want OpenDaylight CSIT to fail because of problems with
    ...    external yangs.
    # Please keep below list in alpha order
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/@2015-03-09.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/TUDA-V1-ATTESTATION-MIB@2017-10-30.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/alto-service-types@2015-03-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/bfd.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/gen-oam@2014-10-23.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/huawei-dhcp@2014-12-18.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/huawei-ipte@2014-08-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/i2rs-rib@2015-04-03.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/i2rs-service-topology@2015-07-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/iana-geo-uri-type@2014-05-08.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-OPSAWG-ute-tunnel.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-bulk-notification@2019-09-23.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-gen-oam-ais@2016-06-25.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-global@2014-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-links@2014-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-lsps@2014-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-mpls-te-tunnel-ifs@2014-10-13.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-netconf-light@2012-01-12.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-sd-onos-service-l3vpn@2015-12-16.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-abstracted-l3vpn@2015-05-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-ddc@2014-12-25.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-supa-l3vpn@2015-02-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-template.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ietf-yang-hash@2016-02-10.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/ipfix-psamp.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/lora.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/media-channel@2014-06-05.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-rsvp@2015-04-22.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/mpls-te@2014-07-07.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/openconfig-mpls-rsvp@2015-09-18.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/service-function@2014-29-04.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/softwire@2014-12-14.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf experimental/ietf-extracted-YANG-modules/tunnel-policy@2018-09-15.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf .git
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf tools
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/nx/7.0-3-I6-1/cisco-nx-openconfig-if-ip-deviations.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/nx/7.0-3-I6-1/cisco-nx-openconfig-routing-policy-deviations.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/nx/7.0-3-I7-1/cisco-nx-openconfig-if-ip-deviations.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/nx/7.0-3-I7-1/cisco-nx-openconfig-routing-policy-deviations.yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/cisco/xr/613/cisco-xr-openconfig-bgp-deviations.yang
    ## Removing entire juniper folder because it creates an OOM Crash with the validator tool.*** Keywords ***
    ## Unsure if the yang models are the problem or something in the tool. This is being tracked here:
    ## https://jira.opendaylight.org/browse/YANGTOOLS-1093
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -vrf vendor/juniper
