*** Settings ***
Documentation     A test suite with a single test for valid login
Library           Collections
Library           OperatingSystem
Library           SSHLibrary
Library           String
Library           XML
Library           Collections
Library           RequestsLibrary

*** Variables ***

*** Keywords ***
Download ODL Micro
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=ODL_System
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}    delay=4s
    ${file_name} =    NexusKeywords.Deploy_Test_Tool    odl-micro    micro-netconf    micro    ${BASE_URL}
    BuiltIn.Set_Suite_Variable    ${FILENAME}    ${filename}

Run ODL Micro
    SSHLibrary.Switch_Connection    ODL_System
    SSHLibrary.Put_File    ${FILE_NAME}    ${ODL_MICRO_WORKSPACE}/${FILE_NAME}
    SSHLibrary.Write    tar -xvf ${ODL_MICRO_WORKSPACE}/${FILE_NAME} -C ${ODL_MICRO_WORKSPACE}/
    SSHLibrary.Write    cd ${ODL_MICRO_WORKSPACE}/micro-netconf-${ODL_MICRO_VERSION}
    ${command} =    NexusKeywords.Compose_Full_Java_Command    -Xms128M -Xmx2048m -XX:+UnlockDiagnosticVMOptions -XX:+HeapDumpOnOutOfMemoryError -XX:+DisableExplicitGC -Dcom.sun.management.jmxremote -Dfile.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom -cp "etc/initial/:lib/*" org.opendaylight.netconf.micro.NetconfMain > /tmp/odlmicro.log 2>&1
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}

Get pid
    [Arguments]    ${process_name}
    ${pid} =    SSHLibrary.Execute Command    ps -fu ${ODL_SYSTEM_USER} | grep "${process_name}" | grep -v "grep" | awk '{print $2}'
    [Return]    ${pid}

Check netstat
    [Arguments]    ${portno}    ${session}=ODL_Micro_instance
    SSHLibrary.Switch_Connection    ${session}
    SSHLibrary.Write    netstat -tunpl
    SSHLibrary.Read Until Regexp    .*${portno}

Check Process Stats
    [Arguments]    ${process_name}
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=ODL_Micro_instance
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}    delay=4s
    ${mock_pid}    Get pid    ${process_name}
    BuiltIn.Run_Keyword_If    '${mock_pid}' == '${EMPTY}'    BuiltIn.Fail    No ${process_name} process is running

Kill process
    [Arguments]    ${process_name}    ${ssh_alias}=ODL_Micro_instance
    SSHLibrary.Switch_Connection    ${ssh_alias}
    ${mock_pid}    Get pid    ${process_name}
    SSHLibrary.Execute_Command    kill -9 ${mock_pid}

Download Netconf Testtool
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=Netconf_System
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}    delay=4s
    # Deploy_From_Url    ${NEXUS_NETCONF_URL}
    ${file_name} =    NexusKeywords.Deploy_Specific_Version_Test_Tool    netconf    netconf-testtool    1.9.0-SNAPSHOT
    BuiltIn.Set_Suite_Variable    ${NETCONF_FILENAME}    ${filename}

Run Netconf Testtool
    [Arguments]    ${ssh_alias}=Netconf_System
    NetconfKeywords.Start_Testtool    ${NETCONF_FILENAME}    device-count=1    schemas=${CURDIR}/../variables/netconf/CRUD/schemas
