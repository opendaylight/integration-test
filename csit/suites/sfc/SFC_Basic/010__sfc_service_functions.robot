*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
Resource          SFC_Basic.robot

*** Test Cases ***
Add Service Functions
    [Documentation]    Add Service Functions from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    ${jsonbody}    To Json    ${body}
    ${functions}    Get From Dictionary    ${jsonbody}    service-functions
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${function}    Get From Dictionary    ${result}    service-functions
    Lists Should be Equal    ${function}    ${functions}

Delete All Service Functions
    [Documentation]    Delete all Service Functions
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function
    [Documentation]    Get one Service Function
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${elements}=    Create List    dpi-102-1    dpi
    Check For Elements At URI    ${SERVICE_FUNCTIONS_URI}service-function/dpi-102-1    ${elements}

Get A Non-existing Service Function
    [Documentation]    Get A Non-existing Service Function
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}service-function/non-existing-sf
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function
    [Documentation]    Delete A Service Function
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}service-function/dpi-102-1
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    dpi-102-1

Delete A Non-existing Empty Service Function
    [Documentation]    Delete A Non existing Service Function
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    ${jsonbody}    To Json    ${body}
    ${functions}    Get From Dictionary    ${jsonbody}    service-functions
    ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_FUNCTIONS_URI}service-function/non-existing-sf
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${function}    Get From Dictionary    ${result}    service-functions
    Lists Should be Equal    ${function}    ${functions}

Put one Service Function
    [Documentation]    Put one Service Function
    Add Elements To URI From File    ${SF_DPI102100_URI}    ${SF_DPI102100_FILE}
    ${elements}=    Create List    dpi-102-100    dpi
    Check For Elements At URI    ${SF_DPI102100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_FUNCTIONS_URI}    ${elements}

Get Service Function DPL
    [Documentation]    Get Service Function Data Plane Locator
    Add Elements To URI From File    ${SF_DPI102100_URI}    ${SF_DPI102100_FILE}
    ${elements}=    Create List    100    10100
    Check For Elements At URI    ${SF_DPI102100_URI}sf-data-plane-locator/dpl-100    ${elements}

Put Service Function DPL
    [Documentation]    Put Service Function Data Plane Locator
    Add Elements To URI From File    ${SF_DPI102100_URI}    ${SF_DPI102100_FILE}
    Add Elements To URI From File    ${SF_DPI102100_URI}sf-data-plane-locator/dpl-101    ${SF_DPL101_FILE}
    ${elements}=    Create List    dpl-101    10101
    Check For Elements At URI    ${SF_DPI102100_URI}sf-data-plane-locator/dpl-101    ${elements}
    Check For Elements At URI    ${SF_DPI102100_URI}    ${elements}

Put Service Function DPL to a Non-existing Service Function
    [Documentation]    Put Service Function DPL to a Non-existing Service Function
    [Tags]    exclude
    Add Elements To URI From File    ${SF_DPI102100_URI}sf-data-plane-locator/dpl-101    ${SF_DPL101_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    dpi-102-100
    ${elements}=    Create List    dpl-101    10101
    Check For Elements At URI    ${SF_DPI102100_URI}sf-data-plane-locator/dpl-101    ${elements}
    Check For Elements At URI    ${SF_DPI102100_URI}    ${elements}

Delete Service Function DPL
    [Documentation]    Delete Service Function Data Plane Locator
    Add Elements To URI From File    ${SF_DPI102100_URI}    ${SF_DPI102100_FILE}
    Remove All Elements At URI    ${SF_DPI102100_URI}sf-data-plane-locator/dpl-100
    ${resp}    RequestsLibrary.Get Request    session    ${SF_DPI102100_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    dpl-100

*** Keywords ***
Init Suite
    SFC_Basic.Init    010__sfc_service_functions
