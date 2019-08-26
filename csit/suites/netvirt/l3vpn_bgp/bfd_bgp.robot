*** Settings ***
Documentation     Test Case to configure and validate default bfd configuration
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${BFD_CONFIG_ADD_CMD}    bfd-config add
${BFD_CONFIG_REMOVE_CMD}    bfd-config del
${BFD_CACHE_CMD}    bfd-cache
${BFD_TX}         6000
${BFD_RX}         500
${BFD_STATE}      yes
${BFD_MULTIPLIER}    3
${BFD_MULTIHOP}    yes

*** Test Cases ***
Verify BGP_BFD Configuration
    [Documentation]    Validate bfd configuration parameters in ODL
    KarafKeywords.Issue Command On Karaf Console    ${BFD_CONFIG_ADD_CMD}
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${BFD_CACHE_CMD}
    BuiltIn.Should Match Regexp    ${output}    .*${BFD_STATE}\\s+.*${BFD_RX}\\s+.*${BFD_TX}\\s+.*${BFD_MULTIPLIER}\\s+.*${BFD_MULTIHOP}
    KarafKeywords.Issue Command On Karaf Console    ${BFD_CONFIG_REMOVE_CMD}

*** Keywords ***
Suite Setup
    [Documentation]    Setup start suite
    VpnOperations.Basic Suite Setup