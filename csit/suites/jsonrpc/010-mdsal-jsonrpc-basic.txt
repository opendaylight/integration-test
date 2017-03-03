*** Settings ***
Documentation     Test suite for verifying basic variations of export API including checking statuses
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           DateTime
Resource          ../../libraries/JsonrpcKeywords.robot

*** Test Cases ***
Push MDSAL data and Verify Through Restconf
    [Documentation]    Push data using python utility and verify using restconf
    [Tags]    Basic data
    JsonrpcKeywords.Run Read Service Python Script on Controller Vm
    JsonrpcKeywords.Mount Read Service Endpoint
    JsonrpcKeywords.Verify Data On Mounted Endpoint
