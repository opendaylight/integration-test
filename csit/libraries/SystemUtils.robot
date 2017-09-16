*** Settings ***
Documentation     Library to use common Linux Commands and also some configuration on MySQL,Rabbit etc.
Library           Collections
Library           SSHLibrary
Library           OperatingSystem

*** Keywords ***
Install Rpm Package
    [Arguments]    ${os_node_cxn}     ${package}
    [Documentation]    Install packages in a node
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo yum install -y ${package}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Crudini Edit
    [Arguments]    ${os_node_cxn}     ${conf_file}     ${section}     ${key}      ${value}
    [Documentation]     Crudini edit on a configuration file
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo crudini --verbose  --set --inplace ${conf_file} ${section} ${key} ${value}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Update Packages
    [Arguments]    ${os_node_cxn}
    [Documentation]     yum update to the latest versions in the repo
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo yum update -y
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Start Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Start a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl start ${service}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Enable Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Enable a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl enable ${service}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      stop a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl stop ${service}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Restart Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Restart a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl restart ${service}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop And Disable Firewall
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]     Disable/stop firewalld and iptables for testing
    Switch Connection     ${os_node_cxn}
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl stop firewalld
    Log    ${output}
    Log    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl disable firewalld
    Log    ${output}
    Log    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl stop iptables
    Log    ${output}
    Log    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo systemctl disable iptables
    Log    ${output}
    Log    ${rc}

Chmod File
    [Arguments]    ${os_node_cxn}     ${file_or_path}      ${perm_value}
    [Documentation]     Chmod on any file in server
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo chmod ${perm_value} ${file_or_path}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Chown File
    [Arguments]    ${os_node_cxn}     ${file_or_path}      ${user_group}
    [Documentation]     Chown on any file in server
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo chown ${user_group} ${file_or_path}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Copy File
    [Arguments]    ${os_node_cxn}     ${file_src}      ${file_dst}
    [Documentation]     Copy file in server from src to dest
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo cp ${file_src} ${file_dst}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Move File
    [Arguments]    ${os_node_cxn}     ${file_src}      ${file_dst}
    [Documentation]     Move or rename a file in server
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo mv ${file_src} ${file_dst}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Touch File
    [Arguments]    ${os_node_cxn}     ${file_name}
    [Documentation]     Execute touch and create  a file in server
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo touch ${file_name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Run Command as User
    [Arguments]    ${os_node_cxn}    ${command}     ${run_as_user}
    [Documentation]     Run a command as a differnt user
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo su -s /bin/sh -c ${command} ${run_as_user}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Create User Pass For Mysql
    [Arguments]    ${os_node_cxn}    ${mysql_user}     ${mysql_pass}
    [Documentation]     Create an user with password to access Mysql DB
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo mysqladmin -u ${mysql_user} password ${mysql_pass}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Create Database for Mysql
    [Arguments]    ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     ${db_name}
    [Documentation]     Create a database on MySQL
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo mysql -u${mysql_user} -p${mysql_pass} -e CREATE DATABASE ${db_name} CHARACTER SET utf8;
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Grant Privileges To Mysql Database
    [Arguments]    ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     ${db_name}     ${db_user}    ${host_name}     ${host_user}
    [Documentation]     Grant Privileges on a database in MySQL
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo mysql -u${mysql_user} -p${mysql_pass} -e GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'${host_name}' identified by '${host_user}';
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Add Rabbitmq User
    [Arguments]    ${os_node_cxn}    ${rabbit_user}     ${rabbit_pass}
    [Documentation]    Add a user to Rabbit MQ
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    sudo rabbitmqctl add_user ${rabbit_user} ${rabbit_pass}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Enable Access to Rabbitmq vhost
    [Arguments]    ${os_node_cxn}    ${rabbit_user}
    [Documentation]    Add a user to Rabbit MQ
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    rabbitmqctl set_permissions ${rabbit_user} ".*" ".*" ".*"
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop RabbitMQ
    [Arguments]    ${os_node_cxn}
    [Documentation]     Stop the RabbitMQ user
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    rabbitmqctl stop_app
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Get RabbitMQ Cookie File
    [Arguments]    ${os_node_cxn}
    [Documentation]     Get the Cookie file from the primary node
    Switch Connection     ${os_node_cxn}
    Get File      /var/lib/rabbitmq/.erlang.cookie       /tmp
    ${rc}    ${output}=    Run And Return Rc And Output      rabbitmqctl start_app
    Log    ${output}
    Should Not Be True    ${rc}
     

Copy RabbitMQ Cookie File
    [Arguments]    ${os_node_cxn}
    [Documentation]      Copy the rabbit  cookie file to other servers to join the cluster
    Switch Connection     ${os_node_cxn}     ${rabbit_user}       ${dst_hostname}
    Put File      /tmp/.erlang.cookie       /var/lib/rabbitmq/.erlang.cookie
    ${rc}    ${output}=    Run And Return Rc And Output     chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
    Log    ${output}
    Should Not Be True    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output     chmod 400 /var/lib/rabbitmq/.erlang.cookie
    Log    ${output}
    Should Not Be True    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output     rabbitmqctl join_cluster --ram ${rabbit_user}@${dst_hostname}
    Log    ${output}
    Should Not Be True    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output     rabbitmqctl start_app
    Log    ${output}
    Should Not Be True    ${rc}
    ${rc}    ${output}=    Run And Return Rc And Output     rabbitmqctl cluster_status
    Log    ${output}
    Should Not Be True    ${rc}


Write To File 
    [Arguments]    ${os_node_cxn}    ${file_name}     ${buffer}
    [Documentation]       Write to file which require sudo access
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    echo ${buffer} | sudo tee ${file_name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}
    
Append To File
    [Arguments]    ${os_node_cxn}    ${file_name}     ${buffer}
    [Documentation]       Append to file which require sudo access
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output    echo ${buffer} | sudo tee --append ${file_name}
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Cat File
    [Arguments]    ${os_node_cxn}    ${file_name}
    [Documentation]       Read a file for logging
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output     cat ${file_name}
    Log    ${output}
    Should Not Be True    ${rc}

Disable SeLinux Tempororily
    [Arguments]    ${os_node_cxn}
    [Documentation]       Disable SELinux from command
    Switch Connection     ${os_node_cxn}
    ${rc}    ${output}=    Run And Return Rc And Output      sudo setenforce 0
    Log    ${output}
    Should Not Be True    ${rc}

Get Ssh Connection
    [Arguments]    ${os_ip}     ${os_user}     ${os_password}     ${prompt}      
    ${conn_id}=    SSHLibrary.Open Connection    ${os_ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=1 hour    alias=${os_ip}
    SSHKeywords.Flexible SSH Login    ${os_user}    ${prompt}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    [Return]    ${conn_id}
