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
    SSHLibrary.Put_File    /home/bhuvan/${FILE_NAME}    /home/bhuvan/check/${FILE_NAME}
    SSHLibrary.Write    tar -xvf ${FILE_NAME}
    SSHLibrary.Write    cd micro-netconf-1.0.0-SNAPSHOT
    ${command} =    NexusKeywords.Compose_Full_Java_Command    -Xms128M -Xmx2048m -XX:+UnlockDiagnosticVMOptions -XX:+HeapDumpOnOutOfMemoryError -XX:+DisableExplicitGC -Dcom.sun.management.jmxremote -Dfile.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom -cp "etc/initial/:lib/*" org.opendaylight.netconf.micro.NetconfMain
    BuiltIn.Log    ${command}
    SSHLibrary.Write    ${command}
    Sleep    20s
    SSHLibrary.Switch_Connection    ODL_System
    SSHLibrary.Write    sudo netstat -tunpl
