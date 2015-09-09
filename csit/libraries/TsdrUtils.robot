*** Settings ***
Library           OperatingSystem
Resource          Utils.robot
Variables           ../variables/Variables.py


*** Variables ***
${HBASE_CLIENT}    /tmp/Hbase/hbase-0.94.15/bin
${final}          ${EMPTY}

*** Keywords ***
Start Tsdr Suite
    [Arguments]    ${switch}=ovsk
    [Documentation]    TSDR specific setup/cleanup work that can be done safely before any system
    ...    is run.
    Clean Mininet System
    ${mininet_conn_id1}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${mininet_conn_id1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    ${start}=    Set Variable    sudo mn --controller=remote,ip=${CONTROLLER} --topo=linear,3 --switch ${switch},protocols=OpenFlow13
    Log    ${start}
    Write    ${start}
    Read Until    mininet>

Stop Tsdr Suite
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Switch Connection    ${mininet_conn_id1}
    Read
    Write    exit
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Close Connection

Initialize the HBase for TSDR
    [Documentation]    Install and initialize the tsdr tables on HBase Server
    ${hbase_server}=    Run Command On Remote System    ${CONTROLLER}    export JAVA_HOME=/usr && ${HBASE_CLIENT}/start-hbase.sh    ${MININET_USER}    ${prompt_timeout}=120
    Log    ${hbase_server}
    ${hbase_process}=    Run Command On Remote System    ${CONTROLLER}    ps -ef | grep HMaster
    Log    ${hbase_process}

Stop the HBase Server
    [Documentation]    Stop the HBase server
    ${hbase_server}=    Run Command On Remote System    ${CONTROLLER}    export JAVA_HOME=/usr && ${HBASE_CLIENT}/stop-hbase.sh    ${MININET_USER}    ${prompt_timeout}=90
    Log    ${hbase_server}

Configure the Queue on Switch
    [Arguments]    ${queue_interface}    ${user}=${MININET_USER}    ${prompt_timeout}=120s
    [Documentation]    Configure the 2 queues on specified openvswitch interface
    Log    Configure the queue on ${queue_interface}
    ${output}=    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set port ${queue_interface} qos=@newqos -- --id=@newqos create qos type=linux-htb other-config:max-rate=200000000 queues=0=@q0,1=@q1,2=@q2 -- --id=@q0 create queue other-config:min-rate=100000 other-config:max-rate=200000 -- --id=@q1 create queue other-config:min-rate=10001 other-config:max-rate=300000 -- --id=@q2 create queue other-config:min-rate=300001 other-config:max-rate=200000000    ${MININET_USER}    ${prompt_timeout}=90
    Log    ${output}

Query the Data from HBaseClient
    [Arguments]    ${query}    ${remote}=${CONTROLLER}    ${user}=${MININET_USER}    ${prompt_timeout}=120s
    [Documentation]    Execute the HBase Query and return the result
    Log    Attempting to execute ${query} on ${remote} via HbaseClient
    ${conn_id}=    Open Connection    ${remote}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${prompt_timeout}
    Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    export JAVA_HOME=/usr
    Write    ${HBASE_CLIENT}/hbase shell
    Read Until    hbase(main):001:0>
    Write    ${query}
    ${output}=    Read Until    hbase(main):
    Write    exit
    LOG    ${output}
    Comment    ${output}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    Close Connection
    [Return]    ${output}

Verify the Metric is Collected?
    [Arguments]    ${tsdr_cmd}    ${metric}    ${remote}=${CONTROLLER}    ${user}=${MININET_USER}    ${prompt_timeout}=120s
    [Documentation]    Verify the ${tsdr_cmd} output contains ${metric}
    Open Karaf Console    ${remote}    ${KARAF_SHELL_PORT}    ${prompt_timeout}
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${remote}    ${KARAF_SHELL_PORT}    ${prompt_timeout}
    Close Karaf Console
    Should Contain    ${output}    ${metric}

Prepare HBase Filter
    [Arguments]    ${left_str}    ${right_str}    ${connector}
    [Documentation]    Prepare the Hbase Filter from Tsdr List output
    ${left_str}=    Remove Space on String    ${left_str}
    ${right_str}=    Remove Space on String    ${right_str}    1
    ${x}=    Run Keyword If    '${left_str}' == 'MetricID'    Catenate    ${SPACE}    _    ELSE IF
    ...    '${left_str}' == 'ObjectKeys'    Catenate    ${right_str}    _    ELSE IF    '${left_str}' == 'TimeStamp'
    ...    Get Epoch Time    ${right_str}    ELSE    Catenate    ${SPACE}
    [Return]    ${x}

Create the Hbase table row
    [Arguments]    ${tsdr_line}    ${metrics}
    [Documentation]    Create the Hbase table row from tsdr:list
    @{words}=    Split String    ${tsdr_line}    |
    : FOR    ${li}    IN    @{words}
    \    ${key}=    Fetch From Left    ${li}    =
    \    ${value}=    Fetch From Right    ${li}    =
    \    ${each_value}=    Prepare HBase Filter    ${key}    ${value}    _
    \    ${final}=    Concatenate the String    ${final}    ${each_value}
    ${query}=    Concatenate the String    ${metrics}    ${final}
    ${query}=    Remove Space on String    ${query}
    [Return]    ${query}

Query Metrics on H2 Datastore
    [Arguments]    ${category}    ${attribute}    ${nodeid}=openflow:1
    [Documentation]    Generate the JDBC query for H2 Datastore
    ${h2_query}=    Concatenate the String    jdbc:query metric "select * from Metric where MetricCategory=    '${category}' and
    ${h2_query}=    Concatenate the String    ${h2_query}    MetricName = '${attribute}' and NODEID = '${nodeid}' order by ID desc limit 5"
    Open Karaf Console    ${CONTROLLER}    ${KARAF_SHELL_PORT}    timeout=30
    ${output}=    Issue Command On Karaf Console    ${h2_query}
    Close Karaf Console
    [Return]    ${output}

Generate HBase Query
    [Arguments]    ${table}    ${filter}
    [Documentation]    Scan the Hbase Table with Filter
    ${hbase_query}=    Concatenate the String    scan    '${table}'
    ${hbase_query}=    Concatenate the String    ${hbase_query}    ,{ FILTER =>\"(RowFilter(=,
    ${hbase_query}=    Concatenate the String    ${hbase_query}    'regexstring:${filter}*\'))\",LIMIT=>10}
    [Return]    ${hbase_query}

Get Metrics Value
    [Arguments]    ${tsdr_line}
    [Documentation]    Get Metric Value from tsdr:list
    ${value}=    Fetch From Right    ${tsdr_line}    |
    ${value}=    Replace String    ${value}    MetricValue    value
    ${value}=    Replace String    ${value}    [m    ${EMPTY}
    ${value}=    Replace String    ${value}    =    \=
    ${value}=    Remove Space on String    ${value}
    ${value}=    Convert to String    ${value}
    [Return]    ${value}

Verify the Metrics Attributes on Hbase Client
    [Arguments]    ${attribute}    ${rowfilter}    ${table}=PortStats
    [Documentation]    Verification on Metrics attributes on Hbase Client
    ${pattern}=    Concatenate the String    ${attribute}    _
    ${pattern}=    Concatenate the String    ${pattern}    ${rowfilter}
    ${pattern}=    Remove Space on String    ${pattern}
    ${query}=    Generate HBase Query    ${table}    ${pattern}
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)${attribute}
