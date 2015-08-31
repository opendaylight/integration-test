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

Add a Vtn Tenant1
    [Documentation]    Create Vtn Tenant1
    Add a VTN    Tenant1    VTN_TEST

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

Add a Flowlist Flowlist1
    [Documentation]    Create Flowlist Tenant1
    Add a FLOWLIST    Flowlist1   IP

Create Flowlistentry in Flowlist1
    [Documentation]    Create an Flowlistentry to Flowlist1
    Create FLOWLISTENTRY    Flowlist1

Create Flowfilter1 in VBRIF
    [Documentation]  Create an Vbrif to Flowfilter
    Create VBRIF in FLOWFILTER   Tenant1   Vbridge1   Interface1   in

Create Flowfilterentry with Drop Action in VBRIF
     [Documentation]   Create an Flowfilter Drop Action
     Create FLOWFILTERENTRY DROP In VBRIFFLOWFILTER  Tenant1   Vbridge1   Interface1  drop

Create Flowfilterentry With Pass Action in VBRIF
     [Documentation]   Update an Flowfilter Pass Action
     Create FLOWFILTERENTRY PASS In VBRIFFLOWFILTER   Tenant1   Vbridge1   Interface1   pass    233

Test Ping for Configuration
    [Documentation]    ping between hosts in mininet
    Wait Until Keyword Succeeds   10s    2s    Test Ping    h1   h3

Delete a VTN Tenant1
    [Documentation]    Delete Vtn Tenant1
    Delete a VTN    Tenant1

Delete a FLOWLIST Flowlist1
    [Documentation]   Delete Flowlist
    Delete a FLOWLIST   Flowlist1

Delete a Controller odc1
    [Documentation]    Delete Controller odc1
    Remove Controller   odc_test
