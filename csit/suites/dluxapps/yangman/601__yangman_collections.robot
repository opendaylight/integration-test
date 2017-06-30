*** Settings ***
Documentation     Verification that when Collections tab is loaded, there are certain elements displayed.
...               Verification that when collections settings button is clicked then dialog content with certain elements is displayed.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Navigate to collections tab and verify collections tab elements presence
    YangmanKeywords.Navigate To Collections Tab
    Verify Collections Tab Elements Presence

Verify collections settings dialog content elements
    Click Collections Settings Button And Verify Elements Presence In Settings Dialog

*** Keywords ***
Verify Collections Tab Elements Presence
    Selenium2Library.Wait Until Page Contains Element    ${COLLECTIONS_SEARCH_INPUT}
    Selenium2Library.Page Should Contain Element    ${SORT_COLLECTIONS_BUTTON}
    Selenium2Library.Page Should Contain Element    ${SAVE_SELECTED_REQUEST_TO_COLLECTION_BUTTON}
    Selenium2Library.Page Should Contain Element    ${IMPORT_COLLECTION_BUTTON}
    Selenium2Library.Page Should Contain Element    ${DELETE_COLLECTIONS_MENU_BUTTON}
    Selenium2Library.Page Should Contain Element    ${SELECT_COLLECTIONS_REQUEST_MENU}
    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_BUTTON}

Click Collections Settings Button And Verify Elements Presence In Settings Dialog
    GUIKeywords.Patient Click    ${COLLECTIONS_SETTINGS_BUTTON}    ${COLLECTIONS_SETTINGS_DIALOG}
    Selenium2Library.Wait Until Page Contains Element    ${COLLECTIONS_SETTINGS_SAVE_BASE_RESPONSE_DATA_CHECKBOX}
    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_SAVE_RECEIVED_DATA_CHECKBOX}
    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX}
    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_CANCEL_BUTTON}
    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_SAVE_BUTTON}
