*** Keywords ***
Generate URI
    [Documentation]    Returns the proper URI to use. Variable input error checking is done to ensure the ${datastore_flag} variable
    ...    is config, operational or rpc. @{node_value_list} is expected to be in the format of node=value. RFC8040 can
    ...    use that as is with '=' delimiter
    [Arguments]    ${identifier}    ${datastore_flag}=config    @{node_value_list}
    ${uri} =    Generate RFC8040 URI    ${identifier}    ${datastore_flag}    @{node_value_list}
    RETURN    ${uri}

Generate RFC8040 URI
    [Arguments]    ${identifier}    ${datastore_flag}=config    @{node_value_list}
    ${node_value_path} =    Set Variable    ${EMPTY}
    FOR    ${nv}    IN    @{node_value_list}
        ${node_value_path} =    Set Variable    ${node_value_path}/${nv}
    END
    IF    "${datastore_flag}" == "config"
        ${uri} =    Set Variable    ${RESTCONF_ROOT}/data/${identifier}${node_value_path}?content=config
    ELSE IF    "${datastore_flag}"=="operational"
        ${uri} =    Set Variable    ${RESTCONF_ROOT}/data/${identifier}${node_value_path}?content=nonconfig
    ELSE
        ${uri} =    Set Variable    ${RESTCONF_ROOT}/operations/${identifier}
    END
    RETURN    ${uri}
