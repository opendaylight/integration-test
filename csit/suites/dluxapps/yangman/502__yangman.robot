*** Settings ***
Documentation     Verification that DLUX cotains Yangman submenu when logged in.
...               Verification that when Yangman submenu entered, there are certain elements displayed.
...               Verification that the selected operation is displayed and relevant code mirror(s) is/are displayed.
Suite Teardown    Close Browser
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Open dlux and login and verify yangman submenu has been loaded
    GUIKeywords.Open Or Launch DLUX Page And Log In To DLUX

Verify yangman submenu elements
    GUIKeywords.Navigate To URL    ${YANGMAN_SUBMENU_URL}
    YangmanKeywords.Verify Yangman Home Page Elements
    Verify Operations Presence In Operation Select Menu
    YangmanKeywords.Exit Opened Application Dialog

Verify operation selection and code mirror displaying works correctly
    Select Each Operation And Verify That Code Mirrors Has Been Displayed Correctly

Verify that selecting/deselecting show data checkboxes in json view results in displaying/hiding the corresponding code mirror
    Verify Displaying And Hiding Of CMs When Selecting Show Data Checkboxes

*** Keywords ***
Verify Operations Presence In Operation Select Menu
    YangmanKeywords.Expand Operation Select Menu
    Selenium2Library.Wait Until Page Contains Element    ${GET_OPTION}
    Selenium2Library.Wait Until Page Contains Element    ${PUT_OPTION}
    Selenium2Library.Wait Until Page Contains Element    ${POST_OPTION}
    Selenium2Library.Wait Until Page Contains Element    ${DELETE_OPTION}

Select Each Operation And Verify That Code Mirrors Has Been Displayed Correctly
    ${operation_ids}=    YangmanKeywords.Return List Of Operation IDs
    ${operation_names}=    YangmanKeywords.Return List Of Operation Names
    FOR    ${i}    IN RANGE    0    len(${operation_ids})
        ${operation_id}=    Collections.Get From List    ${operation_ids}    ${i}
        ${operation_name}=    Collections.Get From List    ${operation_names}    ${i}
        YangmanKeywords.Expand Operation Select Menu And Select Operation    ${operation_id}    ${operation_name}
        Run Keyword If    "${operation_name}"=="PUT" or "${operation_name}"=="POST"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Displayed
        ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
        Run Keyword If    "${operation_name}"=="GET" or "${operation_name}"=="DELETE"    YangmanKeywords.Verify Received Data CM Is Displayed
    END

Verify Displaying And Hiding Of CMs When Selecting Show Data Checkboxes
    YangmanKeywords.Select Json View
    YangmanKeywords.Expand Operation Select Menu And Select Operation    ${GET_OPTION}    GET
    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    YangmanKeywords.Verify Received Data CM Is Displayed
    GUIKeywords.Patient Click    ${SHOW_SENT_DATA_CHECKBOX_UNSELECTED}    ${SHOW_SENT_DATA_CHECKBOX_SELECTED}
    YangmanKeywords.Verify Sent Data CM Is Displayed
    YangmanKeywords.Verify Received Data CM Is Displayed
    GUIKeywords.Patient Click    ${SHOW_RECEIVED_DATA_CHECKBOX_SELECTED}    ${SHOW_RECEIVED_DATA_CHECKBOX_UNSELECTED}
    YangmanKeywords.Verify Sent Data CM Is Displayed
    YangmanKeywords.Verify Received Data CM Is Not Displayed
    GUIKeywords.Patient Click    ${SHOW_SENT_DATA_CHECKBOX_SELECTED}    ${SHOW_SENT_DATA_CHECKBOX_UNSELECTED}
    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    YangmanKeywords.Verify Received Data CM Is Not Displayed
