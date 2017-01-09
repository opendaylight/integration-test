*** Settings ***
Documentation     Verification that DLUX cotains Yangman submenu when logged in.
...               Verification that when Yangman submenu entered, there are certain elements displayed.
...               Verification that the selected operation is displayed and relevant code mirror(s) is/are displayed.
Suite Teardown    Close Browser
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Open dlux and login and verify yangman submenu has been loaded
    GUIKeywords.Launch Or Open DLUX Page And Login DLUX

Verify yangman submenu elements
    YangmanKeywords.Verify Yangman Home Page Elements
    Verify Operations Presence In Operation Select Menu
    YangmanKeywords.Close Select Box

Verify operation selection and code mirror displaying works correctly
    Select Each Operation And Verify That Code Mirrors Has Been Displayed Correctly

Verify that selecting/deselecting show data checkboxes in json view results in displaying/hiding the corresponding code mirror
    Verify Displaying And Hiding Of CMs When Selecting Show Data Checkboxes

*** Keywords ***
Verify Operations Presence In Operation Select Menu
    YangmanKeywords.Expand Operation Select Menu
    Selenium2Library.Wait Until Page Contains Element    ${Get_Option}
    Selenium2Library.Wait Until Page Contains Element    ${Put_Option}
    Selenium2Library.Wait Until Page Contains Element    ${Post_Option}
    Selenium2Library.Wait Until Page Contains Element    ${Delete_Option}

Select Each Operation And Verify That Code Mirrors Has Been Displayed Correctly
    ${operation_ids}=    YangmanKeywords.Return List Of Operation IDs
    ${operation_names}=    YangmanKeywords.Return List Of Operation Names
    : FOR    ${i}    IN RANGE    0    len(${operation_ids})
    \    ${operation_id}=    Collections.Get From List    ${operation_ids}    ${i}
    \    ${operation_name}=    Collections.Get From List    ${operation_names}    ${i}
    \    YangmanKeywords.Expand Operation Select Menu
    \    Select Operation    ${operation_id}
    \    Verify Selected Operation Is Displayed    ${operation_name}
    \    Run Keyword If    "${operation_name}"=="${Put_Operation_Name}" or "${operation_name}"=="${Post_Operation_Name}"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    Run Keyword If    "${operation_name}"=="${Get_Operation_Name}" or "${operation_name}"=="${Delete_Operation_Name}"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed

Verify Displaying And Hiding Of CMs When Selecting Show Data Checkboxes
    Select Json View
    Choose Operation    ${Get_Option}
    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    YangmanKeywords.Verify Received Data CM Is Displayed
    Selenium2Library.Click Element    ${Show_Sent_Data_Checkbox_Unselected}
    YangmanKeywords.Verify Sent Data CM Is Displayed
    YangmanKeywords.Verify Received Data CM Is Displayed
    Selenium2Library.Click Element    ${Show_Received_Data_Checkbox_Selected}
    YangmanKeywords.Verify Sent Data CM Is Displayed
    YangmanKeywords.Verify Received Data CM Is Not Displayed
    Selenium2Library.Click Element    ${Show_Sent_Data_Checkbox_Selected}
    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    YangmanKeywords.Verify Received Data CM Is Not Displayed
