*** Settings ***
Documentation     Test suite to verify odltools
Resource           ODLTools

*** Test Cases ***
Verify Installation
    [Documentation]    Verify odltools has been installed by calling the version cli
    ${output} =    ODLTools.Version
    BuiltIn.Should_Contain    ${output}    (version

Verify Get EOS
    [Documentation]    Verify the show eos cli
    ${output} =    ODLTools.Get EOS
    BuiltIn.Should_Contain    ${output}    python -m odltools

Verify Get Cluster Info
    [Documentation]    Verify the show cluster-info cli
    ${output} =    ODLTools.Get Cluster Info
    BuiltIn.Should_Contain    ${output}    python -m odltools
