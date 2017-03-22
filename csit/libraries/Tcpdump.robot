*** Settings ***
Documentation     Library to catch traffic/packets using linux tcpdump command
Resource          Utils.robot

*** Variables ***
${dump_defaultName}    tcpDump

*** Keywords ***
Start Tcpdumping
    [Arguments]    ${system_ip}    ${fileName}=${dump_defaultName}    ${networkAdapter}=eth0
    [Documentation]    Connects to the remote machine and starts tcpdump
    ${output} =    Run Command On Remote System    ${system_ip}    sudo /usr/sbin/tcpdump -vvv -ni ${networkAdapter} -w /tmp/${fileName}.pcap &
    Log    ${output}

Stop Tcpdumping 
    [Arguments]    ${system_ip}    ${fileName}=${dump_defaultName}
    [Documentation]    Stops catching packets with tcpdump and save in /tmp/
    ${output} =    Run Command On Remote System    ${system_ip}    sudo ps -elf | grep tcpdump
    Log    ${output}
    ${output} =    Run Command On Remote System    ${system_ip}    sudo pkill -f tcpdump
    Log    ${output}

