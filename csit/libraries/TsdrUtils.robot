*** Settings ***
Library           RequestsLibrary
Library           XML
Library           OperatingSystem
Library           String
Library           Collections
Library           DateTime
Resource          Utils.robot
Variables         ../variables/Variables.py
Library           json
Library           HttpLibrary.HTTP
Library           Process

*** Variables ***
${HBASE_CLIENT}    /tmp/Hbase/hbase-0.94.27/bin
${CASSANDRA_CLIENT}    /tmp/cassandra/apache-cassandra-2.1.14/bin
${final}          ${EMPTY}
${prompt_timeout}    ${EMPTY}
${CASSANDRA_DB_PATH}    /tmp/cassandra/apache-cassandra-2.1.14/
${metric_path}    metricpath
${metric_val}     metricval
${metric_log}     metriclog
${temp_metric_val}    temp_metric_val
${NETFLOW_PORT}    2055
${KARAF_PATH}     ${WORKSPACE}/${BUNDLEFOLDER}
${TSDR_PATH}      ${KARAF_PATH}/tsdr
${PURGE_PATH}     ${KARAF_PATH}/etc/tsdr.data.purge.cfg
${SNMP_PATH}      ${KARAF_PATH}/etc/tsdr.snmp.cfg
${SNMP_COMMUNITY}    mib2dev\/if-mib
&{HEADERS_QUERY}    Content-Type=application/json    Content-Type=application/json
&{OPER_STATUS}    up=1    down=2    testing=3    unknown=4    dormant=5    notPresent=6    lowerLayerDown=7
&{syslog_facility}    kern=0
${MESSAGE}        Oct 29 18:10:31: ODL: %STKUNIT0-M:CP %IFMGR-5-ASTATE_UP: Changed interface Admin state to up: Te 0/0
${MESSAGE_PATTERN}    Changed interface

*** Keywords ***
Start Tsdr Suite
    [Arguments]    ${switch}=ovsk    ${switch_count}=3
    [Documentation]    TSDR specific setup/cleanup work that can be done safely before any system.
    ...    is run.
    Clean Mininet System
    ${mininet_conn_id1}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=120s
    Set Suite Variable    ${mininet_conn_id1}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    ${start}=    Set Variable    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo=linear,${switch_count} --switch ${switch},protocols=OpenFlow13
    Log    ${start}
    Write    ${start}
    Read Until    mininet>

Configure Netflow
    [Arguments]    ${user}=${TOOLS_SYSTEM_USER}
    [Documentation]    Configure Netflow
    ${output}=    Run Command On Controller    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl -- set Bridge s1 netflow=@nf -- --id=@nf create NetFlow target=\\"${ODL_SYSTEM_IP}:${NETFLOW_PORT}\\" active-timeout=10    ${user}

Ping All Hosts
    [Arguments]    ${switch}=ovsk
    [Documentation]    Ping between all hosts in mininet topology.
    Switch Connection    ${mininet_conn_id1}
    Write    pingall
    Read Until    mininet>

Ping Pair Hosts
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Ping between ${host1} and ${host2}
    Switch Connection    ${mininet_conn_id1}
    Write    pingpair ${host1} ${host2}
    Read Until    mininet>

Ping Pair Hosts Hbase
    [Arguments]    ${pattern}
    [Documentation]    Ping between h1 and h2 and check Hbase
    Ping Pair Hosts    h1    h2
    ${query_output}=    Query the Data from HBaseClient    count 'NETFLOW'
    Should Match Regexp    ${query_output}    ${pattern}

Ping Pair Hosts Cassandra
    [Arguments]    ${pattern}
    [Documentation]    Ping between h1 and h2 and check Cassandra
    Ping Pair Hosts    h1    h2
    ${query_output}=    Count Cassandra rows    select count(*) from tsdr.metriclog;
    Should Match Regexp    ${query_output}    ${pattern}

Ping Pair Hosts HSQLDB
    [Arguments]    ${pattern}
    [Documentation]    Iperf between h1 and h2 and check Cassandra
    Ping Pair Hosts    h1    h2
    ${query_output}=    Issue Command On Karaf Console    tsdr:list NETFLOW | wc -l
    Should Match Regexp    ${query_output}    ${pattern}

Stop Tsdr Suite
    [Documentation]    Cleanup/Shutdown work that should be done at the completion of all
    ...    tests
    Switch Connection    ${mininet_conn_id1}
    Read
    Write    exit
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Close Connection

Purge Data
    [Arguments]    ${HOST}=127.0.0.1    ${purge_enabled}=true    ${purge_time}=00:00:00    ${purge_interval}=1400    ${retention}=0
    [Documentation]    Write Purge file and copy it to directory.127.0.0.1 refers local controller
    Create File    purge.cfg    \#TSDR Project Configuration file
    Append To File    purge.cfg    \n
    Append To File    purge.cfg    host=${HOST}
    Append To File    purge.cfg    \n
    Append To File    purge.cfg    data_purge_enabled=${purge_enabled}
    Append To File    purge.cfg    \n
    Append To File    purge.cfg    data_purge_time=${purge_time}
    Append To File    purge.cfg    \n
    Append To File    purge.cfg    data_purge_interval_in_minutes=${purge_interval}
    Append To File    purge.cfg    \n
    Append To File    purge.cfg    retention_time_in_hours=${retention}
    Append To File    purge.cfg    \n
    Move File    purge.cfg    ${PURGE_PATH}

Initialize the HBase for TSDR
    [Documentation]    Install and initialize the tsdr tables on HBase Server
    ${hbase_server}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    export JAVA_HOME=/usr && ${HBASE_CLIENT}/start-hbase.sh    ${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120
    Log    ${hbase_server}
    ${hbase_process}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -ef | grep HMaster
    Log    ${hbase_process}

Stop the HBase Server
    [Documentation]    Stop the HBase server
    ${hbase_server}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    export JAVA_HOME=/usr && ${HBASE_CLIENT}/stop-hbase.sh    ${TOOLS_SYSTEM_USER}    ${prompt_timeout}=90
    Log    ${hbase_server}

Configure the Queue on Switch
    [Arguments]    ${queue_interface}    ${user}=${TOOLS_SYSTEM_USER}
    [Documentation]    Configure the 2 queues on specified openvswitch interface
    Log    Configure the queue on ${queue_interface}
    ${output}=    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set port ${queue_interface} qos=@newqos -- --id=@newqos create qos type=linux-htb other-config:max-rate=200000000 queues=0=@q0,1=@q1,2=@q2 -- --id=@q0 create queue other-config:min-rate=100000 other-config:max-rate=200000 -- --id=@q1 create queue other-config:min-rate=10001 other-config:max-rate=300000 -- --id=@q2 create queue other-config:min-rate=300001 other-config:max-rate=200000000
    Log    ${output}

Query the Data from HBaseClient
    [Arguments]    ${query}    ${remote}=${ODL_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120s
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
    [Arguments]    ${tsdr_cmd}    ${metric}    ${remote}=${ODL_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120s
    [Documentation]    Verify the ${tsdr_cmd} output contains ${metric}
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${remote}    ${KARAF_SHELL_PORT}    ${prompt_timeout}
    Should Contain    ${output}    ${metric}

Prepare HBase Filter
    [Arguments]    ${left_str}    ${right_str}    ${connector}
    [Documentation]    Prepare the Hbase Filter from Tsdr List output
    ${left_str}=    Remove Space on String    ${left_str}
    ${right_str}=    Remove Space on String    ${right_str}    1
    ${x}=    Run Keyword If    '${left_str}' == 'MetricID'    Catenate    ${SPACE}    _
    ...    ELSE IF    '${left_str}' == 'ObjectKeys'    Catenate    ${right_str}    _
    ...    ELSE IF    '${left_str}' == 'TimeStamp'    Get Epoch Time    ${right_str}
    ...    ELSE    Catenate    ${SPACE}
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

Initialize Cassandra Tables
    [Arguments]    ${remote}=${ODL_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120s    ${key_table}=metricpath    ${val_table}=metricval
    [Documentation]    Truncate Existing tables in Cassandra to Start it fresh.
    Log    Attempting to truncate tables in Cassandra
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo rm -rf ${CASSANDRA_DB_PATH}${key_table}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo rm -rf ${CASSANDRA_DB_PATH}${val_table}
    ${conn_id}=    Open Connection    ${remote}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${prompt_timeout}
    Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    export JAVA_HOME=/usr
    Write    ${CASSANDRA_CLIENT}/cqlsh
    Read Until    cqlsh>
    Write    TRUNCATE tsdr.${key_table} ;
    Read Until    cqlsh>
    Write    TRUNCATE tsdr.${val_table} ;
    Read Until    cqlsh>
    Write    exit
    Close Connection

Initialize Cassandra Tables Metricval
    [Arguments]    ${remote}=${ODL_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120s    ${key_table}=metricpath    ${val_table}=metricval
    [Documentation]    Truncate Existing tables in Cassandra to Start it fresh
    Log    Attempting to truncate tables in Cassandra
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo rm -rf ${CASSANDRA_DB_PATH}${key_table}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo rm -rf ${CASSANDRA_DB_PATH}${val_table}
    ${conn_id}=    Open Connection    ${remote}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${prompt_timeout}
    Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    export JAVA_HOME=/usr
    Write    ${CASSANDRA_CLIENT}/cqlsh
    Read Until    cqlsh>
    Write    TRUNCATE tsdr.${val_table} ;
    Read Until    cqlsh>
    Write    exit
    Close Connection

Query Metrics on H2 Datastore
    [Arguments]    ${category}    ${attribute}    ${nodeid}=openflow:1
    [Documentation]    Generate the JDBC query for H2 Datastore
    ${h2_query}=    Concatenate the String    jdbc:query metric "select * from Metric where MetricCategory=    '${category}' and
    ${h2_query}=    Concatenate the String    ${h2_query}    MetricName = '${attribute}' and NODEID = '${nodeid}' order by ID desc limit 5"
    ${output}=    Issue Command On Karaf Console    ${h2_query}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    30
    [Return]    ${output}

Generate HBase Query
    [Arguments]    ${table}    ${filter}    ${metric}
    [Documentation]    Scan the Hbase Table with Filter
    ${hbase_query}=    Concatenate the String    scan    '${table}'
    ${hbase_query}=    Concatenate the String    ${hbase_query}    ,{ FILTER =>\"(RowFilter(=,
    ${hbase_query}=    Concatenate the String    ${hbase_query}    'regexstring:${filter}*\')) AND (RowFilter(=,
    ${hbase_query}=    Concatenate the String    ${hbase_query}    'regexstring:${metric}*\'))\",LIMIT=>10}
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
    ${query}=    Generate HBase Query    ${table}    ${rowfilter}    ${attribute}
    ${out}=    Query the Data from HBaseClient    ${query}
    Should Match Regexp    ${out}    (?mui)value

Verify the Metrics Attributes on Cassandra Client
    [Arguments]    ${pattern}
    [Documentation]    Verification on Metrics attributes on Cassandra Client
    @{metric_row}=    Find Metricval Keys    ${pattern}    metricpath
    ${keya}=    Get From List    ${metric_row}    1
    ${keyb}=    Get From List    ${metric_row}    2
    ${keya_bool}=    Evaluate    ${keya} < 0
    ${keya}=    Run Keyword If    '${keya_bool}' == 'True'    Catenate    SEPARATOR=    \\    ${keya}
    ...    ELSE    Catenate    ${keya}
    ${metricval}=    Create Temporary Key Info    ${keya} ${keyb}
    @{lines}=    Split to lines    ${metricval}
    ${mv_len}=    Get Length    ${lines}
    ${mv_len}=    Evaluate    ${mv_len} - 1
    ${found_line}=    Get From List    ${lines}    ${mv_len}
    @{split_line}=    Split String    ${found_line}    ${SPACE}
    ${metric_count}=    Get From List    ${split_line}    3
    [Return]    ${metric_count}

Form Portstats Query Pattern
    [Arguments]    ${metric}    ${node}    ${port}    ${attribute}
    [Documentation]    Used for geneating openflow metrics Queries for Cassandra.
    ${pattern}=    Concatenate the String    ${attribute}    .
    ${pattern}=    Concatenate the String    ${pattern}    ${metric}
    ${pattern}=    Concatenate the String    ${pattern}    .
    ${pattern}=    Concatenate the String    ${pattern}    ${node}
    ${pattern}=    Concatenate the String    ${pattern}    .
    ${pattern}=    Concatenate the String    ${pattern}    Node_${node}
    ${pattern}=    Concatenate the String    ${pattern}    .
    ${pattern}=    Concatenate the String    ${pattern}    NodeConnector_${node}:${port}
    ${pattern}=    Remove Space on String    ${pattern}
    [Return]    ${pattern}

Create Temporary Key Info
    [Arguments]    ${pattern}    ${remote}=${ODL_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120s    ${val_table}=metricval
    [Documentation]    Return rows matching keya and keyb
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    cat ${CASSANDRA_DB_PATH}${val_table}|grep "${pattern}"
    [Return]    ${output}

Verify Metric Val File
    [Documentation]    Returns Value for metric matching particular keya,keyb
    @{metricval}=    Read File and Return Split Lines    ${CASSANDRA_DB_PATH}${temp_metric_val}
    ${mv_len}=    Get Length    ${metricval}
    ${mv_len}=    Evaluate    ${mv_len} - 1
    ${found_line}=    Get From List    ${metricval}    ${mv_len}
    @{split_line}=    Split String    ${found_line}    ${SPACE}
    ${metric_count}=    Get From List    ${split_line}    3
    [Return]    ${metric_count}

Verify Metric log File
    [Arguments]    ${metric_log}    ${pattern}
    [Documentation]    Returns Value for lines in Metriclog matching the pattern
    ${contents}=    Grep From File    ${CASSANDRA_DB_PATH}${temp_metric_val}    ${pattern}
    [Return]    ${contents}

Grep From File
    [Arguments]    ${file}    ${pattern}
    [Documentation]    Use cat to grep from the file and return the output
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    cat ${file} | ${pattern}
    [Return]    ${output}

Find Metricval Keys
    [Arguments]    ${pattern}    ${file}
    [Documentation]    Return list element which has the particular pattern.
    ${metric_grep}=    Grep From File    ${TSDR_PATH}/tsdrKeyCache.txt    ${pattern}
    @{split_line}=    Split String    ${metric_grep}    |
    ${keypath}=    Get From List    ${split_line}    0
    [Return]    @{split_line}

Copy TSDR tables
    [Arguments]    ${remote}=${ODL_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120s    ${key_table}=metricpath    ${val_table}=metricval
    [Documentation]    Copy TSDR files to external File system for text processing.
    Log    Attempting to truncate tables in Cassandra
    ${conn_id}=    Open Connection    ${remote}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${prompt_timeout}
    Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    export JAVA_HOME=/usr
    Write    sudo ${CASSANDRA_CLIENT}/cqlsh
    Read Until    cqlsh>
    Write    COPY tsdr.${key_table} TO '${CASSANDRA_DB_PATH}${key_table}' WITH DELIMITER = ' ';
    Read Until    cqlsh>
    Write    COPY tsdr.${val_table} TO '${CASSANDRA_DB_PATH}${val_table}' WITH DELIMITER = ' ';
    Read Until    cqlsh>
    Write    exit
    Close Connection

Issue Cassandra Query
    [Arguments]    ${query}    ${output}    ${remote}=${ODL_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120s
    [Documentation]    Issue query in cqlsh and match it with output which is passed as a argument
    ${conn_id}=    Open Connection    ${remote}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${prompt_timeout}
    Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    export JAVA_HOME=/usr
    Write    ${CASSANDRA_CLIENT}/cqlsh
    Read Until    cqlsh>
    ${query_output}=    Write    ${query}
    ${query_output}=    Read Until    cqlsh>
    ${str_output}=    Convert To String    ${output}
    Should Contain    ${query_output}    ${str_output}
    Write    exit
    Close Connection

Count Cassandra rows
    [Arguments]    ${query}    ${remote}=${ODL_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${prompt_timeout}=120s
    [Documentation]    Issue query in cqlsh and match it with output which is passed as a argument
    ${conn_id}=    Open Connection    ${remote}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${prompt_timeout}
    Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    export JAVA_HOME=/usr
    Write    ${CASSANDRA_CLIENT}/cqlsh
    Read Until    cqlsh>
    ${query_output}=    Write    ${query}
    ${query_output}=    Read Until    cqlsh>
    Write    exit
    Close Connection
    [Return]    ${query_output}

Read File and Return Split Lines
    [Arguments]    ${filename}
    [Documentation]    Reads the file and returns each line as list
    ${contents}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    cat ${filename}
    @{lines}=    Split to lines    ${contents}
    [Return]    @{lines}

Get Stats XML
    [Arguments]    ${query}    ${xpath}
    [Documentation]    Parse the xml output and returns it.
    ${sid}=    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    headers=${SEND_ACCEPT_XML_HEADERS}    auth=${AUTH}
    ${resp}=    RequestsLibrary.Get Request    session    ${query}    headers=${SEND_ACCEPT_XML_HEADERS}
    ${resp_xml}=    Parse XML    ${resp.content}
    ${id1}=    Get Element Text    ${resp_xml}    ${xpath}
    Delete All Sessions
    [Return]    ${id1}

Return all XML matches
    [Arguments]    ${query}    ${xpath}
    [Documentation]    Returns all the values from xpath
    ${sid}=    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    headers=${SEND_ACCEPT_XML_HEADERS}    auth=${AUTH}
    ${resp}=    RequestsLibrary.Get Request    session    ${query}    headers=${SEND_ACCEPT_XML_HEADERS}
    ${resp_xml}=    Parse XML    ${resp.content}
    @{id1}=    Get Elements Texts    ${resp_xml}    ${xpath}
    Delete All Sessions
    [Return]    @{id1}

Compare Tsdr XML Metrics
    [Arguments]    ${xml}    ${tsdr}    ${deviation}=10
    [Documentation]    Compares xml metrics from openflow plugin with TSDR metric values
    ${val_max}=    Evaluate    ${xml}*${deviation}/100
    ${val_diff}=    Evaluate    ${tsdr} - ${xml}
    ${find_negative}=    Evaluate    ${val_diff} < 0
    ${val_diff}=    Run Keyword If    '${find_negative}' == 'True'    Evaluate    ${val_diff}*-1
    ...    ELSE    Evaluate    ${val_diff}*1
    Should Be True    ${val_diff} <= ${val_max}

Generate Syslog
    [Arguments]    ${facility}
    [Documentation]    Uses netcat to generate logs and send it to port ${ODL_SYSTEM_IP}:1514
    Run    echo "<${facility}>${MESSAGE}" | nc -w 4 -u ${ODL_SYSTEM_IP} 1514

Verify Metric Val File For Syslog
    [Documentation]    Returns Value for metric matching particular keya,keyb
    @{metricval}=    Read File and Return Split Lines    ${CASSANDRA_DB_PATH}${temp_metric_val}
    [Return]    ${metricval}

Verify the Metrics Syslog on Cassandra Client
    [Arguments]    ${pattern}
    [Documentation]    Getting the keya and keyb for a particular syslog agent and create a temporary file from metriclog
    @{metric_row}=    Find Metricval Keys    ${pattern}    metricpath
    ${keya}=    Get From List    ${metric_row}    1
    ${keyb}=    Get From List    ${metric_row}    2
    ${keya_bool}=    Evaluate    ${keya} < 0
    ${keya}=    Run Keyword If    '${keya_bool}' == 'True'    Catenate    SEPARATOR=    \\    ${keya}
    ...    ELSE    Catenate    ${keya}
    ${metric_log}=    Create Temporary Key Info    ${keya} ${keyb}    val_table=metriclog
    [Return]    ${metric_log}

Iterating over metricpath
    [Documentation]    Used to traverse over metricpath file and traverse over metricpath file and get the keys
    @{mp_lines}=    Read File and Return Split Lines    ${CASSANDRA_DB_PATH}${metric_path}
    : FOR    ${line}    IN    @{mp_lines}
    \    @{split_line}=    Split String    ${line}    ${SPACE}
    \    ${keya}=    Get From List    ${split_line}    1
    \    ${keyb}=    Get From List    ${split_line}    2
    \    Iterating over metricval    ${keya}    ${keyb}

Iterating over metricval
    [Arguments]    ${keya}    ${keyb}
    [Documentation]    Used to traverse over metricval file and check if keya and keyb are present.
    ${mv_contents}=    OperatingSystem.Get File    ${CASSANDRA_DB_PATH}${metric_val}
    Should Contain    ${mv_contents}    ${keya}    ${keyb}

Check Metric path
    [Arguments]    ${pattern}
    [Documentation]    Count the number of rows in metricpath and compare with the pattern.
    ${query_output}=    Count Cassandra rows    select count(*) from tsdr.metricpath;
    Should Match Regexp    ${query_output}    ${pattern}

Check HSQLDB
    [Arguments]    ${pattern}    ${TYPE}
    [Documentation]    Count the number of rows in HSQLDB with Metric ${TYPE}
    ${output}=    Issue Command On Karaf Console    tsdr:list ${TYPE}
    Should Match Regexp    ${output}    ${pattern}

Check Metric Val
    [Arguments]    ${pattern}
    [Documentation]    Count the number of rows in metricval table and compare with the pattern.
    ${query_output}=    Count Cassandra rows    select count(*) from tsdr.metricval;
    Should Match Regexp    ${query_output}    ${pattern}

Check Metric Log
    [Arguments]    ${pattern}
    [Documentation]    Count the number of rows in metriclog and compare with the pattern.
    ${query_output}=    Count Cassandra rows    select count(*) from tsdr.metriclog;
    Should Match Regexp    ${query_output}    ${pattern}

Generate TSDR Query
    [Arguments]    ${DC}=    ${MN}=    ${NID}=    ${RK}=    ${from}=0    ${until}=now
    [Documentation]    Issues TSDR Query and returns the list
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_QUERY}
    ${resp}=    RequestsLibrary.Get Request    session    /tsdr/metrics/query?tsdrkey="[NID=${NID}][DC=${DC}][MN=${MN}][RK=${RK}]"&from=${from}&until=${until}    headers=${HEADERS_QUERY}
    @{convert}=    Parse Json    ${resp.content}
    Delete All Sessions
    [Return]    @{convert}

Generate TSDR NBI
    [Arguments]    ${DC}=    ${MN}=    ${NID}=    ${RK}=    ${from}=0    ${until}=now
    ...    ${datapts}=1000000
    [Documentation]    Issues TSDR Query and returns the list
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_QUERY}
    ${resp}=    RequestsLibrary.Get Request    session    /tsdr/nbi/render?target="[NID=${NID}][DC=${DC}][MN=${MN}][RK=${RK}]"&from=${from}&until=${until}&maxDataPoints=${datapts}    headers=${HEADERS_QUERY}
    @{convert}=    Parse Json    ${resp.content}
    ${dict_convert}=    Convert To Dictionary    @{convert}
    @{dict}=    Get Dictionary Values    ${dict_convert}
    @{datapoints_list}=    Convert to List    @{dict}[0]
    Delete All Sessions
    [Return]    @{datapoints_list}

Extract PORTSTATS RecordKeys
    [Arguments]    ${Record_keys}
    [Documentation]    Dissect Record keys for Portstats
    ${node_dict}=    Get From List    ${Record_keys}    0
    ${nc_dict}=    Get From List    ${Record_keys}    1
    ${NODE}=    Get From Dictionary    ${node_dict}    keyValue
    ${NC}=    Get From Dictionary    ${nc_dict}    keyValue
    ${rk_val}=    Set Variable    Node:${NODE},NodeConnector:${NC}
    [Return]    ${rk_val}

Extract QUEUESTATS RecordKeys
    [Arguments]    ${Record_keys}
    [Documentation]    Dissect Record keys for Queuestats
    ${node_dict}=    Get From List    ${Record_keys}    0
    ${connect_dict}=    Get From List    ${Record_keys}    1
    ${queue_dict}=    Get From List    ${Record_keys}    2
    ${NODE}=    Get From Dictionary    ${node_dict}    keyValue
    ${CONNECT}=    Get From Dictionary    ${connect_dict}    keyValue
    ${QUEUE}=    Get From Dictionary    ${queue_dict}    keyValue
    ${rk_val}=    Set Variable    Node:${NODE},NodeConnector:${CONNECT},Queue:${QUEUE}
    [Return]    ${rk_val}

Extract FLOWSTATS RecordKeys
    [Arguments]    ${Record_keys}
    [Documentation]    Dissect Record keys for Flowstats
    ${node_dict}=    Get From List    ${Record_keys}    0
    ${table_dict}=    Get From List    ${Record_keys}    1
    ${flow_dict}=    Get From List    ${Record_keys}    2
    ${NODE}=    Get From Dictionary    ${node_dict}    keyValue
    ${TABLE}=    Get From Dictionary    ${table_dict}    keyValue
    ${FLOW}=    Get From Dictionary    ${flow_dict}    keyValue
    ${rk_val}=    Set Variable    Node:${NODE},Table:${TABLE},Flow:${FLOW}
    [Return]    ${rk_val}

Extract FLOWTABLESTATS RecordKeys
    [Arguments]    ${Record_keys}
    [Documentation]    Dissect Record keys for Flowtablestats
    ${node_dict}=    Get From List    ${Record_keys}    0
    ${table_dict}=    Get From List    ${Record_keys}    1
    ${NODE}=    Get From Dictionary    ${node_dict}    keyValue
    ${TABLE}=    Get From Dictionary    ${table_dict}    keyValue
    ${rk_val}=    Set Variable    Node:${NODE},Table:${TABLE}
    [Return]    ${rk_val}

Extract Row Values from TSDR Query
    [Arguments]    ${row_dict}    ${tsdr_row}    ${nbi_row}    ${DATA_CATEGORY}
    [Documentation]    Extract the row values from query and generate it in DB format
    ${nbi_value}=    Get From List    ${nbi_row}    0
    ${nbi_time}=    Get From List    ${nbi_row}    1
    ${MN}=    Get From Dictionary    ${row_dict}    metricName
    ${MV}=    Get From Dictionary    ${row_dict}    metricValue
    ${NID}=    Get From Dictionary    ${row_dict}    nodeID
    ${RK}=    Get From Dictionary    ${row_dict}    recordKeys
    ${time}=    Get From Dictionary    ${row_dict}    timeStamp
    ${DC}=    Get From Dictionary    ${row_dict}    tsdrDataCategory
    ${RK_VAL}=    Run Keyword If    '${DATA_CATEGORY}'=='PORTSTATS'    Extract PORTSTATS RecordKeys    ${RK}
    ...    ELSE IF    '${DATA_CATEGORY}'=='FLOWSTATS'    Extract FLOWSTATS RecordKeys    ${RK}
    ...    ELSE IF    '${DATA_CATEGORY}'=='FLOWTABLESTATS'    Extract FLOWTABLESTATS RecordKeys    ${RK}
    ...    ELSE IF    '${DATA_CATEGORY}'=='QUEUESTATS'    Extract QUEUESTATS RecordKeys    ${RK}
    ${epoch_time}=    Convert Date    ${time}    epoch    date_format=%a %b %d %H:%M:%S %Z %Y
    ${epoch_time_int}=    Convert To Integer    ${epoch_time}
    Should Match    ${tsdr_row}    *${NID}*
    Should Match    ${tsdr_row}    *${DC}*
    Should Match    ${tsdr_row}    *${MN}*
    Should Match    ${tsdr_row}    *${RK_VAL}*
    Should Match    ${tsdr_row}    *[${MV}]*
    Should Match    ${tsdr_row}    *${epoch_time_int}*
    Should Be Equal As Numbers    ${nbi_time}    ${epoch_time_int}
    Should Be Equal As Numbers    ${nbi_value}    ${MV}

Evaluate Datasets Length
    [Arguments]    ${tsdr_lines}    ${query_output}    ${nbi_output}
    [Documentation]    Compare the outputs returned from all Data Stores
    ${query_count}=    Get Length    ${query_output}
    ${tsdr_count}=    Get Length    ${tsdr_lines}
    ${nbi_count}=    Get Length    ${nbi_output}
    Should Be Equal As Numbers    ${query_count}    ${tsdr_count}
    Should Be Equal As Numbers    ${nbi_count}    ${tsdr_count}

Evaluate Datasets Value
    [Arguments]    ${tsdr_lines}    ${query_output}    ${nbi_output}    ${TYPE}
    [Documentation]    Compare the outputs returned from all Data Stores
    : FOR    ${q_item}    ${t_item}    ${n_item}    IN ZIP    ${query_output}    ${tsdr_lines}
    ...    ${nbi_output}
    \    ${query_row}=    Extract Row Values from TSDR Query    ${q_item}    ${t_item}    ${n_item}    ${TYPE}
    : FOR    ${found_line}    IN    @{matching_list}
    \    @{split_line}=    Split String    ${found_line}    |
    \    ${hex_name}=    Get From List    ${split_line}    2
    \    ${if_desc}=    Decode Bytes To String    ${hex_name}    HEX
    \    Append To List    ${ifdesc_list}    ${if_desc}
    [Return]    @{ifdesc_list}

Write SNMP config
    [Arguments]    ${HOST}=127.0.0.1    ${community}=${SNMP_COMMUNITY}
    [Documentation]    Write SNMP Config File
    Create File    snmp.cfg    credentials=[${HOST},${community}]
    Append To File    snmp.cfg    \n
    Move File    snmp.cfg    ${SNMP_PATH}

Bringup Netflow
    [Documentation]    Brings up basic netflow setup .
    Verify Feature Is Installed    odl-tsdr-netflow-statistics-collector
    Wait Until Keyword Succeeds    24x    10 sec    Check Karaf Log Has Messages    NetFlow Data Colletor Initialized
    Start Tsdr Suite
    Ping All Hosts
    Configure Netflow

Collect Data from SNMP Agent
    [Arguments]    ${SNMP_IP}=127.0.0.1    ${SNMP_AGENT_COMM}=${SNMP_COMMUNITY}
    [Documentation]    Poll for SNMP Agent OID
    ${snmpagentinfo}    Create Dictionary    ip-address=${SNMP_IP}    community=${SNMP_AGENT_COMM}
    ${snmpagentcreate}    Create Dictionary    input=${snmpagentinfo}
    ${snmpagentcreate_json}=    json.dumps    ${snmpagentcreate}
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_QUERY}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/snmp:get-interfaces    data=${snmpagentcreate_json}
    ${convert}=    To Json    ${resp.content}
    @{dict1}=    Get Dictionary Keys    ${convert}
    ${dict1_0}=    Get From List    ${dict1}    0
    ${dict1_val}=    Get From Dictionary    ${convert}    ${dict1_0}
    @{ifEntry}=    Get From Dictionary    ${dict1_val}    ifEntry
    @{SNMP_ENTRY}=    Create List
    @{SNMP_VALUES}=    Create List
    : FOR    ${int}    IN    @{ifEntry}
    \    ${ifindex}=    Get From Dictionary    ${int}    ifIndex
    \    ${ifOutDiscards}=    Get From Dictionary    ${int}    ifOutDiscards
    \    ${ifInDiscards}=    Get From Dictionary    ${int}    ifInDiscards
    \    ${ifType}=    Get From Dictionary    ${int}    ifType
    \    ${ifInOctets}=    Get From Dictionary    ${int}    ifInOctets
    \    ${ifSpeed}=    Get From Dictionary    ${int}    ifSpeed
    \    ${ifOutQLen}=    Get From Dictionary    ${int}    ifOutQLen
    \    ${ifOutErrors}=    Get From Dictionary    ${int}    ifOutErrors
    \    ${ifPhysAddress}=    Get From Dictionary    ${int}    ifPhysAddress
    \    ${ifInUcastPkts}=    Get From Dictionary    ${int}    ifInUcastPkts
    \    ${ifOutNUcastPkts}=    Get From Dictionary    ${int}    ifOutNUcastPkts
    \    ${ifInErrors}=    Get From Dictionary    ${int}    ifInErrors
    \    ${ifOutOctets}=    Get From Dictionary    ${int}    ifOutOctets
    \    ${ifAdminStatus1}=    Get From Dictionary    ${int}    ifAdminStatus
    \    ${ifAdminStatus}=    Get From Dictionary    ${OPER_STATUS}    ${ifAdminStatus1}
    \    ${ifInUnknownProtos}=    Get From Dictionary    ${int}    ifInUnknownProtos
    \    ${ifOutUcastPkts}=    Get From Dictionary    ${int}    ifOutUcastPkts
    \    ${ifInNUcastPkts}=    Get From Dictionary    ${int}    ifInNUcastPkts
    \    ${ifMtu}=    Get From Dictionary    ${int}    ifMtu
    \    ${ifOperStatus1}=    Get From Dictionary    ${int}    ifOperStatus
    \    ${ifOperStatus}=    Get From Dictionary    ${OPER_STATUS}    ${ifOperStatus1}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfOutDiscards | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfOutDiscards
    \    Append To List    ${SNMP_VALUES}    ${ifOutDiscards}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfInDiscards | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfInDiscards
    \    Append To List    ${SNMP_VALUES}    ${ifInDiscards}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfInOctets | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfInOctets
    \    Append To List    ${SNMP_VALUES}    ${ifInOctets}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfOutQLen | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfOutQLen
    \    Append To List    ${SNMP_VALUES}    ${ifOutQLen}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfOutErrors | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfOutErrors
    \    Append To List    ${SNMP_VALUES}    ${ifOutErrors}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfInUcastPkts | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfInUcastPkts
    \    Append To List    ${SNMP_VALUES}    ${ifInUcastPkts}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfOutNUcastPkts | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfOutNUcastPkts
    \    Append To List    ${SNMP_VALUES}    ${ifOutNUcastPkts}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfInErrors | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfInErrors
    \    Append To List    ${SNMP_VALUES}    ${ifInErrors}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfOutOctets | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfOutOctets
    \    Append To List    ${SNMP_VALUES}    ${ifOutOctets}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfAdminStatus | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfAdminStatus
    \    Append To List    ${SNMP_VALUES}    ${ifAdminStatus}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfInUnknownProtos | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfInUnknownProtos
    \    Append To List    ${SNMP_VALUES}    ${ifInUnknownProtos}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfOutUcastPkts | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfOutUcastPkts
    \    Append To List    ${SNMP_VALUES}    ${ifOutUcastPkts}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfInNUcastPkts | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfInNUcastPkts
    \    Append To List    ${SNMP_VALUES}    ${ifInNUcastPkts}
    \    Append To List    ${SNMP_ENTRY}    grep NID=${SNMP_IP} | grep DC=SNMPINTERFACES | grep MN=IfOperStatus | grep RK=ifIndex:${ifindex},ifName:Iso88023Csmacd,SnmpMetric:IfOperStatus
    \    Append To List    ${SNMP_VALUES}    ${ifOperStatus}
    [Return]    ${SNMP_ENTRY}    ${SNMP_VALUES}
