*** Settings ***
Documentation     Test suite to validate bgpvpn configuration commands in an openstack integrated environment.
Suite Setup       Suite Setup
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
Verify ODL supports VPN creation via neutron bgpvpn create command
    [Documentation]    Verify ODL supports VPN creation via neutron bgpvpn create command
    OpenStackOperations.Create Bgpvpn    BgpVpn1    --route-distinguisher 100:10
    ${vpnid} =    OpenStackOperations.Get Bgpvpn Id    BgpVpn1
