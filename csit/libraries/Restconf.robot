*** Settings ***

*** Variables ***
${USE_RFC8040} =    False

*** Keywords ***

Generate URI
    [Arguments]    ${resource}    ${datastore}=config
    [Documentation]    Returns the proper URI to use depending on if RFC8040 is to be used or not. Variable input
    ...    error checking is done to ensure the ${USE_RFC8040} Flag is one of True or False and the ${datastore} variable
    ...    must be config or operational.
    ${uri} =    Run Keyword If    "${USE_RFC8040}" == "True"    Generate RFC8040 URI    "${resource}"    ${datastore}
    Return From Keyword If    "${USE_RFC8040}" == "True"    ${uri}
    Run Keyword If    "${USE_RFC8040}" != "False"    Fail    Invalid Value for RFC8040 Flag: ${USE_RFC8040}
    ${uri} =    Set Variable If    "${datastore}"=="config"    ${CONFIG_API}/${resource}
    ${uri} =    Set Variable If    "${datastore}"=="operational"    ${OPERATIONAL_API}/${resource}
    Run Keyword If    "${datastore}"!="config" and "${datastore}"!="operational"    Fail    Invalid value for datastore: ${datastore}
    [Return]    ${uri}

Generate RFC8040 URI
    [Arguments]    ${resource}    ${datastore}=config
    Log    Noop for now!
