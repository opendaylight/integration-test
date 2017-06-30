*** Settings ***
Documentation     Verification that when History tab is loaded, there are certain elements displayed.
...               Verification that when history settings button is clicked then dialog content with certain elements is displayed.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Navigate to history tab and verify history tab elements presence
    YangmanKeywords.Navigate To History Tab
    Verify History Tab Elements Presence

Verify history settings dialog content elements
    Click History Settings Button And Verify Elements Presence In Settings Dialog

*** Keywords ***
Verify History Tab Elements Presence
    Selenium2Library.Wait Until Page Contains Element    ${HISTORY_SEARCH_INPUT}
    Selenium2Library.Page Should Contain Element    ${SAVE_HISTORY_REQUEST_TO_COLLECTION_BUTTON}
    Selenium2Library.Page Should Contain Element    ${DELETE_HISTORY_REQUEST_MENU_BUTTON}
    Selenium2Library.Page Should Contain Element    ${SELECT_HISTORY_REQUEST_MENU}
    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SETTINGS_BUTTON}

Click History Settings Button And Verify Elements Presence In Settings Dialog
    GUIKeywords.Patient Click    ${HISTORY_REQUESTS_SETTINGS_BUTTON}    ${HISTORY_REQUESTS_SETTINGS_DIALOG}
    Selenium2Library.Wait Until Page Contains Element    ${HISTORY_REQUESTS_BUFFER_SIZE_INPUT}
    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SAVE_BASE_RESPONSE_DATA_CHECKBOX}
    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SAVE_RECEIVED_DATA_CHECKBOX}
    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX}
    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SETTINGS_CANCEL_BUTTON}
    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SETTINGS_SAVE_BUTTON}
