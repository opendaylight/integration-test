*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
${net-1}    NET10
${net-2}    NET20
${subnet-1}    SUBNET1
${subnet-2}    SUBNET2
${subnet-1-cidr}    10.1.1.0/24
${subnet-2-cidr}    20.1.1.0/24

*** Test Cases ***
Verify Tunnel Creation
    [Documentation]    Checks that vxlan tunnels have been created properly.
    [Tags]    exclude
    Log    This test case is currently a noop, but work can be added here to validate if needed.  However, as the
    ...    suite Documentation notes, it's already assumed that the environment has been configured properly.  If
    ...    we do add work in this test case, we need to remove the "exclude" tag for it to run.  In fact, if this
    ...    test case is critical to run, and if it fails we would be dead in the water for the rest of the suite,
    ...    we should move it to Suite Setup so that nothing else will run and waste time in a broken environment.

Create Neutron Networks
    [Documentation]    Create two networks
    Create Network    ${net-1}    --provider:network_type local
    Create Network    ${net-2}    --provider:network_type local
    List Networks

Create Neutron Subnets
    [Documentation]    Create two subnets for previously created networks
    Create SubNet    ${net-1}    {subnet-1}    ${subnet-1-cidr}
    Create SubNet    ${net-2}    {subnet-2}    ${subnet-2-cidr}
    List Subnets

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions