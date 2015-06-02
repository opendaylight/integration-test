*** Settings ***
Documentation     Test suite for VTN Coordinator
Suite Setup       Start SuiteVtnCoTest
Suite Teardown    Stop SuiteVtnCoTest
Resource          ../../../libraries/VtnCoKeywords.txt

*** Test Cases ***
Add a ODL Controller
    [Documentation]    Add a Controller
    Add a Controller    odc_test    ${CONTROLLER}

Verify the Controller Status is up
    [Documentation]    Check Controller status
    Wait Until Keyword Succeeds    30s    5s    Check Controller Status    odc_test    up

Add a Vtn Tenant1
    [Documentation]    Create Vtn Tenant1
    Wait Until Keyword Succeeds    10s    5s    Add a VTN    Tenant1    VTN_TEST

Create VBR in VTN Tenant1
    [Documentation]    Create a VBR in Tenant1 as Vbridge1
    Create VBR in VTN    Tenant1    Vbridge1    odc_test

Create VBRIF in VBRIDGE Vbridge1 Interface1
    [Documentation]    Create an interface to Vbridge1
    Create VBRIF in VBR    Tenant1    Vbridge1    Interface1    Interface1    201

Create VBRIF in VBRIDGE Vbridge1 Interface2
    [Documentation]    Create an interface to Vbridge1
    Create VBRIF in VBR    Tenant1    Vbridge1    Interface2    Interface2    201

Define Portmap for Interface1
    [Documentation]    Map Interface1 to a logical port
    Define Portmap for VBRIF    Tenant1    Vbridge1    Interface1    PP-OF:openflow:3-s3-eth1

Define Portmap for Interface2
    [Documentation]    Map Interface2 to a logical port
    Define Portmap for VBRIF    Tenant1    Vbridge1    Interface2    PP-OF:openflow:2-s2-eth1

Test Ping for Configuration1
    [Documentation]    ping between hosts in mininet
    Wait Until Keyword Succeeds    30s    10s    Test Ping    h1    h3

Delete a VTN Tenant1
    [Documentation]    Delete Vtn Tenant1
    Delete a VTN    Tenant1

Delete a Controller odc1
    [Documentation]    Delete Controller odc1
    Remove Controller    odc_test
