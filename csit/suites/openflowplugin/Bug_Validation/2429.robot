*** Settings ***
Documentation     OF Handshake threads should be closed if the connection has a
...               failure. This bug was fixed in the Helium SR3 release but
...               persisted in to the Lithium release. Once fixed, this will
...               catch any future regressions
Metadata          https://bugs.opendaylight.org/show_bug.cgi?id=2429    ${EMPTY}
Library           OperatingSystem
Library           SSHLibrary
Library           Process
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${openflow_port}    6633
${number_ofconnections_to_fail}    600
${margin_of_error}    0.05    # percentage

*** Test Cases ***
Bug_2429
    [Documentation]    Using the "nc" tool, a number of connections to the ${openflow_port}
    ...    will be opened and closed to simulate a failed OF handshake. The java threadcount
    ...    will be compared before and after to ensure that there are no thread leaks. Since
    ...    it's reasonable for other valid threads to be started (or stopped) during the test
    ...    a larger number of failed connections will be used and a small margin of error will
    ...    determine if the test is a PASS or FAIL
    Log Environment Details
    ${controller_pid}=    Get Process ID Based On Regex On Remote System    ${CONTROLLER}    java.*distribution.*karaf    ${CONTROLLER_USER}
    Should Match Regexp    ${controller_pid}    [0-9]+    PID was not discovered
    ${starting_thread_count}=    Get Process Thread Count On Remote System    ${CONTROLLER}    ${controller_pid}    ${CONTROLLER_USER}
    Repeat Keyword    ${number_ofconnections_to_fail}    Start Process    nc    -w    1    ${CONTROLLER}
    ...    ${openflow_port}
    Log Environment Details
    ${ending_thread_count}=    Get Process Thread Count On Remote System    ${CONTROLLER}    ${controller_pid}    ${CONTROLLER_USER}
    Log Environment Details
    Log    starting count: ${starting_thread_count}\nending count: ${ending_thread_count}
    ${acceptable_thread_count}=    Evaluate    ${starting_thread_count} + (${number_of_connections_to_fail} * ${margin_of_error})
    Should Be True    ${ending_thread_count} <= ${acceptable_thread_count}    Final thread count of ${ending_thread_count} exceeds acceptable count: ${acceptable_thread_count}

*** Keywords ***
Log Environment Details
    [Documentation]    Will display relevant details of the test environement to help aid debugging efforts if
    ...    needed in the future.
    ${output}=    Get Process ID Based On Regex On Remote System    ${CONTROLLER}    java.*distribution.*karaf    ${CONTROLLER_USER}
    Log    ${output}
    ${output}=    Run Command On Remote System    ${CONTROLLER}    netstat -na | grep 6633    ${CONTROLLER_USER}
    Log    ${output}
