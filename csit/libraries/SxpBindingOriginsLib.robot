*** Settings ***
Documentation       Library containing Keywords used for SXP binding origins testing

Library             ./Sxp.py
Resource            ./SxpLib.robot


*** Variables ***
${CONFIG_REST_CONTEXT}      /rests/operations/sxp-config-controller


*** Keywords ***
Revert To Default Binding Origins Configuration
    [Documentation]    Remove CLUSTER binding origin and set default priorities to default origins
    [Arguments]    ${session}=session
    BuiltIn.Run Keyword And Ignore Error    SxpBindingOriginsLib.Delete Binding Origin    CLUSTER    session=${session}
    BuiltIn.Run Keyword And Ignore Error
    ...    SxpBindingOriginsLib.Update Binding Origin
    ...    LOCAL
    ...    1
    ...    session=${session}
    BuiltIn.Run Keyword And Ignore Error
    ...    SxpBindingOriginsLib.Update Binding Origin
    ...    NETWORK
    ...    2
    ...    session=${session}

Get Binding Origins
    [Documentation]    Gets all binding origins via RPC from configuration
    [Arguments]    ${session}=session
    ${resp} =    RequestsLibrary.Get Request    ${session}    /rests/data/sxp-config:binding-origins?content=config
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    RETURN    ${resp}

Add Binding Origin
    [Documentation]    Add custom binding origin to configuration
    [Arguments]    ${origin}    ${priority}    ${session}=session
    ${data} =    Sxp.Add Binding Origin Xml    ${origin}    ${priority}
    SxpLib.Post To Controller
    ...    ${session}
    ...    path=add-binding-origin
    ...    data=${data}
    ...    rest_context=${CONFIG_REST_CONTEXT}

Update Binding Origin
    [Documentation]    Update binding origin in configuration
    [Arguments]    ${origin}    ${priority}    ${session}=session
    ${data} =    Sxp.Update Binding Origin Xml    ${origin}    ${priority}
    SxpLib.Post To Controller
    ...    ${session}
    ...    path=update-binding-origin
    ...    data=${data}
    ...    rest_context=${CONFIG_REST_CONTEXT}

Delete Binding Origin
    [Documentation]    Delete custom binding origin from configuration
    [Arguments]    ${origin}    ${session}=session
    ${data} =    Sxp.Delete Binding Origin Xml    ${origin}
    SxpLib.Post To Controller
    ...    ${session}
    ...    path=delete-binding-origin
    ...    data=${data}
    ...    rest_context=${CONFIG_REST_CONTEXT}

Should Contain Binding Origins
    [Documentation]    Test if data contain specified binding origins
    [Arguments]    @{origins}
    ${resp} =    SxpBindingOriginsLib.Get Binding Origins
    FOR    ${origin}    IN    @{origins}
        ${out} =    Sxp.Find Binding Origin    ${resp.json()}    ${origin}
        BuiltIn.Should Be True    ${out}    Missing origin: ${origin} in ${resp}
    END

Should Not Contain Binding Origins
    [Documentation]    Test if data DONT contain specified binding origins
    [Arguments]    @{origins}
    ${resp} =    SxpBindingOriginsLib.Get Binding Origins
    FOR    ${origin}    IN    @{origins}
        ${out} =    Sxp.Find Binding Origin    ${resp.json()}    ${origin}
        BuiltIn.Should Be Equal As Strings    False    ${out}    Not expected origin: ${origin} in ${resp}
    END

Should Contain Binding Origin With Priority
    [Documentation]    Test if data contain specified binding origin with desired priority
    [Arguments]    ${origin}    ${priority}
    ${resp} =    SxpBindingOriginsLib.Get Binding Origins
    ${out} =    Sxp.Find Binding Origin With Priority    ${resp.json()}    ${origin}    ${priority}
    BuiltIn.Should Be True    ${out}    Missing origin: ${origin} with priority: ${priority} in ${resp}
