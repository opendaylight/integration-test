*** Settings ***
Documentation     Verification that expanding branches in module detail operational tab results in displaying subordinate branches.
...               Verification that collapsing branches in module detail operational tab results in hiding subordinate branches.
...               Verification that expanding branches in module detail config tab results in displaying subordinate branches.
...               Verification that collapsing branches in module detail config tab results in hiding subordinate branches.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Verify that expanding branches in module detail operational tab results in displaying subordinate branches
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULES_WERE_LOADED_ALERT}
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Operational Tab    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    YangmanKeywords.Expand All Branches In Module Detail Content Active Tab

Verify that collapsing branches in module detail operational tab results in hiding subordinate branches
    YangmanKeywords.Collapse All Branches In Module Detail Content Active Tab

Verify that expanding branches in module detail config tab results in displaying subordinate branches
    YangmanKeywords.Select Module Detail Config Tab
    YangmanKeywords.Expand All Branches In Module Detail Content Active Tab

Verify that collapsing branches in module detail config tab results in hiding subordinate branches
    YangmanKeywords.Collapse All Branches In Module Detail Content Active Tab

*** Keywords ***
