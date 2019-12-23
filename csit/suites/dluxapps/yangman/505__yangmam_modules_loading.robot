*** Settings ***
Documentation     Verification that Yangman Modules tab contains at least 1 module loaded.
...               Verification that each loaded module can be expanded and collapsed.
...               Verification that each module contains operations, or operational, or config list items when it is extended.
...               Verification that when operations or operational or config of in modules list is clicked, the name of the module in module detail is the same as the name of the module in module list.
...               Verification that when operations or operational or config is clicked, module detail tab contains chosen tab in selected mode.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL
Suite Teardown    Close Browser
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Verify that any module has been loaded
    ${number_of_modules}=    YangmanKeywords.Return Number Of Modules Loaded    ${MODULE_LIST_ITEM}
    Set Suite Variable    ${number_of_modules}
    YangmanKeywords.Verify Any Module Is Loaded

Verify that each loaded module can be expanded and collapsed
    Verify Each Loaded Module Is Collapsed
    Expand Each Loaded Module    ${number_of_modules}
    Verify Each Loaded Module Is Expanded
    Collapse Each Expanded Module    ${number_of_modules}
    Verify Each Loaded Module Is Collapsed

Verify that each loaded module contains either operations, or operational and config, when expanded
    Expand Each Loaded Module    ${number_of_modules}
    Verify Each Loaded Module Contains Operational Or Config Or Operations    ${number_of_modules}
    Compare Module Name In Module List And Module Detail    ${number_of_modules}

Verify that when operations or operational and config in modules list is clicked, module detail with chosen tab is displayed
    Click Operations Or Operational And Config Of All Modules And Verify Chosen Tab Is Selected    ${number_of_modules}

*** Keywords ***
Verify Each Loaded Module Is Collapsed
    ${number_of_modules_loaded}=    YangmanKeywords.Return Number Of Modules Loaded    ${MODULE_LIST_ITEM}
    ${number_of_modules_loaded_collapsed}=    YangmanKeywords.Return Number Of Modules Loaded    ${MODULE_LIST_ITEM_COLLAPSED}
    BuiltIn.Should Be Equal    ${number_of_modules_loaded}    ${number_of_modules_loaded_collapsed}

Verify Each Loaded Module Is Expanded
    ${number_of_modules_loaded}=    YangmanKeywords.Return Number Of Modules Loaded    ${MODULE_LIST_ITEM}
    ${number_of_modules_loaded_expanded}=    YangmanKeywords.Return Number Of Modules Loaded    ${MODULE_LIST_ITEM_EXPANDED}
    BuiltIn.Should Be Equal    ${number_of_modules_loaded}    ${number_of_modules_loaded_expanded}

Expand Each Loaded Module
    [Arguments]    ${number_of_modules_loaded}
    FOR    ${index}    IN RANGE    0    ${number_of_modules_loaded}
        ${module_list_item_collapsed_indexed}=    YangmanKeywords.Return Module List Item Collapsed Indexed    ${index}
        ${indexed_module_expander_icon}=    YangmanKeywords.Return Indexed Module Expander Icon    ${index}
        ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${module_list_item_collapsed_indexed}
        BuiltIn.Run Keyword If    "${status}"=="True"    GUIKeywords.Focus And Click Element    ${indexed_module_expander_icon}
        Selenium2Library.Wait Until Page Does Not Contain Element    ${module_list_item_collapsed_indexed}
    END

Collapse Each Expanded Module
    [Arguments]    ${number_of_modules_loaded}
    FOR    ${index}    IN RANGE    0    ${number_of_modules_loaded}
        ${module_list_item_expanded_indexed}=    YangmanKeywords.Return Module List Item Expanded Indexed    ${index}
        ${indexed_module_expander_icon}=    YangmanKeywords.Return Indexed Module Expander Icon    ${index}
        ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${module_list_item_expanded_indexed}
        BuiltIn.Run Keyword If    "${status}"=="True"    Run Keyword    GUIKeywords.Focus And Click Element    ${indexed_module_expander_icon}
        Selenium2Library.Wait Until Page Does Not Contain Element    ${module_list_item_expanded_indexed}
    END

Verify Each Loaded Module Contains Operational Or Config Or Operations
    [Arguments]    ${number_of_modules_loaded}
    FOR    ${index}    IN RANGE    0    ${number_of_modules_loaded}
        ${indexed_module_operations}=    YangmanKeywords.Return Indexed Module Operations Label    ${index}
        ${indexed_module_operational}=    YangmanKeywords.Return Indexed Module Operational Label    ${index}
        ${indexed_module_config}=    YangmanKeywords.Return Indexed Module Config Label    ${index}
        ${contains_operational}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${indexed_module_operational}
        ${contains_operations}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${indexed_module_operations}
        ${contains_config}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${indexed_module_config}
        @{states}=    BuiltIn.Create List    "${contains_operational}"    "${contains_operations}"    "${contains_config}"
        Collections.List Should Contain Value    ${states}    "True"
    END

Compare Module Name In Module List And Module Detail
    [Arguments]    ${number_of_modules_loaded}
    FOR    ${index}    IN RANGE    0    ${number_of_modules_loaded}
        ${indexed_module}=    YangmanKeywords.Return Module List Indexed Module    ${index}
        ${indexed_module_operations}=    YangmanKeywords.Return Indexed Module Operations Label    ${index}
        ${indexed_module_operational}=    YangmanKeywords.Return Indexed Module Operational Label    ${index}
        ${indexed_module_config}=    YangmanKeywords.Return Indexed Module Config Label    ${index}
        ${contains_operational}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_operational}
        ${contains_operations}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_operations}
        ${contains_config}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_config}
        ${module_list_module_name}=    Selenium2Library.Get Text    ${indexed_module}//p
        BuiltIn.Run Keyword If    "${contains_operations}"=="True"    BuiltIn.Run Keywords    GUIKeywords.Focus And Click Element    ${indexed_module_operations}
        ...    AND    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_MODULE_NAME_LABEL}
        ${module_detail_module_name}=    BuiltIn.Run Keyword If    "${contains_operations}"=="True"    Selenium2Library.Get Text    ${MODULE_DETAIL_MODULE_NAME_LABEL}
        BuiltIn.Run Keyword If    "${contains_operations}"=="True"    BuiltIn.Run Keywords    BuiltIn.Should Contain    ${module_detail_module_name}    ${module_list_module_name}
        ...    AND    YangmanKeywords.Toggle Module Detail To Modules Or History Or Collections Tab
        ...    AND    Selenium2Library.Wait Until Element Is Visible    ${indexed_module_operations}
        ${contains_operational}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${indexed_module_operational}
        BuiltIn.Run Keyword If    "${contains_operational}"=="True"    BuiltIn.Run Keywords    GUIKeywords.Focus And Click Element    ${indexed_module_operational}
        ...    AND    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_MODULE_NAME_LABEL}
        ${module_detail_module_name}=    BuiltIn.Run Keyword If    "${contains_operational}"=="True"    Selenium2Library.Get Text    ${MODULE_DETAIL_MODULE_NAME_LABEL}
        BuiltIn.Run Keyword If    "${contains_operational}"=="True"    BuiltIn.Run Keywords    BuiltIn.Should Contain    ${module_detail_module_name}    ${module_list_module_name}
        ...    AND    YangmanKeywords.Toggle Module Detail To Modules Or History Or Collections Tab
        ...    AND    Selenium2Library.Wait Until Element Is Visible    ${indexed_module_operational}
        ${contains_config}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${indexed_module_config}
        BuiltIn.Run Keyword If    "${contains_config}"=="True"    BuiltIn.Run Keywords    GUIKeywords.Focus And Click Element    ${indexed_module_config}
        ...    AND    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_MODULE_NAME_LABEL}
        ${module_detail_module_name}=    BuiltIn.Run Keyword If    "${contains_config}"=="True"    Selenium2Library.Get Text    ${MODULE_DETAIL_MODULE_NAME_LABEL}
        BuiltIn.Run Keyword If    "${contains_config}"=="True"    BuiltIn.Run Keywords    BuiltIn.Should Contain    ${module_detail_module_name}    ${module_list_module_name}
        ...    AND    YangmanKeywords.Toggle Module Detail To Modules Or History Or Collections Tab
        ...    AND    Selenium2Library.Wait Until Element Is Visible    ${indexed_module_config}
    END

Click Operations Or Operational And Config Of All Modules And Verify Chosen Tab Is Selected
    [Arguments]    ${number_of_modules_loaded}
    FOR    ${index}    IN RANGE    0    ${number_of_modules_loaded}
        ${indexed_module_operations}=    YangmanKeywords.Return Indexed Module Operations Label    ${index}
        ${indexed_module_operational}=    YangmanKeywords.Return Indexed Module Operational Label    ${index}
        ${indexed_module_config}=    YangmanKeywords.Return Indexed Module Config Label    ${index}
        ${contains_operational}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_operational}
        ${contains_operations}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_operations}
        ${contains_config}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_config}
        BuiltIn.Run Keyword If    "${contains_operations}"=="True"    Run Keywords    YangmanKeywords.Click Indexed Module Operations To Load Module Detail Operations Tab    ${index}
        ...    AND    YangmanKeywords.Toggle Module Detail To Modules Or History Or Collections Tab
        ...    AND    Selenium2Library.Wait Until Element Is Visible    ${indexed_module_operations}
        BuiltIn.Run Keyword If    "${contains_operational}"=="True"    BuiltIn.Run Keywords    YangmanKeywords.Click Indexed Module Operational To Load Module Detail Operational Tab    ${index}
        ...    AND    YangmanKeywords.Toggle Module Detail To Modules Or History Or Collections Tab
        ...    AND    Selenium2Library.Wait Until Element Is Visible    ${indexed_module_operational}
        BuiltIn.Run Keyword If    "${contains_config}"=="True"    BuiltIn.Run Keywords    YangmanKeywords.Click Indexed Module Config To Load Module Detail Config Tab    ${index}
        ...    AND    YangmanKeywords.Toggle Module Detail To Modules Or History Or Collections Tab
        ...    AND    Selenium2Library.Wait Until Element Is Visible    ${indexed_module_config}
    END
