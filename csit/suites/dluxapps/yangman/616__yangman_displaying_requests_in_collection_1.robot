*** Settings ***
Documentation     Verification that PUT requests that were saved from history to collection are present in collections list
...               with correct operation label and API content and status and time values. Verification that unselecting
...               fill form with received data on request select checkbox results in correct displaying of API and form content
...               and status and time values of the requests. Verification that unselecting save base response data checkbox
...               and saving put requests from history to collections results in correct displaying of API and form content
...               and status and time values of the requests. Verification that unselecting save received data checkbox
...               and saving put requests from history to collections results in correct displaying of API and form content
...               and status and time values of the requests.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***
${collection_id_0}    0
${collection_id_1}    1
${collection_id_2}    2

*** Test Cases ***
Delete all history requests and collections and select all checkboxes in history and collections settings
    YangmanKeywords.Delete All History Requests And Collections And Select All Checkboxes In History And Collections Settings

Put t0 and t1 topologies and save requests from history to a new collection and verify requests are present in collectins tab
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}
    BuiltIn.Set Suite Variable    @{keys}
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    2
    YangmanKeywords.Save History Requests With Given Indeces To Collection And Verify Number Of Collections And Number Of Requests In Indexed Collection    0    1    ${COLLECTION_NAME_0}    1

Verify requests in collections tab have correct operation label and API and form and status and time content
    YangmanKeywords.Compare Collection Indexed Request Operation Label And Verify Url Label Contains Given Key    ${collection_id_0}    PUT    ${keys}
    YangmanKeywords.Verify Collections Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data    ${keys}    ${collection_id_0}    0    1

Unselect fill form with received data on request select checkbox and verify API and form content and status and time values
    YangmanKeywords.Open Collections Settings Dialog And Unselect Fill Form View With Received Data On History Request Select Checkbox
    YangmanKeywords.Click Collections Settings Dialog Save Button
    YangmanKeywords.Compare Collection Indexed Request Operation Label And Verify Url Label Contains Given Key    ${collection_id_0}    PUT    ${keys}
    YangmanKeywords.Verify Collections Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${collection_id_0}    0    1

Unselect save base response data checkbox and save requests from history to collections and verify status and time values of new requests are threedots
    YangmanKeywords.Open Collections Settings Dialog And Unselect Save Base Response Data Select Checkbox
    YangmanKeywords.Click Collections Settings Dialog Save Button
    YangmanKeywords.Save History Requests With Given Indeces To Collection And Verify Number Of Collections And Number Of Requests In Indexed Collection    0    1    ${COLLECTION_NAME_1}    2
    YangmanKeywords.Compare Collection Indexed Request Operation Label And Verify Url Label Contains Given Key    ${collection_id_1}    PUT    ${keys}
    YangmanKeywords.Verify Collections Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${collection_id_1}    0    1

Unselect save received data checkbox and save requests from history to collections and verify status and time values of new requests are threedots
    YangmanKeywords.Open Collections Settings Dialog And Unselect Save Received Data Select Checkbox
    YangmanKeywords.Click Collections Settings Dialog Save Button
    YangmanKeywords.Save History Requests With Given Indeces To Collection And Verify Number Of Collections And Number Of Requests In Indexed Collection    0    1    ${COLLECTION_NAME_2}    3
    YangmanKeywords.Compare Collection Indexed Request Operation Label And Verify Url Label Contains Given Key    ${collection_id_2}    PUT    ${keys}
    YangmanKeywords.Verify Collections Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${collection_id_2}    0    1

*** Keywords ***
