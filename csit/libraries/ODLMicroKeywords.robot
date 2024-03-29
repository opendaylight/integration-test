*** Settings ***
Documentation       A test suite which contains keywords of ODL micro which are used commonly.

Library             Collections
Library             OperatingSystem
Library             SSHLibrary
Library             String
Library             XML
Library             Collections
Library             RequestsLibrary


*** Keywords ***
Download ODL Micro
    [Documentation]    Create SSH Connection and deploy odl micro
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=ODL_System
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}    delay=4s
    ${file_name} =    NexusKeywords.Deploy_Test_Tool
    ...    odl-micro
    ...    micro-netconf
    ...    micro
    ...    ${BASE_URL}
    ...    build_version=${ODL_MICRO_VERSION}
    ...    build_location=org/opendaylight/odlmicro
    BuiltIn.Set_Suite_Variable    ${FILENAME}    ${filename}

Run ODL Micro
    [Documentation]    Run ODL Micro
    SSHLibrary.Switch_Connection    ODL_System
    SSHLibrary.Write    tar -xvf ${FILE_NAME} -C ${ODL_MICRO_WORKSPACE}/
    SSHLibrary.Write    cd ${ODL_MICRO_WORKSPACE}/micro-netconf-${ODL_MICRO_VERSION}
    ${response} =    SSHLibrary.Execute_Command    ls
    BuiltIn.Log    ${response}
    ${command} =    NexusKeywords.Compose_Full_Java_Command
    ...    -Xms128M -Xmx2048m -XX:+UnlockDiagnosticVMOptions -XX:+HeapDumpOnOutOfMemoryError -XX:+DisableExplicitGC -Dcom.sun.management.jmxremote -Dfile.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom -cp "etc/initial/:lib/*" org.opendaylight.netconf.micro.NetconfMain > /tmp/odlmicro.log 2>&1
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}

Get pid
    [Arguments]    ${process_name}
    ${pid} =    SSHLibrary.Execute Command
    ...    ps -fu ${ODL_SYSTEM_USER} | grep "${process_name}" | grep -v "grep" | awk '{print $2}'
    RETURN    ${pid}

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
    ${mock_pid} =    Get pid    ${process_name}
    IF    '${mock_pid}' == '${EMPTY}'
        BuiltIn.Fail    No ${process_name} process is running
    END

Kill process
    [Arguments]    ${process_name}    ${ssh_alias}=ODL_Micro_instance
    SSHLibrary.Switch_Connection    ${ssh_alias}
    ${mock_pid} =    Get pid    ${process_name}
    SSHLibrary.Execute_Command    kill -9 ${mock_pid}

Download Netconf Testtool
    [Documentation]    Download netconf testtool from opendaylight nexus
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=Netconf_System
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}    delay=4s
    ${file_name} =    NexusKeywords.Deploy_Test_Tool
    ...    netconf
    ...    netconf-testtool
    ...    build_version=${NETCONF_TESTTOOL_VERSION}
    ...    build_location=org/opendaylight/netconf
    Set Global Variable    ${NETCONF_FILENAME}    ${filename}
    ${file_name} =    NexusKeywords.Deploy_Test_Tool
    ...    netconf
    ...    netconf-testtool
    ...    rest-perf-client
    ...    build_version=${NETCONF_TESTTOOL_VERSION}
    ...    build_location=org/opendaylight/netconf
    Set Global Variable    ${RESTPERF_FILENAME}    ${filename}

Run Netconf Testtool
    [Arguments]    ${ssh_alias}=Netconf_System
    NetconfKeywords.Start_Testtool
    ...    ${NETCONF_FILENAME}
    ...    device-count=1
    ...    schemas=${CURDIR}/../variables/netconf/CRUD/schemas
