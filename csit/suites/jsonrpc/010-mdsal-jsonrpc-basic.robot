*** Settings ***
Documentation     Test suite for verifying basic variations of export API including checking statuses
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           DateTime
Resource          ../../libraries/JsonrpcKeywords.robot
Resource          ../../libraries/KarafKeywords.robot

*** Test Cases ***
Push MDSAL data and Verify Through Restconf
    [Documentation]    Push data using python utility and verify using restconf
    [Tags]    Basic data
    KarafKeywords.Setup_Karaf_Keywords
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.jsonrpc
    JsonrpcKeywords.Mount Read Service Endpoint
    JsonrpcKeywords.Run Read Service Python Script on Controller Vm
    JsonrpcKeywords.Verify Data On Mounted Endpoint
