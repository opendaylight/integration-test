
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
    [Documentation]    Add a Controller odc1
    [Tags]    vtnc
    Add a Controller    odc_test     ${CONTROLLER}

Verify the Controller Status is up
    [Documentation]    Check Controller status
    [Tags]   vtnc
    Wait Until Keyword Succeeds   30s   2s   Check Controller Status   odc_test   up

Verify switch1
    [Documentation]    Get switch1
    [Tags]   vtnc
    Wait Until Keyword Succeeds   30s   2s   Verify Switch   odc_test   00:00:00:00:00:00:00:01

Verify switch2
    [Documentation]    Get switch2
    [Tags]   vtnc
    Wait Until Keyword Succeeds   30s   2s   Verify Switch   odc_test   00:00:00:00:00:00:00:02

Verify switch3
    [Documentation]    Get switch3
    [Tags]   vtnc
    Wait Until Keyword Succeeds   30s   2s   Verify Switch   odc_test   00:00:00:00:00:00:00:03

Verify switchPort switch1
    [Documentation]   Get switchport/switch1
    [Tags]   vtnc
    Wait Until Keyword Succeeds   16s   2s   Verify SwitchPort   odc_test   00:00:00:00:00:00:00:01

Verify switchPort switch2
    [Documentation]   Get switchport/switch2
    [Tags]   vtnc
    Wait Until Keyword Succeeds   16s   2s   Verify SwitchPort   odc_test   00:00:00:00:00:00:00:02

Verify switchPort switch3
    [Documentation]   Get switchport/switch3
    [Tags]   vtnc
    Wait Until Keyword Succeeds   16s   2s   Verify SwitchPort   odc_test   00:00:00:00:00:00:00:03

Delete a Controller
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
   [Arguments]   ${ctrlname}   ${stat}
   [Documentation]    Get controller status
   ${resp}    Get   session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}.json
   ${contents}    To JSON    ${resp.content}
   ${controllerblock}    Get From Dictionary    ${contents}   controller
   ${status}    Get From Dictionary    ${controllerblock}     operstatus
   Should Be Equal As Strings    ${status}    ${stat}

Verify Switch
   [Arguments]   ${ctrlname}  ${switch_id}
   [Documentation]    Get switch
   ${resp}    Get   session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}/${SW}/${switch_id}.json
   ${contents}    To JSON    ${resp.content}
   ${switchblock}    Get From Dictionary    ${contents}   switch
   ${status}    Get From Dictionary    ${switchblock}     switch_id
   Should Be Equal As Strings    ${status}     ${switch_id}

Verify SwitchPort
   [Arguments]   ${ctrlname}  ${switch_id}
   [Documentation]    Get switch
   ${resp}    Get   session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}/${SW}/${switch_id}/${PORTS}
   Should Be Equal As Strings    ${resp.status_code}    200
