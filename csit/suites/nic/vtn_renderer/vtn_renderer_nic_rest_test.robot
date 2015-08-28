*** Settings ***
Documentation     Test suite for NIC VTN Renderer
Suite Setup       Start NIC VTN Rest Test Suite
Suite Teardown    Stop NIC Vtn Rest Test Suite
Resource          ../../../libraries/NicKeywords.robot

*** Test Cases ***
Add Intent
    [Documentation]    Create a new intent .
    Add Intent Using RestConf    ${INTENT_ID}    { "intent:intent" : { "intent:id": ${INTENT_ID} , "intent:actions" : [ { "order" : 1, "block" : {} } ],"intent:subjects" : [ { "order":1 , "end-point-group" : {name:"10.0.0.1"} }, { "order":2 , "end-point-group" : {name:"10.0.0.2"}} ] } }

Verify Intent
    [Documentation]    Verify the Intent created.
    Verify Intent Using RestConf    ${INTENT_ID}

Update Intent
    [Documentation]    Update the Intent created.
    Update Intent Using RestConf    ${INTENT_ID}    { "intent:intent" : { "intent:id": ${INTENT_ID} , "intent:actions" : [ { "order" : 2, "allow" : {} } ],"intent:subjects" : [ { "order":1 , "end-point-group" : {name:"10.0.0.1"} }, { "order":2 , "end-point-group" : {name:"10.0.0.2"}} ] } }

Verify Ping
    [Documentation]    Ping h1 to h2, to verify no packet loss
    Mininet Ping Should Succeed    h1    h2

Delete Intent
    [Documentation]    Delete the intent created.
    Delete Intent Using RestConf    ${INTENT_ID}
    Mininet Ping Should Not Succeed    h1    h2
