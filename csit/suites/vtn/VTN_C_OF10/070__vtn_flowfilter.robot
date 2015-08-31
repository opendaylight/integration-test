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

Create Flowlistentry_any in Flowlist1
    [Documentation]	Create an Flowlistentry_any to Flowlist1
    Create FLOWLISTENTRY_ANY in FLOWLIST   Flowlist1

Create VTN in Flowfilter1
    [Documentation]  Create an Vtn to Flowfilter
    Create FLOWFILTER in VTN   Tenant1   in

Create FlowfilterEntry  in VTNFlowfilter
    [Documentation]   Create an Vtn FlowfilterEntry
    Create FLOWFILTERENTRY PASS in VTNFLOWFILTER   Tenant1   pass

Test Ping for Configuration
    [Documentation]    ping between hosts in mininet
    Wait Until Keyword Succeeds   10s    2s    Test Ping    h1    h3

Delete a VTN Tenant1
    [Documentation]    Delete Vtn Tenant1
    Delete a VTN    Tenant1

Delete a FLOWLIST Flowlist1
    [Documentation]   Delete Flowlist
    Delete a FLOWLIST   Flowlist1


Delete a Controller odc1
    [Documentation]   Delete Controller odc1
    Remove Controller   odc_test 
