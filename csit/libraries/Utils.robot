*** Settings ***
Documentation       General Utils library. This library has broad scope, it can be used by any robot system tests.

Library             SSHLibrary
Library             String
Library             DateTime
Library             Process
Library             Collections
Library             RequestsLibrary
Library             OperatingSystem
Library             ${CURDIR}/UtilLibrary.py
Resource            ${CURDIR}/SSHKeywords.robot
Resource            ${CURDIR}/TemplatedRequests.robot
Resource            ${CURDIR}/../variables/Variables.robot
Resource            ${CURDIR}/../variables/openflowplugin/Variables.robot


*** Variables ***
# TODO: Introduce ${tree_size} and use instead of 1 in the next line.
${start}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,1 --switch ovsk,protocols=OpenFlow13


*** Keywords ***
Start Mininet
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${TOOLS_SYSTEM_PROMPT}    ${timeout}=30s
    Log    Start the test on the base edition
    Clean Mininet System
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible Mininet Login    user=${user}    password=${password}
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Write    ${start}
    Read Until    mininet>

Stop Mininet
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    [Arguments]    ${prompt}=${TOOLS_SYSTEM_PROMPT}
    Log    Stop the test on the base edition
    Switch Connection    ${mininet_conn_id}
    Read
    Write    exit
    Read Until    ${prompt}
    Close Connection

Report Failure Due To Bug
    [Documentation]    Report that a test failed due to a known Bugzilla bug whose
    ...    number is provided as an argument.
    ...    Not FAILED (incl. SKIPPED) test are not reported.
    ...    This keyword must be used in the [Teardown] setting of the affected test
    ...    or as the first line of the test if FastFail module is not being
    ...    used. It reports the URL of the bug on console and also puts it
    ...    into the Robot log file.
    [Arguments]    ${number}    ${include_bug_in_tags}=True
    ${test_skipped}=    BuiltIn.Evaluate    len(re.findall('SKIPPED', """${TEST_MESSAGE}""")) > 0    modules=re
    IF    ('${TEST_STATUS}' != 'FAIL') or ${test_skipped}    RETURN
    Comment    Jira tickets are {PROJECT}-{NUMBER} while Bugzilla tickets are {NUMBER}
    ${match}=    BuiltIn.Run Keyword And Return Status    Should Contain    ${number}    -
    ${bug_url}=    BuiltIn.Set Variable If
    ...    ${match}
    ...    https://jira.opendaylight.org/browse/${number}
    ...    https://bugs.opendaylight.org/show_bug.cgi?id=${number}
    ${msg}=    BuiltIn.Set_Variable    This test fails due to ${bug_url}
    ${newline}=    BuiltIn.Evaluate    chr(10)
    BuiltIn.Set Test Message    ${msg}${newline}${newline}${TEST_MESSAGE}
    BuiltIn.Log    ${msg}
    IF    "${include_bug_in_tags}"=="True"    Set Tags    ${bug_url}

Report_Failure_And_Point_To_Linked_Bugs
    [Documentation]    Report that a test failed and point to linked Bugzilla bug(s).
    ...    Linked bugs must contain the ${reference} inside comments (workaround
    ...    becasue of currently missing suitable field for external references and
    ...    not correctly working the CONTENT MATCHES filter).
    ...    Not FAILED (incl. SKIPPED) test are not reported.
    ...    This keyword must be used in the [Teardown] setting of the affected test
    ...    or as the first line of the test if FastFail module is not being
    ...    used. It reports the URL of the bug on console and also puts it
    ...    into the Robot log file.
    ${test_skipped}=    BuiltIn.Evaluate    len(re.findall('SKIPPED', """${TEST_MESSAGE}""")) > 0    modules=re
    IF    ('${TEST_STATUS}' != 'FAIL') or ${test_skipped}    RETURN
    ${newline}=    BuiltIn.Evaluate    chr(10)
    ${reference}=    String.Replace_String_Using_Regexp    ${SUITE_NAME}_${TEST_NAME}    [ /\.-]    _
    ${reference}=    String.Convert_To_Lowercase    ${reference}
    ${msg}=    BuiltIn.Set_Variable
    ...    ... click for list of related bugs or create a new one if needed (with the${newline}"${reference}"${newline}reference somewhere inside)
    ${bugs}=    BuiltIn.Set_Variable
    ...    "https://bugs.opendaylight.org/buglist.cgi?f1=cf_external_ref&o1=substring&v1=${reference}&order=bug_status"
    BuiltIn.Set Test Message    ${msg}${newline}${bugs}${newline}${newline}${TEST_MESSAGE}
    BuiltIn.Log    ${msg}${newline}${bugs}

Check Nodes Stats
    [Documentation]    A GET on the /node/${node} API is made and specific flow stat
    ...    strings are checked for existence.
    [Arguments]    ${node}    ${session}=session
    ${resp}=    RequestsLibrary.Get On Session
    ...    ${session}
    ...    url=${RFC8040_NODES_API}/node=${node}
    ...    params=${RFC8040_OPERATIONAL_CONTENT}
    ...    expected_status=200
    Should Contain    ${resp.text}    flow-capable-node-connector-statistics
    Should Contain    ${resp.text}    flow-table-statistics

Check For Specific Number Of Elements At URI
    [Documentation]    A GET is made to the specified ${URI} and the specific count of a
    ...    given element is done (as supplied by ${element} and ${expected_count})
    [Arguments]    ${uri}    ${element}    ${expected_count}    ${session}=session
    ${resp}=    RequestsLibrary.Get On Session    ${session}    url=${uri}    expected_status=anything
    Log    ${resp.text}
    RequestsLibrary.Status Should Be    200    ${resp}
    Should Contain X Times    ${resp.text}    ${element}    ${expected_count}

Log Content
    [Arguments]    ${resp_content}
    IF    '''${resp_content}''' != '${EMPTY}'
        ${resp_json}=    BuiltIn.Evaluate
        ...    json.dumps(json.loads('''${resp_content}'''), sort_keys=True, indent=4, separators=(',', ': '))
        ...    modules=json
    ELSE
        ${resp_json}=    BuiltIn.Set Variable    ${EMPTY}
    END
    BuiltIn.Log    ${resp_json}
    RETURN    ${resp_json}

Check For Elements At URI
    [Documentation]    A GET is made at the supplied ${URI} and every item in the list of
    ...    ${elements} is verified to exist in the response
    [Arguments]    ${uri}    ${elements}    ${session}=session    ${pretty_print_json}=False
    ${resp}=    RequestsLibrary.Get On Session    ${session}    url=${uri}    expected_status=anything
    IF    "${pretty_print_json}" == "True"
        Log Content    ${resp.text}
    ELSE
        BuiltIn.Log    ${resp.text}
    END
    RequestsLibrary.Status Should Be    200    ${resp}
    FOR    ${i}    IN    @{elements}
        Should Contain    ${resp.text}    ${i}
    END

Check For Elements Not At URI
    [Documentation]    A GET is made at the supplied ${uri} and every item in the list of
    ...    ${elements} is verified to NOT exist in the response. If ${check_for_null} is True
    ...    return of 404 is treated as empty list. From Neon onwards, an empty list is always
    ...    returned as null, giving 404 on rest call.
    [Arguments]    ${uri}    ${elements}    ${session}=session    ${pretty_print_json}=False    ${check_for_null}=False
    ${resp}=    RequestsLibrary.Get On Session    ${session}    url=${uri}    expected_status=anything
    IF    "${pretty_print_json}" == "True"
        Log Content    ${resp.text}
    ELSE
        BuiltIn.Log    ${resp.text}
    END
    IF    "${check_for_null}" == "True"
        IF    ${resp.status_code} == 404 or ${resp.status_code} == 409    RETURN
    END
    RequestsLibrary.Status Should Be    200    ${resp}
    FOR    ${i}    IN    @{elements}
        Should Not Contain    ${resp.text}    ${i}
    END

Clean Mininet System
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}
    Run Command On Mininet    ${system}    sudo mn -c
    Run Command On Mininet
    ...    ${system}
    ...    sudo ps -elf | egrep 'usr/local/bin/mn' | egrep python | awk '{print "sudo kill -9",$4}' | sh

Clean Up Ovs
    [Documentation]    Cleans up the OVS instance and remove any existing common known bridges.
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}
    ${output}=    Run Command On Mininet    ${system}    sudo ovs-vsctl list-br
    Log    ${output}
    FOR    ${i}    IN    ${output}
        Run Command On Mininet    ${system}    sudo ovs-vsctl --if-exists del-br ${i}
    END
    Run Command On Mininet    ${system}    sudo ovs-vsctl del-manager

Extract Value From Content
    [Documentation]    Will take the given response content and return the value at the given index as a string
    [Arguments]    ${content}    ${index}
    ${JSON}=    BuiltIn.Evaluate    json.loads('''${content}''')    modules=json
    ${value}=    Set Variable    ${JSON${index}}
    RETURN    ${value}

Get Process ID Based On Regex On Remote System
    [Documentation]    Uses ps to find a process that matches the supplied regex. Returns the PID of that process
    ...    The ${regex_string_to_match_on} should produce a unique process otherwise the PID returned may not be
    ...    the expected PID
    [Arguments]    ${system}    ${regex_string_to_match_on}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    # doing the extra -v grep in this command to exclude the grep process itself from the output
    ${cmd}=    Set Variable    ps -elf | grep -v grep | grep ${regex_string_to_match_on} | awk '{print $4}'
    ${output}=    Run Command On Remote System
    ...    ${system}
    ...    ${cmd}
    ...    user=${user}
    ...    password=${password}
    ...    prompt=${prompt}
    ...    prompt_timeout=${prompt_timeout}
    # ${output} contains the system prompt and all we want is the value of the number
    ${pid}=    Fetch From Left    ${output}    \r
    RETURN    ${pid}

    # ...    Should there be * On Mininet and * On Controller specializations?
    # TODO: Get Process * keywords have perhaps non-standard default credentials.

Get Process Thread Count On Remote System
    [Documentation]    Executes the ps command to retrieve the lightweight process (aka thread) count.
    [Arguments]    ${system}    ${pid}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    ${cmd}=    Set Variable    ps --no-headers -o nlwp ${pid}
    ${output}=    Run Command On Remote System
    ...    ${system}
    ...    ${cmd}
    ...    user=${user}
    ...    password=${password}
    ...    prompt=${prompt}
    ...    prompt_timeout=${prompt_timeout}
    # ${output} contains the system prompt and all we want is the value of the number
    ${thread_count}=    Fetch From Left    ${output}    \r
    RETURN    ${thread_count}

Strip Quotes
    [Documentation]    Will strip ALL quotes from given string and return the new string
    [Arguments]    ${string_to_strip}
    ${string_to_return}=    Replace String    ${string_to_strip}    "    \    count=-1
    RETURN    ${string_to_return}

Run Command On Remote System
    [Documentation]    Reduces the common work of running a command on a remote system to a single higher level
    ...    robot keyword, taking care to log in with a public key and. The command given is written and the return value
    ...    depends on the passed argument values of return_stdout (default: True) and return_stderr (default: False).
    ...    At least one should be True, or the keyword will exit and FAIL. If both are True, the resulting return value
    ...    will be a two element list containing both. Otherwise the resulting return value is a string.
    ...    No test conditions are checked.
    [Arguments]    ${system}    ${cmd}    ${user}=${DEFAULT_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    ...    ${return_stdout}=True    ${return_stderr}=False
    IF    "${return_stdout}"!="True" and "${return_stderr}"!="True"
        Fail    At least one of {return_stdout} or {return_stderr} args should be set to True
    END
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    BuiltIn.Log
    ...    Attempting to execute command "${cmd}" on remote system "${system}" by user "${user}" with keyfile pass "${keyfile_pass}" and prompt "${prompt}" and password "${password}"
    ${conn_id}=    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    SSHKeywords.Flexible SSH Login    ${user}    ${password}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    ${cmd}    return_stderr=True
    SSHLibrary.Close Connection
    Log    ${stderr}
    IF    "${return_stdout}"!="True"    RETURN    ${stderr}
    IF    "${return_stderr}"!="True"    RETURN    ${stdout}
    RETURN    ${stdout}    ${stderr}
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_ssh_connection.index}

Run Command On Remote System And Log
    [Documentation]    Reduces the common work of running a command on a remote system to a single higher level
    ...    robot keyword, taking care to log in with a public key and. The command given is written
    ...    and the output returned. No test conditions are checked.
    [Arguments]    ${system}    ${cmd}    ${user}=${DEFAULT_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    ${output}=    Run Command On Remote System    ${system}    ${cmd}    ${user}    ${password}    ${prompt}
    ...    ${prompt_timeout}
    Log    ${output}
    RETURN    ${output}

Run Command On Mininet
    [Documentation]    Call Run Comand On Remote System, but with default values suitable for Mininet machine.
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}    ${cmd}=echo    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${TOOLS_SYSTEM_PROMPT}
    BuiltIn.Run Keyword And Return
    ...    Run Command On Remote System
    ...    ${system}
    ...    ${cmd}
    ...    ${user}
    ...    ${password}
    ...    prompt=${prompt}

Run Command On Controller
    [Documentation]    Call Run Comand On Remote System, but with default values suitable for Controller machine.
    [Arguments]    ${system}=${ODL_SYSTEM_IP}    ${cmd}=echo    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    BuiltIn.Run Keyword And Return
    ...    Run Command On Remote System
    ...    ${system}
    ...    ${cmd}
    ...    ${user}
    ...    ${password}
    ...    prompt=${prompt}

Run Command On Existing Connection
    [Documentation]    Switch to and run command on an already existing SSH connection and switch back
    [Arguments]    ${conn_id}=${EMPTY}    ${cmd}=echo    ${return_stdout}=True    ${return_stderr}=False
    IF    "${return_stdout}"!="True" and "${return_stderr}"!="True"
        Fail    At least one of {return_stdout} or {return_stderr} args should be set to True
    END
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    BuiltIn.Log    Attempting to execute command "${cmd}" on existing connection "${conn_id}
    SSHLibrary.Switch Connection    ${conn_id}
    ${stdout}    ${stderr}=    SSHLibrary.Execute Command    ${cmd}    return_stderr=True
    Log    ${stderr}
    IF    "${return_stdout}"!="True"    RETURN    ${stderr}
    IF    "${return_stderr}"!="True"    RETURN    ${stdout}
    RETURN    ${stdout}    ${stderr}
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_ssh_connection.index}

Verify File Exists On Remote System
    [Documentation]    Will create connection with public key and will PASS if the given ${file} exists,
    ...    otherwise will FAIL
    [Arguments]    ${system}    ${file}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=5s
    ${conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    SSHKeywords.Flexible SSH Login    ${user}    ${password}
    SSHLibrary.File Should Exist    ${file}
    Close Connection

Check Karaf Log File Does Not Have Messages
    [Documentation]    Fails if the provided ${message} is found in the karaf.log file. Uses grep to search. The
    ...    karaf.log file can be overridden with ${log_file} to be any file on the given system @ ${ip}
    [Arguments]    ${ip}    ${message}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}    ${log_file}=${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
    ${output}=    Run Command On Controller
    ...    ${ip}
    ...    grep -c '${message}' ${log_file}
    ...    user=${user}
    ...    password=${password}
    ...    prompt=${prompt}
    Should Be Equal As Strings    ${output}    0

Verify Controller Is Not Dead
    [Documentation]    Will execute any tests to verify the controller is not dead. Some checks are
    ...    Out Of Memory Execptions.
    [Arguments]    ${controller_ip}=${ODL_SYSTEM_IP}
    Check Karaf Log File Does Not Have Messages    ${controller_ip}    java.lang.OutOfMemoryError
    # TODO: Should Verify Controller * keywords also accept user, password, prompt and karaf_log arguments?

Verify Controller Has No Null Pointer Exceptions
    [Documentation]    Will execute any tests to verify the controller is not having any null pointer eceptions.
    [Arguments]    ${controller_ip}=${ODL_SYSTEM_IP}
    Check Karaf Log File Does Not Have Messages    ${controller_ip}    java.lang.NullPointerException

Verify Controller Has No Runtime Exceptions
    [Documentation]    Will execute any tests to verify the controller is not having any runtime eceptions.
    [Arguments]    ${controller_ip}=${ODL_SYSTEM_IP}
    Check Karaf Log File Does Not Have Messages    ${controller_ip}    java.lang.RuntimeException

Get Epoch Time
    [Documentation]    Get the Epoc time from MM/DD/YYYY HH:MM:SS
    [Arguments]    ${time}
    ${epoch_time}=    Convert Date    ${time}    epoch    exclude_milles=True    date_format=%m/%d/%Y %H:%M:%S
    ${epoch_time}=    Convert To Integer    ${epoch_time}
    RETURN    ${epoch_time}

Remove Space on String
    [Documentation]    Remove the empty space from given string.count is optional,if its given
    ...    that many occurence of space will be removed from left
    [Arguments]    ${str}    ${count}=-1
    ${x}=    Convert To String    ${str}
    ${x}=    Replace String    ${str}    ${SPACE}    ${EMPTY}    count=${count}
    RETURN    ${x}

Split Value from String
    [Documentation]    Split the String based on given splitter and return as list
    [Arguments]    ${str}    ${splitter}
    @{x}=    Split String    ${str}    ${splitter}
    RETURN    @{x}

Concatenate the String
    [Documentation]    Catenate the two non-string objects and return as String
    [Arguments]    ${str1}    ${str2}
    ${str1}=    Convert to String    ${str1}
    ${str2}=    Convert to String    ${str2}
    ${output}=    Catenate    ${str1}    ${str2}
    RETURN    ${output}

Post Elements To URI
    [Documentation]    Perform a POST rest operation, using the URL and data provided
    [Arguments]    ${rest_uri}    ${data}    ${headers}=${headers}    ${session}=session
    ${resp}=    RequestsLibrary.Post On Session
    ...    ${session}
    ...    url=${rest_uri}
    ...    data=${data}
    ...    headers=${headers}
    ...    expected_status=anything
    Log    ${resp.text}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Remove All Elements At URI
    [Arguments]    ${uri}    ${session}=session
    ${resp}=    RequestsLibrary.Delete On Session    ${session}    url=${uri}    expected_status=anything
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Remove All Elements At URI And Verify
    [Arguments]    ${uri}    ${session}=session
    ${resp}=    RequestsLibrary.Delete On Session    ${session}    url=${uri}    expected_status=anything
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get On Session    ${session}    url=${uri}    expected_status=anything
    Should Contain    ${DELETED_STATUS_CODES}    ${resp.status_code}

Remove All Elements If Exist
    [Documentation]    Delete all elements from an URI if the configuration was not empty
    [Arguments]    ${uri}    ${session}=session
    ${resp}=    RequestsLibrary.Get On Session    ${session}    url=${uri}    expected_status=anything
    IF    '${resp.status_code}'!='404' and '${resp.status_code}'!='409'
        Remove All Elements At URI    ${uri}    ${session}
    END

Add Elements To URI From File
    [Documentation]    Put data from a file to a URI
    [Arguments]    ${dest_uri}    ${data_file}    ${headers}=${headers}    ${session}=session
    ${body}=    OperatingSystem.Get File    ${data_file}
    ${resp}=    RequestsLibrary.Put On Session
    ...    ${session}
    ...    url=${dest_uri}
    ...    data=${body}
    ...    headers=${headers}
    ...    expected_status=anything
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Add Elements To URI From File And Verify
    [Documentation]    Put data from a file to a URI and verify the HTTP response
    [Arguments]    ${dest_uri}    ${data_file}    ${headers}=${headers}    ${session}=session
    ${body}=    OperatingSystem.Get File    ${data_file}
    Add Elements to URI And Verify    ${dest_uri}    ${body}    ${headers}    ${session}

Add Elements To URI And Verify
    [Documentation]    Put data to a URI and verify the HTTP response
    [Arguments]    ${dest_uri}    ${data}    ${headers}=${headers}    ${session}=session
    ${resp}=    RequestsLibrary.Put On Session
    ...    ${session}
    ...    url=${dest_uri}
    ...    ${data}
    ...    headers=${headers}
    ...    expected_status=anything
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get On Session    ${session}    url=${dest_uri}    expected_status=anything
    Should Not Contain    ${DELETED_STATUS_CODES}    ${resp.status_code}

Add Elements To URI From File And Check Validation Error
    [Documentation]    Shorthand for PUTting data from file and expecting status code 400.
    [Arguments]    ${dest_uri}    ${data_file}    ${headers}=${headers}    ${session}=session
    BuiltIn.Comment    TODO: Does this have any benefits, considering TemplatedRequests can also do this in one line?
    ${body}=    OperatingSystem.Get File    ${data_file}
    ${resp}=    RequestsLibrary.Put On Session
    ...    ${session}
    ...    url=${dest_uri}
    ...    data=${body}
    ...    headers=${headers}
    ...    expected_status=anything
    Should Contain    ${DATA_VALIDATION_ERROR}    ${resp.status_code}

Add Elements To URI From File And Check Server Error
    [Documentation]    Shorthand for PUTting data from file and expecting status code 500.
    ...    Consider opening a Bug against ODL, as in most test cases, 400 is the http code to expect.
    [Arguments]    ${dest_uri}    ${data_file}    ${headers}=${headers}    ${session}=session
    BuiltIn.Comment    TODO: Does this have any benefits, considering TemplatedRequests can also do this in one line?
    ${body}=    OperatingSystem.Get File    ${data_file}
    ${resp}=    RequestsLibrary.Put On Session
    ...    ${session}
    ...    url=${dest_uri}
    ...    data=${body}
    ...    headers=${headers}
    ...    expected_status=anything
    Should Contain    ${INTERNAL_SERVER_ERROR}    ${resp.status_code}

Post Elements To URI From File
    [Arguments]    ${dest_uri}    ${data_file}    ${headers}=${headers}    ${session}=session
    ${body}=    OperatingSystem.Get File    ${data_file}
    ${resp}=    RequestsLibrary.Post On Session
    ...    ${session}
    ...    url=${dest_uri}
    ...    data=${body}
    ...    headers=${headers}
    ...    expected_status=anything
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Run Process With Logging And Status Check
    [Documentation]    Execute an OS command, log STDOUT and STDERR output and check exit code to be 0
    [Arguments]    @{proc_args}
    ${result}=    Run Process    @{proc_args}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0
    RETURN    ${result}

Get Data From URI
    [Documentation]    Issue a Get On Session and return the data obtained or on error log the error and fail.
    ...    Issues a Get On Session for ${uri} in ${session} using headers from
    ...    ${headers}. If the request returns a HTTP error, fails. Otherwise
    ...    returns the data obtained by the request.
    [Arguments]    ${session}    ${uri}    ${headers}=${NONE}
    ${resp}=    RequestsLibrary.Get On Session
    ...    ${session}
    ...    url=${uri}
    ...    headers=${headers}
    ...    expected_status=anything
    IF    ${resp.status_code} == 200    RETURN    ${resp.text}
    Builtin.Log    ${resp.text}
    Builtin.Fail    The request failed with code ${resp.status_code}

Get URI And Verify
    [Documentation]    Issue a Get On Session and verify a successfull HTTP return.
    ...    Issues a Get On Session for ${uri} in ${session} using headers from ${headers}.
    [Arguments]    ${uri}    ${session}=session    ${headers}=${NONE}
    ${resp}=    RequestsLibrary.Get On Session
    ...    ${session}
    ...    url=${uri}
    ...    headers=${headers}
    ...    expected_status=anything
    Builtin.Log    ${resp.status_code}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

No Content From URI
    [Documentation]    Issue a Get On Session and return on error 404 (No content) or will fail and log the content.
    ...    Issues a Get On Session for ${uri} in ${session} using headers from
    ...    ${headers}. If the request returns a HTTP error, fails. Otherwise
    ...    returns the data obtained by the request.
    [Arguments]    ${session}    ${uri}    ${headers}=${NONE}
    ${resp}=    RequestsLibrary.Get On Session
    ...    ${session}
    ...    url=${uri}
    ...    headers=${headers}
    ...    expected_status=anything
    IF    ${resp.status_code} == 404 or ${resp.status_code} == 409    RETURN
    Builtin.Log    ${resp.text}
    Builtin.Fail    The request failed with code ${resp.status_code}

Get Index From List Of Dictionaries
    [Documentation]    Extract index for the dictionary in a list that contains a key-value pair. Returns -1 if key-value is not found.
    [Arguments]    ${dictionary_list}    ${key}    ${value}
    ${length}=    Get Length    ${dictionary_list}
    ${index}=    Set Variable    -1
    FOR    ${i}    IN RANGE    ${length}
        ${dictionary}=    Get From List    ${dictionary_list}    ${i}
        IF    """${dictionary}[${key}]""" == """${value}"""
            Set Test Variable    ${index}    ${i}
        END
    END
    RETURN    ${index}

Check Item Occurrence
    [Documentation]    Check string for occurrences of items expressed in a list of dictionaries {item=occurrences}. 0 occurences means item is not present.
    [Arguments]    ${string}    ${dictionary_item_occurrence}
    FOR    ${item}    IN    @{dictionary_item_occurrence}
        Should Contain X Times    ${string}    ${item}    ${dictionary_item_occurrence}[${item}]
    END

Post Log Check
    [Documentation]    Post body to ${uri}, log response content, and check status
    [Arguments]    ${uri}    ${body}    ${session}=session    ${status_codes}=200
    ${resp}=    RequestsLibrary.Post On Session    ${session}    url=${uri}    data=${body}    expected_status=anything
    Log    ${resp.text}
    TemplatedRequests.Check Status Code    ${resp}    ${status_codes}
    RETURN    ${resp}

Get Log File Name
    [Documentation]    Get the name of the suite sanitized to be usable as a part of filename.
    ...    These names are used to constructs names of the log files produced
    ...    by the testing tools so two suites using a tool wont overwrite the
    ...    log files if they happen to run in one job.
    [Arguments]    ${testtool}    ${testcase}=${EMPTY}
    ${name}=    BuiltIn.Evaluate    """${SUITE_NAME}""".replace(" ","-").replace("/","-").replace(".","-")
    ${suffix}=    BuiltIn.Set_Variable_If    '${testcase}' != ''    --${testcase}    ${EMPTY}
    ${date}=    DateTime.Get Current Date
    ${timestamp}=    DateTime.Convert Date    ${date}    epoch
    RETURN    ${testtool}--${name}${suffix}.${timestamp}.log

Set_User_Configurable_Variable_Default
    [Documentation]    Set a default value for an user configurable variable.
    ...    This keyword is needed if your default value is calculated using
    ...    a complex expression which needs BuiltIn.Evaluate or even more
    ...    complex keywords. It sets the variable ${name} (the name of the
    ...    variable MUST be specified WITHOUT the ${} syntactic sugar due
    ...    to limitations of Robot Framework) to ${value} but only if the
    ...    variable ${name} was not set previously. This keyword is intended
    ...    for user configurable variables which are supposed to be set only
    ...    with pybot -v; calling this keyword on a variable that was already
    ...    set by another keyword will silently turn the call into a NOP and
    ...    thus is a bug in the suite or resource trying to call this
    ...    keyword.
    [Arguments]    ${name}    ${value}
    # TODO: Figure out how to make the ${value} evaluation "lazy" (meaning
    #    evaluating it only when the user did not set anything and thus the
    #    default is needed). This might be needed to avoid potentially costly
    #    keyword invocations when they are not needed. Currently no need for
    #    this was identified, thus leaving it here as a TODO. Based on
    #    comments the best approach would be to create another keyword that
    #    expects a ScalarClosure in the place of ${value} and calls the
    #    closure to get the value but only if the value is needed).
    #    The best idea how to implement this "laziness" would be to have the
    #    used to define another keyword that will be responsible for getting
    #    the default value and then passing the name of this getter keyword
    #    to this keyword. Then this keyword would call the getter (to obtain
    #    the expensive default value) only if it discovers that this value
    #    is really needed (because the variable is not set yet).
    # TODO: Is the above TODO really necessary? Right now we don't have any
    #    examples of "expensive default values" where to obtain the default
    #    value is so expensive on resources (e.g. need to SSH somewhere to
    #    check something) that we would want to skip the calculation if the
    #    variable for which it is needed has a value already provided by the
    #    user using "pybot -v" or something. One example would be
    #    JAVA_HOME if it would be designed as user-configurable variable
    #    (currently it is not; users can specify "use jdk7" or "use jdk8"
    #    but not "use the jdk over there"; and there actually is no JAVA_HOME
    #    present in the resource, rather the Java invocation command uses the
    #    Java invocation with a full path). The default value of JAVA_HOME
    #    has to be obtained by issuing commands on the SSH connection where
    #    the resulting Java invocation command will be used (to check
    #    multiple candidate paths until one that fits is found) and we could
    #    skip all this checking if a JAVA_HOME was supplied by the user using
    #    "pybot -v".
    ${value}=    BuiltIn.Get_Variable_Value    \${${name}}    ${value}
    BuiltIn.Set_Suite_Variable    \${${name}}    ${value}

Convert_To_Minutes
    [Documentation]    Convert a Robot time string to an integer expressing the time in minutes, rounded up
    ...    This is a wrapper around DateTime.Convert_Time which does not
    ...    provide this functionality directly nor is even able to produce
    ...    an integer directly. It is needed for RestPerfClient which
    ...    cannot accept floats for its --timeout parameter and interprets
    ...    the value supplied in this parameter in minutes.
    [Arguments]    ${time}
    ${seconds}=    DateTime.Convert_Time    ${time}    result_format=number
    ${minutes}=    BuiltIn.Evaluate    int(math.ceil(${seconds}/60.0))    modules=math
    RETURN    ${minutes}

Write Commands Until Expected Prompt
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    [Arguments]    ${cmd}    ${prompt}    ${timeout}=${DEFAULT_TIMEOUT}
    BuiltIn.Log    cmd: ${cmd}
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Read
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read Until    ${prompt}
    RETURN    ${output}

Write Commands Until Expected Regexp
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    [Arguments]    ${cmd}    ${regexp}    ${timeout}=${DEFAULT_TIMEOUT}
    BuiltIn.Log    cmd: ${cmd}
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Read
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read Until Regexp    ${regexp}
    RETURN    ${output}

Install Package On Ubuntu System
    [Documentation]    Keyword to install packages for testing to Ubuntu Mininet VM
    [Arguments]    ${package_name}    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    Log    Keyword to install package to Mininet Ubuntu VM
    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    SSHKeywords.Flexible Mininet Login    user=${user}    password=${password}
    Write    sudo apt-get install -y ${package_name}
    Read Until    ${prompt}

Json Parse From String
    [Documentation]    Parse given plain string into json (dictionary)
    [Arguments]    ${plain_string_with_json}
    ${json_data}=    Evaluate    json.loads('''${plain_string_with_json}''')    json
    RETURN    ${json_data}

Json Parse From File
    [Documentation]    Parse given file content into json (dictionary)
    [Arguments]    ${json_file}
    ${json_plain_string}=    OperatingSystem.Get file    ${json_file}
    ${json_data}=    Json Parse From String    ${json_plain_string}
    RETURN    ${json_data}

Modify Iptables On Remote System
    [Documentation]    Wrapper keyword to run iptables with any given ${iptables_rule} string on the remote system given
    ...    by ${remote_system_ip}. The iptables listing will be output before and after the command is run
    [Arguments]    ${remote_system_ip}    ${iptables_rule}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${prompt}=${ODL_SYSTEM_PROMPT}
    ${list_iptables_command}=    BuiltIn.Set Variable    sudo /sbin/iptables -L -n
    ${output}=    Utils.Run Command On Remote System
    ...    ${remote_system_ip}
    ...    ${list_iptables_command}
    ...    ${user}
    ...    ${password}
    ...    prompt=${prompt}
    BuiltIn.Log    ${output}
    Utils.Run Command On Remote System
    ...    ${remote_system_ip}
    ...    sudo /sbin/iptables ${iptables_rule}
    ...    ${user}
    ...    ${password}
    ...    prompt=${prompt}
    ${output}=    Utils.Run Command On Remote System
    ...    ${remote_system_ip}
    ...    ${list_iptables_command}
    ...    ${user}
    ...    ${password}
    ...    prompt=${prompt}
    BuiltIn.Log    ${output}

Get_Sysstat_Statistics
    [Documentation]    Store current connection index, open new connection to ip_address. Run command to get sysstat results from script,
    ...    which is running on all children nodes. Returns cpu, network, memory usage statistics from the node for each 10 minutes
    ...    that node was running. Used for debug purposes. Returns whole output of sysstat.
    [Arguments]    ${ip_address}=${ODL_SYSTEM_IP}
    ${current_connection}=    SSHLibrary.Get_Connection
    SSHKeywords.Open_Connection_To_ODL_System    ${ip_address}
    SSHLibrary.Write    sar -A -f /var/log/sa/sa*
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    SSHLibrary.Close_Connection
    RETURN    ${output}
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_connection.index}

Check Diagstatus
    [Documentation]    GET http://${ip_address}:${RESTCONFPORT}/diagstatus and return the response. ${check_status}
    ...    and ${expected_status_code} can be used to ignore the status code, or validate any status code value.
    ...    By default, this keyword will pass if the status code returned is 200, and fail otherwise.
    [Arguments]    ${ip_address}=${ODL_SYSTEM_IP}    ${check_status}=True    ${expected_status}=${200}
    RequestsLibrary.Create Session    diagstatus_session    http://${ip_address}:${RESTCONFPORT}
    ${resp}=    RequestsLibrary.Get On Session    diagstatus_session    url=/diagstatus    expected_status=anything
    IF    "${check_status}" == "True"
        RequestsLibrary.Status Should Be    ${expected_status}    ${resp}
    END
    RETURN    ${resp}
