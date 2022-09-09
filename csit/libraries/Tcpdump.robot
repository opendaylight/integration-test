*** Settings ***
Documentation       Library to catch traffic/packets using linux tcpdump command

Library             SSHLibrary
Resource            SSHKeywords.robot
Resource            Utils.robot
Resource            RemoteBash.robot
Variables           ../variables/Variables.py


*** Variables ***
${dumpalias}            tcpdump
${dumppcap}             dump.pcap
${dumppcappath}         /tmp/${dumppcap}
${dumpcmd}              sudo tcpdump -s 0 -w ${dumppcappath}
${dump_default_name}    tcpDump


*** Keywords ***
Start Tcpdumping
    [Documentation]    Connects to the remote machine via ssh and starts tcpdump linux command
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${TOOLS_SYSTEM_PROMPT}    ${timeout}=5s    ${eth}=eth0
    ...    ${more_params}=${None}
    ${currentcon} =    SSHLibrary.Get Connection    index=True
    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${timeout}    alias=${dumpalias}
    SSHKeywords.Flexible SSH Login    ${user}    password=${password}    delay=${timeout}
    SSHLibrary.Write    ${dumpcmd} -i ${eth} ${more_params}
    IF    ${currentcon}==${None}    RETURN
    SSHLibrary.Switch Connection    ${currentcon}

Stop Tcpdumping And Download
    [Documentation]    Stops catching packets with tcpdump and download the saved file
    [Arguments]    ${filename}=${dumppcap}.xz
    ${oldcon} =    SSHLibrary.Switch Connection    ${dumpalias}
    RemoteBash.Write_Bare_Ctrl_C
    SSHLibrary.Read
    ${stdout} =    SSHLibrary.Execute Command    xz -9ekvv ${dumppcappath}
    Log    ${stdout}
    ${stdout} =    SSHLibrary.Execute Command    ls -la /tmp
    Log    ${stdout}
    SSHLibrary.Get File    ${dumppcappath}.xz    ${filename}
    SSHLibrary.Close Connection
    IF    ${oldcon}==${None}    RETURN
    SSHLibrary.Switch Connection    ${oldcon}

Start Packet Capture On Node
    [Documentation]    Connects to the remote machine and starts tcpdump
    [Arguments]    ${node_ip}    ${file_Name}=${dump_default_name}    ${network_Adapter}=eth0    ${user}=${DEFAULT_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=${DEFAULT_TIMEOUT}    ${filter}=${EMPTY}
    ${current_ssh_connection} =    SSHLibrary.Get Connection
    ${conn_id} =    SSHLibrary.Open Connection    ${node_ip}    prompt=${prompt}    timeout=${prompt_timeout}
    SSHKeywords.Flexible SSH Login    ${user}    ${password}
    ${cmd} =    Set Variable    sudo /usr/sbin/tcpdump -vvv -ni ${networkAdapter} ${filter} -w /tmp/${file_Name}.pcap
    ${stdout}    ${stderr} =    SSHLibrary.Start Command    ${cmd}
    Log    ${stderr}
    Log    ${stdout}
    RETURN    ${conn_id}
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_ssh_connection.index}

Stop Packet Capture on Node
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    [Arguments]    ${conn_id}
    SSHLibrary.Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    sudo ps -elf | grep tcpdump
    Log    ${stdout}
    ${stdout}    ${stderr} =    SSHLibrary.Execute Command    sudo pkill -f tcpdump    return_stderr=True
    Log    ${stderr}
    Log    ${stdout}
    ${stdout} =    SSHLibrary.Execute Command    sudo xz -9ekvv /tmp/*.pcap
    Log    ${stdout}
    ${stdout} =    SSHLibrary.Execute Command    sudo ls -ls /tmp
    Log    ${stdout}

Start Packet Capture on Nodes
    [Documentation]    Start packet captures on the given list of node ips.
    ...    The captures will be named with the tag and ip.
    [Arguments]    ${tag}=${EMPTY}    ${filter}=${EMPTY}    ${ips}=@{EMPTY}
    @{conn_ids} =    BuiltIn.Create List    @{EMPTY}
    FOR    ${ip}    IN    @{ips}
        ${fname} =    BuiltIn.Catenate    SEPARATOR=__    ${tag}    ${ip}
        ${conn_id} =    Tcpdump.Start Packet Capture on Node    ${ip}    file_Name=${fname}    filter=${filter}
        Collections.Append To List    ${conn_ids}    ${conn_id}
    END
    RETURN    @{conn_ids}

Stop Packet Capture on Nodes
    [Documentation]    Stop the packet captures on the given list of node connection ids
    [Arguments]    ${conn_ids}=@{EMPTY}
    FOR    ${conn_id}    IN    @{conn_ids}
        Stop Packet Capture on Node    ${conn_id}
    END
