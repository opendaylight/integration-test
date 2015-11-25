*** Settings ***
Library           RequestsLibrary
Library           XML
Library           OperatingSystem
Library           String
Library		  Collections
Resource          Utils.robot
Variables           ../variables/Variables.py


*** Variables ***

${HBASE_CLIENT}   /usr/lib/hbase/hbase-0.94.15/bin
${CASSANDRA_CLIENT}    /root/cassandra/apache-cassandra-2.1.11/bin
${final}          ${EMPTY}
${prompt_timeout}
${CASSANDRA_DB_PATH}    /root/cassandra/apache-cassandra-2.1.11/
${metric_path}     metricpath
${metric_val}     metricval
${metric_log}     metriclog
${temp_metric_val}    temp_metric_val
&{HEADER_TSDR}    Content-Type=application/xml    Accept=application/xml

*** Keywords ***
Start Tsdr Suite
    [Arguments]    ${switch}=ovsk    ${switch_count}=3
    [Documentation]    TSDR specific setup/cleanup work that can be done safely before any system
    ...    is run.
    Clean Mininet System
    ${mininet_conn_id1}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${mininet_conn_id1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}   any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    ${start}=    Set Variable    sudo mn --controller=remote,ip=${CONTROLLER} --topo=linear,${switch_count} --switch ${switch},protocols=OpenFlow13
    Log    ${start}
    Write    ${start}
    Read Until    mininet>

Ping All Hosts
    [Arguments]    ${switch}=ovsk
    [Documentation]    Ping between all hosts in mininet topology.
    Switch Connection    ${mininet_conn_id1}
    Write    pingall
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
    [Arguments]    ${queue_interface}    ${user}=${MININET_USER} 
    [Documentation]    Configure the 2 queues on specified openvswitch interface
    Log    Configure the queue on ${queue_interface}
    ${output}=    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set port ${queue_interface} qos=@newqos -- --id=@newqos create qos type=linux-htb other-config:max-rate=200000000 queues=0=@q0,1=@q1,2=@q2 -- --id=@q0 create queue other-config:min-rate=100000 other-config:max-rate=200000 -- --id=@q1 create queue other-config:min-rate=10001 other-config:max-rate=300000 -- --id=@q2 create queue other-config:min-rate=300001 other-config:max-rate=200000000    
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
    ${output}=    Issue Command On Karaf Console    ${tsdr_cmd}    ${remote}    ${KARAF_SHELL_PORT}    ${prompt_timeout}
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

Initialize Cassandra Tables
    [Arguments]    ${remote}=${CONTROLLER}    ${user}=${MININET_USER}    ${prompt_timeout}=120s    ${key_table}=metricpath    ${val_table}=metricval
    [Documentation]    Truncate Existing tables in Cassandra to Start it fresh.
    Log    Attempting to truncate tables in Cassandra
    Run Command On Remote System    ${CONTROLLER}    rm -rf ${CASSANDRA_DB_PATH}${key_table}
    Run Command On Remote System    ${CONTROLLER}    rm -rf ${CASSANDRA_DB_PATH}${val_table}
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
    [Arguments]    ${remote}=${CONTROLLER}    ${user}=${MININET_USER}    ${prompt_timeout}=120s    ${key_table}=metricpath    ${val_table}=metricval
    [Documentation]    Truncate Existing tables in Cassandra to Start it fresh.
    Log    Attempting to truncate tables in Cassandra
    Run Command On Remote System    ${CONTROLLER}    rm -rf ${CASSANDRA_DB_PATH}${key_table}
    Run Command On Remote System    ${CONTROLLER}    rm -rf ${CASSANDRA_DB_PATH}${val_table}
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
    ${output}=    Issue Command On Karaf Console    ${h2_query}    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
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


Verify the Metrics Attributes on Cassandra Client
    [Arguments]    ${pattern}
    [Documentation]    Verification on Metrics attributes on Cassandra Client
    @{metric_row}=    Find Metricval Keys    ${pattern}    metricpath
    ${keya}=    Get From List    ${metric_row}    1
    ${keyb}=    Get From List    ${metric_row}    2
    ${keya_bool}=    Evaluate     ${keya} < 0
    ${keya}=    Run Keyword If    '${keya_bool}' == 'True'    Catenate    SEPARATOR=    \\    ${keya}    ELSE  
    ...    Catenate    ${keya}
    Create Temporary Key Info    ${keya} ${keyb}    
    ${metric_value}=    Verify Metric Val File
    [Return]    ${metric_value}   

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
    [Arguments]    ${pattern}    ${remote}=${CONTROLLER}    ${user}=${MININET_USER}    ${prompt_timeout}=120s    ${val_table}=metricval 
    [Documentation]    Creates a temporary File with matching keya,keyb values.
    Log    Removing existing file
    Run Command On Remote System    ${CONTROLLER}    rm -rf ${CASSANDRA_DB_PATH}${temp_metric_val}   
    Run Command On Remote System    ${CONTROLLER}    cat ${CASSANDRA_DB_PATH}${val_table}|grep "${pattern}" > ${CASSANDRA_DB_PATH}${temp_metric_val}   



Verify Metric Val File
    [Documentation]    Returns Value for metric matching particular keya,keyb
    @{metricval}=    Read File and Return Split Lines    ${CASSANDRA_DB_PATH}${temp_metric_val}
    ${mv_len}=    Get Length    ${metricval}
    ${mv_len}=    Evaluate    ${mv_len} - 1
    ${found_line}=    Get From List    ${metricval}    ${mv_len}
    @{split_line}=    Split String    ${found_line}    ${SPACE}
    ${metric_count}=    Get From List    ${split_line}    3
    [Return]    ${metric_count}
    
Find Metricval Keys
    [Arguments]    ${pattern}    ${file}
    [Documentation]    Return list element which has the particular pattern.
    ${metric_grep}=    Grep File    ${CASSANDRA_DB_PATH}${file}    ${pattern}
    @{split_line}=    Split String    ${metric_grep}    ${SPACE}
    [Return]    @{split_line}

Copy TSDR tables
    [Arguments]     ${remote}=${CONTROLLER}    ${user}=${MININET_USER}    ${prompt_timeout}=120s    ${key_table}=metricpath    ${val_table}=metricval     
    [Documentation]    Copy TSDR files to external File system for text processing.
    Log    Attempting to truncate tables in Cassandra
    ${conn_id}=    Open Connection    ${remote}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${prompt_timeout}
    Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    export JAVA_HOME=/usr
    Write    ${CASSANDRA_CLIENT}/cqlsh
    Read Until    cqlsh>
    Write    COPY tsdr.${key_table} TO '${CASSANDRA_DB_PATH}${key_table}' WITH DELIMITER = ' ';
    Read Until    cqlsh>
    Write    COPY tsdr.${val_table} TO '${CASSANDRA_DB_PATH}${val_table}' WITH DELIMITER = ' ';
    Read Until    cqlsh>    
    Write    exit
    Close Connection


Issue Cassandra Query


    [Arguments]     ${query}    ${output}    ${remote}=${CONTROLLER}    ${user}=${MININET_USER}    ${prompt_timeout}=120s
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

    [Arguments]     ${query}    ${remote}=${CONTROLLER}    ${user}=${MININET_USER}    ${prompt_timeout}=120s
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
    [Documentation]    Reads the file and returns each line  as list
    ${contents}=    OperatingSystem.Get File    ${filename}
    @{lines}=    Split to lines    ${contents}
    [Return]    @{lines}
 
Get Stats XML 

    [Arguments]    ${query}    ${xpath}
    [Documentation]    Parse the xml output and returns it.
    ${sid}=    RequestsLibrary.Create_Session    session    http://${CONTROLLER}:${RESTCONFPORT}    headers=${HEADER_TSDR}    auth=${AUTH}
    ${resp}=    RequestsLibrary.Get Request    session    ${query}    headers=${HEADER_TSDR}
    ${resp_xml}=     Parse XML    ${resp.content}
    ${id1}=    Get Element Text    ${resp_xml}    ${xpath}
    [Return]    ${id1}

Return all XML matches

    [Arguments]    ${query}    ${xpath}
    [Documentation]    Returns all the values from xpath  
    ${sid}=    RequestsLibrary.Create_Session    session    http://${CONTROLLER}:${RESTCONFPORT}    headers=${HEADER_TSDR}    auth=${AUTH}
    ${resp}=    RequestsLibrary.Get Request    session    ${query}    headers=${HEADER_TSDR}
    ${resp_xml}=     Parse XML    ${resp.content}
    @{id1}=    Get Elements Texts    ${resp_xml}    ${xpath}
    [Return]    @{id1}




Compare Tsdr XML Metrics

    [Arguments]    ${xml}    ${tsdr}    ${deviation}=10
    [Documentation]    Compares xml metrics from openflow plugin with TSDR metric values
    Log    ${xml}--${tsdr}    
    ${val_max}=    Evaluate    ${xml}*${deviation}/100
    ${val_diff}=    Evaluate    ${tsdr} - ${xml}
    ${find_negative}=    Evaluate    ${val_diff} < 0
    ${val_diff}=    Run Keyword If    '${find_negative}' == 'True'    Evaluate    ${val_diff}*-1    ELSE
    ...    Evaluate    ${val_diff}*1 
    Should Be True    ${val_diff} <= ${val_max}

Generate Syslog
   [Documentation]    Uses syslogd to generate syslogs 
   [Arguments]    ${facility}    ${level}
   Run Command On Remote System    ${CONTROLLER}    logger -p ${facility}.${level} -n 127.0.0.1 -u 514 ${MESSAGE} 

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
    ${keya_bool}=    Evaluate     ${keya} < 0
    ${keya}=    Run Keyword If    '${keya_bool}' == 'True'    Catenate    SEPARATOR=    \\    ${keya}    ELSE
    ...    Catenate    ${keya}
    Create Temporary Key Info    ${keya} ${keyb}    val_table=${metric_log}


Iterating over metricpath
    [Documentation]    Used to traverse over metricpath file and traverse over metricpath file and get the keys
    @{mp_lines}=    Read File and Return Split Lines    ${CASSANDRA_DB_PATH}${metric_path}
    :FOR    ${line}    IN    @{mp_lines}
    \    log    ${line}    WARN
    \    @{split_line}=    Split String    ${line}    ${SPACE}
    \    ${keya}=    Get From List    ${split_line}    1
    \    ${keyb}=    Get From List    ${split_line}    2
    \    Iterating over metricval    ${keya}    ${keyb}

Iterating over metricval
    [Documentation]    Used to traverse over metricval file and check if keya and keyb are present.
    [Arguments]    ${keya}    ${keyb}
    ${mv_contents}=    OperatingSystem.Get File    ${CASSANDRA_DB_PATH}${metric_val}
    Should Contain    ${mv_contents}    ${keya}    ${keyb}

Verify Log
    [Documentation]    Used to check if syslog has started
    [Arguments]    ${pattern}
    ${output}=    Issue Command On Karaf Console    log:display | grep TSDR
    Should Contain    ${output}    ${pattern}

Check Metric path
    [Documentation]    Count number of rows in metricpath table and compare it with pattern.
    [Arguments]    ${pattern}
    ${query_output}=    Count Cassandra rows    select count(*) from tsdr.metricpath;
    Should Match Regexp    ${query_output}    ${pattern}


Check Metric Val
    [Documentation]    Count number of rows in metricval table and compare it with pattern.
    [Arguments]    ${pattern}
    ${query_output}=    Count Cassandra rows    select count(*) from tsdr.metricval;
    Should Match Regexp    ${query_output}    ${pattern}


Severity Iterator
    [Documentation]    Used in FOR loop to iterate over syslog_severity
    [Arguments]    ${key}
    :FOR    ${level}    IN ZIP    &{syslog_severity}
    \    ${level_value}=    Get From Dictionary    ${syslog_severity}    ${level}
    \    Generate Syslog    ${key}    ${level}



Severity Iterator For TSDR
    [Documentation]    Used in to iterate over syslogs in Cassandra Data store .
    [Arguments]    ${key}     ${facility_value}    ${iterator_value}    ${syslogs}
    ${iterator}=    Evaluate    ${iterator_value} * 8
    :FOR    ${level}    IN ZIP    &{syslog_severity}
    \    ${severity_value}=    Get From Dictionary    ${syslog_severity}    ${level}
    \    ${fac_sev}=    Evaluate    ${facility_value} * 8 + ${severity_value}
    \    log    ${level}-@{syslogs}[${iterator}]    WARN
    \    Should Contain    @{syslogs}[${iterator}]     ${MESSAGE}
    \    Should Contain    @{syslogs}[${iterator}]     <${fac_sev}>
    \    ${iterator}=    Evaluate    ${iterator} + 1

Severity Iterator For Syslog HBase
    [Documentation]    Used in to iterate over syslogs in HBase Data Store
    [Arguments]    ${message}    ${value}    &{syslog_severity}    
    ${output}=    Query the Data from HBaseClient    scan 'SysLog'
    Should Contain X Times    ${output}    ${message}    8
    ${iterator}=    Evaluate    ${value} * 8
    :FOR    ${level}    IN ZIP    &{syslog_severity}
    \    ${severity_value}=    Get From Dictionary    ${syslog_severity}    ${level}
    \    ${fac_sev}=    Evaluate    ${iterator} + ${severity_value}
    \    Should Match     ${output}    *${fac_sev}>*



Get OID_Value
    [Documentation]    Used to parse MIB_REC file to get metrics of OID's which are not of String type
    [Arguments]    ${MIB_REC}    ${OID}
    ${matching_lines}=    Grep File    ${MIB_REC}    1.3.6.1.2.1.2.2.1.1.
    @{matching_list}=    Split String    ${matching_lines}
    ${ifindex}=    Create List     Null
    Remove From List    ${ifindex}    0
    :FOR    ${found_line}     IN     @{matching_list}
    \    @{split_line}=    Split String    ${found_line}    |
    \    ${index}=    Get From List    ${split_line}    2
    \    Append To List    ${ifindex}    ${index}
    [Return]    @{ifindex} 


Get OID_String
    [Documentation]    Used to parse MIB_REC file to get metrics of OID's which are of String type
    [Arguments]    ${MIB_REC}    ${OID}
    ${matching_lines}=    Grep File    ${MIB_REC}    1.3.6.1.2.1.2.2.1.2.
    @{matching_list}=    Split String    ${matching_lines}
    ${ifdesc_list}=    Create List     Null
    Remove From List    ${ifdesc_list}    0
    :FOR    ${found_line}     IN     @{matching_list}
    \    @{split_line}=    Split String    ${found_line}    |
    \    ${hex_name}=    Get From List    ${split_line}    2
    \    ${if_desc}=    Decode Bytes To String    ${hex_name}    HEX
    \    Append To List    ${ifdesc_list}    ${if_desc}
    [Return]    @{ifdesc_list}


