*** Settings ***
Documentation     A test suite with a single test for valid login.
...
...               This test has a workflow that is created using keywords in
...               the imported resource file.
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ${CURDIR}/../../libraries/NexusKeywords.robot

*** Variables ***
${ODL_MICRO_VERSION}    1.0.0-SNAPSHOT
${BASE_URL}       https://nexus.opendaylight.org/content/repositories/opendaylight.snapshot/org/opendaylight/odlmicro/micro-netconf
${ORG_URL}        ${BASE_URL}/${ODL_MICRO_VERSION}/
${BUNDLE_URL}     ${BASE_URL}
${ODL_MICRO_WORKSPACE}    /tmp

*** Test Cases ***
Download ODL Micro
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=ODL_System
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}    delay=4s
    ${file_name} =    NexusKeywords.Deploy_Test_Tool    odl-micro    micro-netconf    micro    ${BASE_URL}
    BuiltIn.Set_Suite_Variable    ${FILENAME}    ${filename}

Run ODL Micro
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=ODL_micro_session
    SSHLibrary.Set_Client_Configuration    timeout=10s
    SSHLibrary.Set_Client_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHKeywords.Flexible_SSH_Login    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}    delay=4s
    SSHLibrary.Put_File    ${WORKSPACE}/${FILE_NAME}    ${ODL_MICRO_WORKSPACE}/${FILE_NAME}
    SSHLibrary.Write    tar -xvf ${ODL_MICRO_WORKSPACE}/${FILE_NAME} -C ${ODL_MICRO_WORKSPACE}/
    SSHLibrary.Write    cd ${ODL_MICRO_WORKSPACE}/micro-netconf-${ODL_MICRO_VERSION}
    ${command} =    NexusKeywords.Compose_Full_Java_Command    -Xms128M -Xmx2048m -XX:+UnlockDiagnosticVMOptions -XX:+HeapDumpOnOutOfMemoryError -XX:+DisableExplicitGC -Dcom.sun.management.jmxremote -Dfile.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom -cp "etc/initial/:lib/*" org.opendaylight.netconf.micro.NetconfMain > /tmp/odlmicro.log 2>&1
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}
    BuiltIn.Wait_until_keyword_succeeds    1 min    5 sec    Check netstat    ODL_System

*** Keywords ***
Check netstat
    [Arguments]    ${session}
    SSHLibrary.Switch_Connection    ${session}
    SSHLibrary.Write    netstat -tunpl
    SSHLibrary.Read Until Regexp    .*8181
