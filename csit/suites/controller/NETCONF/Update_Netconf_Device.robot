*** Settings ***
Suite Teardown
Default Tags      functional    netconf-performance
Library           OperatingSystem
Library           ../../../libraries/RequestsLibrary.py
Library           DateTime
Library           SSHLibrary    timeout=120s
Library           Collections
Library           ${CURDIR}/../../../libraries/netconf_library.py
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ../../../variables/netconf_scale/NetScale_variables.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/NetconfKeywords.robot
Resource          ../../../libraries/NexusKeywords.robot

*** Variables ***

*** Test Cases ***
Connect to ODL System
    SSHLibrary.Open Connection    ${CONTROLLER}    odlsystem
    SSHLibrary.Login With Public Key    ${ODL_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    ${KEYFILE_PASS}

Generate netconf configuration files
# Deploy test tool
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool
    Log    "Filename of test tool=" ${filename}
    Log    "Location of test tool=" ${ttlocation}
    ClusterManagement.Kill_Members_From_List_Or_All
# Generate files
    Start Command    java -jar ${ttlocation}/${filename} --distribution-folder ${WORKSPACE}/${BUNDLEFOLDER} --device-count 4 --debug true

Restart ODL system
    ClusterManagement.Start_Members_From_List_Or_All
    SSHLibrary.Close Connection
    


