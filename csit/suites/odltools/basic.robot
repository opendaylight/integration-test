*** Settings ***
Documentation       Test suite to verify odltools

Resource            ../../libraries/ODLTools.robot


*** Test Cases ***
Verify Installation
    [Documentation]    Verify odltools has been installed by calling the version cli
    ${output} =    ODLTools.Version
    BuiltIn.Should_Contain    ${output}    (version

Verify Get EOS
    [Documentation]    Verify the show eos cli
    ${output} =    ODLTools.Get EOS
    BuiltIn.Should_Contain    ${output}    Entity Ownership Service

Verify Get Cluster Info
    [Documentation]    Verify the show cluster-info cli
    ${output} =    ODLTools.Get Cluster Info
