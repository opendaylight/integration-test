*** Settings ***
Documentation     Test suite for SFC Service Function Forwarders, Operates SFFs from Restconf APIs.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SERVICE_FORWARDERS_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/
${SERVICE_FORWARDERS_FILE}    ../../../variables/sfc/service-function-forwarders.json
${SFF_OVS100_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/service-function-forwarder/ovs-100/
${SFF_OVS100_FILE}    ../../../variables/sfc/sff_ovs_100.json
${SFF_DPL101_FILE}    ../../../variables/sfc/sff_dpl_101.json
${SFF_DPL_LOCATOR_FILE}    ../../../variables/sfc/sff_dpl_locator.json
${SFF_SFD_SF100_FILE}    ../../../variables/sfc/sff_sfd_sf100.json
${SFF_SFD_LOCATOR_FILE}    ../../../variables/sfc/sff_sfd_locator.json
${SFF_CSD_SFF100_FILE}    ../../../variables/sfc/sff_csd_sff100.json
${SFF_CSD_LOCATOR_FILE}    ../../../variables/sfc/sff_csd_locator.json

*** Test Cases ***
Put Service Function Forwarders
    [Documentation]    Add Service Function Forwarders from JSON file
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FORWARDERS_FILE}
    ${jsonbody}    To Json    ${body}
    ${forwarders}    Get From Dictionary    ${jsonbody}    service-function-forwarders
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${forwarder}    Get From Dictionary    ${result}    service-function-forwarders
    Lists Should be Equal    ${forwarder}    ${forwarders}

Delete All Service Function Forwarders
    [Documentation]    Delete all Service Function Forwarders
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function Forwarder
    [Documentation]    Get one Service Function Forwarder
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    Create List    SFF-bootstrap    service-locator:vxlan-gpe    SF1
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap    ${elements}

Get A Non-existing Service Function Forwarder
    [Documentation]    Get A Non-existing Service Function Forwarder
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/non-existing-sff
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function Forwarder
    [Documentation]    Delete A Service Function Forwarder
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    SF1

Delete A Non-existing Service Function Forwarder
    [Documentation]    Delete A Non existing Service Function
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FORWARDERS_FILE}
    ${jsonbody}    To Json    ${body}
    ${forwarders}    Get From Dictionary    ${jsonbody}    service-function-forwarders
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/non-existing-sff
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${forwarder}    Get From Dictionary    ${result}    service-function-forwarders
    Lists Should be Equal    ${forwarder}    ${forwarders}

Put one Service Function Forwarder
    [Documentation]    Put one Service Function Forwarder
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SFF_OVS100_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}=    Create List    ovs-100    SF7
    Check For Elements At URI    ${SFF_OVS100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}    ${elements}

Get Service Function Forwarder DPL
    [Documentation]    Get Service Function Data Plane Locator
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    ${elements}=    Create List    eth0    service-locator:vxlan-gpe
    Check For Elements At URI    ${SFF_OVS100_URI}sff-data-plane-locator/eth0    ${elements}

Put Service Function Forwarder DPL
    [Documentation]    Put Service Function Forwarder Data Plane Locator
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    ${elements}=    Create List    dpl-101    6101
    Check For Elements At URI    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101    ${elements}
    Check For Elements At URI    ${SFF_OVS100_URI}    ${elements}

Put DPL to a Non-existing Service Function Forwarder
    [Documentation]    Put Service Function DPL to a Non-existing Service Function
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ovs-100
    ${elements}=    Create List    dpl-101    6101
    Check For Elements At URI    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101    ${elements}
    Check For Elements At URI    ${SFF_OVS100_URI}    ${elements}

Delete Service Function Forwarder DPL
    [Documentation]    Delete Service Function Forwarder Data Plane Locator
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    Remove All Elements At URI    ${SFF_OVS100_URI}sff-data-plane-locator/eth0
    ${resp}    RequestsLibrary.Get    session    ${SFF_OVS100_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    eth0

Get Service Function Forwarder DPL's Locator
    [Documentation]    Get Service Function Data Plane Locator
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    ${elements}=    Create List    6000    service-locator:vxlan-gpe
    Check For Elements At URI    ${SFF_OVS100_URI}sff-data-plane-locator/eth0/data-plane-locator/    ${elements}

Put Service Function Forwarder DPL's Locator
    [Documentation]    Put Service Function Forwarder Data Plane Locator
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101/data-plane-locator/    ${SFF_DPL_LOCATOR_FILE}
    ${elements}=    Create List    5000    service-locator:vxlan-gpe
    Check For Elements At URI    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101/data-plane-locator    ${elements}
    ${elements}=    Create List    dpl-101    5000    service-locator:vxlan-gpe
    Check For Elements At URI    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101    ${elements}
    Check For Elements At URI    ${SFF_OVS100_URI}    ${elements}

Delete Service Function Forwarder DPL's Locator
    [Documentation]    Delete Service Function Forwarder Data Plane Locator
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101/data-plane-locator/    ${SFF_DPL_LOCATOR_FILE}
    Remove All Elements At URI    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101/data-plane-locator
    ${resp}    RequestsLibrary.Get    session    ${SFF_OVS100_URI}sff-data-plane-locator/dpl-101
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    dpl-101
    Should Not Contain    ${resp.content}    6101
    Should Not Contain    ${resp.content}    service-locator:vxlan-gpe
    ${resp}    RequestsLibrary.Get    session    ${SFF_OVS100_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    dpl-101
    Should Not Contain    ${resp.content}    6101

Get Service Function Dictionary From SFF
    [Documentation]    Get Service Function Dictionary From SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    Create List    service-function-dictionary    service-function-type:dpi    SF1
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1    ${elements}

Delete Service Function Dictionary From SFF
    [Documentation]    Delete Service Function Dictionary From SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    service-function-dictionary
    Should Not Contain    ${resp.content}    SF1

Put Service Function Dictionary to SFF
    [Documentation]    Put Service Function Dictionary to SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF100    ${SFF_SFD_SF100_FILE}
    ${elements}=    Create List    service-function-type:napt44    SF100
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF100    ${elements}
    ${elements}=    create list    service-function-dictionary    service-function-type:napt44    SF100
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/    ${elements}

Get Service Function Dictionary's DPL From SFF
    [Documentation]    Get Service Function Dictionary From SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    create list    sff-sf-data-plane-locator    5000    10.1.1.1
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1/sff-sf-data-plane-locator/    ${elements}

Delete Service Function Dictionary's DPL From SFF
    [Documentation]    Delete Service Function Dictionary From SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1/sff-sf-data-plane-locator/
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1/sff-sf-data-plane-locator/
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1/sff-sf-data-plane-locator/
    Should Be Equal As Strings    ${resp.status_code}    404

Put DPL of Service Function Dictionary to SFF
    [Documentation]    Put DPL of Service Function Dictionary to SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1/sff-sf-data-plane-locator/    ${SFF_SFD_LOCATOR_FILE}
    ${elements}=    create list    sff-sf-data-plane-locator    6000    10.1.1.1
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1/sff-sf-data-plane-locator/    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/service-function-dictionary/SF1/    ${elements}

Get Connected SFF Dictionary From SFF
    [Documentation]    Get Connected SFF Dictionary Dictionary From SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    create list    connected-sff-dictionary    br-int-ovs-2    sff-sff-data-plane-locator
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2    ${elements}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/br-int-ovs-2/connected-sff-dictionary/SFF-bootstrap
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    SFF-bootstrap

Delete Connected SFF Dictionary From SFF
    [Documentation]    Delete Connected SFF Dictionary From SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    br-int-ovs-2

Put Connected SFF Dictionary to SFF
    [Documentation]    Put Connected SFF Dictionary to SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/SFF100    ${SFF_CSD_SFF100_FILE}
    ${elements}=    create list    SFF100    service-function-forwarder:open
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/SFF100    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/    ${elements}

Get Connected SFF Dictionary's DPL From SFF
    [Documentation]    Get Connected SFF Dictionary's DPL From SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    create list    sff-sff-data-plane-locator    5000    192.168.1.2
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator/    ${elements}

Delete Connected SFF Dictionary's DPL From SFF
    [Documentation]    Connected SFF Dictionary's DPL From SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator/
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator/
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator/
    Should Be Equal As Strings    ${resp.status_code}    404

Put DPL of Connected SFF Dictionary to SFF
    [Documentation]    Put DPL of Connected SFF Dictionary to SFF
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator/    ${SFF_CSD_LOCATOR_FILE}
    ${elements}=    create list    sff-sff-data-plane-locator    6000    10.1.1.1
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator/    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}service-function-forwarder/SFF-bootstrap/connected-sff-dictionary/br-int-ovs-2/    ${elements}

Clean The Datastore After Tests
    [Documentation]    Clean All Service Function Forwarders In Datastore After Tests
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
