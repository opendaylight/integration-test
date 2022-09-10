*** Settings ***
Documentation       Library to use common Linux Commands and also some configuration on MySQL,Rabbit etc.

Library             Collections
Library             SSHLibrary
Library             OperatingSystem
Resource            SSHKeywords.robot


*** Keywords ***
Install Rpm Package
    [Documentation]    Install packages in a node
    [Arguments]    ${os_node_cxn}    ${package}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo yum install -y ${package}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Local Install Rpm Package
    [Documentation]    Install packages in local VM
    [Arguments]    ${package}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo yum install -y ${package}
    Log    ${output}
    Should Not Be True    ${rc}

Install Local Rpm Package
    [Documentation]    Install local rpm packages
    [Arguments]    ${os_node_cxn}    ${package}
    Switch Connection    ${os_node_cxn}
    Put File    /tmp/${ODL_RPM}    /tmp/
    ${output}    ${rc}=    Execute Command
    ...    sudo yum localinstall -y /tmp/${package}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Crudini Edit
    [Documentation]    Crudini edit on a configuration file
    [Arguments]    ${os_node_cxn}    ${conf_file}    ${section}    ${key}    ${value}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo crudini --verbose --set --inplace ${conf_file} ${section} ${key} ${value}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Crudini Delete
    [Documentation]    Crudini edit on a configuration file
    [Arguments]    ${os_node_cxn}    ${conf_file}    ${section}    ${key}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo crudini --verbose --del --inplace ${conf_file} ${section} ${key}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Update Packages
    [Documentation]    yum update to the latest versions in the repo
    [Arguments]    ${os_node_cxn}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo yum update -y    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Start Service
    [Documentation]    Start a service in CentOs
    [Arguments]    ${os_node_cxn}    ${service}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo systemctl start ${service}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Enable Service
    [Documentation]    Enable a service in CentOs
    [Arguments]    ${os_node_cxn}    ${service}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo systemctl enable ${service}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Stop Service
    [Documentation]    stop a service in CentOs
    [Arguments]    ${os_node_cxn}    ${service}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo systemctl stop ${service}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Daemon Reload
    [Documentation]    daemon reload
    [Arguments]    ${os_node_cxn}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo systemctl daemon-reload    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Restart Service
    [Documentation]    Restart a service in CentOs
    [Arguments]    ${os_node_cxn}    ${service}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo systemctl restart ${service}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Stop And Disable Firewall
    [Documentation]    Disable/stop firewalld and iptables for testing
    [Arguments]    ${os_node_cxn}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo systemctl stop firewalld    return_rc=True    return_stdout=True
    Log    ${output}
    Log    ${rc}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    sudo systemctl disable firewalld    return_rc=True    return_stdout=True
    Log    ${output}
    Log    ${rc}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    sudo systemctl stop iptables    return_rc=True    return_stdout=True
    Log    ${output}
    Log    ${rc}
    ${output}    ${rc}=    Execute Command    sudo systemctl disable iptables    return_rc=True    return_stdout=True
    Log    ${output}
    Log    ${rc}

Chmod File
    [Documentation]    Chmod on any file in server
    [Arguments]    ${os_node_cxn}    ${file_or_path}    ${perm_value}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo chmod ${perm_value} ${file_or_path}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Chown File
    [Documentation]    Chown on any file in server
    [Arguments]    ${os_node_cxn}    ${file_or_path}    ${user}    ${group}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo chown -R ${user}:${group} ${file_or_path}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Copy File
    [Documentation]    Copy file in server from src to dest
    [Arguments]    ${os_node_cxn}    ${file_src}    ${file_dst}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo cp -f ${file_src} ${file_dst}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Move File
    [Documentation]    Move or rename a file in server
    [Arguments]    ${os_node_cxn}    ${file_src}    ${file_dst}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo mv -v -f ${file_src} ${file_dst}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    RETURN    ${output}

Touch File
    [Documentation]    Execute touch and create a file in server
    [Arguments]    ${os_node_cxn}    ${file_name}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo touch ${file_name}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Run Command As User
    [Documentation]    Run a command as a differnt user
    [Arguments]    ${os_node_cxn}    ${command}    ${run_as_user}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo su -s /bin/sh -c ${command} ${run_as_user}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Run Command
    [Documentation]    Run a command as a differnt user
    [Arguments]    ${os_node_cxn}    ${command}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    ${command}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Create User Pass For Mysql
    [Documentation]    Create an user with password to access Mysql DB
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo mysqladmin -u ${mysql_user} password ${mysql_pass}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Create Database for Mysql
    [Documentation]    Create a database on MySQL
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${db_name}
    Switch Connection    ${os_node_cxn}
    Write Commands Until Expected Prompt    sudo mysql -u${mysql_user} -p${mysql_pass}    >    30s
    ${output}=    Write Commands Until Expected Prompt
    ...    CREATE DATABASE ${db_name} CHARACTER SET utf8; exit;
    ...    Bye
    ...    30s
    Log    ${output}
    RETURN    ${output}

Rsync Directory
    [Arguments]    ${os_node_cxn}    ${dst_node_ip}    ${src_dir}    ${dst_dir}
    Switch Connection    ${os_node_cxn}
    Write Commands Until Expected Prompt
    ...    sudo rsync -e "ssh -o StrictHostKeyChecking=no" -avz ${src_dir} ${dst_node_ip}:${dst_dir}
    ...    d:
    ...    30s
    Write Commands Until Expected Prompt    ${OS_USER_PASSWORD}    ${OS_NODE_PROMPT}    30s

Grant Privileges To Mysql Database
    [Documentation]    Grant Privileges on a database in MySQL
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${db_name}    ${db_user}    ${host_name}
    ...    ${db_pass}
    Switch Connection    ${os_node_cxn}
    Write Commands Until Expected Prompt    sudo mysql -u${mysql_user} -p${mysql_pass}    >    30s
    ${output}=    Write Commands Until Expected Prompt
    ...    GRANT ALL PRIVILEGES ON ${db_name} TO '${db_user}'@'${host_name}' identified by '${db_pass}'; exit;
    ...    Bye
    ...    30s
    Log    ${output}
    RETURN    ${output}

Grant Process To Mysql Database
    [Documentation]    Grant Privileges on a database in MySQL
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${db_name}    ${db_user}    ${host_name}
    ...    ${db_pass}
    Switch Connection    ${os_node_cxn}
    Write Commands Until Expected Prompt    sudo mysql -u${mysql_user} -p${mysql_pass}    >    30s
    ${output}=    Write Commands Until Expected Prompt
    ...    GRANT PROCESS ON ${db_name} TO '${db_user}'@'${host_name}' identified by '${db_pass}'; FLUSH PRIVILEGES; exit;
    ...    Bye
    ...    30s
    Log    ${output}
    RETURN    ${output}

Execute MySQL STATUS Query
    [Arguments]    ${os_node_cxn}    ${mysql_user}    ${mysql_pass}    ${attribute}
    Switch Connection    ${os_node_cxn}
    Write Commands Until Expected Prompt    sudo mysql -u${mysql_user} -p${mysql_pass}    >    30s
    ${output}=    Write Commands Until Expected Prompt    show STATUS LIKE '${attribute}';exit;    Bye    30s
    Log    ${output}
    RETURN    ${output}

Write To File
    [Documentation]    Write to file which require sudo access
    [Arguments]    ${os_node_cxn}    ${file_name}    ${buffer}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    echo ${buffer} | sudo tee ${file_name}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Append To File
    [Documentation]    Append to file which require sudo access
    [Arguments]    ${os_node_cxn}    ${file_name}    ${buffer}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    echo ${buffer} | sudo tee --append ${file_name}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Create Softlink
    [Documentation]    Create Soft Link
    [Arguments]    ${os_node_cxn}    ${src_file_name}    ${link_path}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command
    ...    sudo ln -s ${src_file_name} ${link_path}
    ...    return_rc=True
    ...    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Unlink File
    [Documentation]    Unlink a wrong link created
    [Arguments]    ${os_node_cxn}    ${link_path}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo unlink ${link_path}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    RETURN    ${output}

Create LocalFile
    [Documentation]    Touch a local file
    [Arguments]    ${src_file_name}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo touch ${src_file_name}
    Log    ${output}
    Should Not Be True    ${rc}

Write To Local File
    [Documentation]    AddEntry to Local File
    [Arguments]    ${src_file_name}    ${buffer}
    ${rc}    ${output}=    Run And Return Rc And Output    echo ${buffer} | sudo tee ${src_file_name}
    Log    ${output}
    Should Not Be True    ${rc}

Append To Local File
    [Documentation]    AddEntry to Local File
    [Arguments]    ${src_file_name}    ${buffer}
    ${rc}    ${output}=    Run And Return Rc And Output    echo ${buffer} | sudo tee -a ${src_file_name}
    Log    ${output}
    Should Not Be True    ${rc}

Source Local File
    [Documentation]    Export Varaibles to Env
    [Arguments]    ${src_file_name}
    ${rc}    ${output}=    Run And Return Rc And Output    source ${src_file_name}
    Log    ${output}
    Should Not Be True    ${rc}

Run Command In Local Node
    [Arguments]    ${command}
    ${rc}    ${output}=    Run And Return Rc And Output    ${command}
    Log    ${output}
    Should Not Be True    ${rc}

Generic HAProxy Entry
    [Documentation]    Add an entry in haproxy.cfg for the service
    [Arguments]    ${os_node_cxn}    ${haproxy_ip}    ${port_to_listen}    ${proxy_entry}
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    ' '
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    frontend vip-${proxy_entry}
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    ' 'bind *:${port_to_listen}
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    ' 'timeout client 90s
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    ' 'default_backend ${proxy_entry}
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    ' '
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    backend ${proxy_entry}
    Append To File    ${os_node_cxn}    /etc/haproxy/haproxy.cfg    ' 'balance roundrobin
    Append To File
    ...    ${os_node_cxn}
    ...    /etc/haproxy/haproxy.cfg
    ...    ' 'server ${proxy_entry}_controller1 ${OS_CONTROL_1_IP}:${port_to_listen} check inter 1s
    Append To File
    ...    ${os_node_cxn}
    ...    /etc/haproxy/haproxy.cfg
    ...    ' 'server ${proxy_entry}_controller2 ${OS_CONTROL_2_IP}:${port_to_listen} check inter 1s
    Append To File
    ...    ${os_node_cxn}
    ...    /etc/haproxy/haproxy.cfg
    ...    ' 'server ${proxy_entry}_controller3 ${OS_CONTROL_3_IP}:${port_to_listen} check inter 1s
    IF    3 < ${NUM_CONTROL_NODES}
        Append To File
        ...    ${os_node_cxn}
        ...    /etc/haproxy/haproxy.cfg
        ...    ' 'server ${proxy_entry}_controller4 ${OS_CONTROL_4_IP}:${port_to_listen} check inter 1s
    END
    IF    4 < ${NUM_CONTROL_NODES}
        Append To File
        ...    ${os_node_cxn}
        ...    /etc/haproxy/haproxy.cfg
        ...    ' 'server ${proxy_entry}_controller5 ${OS_CONTROL_5_IP}:${port_to_listen} check inter 1s
    END
    Restart Service    ${os_node_cxn}    haproxy

Cat File
    [Documentation]    Read a file for logging
    [Arguments]    ${os_node_cxn}    ${file_name}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    cat ${file_name}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Disable SeLinux Tempororily
    [Documentation]    Disable SELinux from command
    [Arguments]    ${os_node_cxn}
    Switch Connection    ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo setenforce 0    return_rc=True    return_stdout=True
    Log    ${output}

Get Ssh Connection
    [Arguments]    ${os_ip}    ${os_user}    ${os_password}    ${prompt}
    ${conn_id}=    SSHLibrary.Open Connection    ${os_ip}    prompt=${prompt}    timeout=1 hour    alias=${os_ip}
    SSHKeywords.Flexible SSH Login    ${os_user}    password=${os_password}
    SSHLibrary.Set Client Configuration    timeout=1 hour
    RETURN    ${conn_id}
