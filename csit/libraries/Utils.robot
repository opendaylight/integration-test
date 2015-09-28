*** Settings ***
Library           SSHLibrary
Library           String
Library           DateTime
Library           ./UtilLibrary.py
Resource          KarafKeywords.robot
Variables         ../variables/Variables.py

*** Variables ***
# TODO: Introduce ${tree_size} and use instead of 1 in the next line.
${start}          sudo mn --controller=remote,ip=${CONTROLLER} --topo tree,1 --switch ovsk,protocols=OpenFlow13

*** Keywords ***
Start Suite
    [Arguments]    ${system}=${MININET}    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${timeout}=30s
    [Documentation]    Basic setup/cleanup work that can be done safely before any system
    ...    is run.
    Log    Start the test on the base edition
    Clean Mininet System
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Mininet Login    user=${user}    password=${password}
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Write    ${start}
    Read Until    mininet>

Start Mininet
    [Arguments]    ${system}=${MININET}    ${cmd}=${start}    ${custom}=${OVSDB_CONFIG_DIR}/ovsdb.py    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=30s
    [Documentation]    Basic setup to start mininet with custom topology
    Log    Start the test on the base edition
    Clean Mininet System
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Mininet Login    user=${user}    password=${password}
    Put File    ${custom}
    Write    ${cmd}
    Read Until    mininet>
    [Return]    ${mininet_conn_id}

Stop Mininet
    [Arguments]    ${mininet_conn_id}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Basic setup to stop/clean mininet
    Switch Connection    ${mininet_conn_id}
    SSHLibrary.Write    exit
    Read Until    ${prompt}
    Close Connection

Stop Suite
    [Arguments]    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Log    Stop the test on the base edition
    Switch Connection    ${mininet_conn_id}
    Read
    Write    exit
    Read Until    ${prompt}
    Close Connection

Ensure All Nodes Are In Response
    [Arguments]    ${URI}    ${node_list}
    [Documentation]    A GET is made to the supplied ${URI} and every item in the ${node_list}
    ...    is verified to exist in the repsonse. This keyword currently implies that it's node
    ...    specific but any list of strings can be given in ${node_list}. Refactoring of this
    ...    to make it more generic should be done. (see keyword "Check For Elements At URI")
    : FOR    ${node}    IN    @{node_list}
    \    ${resp}    RequestsLibrary.Get    session    ${URI}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    Should Contain    ${resp.content}    ${node}

Check Nodes Stats
    [Arguments]    ${node}
    [Documentation]    A GET on the /node/${node} API is made and specific flow stat
    ...    strings are checked for existence.
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}/node/${node}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    flow-capable-node-connector-statistics
    Should Contain    ${resp.content}    flow-table-statistics

Check That Port Count Is Ok
    [Arguments]    ${node}    ${count}
    [Documentation]    A GET on the /port API is made and the specified port ${count} is
    ...    verified. A more generic Keyword "Check For Specific Number Of Elements At URI"
    ...    also does this work and further consolidation should be done.
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/${CONTAINER}/port
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain X Times    ${resp.content}    ${node}    ${count}

Check For Specific Number Of Elements At URI
    [Arguments]    ${uri}    ${element}    ${expected_count}
    [Documentation]    A GET is made to the specified ${URI} and the specific count of a
    ...    given element is done (as supplied by ${element} and ${expected_count})
    ${resp}    RequestsLibrary.Get    session    ${uri}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain X Times    ${resp.content}    ${element}    ${expected_count}

Check For Elements At URI
    [Arguments]    ${uri}    ${elements}
    [Documentation]    A GET is made at the supplied ${URI} and every item in the list of
    ...    ${elements} is verified to exist in the response
    ${resp}    RequestsLibrary.Get    session    ${uri}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN    @{elements}
    \    Should Contain    ${resp.content}    ${i}

Check For Elements Not At URI
    [Arguments]    ${uri}    ${elements}
    [Documentation]    A GET is made at the supplied ${URI} and every item in the list of
    ...    ${elements} is verified to NOT exist in the response
    ${resp}    RequestsLibrary.Get    session    ${uri}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN    @{elements}
    \    Should Not Contain    ${resp.content}    ${i}

Clean Mininet System
    [Arguments]    ${system}=${MININET}
    Run Command On Mininet    ${system}    sudo mn -c
    Run Command On Mininet    ${system}    sudo ps -elf | egrep 'usr/local/bin/mn' | egrep python | awk '{print "sudo kill -9",$4}' | sh

Clean Up Ovs
    [Arguments]    ${system}=${MININET}
    [Documentation]    Cleans up the OVS instance and remove any existing common known bridges.
    ${output}=    Run Command On Mininet    ${system}    sudo ovs-vsctl list-br
    Log    ${output}
    : FOR    ${i}    IN    ${output}
    \    Run Command On Mininet    ${system}    sudo ovs-vsctl --if-exists del-br ${i}
    Run Command On Mininet    ${system}    sudo ovs-vsctl del-manager

Extract Value From Content
    [Arguments]    ${content}    ${index}    ${strip}=nostrip
    [Documentation]    Will take the given response content and return the value at the given index as a string
    ${value}=    Get Json Value    ${content}    ${index}
    ${value}=    Convert To String    ${value}
    ${value}=    Run Keyword If    '${strip}' == 'strip'    Strip Quotes    ${value}
    [Return]    ${value}

Get Process ID Based On Regex On Remote System
    [Arguments]    ${system}    ${regex_string_to_match_on}    ${user}=${MININET_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Uses ps to find a process that matches the supplied regex. Returns the PID of that process
    ...    The ${regex_string_to_match_on} should produce a unique process otherwise the PID returned may not be
    ...    the expected PID
    # doing the extra -v grep in this command to exclude the grep process itself from the output
    ${cmd}=    Set Variable    ps -elf | grep -v grep | grep ${regex_string_to_match_on} | awk '{print $4}'
    ${output}=    Run Command On Remote System    ${system}    ${cmd}    user=${user}    password=${password}    prompt=${prompt}
    ...    prompt_timeout=${prompt_timeout}
    # ${output} contains the system prompt and all we want is the value of the number
    ${pid}=    Fetch From Left    ${output}    \r
    # TODO: Get Process * keywords have perhaps non-standard default credentials.
    # ...    Should there be * On Mininet and * On Controller specializations?
    [Return]    ${pid}

Get Process Thread Count On Remote System
    [Arguments]    ${system}    ${pid}    ${user}=${MININET_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Executes the ps command to retrieve the lightweight process (aka thread) count.
    ${cmd}=    Set Variable    ps --no-headers -o nlwp ${pid}
    ${output}=    Run Command On Remote System    ${system}    ${cmd}    user=${user}    password=${password}    prompt=${prompt}
    ...    prompt_timeout=${prompt_timeout}
    # ${output} contains the system prompt and all we want is the value of the number
    ${thread_count}=    Fetch From Left    ${output}    \r
    [Return]    ${thread_count}

Strip Quotes
    [Arguments]    ${string_to_strip}
    [Documentation]    Will strip ALL quotes from given string and return the new string
    ${string_to_return}=    Replace String    ${string_to_strip}    "    \    count=-1
    [Return]    ${string_to_return}

Flexible SSH Login
    [Arguments]    ${user}    ${password}=${EMPTY}    ${delay}=0.5s
    [Documentation]    On active SSH session: if given non-empty password, do Login, else do Login With Public Key.
    ${pwd_length} =    BuiltIn.Get Length    ${password}
    # ${pwd_length} is guaranteed to be an integer, so we are safe to evaluate it as Python expression.
    BuiltIn.Run Keyword And Return If    ${pwd_length} > 0    SSHLibrary.Login    ${user}    ${password}    delay=${delay}
    BuiltIn.Run Keyword And Return    SSHLibrary.Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    ${KEYFILE_PASS}    delay=${delay}

Flexible Mininet Login
    [Arguments]    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}    ${delay}=0.5s
    [Documentation]    Call Flexible SSH Login, but with default values suitable for Mininet machine.
    BuiltIn.Run Keyword And Return    Flexible SSH Login    user=${user}    password=${password}    delay=${delay}

Flexible Controller Login
    [Arguments]    ${user}=${CONTROLLER_USER}    ${password}=${CONTROLLER_PASSWORD}    ${delay}=0.5s
    [Documentation]    Call Flexible SSH Login, but with default values suitable for Controller machine.
    BuiltIn.Run Keyword And Return    Flexible SSH Login    user=${user}    password=${password}    delay=${delay}

Run Command On Remote System
    [Arguments]    ${system}    ${cmd}    ${user}=${MININET_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Reduces the common work of running a command on a remote system to a single higher level
    ...    robot keyword, taking care to log in with a public key and. The command given is written
    ...    and the output returned. No test conditions are checked.
    Log    Attempting to execute ${cmd} on ${system} by ${user} with ${keyfile_pass} and ${prompt}
    ${conn_id}=    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read Until    ${prompt}
    SSHLibrary.Close Connection
    Log    ${output}
    [Return]    ${output}

Write_Bare_Ctrl_C
    [Documentation]    Construct ctrl+c character and SSH-write it (without endline) to the current SSH connection.
    ...    Do not read anything yet.
    ${ctrl_c}=    BuiltIn.Evaluate    chr(int(3))
    SSHLibrary.Write_Bare    ${ctrl_c}

Run Command On Mininet
    [Arguments]    ${system}=${MININET}    ${cmd}=echo    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Call Run Comand On Remote System, but with default values suitable for Mininet machine.
    BuiltIn.Run Keyword And Return    Run Command On Remote System    ${system}    ${cmd}    user=${user}    password=${password}    prompt=${prompt}
    ...    prompt_timeout=${prompt_timeout}

Run Command On Controller
    [Arguments]    ${system}=${CONTROLLER}    ${cmd}=echo    ${user}=${CONTROLLER_USER}    ${password}=${CONTROLLER_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Call Run Comand On Remote System, but with default values suitable for Controller machine.
    BuiltIn.Run Keyword And Return    Run Command On Remote System    ${system}    ${cmd}    user=${user}    password=${password}    prompt=${prompt}
    ...    prompt_timeout=${prompt_timeout}

Verify File Exists On Remote System
    [Arguments]    ${system}    ${file}    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=5s
    [Documentation]    Will create connection with public key and will PASS if the given ${file} exists,
    ...    otherwise will FAIL
    ${conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    SSHLibrary.File Should Exist    ${file}
    Close Connection

Verify Controller Is Not Dead
    [Arguments]    ${controller_ip}=${CONTROLLER}
    [Documentation]    Will execute any tests to verify the controller is not dead. Some checks are
    ...    Out Of Memory Execptions.
    Check Karaf Log File Does Not Have Messages    ${controller_ip}    java.lang.OutOfMemoryError
    # TODO: Should Verify Controller * keywords also accept user, password, prompt and karaf_log arguments?

Verify Controller Has No Null Pointer Exceptions
    [Arguments]    ${controller_ip}=${CONTROLLER}
    [Documentation]    Will execute any tests to verify the controller is not having any null pointer eceptions.
    Check Karaf Log File Does Not Have Messages    ${controller_ip}    java.lang.NullPointerException

Get Epoch Time
    [Arguments]    ${time}
    [Documentation]    Get the Epoc time from MM/DD/YYYY HH:MM:SS
    ${epoch_time}=    Convert Date    ${time}    epoch    exclude_milles=True    date_format=%m/%d/%Y %H:%M:%S
    ${epoch_time}=    Convert To Integer    ${epoch_time}
    [Return]    ${epoch_time}

Remove Space on String
    [Arguments]    ${str}    ${count}=-1
    [Documentation]    Remove the empty space from given string.count is optional,if its given
    ...    that many occurence of space will be removed from left
    ${x}=    Convert To String    ${str}
    ${x}=    Replace String    ${str}    ${SPACE}    ${EMPTY}    count=${count}
    [Return]    ${x}

Split Value from String
    [Arguments]    ${str}    ${splitter}
    [Documentation]    Split the String based on given splitter and return as list
    @{x}=    Split String    ${str}    ${splitter}
    [Return]    @{x}

Concatenate the String
    [Arguments]    ${str1}    ${str2}
    [Documentation]    Catenate the two non-string objects and return as String
    ${str1}=    Convert to String    ${str1}
    ${str2}=    Convert to String    ${str2}
    ${output}=    Catenate    ${str1}    ${str2}
    [Return]    ${output}

Remove All Elements At URI
    [Arguments]    ${uri}
    ${resp}    RequestsLibrary.Delete    session    ${uri}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Elements To URI From File
    [Arguments]    ${dest_uri}    ${data_file}
    ${body}    OperatingSystem.Get File    ${data_file}
    ${resp}    RequestsLibrary.Put    session    ${dest_uri}    data=${body}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

Post Elements To URI From File
    [Arguments]    ${dest_uri}    ${data_file}
    ${body}    OperatingSystem.Get File    ${data_file}
    ${resp}    RequestsLibrary.Post    session    ${dest_uri}    data=${body}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

FIXME__REFACTOR_THE_CODE_BELOW_AND_EXTRACT_TO_ITS_OWN_MODULE
    #
    # Refactoring of the code below to satisfy "best Robot coding pracitces"
    # needs to be postponed because it is long and involved work and the
    # unavailability of this API blocks many important tasks from being
    # merged and also slows people down. The following problems were
    # identified:
    #
    # - Using global variables to store state. This is frowned upon.
    #
    # Right now the priority is to have the API working. Refactoring the code
    # to look good can wait.
    #
    # The ugly "Utils__XXX_YYY_ZZZ" names of the keywords are intentional.
    # These are internal keywords that are not supposed to be called from the
    # outside of this resource. We need to create a naming convention for
    # such keywords. The only keywords that are part of the API are those
    # with names that comply to the conventions of this file.
    #
    # Additionally, this piece of code shall be in its own keyword resource
    # to reduce the "Utils resource bloat" problem. Unfortunately that is
    # nearly impossible to be done now until some sort of "Robot automatic
    # review system" is created before because Robot is not exactly helpful
    # when it comes to reporting where an undefined keyword was used. The
    # first problem is that it only says that an undefined keyword was used
    # but it fails to reveal where, and second problem is that the failure
    # can get pretty hidden if the offending code happens to run under "Run
    # Keyword And Ignore Error" or similar (in that case one needs to dig
    # the error report out of the logs).

Utils__Store_Response_Code
    [Arguments]    ${response}
    # Store the response code for later checking. If the code is not
    # 200, stores also the response text (as it most likely contains further details
    # about the error response code). The response code is stored into the suite
    # variable ${response_code} which can be read by the tests as necessary.
    Builtin.Set_Suite_Variable    ${Utils__response_code}    ${response.status_code}
    Builtin.Run_Keyword_If    ${Utils__response_code} <> 200    Builtin.Set_Suite_Variable    ${Utils__response_text}    ${response.text}

Utils__Run_Keyword_If_Status_Is_Ok
    [Arguments]    @{Keyword}
    Builtin.Run_Keyword_If    ${Utils__response_code} == 200    Builtin.Run_Keyword    @{Keyword}

Utils__Fail_If_Status_Is_Wrong
    # Check that the stored response code is 200. If not, log the
    # stored response text and then fail.
    Builtin.Return_From_Keyword_If    ${Utils__response_code} == 200
    Builtin.Log    ${Utils__response_text}
    Builtin.Fail    The request failed with code ${Utils__response_code}

Utils__Identity
    [Arguments]    ${data}
    [Return]    ${data}

Get Data From URI
    [Arguments]    ${session}    ${uri}    ${headers}=${NONE}
    [Documentation]    Issue a GET request and return the data obtained or on error log the error and fail.
    ...    Issues a GET request for ${uri} in ${session} using headers from
    ...    ${headers}. If the request returns a HTTP error, fails. Otherwise
    ...    returns the data obtained by the request.
    ${response}=    RequestsLibrary.Get    ${session}    ${uri}    ${headers}
    Utils__Store_Response_Code    ${response}
    Utils__Fail_If_Status_Is_Wrong
    [Return]    ${response.text}

Utils__Request_And_Check_Data
    [Arguments]    ${getter}    ${pass_on_http_errors}    @{keyword}
    # Some of the getters may generates a LOT of garbage, especially when
    # they download massive datasets and then passage them all the way down
    # to just one integer or something similarly small (an example can be
    # getting count of routes in topology which can generate several tens of
    # MB of garbage if the topology contains several million routes). This
    # garbage is not immediately reclaimed by Python once it is no longer in
    # use because Robot creates cycled structures that hold references to
    # this multi-megabyte garbage. Allowing this garbage to build could cause
    # "sudden death syndrome" (OOM killer invocation) of the Robot process
    # before Python decides to collect the multi-megabyte pieces of the
    # garbage on its own so make sure to tell Python to do this collection
    # after the getter is invoked (and before anything else is done). This
    # must be done here because only here we can be sure that the
    # multi-mega-byte value used internally by the getter is really turned
    # into a piece of garbage waiting for collection. Additionally I don't
    # want the getters to be concerned with this piece of low level
    # housekeeping.
    ${status}    ${data}=    BuiltIn.Run Keyword And Ignore Error    ${getter}
    Builtin.Evaluate    gc.collect()    modules=gc
    BuiltIn.Run Keyword Unless    ${pass_on_http_errors}    BuiltIn.Run Keyword If    '${status}' <> 'PASS'    BuiltIn.Fail    Data getter error encountered
    BuiltIn.Run Keyword If    '${status}' == 'PASS'    BuiltIn.Run Keyword    @{keyword}    ${data}
    [Return]    ${status}

Utils__Wait_For_Data_To_Satisfy_Keyword_Core
    [Arguments]    ${timeout}    ${period}    ${getter}    ${stop_at_http_errors}    @{keyword}
    # The WUKS executes the first test immediately. This may cause the data
    # check to generate a "false positive", terminating the WUKS prematurely
    # if the data being checked is some sort of performance counter that
    # reacts on changes being made elsewhere and which are initiated by the
    # keywords immediately preceeding this WUKS. An example is BGP scaling
    # test which is using "data-change-counter" for job completion detection.
    # The test fitst tells a mockup BGP peer to start sending updates and
    # then executes this keyword with a getter that consults the data change
    # counter to determine if work is still being done in the system or not.
    # The work is considered incomplete when the checker keyword sees changes
    # in the data change counter since it was invoked last time, telling the
    # WUKS to continue looping. But if a bare WUKS would be used here, the
    # first invocation of the check would occur immediately, producing a
    # false positive (the checker would think the work is completed though
    # it is not) because the MDSAL and the data change counter get no time
    # to obtain and complete any work that would affect the data change
    # counter and thus signal the checker that some work is being done and
    # thus it is necessary to wait. Avoiding this pitfall with bare WUKS
    # would require quite complicated design of the checker that would
    # require seeing "lack of changes" during several invocations before
    # "being convicted" to pass but that is long and involved work which is
    # better left for another commit. Currently a quickfix is implemented
    # here to use a Sleep to emulate a WUKS which inserts the "refresh
    # period" before every invocation of the check. In future another API for
    # this type of checkers will be added that allows the test described in
    # the example above to become robust against behavior of the WUKS. That
    # will allow us to get rid of this Sleep (and this comment as well).
    BuiltIn.Sleep    ${period}
    ${status}=    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Utils__Request_And_Check_Data    ${getter}    ${stop_at_http_errors}
    ...    @{keyword}
    BuiltIn.Run_Keyword_If    ${stop_at_http_errors}    BuiltIn.Run Keyword If    '${status}' <> 'PASS'    BuiltIn.Fail    Wait aborted because a data getter error was encountered

Wait For Data To Satisfy Keyword
    [Arguments]    ${timeout}    ${period}    ${getter}    ${keyword}=Utils__Identity    @{arguments}
    [Documentation]    Repeate a data request and check the data from the response until either the check passes or the request fails.
    ...    This runs ${getter} to obtain data repeatedly with ${period} time
    ...    between the attempts to obtain data. It passes if the data
    ...    obtained from ${getter} satisfies @{keyword}, which is composed of
    ...    ${keyword} and @{arguments}). Fails immediately if ${getter} fails
    ...    or ${timeout} ellapses. If @{keyword} is not specified, this
    ...    passes as soon as ${getter} returns any data successfully.
    Utils__Wait_For_Data_To_Satisfy_Keyword_Core    ${timeout}    ${period}    ${getter}    False    ${keyword}    @{arguments}

Wait For Data To Satisfy Keyword And Ignore Errors
    [Arguments]    ${timeout}    ${period}    ${getter}    ${keyword}=Utils__Identity    @{arguments}
    [Documentation]    Repeate a data request and check the data from the response until the check passes. Ignore any request failures.
    ...    Repeatedly uses ${getter} to obtain data with ${period} time
    ...    between the attempts until either the data obtained satisfies
    ...    @{keyword} or ${timeout} period ellapses. Any ${getter} failures
    ...    are ignored and waiting continues. If @{keyword} is not specified,
    ...    this passes as soon as ${getter} returns any data successfully.
    Utils__Wait_For_Data_To_Satisfy_Keyword_Core    ${timeout}    ${period}    ${getter}    True    ${keyword}    @{arguments}
