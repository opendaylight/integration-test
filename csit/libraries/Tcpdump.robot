*** Settings ***
Documentation     Library to catch traffic/packets using linux tcpdump command
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
${dumpalias}      tcpdump
${dumppcap}       dump.pcap
${dumppcappath}    /tmp/${dumppcap}
${dumpcmd}        sudo tcpdump -i eth0 -s 0 -w ${dumppcappath}

*** Keywords ***
Start Tcpdumping
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${TOOLS_SYSTEM_PROMPT}    ${timeout}=5s
    [Documentation]    Connects to the remote machine via ssh and starts tcpdump linux command
    ${currentcon}=    SSHLibrary.Get Connection    index=True
    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${timeout}    alias=${dumpalias}
    Utils.Flexible SSH Login    ${user}    password=${password}    delay=${timeout}
    SSHLibrary.Write    ${dumpcmd}
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
