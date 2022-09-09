*** Variables ***
${USE_RFC8040} =    False


*** Keywords ***
Generate URI
    [Documentation]    Returns the proper URI to use depending on if RFC8040 is to be used or not. Variable input
    ...    error checking is done to ensure the ${USE_RFC8040} Flag is one of True or False and the ${datastore_flag} variable
    ...    must be config, operational or rpc. @{node_value_list} is expected to be in the format of node=value. RFC8040 can
    ...    use that as is with '=' delimiter, but older restconf URI will convert the '=' to a '/'
    [Arguments]    ${identifier}    ${datastore_flag}=config    @{node_value_list}
    IF    "${USE_RFC8040}" == "True"
        ${uri} =    Generate RFC8040 URI    ${identifier}    ${datastore_flag}    @{node_value_list}
    ELSE
        ${uri} =    Set Variable    ${None}
    END
    IF    "${USE_RFC8040}" == "True"    RETURN    ${uri}
    IF    "${USE_RFC8040}" != "False"
        Fail    Invalid Value for RFC8040 Flag: ${USE_RFC8040}
    END
    IF    "${datastore_flag}"!="config" and "${datastore_flag}"!="operational" and "${datastore_flag}"!="rpc"
        Fail    Invalid value for datastore: ${datastore_flag}
    END
    IF    "${datastore_flag}"=="config"
        ${uri} =    Set Variable    ${CONFIG_API}/${identifier}
    ELSE IF    "${datastore_flag}"=="operational"
        ${uri} =    Set Variable    ${OPERATIONAL_API}/${identifier}
    ELSE
        ${uri} =    Set Variable    ${OPERATIONS_API}/${identifier}
    END
    ${node_value_path} =    Set Variable    ${EMPTY}
    FOR    ${nv}    IN    @{node_value_list}
        ${nv} =    String.Replace String    ${nv}    =    /
        ${node_value_path} =    Set Variable    ${node_value_path}/${nv}
    END
    RETURN    ${uri}${node_value_path}

Generate RFC8040 URI
    [Arguments]    ${identifier}    ${datastore_flag}=config    @{node_value_list}
    ${node_value_path} =    Set Variable    ${EMPTY}
    FOR    ${nv}    IN    @{node_value_list}
        ${node_value_path} =    Set Variable    ${node_value_path}/${nv}
    END
    IF    "${datastore_flag}" == "config"
        ${uri} =    Set Variable    rests/data/${identifier}${node_value_path}?content=config
    ELSE IF    "${datastore_flag}"=="operational"
        ${uri} =    Set Variable    rests/data/${identifier}${node_value_path}?content=nonconfig
    ELSE
        ${uri} =    Set Variable    rests/operations/${identifier}
    END
    RETURN    ${uri}
