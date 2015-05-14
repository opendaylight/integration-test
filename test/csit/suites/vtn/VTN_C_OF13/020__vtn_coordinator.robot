*** Settings ***
Documentation     Test suite for VTN Coordinator
Suite Setup       Create Session    session    http://${VTNC}:8083  headers=${VTNC_HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/Topology.py
Variables         ../../../variables/Variables.py



*** Test Cases ***
Add a ODL Controller
    [Documentation]    Add a Controller
    [Tags]    vtnc
    Add a Controller    odc_test     ${CONTROLLER}


Verify the Controller Status is up
    [Documentation]    Check Controller status
    [Tags]   vtnc
    Wait Until Keyword Succeeds    30s    2s    Check Controller Status    odc_test    up


Add a Vtn Tenant1
    [Documentation]   Create Vtn Tenant1
    [Tags]   vtnc
    Add a VTN  Tenant1  VTN_TEST


Create VBR in VTN Tenant1
    [Documentation]   Create a VBR in Tenant1 as Vbridge1
    [Tags]   vtnc
    Create VBR in VTN     Tenant1    Vbridge1    odc_test


Create VBRIF in VBRIDGE Vbridge1 Interface1
    [Documentation]   Create an interface to Vbridge1
    [Tags]   vtnc
    Create VBRIF in VBR   Tenant1    Vbridge1   Interface1  Interface1


Create VBRIF in VBRIDGE Vbridge1 Interface2
    [Documentation]   Create an interface to Vbridge1
    [Tags]   vtnc
    Create VBRIF in VBR   Tenant1    Vbridge1   Interface2  Interface2


Define Portmap for Interface1
    [Documentation]   Map Interface1 to a logical port
    [Tags]   vtnc
    Define Portmap for VBRIF    Tenant1    Vbridge1     Interface1    PP-OF:openflow:3-s3-eth1


Define Portmap for Interface2
    [Documentation]   Map Interface2 to a logical port
    [Tags]   vtnc
    Define Portmap for VBRIF    Tenant1    Vbridge1     Interface2    PP-OF:openflow:2-s2-eth1


Test Ping for Configuration1
    [Documentation]   ping between hosts in mininet
    [Tags]   vtnc
    Wait Until Keyword Succeeds    30s    5s   Test Ping    h1    h3


Delete a VTN Tenant1
    [Documentation]   Delete Vtn Tenant1
    [Tags]   vtnc
    Delete a VTN  Tenant1


Delete a Controller odc1
    [Documentation]   Delete Controller odc1
    [Tags]   vtnc
    Remove Controller    odc_test



*** Keywords ***
Add a Controller
   [Arguments]   ${ctrlname}   ${ctrlip}
   [Documentation]    Create a controller
   ${controllerinfo}    Create Dictionary   controller_id   ${ctrlname}   type    odc    ipaddr    ${CONTROLLER}    version    1.0    auditstatus    enable
   ${controllercreate}    Create Dictionary   controller    ${controllerinfo}
   ${resp}    PostJson    session    ${VTNWEBAPI}/${CTRLS_CREATE}    data=${controllercreate}
   Should Be Equal As Strings    ${resp.status_code}    201


Remove Controller
   [Arguments]   ${ctrlname}
   [Documentation]   Delete a Controller
   ${resp}    Delete   session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}.json
   Should Be Equal As Strings    ${resp.status_code}    204


Check Controller Status
   [Arguments]   ${ctrlname}  ${stat}
   [Documentation]    Get controller status
   ${resp}    Get   session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}.json
   ${contents}    To JSON    ${resp.content}
   ${controllerblock}    Get From Dictionary    ${contents}   controller
   ${status}    Get From Dictionary    ${controllerblock}     operstatus
   Should Be Equal As Strings    ${status}    ${stat}


Add a VTN
   [Arguments]   ${vtnname}    ${vtndescription}
   [Documentation]    Create VTN in Coordinator
   ${vtninfo}    Create Dictionary    vtn_name    ${vtnname}    description    ${vtndescription}
   ${vtncreate}    Create Dictionary    vtn    ${vtninfo}
   ${resp}    PostJson    session    ${VTNWEBAPI}/${VTNS_CREATE}    data=${vtncreate}
   Should Be Equal As Strings    ${resp.status_code}    201


Delete a VTN
   [Arguments]   ${vtnname}
   [Documentation]  Delete a VTN Created
   ${resp}    Delete    session    ${VTNWEBAPI}/${VTNS}/${vtnname}.json
   Should Be Equal As Strings    ${resp.status_code}    204


Create VBR in VTN
   [Arguments]   ${vtnname}    ${vbrname}    ${ctrlname}
   [Documentation]    Create VBR for VTN in Coordinator
   ${vbrinfo}    Create Dictionary   vbr_name    ${vbrname}    controller_id   ${ctrlname}    domain_id    (DEFAULT)
   ${vbrcreate}   Create Dictionary   vbridge    ${vbrinfo}
   ${resp}    PostJson    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS_CREATE}    data=${vbrcreate}
   Should Be Equal As Strings    ${resp.status_code}    201


Create VBRIF in VBR
   [Arguments]   ${vtnname}    ${vbrname}    ${vbrifname}    ${ifdescription}
   [Documentation]    Create VBR Interface in VBR
   ${vbrifinfo}    Create Dictionary   if_name    ${vbrifname}    description    ${ifdescription}
   ${vbrifcreate}    Create Dictionary   interface    ${vbrifinfo}
   ${resp}    PostJson    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${VBRIFS_CREATE}  data=${vbrifcreate}
   Should Be Equal As Strings    ${resp.status_code}    201


Define Portmap for VBRIF
   [Arguments]   ${vtnname}    ${vbrname}    ${vbrifname}   ${logical_port_id}
   [Documentation]   Map  Interface to a logical port
   ${logical_port_info}    Create Dictionary    logical_port_id    ${logical_port_id}
   ${portmapdefine}     Create Dictionary     portmap     ${logical_port_info}
   ${resp}   Put     session      ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${VBRIFS}/${vbrifname}/${PORTMAP_CREATE}    data=${portmapdefine}
   Should Be Equal As Strings    ${resp.status_code}    204

Test Ping
   [Arguments]   ${host1}    ${host2}
   [Documentation]  Ping hosts to check connectivity
   Write    ${host1} ping -w 10 ${host2}
   ${result}    Read
   Should Contain    ${result}    64 bytes
