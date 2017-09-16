*** Settings ***
Documentation     Library to use common Linux Commands and also some configuration on MySQL,Rabbit etc.
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Resource          SSHKeywords.robot

*** Keywords ***
Install Rpm Package
    [Arguments]    ${os_node_cxn}     ${package}
    [Documentation]    Install packages in a node
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command     sudo yum install -y ${package}      return_rc=True      return_stdout=True
    Log     ${output}
    Should Not Be True    ${rc}

Crudini Edit
    [Arguments]    ${os_node_cxn}     ${conf_file}     ${section}     ${key}      ${value}
    [Documentation]     Crudini edit on a configuration file
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo crudini --verbose --set --inplace ${conf_file} ${section} ${key} ${value}     return_rc=True     return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Crudini Delete
    [Arguments]    ${os_node_cxn}     ${conf_file}     ${section}     ${key}
    [Documentation]     Crudini edit on a configuration file
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo crudini --verbose --del --inplace ${conf_file} ${section} ${key}     return_rc=True     return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Update Packages
    [Arguments]    ${os_node_cxn}
    [Documentation]     yum update to the latest versions in the repo
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo yum update -y     return_rc=True     return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Start Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Start a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo systemctl start ${service}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Enable Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Enable a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo systemctl enable ${service}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      stop a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command  sudo systemctl stop ${service}     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Restart Service
    [Arguments]    ${os_node_cxn}     ${service}
    [Documentation]      Restart a service in CentOs
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo systemctl restart ${service}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop And Disable Firewall
    [Arguments]    ${os_node_cxn}
    [Documentation]     Disable/stop firewalld and iptables for testing
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo systemctl stop firewalld    return_rc=True    return_stdout=True
    Log    ${output}
    Log    ${rc}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command   sudo systemctl disable firewalld    return_rc=True    return_stdout=True
    Log    ${output}
    Log    ${rc}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command   sudo systemctl stop iptables     return_rc=True    return_stdout=True
    Log    ${output}
    Log    ${rc}
    ${output}    ${rc}=    Execute Command   sudo systemctl disable iptables    return_rc=True    return_stdout=True
    Log    ${output}
    Log    ${rc}

Chmod File
    [Arguments]    ${os_node_cxn}     ${file_or_path}      ${perm_value}
    [Documentation]     Chmod on any file in server
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo chmod ${perm_value} ${file_or_path}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Chown File
    [Arguments]    ${os_node_cxn}     ${file_or_path}      ${user_group}
    [Documentation]     Chown on any file in server
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo chown -R ${user_group} ${file_or_path}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Copy File
    [Arguments]    ${os_node_cxn}     ${file_src}      ${file_dst}
    [Documentation]     Copy file in server from src to dest
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo cp -f ${file_src} ${file_dst}   return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Move File
    [Arguments]    ${os_node_cxn}     ${file_src}      ${file_dst}
    [Documentation]     Move or rename a file in server
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo mv -v -f ${file_src} ${file_dst}     return_rc=True    return_stdout=True
    Log    ${output}
    [Return]    ${output}

Touch File
    [Arguments]    ${os_node_cxn}     ${file_name}
    [Documentation]     Execute touch and create  a file in server
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo touch ${file_name}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Run Command As User
    [Arguments]    ${os_node_cxn}    ${command}     ${run_as_user}
    [Documentation]     Run a command as a differnt user
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo su -s /bin/sh -c ${command} ${run_as_user}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Run Command
    [Arguments]    ${os_node_cxn}    ${command}
    [Documentation]     Run a command as a differnt user
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   sudo ${command}     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Create User Pass For Mysql
    [Arguments]    ${os_node_cxn}    ${mysql_user}     ${mysql_pass}
    [Documentation]     Create an user with password to access Mysql DB
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo mysqladmin -u ${mysql_user} password ${mysql_pass}    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Create Database for Mysql
    [Arguments]    ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     ${db_name}
    [Documentation]     Create a database on MySQL
    Switch Connection     ${os_node_cxn}
    Write Commands Until Expected Prompt      sudo mysql -u${mysql_user} -p${mysql_pass}         >         30s
    ${output}=     Write Commands Until Expected Prompt     CREATE DATABASE ${db_name} CHARACTER SET utf8; exit;      Bye       30s
    Log    ${output}
    [Return]    ${output}

Grant Privileges To Mysql Database
    [Arguments]    ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     ${db_name}     ${db_user}    ${host_name}     ${db_pass}
    [Documentation]     Grant Privileges on a database in MySQL
    Switch Connection     ${os_node_cxn}
    Write Commands Until Expected Prompt      sudo mysql -u${mysql_user} -p${mysql_pass}         >         30s
    ${output}=     Write Commands Until Expected Prompt      GRANT ALL PRIVILEGES ON ${db_name} TO '${db_user}'@'${host_name}' identified by '${db_pass}'; exit;      Bye       30s
    Log    ${output}
    [Return]    ${output}

Execute MySQL STATUS Query
    [Arguments]    ${os_node_cxn}    ${mysql_user}     ${mysql_pass}     ${attribute}
    Switch Connection     ${os_node_cxn}
    Write Commands Until Expected Prompt      sudo mysql -u${mysql_user} -p${mysql_pass}         >         30s
    ${output}=     Write Commands Until Expected Prompt     show STATUS LIKE '${attribute}';exit;      Bye         30s
    Log    ${output}
    [Return]    ${output}

Add Rabbitmq User
    [Arguments]    ${os_node_cxn}    ${rabbit_user}     ${rabbit_pass}
    [Documentation]    Add a user to Rabbit MQ
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl add_user ${rabbit_user} ${rabbit_pass}     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Change Rabbitmq Password
    [Arguments]    ${os_node_cxn}    ${rabbit_user}     ${rabbit_pass}
    [Documentation]    Add a user to Rabbit MQ
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo rabbitmqctl change_password ${rabbit_user} ${rabbit_pass}     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Enable Access to Rabbitmq vhost
    [Arguments]    ${os_node_cxn}    ${rabbit_user}
    [Documentation]    Add a user to Rabbit MQ
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   rabbitmqctl set_permissions ${rabbit_user} ".*" ".*" ".*"     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Stop RabbitMQ
    [Arguments]    ${os_node_cxn}
    [Documentation]     Stop the RabbitMQ user
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    rabbitmqctl stop_app     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Get RabbitMQ Cookie File
    [Arguments]    ${os_node_cxn}
    [Documentation]     Get the Cookie file from the primary node
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    rabbitmqctl stop_app     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    SSHLibrary.Get File      /var/lib/rabbitmq/.erlang.cookie       /tmp/
    ${output}    ${rc}=    Execute Command    rabbitmqctl start_app     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    rabbitmqctl cluster_status    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
     
Copy RabbitMQ Cookie File
    [Arguments]    ${os_node_cxn}    ${rabbit_user}       ${src_hostname}
    [Documentation]      Copy the rabbit  cookie file to other servers to join the cluster
    Switch Connection     ${os_node_cxn}
    SSHLibrary.Put File      /tmp/.erlang.cookie       /var/lib/rabbitmq/.erlang.cookie
    ${output}    ${rc}=    Execute Command    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    chmod 400 /var/lib/rabbitmq/.erlang.cookie    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    Start Service     ${os_node_cxn}     rabbitmq-server
    ${output}    ${rc}=    Execute Command    rabbitmqctl stop_app     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    rabbitmqctl join_cluster --ram ${rabbit_user}@${src_hostname}     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    ExecuteCommand    rabbitmqctl start_app    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    ${output}    ${rc}=    Execute Command    rabbitmqctl cluster_status    return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Write To File 
    [Arguments]    ${os_node_cxn}    ${file_name}     ${buffer}
    [Documentation]       Write to file which require sudo access
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    echo ${buffer} | sudo tee ${file_name}     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}
    
Append To File
    [Arguments]    ${os_node_cxn}    ${file_name}     ${buffer}
    [Documentation]       Append to file which require sudo access
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   echo ${buffer} | sudo tee --append ${file_name}     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Create Softlink
    [Arguments]    ${os_node_cxn}    ${src_file_name}     ${link_path}
    [Documentation]       Create Soft Link
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command   "sudo ln -s ${src_file_name} ${link_path}"     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}
    [Return]    ${output}

Create LocalFile
    [Arguments]    ${src_file_name}
    [Documentation]       Touch a local file
    ${rc}    ${output}=    Run And Return Rc And Output    sudo touch ${src_file_name}
    Log    ${output}
    Should Not Be True    ${rc}

Append To Local File
    [Arguments]    ${src_file_name}    ${buffer}
    [Documentation]       AddEntry to Local File
    ${rc}    ${output}=    Run And Return Rc And Output    echo ${buffer} | sudo tee -a ${src_file_name}
    Log    ${output}
    Should Not Be True    ${rc}

Source Local File
    [Arguments]    ${src_file_name}
    [Documentation]       Export Varaibles to Env
    ${rc}    ${output}=    Run And Return Rc And Output     source ${src_file_name}
    Log    ${output}
    Should Not Be True    ${rc}

Generic HAProxy Entry
    [Arguments]    ${os_node_cxn}    ${haproxy_ip}     ${port_to_listen}     ${proxy_entry}
    [Documentation]       Add an entry in haproxy.cfgfor the service
    Switch Connection     ${os_node_cxn}
    Append To File      /etc/haproxy/haproxy.cfg     ${proxy_entry} 
    ${entry}=      Set Variable     "     bind *:${port_to_listen}" 
    Append To File      /etc/haproxy/haproxy.cfg     ${entry} 
    ${entry}=      Set Variable     "     balance source" 
    Append To File      /etc/haproxy/haproxy.cfg     ${entry} 
    ${entry}=      Set Variable     "     option tcpka" 
    Append To File      /etc/haproxy/haproxy.cfg     ${entry} 
    ${entry}=      Set Variable     "     option httpchk" 
    Append To File      /etc/haproxy/haproxy.cfg     ${entry} 
    ${entry}=      Set Variable     "     option tcplog" 
    Append To File      /etc/haproxy/haproxy.cfg     ${entry} 
    ${entry}=      Set Variable     "     server controller1 ${OS_CONTROL_1_IP}:${port_to_listen} check inter 2000 rise 2 fall 5" 
    Append To File      /etc/haproxy/haproxy.cfg     ${entry} 
    ${entry}=      Set Variable     "     server controller1 ${OS_CONTROL_2_IP}:${port_to_listen} check inter 2000 rise 2 fall 5" 
    Append To File      /etc/haproxy/haproxy.cfg     ${entry} 
    ${entry}=      Set Variable     "     server controller1 ${OS_CONTROL_3_IP}:${port_to_listen} check inter 2000 rise 2 fall 5" 
    Append To File      /etc/haproxy/haproxy.cfg     ${entry} 
    Restart Service      ${os_node_cxn}      haproxy

Cat File
    [Arguments]    ${os_node_cxn}    ${file_name}
    [Documentation]       Read a file for logging
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    cat ${file_name}     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Disable SeLinux Tempororily
    [Arguments]    ${os_node_cxn}
    [Documentation]       Disable SELinux from command
    Switch Connection     ${os_node_cxn}
    ${output}    ${rc}=    Execute Command    sudo setenforce 0     return_rc=True    return_stdout=True
    Log    ${output}
    Should Not Be True    ${rc}

Get Ssh Connection
    [Arguments]    ${os_ip}     ${os_user}     ${os_password}     ${prompt}      
    ${conn_id}=    SSHLibrary.Open Connection    ${os_ip}    prompt=${prompt}    timeout=1 hour    alias=${os_ip}
    SSHKeywords.Flexible SSH Login    ${os_user}    password=${os_password}
    SSHLibrary.Set Client Configuration    timeout=1 hour
    [Return]    ${conn_id}
