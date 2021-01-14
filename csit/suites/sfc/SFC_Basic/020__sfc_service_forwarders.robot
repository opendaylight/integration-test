*** Settings ***
Documentation     Test suite for SFC Service Function Forwarders, Operates SFFs from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Put Service Function Forwarders
    [Documentation]    Add Service Function Forwarders from JSON file
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FORWARDERS_FILE}
    ${jsonbody}    To Json    ${body}
    ${forwarders}    Get From Dictionary    ${jsonbody}    service-function-forwarders
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FORWARDERS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${forwarder}    Get From Dictionary    ${result}    service-function-forwarders
    Lists Should be Equal    ${forwarder}    ${forwarders}

Delete All Service Function Forwarders
    [Documentation]    Delete all Service Function Forwarders
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FORWARDERS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function Forwarder
    [Documentation]    Get one Service Function Forwarder
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    Create List    SFF-bootstrap    service-locator:vxlan-gpe    SF1
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}    ${elements}

Get A Non-existing Service Function Forwarder
    [Documentation]    Get A Non-existing Service Function Forwarder
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FORWARDER_URI}/non-existing-sff
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function Forwarder
    [Documentation]    Delete A Service Function Forwarder
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SFF_BOOTSTRAP_URI}
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.text}    SF1

Delete A Non-existing Service Function Forwarder
    [Documentation]    Delete A Non existing Service Function
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FORWARDERS_FILE}
    ${jsonbody}    To Json    ${body}
    ${forwarders}    Get From Dictionary    ${jsonbody}    service-function-forwarders
    ${resp}    RequestsLibrary.DELETE On Session    session    ${SERVICE_FORWARDER_URI}/non-existing-sff
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FORWARDERS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${forwarder}    Get From Dictionary    ${result}    service-function-forwarders
    Lists Should be Equal    ${forwarder}    ${forwarders}

Put one Service Function Forwarder
    [Documentation]    Put one Service Function Forwarder
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_OVS100_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    ovs-100    SF7
    Check For Elements At URI    ${SFF_OVS100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}    ${elements}

Get Service Function Forwarder DPL
    [Documentation]    Get Service Function Data Plane Locator
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    ${elements}=    Create List    eth0    service-locator:vxlan-gpe
    Check For Elements At URI    ${SFF_OVS100_URI}/sff-data-plane-locator/eth0    ${elements}

Put Service Function Forwarder DPL
    [Documentation]    Put Service Function Forwarder Data Plane Locator
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    ${elements}=    Create List    dpl-101    6101
    Check For Elements At URI    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101    ${elements}
    Check For Elements At URI    ${SFF_OVS100_URI}    ${elements}

Put DPL to a Non-existing Service Function Forwarder
    [Documentation]    Put Service Function DPL to a Non-existing Service Function
    Add Elements To URI From File    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FORWARDERS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.text}    ovs-100
    ${elements}=    Create List    dpl-101    6101
    Check For Elements At URI    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101    ${elements}
    Check For Elements At URI    ${SFF_OVS100_URI}    ${elements}

Delete Service Function Forwarder DPL
    [Documentation]    Delete Service Function Forwarder Data Plane Locator
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    Remove All Elements At URI    ${SFF_OVS100_URI}/sff-data-plane-locator/eth0
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_OVS100_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.text}    "name":"eth0"

Get Service Function Forwarder DPL's Locator
    [Documentation]    Get Service Function Data Plane Locator
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    ${elements}=    Create List    6000    service-locator:vxlan-gpe
    Check For Elements At URI    ${SFF_OVS100_URI}/sff-data-plane-locator/eth0/data-plane-locator/    ${elements}

Put Service Function Forwarder DPL's Locator
    [Documentation]    Put Service Function Forwarder Data Plane Locator
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101/data-plane-locator/    ${SFF_DPL_LOCATOR_FILE}
    ${elements}=    Create List    5000    service-locator:vxlan-gpe
    Check For Elements At URI    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101/data-plane-locator    ${elements}
    ${elements}=    Create List    dpl-101    5000    service-locator:vxlan-gpe
    Check For Elements At URI    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101    ${elements}
    Check For Elements At URI    ${SFF_OVS100_URI}    ${elements}

Delete Service Function Forwarder DPL's Locator
    [Documentation]    Delete Service Function Forwarder Data Plane Locator
    [Tags]    exclude
    Add Elements To URI From File    ${SFF_OVS100_URI}    ${SFF_OVS100_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101    ${SFF_DPL101_FILE}
    Add Elements To URI From File    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101/data-plane-locator    ${SFF_DPL_LOCATOR_FILE}
    Remove All Elements At URI    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101/data-plane-locator
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_OVS100_URI}/sff-data-plane-locator/dpl-101
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.text}    dpl-101
    Should Not Contain    ${resp.text}    6101
    Should Not Contain    ${resp.text}    service-locator:vxlan-gpe
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_OVS100_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.text}    dpl-101
    Should Not Contain    ${resp.text}    6101

Get Service Function Dictionary From SFF
    [Documentation]    Get Service Function Dictionary From SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    Create List    service-function-dictionary    SF1    SF1-DPL    eth0
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}    ${elements}

Delete Service Function Dictionary From SFF
    [Documentation]    Delete Service Function Dictionary From SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.text}    service-function-dictionary
    Should Not Contain    ${resp.text}    SF1

Put Service Function Dictionary to SFF
    [Documentation]    Put Service Function Dictionary to SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SFF_BOOTSTRAP_URI}/service-function-dictionary/SF100    ${SFF_SFD_SF100_FILE}
    ${elements}=    Create List    SF100    SF2-DPL    eth0
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/service-function-dictionary/SF100    ${elements}
    ${elements}=    create list    service-function-dictionary    SF100    SF2-DPL    eth0
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}    ${elements}

Get Service Function Dictionary's DPL From SFF
    [Documentation]    Get Service Function Dictionary From SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    create list    sff-sf-data-plane-locator    SF1-DPL    eth0
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}/sff-sf-data-plane-locator/    ${elements}

Delete Service Function Dictionary's DPL From SFF
    [Documentation]    Delete Service Function Dictionary From SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}/sff-sf-data-plane-locator
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}/sff-sf-data-plane-locator
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}/sff-sf-data-plane-locator
    Should Be Equal As Strings    ${resp.status_code}    404

Put DPL of Service Function Dictionary to SFF
    [Documentation]    Put DPL of Service Function Dictionary to SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}/sff-sf-data-plane-locator    ${SFF_SFD_LOCATOR_FILE}
    ${elements}=    create list    sff-sf-data-plane-locator    SF2-DPL    eth0
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}/sff-sf-data-plane-locator    ${elements}
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/${SF_DICT_SF1_URI}    ${elements}

Get Connected SFF Dictionary From SFF
    [Documentation]    Get Connected SFF Dictionary Dictionary From SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    create list    connected-sff-dictionary    br-int-ovs-2    sff-sff-data-plane-locator
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/br-int-ovs-2    ${elements}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FORWARDER_URI}/br-int-ovs-2/connected-sff-dictionary/SFF-bootstrap
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.text}    SFF-bootstrap

Delete Connected SFF Dictionary From SFF
    [Documentation]    Delete Connected SFF Dictionary From SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/br-int-ovs-2
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/br-int-ovs-2
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/br-int-ovs-2
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.GET On Session    session    ${SFF_BOOTSTRAP_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.text}    br-int-ovs-2

Put Connected SFF Dictionary to SFF
    [Documentation]    Put Connected SFF Dictionary to SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/SFF100    ${SFF_CSD_SFF100_FILE}
    ${elements}=    create list    SFF100    service-function-forwarder:open
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/SFF100    ${elements}
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}    ${elements}

Get Connected SFF Dictionary's DPL From SFF
    [Documentation]    Get Connected SFF Dictionary's DPL From SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    create list    sff-sff-data-plane-locator    5000    192.168.1.2
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator    ${elements}

Put DPL of Connected SFF Dictionary to SFF
    [Documentation]    Put DPL of Connected SFF Dictionary to SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator    ${SFF_CSD_LOCATOR_FILE}
    ${elements}=    create list    sff-sff-data-plane-locator    6000    10.1.1.1
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/br-int-ovs-2/sff-sff-data-plane-locator    ${elements}
    Check For Elements At URI    ${SFF_BOOTSTRAP_URI}/connected-sff-dictionary/br-int-ovs-2    ${elements}

*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${TEST_DIR}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${TEST_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SFF_OVS100_URI}    ${SERVICE_FORWARDER_URI}/ovs-100
    Set Suite Variable    ${SFF_BOOTSTRAP_URI}    ${SERVICE_FORWARDER_URI}/SFF-bootstrap
    Set Suite Variable    ${SF_DICT_SF1_URI}    service-function-dictionary/SF1
    Set Suite Variable    ${SFF_OVS100_FILE}    ${TEST_DIR}/sff_ovs_100.json
    Set Suite Variable    ${SFF_DPL101_FILE}    ${TEST_DIR}/sff_dpl_101.json
    Set Suite Variable    ${SFF_DPL_LOCATOR_FILE}    ${TEST_DIR}/sff_dpl_locator.json
    Set Suite Variable    ${SFF_SFD_SF100_FILE}    ${TEST_DIR}/sff_sfd_sf100.json
    Set Suite Variable    ${SFF_SFD_LOCATOR_FILE}    ${TEST_DIR}/sff_sfd_locator.json
    Set Suite Variable    ${SFF_CSD_SFF100_FILE}    ${TEST_DIR}/sff_csd_sff100.json
    Set Suite Variable    ${SFF_CSD_LOCATOR_FILE}    ${TEST_DIR}/sff_csd_locator.json
