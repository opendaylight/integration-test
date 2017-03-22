*** Settings ***
Documentation     Library to catch traffic/packets using linux tcpdump command
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
${dumpalias}      tcpdump
${dumppcap}       dump.pcap
${dumppcappath}    /tmp/${dumppcap}
${dumpcmd}        sudo tcpdump -s 0 -w ${dumppcappath}
${dump_default_name}    tcpDump

*** Keywords ***
Start Tcpdumping
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${TOOLS_SYSTEM_PROMPT}    ${timeout}=5s    ${eth}=eth0
    ...    ${more_params}=${None}
    [Documentation]    Connects to the remote machine via ssh and starts tcpdump linux command
    ${currentcon}=    SSHLibrary.Get Connection    index=True
    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${timeout}    alias=${dumpalias}
    Utils.Flexible SSH Login    ${user}    password=${password}    delay=${timeout}
    SSHLibrary.Write    ${dumpcmd} -i ${eth} ${more_params}
    Run Keyword If    ${currentcon}==${None}    Return From Keyword
    SSHLibrary.Switch Connection    ${currentcon}

Stop Tcpdumping And Download
    [Arguments]    ${filename}=${dumppcap}.xz
    [Documentation]    Stops catching packets with tcpdump and download the saved file
    ${oldcon}=    SSHLibrary.Switch Connection    ${dumpalias}
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Read
    ${stdout}=    SSHLibrary.Execute Command    xz -9ekvv ${dumppcappath}
    Log    ${stdout}
    ${stdout}=    SSHLibrary.Execute Command    ls -la /tmp
    Log    ${stdout}
    SSHLibrary.Get File    ${dumppcappath}.xz    ${filename}
    SSHLibrary.Close Connection
    Run Keyword If    ${oldcon}==${None}    Return From Keyword
    SSHLibrary.Switch Connection    ${oldcon}

Start Packet Capture On Node
    [Arguments]    ${node_ip}    ${file_Name}=${dump_default_name}    ${network_Adapter}=eth0     ${user}=${DEFAULT_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}     ${prompt_timeout}=${DEFAULT_TIMEOUT} 
    [Documentation]    Connects to the remote machine and starts tcpdump
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    ${conn_id}=    SSHLibrary.Open Connection    ${node_ip}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    ${cmd} =    Set Variable   sudo /usr/sbin/tcpdump -vvv -ni ${networkAdapter} -w /tmp/${file_Name}.pcap & 
    ${stdout}    ${stderr}    SSHLibrary.Execute Command     ${cmd}     return_stderr=True
    Log    ${stderr}
    Log    ${stdout}
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_ssh_connection.index}
    [Return]    ${conn_id}
	

Stop Packet Capture on Node
    [Arguments]    ${conn_id}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    SSHLibrary.Switch Connection    ${conn_id}
    ${stdout}    ${stderr}    SSHLibrary.Execute Command     sudo ps -elf | grep tcpdump     return_stderr=True
    Log    ${stderr}
    Log    ${stdout}
    ${stdout}    ${stderr}    SSHLibrary.Execute Command     sudo pkill -f tcpdump     return_stderr=True
    Log    ${stderr}
    Log    ${stdout}
    SSHLibrary. Close Connection
