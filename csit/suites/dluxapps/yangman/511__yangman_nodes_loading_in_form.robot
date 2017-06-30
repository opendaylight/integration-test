*** Settings ***
Documentation     Verification that clicking the branch in operational tab of module detail results in loading nothing in the form.
...               Verification that clicking the branch in config tab of module detail results in loading the corresponding node in the form.
...               Verification that when list node branch is clicked in config tab while form view is selected then the form top element contains yangmenu and node [0] list item.
...               Verification that when list node branch is clicked in config tab while json view is selected, then when switched to form view, the form contains node [0] list item.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***
${0_ID}           0

*** Test Cases ***
Verify that when node branch is clicked in operational tab then the node is not loaded in the form
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Operational Tab    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    YangmanKeywords.Expand All Branches In Module Detail Content Active Tab
    YangmanKeywords.Select Form View
    ${branches_number}=    Selenium2Library.Get Matching Xpath Count    ${MODULE_DETAIL_BRANCH}
    BuiltIn.Set Suite Variable    ${branches_number}
    Click Each Branch In Operational Tab Form View And Verify No Data Were Loaded In The Form    ${branches_number}

Verify that when node branch is clicked in config tab then the node is loaded in the form
    YangmanKeywords.Select Module Detail Config Tab
    YangmanKeywords.Expand All Branches In Module Detail Content Active Tab
    YangmanKeywords.Select Form View
    Click Each Branch In Config Tab Form View And Verify Node Was Loaded In The Form    ${branches_number}

Verify that when list node branch is clicked in config tab form view then the form top element contains yangmenu and node [0] list item
    YangmanKeywords.Select Form View
    Click Each List Branch In Config Tab Form View And Verify Form Top Element Contains List Item With Index [0] And Yangmenu    ${branches_number}

Verify that when list node branch is clicked in config tab json view, and when switched to form view then the yangmenu and node [0] list item are present
    Click Each List Branch In Config Tab Json View And Verify Form Top Element Contains List Item With Index [0] And Yangmenu When Switched To Form View    ${branches_number}

*** Keywords ***
Compose Branch Id And Module Detail Branch Indexed And Verify Module Detail Branch Is List Branch
    [Arguments]    ${index}
    ${module_detail_branch_indexed}=    YangmanKeywords.Compose Branch Id And Return Module Detail Branch Indexed    ${index}
    ${status}=    YangmanKeywords.Verify Module Detail Branch Is List Branch    ${module_detail_branch_indexed}
    [Return]    ${status}

Click Each Branch In Operational Tab Form View And Verify No Data Were Loaded In The Form
    [Arguments]    ${branches_number}
    : FOR    ${index}    IN RANGE    0    ${branches_number}
    \    ${module_detail_branch_indexed}=    YangmanKeywords.Compose Branch Id And Return Module Detail Branch Indexed    ${index}
    \    YangmanKeywords.Click Module Detail Branch Indexed    ${module_detail_branch_indexed}
    \    Selenium2Library.Element Should Not Be Visible    ${FORM_TOP_ELEMENT_POINTER}

Click Each Branch In Config Tab Form View And Verify Node Was Loaded In The Form
    [Arguments]    ${branches_number}
    : FOR    ${index}    IN RANGE    0    ${branches_number}
    \    ${module_detail_branch_indexed}=    YangmanKeywords.Compose Branch Id And Return Module Detail Branch Indexed    ${index}
    \    ${branch_label}=    YangmanKeywords.Return Indexed Branch Label    ${module_detail_branch_indexed}
    \    YangmanKeywords.Click Module Detail Branch Indexed    ${module_detail_branch_indexed}
    \    ${branch_label_without_curly_braces_part}=    YangmanKeywords.Return Branch Label Without Curly Braces Part    ${branch_label}
    \    ${form_top_element_labelled}=    YangmanKeywords.Return Form Top Element Labelled    ${branch_label_without_curly_braces_part}
    \    Selenium2Library.Wait Until Page Contains Element    ${form_top_element_labelled}

Click Each List Branch In Config Tab Form View And Verify Form Top Element Contains List Item With Index [0] And Yangmenu
    [Arguments]    ${branches_number}
    : FOR    ${index}    IN RANGE    0    ${branches_number}
    \    ${status}=    Compose Branch Id And Module Detail Branch Indexed And Verify Module Detail Branch Is List Branch    ${index}
    \    BuiltIn.Continue For Loop If    "${status}"=="False"
    \    ${module_detail_branch_indexed}=    YangmanKeywords.Compose Branch Id And Return Module Detail Branch Indexed    ${index}
    \    ${branch_label}=    YangmanKeywords.Return Indexed Branch Label    ${module_detail_branch_indexed}
    \    YangmanKeywords.Click Module Detail Branch Indexed    ${module_detail_branch_indexed}
    \    YangmanKeywords.Verify List Item With Index Or Key Is Visible    ${branch_label}    ${EMPTY}    ${0_ID}
    \    Selenium2Library.Page Should Contain Element    ${FORM_TOP_ELEMENT_YANGMENU}

Click Each List Branch In Config Tab Json View And Verify Form Top Element Contains List Item With Index [0] And Yangmenu When Switched To Form View
    [Arguments]    ${branches_number}
    : FOR    ${index}    IN RANGE    0    ${branches_number}
    \    ${status}=    Compose Branch Id And Module Detail Branch Indexed And Verify Module Detail Branch Is List Branch    ${index}
    \    BuiltIn.Continue For Loop If    "${status}"=="False"
    \    ${module_detail_branch_indexed}=    YangmanKeywords.Compose Branch Id And Return Module Detail Branch Indexed    ${index}
    \    ${branch_label}=    YangmanKeywords.Return Indexed Branch Label    ${module_detail_branch_indexed}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Click Module Detail Branch Indexed    ${module_detail_branch_indexed}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Verify List Item With Index Or Key Is Visible    ${branch_label}    ${EMPTY}    ${0_ID}
    \    Selenium2Library.Page Should Contain Element    ${FORM_TOP_ELEMENT_YANGMENU}
