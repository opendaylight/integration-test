*** Settings ***
Documentation     Test Case to configure and validate default bgp bfd configuration 
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/VpnOperations.robot

*** Variables ***
${BFD_CONFIG_ADD_CMD}    bfd-config add
${BFD_CONFIG_REMOVE_CMD}    bfd-config del
${BFD_CACHE_CMD}    bfd-cache
${BFD_TX}    6000
${BFD_RX}    500
${BFD_STATE}    YES
${BFD_MULTI}    3

*** Test Cases ***
Verify BGP_BFD Configuration 
    [Documentation]    Verify BGP-BFD configuration in ODL 
    ${output} = KarafKeywords.Issue Command On Karaf Console    ${BFD_CACHE_CMD}
    BuiltIn.Should Contain    ${output}    ${BFD_STATE}
    BuiltIn.Should Contain    ${output}    ${BFD_TX}
    BuiltIn.Should Contain    ${output}    ${BFD_RX}
    BuiltIn.Should Contain    ${output}    ${BFD_MULTI}

*** Keywords ***
Create BFD Config On ODL
    [Documentation]    Configure BFD Config on ODL
    KarafKeywords.Issue Command On Karaf Console    ${BFD_CONFIG_SERVER_CMD}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}
Get BGP Configuration On ODL
    [Arguments]    ${odl_session}
    [Documentation]    Get bgp configuration
    ${resp} =    RequestsLibrary.Get Request    ${odl_session}    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.content}
    [Return]    ${resp.content}
Start Suite
    [Documentation]    Test teardown for bgp bfd  suite.
    KarafKeywords.Issue Command On Karaf Console    ${BFD_CONFIG_ADD_CMD}
Stop Suite
    [Documentation]    Test teardown for bgp bfd  suite.
    KarafKeywords.Issue Command On Karaf Console    ${BFD_CONFIG_REMOVE_CMD}
