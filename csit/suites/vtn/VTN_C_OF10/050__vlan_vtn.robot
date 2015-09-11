*** Settings ***
Documentation     Test suite for VTN Coordinator
Suite Setup       Start SuiteVtnCoTest
Suite Teardown    Stop SuiteVtnCoTest
Resource          ../../../libraries/VtnCoKeywords.robot

*** Test Cases ***
Add a ODL Controller
    [Documentation]    Add a Controller
    Add a Controller    odc_test    ${CONTROLLER}

Verify the Controller Status is waiting_audit
    [Documentation]    Check Controller status
    # Ping starts after 12sec of completing audit and controller status become "UP"
    Wait Until Keyword Succeeds    12s    2s   Check Controller Status    odc_test   waiting_audit

Audit a controller
    [Documentation]    Trigger update audit
    Audit Controller    odc_test

Clear Mininet
    [Documentation]   Clear the old mininet session.
    Clear Mininet

Start topology
    [Documentation]    Add a vlan topology
    Start vlan_topo

Add a Vtn Tenant1
    [Documentation]    Create Vtn Tenant1
    Add a VTN    Tenant1    VTN_TEST

Create VBR in VTN Tenant1
    [Documentation]    Create a VBR in Tenant1 as Vbridge1
    Create VBR in VTN    Tenant1    Vbridge1    odc_test

Create VLANMAP in VBRIDGE1
    [Documentation]    Create a Vlanmap in  Vbridge1
    Create VLANMAP in VBRIDGE    Tenant1   Vbridge1   200

Create VBR2 in VTN Tenant1
    [Documentation]    Create a VBR in Tenant1 as Vbridge1
    Create VBR in VTN    Tenant1    Vbridge2    odc_test

Create VLANMAP in VBRIDGE2
    [Documentation]    Create a Vlanmap in  Vbridge1
    Create VLANMAP in VBRIDGE    Tenant1   Vbridge2   300

Test Ping for Configuration1
    [Documentation]    ping between hosts in mininet
    Wait Until Keyword Succeeds    30s    2s    Test Ping    h1   h3

Test Ping for Configuration2
    [Documentation]    ping between hosts in mininet
    Wait Until Keyword Succeeds    30s    2s    Test Ping    h1   h5

Test Ping for Configuration3
    [Documentation]    ping between hosts in mininet
    Wait Until Keyword Succeeds    30s    2s    Test Ping    h2   h4

Test Ping for Configuration4
    [Documentation]    ping between hosts in mininet
    Wait Until Keyword Succeeds    30s    2s    Test Ping    h2   h6

Delete a VTN Tenant1
    [Documentation]   Delete Vtn Tenant1
    Delete a VTN    Tenant1

Delete a Controller odc1
    [Documentation]    Delete Controller odc1
    Remove Controller    odc_test
