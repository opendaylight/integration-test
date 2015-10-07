*** Settings ***
Library           SSHLibrary
Library           Telnet

*** Variables ***

*** Keywords ***
Get Switch Datapath ID
    [Arguments]    ${switch}
    [Documentation]    Using the connection index for the given switch, will execute the command string
    ...    "datapath_id_output_command" which will store the output in switch.datapath_id_output_string.
    ...    The switch object method "update_datapath_id" is called which is assumed to place the ODL
    ...    friendly (decimal) version of the datapath id in to switch.datapath_id and the value is also
    ...    returned from this keyword.
    Configure Connection Index And Prompt Wrapper    ${switch}
    Read Wrapper    ${switch}
    ${switch.datapath_id_output_string}=    Execute Command Wrapper    ${switch}    ${switch.datapath_id_output_command}
    Log    ${switch.datapath_id_output_string}
    Call Method    ${switch}    update_datapath_id
    [Return]    ${switch.datapath_id}

Verify Switch In Operational Data Store
    [Arguments]    ${switch}
    [Documentation]    Verifies the existence of the switch.datapath_id in the operational datastore.
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}
    Log    ${resp.content}
    Should Match Regexp    ${resp.content}    openflow:${switch.datapath_id}

Verify Switch Not In Operational Data Store
    [Arguments]    ${switch}
    [Documentation]    Verifies that the given switch.datapath_id is not in the operational datastore.
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}
    Log    ${resp.content}
    Should Not Match Regexp    ${resp.content}    openflow:${switch.datapath_id}

Iterate Switch Commands From List
    [Arguments]    ${switch}    ${cmd_list}
    [Documentation]    Each string in the @{cmd_list} argument is executed on the switch.connection_index.
    Configure Connection Index And Prompt Wrapper    ${switch}
    : FOR    ${cmd}    IN    @{cmd_list}
    \    Log    ${cmd}
    \    Read Wrapper    ${switch}
    \    Execute Command Wrapper    ${switch}    ${cmd}

Configure OpenFlow
    [Arguments]    ${switch}
    [Documentation]    The commands neccessary to configure openflow on the given switch object should exist in the switch.base_openflow_config attribute. \ Also, the commands/logic to verify that openflow is working are checked in this keyword and come
    ...    from switch.openflow_validation_cmd output where the validation strings are
    ...    stored in switch.openflow_enable_validations
    Log    Applying configs to configure openflow on the given switch.
    Configure Connection Index And Prompt Wrapper    ${switch}
    Iterate Switch Commands From List    ${switch}    ${switch.base_openflow_config}
    Read Wrapper    ${switch}
    Wait Until Keyword Succeeds    10s    1s    Validate Switch Output    ${switch}    ${switch.openflow_validation_cmd}    ${switch.openflow_enable_validations}
    Read Wrapper    ${switch}

Validate Switch Output
    [Arguments]    ${switch}    ${cmd}    ${validations}    ${should_exist}=true
    [Documentation]    A generic keyword that will execute one command on the switch, and check for each string in the @{validations} argument. \ There is a boolean flag ${should_exist} that can be used to check that the validations are or are NOT in the output of the command executed.
    Configure Connection Index And Prompt Wrapper    ${switch}
    Read Wrapper    ${switch}
    ${tmp}=    Execute Command Wrapper    ${switch}    /sbin/ifconfig
    Log    ${tmp}
    ${output}=    Execute Command Wrapper    ${switch}    ${cmd}
    Log    ${output}
    : FOR    ${str}    IN    @{validations}
    \    Run Keyword If    "${should_exist}" == "true"    Should Match Regexp    ${output}    ${str}
    \    Run Keyword If    "${should_exist}" == "false"    Should Not Match Regexp    ${output}    ${str}

Enable OpenFlow
    [Arguments]    ${switch}
    [Documentation]    executes the switch.openflow_enable_config on the given switch and validates that openflow is operational with the switch.openflow_validation_command against all the strings in the switch.openflow_enable_validations list.
    Log    Will toggle openflow to be ON
    Iterate Switch Commands From List    ${switch}    ${switch.openflow_enable_config}
    Read Wrapper    ${switch}
    Wait Until Keyword Succeeds    10s    1s    Validate Switch Output    ${switch}    ${switch.openflow_validation_cmd}    ${switch.openflow_enable_validations}

Disable OpenFlow
    [Arguments]    ${switch}
    [Documentation]    executes the switch.openflow_disable_config on the given switch and validates that openflow is NOT operational with the switch.openflow_validation_command against all the strings in the switch.openflow_disable_validations list.
    Log    Will toggle openflow to be OFF
    Iterate Switch Commands From List    ${switch}    ${switch.openflow_disable_config}
    Read Wrapper    ${switch}
    Wait Until Keyword Succeeds    10s    1s    Validate Switch Output    ${switch}    ${switch.openflow_validation_cmd}    ${switch.openflow_disable_validations}

Open Connection Wrapper
    [Arguments]    ${switch}
    [Documentation]    Some switches require telnet access and others require ssh access. \ Based on the
    ...    switch.mgmt_protocol, the connection open will be handled by the right robot
    ...    library (Telnet or SSHLibrary). \ The connection_index is returned.
    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    Call Method    ${switch}    set_ssh_key    ${USER_HOME}/.ssh/${SSH_KEY}
    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    Call Method    ${switch}    set_mgmt_user    ${MININET_USER}
    ${connection_index}=    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    SSHLibrary.Open Connection    ${switch.mgmt_ip}    prompt=${switch.mgmt_prompt}    timeout=30s
    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    Login With Public Key    ${switch.mgmt_user}    ${switch.ssh_key}    any
    ${connection_index}=    Run Keyword If    "${switch.mgmt_protocol}" == "telnet"    Telnet.Open Connection    ${switch.mgmt_ip}    ELSE    Set Variable
    ...    ${connection_index}
    [Return]    ${connection_index}

Configure Connection Index And Prompt Wrapper
    [Arguments]    ${switch}
    [Documentation]    when using multiple switch connections (e.g. more than one switch device) this keyword will switch the current connection index and prompt so that the following
    ...    Read or Write actions happen on the correct device.
    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    SSHLibrary.Switch Connection    ${switch.connection_index}
    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    SSHLibrary.Set Client Configuration    prompt=${switch.mgmt_prompt}    timeout=5s
    Run Keyword If    "${switch.mgmt_protocol}" == "telnet"    Telnet.Switch Connection    ${switch.connection_index}
    Run Keyword If    "${switch.mgmt_protocol}" == "telnet"    Telnet.Set Prompt    ${switch.mgmt_prompt}    True

Read Wrapper
    [Arguments]    ${switch}
    [Documentation]    Wraps the Read command so that depending on the switch.mgmt_protocol the right
    ...    library (Telnet or SSHLibrary) is used.
    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    SSHLibrary.Read
    Run Keyword If    "${switch.mgmt_protocol}" == "telnet"    Telnet.Read

Write Bare Wrapper
    [Arguments]    ${switch}    ${cmd}
    [Documentation]    Wraps the Write Bare command so that depending on the switch.mgmt_protocol the right
    ...    library (Telnet or SSHLibrary) is used.
    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    SSHLibrary.Write Bare    ${cmd}
    Run Keyword If    "${switch.mgmt_protocol}" == "telnet"    Telnet.Write Bare    ${cmd}

Execute Command Wrapper
    [Arguments]    ${switch}    ${cmd}
    [Documentation]    Wraps the Execute Command keyword so that depending on the switch.mgmt_protocol the right
    ...    library (Telnet or SSHLibrary) is used.
    ${output}=    Run Keyword If    "${switch.mgmt_protocol}" == "ssh"    SSHLibrary.Execute Command    ${cmd}
    ${output}=    Run Keyword If    "${switch.mgmt_protocol}" == "telnet"    Telnet.Execute Command    ${cmd}    ELSE    Set Variable
    ...    ${output}
    [Return]    ${output}

Connect To Switch
    [Arguments]    ${switch}
    [Documentation]    Will Open a connection to the switch, which will set the switch.connection_index.
    ...    For each switch.connection_configs string, a write bare will be executed on the
    ...    switch connection. \ The write bare is done becuase some switch consoles require
    ...    extra input (CR/LF, etc.) that are needed. \ The connection_configs strings should
    ...    be sufficient to put the switch console in to a usuable state so that further
    ...    interactions with the switch can be used with the robot keyword "Execute
    ...    Command"
    ${connection_index}=    Open Connection Wrapper    ${switch}
    Call Method    ${switch}    set_connection_index    ${connection_index}
    Configure Connection Index And Prompt Wrapper    ${switch}
    : FOR    ${cmd}    IN    @{switch.connection_configs}
    \    Write Bare Wrapper    ${switch}    ${cmd}
    \    Sleep    1
    \    Read Wrapper    ${switch}

Cleanup Switch
    [Arguments]    ${switch}
    [Documentation]    will execute and command strings stored in switch.cleanup_cmds
    Iterate Switch Commands From List    ${switch}    ${switch.cleanup_cmds}

Initialize Switch
    [Arguments]    ${switch}
    [Documentation]    Will connect and execute all switch.initialization_cmds on the given switch.
    ...    In some cases, this may be a reboot. \ If so, the switch.initialization_type can
    ...    be set to "reboot" and further logic is invoked to wait for the reboot to complete
    ...    and a reconnect to the switch is made.
    Connect To Switch    ${switch}
    Configure Connection Index And Prompt Wrapper    ${switch}
    : FOR    ${cmd}    IN    @{switch.initialization_cmds}
    \    Write Bare Wrapper    ${switch}    ${cmd}
    \    Sleep    1
    \    Run Keyword And Ignore Error    Read Wrapper    ${switch}
    Run Keyword If    "${switch.initialization_type}" == "reboot"    Wait For Switch Reboot    ${switch}
    Run Keyword If    "${switch.initialization_type}" == "reboot"    Connect To Switch    ${switch}

Wait For Switch Reboot
    [Arguments]    ${switch}
    [Documentation]    If a switch has been set to reboot, it may take some time. \ This keyword will first
    ...    make sure the switch has gone down (10 pings over 10 seconds should not see
    ...    a 100% success, although it may respond for a short time after the reload is
    ...    issued). \ Then a poll is done with a single ping request every 5s until a success
    ...    is found, at which point it is assumed the switch is up and ready.
    ${output}=    Run    ping ${switch.mgmt_ip} -c 10 -W 1
    Should Not Contain    ${output}    10 packets transmitted, 10 received, 0% packet loss    Does not appear that switch has rebooted
    Wait Until Keyword Succeeds    240s    5s    Ping    ${switch.mgmt_ip}

Ping
    [Arguments]    ${ip}
    ${output}=    Run    ping ${ip} -c 1 -W 1
    Should Contain    ${output}    1 packets transmitted, 1 received
