*** Settings ***
Documentation     Library containing Keywords used for SXP testing
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ./Sxp.py
Resource          ./SxpLib.robot

*** Variables ***
${REST_CONTEXT}    /restconf/operations/sxp-config-controller

*** Keywords ***
Clean Binding Origins
    [Documentation]    Remove CLUSTER binding origin and set default priorities to default origins
    BuiltIn.Run Keyword And Ignore Error    SxpBindingOriginsLib.Delete Binding Origin    CLUSTER
    BuiltIn.Run Keyword And Ignore Error    SxpBindingOriginsLib.Update Binding Origin    LOCAL    1
    BuiltIn.Run Keyword And Ignore Error    SxpBindingOriginsLib.Update Binding Origin    NETWORK    2

Get Binding Origins
    [Arguments]    ${session}=session
    [Documentation]    Gets all binding origins via RPC from configuration
    ${resp}    RequestsLibrary.Get Request    ${session}    /restconf/config/sxp-config:binding-origins
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp}

Add Binding Origin
    [Arguments]    ${origin}    ${priority}    ${session}=session
    [Documentation]    Add custom binding origin to configuration
    ${DATA}    Sxp.Add Binding Origin Xml    ${origin}    ${priority}
    SxpLib.Post To Controller    ${session}    add-binding-origin    ${DATA}    ${REST_CONTEXT}

Update Binding Origin
    [Arguments]    ${origin}    ${priority}    ${session}=session
    [Documentation]    Update binding origin in configuration
    ${DATA}    Sxp.Update Binding Origin Xml    ${origin}    ${priority}
    SxpLib.Post To Controller    ${session}    update-binding-origin    ${DATA}    ${REST_CONTEXT}

Delete Binding Origin
    [Arguments]    ${origin}    ${session}=session
    [Documentation]    Delete custom binding origin from configuration
    ${DATA}    Sxp.Delete Binding Origin Xml    ${origin}
    SxpLib.Post To Controller    ${session}    delete-binding-origin    ${DATA}    ${REST_CONTEXT}

Should Contain Binding Origins
    [Arguments]    @{origins}
    [Documentation]    Test if data contain specified binding origins
    ${resp}    SxpBindingOriginsLib.Get Binding Origins
    : FOR    ${origin}    IN    @{origins}
    \    ${out}    Sxp.Find Binding Origin    ${resp.json()}    ${origin}
    \    BuiltIn.Should Be True    ${out}    Missing ${origin} in ${resp}

Should Not Contain Binding Origins
    [Arguments]    @{origins}
    [Documentation]    Test if data DONT contain specified binding origins
    ${resp}    SxpBindingOriginsLib.Get Binding Origins
    : FOR    ${origin}    IN    @{origins}
    \    ${out}    Sxp.Find Binding Origin    ${resp.json()}    ${origin}
    \    BuiltIn.Should Be Equal As Strings    False    ${out}    Missing ${origin} in ${resp}

Should Contain Binding Origin With Priority
    [Arguments]    ${origin}    ${priority}
    [Documentation]    Test if data contain specified binding origin with desired priority
    ${resp}    SxpBindingOriginsLib.Get Binding Origins
    ${out}    Sxp.Find Binding Origin With Priority    ${resp.json()}    ${origin}    ${priority}
    BuiltIn.Should Be True    ${out}    Missing ${origin} with ${priority} in ${resp}
