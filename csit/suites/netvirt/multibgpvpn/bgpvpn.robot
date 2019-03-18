*** Settings ***
Documentation     Test suite to validate bgpvpn configuration commands in an openstack integrated environment.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***

*** Test Cases ***
Verify CSC supports VPN creation via neutron bgpvpn create command
    [Documentation]    Verify CSC supports VPN creation via neutron bgpvpn create command
    Log    Create a VPN with multiple RD's
    ${Additional_Args}    Set Variable    --route-distinguisher 100:10
    OpenStackOperations.Create Bgpvpn    BgpVpn1    ${Additional_Args}
    ${vpnid}    OpenStackOperations.Get Bgpvpn Id    BgpVpn1

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for BGP_VPN_CONFIGS.
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Get Suite Debugs
