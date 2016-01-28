*** Settings ***
Documentation     Test suite for VTN Coordinator
Suite Setup       Start SuiteVtnCoTest
Suite Teardown    Stop SuiteVtnCoTest
Resource          ../../../libraries/VtnCoKeywords.robot
Resource          ../../../libraries/WaitForFailure.robot

*** Test Cases ***
Add a ODL Controller with Invalid IP
    [Documentation]    Add a Controller
    Add a Controller    odc_test    10.0.0.1

Verify the Controller Status is down
    [Documentation]    Check Controller status
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    12s    1s    Check Controller Status    odc_test    down

Add a Vtn Tenant1
    [Documentation]    Create Vtn Tenant1
    Add a VTN    Tenant1    VTN_TEST

Create VBR in VTN Tenant1
    [Documentation]    Create a VBR in Tenant1 as Vbr_audit
    Create VBR in VTN    Tenant1    Vbr_audit    odc_test

Create VBRIF in VBRIDGE Vbr_audit Interface1
    [Documentation]    Create an interface to Vbr_audit
    Create VBRIF in VBR    Tenant1    Vbr_audit    Interface1    Interface1    202

Create VBRIF in VBRIDGE Vbr_audit Interface2
    [Documentation]    Create an interface to Vbr_audit
    Create VBRIF in VBR    Tenant1    Vbr_audit    Interface2    Interface2    202

Update controller to Valid IP
    [Documentation]    Update Controller ip to valid from invalid
    Update Controller    odc_test    ${ODL_SYSTEM_IP}    valid_IP

Verify the Controller State is in waiting_audit
    [Documentation]    Check Controller status
    Wait Until Keyword Succeeds    12s    2s    Check Controller Status    odc_test    waiting_audit

Audit a controller manually
    [Documentation]    Trigger update audit
    Audit Controller    odc_test

Define Portmap for Interface1
    [Documentation]    Map Interface1 to a logical port
    Define Portmap for VBRIF    Tenant1    Vbr_audit    Interface1    PP-OF:openflow:2-s2-eth1

Define Portmap for Interface2
    [Documentation]    Map Interface2 to a logical port
    Define Portmap for VBRIF    Tenant1    Vbr_audit    Interface2    PP-OF:openflow:2-s2-eth2

Test Ping for Configuration1
    [Documentation]    ping between hosts in mininet
    Wait Until Keyword Succeeds    20s    1s    Test Ping    h1    h2

Delete a VTN Tenant1
    [Documentation]    Delete Vtn Tenant1
    Delete a VTN    Tenant1

Delete a Controller odc1
    [Documentation]    Delete Controller odc1
    Remove Controller    odc_test
