*** Settings ***
Documentation     Test Suite that, verifies the features and corresponding bundles are installed.
Resource          ../../libraries/KarafKeywords.robot

*** Variables ***
@{FEATURE_LIST}    odl-vpnservice-api    odl-vpnservice-impl    odl-vpnservice-impl-rest    odl-vpnservice-impl-ui    odl-vpnservice-core
@{BUNDLE_LIST}    org.opendaylight.vpnservice.vpnmanager-impl    org.opendaylight.vpnservice.interfacemgr-impl    org.opendaylight.vpnservice.nexthopmgr-impl    org.opendaylight.vpnservice.idmanager-impl    org.opendaylight.vpnservice.fibmanager-impl    org.opendaylight.vpnservice.bgpmanager-impl    org.opendaylight.vpnservice.model-bgp
@{MESSAGE_STRING_LIST}    VpnserviceProvider Session Initiated    InterfacemgrProvider Session Initiated    NexthopmgrProvider Session Initiated    IDManagerserviceProvider Session Initiated    FibManagerProvider Session Initiated    BgpManager Session Initiated

*** Test Cases ***
Verify if the VPN Service features are installed for vpnservice
    [Documentation]    Executes command "feature list -i | grep <feature_name>" in karaf console and checks if output \ contain \ the specific features.
    [Tags]    Verify Feature
    : FOR    ${feature}    IN    @{FEATURE_LIST}
    \    Verify Feature Is Installed    ${feature}

Verify if the VPN Service bundles are loaded
    [Documentation]    Executes command "bundle:list -s | grep <bundle name>" and checks in the output for the specific bundles
    [Tags]    Verify VPN bundles
    : FOR    ${bundle}    IN    @{BUNDLE_LIST}
    \    Verify Bundle Is Installed    ${bundle}

Verify if the sessions for bundles got initiated
    [Documentation]    Executes"log:display | grep vpnservice" command in karaf console and verifies the logs for session initiation
    [Tags]    Verify Session
    Wait Until Keyword Succeeds    240 seconds    30 seconds    Check Karaf Log Has Messages    vpnservice    @{MESSAGE_STRING_LIST}
