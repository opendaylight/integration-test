*** Settings ***
Documentation     Cbench Latency and Throughput tests can be run from an external
...               cbench.
...               If cbench is run with a medium number of switches or higher (e.g. 32+)
...               the normal openflow operations seem to break.
...               BUG: https://bugs.opendaylight.org/show_bug.cgi?id=2897
Suite Setup       Cbench Suite Setup
Test Teardown     Log Results As Zero If Cbench Timed Out
Force Tags        cbench
Library           String
Library           Process
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${log_level}      ERROR
${throughput_threshold}    30000
${latency_threshold}    10000
${switch_count}    16
${duration_in_secs}    10
${loops}          10
${num_of_unique_macs}    100
${start_delay}    5000
${test_delay}     0
${of_port}        6633
${cbench_system}    ${TOOLS_SYSTEM_IP}
${cbench_executable}    /usr/local/bin/cbench
${throughput_results_file}    throughput.csv
${latency_results_file}    latency.csv

*** Test Cases ***
Cbench Latency Test
    [Documentation]    cbench executed in default latency mode. Test parameters have defaults, but can be overridden
    ...    on the pybot command line
    [Tags]    latency
    [Timeout]    ${test_timeout}
    Log    Cbench tests using ${loops} iterations of ${duration_in_secs} second tests. Switch Count: ${switch_count}. Unique MACS to cycle: ${num_of_unique_macs}
    Run Cbench And Log Results    -m ${duration_in_ms} -M ${num_of_unique_macs} -S ${switch_count} -l ${loops} -D ${start_delay} -p ${of_port}    ${latency_threshold}    ${latency_results_file}
    # We have to give some time for the controller to recover. See bug 6176.
    Sleep    ${test_delay}

Cbench Throughput Test
    [Documentation]    cbench executed in throughput mode (-t). Test parameters have defaults, but can be overridden
    ...    on the pybot command line
    [Tags]    throughput
    [Timeout]    ${test_timeout}
    Log    Cbench tests using ${loops} iterations of ${duration_in_secs} second tests. Switch Count: ${switch_count}. Unique MACS to cycle: ${num_of_unique_macs}
    Run Cbench And Log Results    -t -m ${duration_in_ms} -M ${num_of_unique_macs} -S ${switch_count} -l ${loops} -D ${start_delay} -p ${of_port}    ${throughput_threshold}    ${throughput_results_file}
    # We have to give some time for the controller to recover. See bug 6176.
    Sleep    ${test_delay}

Rerun Latency Test To Check Bug 6176
    [Documentation]    cbench executed in latency mode to see if controller is healthy
    [Tags]    latency
    [Timeout]    ${test_timeout}
    Log    Cbench tests using ${loops} iterations of ${duration_in_secs} second tests. Switch Count: ${switch_count}. Unique MACS to cycle: ${num_of_unique_macs}
    Run Cbench And Log Results    -m ${duration_in_ms} -M ${num_of_unique_macs} -S ${switch_count} -l ${loops} -D ${start_delay} -p ${of_port}    ${latency_threshold}    bug.csv
    # We have to give some time for the controller to recover. See bug 6176.
    Sleep    ${test_delay}
    [Teardown]    Report_Failure_Due_To_Bug    6176

*** Keywords ***
Run Cbench And Log Results
    [Arguments]    ${cbench_args}    ${average_threshold}    ${output_filename}=results.csv
    ##If the cbench command fails to return, the keyword to run it will time out.    The test tear
    ##down can catch this problem and log the results as zero.    However, we need to know which
    ##file to log to, so setting it as a suite variable here.
    Set Suite Variable    ${output_filename}
    ${output}=    Run Keyword If    "${cbench_system}" == "localhost"    Run    ${cbench_executable} -c ${ODL_SYSTEM_IP} ${cbench_args}
    ...    ELSE    Run Command On Remote System    ${cbench_system}    ${cbench_executable} -c ${ODL_SYSTEM_IP} ${cbench_args}    prompt_timeout=${test_timeout}    return_stdout=False
    ...    return_stderr=True
    Log    ${output}
    Should Contain    ${output}    RESULT
    ${result_line}=    Get Lines Containing String    ${output}    RESULT
    @{results_list}=    Split String    ${result_line}
    Log    ${results_list[5]}
    Log    ${results_list[7]}
    @{result_name_list}=    Split String    ${results_list[5]}    /
    @{result_value_list}=    Split String    ${results_list[7]}    /
    ${num_stats}=    Get Length    ${result_name_list}
    FOR    ${i}    IN RANGE    0    ${num_stats}
        Log    ${result_name_list[${i}]} :: ${result_value_list[${i}]}
    END
    ${min}=    Set Variable    ${result_value_list[${0}]}
    ${max}=    Set Variable    ${result_value_list[${1}]}
    ${average}=    Set Variable    ${result_value_list[${2}]}
    ${stdev}=    Set Variable    ${result_value_list[${3}]}
    ${date}=    Get Time    d,m,s
    Log    CBench Result: ${date},${cbench_args},${min},${max},${average},${stdev}
    Log Results And Determine Status    ${min}    ${max}    ${average}    ${average_threshold}    ${output_filename}

Cbench Suite Setup
    Wait Until Keyword Succeeds    3x    1s    KarafKeywords.Issue Command On Karaf Console    log:set ${log_level}
    Append To File    ${latency_results_file}    LATENCY_MIN,LATENCY_MAX,LATENCY_AVERAGE\n
    Append To File    ${throughput_results_file}    THROUGHPUT_MIN,THROUGHPUT_MAX,THROUGHPUT_AVERAGE\n
    ${duration_in_ms}    Evaluate    ${duration_in_secs} * 1000
    Set Suite Variable    ${duration_in_ms}
    ##Setting the test timeout dynamically in case larger values on command line override default
    ${test_timeout}    Evaluate    (${loops} * ${duration_in_secs}) * 1.5
    Set Suite Variable    ${test_timeout}
    Run Keyword If    "${cbench_system}" == "localhost"    OperatingSystem.File Should Exist    ${cbench_executable}
    ...    ELSE    Verify File Exists On Remote System    ${cbench_system}    ${cbench_executable}
    Should Be True    ${loops} >= 2    If number of loops is less than 2, cbench will not run
    Verify Feature Is Installed    odl-openflowplugin-drop-test
    Issue Command On Karaf Console    dropallpacketsrpc on

Log Results And Determine Status
    [Arguments]    ${min}    ${max}    ${average}    ${threshold}    ${output_file}
    Append To File    ${output_file}    ${min},${max},${average}\n
    Should Be True    ${average} > ${threshold}    ${average} flow_mods per/sec did not exceed threshold of ${threshold}

Log Results As Zero If Cbench Timed Out
    Run Keyword If Timeout Occurred    Log Results And Determine Status    0    0    0    0    ${output_filename}
